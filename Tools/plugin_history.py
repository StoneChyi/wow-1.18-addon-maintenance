"""Build the plugin change indexes from per-plugin Markdown records.

Run `python Tools/plugin_history.py build` after editing records, then `check`.
The historical reference catalog and original evidence are never regenerated.
"""
import argparse
from collections import Counter
from datetime import date
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
REPOSITORY = "https://github.com/StoneChyi/wow-1.18-addon-maintenance"
KINDS = {"修改", "更新合并", "实测反馈", "方案", "来源补充", "差异核对", "停用", "范围确认"}
GAME_STATES = {"待游戏验收", "用户实测（限本条范围）", "不适用（说明或停用记录）"}
STATES = {
    "documented_history": "有维护记录",
    "snapshot_difference": "有备份差异，来源待确认",
    "related_skin_only": "仅确认关联皮肤适配",
    "unconfirmed": "尚未确认个人修改",
}
ENTRY = re.compile(r'^<a id="(change-[^"\r\n]+)"></a>\r?\n(?:\r?\n)?'
                   r'### (\d{4}-\d{2}-\d{2})｜([^\r\n]+)\r?\n', re.M)
CONTEXT_MARKER = "<!-- preserved-index-context -->"


def read_text(path):
    return path.read_bytes().decode("utf-8-sig")


def write_text(path, text):
    """Use the original BOM and dominant newline for generated content only."""
    before = path.read_bytes() if path.exists() else b""
    newline = "\r\n" if before.count(b"\r\n") > before.count(b"\n") / 2 else "\n"
    bom = b"\xef\xbb\xbf" if before.startswith(b"\xef\xbb\xbf") else b""
    output = bom + text.replace("\r\n", "\n").replace("\n", newline).encode("utf-8")
    if before != output:
        path.write_bytes(output)


def parse_entries(text, addon):
    if "## 逐次修改记录" not in text:
        return []
    start = text.index("## 逐次修改记录")
    end = text.index("## 早期历史汇总与维护依据", start)
    section = text[start:end]
    matches = list(ENTRY.finditer(section))
    assert len(re.findall(r"^### \d{4}-\d{2}-\d{2}", section, re.M)) == len(matches), (addon, "Entry without stable anchor/date")
    entries = []
    for i, match in enumerate(matches):
        anchor, changed_on, title = match.groups()
        date.fromisoformat(changed_on)
        body = section[match.end():matches[i + 1].start() if i + 1 < len(matches) else len(section)]

        def field(label):
            found = re.findall(r"^- " + label + r"：([^\r\n]+)", body, re.M)
            assert len(found) == 1, (addon, title, "Missing/duplicate " + label)
            return found[0].strip()

        record_id = field("记录编号").strip("`")
        assert re.fullmatch(re.escape(addon) + "-" + changed_on.replace("-", "") + r"-\d{2,}", record_id)
        assert anchor == "change-" + record_id
        kind, game = field("记录类型"), field("游戏验收")
        assert kind in KINDS and game in GAME_STATES, (addon, title, kind, game)
        source = field("对应提交")
        commits = re.findall(re.escape(REPOSITORY) + r"/commit/([0-9a-f]{40})(?=[)#\s]|$)", source)
        # A new record is committed together with its implementation. Its own SHA
        # cannot be embedded in that same commit; the file-history link resolves it.
        if not commits:
            assert source == "随本条记录一并提交（见本页 Git 历史）", (addon, title, "Missing commit reference")
        assert body.strip(), (addon, title)
        entries.append({"id": record_id, "date": changed_on, "title": title,
                        "kind": kind, "game_acceptance": game, "commits": commits,
                        "anchor": anchor})
    assert len({e["id"] for e in entries}) == len(entries), (addon, "Duplicate record ID")
    # IDs number events in chronological order, including multiple events per day.
    order = [(e["date"], int(e["id"].rsplit("-", 1)[1])) for e in entries]
    assert order == sorted(order, reverse=True), (addon, "Records must be newest first")
    return entries


def collect(root):
    catalog = json.loads((root / "PluginHistory/maintenance-index.json").read_bytes())
    rows = catalog["addons"] + catalog.get("added_addons", [])
    records = []
    for row in rows:
        addon = row["addon"]
        assert addon not in {".", ".."} and not re.search(r"[/\\]", addon)
        assert row["note"] == "PluginHistory/Plugins/" + addon + ".md"
        text = read_text(root / row["note"])
        events = parse_entries(text, addon)
        assert row["status"] in STATES
        if row["status"] != "unconfirmed" or events:
            assert "## 插件概况" in text and "## 当前维护摘要" in text, addon
            assert "## 早期历史汇总与维护依据" in text, addon
        records.append({"addon": addon, "status": row["status"], "note": row["note"],
                        "purpose": row["purpose"], "latest_record_date": events[0]["date"] if events else None,
                        "latest_record_title": events[0]["title"] if events else "早期历史汇总（日期待确认）",
                        "latest_game_acceptance": events[0]["game_acceptance"] if events else "见早期记录",
                        "record_count": len(events), "records": events})
    assert len({r["addon"] for r in records}) == len(records), "Duplicate addon"
    return catalog, records


def cell(value):
    return str(value).replace("|", "\\|").replace("\n", " ").replace("\r", "")


