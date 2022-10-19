local L = LibStub('AceLocale-3.0'):GetLocale('RaidBuffStatus')
local longtoshortblessing = RaidBuffStatus.longtoshortblessing
local ppassignments = RaidBuffStatus.ppassignments
local pppallies = RaidBuffStatus.pppallies
local SP = RaidBuffStatus.SP
local GT = RaidBuffStatus.GT
local report = RaidBuffStatus.report
local raid = RaidBuffStatus.raid
RBS_svnrev["Buffs.lua"] = select(3,string.find("$Revision: 388 $", ".* (.*) .*"))

local function tableMerge(result, ...)
  for _, t in ipairs({...}) do
    for _, v in ipairs(t) do
      table.insert(result, v)
    end
  end
end

local BSmeta = {}
local BS = setmetatable({}, BSmeta)
local BSI = setmetatable({}, BSmeta)
BSmeta.__index = function(self, key)
	local name, icon
	if type(key) == "number" then
		name, _, icon = GetSpellInfo(key)
	else
		geterrorhandler()(("Unknown spell key %q"):format(key))
	end
	if name then
		BS[key] = name
		BS[name] = name
		BSI[key] = icon
		BSI[name] = icon
	else
		BS[key] = false
		BSI[key] = false
		geterrorhandler()(("Unknown spell info key %q"):format(key))
	end
	return self[key]
end

local function SpellName(spellID)
	local name = GetSpellInfo(spellID)
	return name
end

local ITmeta = {}
local ITN = setmetatable({}, ITmeta)
local ITT = setmetatable({}, ITmeta)
ITN.unknown = L["Please relog or reload UI to update the item cache."]
ITT.unknown = "Interface\\Icons\\INV_Misc_QuestionMark"
ITmeta.__index = function(self, key)
	local name, icon
	if type(key) == "number" then
		name, _, _, _, _, _, _, _, _, icon = GetItemInfo(key)
		if not name then
			GameTooltip:SetHyperlink("item:"..key..":0:0:0:0:0:0:0")  -- force server to send item info
			GameTooltip:ClearLines();
			name, _, _, _, _, _, _, _, _, icon = GetItemInfo(key)  -- info might not be in the cache yet but worth trying again
		end
	else
		geterrorhandler()(("Unknown item key %q"):format(key))
	end
	if name then
		ITN[key] = name
		ITN[name] = name
		ITT[key] = icon
		ITT[name] = icon
		return self[key]
	end
	return self.unknown
end

local tbcflasks = {
	SpellName(17626), -- Flask of the Titans
	SpellName(17627), -- [Flask of] Distilled Wisdom
	SpellName(17628), -- [Flask of] Supreme Power
	SpellName(17629), -- [Flask of] Chromatic Resistance
	SpellName(28518), -- Flask of Fortification
	SpellName(28519), -- Flask of Mighty Restoration
	SpellName(28520), -- Flask of Relentless Assault
	SpellName(28521), -- Flask of Blinding Light
	SpellName(28540), -- Flask of Pure Death
	SpellName(33053), -- Mr. Pinchy's Blessing
	SpellName(42735), -- [Flask of] Chromatic Wonder
	SpellName(40567), -- Unstable Flask of the Bandit
	SpellName(40568), -- Unstable Flask of the Elder
	SpellName(40572), -- Unstable Flask of the Beast
	SpellName(40573), -- Unstable Flask of the Physician
	SpellName(40575), -- Unstable Flask of the Soldier
	SpellName(40576), -- Unstable Flask of the Sorcerer
	SpellName(41608), -- Relentless Assault of Shattrath
	SpellName(41609), -- Fortification of Shattrath
	SpellName(41610), -- Mighty Restoration of Shattrath
	SpellName(41611), -- Supreme Power of Shattrath
	SpellName(46837), -- Pure Death of Shattrath
	SpellName(46839), -- Blinding Light of Shattrath
	SpellName(67019), -- Flask of the North (WotLK 3.2)
}

local wotlkflasks = {
	SpellName(53755), -- Flask of the Frost Wyrm
	SpellName(53758), -- Flask of Stoneblood
	SpellName(54212), -- Flask of Pure Mojo
	SpellName(53760), -- Flask of Endless Rage
	SpellName(62380), -- Lesser Flask of Resistance  -- pathetic flask
}

local tbcbelixirs = {
	SpellName(11390),-- Arcane Elixir
	SpellName(17538),-- Elixir of the Mongoose
	SpellName(17539),-- Greater Arcane Elixir
	SpellName(28490),-- Major Strength
	SpellName(28491),-- Healing Power
	SpellName(28493),-- Major Frost Power
	SpellName(54494),-- Major Agility
	SpellName(28501),-- Major Firepower
	SpellName(28503),-- Major Shadow Power
	SpellName(38954),-- Fel Strength Elixir
	SpellName(33720),-- Onslaught Elixir
	SpellName(54452),-- Adept's Elixir
	SpellName(33726),-- Elixir of Mastery
	SpellName(26276),-- Elixir of Greater Firepower
	SpellName(45373),-- Bloodberry - only works on Sunwell Plateau
}
local tbcgelixirs = {
	SpellName(11348),-- Greater Armor/Elixir of Superior Defense
	SpellName(11396),-- Greater Intellect
	SpellName(24363),-- Mana Regeneration/Mageblood Potion
	SpellName(28502),-- Major Armor/Elixir of Major Defense
	SpellName(28509),-- Greater Mana Regeneration/Elixir of Major Mageblood
	SpellName(28514),-- Empowerment
	SpellName(29626),-- Earthen Elixir
	SpellName(39625),-- Elixir of Major Fortitude
	SpellName(39627),-- Elixir of Draenic Wisdom
	SpellName(39628),-- Elixir of Ironskin
}

local wotlkbelixirs = {
	SpellName(28497), -- Mighty Agility
	SpellName(53748), -- Mighty Strength
	SpellName(53749), -- Guru's Elixir
	SpellName(33721), -- Spellpower Elixir
	SpellName(53746), -- Wrath Elixir
	SpellName(60345), -- Armor Piercing
	SpellName(60340), -- Accuracy
	SpellName(60344), -- Expertise
	SpellName(60341), -- Deadly Strikes
	SpellName(60346), -- Lightning Speed
}
local wotlkgelixirs = {
	SpellName(60347), -- Mighty Thoughts
	SpellName(53751), -- Mighty Fortitude
	SpellName(53747), -- Elixir of Spirit
	SpellName(60343), -- Mighty Defense
	SpellName(53763), -- Elixir of Protection
	SpellName(53764), -- Mighty Mageblood
}

local wotlkgoodtbcflasks = {}
local wotlkgoodtbcbelixirs = {}
local wotlkgoodtbcgelixirs = {}

table.insert(wotlkgoodtbcflasks,SpellName(17627)) -- [Flask of] Distilled Wisdom

table.insert(wotlkgoodtbcbelixirs,SpellName(33721)) -- Spellpower Elixir
table.insert(wotlkgoodtbcbelixirs,SpellName(28491))-- Healing Power
table.insert(wotlkgoodtbcbelixirs,SpellName(54494))-- Major Agility
table.insert(wotlkgoodtbcbelixirs,SpellName(28503))-- Major Shadow Power

table.insert(wotlkgoodtbcgelixirs,SpellName(39627))-- Elixir of Draenic Wisdom

RaidBuffStatus.wotlkgoodtbcflixirs = {}
for _,v in ipairs (wotlkgoodtbcflasks) do
	table.insert(RaidBuffStatus.wotlkgoodtbcflixirs,v)
end
for _,v in ipairs (wotlkgoodtbcbelixirs) do
	table.insert(RaidBuffStatus.wotlkgoodtbcflixirs,v)
end
for _,v in ipairs (wotlkgoodtbcgelixirs) do
	table.insert(RaidBuffStatus.wotlkgoodtbcflixirs,v)
end

for _,v in ipairs (wotlkgelixirs) do
	table.insert(wotlkgoodtbcgelixirs,v)
end
for _,v in ipairs (wotlkbelixirs) do
	table.insert(wotlkgoodtbcbelixirs,v)
end
for _,v in ipairs (wotlkflasks) do
	table.insert(wotlkgoodtbcflasks,v)
end


local allflasks = {}
local allbelixirs = {}
local allgelixirs = {}
for _,v in ipairs (tbcflasks) do
	table.insert(allflasks,v)
