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






































