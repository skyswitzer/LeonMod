
-- Author: EnormousApplePie & Lek10 & Leon

--=================================================================================================================
--=================================================================================================================
						-- GLOBALS (from JFD)
--=================================================================================================================
--=================================================================================================================

local g_ConvertTextKey  		= Locale.ConvertTextKey
local g_MapGetPlot				= Map.GetPlot
local g_MathCeil				= math.ceil
local g_MathFloor				= math.floor
local g_MathMax					= math.max
local g_MathMin					= math.min

include("PlotIterators")
include("FLuaVector.lua")

--=================================================================================================================
--=================================================================================================================
						--PRACTICAL FUNCTIONS (Eg: Calculations, random, optimizations, utils)
--=================================================================================================================
--=================================================================================================================

-- GetRandom number
function GetRandom(lower, upper)
        return Game.Rand((upper + 1) - lower, "") + lower
 end
--Game_GetRound (from JFD)
function Game_GetRound(num, idp)
	local mult = 10^(idp or 0)
	return g_MathFloor(num * mult + 0.5) / mult
end
local g_GetRound = Game_GetRound


--IscivActive (from JFD)
local iPracticalNumCivs = (GameDefines.MAX_MAJOR_CIVS - 1)

function JFD_IsCivilisationActive(civilizationID)
	for iSlot = 0, iPracticalNumCivs, 1 do
		local slotStatus = PreGame.GetSlotStatus(iSlot)
		if (slotStatus == SlotStatus["SS_TAKEN"] or slotStatus == SlotStatus["SS_COMPUTER"]) then
			if PreGame.GetCivilization(iSlot) == civilizationID then
				return true
			end
		end
	end
	return false
end

function JFD_GetNumDomesticRoutesFromThisCity(player, city) -- for both Sea and Land
	local tradeRoutes = player:GetTradeRoutes()
	local numDomesticRoutes = 0
	for tradeRouteID, tradeRoute in ipairs(tradeRoutes) do
		local domain = tradeRoute.Domain
		local originatingCity = tradeRoute.FromCity
		local targetCity = tradeRoute.ToCity
		if targetCity and originatingCity == city then
			numDomesticRoutes = numDomesticRoutes + 1
		end
	end
	
	return numDomesticRoutes
end

-- Returns true if this player now has this policy tree completed
function IsNowComplete(player, newPolicyId, allPolicyIds)
	for _, policyId in ipairs(allPolicyIds) do
		if(not player:HasPolicy(policyId) and newPolicyId ~= policyId) then
			return false; -- they are missing a policy
		end
	end
	return true; -- they have all the policies
end

