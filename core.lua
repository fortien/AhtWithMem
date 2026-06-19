local f=CreateFrame("Frame")
f:RegisterEvent("START_TIMER")

local function detectArenaHealer(switchDDs)
	print("arena mode started")
	
	local specID1, _ = GetArenaOpponentSpec(1)
	if specID1 == nil then
		_G["ahtTimerInProgress"] = false
		print("arena mode finished with error not enough enemy players info")	
		tabForWorld()
		return 
	end
	local _, name1, _, _, role1, class1, _ = GetSpecializationInfoByID(specID1)
	print("class1: "..class1..", spec1: "..name1)
	
	local specID2, _ = GetArenaOpponentSpec(2)
	if specID2 == nil then
		_G["ahtTimerInProgress"] = false
		print("arena mode finished with error not enough enemy players info")
		tabForWorld()
		return 
	end
	local _, name2, _, _, role2, class2, _ = GetSpecializationInfoByID(specID2)
	print("class2: "..class2..", spec2: "..name2)
	
	local rogueTarget, rogueArenaNum
	
	local specID3, _ = GetArenaOpponentSpec(3)
	local name3, role3, class3
	if specID3 ~= nil then 
		_, name3, _, _, role3, class3, _ = GetSpecializationInfoByID(specID3) 
		print("class3: "..class3..", spec3: "..name3)
		if class3 == "ROGUE" then
			rogueTarget = name3
			rogueArenaNum = "arena3"
		end
	end
	
	--looking for stealther
	if class1 == "ROGUE" then
		rogueTarget = name1
		rogueArenaNum = "arena1"
	elseif class2 == "ROGUE" then 
		rogueTarget = name2
		rogueArenaNum = "arena2"
	end
		
	local healerRole = "HEALER"
	
	local healerTargetLocal = "focus"
	local mainTarget = "arena1"
	local focusTarget = "arena2"
	if role1 == healerRole then
		healerTargetLocal = "arena1"
		mainTarget = "arena2"
		focusTarget = "arena3"
	elseif role2 == healerRole then 
		healerTargetLocal = "arena2"
		mainTarget = "arena1"
		focusTarget = "arena3"			
	elseif role3 == healerRole then
		healerTargetLocal = "arena3"
		mainTarget = "arena1"
		focusTarget = "arena2"	
	end
	
	
	if healerTargetLocal == "focus" then
		print("2s vs 2dd")
		mainTarget = "arena1"
		focusTarget = "arena2"
		if rogueTarget ~= nil then
			print("with rog")
			mainTarget = rogueArenaNum
			if mainTarget == focusTarget then
				focusTarget = "arena1"
			end
		end
	end
	
	if role3 == nil and not(healerTargetLocal == "focus") then
		print("2s vs healdd")
		focusTarget = healerTargetLocal
	end
	
	
	local sapMacro = "/target "..mainTarget.."\n/cast Sap"
	ReplaceMacroBody("lfrog", sapMacro)
	if rogueTarget ~= nil then
		print("found rog(feral,hunt?) = "..rogueTarget..rogueArenaNum)
		ReplaceMacroBody("lfrog", "/target "..rogueArenaNum.."\n/cast Sap")
	end
	
	
	if switchDDs == true then
		local tmp = mainTarget
		mainTarget = focusTarget
		focusTarget = tmp
	end		
	
	local fd, fh
	if UnitGroupRolesAssigned("party1") == "DAMAGER" then
		fd = "party1"
		fh = "party2"
	else 
		fd = "party2"
		fh = "party1"
	end
	
	print("fd =", fd, "fh =", fh)
	print("healerTarget =", healerTargetLocal)
	print("mainTarget =", mainTarget, "focusTarget =", focusTarget)

	EditAhtMacro(healerTargetLocal, mainTarget, focusTarget, "focus", fd, fh)

	_G["ahtTimerInProgress"] = false
	--print("classes: "..class1..class2..class3)
	print("arena mode finished")
end

function tabForWorld()
	print("tab for world")
	ReplaceMacroBody("tab", "/targetenemyplayer")
	ReplaceMacroBody("sTab", "/target [@focus]\n/targetlasttarget\n/focus\n/targetlasttarget")
end	