end
for _,v in ipairs (wotlkflasks) do
	table.insert(allflasks,v)
end
for _,v in ipairs (tbcbelixirs) do
	table.insert(allbelixirs,v)
end
for _,v in ipairs (wotlkbelixirs) do
	table.insert(allbelixirs,v)
end
for _,v in ipairs (tbcgelixirs) do
	table.insert(allgelixirs,v)
end
for _,v in ipairs (wotlkgelixirs) do
	table.insert(allgelixirs,v)
end


local foods = {
	SpellName(35272), -- Well Fed
	SpellName(44106), -- "Well Fed" from Brewfest
}

local allfoods = {
	SpellName(35272), -- Well Fed
	SpellName(44106), -- "Well Fed" from Brewfest
	SpellName(43730), -- Electrified
	SpellName(43722), -- Enlightened
	SpellName(25661), -- Increased Stamina
	SpellName(25804), -- Rumsey Rum Black Label
}

local fortitude = {
	SpellName(1243), -- Power Word: Fortitude
	SpellName(21562), -- Prayer of Fortitude
}

local wild = {
	SpellName(1126), -- Mark of the Wild
	SpellName(21849), -- Gift of the Wild
}

local intellect = {
	SpellName(1459), -- Arcane Intellect
	SpellName(23028), -- Arcane Brilliance
	SpellName(61024), -- Dalaran Intellect
	SpellName(61316), -- Dalaran Brilliance
}

local spirit = {
	SpellName(14752), -- Divine Spirit
	SpellName(27681), -- Prayer of Spirit
}

local shadow = {
	SpellName(976), -- Shadow Protection
	SpellName(27683), -- Prayer of Shadow Protection
}

local auras = {
	SpellName(32223), -- Crusader Aura
	SpellName(465), -- Devotion Aura
	SpellName(7294), -- Retribution Aura
	SpellName(19746), -- Concentration Aura
	SpellName(19876), -- Shadow Resistance Aura
	SpellName(19888), -- Frost Resistance Aura
	SpellName(19891), -- Fire Resistance Aura
}

local aspects = {
	SpellName(13163), -- Aspect of the Monkey
	SpellName(13165), -- Aspect of the Hawk
	SpellName(13161), -- Aspect of the Beast
	SpellName(20043), -- Aspect of the Wild
	SpellName(34074), -- Aspect of the Viper
	SpellName(5118), -- Aspect of the Cheetah
	SpellName(13159), -- Aspect of the Pack
	SpellName(61846),  -- Aspect of the Dragonhawk
}

local badaspects = {
	SpellName(5118), -- Aspect of the Cheetah
	SpellName(13159), -- Aspect of the Pack
}

local magearmors = {
	SpellName(6117), -- Mage Armor
	SpellName(168), -- Frost Armor
	SpellName(7302), -- Ice Armor
	SpellName(30482), -- Molten Armor
}

local dkpresences = {
	SpellName(48266), -- Blood Presence
	SpellName(48263), -- Frost Presence
	SpellName(48265), -- Unholy Presence
}

local seals = {
	SpellName(20165), -- Seal of Light
	SpellName(20166), -- Seal of Wisdom
	SpellName(21084), -- Seal of Righteousness
	SpellName(20164), -- Seal of Justice
	SpellName(31801), -- Seal of Vengeance
	SpellName(20375), -- Seal of Command
	SpellName(53736), -- Seal of Corruption
}

local blessingofforgottenkings = {
	BS[69378], -- Blessing of Forgotten Kings
	BS[20217], -- Blessing of Kings
	BS[25898], -- Greater Blessing of Kings
}

local blessingofkings = {
	BS[20217], -- Blessing of Kings
	BS[25898], -- Greater Blessing of Kings
--	BS[69378], -- Blessing of Forgotten Kings
}
blessingofkings.name = BS[20217] -- Blessing of Kings
blessingofkings.shortname = L["BoK"]

local blessingofsanctuary = {
	BS[20911], -- Blessing of Sanctuary
	BS[25899], -- Greater Blessing of Sanctuary
}
blessingofsanctuary.name = BS[20911] -- Blessing of Sanctuary
blessingofsanctuary.shortname = L["BoS"]

local blessingofwisdom = {
	BS[19742], -- Blessing of Wisdom
	BS[25894], -- Greater Blessing of Wisdom
	BS[5677], -- Mana Spring
}
blessingofwisdom.name = BS[19742] -- Blessing of Wisdom
blessingofwisdom.shortname = L["BoW"]

local blessingofmight = {
	BS[19740], -- Blessing of Might
	BS[25782], -- Greater Blessing of Might
	BS[27578], -- Battle Shout
	BS[2048],  -- Battle Shout
	BS[47436], -- Battle Shout
}
blessingofmight.name = BS[19740] -- Blessing of Might
blessingofmight.shortname = L["BoM"]

local allblessings = {}
table.insert(allblessings, blessingofkings)
table.insert(allblessings, blessingofsanctuary)
table.insert(allblessings, blessingofwisdom)
table.insert(allblessings, blessingofmight)

local nametoblessinglist = {}
nametoblessinglist[BS[20217]] = blessingofkings -- Blessing of Kings
nametoblessinglist[BS[20911]] = blessingofsanctuary -- Blessing of Sanctuary
nametoblessinglist[BS[19742]] = blessingofwisdom -- Blessing of Wisdom
nametoblessinglist[BS[19740]] = blessingofmight -- Blessing of Might
RaidBuffStatus.nametoblessinglist = nametoblessinglist

local minblessings = {}
local mb = minblessings
mb.HERO = {}
mb.HERO.ALL = {}

mb.WARRIOR = {}
mb.WARRIOR.All = {}
mb.WARRIOR.All[1] = blessingofmight
mb.WARLOCK = {}
mb.WARLOCK.All = {}
mb.SHAMAN = {}
mb.SHAMAN.All = {}
mb.SHAMAN[L["Elemental"]] = {}
mb.SHAMAN[L["Enhancement"]] = {}
mb.SHAMAN[L["Restoration"]] = {}
mb.SHAMAN[L["Enhancement"]][1] = blessingofmight
mb.ROGUE = {}
mb.ROGUE.All = {}
mb.ROGUE.All[1] = blessingofmight
mb.PRIEST = {}
mb.PRIEST.All = {}
mb.PALADIN = {}
mb.PALADIN.All = {}
mb.PALADIN[L["Holy"]] = {}
mb.PALADIN[L["Protection"]] = {}
mb.PALADIN[L["Retribution"]] = {}
mb.PALADIN[L["Protection"]][1] = blessingofmight
mb.PALADIN[L["Retribution"]][1] = blessingofmight
mb.MAGE = {}
mb.MAGE.All = {}
mb.HUNTER = {}
mb.HUNTER.All = {}
mb.HUNTER.All[1] = blessingofmight
mb.DRUID = {}
mb.DRUID.All = {}
mb.DRUID[L["Balance"]] = {}
mb.DRUID[L["Feral Combat"]] = {}
mb.DRUID[L["Restoration"]] = {}
mb.DRUID[L["Feral Combat"]][1] = blessingofmight
mb.DEATHKNIGHT = {}
mb.DEATHKNIGHT.All = {}
mb.DEATHKNIGHT.All[1] = blessingofmight
table.insert(mb.WARRIOR.All, blessingofkings) -- todo change in to the format above instead of table inserts
table.insert(mb.WARLOCK.All, blessingofkings)
table.insert(mb.SHAMAN.All, blessingofkings)
table.insert(mb.SHAMAN[L["Elemental"]], blessingofkings)
table.insert(mb.SHAMAN[L["Enhancement"]], blessingofkings)
table.insert(mb.SHAMAN[L["Restoration"]], blessingofkings)
table.insert(mb.ROGUE.All, blessingofkings)
table.insert(mb.PRIEST.All, blessingofkings)
table.insert(mb.PALADIN.All, blessingofkings)
table.insert(mb.PALADIN[L["Holy"]], blessingofkings)
table.insert(mb.PALADIN[L["Protection"]], blessingofkings)
table.insert(mb.PALADIN[L["Retribution"]], blessingofkings)
table.insert(mb.MAGE.All, blessingofkings)
table.insert(mb.HUNTER.All, blessingofkings)
table.insert(mb.DRUID.All, blessingofkings)
table.insert(mb.DRUID[L["Restoration"]], blessingofkings)
table.insert(mb.DRUID[L["Balance"]], blessingofkings)
table.insert(mb.DRUID[L["Feral Combat"]], blessingofkings)
table.insert(mb.DEATHKNIGHT.All, blessingofkings)
table.insert(mb.WARLOCK.All, blessingofwisdom)
table.insert(mb.SHAMAN.All, blessingofwisdom)
table.insert(mb.SHAMAN[L["Elemental"]], blessingofwisdom)
table.insert(mb.SHAMAN[L["Enhancement"]], blessingofwisdom)
table.insert(mb.SHAMAN[L["Restoration"]], blessingofwisdom)
table.insert(mb.PRIEST.All, blessingofwisdom)
table.insert(mb.PALADIN.All, blessingofwisdom)
table.insert(mb.PALADIN[L["Protection"]], blessingofwisdom)
table.insert(mb.PALADIN[L["Holy"]], blessingofwisdom)
table.insert(mb.PALADIN[L["Retribution"]], blessingofwisdom)
table.insert(mb.MAGE.All, blessingofwisdom)
table.insert(mb.HUNTER.All, blessingofwisdom)
table.insert(mb.DRUID.All, blessingofwisdom)
table.insert(mb.DRUID[L["Balance"]], blessingofwisdom)
table.insert(mb.DRUID[L["Feral Combat"]], blessingofwisdom)
table.insert(mb.DRUID[L["Restoration"]], blessingofwisdom)
table.insert(mb.WARRIOR.All, blessingofsanctuary)
table.insert(mb.WARLOCK.All, blessingofsanctuary)
table.insert(mb.SHAMAN.All, blessingofsanctuary)
table.insert(mb.SHAMAN[L["Elemental"]], blessingofsanctuary)
table.insert(mb.SHAMAN[L["Enhancement"]], blessingofsanctuary)
table.insert(mb.SHAMAN[L["Restoration"]], blessingofsanctuary)
table.insert(mb.ROGUE.All, blessingofsanctuary)
table.insert(mb.PRIEST.All, blessingofsanctuary)
table.insert(mb.PALADIN.All, blessingofsanctuary)
table.insert(mb.PALADIN[L["Holy"]], blessingofsanctuary)
table.insert(mb.PALADIN[L["Protection"]], blessingofsanctuary)
table.insert(mb.PALADIN[L["Retribution"]], blessingofsanctuary)
table.insert(mb.MAGE.All, blessingofsanctuary)
table.insert(mb.HUNTER.All, blessingofsanctuary)
table.insert(mb.DRUID.All, blessingofsanctuary)
table.insert(mb.DRUID[L["Restoration"]], blessingofsanctuary)
table.insert(mb.DRUID[L["Balance"]], blessingofsanctuary)
table.insert(mb.DRUID[L["Feral Combat"]], blessingofsanctuary)
table.insert(mb.DEATHKNIGHT.All, blessingofsanctuary)