--=================================================================================================================
--=================================================================================================================
--		Event Handling	
--=================================================================================================================
--=================================================================================================================
--[[
 229509: 			<Type>POLICY_BRANCH_LIBERTY</Type> 
209245: 			<Type>POLICY_LIBERTY</Type> 
 209405: 			<Type>POLICY_COLLECTIVE_RULE</Type> 
 209566: 			<Type>POLICY_CITIZENSHIP</Type> 
 209727: 			<Type>POLICY_REPUBLIC</Type> 
 209888: 			<Type>POLICY_REPRESENTATION</Type> 
 210049: 			<Type>POLICY_MERITOCRACY</Type> 
 216156: 			<Type>POLICY_LIBERTY_FINISHER</Type> 

 229491: 			<Type>POLICY_BRANCH_TRADITION</Type> 
 210210: 			<Type>POLICY_TRADITION</Type> 
 210370: 			<Type>POLICY_ARISTOCRACY</Type> 
 210531: 			<Type>POLICY_OLIGARCHY</Type> 
 210692: 			<Type>POLICY_LEGALISM</Type> 
 210853: 			<Type>POLICY_LANDED_ELITE</Type> 
 211014: 			<Type>POLICY_MONARCHY</Type> 
 216000: 			<Type>POLICY_TRADITION_FINISHER</Type> 

 229527: 			<Type>POLICY_BRANCH_HONOR</Type> 
 211175: 			<Type>POLICY_HONOR</Type> 
 211335: 			<Type>POLICY_WARRIOR_CODE</Type> 
 211496: 			<Type>POLICY_DISCIPLINE</Type> 
 211657: 			<Type>POLICY_MILITARY_TRADITION</Type> 
 211818: 			<Type>POLICY_MILITARY_CASTE</Type> 
 211979: 			<Type>POLICY_PROFESSIONAL_ARMY</Type> 
 216312: 			<Type>POLICY_HONOR_FINISHER</Type>

 229545: 			<Type>POLICY_BRANCH_PIETY</Type> 
 212140: 			<Type>POLICY_PIETY</Type> 
 212300: 			<Type>POLICY_ORGANIZED_RELIGION</Type> 
 212461: 			<Type>POLICY_MANDATE_OF_HEAVEN</Type> 
 212622: 			<Type>POLICY_THEOCRACY</Type> 
 212783: 			<Type>POLICY_REFORMATION</Type> 
 212944: 			<Type>POLICY_FREE_RELIGION</Type> 
 216468: 			<Type>POLICY_PIETY_FINISHER</Type> 

 229563: 			<Type>POLICY_BRANCH_PATRONAGE</Type> 
 213105: 			<Type>POLICY_PATRONAGE</Type> 
 213265: 			<Type>POLICY_PHILANTHROPY</Type> 
 213426: 			<Type>POLICY_CONSULATES</Type> 
 213587: 			<Type>POLICY_SCHOLASTICISM</Type> 
 213748: 			<Type>POLICY_CULTURAL_DIPLOMACY</Type> 
 213909: 			<Type>POLICY_MERCHANT_CONFEDERACY</Type> 
 216625: 			<Type>POLICY_PATRONAGE_FINISHER</Type> 

 229601: 			<Type>POLICY_BRANCH_COMMERCE</Type> 
 214070: 			<Type>POLICY_COMMERCE</Type> 
 214230: 			<Type>POLICY_TRADE_UNIONS</Type> 
 214391: 			<Type>POLICY_ENTREPRENEURSHIP</Type> 
 214552: 			<Type>POLICY_MERCANTILISM</Type> 
 214713: 			<Type>POLICY_CARAVANS</Type> 
 214874: 			<Type>POLICY_PROTECTIONISM</Type> 
 216781: 			<Type>POLICY_COMMERCE_FINISHER</Type> 

 229639: 			<Type>POLICY_BRANCH_RATIONALISM</Type> 
 215035: 			<Type>POLICY_RATIONALISM</Type> 
 215195: 			<Type>POLICY_SECULARISM</Type> 
 215356: 			<Type>POLICY_HUMANISM</Type> 
 215517: 			<Type>POLICY_FREE_THOUGHT</Type> 
 215678: 			<Type>POLICY_SOVEREIGNTY</Type> 
 215839: 			<Type>POLICY_SCIENTIFIC_REVOLUTION</Type> 
 216937: 			<Type>POLICY_RATIONALISM_FINISHER</Type> 
 

 229582: 			<Type>POLICY_BRANCH_AESTHETICS</Type> 
 217093: 			<Type>POLICY_AESTHETICS</Type> 
 217253: 			<Type>POLICY_CULTURAL_CENTERS</Type> 
 217414: 			<Type>POLICY_FINE_ARTS</Type> 
 217575: 			<Type>POLICY_FLOURISHING_OF_ARTS</Type> 
 217736: 			<Type>POLICY_ARTISTIC_GENIUS</Type> 
 217897: 			<Type>POLICY_ETHICS</Type> 
 218058: 			<Type>POLICY_AESTHETICS_FINISHER</Type> 

 229620: 			<Type>POLICY_BRANCH_EXPLORATION</Type> 
 218214: 			<Type>POLICY_EXPLORATION</Type> 
 218374: 			<Type>POLICY_MARITIME_INFRASTRUCTURE</Type> 
 218535: 			<Type>POLICY_NAVAL_TRADITION</Type> 
 218696: 			<Type>POLICY_MERCHANT_NAVY</Type> 
 218857: 			<Type>POLICY_NAVIGATION_SCHOOL</Type> 
 219018: 			<Type>POLICY_TREASURE_FLEETS</Type> 
 219179: 			<Type>POLICY_EXPLORATION_FINISHER</Type> 

 229658: 			<Type>POLICY_BRANCH_FREEDOM</Type> 
 219335: 			<Type>POLICY_OPEN_SOCIETY</Type> 
 219496: 			<Type>POLICY_CREATIVE_EXPRESSION</Type> 
 219657: 			<Type>POLICY_CIVIL_SOCIETY</Type> 
 219818: 			<Type>POLICY_VOLUNTEER_ARMY</Type> 
 219979: 			<Type>POLICY_COVERT_ACTION</Type> 
 220140: 			<Type>POLICY_URBANIZATION</Type> 
 220301: 			<Type>POLICY_CAPITALISM</Type> 
 220462: 			<Type>POLICY_ECONOMIC_UNION</Type> 
 220623: 			<Type>POLICY_THEIR_FINEST_HOUR</Type> 
 220784: 			<Type>POLICY_UNIVERSAL_SUFFRAGE</Type> 
 220945: 			<Type>POLICY_NEW_DEAL</Type> 
 221106: 			<Type>POLICY_ARSENAL_DEMOCRACY</Type> 
 221267: 			<Type>POLICY_MEDIA_CULTURE</Type> 
 221428: 			<Type>POLICY_TREATY_ORGANIZATION</Type> 
 221589: 			<Type>POLICY_SPACE_PROCUREMENTS</Type> 
 226580: 			<Type>POLICY_UNIVERSAL_HEALTHCARE_F</Type> 

 229675: 			<Type>POLICY_BRANCH_ORDER</Type> 
 221750: 			<Type>POLICY_HERO_OF_THE_PEOPLE</Type> 
 221911: 			<Type>POLICY_SOCIALIST_REALISM</Type> 
 222072: 			<Type>POLICY_SKYSCRAPERS</Type> 
 222233: 			<Type>POLICY_PATRIOTIC_WAR</Type> 
 222394: 			<Type>POLICY_DOUBLE_AGENTS</Type> 
 222555: 			<Type>POLICY_YOUNG_PIONEERS</Type> 
 222716: 			<Type>POLICY_ACADEMY_SCIENCES</Type> 
 222877: 			<Type>POLICY_PARTY_LEADERSHIP</Type> 
 223038: 			<Type>POLICY_RESETTLEMENT</Type> 
 223199: 			<Type>POLICY_CULTURAL_REVOLUTION</Type> 
 223360: 			<Type>POLICY_WORKERS_FACULTIES</Type> 
 223521: 			<Type>POLICY_FIVE_YEAR_PLAN</Type> 
 223682: 			<Type>POLICY_DICTATORSHIP_PROLETARIAT</Type> 
 223843: 			<Type>POLICY_IRON_CURTAIN</Type> 
 224004: 			<Type>POLICY_SPACEFLIGHT_PIONEERS</Type> 
 226741: 			<Type>POLICY_UNIVERSAL_HEALTHCARE_O</Type> 

 229692: 			<Type>POLICY_BRANCH_AUTOCRACY</Type> 
 224165: 			<Type>POLICY_ELITE_FORCES</Type> 
 224326: 			<Type>POLICY_MOBILIZATION</Type> 
 224487: 			<Type>POLICY_UNITED_FRONT</Type> 
 224648: 			<Type>POLICY_FUTURISM</Type> 
 224809: 			<Type>POLICY_INDUSTRIAL_ESPIONAGE</Type> 
 224970: 			<Type>POLICY_MILITARISM</Type> 
 225131: 			<Type>POLICY_FORTIFIED_BORDERS</Type> 
 225292: 			<Type>POLICY_LIGHTNING_WARFARE</Type> 
 225453: 			<Type>POLICY_POLICE_STATE</Type> 
 225614: 			<Type>POLICY_NATIONALISM</Type> 
 225775: 			<Type>POLICY_THIRD_ALTERNATIVE</Type> 
 225936: 			<Type>POLICY_TOTAL_WAR</Type> 
 226097: 			<Type>POLICY_CULT_PERSONALITY</Type> 
 226258: 			<Type>POLICY_GUNBOAT_DIPLOMACY</Type> 
 226419: 			<Type>POLICY_NEW_ORDER</Type> 
 226902: 			<Type>POLICY_UNIVERSAL_HEALTHCARE_A</Type> 

 227063: 			<Type>POLICY_DUMMY_AKKAD</Type> 
 227223: 			<Type>POLICY_DUMMY_PRUSSIA</Type> 
 227383: 			<Type>POLICY_DUMMY_KOREA</Type> 
 227543: 			<Type>POLICY_DUMMY_GERMANY</Type> 
 227704: 			<Type>POLICY_DUMMY_GOTH</Type> 
 227864: 			<Type>POLICY_DUMMY_ROMANIA</Type> 
 228024: 			<Type>POLICY_DUMMY_SCOTLAND</Type> 
 228184: 			<Type>POLICY_DUMMY_IRELAND</Type> 
 228344: 			<Type>POLICY_DUMMY_TURKEY</Type> 
 228504: 			<Type>POLICY_DUMMY_KILWA</Type> 
 228664: 			<Type>POLICY_DUMMY_NZ</Type> 
 228824: 			<Type>POLICY_DUMMY_MAORI</Type> 
 228984: 			<Type>POLICY_DUMMY_LEXICO</Type> 
 229144: 			<Type>POLICY_DUMMY_VIETNAM</Type> 
 229304: 			<Type>POLICY_DUMMY_CUBA</Type> 
]] -- FEATURE_ARARAT_MOUNTAIN

