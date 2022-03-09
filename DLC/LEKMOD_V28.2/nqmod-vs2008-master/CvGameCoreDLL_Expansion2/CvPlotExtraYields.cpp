/*	-------------------------------------------------------------------------------------------------------
	© 1991-2012 Take-Two Interactive Software and its subsidiaries.  Developed by Firaxis Games.  
	Sid Meier's Civilization V, Civ, Civilization, 2K Games, Firaxis Games, Take-Two Interactive Software 
	and their respective logos are all trademarks of Take-Two interactive Software, Inc.  
	All other marks and trademarks are the property of their respective owners.  
	All rights reserved. 
	------------------------------------------------------------------------------------------------------- */

#include "CvGameCoreDLLPCH.h"
#include "CvPlot.h"
#include "CvCity.h"
#include "CvUnit.h"
#include "CvGlobals.h"
#include "CvArea.h"
#include "ICvDLLUserInterface.h"
#include "CvMap.h"
#include "CvPlayerAI.h"
#include "CvTeam.h"
#include "CvGameCoreUtils.h"
#include "CvRandom.h"
#include "CvInfos.h"
#include "CvImprovementClasses.h"
#include "CvAStar.h"
#include "CvEconomicAI.h"
#include "CvEnumSerialization.h"
#include "CvNotifications.h"
#include "CvMinorCivAI.h"
#include "CvUnitCombat.h"
#include "CvDLLUtilDefines.h"
#include "CvInfosSerializationHelper.h"
#include "CvBarbarians.h"

#include "CvDllPlot.h"
#include "CvDllUnit.h"
#include "CvUnitMovement.h"
#include "CvTargeting.h"
#include "CvTypes.h"

// Include this after all other headers.
#include "LintFree.h"



BuildingClassTypes BuildingClass(const string name)
{
	return GC.GetGameBuildings()->BuildingClass(name);
}


