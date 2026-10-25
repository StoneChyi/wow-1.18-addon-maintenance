assert(BigWigs, "BigWigs not found!")

------------------------------
--      Are you local?      --
------------------------------

local L = AceLibrary("AceLocale-2.2"):new("BigWigsSound")
--~~ local dewdrop = DewdropLib:GetInstance("1.0")

local sounds = {
	Long = "Interface\\AddOns\\BigWigs\\Sounds\\Long.mp3",
	Info = "Interface\\AddOns\\BigWigs\\Sounds\\Info.ogg",
	Alert = "Interface\\AddOns\\BigWigs\\Sounds\\Alert.mp3",
	Alarm = "Interface\\AddOns\\BigWigs\\Sounds\\Alarm.mp3",
	Victory = "Interface\\AddOns\\BigWigs\\Sounds\\Victory.mp3",

	Beware = "Interface\\AddOns\\BigWigs\\Sounds\\Beware.ogg",
	RunAway = "Interface\\AddOns\\BigWigs\\Sounds\\RunAway.ogg",
	Run = "Interface\\AddOns\\BigWigs\\Sounds\\RunAway.wav",

	One = "Interface\\AddOns\\BigWigs\\Sounds\\1.ogg",
	Two = "Interface\\AddOns\\BigWigs\\Sounds\\2.ogg",
	Three = "Interface\\AddOns\\BigWigs\\Sounds\\3.ogg",
	Four = "Interface\\AddOns\\BigWigs\\Sounds\\4.ogg",
	Five = "Interface\\AddOns\\BigWigs\\Sounds\\5.ogg",
	Six = "Interface\\AddOns\\BigWigs\\Sounds\\6.ogg",
	Seven = "Interface\\AddOns\\BigWigs\\Sounds\\7.ogg",
	Eight = "Interface\\AddOns\\BigWigs\\Sounds\\8.ogg",
	Nine = "Interface\\AddOns\\BigWigs\\Sounds\\9.ogg",
	Ten = "Interface\\AddOns\\BigWigs\\Sounds\\10.ogg",

	Murloc = "Sound\\Creature\\Murloc\\mMurlocAggroOld.wav",
	Pain = "Sound\\Creature\\Thaddius\\THAD_NAXX_ELECT.wav",
	Shakira = "Interface\\AddOns\\BigWigs\\Sounds\\Shakira.mp3",

	BikeHorn = "Interface\\AddOns\\BigWigs\\Sounds\\BikeHorn.ogg",
	AirHorn = "Interface\\AddOns\\BigWigs\\Sounds\\custom2\\AirHorn.ogg",

	Scorch = "Interface\\AddOns\\BigWigs\\Sounds\\Scorch.mp3",
	ScorchResist = "Interface\\AddOns\\BigWigs\\Sounds\\ScorchResist.mp3",
	stopcasting = "Interface\\AddOns\\BigWigs\\Sounds\\stopcasting.ogg",
	IgniteDanger = "Interface\\AddOns\\BigWigs\\Sounds\\IgniteDanger.mp3",
	Pyro = "Interface\\AddOns\\BigWigs\\Sounds\\Pyro.mp3",
	stop = "Interface\\AddOns\\BigWigs\\Sounds\\stop.mp3",
	AirHorn = "Interface\\AddOns\\BigWigs\\Sounds\\AirHorn.ogg",
	zjd = "Interface\\AddOns\\BigWigs\\Sounds\\zjd.mp3",
	DropIgnite = "Interface\\AddOns\\BigWigs\\Sounds\\DropIgnite.mp3",
	GoBow = "Interface\\AddOns\\BigWigs\\Sounds\\GoBow.mp3",
	Shakira = "Interface\\AddOns\\BigWigs\\Sounds\\Shakira.mp3",
	Murloc = "Interface\\AddOns\\BigWigs\\Sounds\\Murloc.mp3",
	fire = "Interface\\AddOns\\BigWigs\\Sounds\\fire.mp3",
	cleave = "Interface\\AddOns\\BigWigs\\Sounds\\cleave.mp3",
	daduan = "Interface\\AddOns\\BigWigs\\Sounds\\daduan.mp3",
	tingzhiyidong = "Interface\\AddOns\\BigWigs\\Sounds\\tingzhiyidong.mp3",
	yuexiang = "Interface\\AddOns\\BigWigs\\Sounds\\yuexiang.mp3",
	tingzhishifa = "Interface\\AddOns\\BigWigs\\Sounds\\tizhishifa.mp3",
	zhadan = "Interface\\AddOns\\BigWigs\\Sounds\\zhadan.mp3",
	xiagui = "Interface\\AddOns\\BigWigs\\Sounds\\xiagui.mp3",
	huoyan = "Interface\\AddOns\\BigWigs\\Sounds\\huoyan.mp3",
	heishui = "Interface\\AddOns\\BigWigs\\Sounds\\heishui.mp3",
	buyaodong = "Interface\\AddOns\\BigWigs\\Sounds\\buyaodong.mp3",
	anquan = "Interface\\AddOns\\BigWigs\\Sounds\\anquan.mp3",
	Shakira = "Interface\\AddOns\\BigWigs\\Sounds\\Shakira.mp3",
	Hide = "Interface\\AddOns\\BigWigs\\Sounds\\hide.mp3",
	yuanlidatuan = "Interface\\AddOns\\BigWigs\\Sounds\\yuanlidatuan.mp3",
	goforbuff = "Interface\\AddOns\\BigWigs\\Sounds\\goforbuff.wav",

	-- 木喉要塞 DBM 语音包（源自团本小助理 RaidCommandAssistant）
	-- 集合分摊 / 快出人群 / 快转火 / 注意仇恨 / 打断 / 驱散 / 停手 / 转阶段 / 恐惧
	voiceGather = "Interface\\AddOns\\BigWigs\\Sounds\\Voice\\gathershare.ogg",
	voiceOut = "Interface\\AddOns\\BigWigs\\Sounds\\Voice\\runout.ogg",
	voiceSwitch = "Interface\\AddOns\\BigWigs\\Sounds\\Voice\\changetarget.ogg",
	voiceThreat = "Interface\\AddOns\\BigWigs\\Sounds\\Voice\\tauntboss.ogg",
	voiceInterrupt = "Interface\\AddOns\\BigWigs\\Sounds\\Voice\\interruptsoon.ogg",
	voiceDispel = "Interface\\AddOns\\BigWigs\\Sounds\\Voice\\dispelnow.ogg",
	voiceStopheal = "Interface\\AddOns\\BigWigs\\Sounds\\Voice\\dpsstop.ogg",
	voicePhase = "Interface\\AddOns\\BigWigs\\Sounds\\Voice\\switchphase.ogg",
	voiceFear = "Interface\\AddOns\\BigWigs\\Sounds\\Voice\\fearsoon.ogg",
}