function default(current, auto)
    if current == nil then 
    	return auto;
    else 
    	return current;
    end
end

function PolicyGrantsFreeBuilding(GameEvents, policyName, buildingName, includeExistingCities, includeNewCities, isBranch, requiresWholeBranch)
	includeExistingCities = default(includeExistingCities, true);
	includeNewCities = default(includeNewCities, true);
	isBranch = default(isBranch, false);
	requiresWholeBranch = default(requiresWholeBranch, false);
	-- Add to existing cities
	if (includeExistingCities) then
		local onPolicyAdopted = function (playerID, policyID)
			--print("onPolicyAdopted called with policy name: "..policyName.."and id: "..policyID);
			local player = Players[playerID];

			-- check if correct policy
			local match = false;
			if (isBranch and not requiresWholeBranch) then 
				match = policyID == GameInfo.PolicyBranchTypes[policyName].ID;
				--print("1matched?: "..match);
			elseif (isBranch and requiresWholeBranch) then
				local willBeComplete = player:WillFinishReturnedBranchIfAdopted(policyID);
				match = willBeComplete == GameInfo.PolicyBranchTypes[policyName].ID;
				--print("2matched?: "..willBeComplete);
			else
				match = policyID == GameInfo.Policies[policyName].ID;
				--print("3matched?: "..match);
			end
			if (match) then
				for loopCity in player:Cities() do
					loopCity:SetNumRealBuilding(GameInfoTypes[buildingName], 1);
				end
			end
		end
		--print("RequiresWhole Branch?: "..tostring(requiresWholeBranch));
		--print("isBranch?: "..tostring(isBranch));
		-- add to events
		if (isBranch and not requiresWholeBranch) then
			--print("onPolicyAdopted listening for branch "..policyName);
			GameEvents.PlayerAdoptPolicyBranch.Add(onPolicyAdopted);
		else -- if requiresWholeBranch is true, we'll get called on a normal policy adoption
			--print("onPolicyAdopted listening for policy "..policyName);
			GameEvents.PlayerAdoptPolicy.Add(onPolicyAdopted);
		end
	end
	-- Add to new cities
	if (includeNewCities) then
		local onCityFounded = function (iPlayer, iCityX, iCityY)
			--print("onCityFounded called with policy name: "..policyName);
			local player = Players[iPlayer]

			-- check if correct policy
			local match = false;
			if (isBranch and not requiresWholeBranch) then 
				match = player:IsPolicyBranchUnlocked(GameInfo.PolicyBranchTypes[policyName].ID);
				--print("onCityFounded IsPolicyBranchUnlocked with policy name: "..policyName.."   "..tostring(match));
			elseif (isBranch and requiresWholeBranch) then
				match = player:IsPolicyBranchFinished(GameInfo.PolicyBranchTypes[policyName].ID);
				--print("onCityFounded IsPolicyBranchFinished with policy name: "..policyName.."   "..tostring(match));
			else
				match = player:HasPolicy(GameInfo.Policies[policyName].ID);
			end
			
			if (match) then
				for loopCity in player:Cities() do
					if (loopCity:GetX() == iCityX and loopCity:GetY() == iCityY) then
						loopCity:SetNumRealBuilding(GameInfoTypes[buildingName], 1);
					end
				end
			end
		end
		GameEvents.PlayerCityFounded.Add(onCityFounded); -- TODO CityCaptureComplete
	end