local function detectBattlegroundHealers()
	RequestBattlefieldScoreData()
	C_Timer.After(1, function() 
		print("bg mode started")
		
		tabForWorld()
		print("tab for world chosen")

		local numBattlefieldScores = GetNumBattlefieldScores()
		print("numBattlefieldScores =", numBattlefieldScores)
		
		local name, realm = UnitFullName("player")
		print("playerName & realm = "..name.."-"..realm)
		local playerFullName = name.."-"..realm
		local playerFaction = 0
		
		for i = 1, numBattlefieldScores, 1 do
			local info = C_PvP.GetScoreInfo(i)
			print("info name "..i.." = "..info.name)
			if info.name == playerFullName or info.name == name then
				playerFaction = info.faction
				print("playerFaction = "..playerFaction)
				break
			end
		end
		
		local healer1 = "focus"
		local healer2 = "focus"
		local healersCount = 0
		for i = 1, numBattlefieldScores, 1 do
			local info = C_PvP.GetScoreInfo(i)
			if info.faction ~= playerFaction and info.roleAssigned == 4 then
				healersCount = healersCount + 1
				if healersCount == 1 then
					healer1 = info.name
				else
					healer2 = info.name
				end
				print(i, info.name, "faction = ", info.faction, info.talentSpec, "roleAssigned = ", info.roleAssigned)
				if healersCount == 2 then break end
			end
		end
		
		if healersCount == 0 then
			print("healersCount =", healersCount)
		else
			print("healer1 =", healer1)
			print("healer2 =", healer2)
			
			local healer1Name, healer1Realm = healer1:match("([^-]+)-([^-]+)")
			local healer2Name, healer2Realm = healer2:match("([^-]+)-([^-]+)")
			
			--WeakAurasSaved["healer1FullNameG"] = healer1
			--WeakAurasSaved["healer2FullNameG"] = healer2
			EditAhtMacro(healer1, "target", "focus", healer2, "party1", "party2")
		end

		
		_G["ahtTimerInProgress"] = false
		print("bg mode finished")
	end)
end

local function MemUnit(name)
	_G["ahtTimerInProgress"] = false
	print("memUnit started")
	EditMemMacro(name)
	--_G["ahtTimerInProgress"] = false
end

local function MemTarget()
    _G["ahtTimerInProgress"] = false
	print("memTarget started")
	local name = "none"
	if UnitExists("target") then
		name = UnitName("target")
	end
	EditMemMacro(name)
end

local function MemMouseover()
    _G["ahtTimerInProgress"] = false
	print("memMouseover started")
	local name = "none"
	if UnitExists("mouseover") then
		name = UnitName("mouseover")
	end
	EditMemMacro(name)
end

memTarget = ""

function EditMemMacro(memUnit)
	-- Start at the end, and move backward to first position (121).
	memTarget = memUnit
	--f:RegisterEvent("MEM_UNIT")
	for i = 120 + select(2,GetNumMacros()), 121, -1 do
		local name, icon, body = GetMacroInfo(i)
		if string.sub(name, 1, 1) == "$" and not(name=="$sTab") and not(name=="$tab") and not(name=="$lfrog") then
			local replaced, _ = string.gsub(body, "(!mem)", memUnit)
			local nameWithoutPrefix, _ = string.sub(name, 2)
			local existedName, existedIcon, _ = GetMacroInfo(nameWithoutPrefix)
			if existedName == nil then
				CreateMacro(nameWithoutPrefix, icon, replaced, nil)
			else
				EditMacro(existedName, nil, nil, replaced)
			end
		end
	end
	print("Mem "..memUnit)
end