local scrollofagility = {
	BS[8115], -- Agility
}
scrollofagility.name = BS[8115] -- Agility
scrollofagility.shortname = L["Agil"]

local scrollofstrength = {
	BS[8118], -- Strength
}
scrollofstrength.name = BS[8118] -- Strength
scrollofstrength.shortname = L["Str"]

local scrollofintellect = {
	BS[8096], -- Intellect
}
scrollofintellect.name = BS[8096] -- Intellect
scrollofintellect.shortname = L["Int"]

local scrollofprotection = {
	BS[42206], -- Protection
}
scrollofprotection.name = BS[42206] -- Protection
scrollofprotection.shortname = L["Prot"]

local scrollofspirit = {
	BS[8112], -- Spirit
}
scrollofspirit.name = BS[8112] -- Spirit
scrollofspirit.shortname = L["Spi"]

local flaskzones = {
	gruul = {
		zones = {
			L["Gruul's Lair"],
		},
		flasks = {
			SpellName(40567), -- 40567 Unstable Flask of the Bandit
			SpellName(40568), -- 40568 Unstable Flask of the Elder
			SpellName(40572), -- 40572 Unstable Flask of the Beast
			SpellName(40573), -- 40573 Unstable Flask of the Physician
			SpellName(40575), -- 40575 Unstable Flask of the Soldier
			SpellName(40576), -- 40576 Unstable Flask of the Sorcerer
		},
	},
	shattrath = {
		zones = {
			L["Tempest Keep"],
			L["Serpentshrine Cavern"],
			L["Black Temple"],
			L["Sunwell Plateau"],
			L["Hyjal Summit"],
		},
		flasks = {
			SpellName(41608), -- 41608 Relentless Assault of Shattrath
			SpellName(41609), -- 41609 Fortification of Shattrath
			SpellName(41610), -- 41610 Mighty Restoration of Shattrath
			SpellName(41611), -- 41611 Sureme Power of Shattrath
			SpellName(46837), -- 46837 Pure Death of Shattrath
			SpellName(46839), -- 46839 Blinding Light of Shattrath
		},
	},
}

local roguewepbuffs = {
	L["( Poison ?[IVX]*)"], -- Anesthetic Poison, Deadly Poison [IVX]*, Crippling Poison [IVX]*, Wound Poison [IVX]*, Instant Poison [IVX]*, Mind-numbing Poison [IVX]*
}

local lockwepbuffs = {
	L["(Spellstone)"], -- Lock self buff
	L["(Firestone)"], -- Lock self buff
}

local shamanwepbuffs = {
	L["(Flametongue)"], -- Shaman self buff
	L["(Earthliving)"], -- Resto Shaman self buff
	L["(Frostbrand)"], -- Shaman self buff
	L["(Rockbiter)"], -- Shaman self buff
	L["(Windfury)"], -- Shaman self buff
}


local BF = {
	pvp = {											-- button name
		order = 1000,
		list = "pvplist",								-- list name
		check = "checkpvp",								-- check name
		default = false,									-- default state enabled
		defaultbuff = false,								-- default state report as buff missing
		defaultwarning = true,								-- default state report as warning
		defaultdash = false,								-- default state show on dash
		defaultdashcombat = false,							-- default state show on dash when in combat
		defaultboss = false,
		defaulttrash = false,
		checkzonedout = true,								-- check when unit is not in this zone
		selfbuff = true,								-- is it a buff the player themselves can fix
		timer = true,									-- rbs will count how many minutes this buff has been missing/active
		chat = L["PVP On"],								-- chat report
		pre = nil,
		main = function(self, name, class, unit, raid, report)				-- called in main loop
			if UnitIsPVP(unit.unitid) then
				table.insert(report.pvplist, name)
			end
		end,
		post = nil,									-- called after main loop
		icon = "Interface\\Icons\\INV_BannerPVP_02",					-- icon
		update = function(self)								-- icon text
			RaidBuffStatus:DefaultButtonUpdate(self, report.pvplist, RaidBuffStatus.db.profile.checkpvp, true, report.pvplist)
		end,
		click = function(self, button, down)						-- button click
			RaidBuffStatus:ButtonClick(self, button, down, "pvp")
		end,
		tip = function(self)								-- tool tip
			RaidBuffStatus:Tooltip(self, L["PVP is On"], report.pvplist, raid.BuffTimers.pvptimerlist)
		end,
		whispertobuff = nil,
		singlebuff = nil,
		partybuff = nil,
		raidbuff = nil,
	},
	crusader = {
		order = 990,
		list = "crusaderlist",
		check = "checkcrusader",
		default = true,
		defaultbuff = false,
		defaultwarning = true,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = BS[32223], -- Crusader Aura
		pre = function(self, raid, report)
			report.whoescrusader = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.crusader = true
			if unit.hasbuff[BS[32223]] then -- Crusader Aura
				local _, _, _, _, _, _, _, caster = UnitBuff(unit.unitid, BS[32223]) -- Crusader Aura
				if caster then
					local lolname = RaidBuffStatus:UnitNameRealm(caster)
					report.whoescrusader[lolname] = true
				end
			end
		end,
		post = function(self, raid, report)
			for name, _ in pairs(report.whoescrusader) do
				table.insert(report.crusaderlist, name)
			end
		end,
		icon = BSI[32223], -- Crusader Aura
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.crusaderlist, RaidBuffStatus.db.profile.checkcrusader, report.checking.crusader or false, report.crusaderlist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "crusader", RaidBuffStatus:SelectPalaAura())
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Paladin has Crusader Aura"], report.crusaderlist)
		end,
		whispertobuff = nil,
		singlebuff = nil,
		partybuff = nil,
		raidbuff = nil,
	},