end

--print("adding callbacks");
PolicyGrantsFreeBuilding(GameEvents, "POLICY_BRANCH_LIBERTY", "BUILDING_GOVERNORS_MANSION", false, true, true);

PolicyGrantsFreeBuilding(GameEvents, "POLICY_BRANCH_EXPLORATION", "BUILDING_POLICY_BONUS_PRODUCTION", true, true, true, false); -- opener
PolicyGrantsFreeBuilding(GameEvents, "POLICY_MERCHANT_NAVY", "BUILDING_POLICY_BONUS_RESOURCES_PRODUCTION");
PolicyGrantsFreeBuilding(GameEvents, "POLICY_MARITIME_INFRASTRUCTURE", "BUILDING_POLICY_BONUS_MOUNTAIN_PRODUCTION");
PolicyGrantsFreeBuilding(GameEvents, "POLICY_NAVIGATION_SCHOOL", "BUILDING_POLICY_BONUS_SEA_PRODUCTION");
PolicyGrantsFreeBuilding(GameEvents, "POLICY_BRANCH_EXPLORATION", "BUILDING_POLICY_BONUS_SEA_GOLD", true, true, true, true); -- closer

--[[
function OnPolicyAdopted(playerID, policyID)
	local player = Players[playerID];
	local capitalCity = player:GetCapitalCity();


	-- todo add order
	if (player:HasPolicy(GameInfo.Policies["POLICY_BRANCH_AUTOCRACY"].ID)) then
		capitalCity:SetNumRealBuilding(GameInfoTypes["CAN_BUILD_FIREWALL"], 1);
	-- Autocracy and Order can build the Great Firewall
	if (policyID == GameInfo.Policies["POLICY_BRANCH_AUTOCRACY"].ID or policyID == GameInfo.Policies["POLICY_BRANCH_ORDER"].ID) then
		for loopCity in player:Cities() do
			loopCity:SetNumRealBuilding(GameInfoTypes["CAN_BUILD_FIREWALL"], 1);
		end
	end
	-- Exploration gets city bonuses
	if (policyID == GameInfo.Policies["POLICY_EXPLORATION_OPENER"].ID) then
		for loopCity in player:Cities() do
			loopCity:SetNumRealBuilding(GameInfoTypes["BUILDING_GOVERNORS_MANSION"], 1)
		end
	end
end
GameEvents.PlayerAdoptPolicy.Add(OnPolicyAdopted);
function OnCityFounded(iPlayer, iCityX, iCityY)
	local player = Players[iPlayer]
	if (player:HasPolicy(GameInfo.Policies["POLICY_LIBERTY"].ID)) then
		for loopCity in player:Cities() do
			if (loopCity:GetX() == iCityX and loopCity:GetY() == iCityY) then
				loopCity:SetNumRealBuilding(GameInfoTypes["BUILDING_GOVERNORS_MANSION"], 1)
			end
		end
	end
end
GameEvents.PlayerCityFounded.Add(OnCityFounded)
--]]