----------------------------
--      Localization      --
----------------------------

L:RegisterTranslations("enUS", function()
	return {
		["Sounds"] = true,
		["sounds"] = true,
		["Options for sounds."] = true,

		["toggle"] = true,
		["Use sounds"] = true,
		["Toggle sounds on or off."] = true,
		["default"] = true,
		["Default only"] = true,
		["Use only the default sound."] = true,

		["voice"] = true,
		["Use voice alerts"] = true,
		["Toggle voice alerts (DBM voice pack) on or off."] = true,

	-- Sunelegy，Wind汉化修复Turtle-WOW中文数据
	-- Last update: 2024-06-22
	["Sounds"] = "声音",
	--["sounds"] = "声音",
	["Options for sounds."] = "声音设置.",

	["toggle"] = "切换",
	["Use sounds"] = "使用声音",
	["Toggle sounds on or off."] = "切换声音开和关.",
	-- ["default"] = "默认",
	["Default only"] = "默认",
	["Use only the default sound."] = "只选用默认声音.",
	}
end)

L:RegisterTranslations("esES", function()
	return {
		["Sounds"] = "Sonidos",
		--["sounds"] = true,
		["Options for sounds."] = "Opciones para sonidos",

		--["toggle"] = "Alternar",
		["Use sounds"] = "Usar sonidos",
		["Toggle sounds on or off."] = "Alterna los sonidos activos o desactivos",
		--["default"] = "defecto",
		["Default only"] = "Solamente defecto",
		["Use only the default sound."] = "Solamente usa el sonido por defecto",
	}
end)