-- TODO
--[[
	shadows = {
		order = 980,
		list = "shadowslist",
		check = "checkshadows",
		default = false,
		defaultbuff = false,
		defaultwarning = true,
		defaultdash = false,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = L["Shadow Resistance Aura AND Shadow Protection"],
		main = function(self, name, class, unit, raid, report)
			report.checking.shadows = true
			if unit.hasbuff[BS[19876] then -- Shadow Resistance Aura
				table.insert(report.shadowslist, name)
			end
		end,
		post = nil,
		icon = BSI[19876], -- Shadow Resistance Aura
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.shadowslist, RaidBuffStatus.db.profile.checkshadows, report.checking.shadows or false, nil)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "shadows", RaidBuffStatus:SelectPalaAura())
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Paladin has Shadow Resistance Aura AND Shadow Protection"], report.shadowslist)
		end,
		whispertobuff = nil,
		singlebuff = nil,
		partybuff = nil,
		raidbuff = nil,
	},
]]--
	
	health = {
		order = 970,
		list = "healthlist",
		check = "checkhealth",
		default = true,
		defaultbuff = false,
		defaultwarning = true,
		defaultdash = true,
		defaultdashcombat = true,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = L["Health less than 80%"],
		main = function(self, name, class, unit, raid, report)
			if not unit.isdead then
				if UnitHealth(unit.unitid)/UnitHealthMax(unit.unitid) < 0.8 then
					table.insert(report.healthlist, name)
				end
			end
		end,
		post = nil,
		icon = "Interface\\Icons\\INV_Potion_131",
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.healthlist, RaidBuffStatus.db.profile.checkhealth, true, report.healthlist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "health")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Player has health less than 80%"], report.healthlist)
		end,
		whispertobuff = nil,
		singlebuff = nil,
		partybuff = nil,
		raidbuff = nil,
	},

	mana = {
		order = 960,
		list = "manalist",
		check = "checkmana",
		default = true,
		defaultbuff = false,
		defaultwarning = true,
		defaultdash = true,
		defaultdashcombat = true,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = L["Mana less than 80%"],
		main = function(self, name, class, unit, raid, report)
			if unit.isdead then
				return
			end
			if UnitMana(unit.unitid)/UnitManaMax(unit.unitid) < 0.8 then
				table.insert(report.manalist, name)
			end
		end,
		post = nil,
		icon = "Interface\\Icons\\INV_Potion_137",
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.manalist, RaidBuffStatus.db.profile.checkmana, true, report.manalist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "mana")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Player has mana less than 80%"], report.manalist)
		end,
		whispertobuff = nil,
		singlebuff = nil,
		partybuff = nil,
		raidbuff = nil,
	},
	zone = {
		order = 950,
		list = "zonelist",
		check = "checkzone",
		default = true,
		defaultbuff = false,
		defaultwarning = true,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = true, -- actually has no effect
		selfbuff = false,
		timer = false,
		core = true,
		chat = L["Different Zone"],
		main = nil, -- done by main code
		post = nil,
		icon = "Interface\\Icons\\INV_Misc_QuestionMark",
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.zonelist, RaidBuffStatus.db.profile.checkzone, raid.israid, nil)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "zone")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Player is in a different zone"], nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, report.zonelist)
		end,
		whispertobuff = function(reportl, prefix)
			if not raid.leader or #reportl < 1 then
				return
			end
			if RaidBuffStatus.db.profile.WhisperMany and #reportl >= RaidBuffStatus.db.profile.HowMany then
				RaidBuffStatus:Say(prefix .. "<" .. RaidBuffStatus.BF.zone.chat .. ">: " .. L["MANY!"], raid.leader)
			else
				RaidBuffStatus:Say(prefix .. "<" .. RaidBuffStatus.BF.zone.chat .. ">: " .. table.concat(reportl, ", "), raid.leader)
			end
		end,
		singlebuff = nil,
		partybuff = nil,
		raidbuff = nil,
	},

	offline = {
		order = 940,
		list = "offlinelist",
		check = "checkoffline",
		default = true,
		defaultbuff = false,
		defaultwarning = true,
		defaultdash = true,
		defaultdashcombat = true,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = true, -- actualy has no effect
		selfbuff = false,
		timer = true,
		core = true,
		chat = L["Offline"],
		main = nil, -- done by main code
		post = nil,
		icon = "Interface\\Icons\\INV_Gizmo_FelStabilizer",
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.offlinelist, RaidBuffStatus.db.profile.checkoffline, true, nil)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "offline")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Player is Offline"], report.offlinelist, raid.BuffTimers.offlinetimerlist)
		end,
		whispertobuff = function(reportl, prefix)
			if not raid.leader or #reportl < 1 then
				return
			end
			if RaidBuffStatus.db.profile.WhisperMany and #reportl >= RaidBuffStatus.db.profile.HowMany then
				RaidBuffStatus:Say(prefix .. "<" .. RaidBuffStatus.BF.offline.chat .. ">: " .. L["MANY!"], raid.leader)
			else
				RaidBuffStatus:Say(prefix .. "<" .. RaidBuffStatus.BF.offline.chat .. ">: " .. table.concat(reportl, ", "), raid.leader)
			end
		end,
		singlebuff = nil,
		partybuff = nil,
		raidbuff = nil,
	},

	afk = {
		order = 930,
		list = "afklist",
		check = "checkafk",
		default = true,
		defaultbuff = false,
		defaultwarning = true,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = true,
		selfbuff = true,
		timer = true,
		chat = L["AFK"],
		main = function(self, name, class, unit, raid, report)
			if UnitIsAFK(unit.unitid) then
				table.insert(report.afklist, name)
			end
		end,
		post = nil,
		icon = "Interface\\Icons\\Trade_Fishing",
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.afklist, RaidBuffStatus.db.profile.checkafk, true, report.afklist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "afk")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Player is AFK"], report.afklist, raid.BuffTimers.afktimerlist)
		end,
		whispertobuff = nil,
		singlebuff = nil,
		partybuff = nil,
		raidbuff = nil,
	},

	dead = {
		order = 920,
		list = "deadlist",
		check = "checkdead",
		default = true,
		defaultbuff = false,
		defaultwarning = true,
		defaultdash = true,
		defaultdashcombat = true,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = true,
		selfbuff = false,
		timer = true,
		chat = L["Dead"],
		icon = "Interface\\Icons\\Spell_Holy_SenseUndead",
		main = function(self, name, class, unit, raid, report)
			if unit.isdead then
				table.insert(report.deadlist, name)
			end
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.deadlist, RaidBuffStatus.db.profile.checkdead, true, deadlist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "dead")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Player is Dead"], report.deadlist, raid.BuffTimers.deadtimerlist)
		end,
		singlebuff = false,
		partybuff = false,
		raidbuff = false
	},
	
	-- TODO who buffed
	cheetahpack = {
		order = 900,
		list = "cheetahpacklist",
		check = "checkcheetahpack",
		default = true,
		defaultbuff = false,
		defaultwarning = true,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		class = { HUNTER = true, },
		chat = L["Aspect Cheetah/Pack On"],
		main = function(self, name, class, unit, raid, report)
			report.checking.cheetahpack = true
			local hasbuff = false
			for _, v in ipairs(badaspects) do
				if unit.hasbuff[v] then
					hasbuff = true
					break
				end
			end
			if hasbuff then
				if RaidBuffStatus.db.profile.ShowGroupNumber then
					table.insert(report.cheetahpacklist, name .. "(" .. unit.group .. ")" )
				else
					table.insert(report.cheetahpacklist, name)
				end
			end
		end,
		post = function(self, raid, report)
			RaidBuffStatus:SortNameBySuffix(report.cheetahpacklist)
		end,
		icon = BSI[5118], -- Aspect of the Cheetah
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.cheetahpacklist, RaidBuffStatus.db.profile.checkcheetahpack, report.checking.cheetahpack or false, report.cheetahpacklist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "cheetahpack")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Aspect of the Cheetah or Pack is on"], report.cheetahpacklist)
		end,
		whispertobuff = nil,
		singlebuff = nil,
		partybuff = nil,
		raidbuff = nil,
	},

	oldflixir = {
		order = 895,
		list = "oldflixirlist",
		check = "checkoldflixir",
		default = true,
		defaultbuff = false,
		defaultwarning = true,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = false,
		defaulttrash = false,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = L["Flasked or Elixired but slacking"],
		main = function(self, name, class, unit, raid, report)
			for _, v in ipairs(tbcflasks) do
				if unit.hasbuff[v] then
					if RaidBuffStatus.db.profile.GoodTBC then
						for _, f in ipairs(RaidBuffStatus.wotlkgoodtbcflixirs) do
							if v == f then
								return
							end
						end
					end
					table.insert(report.oldflixirlist, name .. "(" .. v .. ")")
					return
				end
			end
			for _, v in ipairs(tbcbelixirs) do
				if unit.hasbuff[v] then
					if RaidBuffStatus.db.profile.GoodTBC then
						local found = false
						for _, f in ipairs(RaidBuffStatus.wotlkgoodtbcflixirs) do
							if v == f then
								found = true
								break
							end
						end
						if found then
							break
						end
					end
					table.insert(report.oldflixirlist, name .. "(" .. v .. ")")
					break
				end
			end
			for _, v in ipairs(tbcgelixirs) do
				if unit.hasbuff[v] then
					if RaidBuffStatus.db.profile.GoodTBC then
						local found = false
						for _, f in ipairs(RaidBuffStatus.wotlkgoodtbcflixirs) do
							if v == f then
								found = true
								break
							end
						end
						if found then
							break
						end
					end
					table.insert(report.oldflixirlist, name .. "(" .. v .. ")")
					return
				end
			end
		end,
		post = nil,
		icon = "Interface\\Icons\\INV_Potion_91",
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.oldflixirlist, RaidBuffStatus.db.profile.checkoldflixir, true, report.oldflixirlist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "oldflixir")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Flasked or Elixired but slacking"], report.oldflixirlist)
		end,
		whispertobuff = nil,
		singlebuff = nil,
		partybuff = nil,
		raidbuff = nil,
	},

	slackingfood = {
		order = 894,
		list = "slackingfoodlist",
		check = "checkslackingfood",
		default = true,
		defaultbuff = false,
		defaultwarning = true,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = false,
		defaulttrash = false,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = L["Well Fed but slacking"],
		main = function(self, name, class, unit, raid, report)
			local hasfood = false
			local slacking = false
			for _, v in ipairs(allfoods) do
				if unit.hasbuff[v] then
					hasfood = true
					break
				end
			end
			if hasfood then
				slacking = true
				if unit.hasbuff["foodz"] then
					if unit.hasbuff["foodz"]:find(L["Stamina increased by 40"]) then
						slacking = false
					end
				end
			end
			if slacking then
				table.insert(report.slackingfoodlist, name)
			end
		end,
		post = nil,
		icon = "Interface\\Icons\\INV_Misc_Food_67",
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.slackingfoodlist, RaidBuffStatus.db.profile.checkslackingfood, true, report.slackingfoodlist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "slackingfood")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Well Fed but slacking"], report.slackingfoodlist)
		end,
		partybuff = nil,
	},

	thorns = {
		order = 880,
		list = "thornslist",
		check = "checkthorns",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = false,
		checkzonedout = false,
		selfbuff = false,
		timer = false,
		chat = BS[26992],  -- Thorns
		buffsToCheck = { 26992 },
		main = function(self, name, class, unit, raid, report)
			report.checking.thorns = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.thorns.buffsToCheck, report.thornslist)
		end,
		post = nil,
		icon = BSI[26992],  -- Thorns
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.thornslist, RaidBuffStatus.db.profile.checkthorns, report.checking.thorns or false, RaidBuffStatus.BF.thorns:buffers())
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "thorns")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. "Thorns", report.thornslist, nil, RaidBuffStatus.BF.thorns:buffers())
		end,
		singlebuff = true,
		partybuff = false,
		raidbuff = false,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.thorns.buffsToCheck, raid.classes.DRUID)
		end,
	},

	food = {
		order = 500,
		list = "foodlist",
		check = "checkfood",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = false,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		core = true,
		class = { WARRIOR = true, ROGUE = true, PRIEST = true, DRUID = true, PALADIN = true, HUNTER = true, MAGE = true, WARLOCK = true, SHAMAN = true, DEATHKNIGHT = true, },
		chat = BS[35272], -- Well Fed
		main = function(self, name, class, unit, raid, report)
			local missingbuff = true
			if RaidBuffStatus.db.profile.GoodFoodOnly then
				if unit.hasbuff["foodz"] then
					if unit.hasbuff["foodz"]:find(L["Stamina increased by 40"]) then
						missingbuff = false
					end
				end
			else
				for _, v in ipairs(foods) do
					if unit.hasbuff[v] then
						missingbuff = false
						break
					end
				end
			end
			if missingbuff then
				table.insert(report.foodlist, name)
			end
		end,
		post = nil,
		icon = "Interface\\Icons\\INV_Misc_Food_74",
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.foodlist, RaidBuffStatus.db.profile.checkfood, true, report.foodlist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "food")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Not Well Fed"], report.foodlist)
		end,
		partybuff = nil,
	},
	flask = {
		order = 490,
		list = "flasklist",
		check = "checkflaskir",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = false,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		core = true,
		class = { WARRIOR = true, ROGUE = true, PRIEST = true, DRUID = true, PALADIN = true, HUNTER = true, MAGE = true, WARLOCK = true, SHAMAN = true, DEATHKNIGHT = true, },
		chat = L["Flask or two Elixirs"],
		pre = function(self, raid, report)
			report.belixirlist = {}
			report.gelixirlist = {}
			report.flaskzonelist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.flaskir = true
			local cflasks = wotlkflasks
			local cbelixirs = wotlkbelixirs
			local cgelixirs = wotlkgelixirs
			if RaidBuffStatus.db.profile.TBCFlasksElixirs then
				cflasks = allflasks
				cbelixirs = allbelixirs
				cgelixirs = allgelixirs
			elseif RaidBuffStatus.db.profile.GoodTBC then
				cflasks = wotlkgoodtbcflasks
				cbelixirs = wotlkgoodtbcbelixirs
				cgelixirs = wotlkgoodtbcgelixirs
			end
			local missingbuff = true
			for _, v in ipairs(cflasks) do
				if unit.hasbuff[v] then
					missingbuff = false
					-- has flask now check the zone
					if raid.israid then
						local thiszone = GetRealZoneText()
						local flaskmatched = false
						for _, types in pairs (flaskzones) do
							for _, flask in ipairs(types.flasks) do
								if flask == v then
									flaskmatched = true
									local zonematched = false
									for _, zone in ipairs(types.zones) do
										if thiszone == zone then
											zonematched = true
											break
										end
									end
									if not zonematched then
										table.insert(report.flaskzonelist, name .. "(" .. v .. ")")
									end
								break
								end
							end
							if flaskmatched then break end
						end
					end
					break
				end
			end
			if missingbuff then
				local numbbelixir = 0
				local numbgelixir = 0
				for _, v in ipairs(cbelixirs) do
					if unit.hasbuff[v] then
						numbbelixir = 1
						break
					end
				end
				for _, v in ipairs(cgelixirs) do
					if unit.hasbuff[v] then
						numbgelixir = 1
						break
					end
				end
				local totalelixir = numbbelixir + numbgelixir
				if totalelixir == 0 then
					table.insert(report.flasklist, name) -- no flask or elixir
				elseif totalelixir == 1 then
					if numbbelixir == 0 then
						table.insert(report.belixirlist, name)
					else
						table.insert(report.gelixirlist, name)
					end
				end
			end
		end,
		post = nil,
		icon = "Interface\\Icons\\INV_Potion_119",
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.flasklist, RaidBuffStatus.db.profile.checkflaskir, true, report.flasklist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "flask")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing a Flask or two Elixirs"], report.flasklist)
		end,
		partybuff = nil,
	},
	
	belixir = {
		order = 480,
		list = "belixirlist",
		check = "checkflaskir",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = false,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		core = true,
		class = { WARRIOR = true, ROGUE = true, PRIEST = true, DRUID = true, PALADIN = true, HUNTER = true, MAGE = true, WARLOCK = true, SHAMAN = true, DEATHKNIGHT = true, },
		chat = L["Battle Elixir"],
		pre = nil,
		main = nil,
		post = nil,
		icon = "Interface\\Icons\\INV_Potion_111",
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.belixirlist, RaidBuffStatus.db.profile.checkflaskir, true, report.belixirlist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "flask")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing a Battle Elixir"], report.belixirlist)
		end,
		partybuff = nil,
	},
	
	gelixir = {
		order = 470,
		list = "gelixirlist",
		check = "checkflaskir",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = false,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		core = true,
		class = { WARRIOR = true, ROGUE = true, PRIEST = true, DRUID = true, PALADIN = true, HUNTER = true, MAGE = true, WARLOCK = true, SHAMAN = true, DEATHKNIGHT = true, },
		chat = L["Guardian Elixir"],
		pre = nil,
		main = nil,
		post = nil,
		icon = "Interface\\Icons\\INV_Potion_158",
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.gelixirlist, RaidBuffStatus.db.profile.checkflaskir, true, report.gelixirlist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "flask")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing a Guardian Elixir"], report.gelixirlist)
		end,
		partybuff = nil,
	},

	flaskzone = {
		order = 465,
		list = "flaskzonelist",
		check = "checkflaskzone",
		default = false,
		defaultbuff = false,
		defaultwarning = true,
		defaultdash = false,
		defaultdashcombat = false,
		defaultboss = false,
		defaulttrash = false,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = L["Wrong flask for this zone"],
		pre = nil,
		main = nil,
		post = nil,
		icon = "Interface\\Icons\\INV_Potion_35",
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.flaskzonelist, RaidBuffStatus.db.profile.flaskzone, report.checking.flaskir or false, report.flaskzonelist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "flaskzone")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Wrong flask for this zone"], report.flaskzonelist)
		end,
		partybuff = nil,
	},
	
	---------------
	-- RaidBuffs --
	---------------
	
	kingsbuff = {
		order = 461,
		list = "nokingsbufflist",
		check = "checkkingsbuff",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = L["Blessing of Kings"],
		icon = BSI[25898], -- Blessing of Kings
		buffsToCheck = { 25898, 20217 },
		pre = function(self, raid, report)
			report.nokingsbufflist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.kingsbuff = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.kingsbuff.buffsToCheck, report.nokingsbufflist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.nokingsbufflist, RaidBuffStatus.db.profile.checkkingsbuff, report.checking.kingsbuff or false, report.nokingsbufflist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "kingsbuff")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. "Blessing of Kings", report.nokingsbufflist, nil, RaidBuffStatus.BF.kingsbuff:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.kingsbuff.buffsToCheck, raid.classes.DRUID)
		end
	},
	
	sanctuarybuff = {
		order = 460,
		list = "nosanctuarybufflist",
		check = "checksanctuarybuff",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = L["Blessing of Sanctuary"],
		icon = BSI[25899], -- Blessing of Sanctuary
		buffsToCheck = { 25899, 20911 },
		pre = function(self, raid, report)
			report.nosanctuarybufflist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.sanctuarybuff = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.sanctuarybuff.buffsToCheck, report.nosanctuarybufflist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.nosanctuarybufflist, RaidBuffStatus.db.profile.checksanctuarybuff, report.checking.sanctuarybuff or false, report.nosanctuarybufflist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "sanctuarybuff")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. "Blessing of Sanctuary", report.nosanctuarybufflist, nil, RaidBuffStatus.BF.sanctuarybuff:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.sanctuarybuff.buffsToCheck, raid.classes.DRUID)
		end
	},
	
	wisdombuff = {
		order = 459,
		list = "nowisdombufflist",
		check = "checkwisdombuff",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = L["Blessing of Wisdom"],
		icon = BSI[27143], -- Blessing of Wisdom
		buffsToCheck = { 27143, 27142 },
		pre = function(self, raid, report)
			report.nowisdombufflist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.wisdombuff = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.wisdombuff.buffsToCheck, report.nowisdombufflist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.nowisdombufflist, RaidBuffStatus.db.profile.checkwisdombuff, report.checking.wisdombuff or false, report.nowisdombufflist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "wisdombuff")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. "Blessing of Wisdom", report.nowisdombufflist, nil, RaidBuffStatus.BF.wisdombuff:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.wisdombuff.buffsToCheck, raid.classes.DRUID)
		end,
	},
	
	mightbuff = {
		order = 458,
		list = "nomightbufflist",
		check = "checkmightbuff",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = L["Blessing of Might/Battle Shout"],
		icon = BSI[27141], -- Blessing of Might
		buffsToCheck = { 27141, 27140, 2048 },
		pre = function(self, raid, report)
			report.nomightbufflist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.mightbuff = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.mightbuff.buffsToCheck, report.nomightbufflist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.nomightbufflist, RaidBuffStatus.db.profile.checkmightbuff, report.checking.mightbuff or false, report.nomightbufflist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "mightbuff")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. "Attack Power - (Blessing of Might, Battle Shout)", report.nomightbufflist, nil, RaidBuffStatus.BF.mightbuff:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.mightbuff.buffsToCheck, raid.classes.DRUID)
		end,
	},
	
	commandingshout = {
		order = 457,
		list = "nocommandingshoutlist",
		check = "checkcommandingshout",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = L["Commanding Shout/Blood Pact"],
		icon = BSI[469], -- Commanding Shout
		buffsToCheck = { 469, 27268 },
		pre = function(self, raid, report)
			report.nocommandingshoutlist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.commandingshout = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.commandingshout.buffsToCheck, report.nocommandingshoutlist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.nocommandingshoutlist, RaidBuffStatus.db.profile.checkcommandingshout, report.checking.commandingshout or false, report.nocommandingshoutlist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "commandingshout")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. "Health - (Commanding Shout, Blood Pact)", report.nocommandingshoutlist, nil, RaidBuffStatus.BF.commandingshout:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.commandingshout.buffsToCheck, raid.classes.DRUID)
		end
	},

	spirit = {
		order = 455,
		list = "spiritlist",
		check = "checkspirit",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = BS[14752], -- Divine Spirit
		icon = BSI[14752], -- Divine Spirit
		buffsToCheck = { 25312, 32999 },
		pre = function(self, raid, report)
			report.spiritlist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.spirit = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.spirit.buffsToCheck, report.spiritlist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.spiritlist, RaidBuffStatus.db.profile.checkspirit, report.checking.spirit or false, RaidBuffStatus.BF.spirit:buffers())
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "spirit")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. BS[14752], report.spiritlist, nil, RaidBuffStatus.BF.spirit:buffers()) -- Divine Spirit
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.spirit.buffsToCheck, raid.classes.DRUID)
		end,
	},
	
	intellect = {
		order = 450,
		list = "intellectlist",
		check = "checkintellect",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = BS[1459], -- Arcane Intellect
		icon = BSI[1459], -- Arcane Intellect
		buffsToCheck = { 27126, 27127 },
		pre = function(self, raid, report)
			report.intellectlist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.intellect = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.intellect.buffsToCheck, report.intellectlist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.intellectlist, RaidBuffStatus.db.profile.checkintellect, report.checking.intellect or false, report.intellectlist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "intellect")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. BS[1459], report.intellectlist, nil, RaidBuffStatus.BF.intellect:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.intellect.buffsToCheck, raid.classes.DRUID)
		end,
	},
	
	fortitude = {
		order = 440,
		list = "fortitudelist",
		check = "checkfortitude",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = BS[1243], -- Power Word: Fortitude
		icon = BSI[1243], -- Power Word: Fortitude
		buffsToCheck = { 25389, 25392 },
		pre = function(self, raid, report)
			report.fortitudelist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.fortitude = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.fortitude.buffsToCheck, report.fortitudelist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.fortitudelist, RaidBuffStatus.db.profile.checkfortitude, report.checking.fortitude or false, report.fortitudelist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "fortitude")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. BS[1243], report.fortitudelist, nil, RaidBuffStatus.BF.fortitude:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.fortitude.buffsToCheck, raid.classes.DRUID)
		end,
	},
	
	wild = {
		order = 430,
		list = "wildlist",
		check = "checkwild",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = BS[1126], -- Mark of the Wild
		icon = BSI[1126], -- Mark of the Wild
		buffsToCheck = { 26990, 26991 },
		pre = function(self, raid, report)
			report.wildlist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.wild = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.wild.buffsToCheck, report.wildlist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.wildlist, RaidBuffStatus.db.profile.checkwild, report.checking.wild or false, report.wildlist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "wild")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. BS[1126], report.wildlist, nil, RaidBuffStatus.BF.wild:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.wild.buffsToCheck, raid.classes.DRUID)
		end,
	},
	
	shadow = {
		order = 420,
		list = "shadowlist",
		check = "checkshadow",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = "Shadow Resistance", --BS[27151], -- Shadow Protection
		icon = BSI[976], -- Shadow Protection
		buffsToCheck = { 39374, 25433, 27151 },
		pre = function(self, raid, report)
			report.shadowlist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.shadow = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.shadow.buffsToCheck, report.shadowlist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.shadowlist, RaidBuffStatus.db.profile.checkshadow, report.checking.shadow or false, report.shadowlist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "shadow")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. "Shadow Resistance", report.shadowlist, nil, RaidBuffStatus.BF.shadow:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.shadow.buffsToCheck, raid.classes.DRUID)
		end,
	},
	
	fireaura = {
		order = 410,
		list = "nofireauralist",
		check = "checkfireaura",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = "Fire Resistance",
		icon = BSI[27153], -- Fire Resistance Aura
		buffsToCheck = { 27153, 25562 },
		pre = function(self, raid, report)
			report.nofireauralist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.fireaura = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.fireaura.buffsToCheck, report.nofireauralist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.nofireauralist, RaidBuffStatus.db.profile.checkfireaura, report.checking.fireaura or false, report.nofireauralist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "fireaura")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. "Fire Resistance", report.nofireauralist, nil, RaidBuffStatus.BF.fireaura:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.fireaura.buffsToCheck, raid.classes.DRUID)
		end,
	},
	
	frostaura = {
		order = 409,
		list = "nofrostauralist",
		check = "checkfrostaura",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = "Frost Resistance",
		icon = BSI[27152], -- Frost Resistance Aura
		buffsToCheck = { 27152, 25559 },
		pre = function(self, raid, report)
			report.nofrostauralist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.frostaura = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.frostaura.buffsToCheck, report.nofrostauralist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.nofrostauralist, RaidBuffStatus.db.profile.checkfrostaura, report.checking.frostaura or false, report.nofrostauralist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "frostaura")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. "Frost Resistance", report.nofrostauralist, nil, RaidBuffStatus.BF.frostaura:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.frostaura.buffsToCheck, raid.classes.DRUID)
		end,
	},
	
	natureaspect = {
		order = 408,
		list = "nonatureaspectlist",
		check = "checknatureaspect",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = L["Nature Resistance"],
		icon = BSI[27045], -- Aspect of the Wild
		buffsToCheck = { 27045, 25573 },
		pre = function(self, raid, report)
			report.natureaspectlist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.natureaspect = true
			-- Aspect of the Wild, Nature Resistance Totem
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.natureaspect.buffsToCheck, report.nonatureaspectlist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.nonatureaspectlist, RaidBuffStatus.db.profile.checknatureaspect, report.checking.natureaspect or false, report.nonatureaspectlist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "natureaspect")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. "Nature Resistance", report.nonatureaspectlist, nil, RaidBuffStatus.BF.natureaspect:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.natureaspect.buffsToCheck, raid.classes.DRUID)
		end,
	},
	
	devotionaura = {
		order = 400,
		list = "nodevotionauralist",
		check = "checkdevotionaura",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = L["Devotion Aura"],
		icon = BSI[465], -- Devotion Aura
		buffsToCheck = { 27149 },
		pre = function(self, raid, report)
			report.nodevotionauralist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.devotionaura = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.devotionaura.buffsToCheck, report.nodevotionauralist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.nodevotionauralist, RaidBuffStatus.db.profile.checkdevotionaura, report.checking.devotionaura or false, report.nodevotionauralist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "devotionaura")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. "Devotion Aura", report.nodevotionauralist, nil, RaidBuffStatus.BF.devotionaura:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.devotionaura.buffsToCheck, raid.classes.DRUID)
		end,
	},

	concentrationaura = {
		order = 399,
		list = "noconcentrationauralist",
		check = "checkconcentrationaura",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = L["Concentration Aura"],
		icon = BSI[19746], -- Concentration Aura
		buffsToCheck = { 19746 },
		pre = function(self, raid, report)
			report.noconcentrationauralist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.concentrationaura = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.concentrationaura.buffsToCheck, report.noconcentrationauralist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.noconcentrationauralist, RaidBuffStatus.db.profile.checkconcentrationaura, report.checking.concentrationaura or false, report.noconcentrationauralist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "concentrationaura")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. "Concentration Aura", report.noconcentrationauralist, nil, RaidBuffStatus.BF.concentrationaura:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.concentrationaura.buffsToCheck, raid.classes.DRUID)
		end,
	},
	
	retributionaura = {
		order = 398,
		list = "noretributionauralist",
		check = "checkretributionaura",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = L["Retribution Aura"],
		icon = BSI[27150], -- Retribution Aura
		buffsToCheck = { 27150 },
		pre = function(self, raid, report)
			report.noretributionauralist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.retributionaura = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.retributionaura.buffsToCheck, report.noretributionauralist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.noretributionauralist, RaidBuffStatus.db.profile.checkretributionaura, report.checking.retributionaura or false, report.noretributionauralist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "retributionaura")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. BS[27150], report.noretributionauralist, nil, RaidBuffStatus.BF.retributionaura:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.retributionaura.buffsToCheck, raid.classes.DRUID)
		end,
	},
	
	totemstrengthofearth = {
		order = 395,
		list = "nototemstrengthofearthlist",
		check = "checktotemstrengthofearth",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = L["Strength of Earth Totem"],
		icon = BSI[25527], -- Strength of Earth Totem
		buffsToCheck = { 25527 },
		pre = function(self, raid, report)
			report.nototemstrengthofearthlist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.totemstrengthofearth = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.totemstrengthofearth.buffsToCheck, report.nototemstrengthofearthlist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.nototemstrengthofearthlist, RaidBuffStatus.db.profile.checktotemstrengthofearth, report.checking.totemstrengthofearth or false, report.nototemstrengthofearthlist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "totemstrengthofearth")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. "Strength of Earth Totem", report.nototemstrengthofearthlist, nil, RaidBuffStatus.BF.totemstrengthofearth:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.totemstrengthofearth.buffsToCheck, raid.classes.DRUID)
		end
	},
	
	totemwindfury = {
		order = 394,
		list = "nototemwindfurylist",
		check = "checktotemwindfury",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = L["Wind Fury Totem"],
		icon = BSI[8512], -- Wind Fury Totem
		buffsToCheck = { 8512 },
		pre = function(self, raid, report)
			report.nototemwindfurylist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.totemwindfury = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.totemwindfury.buffsToCheck, report.nototemwindfurylist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.nototemwindfurylist, RaidBuffStatus.db.profile.checktotemwindfury, report.checking.totemwindfury or false, report.nototemwindfurylist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "totemwindfury")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. "Windfury Totem", report.nototemwindfurylist, nil, RaidBuffStatus.BF.totemwindfury:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.totemwindfury.buffsToCheck, raid.classes.DRUID)
		end
	},
	
	totemstoneskin = {
		order = 393,
		list = "nototemstoneskinlist",
		check = "checktotemstoneskin",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = L["Stoneskin Totem"],
		icon = BSI[25507], -- Stoneskin Totem
		buffsToCheck = { 25507 },
		pre = function(self, raid, report)
			report.nototemstoneskinlist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.totemstoneskin = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.totemstoneskin.buffsToCheck, report.nototemstoneskinlist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.nototemstoneskinlist, RaidBuffStatus.db.profile.checktotemstoneskin, report.checking.totemstoneskin or false, report.nototemstoneskinlist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "totemstoneskin")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. "Stoneskin Totem", report.nototemstoneskinlist, nil, RaidBuffStatus.BF.totemstoneskin:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.totemstoneskin.buffsToCheck, raid.classes.DRUID)
		end
	},
	
	totemflametongue = {
		order = 392,
		list = "nototemflametonguelist",
		check = "checktotemflametongue",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = "Flametongue Totem/Totem of Wrath",
		icon = BSI[25557], -- Flame Tongue
		buffsToCheck = { 25557, 57721 },
		pre = function(self, raid, report)
			report.nototemflametonguelist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.totemflametongue = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.totemflametongue.buffsToCheck, report.nototemflametonguelist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.nototemflametonguelist, RaidBuffStatus.db.profile.checktotemflametongue, report.checking.totemflametongue or false, report.nototemflametonguelist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "totemflametongue")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. "Spellpower - (Flametongue Totem, Totem of Wrath)", report.nototemflametonguelist, nil, RaidBuffStatus.BF.totemflametongue:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.totemflametongue.buffsToCheck, raid.classes.DRUID)
		end
	},

	trueshotaura = {
		order = 390,
		list = "trueshotauralist",
		check = "checktrueshotaura",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = "5% attack power", --BS[19506], -- Trueshot Aura
		icon = BSI[19506], -- Trueshot Aura
		buffsToCheck = { 19506, 30802 },
		pre = function(self, raid, report)
			report.trueshotauralist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.trueshotaura = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.trueshotaura.buffsToCheck, report.trueshotauralist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.trueshotauralist, RaidBuffStatus.db.profile.checktrueshotaura, report.checking.trueshotaura or false, report.trueshotauralist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "trueshotaura", BS[19506]) -- Trueshot Aura
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. "5% Attack Power - (Trueshot Aura, Unleashed Rage)", report.trueshotauralist, nil, RaidBuffStatus.BF.trueshotaura:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.trueshotaura.buffsToCheck, raid.classes.DRUID)
		end,
	},

	rampage = {
		order = 389,
		list = "rampagelist",
		check = "checkrampage",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = "5% melee/ranged crit ", --BS[29801], -- Rampage, Leader of the Pack
		icon = BSI[29801],
		buffsToCheck = { 29801, 17007, 24932 },
		pre = function(self, raid, report)
			report.rampagelist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.rampage = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.rampage.buffsToCheck, report.rampagelist)
		end,
		post = nil,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.rampagelist, RaidBuffStatus.db.profile.checkrampage, report.checking.rampage or false, report.rampagelist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "rampage", BS[29801])
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. "5% melee and ranged crit - (Rampage, Leader of the Pack)", report.rampagelist, nil, RaidBuffStatus.BF.rampage:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.rampage.buffsToCheck, raid.classes.DRUID)
		end,
	},
	
	moonkinaura = {
		order = 375,
		list = "nomoonkinauralist",
		check = "checkmoonkinaura",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = "Spell Crit (3%)",
		icon = BSI[24858], -- Moonkin Aura
		buffsToCheck = { 24858, 57721, 51471 },
		pre = function(self, raid, report)
			report.nomoonkinauralist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.moonkinaura = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.moonkinaura.buffsToCheck, report.nomoonkinauralist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.nomoonkinauralist, RaidBuffStatus.db.profile.checkmoonkinaura, report.checking.moonkinaura or false, report.nomoonkinauralist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "moonkinaura")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. "Spell Crit (3%) - (Moonkin Aura, Elemental Oath, Totem of Wrath)", report.nomoonkinauralist, nil, RaidBuffStatus.BF.moonkinaura:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.moonkinaura.buffsToCheck, raid.classes.DRUID)
		end
	},
	
	totemwrathofair = {
		order = 374,
		list = "nototemwrathofairlist",
		check = "checktotemwrathofair",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = "Spell Haste (3%)",
		icon = BSI[3738], -- Wrath of Air Totem
		buffsToCheck = { 3738, 50172, 853648 },
		pre = function(self, raid, report)
			report.nototemwrathofairlist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.totemwrathofair = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.totemwrathofair.buffsToCheck, report.nototemwrathofairlist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.nototemwrathofairlist, RaidBuffStatus.db.profile.checktotemwrathofair, report.checking.totemwrathofair or false, report.nototemwrathofairlist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "totemwrathofair")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. "Spell Haste (3%) - (Wrath of Air Totem, Moonkin's Presence, Swift Retribution)", report.nototemwrathofairlist, nil, RaidBuffStatus.BF.totemwrathofair:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.totemwrathofair.buffsToCheck, raid.classes.DRUID)
		end
	},
	
	ferociousinspiration = {
		order = 373,
		list = "noferociousinspirationlist",
		check = "checkferociousinspiration",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = "All Damage (3%)",
		icon = BSI[75447], -- Ferocious Inspiration
		buffsToCheck = { 75447, 731583, 731871 },
		pre = function(self, raid, report)
			report.noferociousinspirationlist = {}
		end,
		main = function(self, name, class, unit, raid, report)
			report.checking.ferociousinspiration = true
			RaidBuffStatus:UpdateNoBuffList(name, unit.hasbuff, RaidBuffStatus.BF.ferociousinspiration.buffsToCheck, report.noferociousinspirationlist)
		end,
		update = function(self)
			RaidBuffStatus:DefaultButtonUpdate(self, report.noferociousinspirationlist, RaidBuffStatus.db.profile.checkferociousinspiration, report.checking.ferociousinspiration or false, report.noferociousinspirationlist)
		end,
		click = function(self, button, down)
			RaidBuffStatus:ButtonClick(self, button, down, "ferociousinspiration")
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, L["Missing "] .. "All Damage (3%) - (Ferocious Inspiration, Arcane Empowerment, Sanctified Retribution)", report.noferociousinspirationlist, nil, RaidBuffStatus.BF.ferociousinspiration:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.ferociousinspiration.buffsToCheck, raid.classes.DRUID)
		end
	},
	
	totemmanaspring = {
		order = 200,
		list = "none",
		check = "checktotemmanaspring",
		default = true,
		defaultbuff = false,
		defaultwarning = true,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = true,
		checkzonedout = false,
		selfbuff = true,
		timer = false,
		chat = "Slacking with Mana Spring",
		icon = BSI[25569], -- Mana Spring Totem
		buffsToCheck = { 25569, 10497, 10496, 10495, 5675 },
		main = nil,
		update = function(self)
			local slackers = RaidBuffStatus.BF.totemmanaspring:buffers()
			if #slackers > 0 then
				self.count:SetText(#slackers)
				self.count:SetTextColor(RED_FONT_COLOR.r, RED_FONT_COLOR.g, RED_FONT_COLOR.b)
			else
				self.count:SetText("0")
			end
		end,
		click = function(self, button, down)
			local slackers = RaidBuffStatus.BF.totemmanaspring:buffers()
			if #slackers > 0 then
				local slackersstring = table.concat(RaidBuffStatus.BF.totemmanaspring:buffers(), ", ")
				RaidBuffStatus:Say("Slacking with Mana Spring: "..slackersstring)
			end
		end,
		tip = function(self)
			RaidBuffStatus:Tooltip(self, "Slacking with Mana Spring", RaidBuffStatus.BF.totemmanaspring:buffers())
		end,
		partybuff = nil,
		buffers = function()
			return RaidBuffStatus:GetBuffCasters(RaidBuffStatus.BF.totemmanaspring.buffsToCheck, raid.classes.DRUID)
		end
	},
	
	help20090704 = {
		order = 10,
		list = "none",
		check = "checkhelp20090704",
		default = true,
		defaultbuff = true,
		defaultwarning = false,
		defaultdash = true,
		defaultdashcombat = false,
		defaultboss = true,
		defaulttrash = false,
		checkzonedout = false,
		selfbuff = false,
		timer = false,
		chat = nil,
		pre = nil,
		main = nil,
		post = nil,
		icon = "Interface\\Icons\\Mail_GMIcon",
		update = function(self)
			self.count:SetText("")
		end,
		click = nil,
		tip = function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetText(L["RBS Dashboard Help"],1,1,1)
			GameTooltip:AddLine(L["Click buffs to disable and enable."],nil,nil,nil)
			GameTooltip:AddLine(L["Shift-Click buffs to report on only that buff."],nil,nil,nil)
			GameTooltip:AddLine(L["Ctrl-Click buffs to whisper those who need to buff."],nil,nil,nil)
			GameTooltip:AddLine(L["Alt-Click on a self buff will renew that buff."],nil,nil,nil)
			GameTooltip:AddLine(L["Alt-Click on a party buff will cast on someone missing that buff."],nil,nil,nil)
			GameTooltip:AddLine(" ",nil,nil,nil)
			GameTooltip:AddLine(L["Remove this button from this dashboard in the buff options window."],nil,nil,nil)
			GameTooltip:AddLine(" ",nil,nil,nil)
			GameTooltip:AddLine(L["The above default button actions can be reconfigured."],nil,nil,nil)
			GameTooltip:AddLine(L["Press Escape -> Interface -> AddOns -> RaidBuffStatus for more options."],nil,nil,nil)
			GameTooltip:AddLine(" ",nil,nil,nil)
			GameTooltip:AddLine(L["Ctrl-Click Boss or Trash to whisper all those who need to buff."],nil,nil,nil)
			GameTooltip:Show()
		end,
		partybuff = nil,
	},
}

RaidBuffStatus.BF = BF