function AddBuilding(player, buildingID, buildingName, policyName)
	if (buildingID == GameInfo.Buildings[buildingName].ID and 
		not player:HasPolicy(GameInfo.Policies[policyName].ID)) then
		return false;
	end
	return true;
end
function HasRequiredPolicy(player, buildingID, buildingName, policyName)
	if (buildingID == GameInfo.Buildings[buildingName].ID and 
		not player:HasPolicy(GameInfo.Policies[policyName].ID)) then
		return false;
	end
	return true;
end

function HasRequiredPolicyBranch(player, buildingID, buildingName, branchName)
	if (buildingID == GameInfo.Buildings[buildingName].ID and 
		not player:IsPolicyBranchUnlocked(GameInfo.PolicyBranchTypes[branchName].ID)) then
		return false;
	end
	return true;
end
function HasRequiredPolicyBranchComplete(player, buildingID, buildingName, branchName)
	if (buildingID == GameInfo.Buildings[buildingName].ID and 
		not player:IsPolicyBranchFinished(GameInfo.PolicyBranchTypes[branchName].ID)) then
		return false;
	end
	return true;
end

-- additional building restrictions
function CheckCanConstruct(playerID, buildingTypeID)
	local ply = Players[playerID];
	local bID = buildingTypeID;
	local canBuild = true;

-- Oracle
	canBuild = canBuild and (HasRequiredPolicy(ply, bID, "BUILDING_ORACLE", "POLICY_ARISTOCRACY"));
-- Great Wall
	canBuild = canBuild and (HasRequiredPolicy(ply, bID, "BUILDING_GREAT_WALL", "POLICY_CITIZENSHIP"));
-- Terracotta Army
	canBuild = canBuild and (HasRequiredPolicy(ply, bID, "BUILDING_TERRACOTTA_ARMY", "POLICY_WARRIOR_CODE"));
-- Great Fire Wall
	canBuild = canBuild and ( -- Great Wall
		HasRequiredPolicy(ply, bID, "BUILDING_GREAT_FIREWALL", "POLICY_ORDER_OPENER") or
		HasRequiredPolicy(ply, bID, "BUILDING_GREAT_FIREWALL", "POLICY_AUTOCRACY_OPENER"));
-- Sydney Opera House
	canBuild = canBuild and (HasRequiredPolicy(ply, bID, "BUILDING_SYDNEY_OPERA_HOUSE", "POLICY_FLOURISHING_OF_ARTS"));
-- Panama Canal
	canBuild = canBuild and (HasRequiredPolicy(ply, bID, "BUILDING_PANAMA", "POLICY_ENTREPRENEURSHIP"));