L:RegisterTranslations("koKR", function()
	return {
		["Sounds"] = "효과음",
		["Options for sounds."] = "효과음 옵션.",

		["Use sounds"] = "효과음 사용",
		["Toggle sounds on or off."] = "효과음을 켜거나 끔.",
		["Default only"] = "기본음",
		["Use only the default sound."] = "기본음만 사용.",
	}
end)

L:RegisterTranslations("deDE", function()
	return {
		["Sounds"] = "Sound",
		["Options for sounds."] = "Optionen f\195\188r Sound.",
		["Use sounds"] = "Sound nutzen",
		["Toggle sounds on or off."] = "Sound aktivieren/deaktivieren.",
		["Default only"] = "Nur Standard",
		["Use only the default sound."] = "Nur Standard Sound.",
	}
end)

L:RegisterTranslations("zhCN", function() return {
	-- Sunelegy，Wind汉化修复Turtle-WOW中文数据
	-- Last update: 2024-06-22
	["Sounds"] = "声音",
	-- ["sounds"] = "声音",
	["Options for sounds."] = "声音设置.",

	["toggle"] = "切换",
	["Use sounds"] = "使用声音",
	["Toggle sounds on or off."] = "切换声音开和关.",
	-- ["default"] = "默认",
	["Default only"] = "默认",
	["Use only the default sound."] = "只选用默认声音.",

	["voice"] = "语音",
	["Use voice alerts"] = "语音提醒",
	["Toggle voice alerts (DBM voice pack) on or off."] = "切换语音提醒（DBM语音包）开和关.",
	}
end)

----------------------------------
--      Module Declaration      --
----------------------------------

BigWigsSound = BigWigs:NewModule(L["Sounds"])
BigWigsSound.defaultDB = {
	defaultonly = false,
	sound = true,
	voice = true,
}
BigWigsSound.consoleCmd = L["sounds"]
BigWigsSound.consoleOptions = {
	type = "group",
	name = L["Sounds"],
	desc = L["Options for sounds."],
	args = {
		[L["toggle"]] = {
			type = "toggle",
			name = L["Sounds"],
			desc = L["Toggle sounds on or off."],
			get = function()
				return BigWigsSound.db.profile.sound
			end,
			set = function(v)
				BigWigsSound.db.profile.sound = v
				BigWigs:ToggleModuleActive(L["Sounds"], v)
			end,
		},
		[L["default"]] = {
			type = "toggle",
			name = L["Default only"],
			desc = L["Use only the default sound."],
			get = function()
				return BigWigsSound.db.profile.defaultonly
			end,
			set = function(v)
				BigWigsSound.db.profile.defaultonly = v
			end,
		},
		[L["voice"]] = {
			type = "toggle",
			name = L["Use voice alerts"],
			desc = L["Toggle voice alerts (DBM voice pack) on or off."],
			get = function()
				return BigWigsSound.db.profile.voice
			end,
			set = function(v)
				BigWigsSound.db.profile.voice = v
			end,
		},
	}
}

------------------------------
--      Initialization      --
------------------------------

function BigWigsSound:OnEnable()
	self:RegisterEvent("BigWigs_Message")
	self:RegisterEvent("BigWigs_Sound")
end
function BigWigsSound:OnDisable()
	BigWigs:DebugMessage("OnDisable")
end

-- 语音键（voiceXxx）受独立的「语音提醒」开关控制，关闭时静音（不回退提示音）
local function IsVoiceKey(sound)
	return sound and string.sub(sound, 1, 5) == "voice"
end

function BigWigsSound:BigWigs_Message(text, color, noraidsay, sound, broadcastonly)
	if self.db.profile.sound then
		if not text or sound == false or broadcastonly then
			return
		end

		if IsVoiceKey(sound) and not self.db.profile.voice then
			return
		end
		if sounds[sound] and not self.db.profile.defaultonly then
			PlaySoundFile(sounds[sound])
		else
			PlaySound("RaidWarning")
		end
	end
end

function BigWigsSound:BigWigs_Sound(sound)
	if self.db.profile.sound then
		if IsVoiceKey(sound) and not self.db.profile.voice then
			return
		end
		if sounds[sound] and not self.db.profile.defaultonly then
			PlaySoundFile(sounds[sound])
		else
			PlaySound("RaidWarning")
		end
	end
end