// extra yields for plots
int CvPlot::getExtraYield
(
	// type of yield we are considering
	const YieldTypes eYieldType,
	// type of improvement
	const ImprovementTypes eImprovement,
	// type of route (road, railroad, none)
	const RouteTypes eRouteType,
	// owning player
	const PlayerTypes tileOwner
)
{
	const CvPlot& plot = *this;
	// city that is/could work this tile
	const CvCity* pWorkingCity = plot.getWorkingCity();
	// true if a is/could work this tile
	const bool hasAWorkingCity = pWorkingCity != NULL;
	// true if this tile is not pillaged
	const bool isNotPillaged = !plot.IsRoutePillaged() && !plot.IsImprovementPillaged();
	// true if we have a road or railroad
	const bool hasAnyRoute = eRouteType != NO_ROUTE && isNotPillaged;
	// true if this tile has any improvements
	const bool hasAnyImprovement = eImprovement != NO_IMPROVEMENT;
	// true if this is the actual city tile (not just a surrounding tile)
	const bool isCityCenter = plot.getPlotCity() != NULL;
	// true if this tile has any atoll on it
	const bool hasAnyAtoll = plot.HasAnyAtoll();
	CvImprovementEntry* pImprovement = NULL;
	string improvementName = ""; // <ImprovementType>
	if (hasAnyImprovement)
	{
		pImprovement = GC.getImprovementInfo((ImprovementTypes)m_eImprovementType);
		if (pImprovement != NULL)
		{
			improvementName = pImprovement->GetType();
		}
	}

	int yieldChange = 0;


	const bool isTundra = plot.HasTerrain(TERRAIN_TUNDRA);
	const bool isDesert = plot.HasTerrain(TERRAIN_DESERT);
	const bool hasBonus = plot.HasResourceClass("RESOURCECLASS_BONUS"); // has a bonus resource
	const bool hasLuxury = plot.HasResourceClass("RESOURCECLASS_LUXURY"); // has a luxury resource
	const bool hasStrategic = plot.HasResourceClass("RESOURCECLASS_RUSH") || plot.HasResourceClass("RESOURCECLASS_MODERN"); // has any strategic resource
	const bool noResource = !hasBonus && !hasLuxury && !hasStrategic; // no resource of any kind (might have artifacts though)


	// depends on player
	if (tileOwner != NO_PLAYER)
	{
		const CvPlayer& player = GET_PLAYER(tileOwner);
		// depends on city
		if (pWorkingCity != NULL)
		{
			const CvCity& city = *pWorkingCity;
			const ReligionTypes majorityReligion = city.GetCityReligions()->GetReligiousMajority(); // the majority religion in this city
			const int numCitiesFollowing = GC.getGame().GetGameReligions()->GetNumCitiesFollowing(majorityReligion); // number of cities with this as majority
			const int numCityStatesFollowing = GC.getGame().GetGameReligions()->GetNumCitiesFollowing(majorityReligion, true); // number of city states with this as majority
			const bool isHolyCity = city.GetCityReligions()->IsHolyCityForReligion(majorityReligion); // true if this is the holy city of the majority religion in this city
			const int numFollowersLocal = city.GetCityReligions()->GetNumFollowers(majorityReligion); // number of people following the majority religion in this city
			const int numFollowersGlobal = city.GetCityReligions()->GetNumFollowers(majorityReligion); // number of people following the majority religion in this city globaly
			const int cityPopulation = city.getPopulation(); // number of people in this city
			const int numTradeCityStates = player.GetTrade()->GetNumberOfCityStateTradeRoutes(); // number of trade routes we have with city states
			const int numTradeMajorCivs = player.GetTrade()->GetNumForeignTradeRoutes(player.GetID()) - numTradeCityStates; // number of trade routes we have with other civ players (not city states)

			{// BELIEF_Religious Community - gives 1 diplo point per 6 followers (max 20)
				const bool hasBeliefReligiousCommunity = city.HasBelief("BELIEF_RELIGIOUS_COMMUNITY");
				if (eYieldType == YIELD_DIPLOMATIC_SUPPORT && hasBeliefReligiousCommunity && isHolyCity && isCityCenter)
					yieldChange += min(20, numFollowersGlobal/3);
			}

			{// BELIEF_Church Property - Holy City - +1 (food, production, gold, faith, culture, and science) and an additional of each yield per 40 followers (max +5)
				const bool hasBeliefChurchProperty = city.HasBelief("BELIEF_CHURCH_PROPERTY");
				if (eYieldType == YIELD_FOOD && hasBeliefChurchProperty && isHolyCity && isCityCenter)
					yieldChange += 1;
				if (eYieldType == YIELD_PRODUCTION && hasBeliefChurchProperty && isHolyCity && isCityCenter)
					yieldChange += 1;
				if (eYieldType == YIELD_CULTURE && hasBeliefChurchProperty && isHolyCity && isCityCenter)
					yieldChange += 1;
				if (eYieldType == YIELD_FAITH && hasBeliefChurchProperty && isHolyCity && isCityCenter)
					yieldChange += 1;
				if (eYieldType == YIELD_SCIENCE && hasBeliefChurchProperty && isHolyCity && isCityCenter)
					yieldChange += 1;
				if (eYieldType == YIELD_GOLD && hasBeliefChurchProperty && isHolyCity && isCityCenter)
					yieldChange += 1;
				if (eYieldType == YIELD_FOOD && hasBeliefChurchProperty && isHolyCity && isCityCenter)
					yieldChange += min(6, numFollowersGlobal / 50);
				if (eYieldType == YIELD_PRODUCTION && hasBeliefChurchProperty && isHolyCity && isCityCenter)
					yieldChange += min(6, numFollowersGlobal / 50);
				if (eYieldType == YIELD_CULTURE && hasBeliefChurchProperty && isHolyCity && isCityCenter)
					yieldChange += min(6, numFollowersGlobal / 50);
				if (eYieldType == YIELD_FAITH && hasBeliefChurchProperty && isHolyCity && isCityCenter)
					yieldChange += min(6, numFollowersGlobal / 50);
				if (eYieldType == YIELD_SCIENCE && hasBeliefChurchProperty && isHolyCity && isCityCenter)
					yieldChange += min(6, numFollowersGlobal / 50);
				if (eYieldType == YIELD_GOLD && hasBeliefChurchProperty && isHolyCity && isCityCenter)
					yieldChange += min(6, numFollowersGlobal / 50);
			}

			{// BELIEF_Dawah - Holy City - 2 Culture, 1 Culture per 8 followers (max 20)
				const bool hasBeliefDawah = city.HasBelief("BELIEF_DAWAHH");
				if (eYieldType == YIELD_CULTURE && hasBeliefDawah && isHolyCity && isCityCenter)
					yieldChange += 2;
				if (eYieldType == YIELD_CULTURE && hasBeliefDawah && isHolyCity && isCityCenter)
					yieldChange += min(20, numFollowersGlobal / 8);
			}

			{// BELIEF_initiation rites - renamed Religios Scholars - Holy City - 2 Science, 1 science per 3 followers (max 100)
				const bool hasBeliefReligiousScholars = city.HasBelief("BELIEF_INITIATION_RITES");
				if (eYieldType == YIELD_SCIENCE && hasBeliefReligiousScholars && isHolyCity && isCityCenter)
					yieldChange += 2;
				if (eYieldType == YIELD_SCIENCE && hasBeliefReligiousScholars && isHolyCity && isCityCenter)
					yieldChange += min(100, numFollowersGlobal / 3);
			}

			{// BELIEF_Messiah - renamed Sacrificial Altars - Holy Sites - 1 faith, culture, tourism, and 1 additioanl for 40 followers (max 3)
				const bool hasBeliefSacrificialAltars = city.HasBelief("BELIEF_MESSIAH");
				const bool isHolySite = plot.HasImprovement("IMPROVEMENT_HOLY_SITE");
				if (eYieldType == YIELD_CULTURE && hasBeliefSacrificialAltars && isHolySite)
					yieldChange += 1;
				if (eYieldType == YIELD_FAITH && hasBeliefSacrificialAltars && isHolySite)
					yieldChange += 1;
				if (eYieldType == YIELD_TOURISM && hasBeliefSacrificialAltars && isHolySite)
					yieldChange += 1;
				if (eYieldType == YIELD_CULTURE && hasBeliefSacrificialAltars && isHolySite)
					yieldChange += min(3, numFollowersGlobal / 40);
				if (eYieldType == YIELD_FAITH && hasBeliefSacrificialAltars && isHolySite)
					yieldChange += min(3, numFollowersGlobal / 40);
				if (eYieldType == YIELD_TOURISM && hasBeliefSacrificialAltars && isHolySite)
					yieldChange += min(3, numFollowersGlobal / 40);
			}

			{// BELIEF_MISSIONARY_ZEAL - Holy City - 2 tourism and 1 tourism per 12 followers (max 20)
				const bool hasBeliefMissionaryZeal = city.HasBelief("BELIEF_MISSIONARY_ZEAL");
				if (eYieldType == YIELD_TOURISM && hasBeliefMissionaryZeal && isHolyCity && isCityCenter)
					yieldChange += 2;
				if (eYieldType == YIELD_TOURISM && hasBeliefMissionaryZeal && isHolyCity && isCityCenter)
					yieldChange += min(20, numFollowersGlobal / 12);
			}

			{// BELIEF_MITHRAEA - Holy City - 3 food and 1 food per 6 followers (max 30)
				const bool hasBeliefMithraea = city.HasBelief("BELIEF_MITHRAEA");
				if (eYieldType == YIELD_FOOD && hasBeliefMithraea && isHolyCity && isCityCenter)
					yieldChange += 3;
				if (eYieldType == YIELD_FOOD && hasBeliefMithraea && isHolyCity && isCityCenter)
					yieldChange += min(30, numFollowersGlobal / 6);
			}

			{// BELIEF_HEATHEN_CONVERSION - renamed religious troubarods - Trade Routes - 3 faith, 3 diplo points, +2 trade routes
				const bool hasBeliefReligiousTroubadors = city.HasBelief("BELIEF_HEATHEN_CONVERSION");
				if (eYieldType == YIELD_DIPLOMATIC_SUPPORT && hasBeliefReligiousTroubadors && isHolyCity && isCityCenter)
					yieldChange += ((numTradeMajorCivs + numTradeCityStates) * 3);
			}

			{// BELIEF_RELIGIOUS_UNITY - +4 diplo for foreign city following (max 32) 
				const bool hasBeliefReligiousUnity = city.HasBelief("BELIEF_RELIGIOUS_UNITY");
				if (eYieldType == YIELD_DIPLOMATIC_SUPPORT && hasBeliefReligiousUnity && isHolyCity && isCityCenter)
					yieldChange += (numCityStatesFollowing * 4);
			}

			{// BELIEF_SALATT - Holy City - 2 Production, 1 Production per 8 followers (max 20)
				const bool hasBeliefSalatt = city.HasBelief("BELIEF_SALATT");
				if (eYieldType == YIELD_PRODUCTION && hasBeliefSalatt && isHolyCity && isCityCenter)
					yieldChange += 2;
				if (eYieldType == YIELD_PRODUCTION && hasBeliefSalatt && isHolyCity && isCityCenter)
					yieldChange += min(20, numFollowersGlobal / 8);
			}

			{// BELIEF_TITHE - Holy City - 4 Gold, 1 Gold per 4 followers (max 40)
				const bool hasBeliefTithe = city.HasBelief("BELIEF_TITHE");
				if (eYieldType == YIELD_GOLD && hasBeliefTithe && isHolyCity && isCityCenter)
					yieldChange += 2;
				if (eYieldType == YIELD_GOLD && hasBeliefTithe && isHolyCity && isCityCenter)
					yieldChange += min(40, numFollowersGlobal / 4);
			}

			{// BELIEF_ZAKATT - Holy City - 1 Scientific Influence, 1 per 16 followers (max 10)
				const bool hasBeliefZakatt = city.HasBelief("BELIEF_ZAKATT");
				if (eYieldType == YIELD_SCIENTIFIC_INSIGHT && hasBeliefZakatt && isHolyCity && isCityCenter)
					yieldChange += 1;
				if (eYieldType == YIELD_SCIENTIFIC_INSIGHT && hasBeliefZakatt && isHolyCity && isCityCenter)
					yieldChange += min(10, numFollowersGlobal / 16);
			}

			// example gives one production to every tile if you satisfy all criteria
			//const bool hasLibertyOpener = player.HasPolicy("POLICY_LIBERTY");
			//const bool hasBeliefCathedrals = city.HasBelief("BELIEF_CATHEDRALS");
			//const bool hasWalls = city.HasBuildingClass(BuildingClass("BUILDINGCLASS_WALLS"));
			//if (eYieldType == YIELD_PRODUCTION && hasLibertyOpener && hasBeliefCathedrals && hasWalls)
			//{
			//	yieldChange += 1;
			//}

			
			{ // BELIEF_DANCE_AURORA - Dance of the Aurora - on tundra tiles only - gives +1 production to bonus tiles, +1 culture to luxury tiles, +1 Gold to Strategic, and +1 faith to every other tundra tile
				const bool hasBeliefDanceOfTheAurora = city.HasBelief("BELIEF_DANCE_AURORA");
				if (eYieldType == YIELD_FAITH && hasBeliefDanceOfTheAurora && isTundra && noResource)
					yieldChange += 1;
				if (eYieldType == YIELD_PRODUCTION && hasBeliefDanceOfTheAurora && isTundra && hasBonus)
					yieldChange += 1;
				if (eYieldType == YIELD_CULTURE && hasBeliefDanceOfTheAurora && isTundra && hasLuxury)
					yieldChange += 1;
				if (eYieldType == YIELD_GOLD && hasBeliefDanceOfTheAurora && isTundra && hasStrategic)
					yieldChange += 1;
			}

			{ // BELIEF_DESERT_FOLKLORE - Desert Folklore - on Desert tiles only - gives +1 production to bonus tiles, +1 culture to luxury tiles, +1 Gold to Strategic, and +1 faith to every other Desert tile
				const bool hasBeliefDesertFolklore = city.HasBelief("BELIEF_DESERT_FOLKLORE");
				if (eYieldType == YIELD_FAITH && hasBeliefDesertFolklore && isDesert && noResource)
					yieldChange += 1;
				if (eYieldType == YIELD_PRODUCTION && hasBeliefDesertFolklore && isDesert && hasBonus)
					yieldChange += 1;
				if (eYieldType == YIELD_CULTURE && hasBeliefDesertFolklore && isDesert && hasLuxury)
					yieldChange += 1;
				if (eYieldType == YIELD_GOLD && hasBeliefDesertFolklore && isDesert && hasStrategic)
					yieldChange += 1;
			}

			{ // BELIEF_SACRED_WATERS - gives one tourism from lake and atoll tiles. Could change to lake and oasis in future if Atolls seems too good. Features don't work right now though. 
				const bool hasBeliefSacredWaters = city.HasBelief("BELIEF_SACRED_WATERS");
				const bool isLake = plot.isLake();
				const bool isOasis = plot.HasFeature("FEATURE_OASIS");
				if (eYieldType == YIELD_TOURISM && hasBeliefSacredWaters && (isLake || hasAnyAtoll || isOasis))
					yieldChange += 1;
			}
			
			{ // Policy_Cutural Exchange - gives 1 tourism to great person tile improvements. 
				const bool hasPolicyCulturalExchange = player.HasPolicy("POLICY_ETHICS");
				const bool isAcadamy = plot.HasImprovement("IMPROVEMENT_ACADEMY");
				const bool isCustomsHouse = plot.HasImprovement("IMPROVEMENT_CUSTOMS_HOUSE");
				const bool isManufactory = plot.HasImprovement("IMPROVEMENT_MANUFACTORY");
				const bool isHolySite = plot.HasImprovement("IMPROVEMENT_HOLY_SITE");
				const bool isDrydock = plot.HasImprovement("IMPROVEMENT_DOCK");
				const bool isChileDry = plot.HasImprovement("IMPROVEMENT_CHILE_DOCK");
				const bool isSacredGrove = plot.HasImprovement("IMPROVEMENT_SACRED_GROVE");
				if (eYieldType == YIELD_TOURISM && hasPolicyCulturalExchange && (isAcadamy || isCustomsHouse || isManufactory || isHolySite || isDrydock || isChileDry || isSacredGrove))
					yieldChange += 1;
			}
			

		}
	}


	// does not depend on player

	{ // don't stack lake and atoll yields
		if (plot.isLake() && hasAnyAtoll)
		{
			// remove whatever the lake would have given
			const CvYieldInfo& kYield = *GC.getYieldInfo(eYieldType);
			yieldChange -= kYield.getLakeChange();
		}
	}

	return yieldChange;
}