-- Urbanization tree buildings
	canBuild = canBuild and (HasRequiredPolicyBranch(ply, bID, "BUILDING_POLICY_BONUS_PRODUCTION", "POLICY_BRANCH_EXPLORATION"));
	canBuild = canBuild and (HasRequiredPolicy(ply, bID, "BUILDING_POLICY_BONUS_RESOURCES_PRODUCTION", "POLICY_MERCHANT_NAVY"));
	canBuild = canBuild and (HasRequiredPolicy(ply, bID, "BUILDING_POLICY_BONUS_MOUNTAIN_PRODUCTION", "POLICY_MARITIME_INFRASTRUCTURE"));
	canBuild = canBuild and (HasRequiredPolicy(ply, bID, "BUILDING_POLICY_BONUS_SEA_PRODUCTION", "POLICY_NAVIGATION_SCHOOL"));
	canBuild = canBuild and (HasRequiredPolicyBranchComplete(ply, bID, "BUILDING_POLICY_BONUS_SEA_GOLD", "POLICY_BRANCH_EXPLORATION"));

	canBuild = canBuild and (HasRequiredPolicy(ply, bID, "BUILDING_UFFIZI", "POLICY_CULTURAL_CENTERS"));
	canBuild = canBuild and (HasRequiredPolicy(ply, bID, "BUILDING_PORCELAIN_TOWER", "POLICY_HUMANISM"));

	return canBuild;
end
GameEvents.PlayerCanConstruct.Add(CheckCanConstruct);