function EditAhtMacro(healerTargetLocal, firstDpsTarget, secondDpsTarget, focusTarget, fd, fh)
	--print("editAhtMacro started")
	-- Start at the end, and move backward to first position (121).
	for i = 120 + select(2,GetNumMacros()), 121, -1 do
		local name, icon, body = GetMacroInfo(i)
		if string.sub(name, 1, 1) == "$" and not(name=="$lfrog") then
			local bodyWithHealerTargetReplaced, _ = string.gsub(body, "(!mem)", healerTargetLocal)
			local bodyWithFirstDpsTargetReplaced, _ = string.gsub(bodyWithHealerTargetReplaced, "(!mt)", firstDpsTarget)
			local bodyWithSecondDpsTargetReplaced, _ = string.gsub(bodyWithFirstDpsTargetReplaced, "(!st)", secondDpsTarget)
			local bodyWithFocusTargetReplaced, _ = string.gsub(bodyWithSecondDpsTargetReplaced, "(!ft)", focusTarget)
			local bodyWithFriendDdReplaced, _ = string.gsub(bodyWithFocusTargetReplaced, "(!fd)", fd)
			local bodyWithFriendHealReplaced, _ = string.gsub(bodyWithFriendDdReplaced, "(!fh)", fh)
			local bodyWithAnchorsReplaced = bodyWithFriendHealReplaced
			local nameWithoutPrefix, _ = string.sub(name, 2)
			local existedName, existedIcon, _ = GetMacroInfo(nameWithoutPrefix)
			if existedName == nil then
				CreateMacro(nameWithoutPrefix, icon, bodyWithAnchorsReplaced, nil)
			else
				EditMacro(existedName, nil, nil, bodyWithAnchorsReplaced)
			end
		end
	end
end

function ReplaceMacroBody(macroName, newBody)
	--print("ReplaceMacroBody started")
	-- Start at the end, and move backward to first position (121).
	for i = 120 + select(2,GetNumMacros()), 121, -1 do
		local name, icon, body = GetMacroInfo(i)
		if name == "$"..macroName then
			local existedName, existedIcon, _ = GetMacroInfo(macroName)
			--print("ReplaceMacroBody for "..macroName)
			--print("Body "..newBody)
			if existedName == nil then
				CreateMacro(macroName, icon, newBody, nil)
			else
				EditMacro(existedName, nil, nil, newBody)
			end
		end
	end
end

local function OnEvent(self, event, arg1, arg2, arg3, ...)
	if arg2 < 11 then
		print("AHT will not start, timer is less than 11 sec")
		return
	end
	
	if _G["ahtTimerInProgress"] == true then
		return
	end
	
	_G["ahtTimerInProgress"] = true

	local isArena, isRegistered = IsActiveBattlefieldArena()
	
	local delayInSeconds = arg2-10
    print("AHT info event handled, will start after "..delayInSeconds.." sec")
	if isArena then
		C_Timer.After(delayInSeconds, detectArenaHealer)
	else
		C_Timer.After(delayInSeconds, detectBattlegroundHealers)
	end	
end 

f:SetScript("OnEvent", OnEvent)
SLASH_AHTR1 = '/ahtr'
SLASH_AHT1 = '/aht'
SLASH_AHTSM1 = '/ahtsm'
SLASH_AHTBG1 = '/ahtbg'
SLASH_AHTW1 = '/ahtw'
SLASH_MEM1 = '/mem'
SLASH_MEMT1 = '/memt'
SLASH_MEMMO1 = '/memmo'


function SlashCmdList.AHTR(msg, editBox)
	_G["ahtTimerInProgress"] = false
	print("timer reset")
end

function SlashCmdList.AHT(msg, editBox)
	if _G["ahtTimerInProgress"] == true then
		print("AHT will not start, timer is already in progress")
		return
	end
    detectArenaHealer(false)
end

function SlashCmdList.AHTSM(msg, editBox)
	if _G["ahtTimerInProgress"] == true then
		print("AHT will not start, timer is already in progress")
		return
	end
    detectArenaHealer(true)
end

function SlashCmdList.AHTBG(msg, editBox)
	if _G["ahtTimerInProgress"] == true then
		print("AHT will not start, timer is already in progress")
		return
	end
    detectBattlegroundHealers()
end

function SlashCmdList.AHTW(msg, editBox)
	tabForWorld()
end

function SlashCmdList.MEM(msg, editBox)
	if _G["ahtTimerInProgress"] == true then
		print("AHT will not start, timer is already in progress")
		return
	end
	MemUnit(msg)
	return
end

function SlashCmdList.MEMT(msg, editBox)
	if _G["ahtTimerInProgress"] == true then
		print("AHT will not start, timer is already in progress")
		return
	end
	MemTarget()
	return
end

function SlashCmdList.MEMMO(msg, editBox)
	if _G["ahtTimerInProgress"] == true then
		print("AHT will not start, timer is already in progress")
		return
	end
	MemMouseover()
	return
end