// Extra yields for buildings.
int CvPlayer::GetExtraYieldForBuilding
(
	const CvCity* pCity, 
	const BuildingTypes eBuilding, 
	const BuildingClassTypes eBuildingClass,
	const CvBuildingEntry* pBuildingInfo,
	const YieldTypes eYieldType, 
	const bool isPercentMod
	
) const
{
	int yieldChange = 0;

	const CvPlayer& player = *this;
	
	if (pCity != NULL) // in a city
	{
		const CvCity& city = *pCity;


		{ // adds +1 scientific insight to national college wings from peace gardens
			const bool hasBeliefPeaceGardens = city.HasBelief("BELIEF_PEACE_GARDENZ");
			const bool isNationalCollege1 = eBuildingClass == BuildingClass("BUILDINGCLASS_NATIONAL_COLLEGE");
			const bool isNationalCollege2 = eBuildingClass == BuildingClass("BUILDINGCLASS_NATIONAL_SCIENCE_1");
			const bool isNationalCollege3 = eBuildingClass == BuildingClass("BUILDINGCLASS_NATIONAL_SCIENCE_2");
			if (eYieldType == YIELD_SCIENTIFIC_INSIGHT && hasBeliefPeaceGardens && (isNationalCollege1 || isNationalCollege2 || isNationalCollege3))
				yieldChange += 1; 
		}
		
	}
	
	return yieldChange;
}






