--[[

function Italy_OnPolicyAdopted(playerID, policyID)

	local player = Players[playerID]

	-- Tradition Finished
	if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_ITALY"] then

		if	(policyID == GameInfo.Policies["POLICY_ARISTOCRACY"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_LANDED_ELITE"].ID)
			and player:HasPolicy(GameInfo.Policies["POLICY_MONARCHY"].ID)
			and player:HasPolicy(GameInfo.Policies["POLICY_OLIGARCHY"].ID)) or
			(policyID == GameInfo.Policies["POLICY_LANDED_ELITE"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_ARISTOCRACY"].ID)
			and player:HasPolicy(GameInfo.Policies["POLICY_MONARCHY"].ID)
			and player:HasPolicy(GameInfo.Policies["POLICY_OLIGARCHY"].ID)) or
			(policyID == GameInfo.Policies["POLICY_MONARCHY"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_LANDED_ELITE"].ID)
			and player:HasPolicy(GameInfo.Policies["POLICY_ARISTOCRACY"].ID)
			and player:HasPolicy(GameInfo.Policies["POLICY_OLIGARCHY"].ID)) or
			(policyID == GameInfo.Policies["POLICY_OLIGARCHY"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_LANDED_ELITE"].ID)
			and player:HasPolicy(GameInfo.Policies["POLICY_MONARCHY"].ID)
			and player:HasPolicy(GameInfo.Policies["POLICY_ARISTOCRACY"].ID)) then

			-- Finished Policy Tree, now add the building
			local pCity = player:GetCapitalCity();
			pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_ITALY_TRAIT_TRADITION"], 1);
		end
	end 
end

if bIsActive then
GameEvents.PlayerAdoptPolicy.Add(Italy_OnPolicyAdopted);
end
function Italy_OnPolicyAdopted(playerID, policyID)

	local player = Players[playerID]

	-- Liberty Finished
	if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_ITALY"] then

		if	(policyID == GameInfo.Policies["POLICY_COLLECTIVE_RULE"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_REPRESENTATION"].ID)
			and player:HasPolicy(GameInfo.Policies["POLICY_MERITOCRACY"].ID)) or
			(policyID == GameInfo.Policies["POLICY_REPRESENTATION"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_COLLECTIVE_RULE"].ID)
			and player:HasPolicy(GameInfo.Policies["POLICY_MERITOCRACY"].ID)) or
			(policyID == GameInfo.Policies["POLICY_MERITOCRACY"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_COLLECTIVE_RULE"].ID)
			and player:HasPolicy(GameInfo.Policies["POLICY_REPRESENTATION"].ID)) then

			-- Finished Policy Tree, now add the building
			local pCity = player:GetCapitalCity();
			pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_ITALY_TRAIT_LIBERTY"], 1);
		end
	end 
end
if bIsActive then
GameEvents.PlayerAdoptPolicy.Add(Italy_OnPolicyAdopted);
end

function Italy_OnPolicyAdopted(playerID, policyID)

	local player = Players[playerID]

	-- Honor Finished
	if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_ITALY"] then

		if	(policyID == GameInfo.Policies["POLICY_MILITARY_CASTE"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_MILITARY_TRADITION"].ID)
			and player:HasPolicy(GameInfo.Policies["POLICY_DISCIPLINE"].ID)) or
			(policyID == GameInfo.Policies["POLICY_MILITARY_TRADITION"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_MILITARY_CASTE"].ID)
			and player:HasPolicy(GameInfo.Policies["POLICY_DISCIPLINE"].ID)) or
			(policyID == GameInfo.Policies["POLICY_DISCIPLINE"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_MILITARY_CASTE"].ID)
			and player:HasPolicy(GameInfo.Policies["POLICY_MILITARY_TRADITION"].ID)) then

			-- Finished Policy Tree, now add the building
			local pCity = player:GetCapitalCity();
			pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_ITALY_TRAIT_HONOR"], 1);
		end
	end 
end
if bIsActive then
GameEvents.PlayerAdoptPolicy.Add(Italy_OnPolicyAdopted);
end

function Italy_OnPolicyAdopted(playerID, policyID)

	local player = Players[playerID]

	-- Patronage Finished
	if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_ITALY"] then

		if	(policyID == GameInfo.Policies["POLICY_CONSULATES"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_SCHOLASTICISM"].ID)
			and player:HasPolicy(GameInfo.Policies["POLICY_PHILANTHROPY"].ID)) or
			(policyID == GameInfo.Policies["POLICY_SCHOLASTICISM"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_CONSULATES"].ID)
			and player:HasPolicy(GameInfo.Policies["POLICY_PHILANTHROPY"].ID)) or
			(policyID == GameInfo.Policies["POLICY_PHILANTHROPY"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_CONSULATES"].ID)
			and player:HasPolicy(GameInfo.Policies["POLICY_SCHOLASTICISM"].ID)) then

			-- Finished Policy Tree, now add the building
			local pCity = player:GetCapitalCity();
			pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_ITALY_TRAIT_PATRONAGE"], 1);
		end
	end 
end
if bIsActive then
GameEvents.PlayerAdoptPolicy.Add(Italy_OnPolicyAdopted);
end

function Italy_OnPolicyAdopted(playerID, policyID)

	local player = Players[playerID]

	-- Aesthetics Finished
	if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_ITALY"] then

		if	(policyID == GameInfo.Policies["POLICY_FINE_ARTS"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_FLOURISHING_OF_ARTS"].ID)) or
			(policyID == GameInfo.Policies["POLICY_FLOURISHING_OF_ARTS"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_FINE_ARTS"].ID)) then

			-- Finished Policy Tree, now add the building
			local pCity = player:GetCapitalCity();
			pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_ITALY_TRAIT_AESTHETICS"], 1);
		end
	end 
end

if bIsActive then
GameEvents.PlayerAdoptPolicy.Add(Italy_OnPolicyAdopted);
end
function Italy_OnPolicyAdopted(playerID, policyID)

	local player = Players[playerID]

	-- Exploration Finished
	if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_ITALY"] then

		if	(policyID == GameInfo.Policies["POLICY_TREASURE_FLEETS"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_MERCHANT_NAVY"].ID)) or
			(policyID == GameInfo.Policies["POLICY_MERCHANT_NAVY"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_TREASURE_FLEETS"].ID)) then

			-- Finished Policy Tree, now add the building
			local pCity = player:GetCapitalCity();
			pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_ITALY_TRAIT_EXPLORATION"], 1);
		end
	end 
end
if bIsActive then
GameEvents.PlayerAdoptPolicy.Add(Italy_OnPolicyAdopted);
end

function Italy_OnPolicyAdopted(playerID, policyID)

	local player = Players[playerID]

	-- Rationalism Finished
	if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_ITALY"] then

		if	(policyID == GameInfo.Policies["POLICY_SECULARISM"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_HUMANISM"].ID)) or
			(policyID == GameInfo.Policies["POLICY_HUMANISM"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_SECULARISM"].ID)) then

			-- Finished Policy Tree, now add the building
			local pCity = player:GetCapitalCity();
			pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_ITALY_TRAIT_RATIONALISM"], 1);
		end
	end 
end
if bIsActive then
GameEvents.PlayerAdoptPolicy.Add(Italy_OnPolicyAdopted);
end

function Italy_OnPolicyAdopted(playerID, policyID)

	local player = Players[playerID]

	-- Commerce Finished
	if player:GetCivilizationType() == GameInfoTypes["CIVILIZATION_ITALY"] then

		if	(policyID == GameInfo.Policies["POLICY_ENTREPRENEURSHIP"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_PROTECTIONISM"].ID)
			and player:HasPolicy(GameInfo.Policies["POLICY_TRADE_UNIONS"].ID)) or
			(policyID == GameInfo.Policies["POLICY_PROTECTIONISM"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_ENTREPRENEURSHIP"].ID)
			and player:HasPolicy(GameInfo.Policies["POLICY_TRADE_UNIONS"].ID)) or
			(policyID == GameInfo.Policies["POLICY_TRADE_UNIONS"].ID 
			and player:HasPolicy(GameInfo.Policies["POLICY_ENTREPRENEURSHIP"].ID)
			and player:HasPolicy(GameInfo.Policies["POLICY_PROTECTIONISM"].ID)) then

			-- Finished Policy Tree, now add the building
			local pCity = player:GetCapitalCity();
			pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_ITALY_TRAIT_COMMERCE"], 1);
		end
	end 
end

if bIsActive then
GameEvents.PlayerAdoptPolicy.Add(Italy_OnPolicyAdopted);
end



-- PietyChanges
-- Author: Cirra
-- DateCreated: 10/17/2019 1:22:18 AM
--------------------------------------------------------------

function Piety_OnPolicyAdopted(playerID, policyID)

	local player = Players[playerID]

	-- Piety finisher

	if	(policyID == GameInfo.Policies["POLICY_THEOCRACY"].ID 
		and player:HasPolicy(GameInfo.Policies["POLICY_MANDATE_OF_HEAVEN"].ID)
		and player:HasPolicy(GameInfo.Policies["POLICY_FREE_RELIGION"].ID)
		and player:HasPolicy(GameInfo.Policies["POLICY_REFORMATION"].ID)) or
		(policyID == GameInfo.Policies["POLICY_MANDATE_OF_HEAVEN"].ID 
		and player:HasPolicy(GameInfo.Policies["POLICY_THEOCRACY"].ID)
		and player:HasPolicy(GameInfo.Policies["POLICY_FREE_RELIGION"].ID)
		and player:HasPolicy(GameInfo.Policies["POLICY_REFORMATION"].ID)) or
		(policyID == GameInfo.Policies["POLICY_FREE_RELIGION"].ID 
		and player:HasPolicy(GameInfo.Policies["POLICY_MANDATE_OF_HEAVEN"].ID)
		and player:HasPolicy(GameInfo.Policies["POLICY_THEOCRACY"].ID)
		and player:HasPolicy(GameInfo.Policies["POLICY_REFORMATION"].ID)) or
		(policyID == GameInfo.Policies["POLICY_REFORMATION"].ID 
		and player:HasPolicy(GameInfo.Policies["POLICY_MANDATE_OF_HEAVEN"].ID)
		and player:HasPolicy(GameInfo.Policies["POLICY_FREE_RELIGION"].ID)
		and player:HasPolicy(GameInfo.Policies["POLICY_THEOCRACY"].ID)) then

		-- The player has finished Piety. Add a Grand Monument to the capital, gives allows buying great people.
		local pCity = player:GetCapitalCity();
		pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_PIETY_FINISHER"], 1);

		local i = 
		local iIndo = GameInfo.Civilizations["CIVILIZATION_INDONESIA"].ID
		local iKhmer = GameInfo.Civilizations["CIVILIZATION_KHMER"].ID
		local iRoma = GameInfo.Civilizations["CIVILIZATION_MC_ROMANIA"].ID
		for pCity in player:Cities() do
			if i >= 4 then break end
			if (player:GetCivilizationType() == iIndo) then pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_CANDI"], 1) 
			elseif (player:GetCivilizationType() == iKhmer) then pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_BARAY"], 1)
			elseif (player:GetCivilizationType() == iRoma) then pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_MC_ROMANIAN_PAINTED_MONASTERY"], 1)
			else pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_GARDEN"], 1) end
			i = i + 1
		end
	end
end
GameEvents.PlayerAdoptPolicy.Add(Piety_OnPolicyAdopted);

-- HonorChanges
-- Author: Cirra
-- DateCreated: 7/27/2019 1:22:18 AM
--------------------------------------------------------------

function Honor_OnPolicyAdopted(playerID, policyID)

	local player = Players[playerID]

	-- Honor Finisher
	if	(policyID == GameInfo.Policies["POLICY_DISCIPLINE"].ID 
		and player:HasPolicy(GameInfo.Policies["POLICY_MILITARY_TRADITION"].ID)
		and player:HasPolicy(GameInfo.Policies["POLICY_MILITARY_CASTE"].ID)) or
		(policyID == GameInfo.Policies["POLICY_MILITARY_TRADITION"].ID 
		and player:HasPolicy(GameInfo.Policies["POLICY_DISCIPLINE"].ID)
		and player:HasPolicy(GameInfo.Policies["POLICY_MILITARY_CASTE"].ID)) or
		(policyID == GameInfo.Policies["POLICY_MILITARY_CASTE"].ID 
		and player:HasPolicy(GameInfo.Policies["POLICY_MILITARY_TRADITION"].ID)
		and player:HasPolicy(GameInfo.Policies["POLICY_DISCIPLINE"].ID)) then

		-- The player has finished Honor. Add old ToA to the capital, which gives +10% food everywhere.
		local pCity = player:GetCapitalCity();
		pCity:SetNumRealBuilding(GameInfoTypes["BUILDING_HONOR_FINISHER"], 1);

	end

end
GameEvents.PlayerAdoptPolicy.Add(Honor_OnPolicyAdopted);
		--]]
