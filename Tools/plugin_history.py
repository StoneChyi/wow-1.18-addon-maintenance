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
    runtime_rows = catalog.get("runtime_components", [])
    rows = catalog["addons"] + catalog.get("added_addons", []) + runtime_rows
    runtime_names = {row["addon"] for row in runtime_rows}
    records = []
    for row in rows:
        addon = row["addon"]
        assert addon not in {".", ".."} and not re.search(r"[/\\]", addon)
        expected_directory = "Runtime" if addon in runtime_names else "Plugins"
        assert row["note"] == "PluginHistory/" + expected_directory + "/" + addon + ".md"
        text = read_text(root / row["note"])
        events = parse_entries(text, addon)
        assert row["status"] in STATES
        if row["status"] != "unconfirmed" or events:
            assert "## 插件概况" in text and "## 当前维护摘要" in text, addon
            assert "## 早期历史汇总与维护依据" in text, addon
        records.append({"addon": addon, "status": row["status"], "note": row["note"],
                        "purpose": row["purpose"], "history_group": row.get("history_group"), "latest_record_date": events[0]["date"] if events else None,
                        "latest_record_title": events[0]["title"] if events else "早期历史汇总（日期待确认）",
                        "latest_game_acceptance": events[0]["game_acceptance"] if events else "见早期记录",
                        "record_count": len(events), "records": events})
        if addon in runtime_names:
            records[-1]["scope_type"] = "runtime"
    assert len({r["addon"] for r in records}) == len(records), "Duplicate addon"
    return catalog, records


def cell(value):
    return str(value).replace("|", "\\|").replace("\n", " ").replace("\r", "")


def table(records, base="Plugins"):
    lines = ["| 插件 / 组件 | 最近记录 |", "| --- | --- |"]
    for row in records:
        directory = "Runtime" if row.get("scope_type") == "runtime" else "Plugins"
        prefix = "" if directory == base else "../" + directory + "/"
        link = prefix + row["addon"] + ".md"
        latest = row["latest_record_date"] or "早期记录，日期待确认"
        if row["records"]:
            latest += " · " + row["latest_record_title"]
            latest = f'[{cell(latest)}]({link}#{row["records"][0]["anchor"]})'
        elif row.get("history_group") == "unchanged":
            latest = "暂无本体变化记录"
        lines.append(f'| [{row["addon"]}]({link}) | {latest} |')
    return "\n".join(lines)


def outputs(root):
    catalog, all_records = collect(root)
    records = [r for r in all_records if r.get("scope_type") != "runtime"]
    runtime_records = sorted((r for r in all_records if r.get("scope_type") == "runtime"),
                             key=lambda r: r["addon"].casefold())
    assert all(r["history_group"] in {"unchanged", "modified"} for r in records), "Missing history classification"
    unchanged = sorted((r for r in records if r["history_group"] == "unchanged"), key=lambda r: r["addon"].casefold())
    changed = sorted((r for r in records if r["history_group"] == "modified"), key=lambda r: r["addon"].casefold())
    counts = dict(Counter(r["status"] for r in records))
    main = f'''# 插件修改记录

按插件查找，每个插件一页；页内按时间倒序记录。共 **{len(records)} 个插件档案**，包含已停用插件的历史，不等于当前安装数量。

[总入口](../README.md) · [DLL 等其他组件](../Runtime/README.md) · [记录规范](../记录规范.md)

## 一、没有变化的插件

共 **{len(unchanged)} 个**。这里的“没有变化”仅指现有依据未确认本插件本体的版本迭代或文件修改，不宣称从未修改或等同官方原版。仅来源补充、未实施的核对、其他插件的皮肤适配不算本体修改；取得真实变化依据后移入第二类。

{table(unchanged)}

## 二、经过版本迭代或修改的插件

共 **{len(changed)} 个**。包括版本更新、自行修改、新增、回退，以及有文件差异证据但作者未确认的历史；是否个人原创另按实际证据说明。

每页以时间记录为主。只有确实存在的当前问题或已经提出的进一步优化方案才设相应章节；没有则不设。待游戏验收不自动等于存在故障。

{table(changed)}

## 三、DLL 等其他组件

见 [独立组件记录](../Runtime/README.md)，不混入插件分类或插件数量。
'''
    runtime = f'''# DLL 等其他组件记录

[返回总入口](../README.md) · [插件修改记录](../Plugins/README.md)

共 **{len(runtime_records)} 个**已有独立记录的组件。每个组件分别保留版本更新、修改、验证和回退历史；没有修改任何实际 DLL 或运行配置。原 Plugins 路径的已有历史原件暂时保留，不重复计数，也不作为新的维护入口。

{table(runtime_records, base="Runtime")}
'''
    pending = '''# 历史分类入口已合并

插件只按 [没有变化 / 经过版本迭代或修改](Plugins/README.md) 两类查找，不再用“个人修改归属待确认”另建一套分类。

原有来源不明、作者待确认等说明仍在各插件的早期历史中；没有依据不等于从未修改。此页保留旧链接兼容，不再重复维护名单。
'''
    machine = {"schema_version": 2, "source": "PluginHistory/Plugins/*.md + Runtime/*.md + maintenance-index.json",
               "note": "Generated by Tools/plugin_history.py; classification concerns recorded changes, not authorship or game acceptance.",
               "counts": counts, "history_group_counts": {"unchanged": len(unchanged), "modified": len(changed)},
               "addon_pages": len(records), "dated_records": sum(r["record_count"] for r in records), "addons": records,
               "runtime_dated_records": sum(r["record_count"] for r in runtime_records), "runtime_components": runtime_records}
    return {"PluginHistory/Plugins/README.md": main,
            "PluginHistory/Runtime/README.md": runtime,
            "PluginHistory/待确认插件.md": pending,
            "PluginHistory/change-index.json": json.dumps(machine, ensure_ascii=False, indent=2) + "\n"}, all_records


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
    print(json.dumps({"ok": True, "command": args.command,
                      "addon_pages": sum(r.get("scope_type") != "runtime" for r in records),
                      "runtime_pages": sum(r.get("scope_type") == "runtime" for r in records),
                      "dated_records": sum(r["record_count"] for r in records),
                      "generated_files": list(generated)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