def table(records, pending=False):
    if pending:
        lines = ["| 插件 | 证据状态 | 已知情况 / 待确认 |", "| --- | --- | --- |"]
    else:
        lines = ["| 插件 | 最近记录日期 | 最近记录 | 游戏验收（仅最近一条） |", "| --- | --- | --- | --- |"]
    for row in records:
        prefix = "Plugins/" if pending else ""
        link = f'[{row["addon"]}]({prefix}{row["addon"]}.md)'
        if pending:
            lines.append(f'| {link} | {STATES[row["status"]]} | {cell(row["purpose"])} |')
        else:
            latest = row["latest_record_title"] if row["records"] else row["purpose"]
            if row["records"]:
                latest = f'[{cell(latest)}]({row["addon"]}.md#{row["records"][0]["anchor"]})'
            lines.append(f'| {link} | {row["latest_record_date"] or "日期待确认"} | {latest} | {row["latest_game_acceptance"]} |')
    return "\n".join(lines)


def outputs(root):
    catalog, records = collect(root)
    counts = dict(Counter(r["status"] for r in records))
    changed = sorted((r for r in records if r["status"] == "documented_history"),
                     key=lambda r: (r["latest_record_date"] or "", r["addon"].casefold()), reverse=True)
    related = sorted((r for r in records if r["status"] == "related_skin_only"), key=lambda r: r["addon"].casefold())
    pending = sorted((r for r in records if r["status"] in {"snapshot_difference", "unconfirmed"}), key=lambda r: r["addon"].casefold())
    previous = read_text(root / "PluginHistory/Plugins/README.md")
    context = previous.split(CONTEXT_MARKER, 1)[1].lstrip("\r\n") if CONTEXT_MARKER in previous else ""
    main = f'''# 插件修改记录

每个插件一个文件，每次修改一条记录；点插件名查看完整历史，点最近记录直接跳转。最新记录在前，早期历史及依据保留在文件末尾。

当前覆盖 **{len(records)} 个插件页面**：有维护记录 **{counts.get("documented_history", 0)} 个**，仅关联皮肤适配 **{len(related)} 个**，其余 **{len(pending)} 个**的个人修改归属或内容待确认。已停用插件保留历史。

[待确认插件](../待确认插件.md) · [验收与历史缺项](../待补充清单.md) · [记录规范](../记录规范.md) · [记录模板](../记录模板.md) · [机器索引](../change-index.json)

## 有维护记录的插件

“最近记录”包含修改、更新、反馈和方案，记录类型在插件页注明；日期待确认的早期汇总不伪造修改时间。游戏验收只代表最近一条的范围，其他功能请查相应记录。

{table(changed)}

## 仅确认关联皮肤适配

{table(related)}

## 记录与查找

- 有明确日期的维护逐条记录；同日多次修改分别编号，旧记录保留。
- 尚不能准确拆分的早期内容保留为历史汇总，附原始依据。
- 新插件独立加入 added_addons；初始化的 105 项与基线证据保持原义。
- 修改插件页后运行 `python Tools/plugin_history.py build`，再运行 `python Tools/plugin_history.py check` 与 `python Tools/check_plugin_notes.py`。
- 对应提交是可点击的 GitHub 提交链接；新记录可使用“随本条记录一并提交（见本页 Git 历史）”，避免为填入自身提交号另造提交。

{CONTEXT_MARKER}
{context}'''
    pending_text = f'''# 待确认插件

这里列出 **{len(pending)} 个**尚不能确认个人修改归属或具体内容的插件。保留原说明页和完整基线；未找到依据不等于从未修改。TWThreat 的来源补充也不等于确认个人修改。

[返回插件修改记录](Plugins/README.md) · [补充历史与游戏验收](待补充清单.md)

{table(pending, pending=True)}

用户补充按实际确认日期新增记录，不反填未经证实的历史日期。仅关联皮肤适配的插件单列于主索引。
'''
    machine = {"schema_version": 1, "source": "PluginHistory/Plugins/*.md + maintenance-index.json",
               "note": "Generated by Tools/plugin_history.py; dates describe records, not proof of original authorship or global game acceptance.",
               "counts": counts, "addon_pages": len(records),
               "dated_records": sum(r["record_count"] for r in records), "addons": records}
    return {"PluginHistory/Plugins/README.md": main,
            "PluginHistory/待确认插件.md": pending_text,
            "PluginHistory/change-index.json": json.dumps(machine, ensure_ascii=False, indent=2) + "\n"}, records


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["build", "check"])
    args = parser.parse_args()
    generated, records = outputs(ROOT)
    if args.command == "build":
        for relative, text in generated.items():
            write_text(ROOT / relative, text)
    else:
        for relative, expected in generated.items():
            assert read_text(ROOT / relative).replace("\r\n", "\n") == expected.replace("\r\n", "\n"), (relative, "Index is stale; run build")
        commits = {c for r in records for e in r["records"] for c in e["commits"]}
        for commit in commits:
            subprocess.run(["git", "-C", str(ROOT), "cat-file", "-e", commit + "^{commit}"], check=True, capture_output=True)
    print(json.dumps({"ok": True, "command": args.command, "addon_pages": len(records),
                      "dated_records": sum(r["record_count"] for r in records),
                      "generated_files": list(generated)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
