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
	const bool hasBonus = plot.HasResourceClass("RESOURCECLASS_BONUS");
	const bool hasLuxury = plot.HasResourceClass("RESOURCECLASS_LUXURY");
	const bool hasStrategic = plot.HasResourceClass("RESOURCECLASS_RUSH") || plot.HasResourceClass("RESOURCECLASS_MODERN");
	const bool noResource = !hasBonus && !hasLuxury && !hasStrategic;


	// depends on player
	if (tileOwner != NO_PLAYER)
	{
		const CvPlayer& player = GET_PLAYER(tileOwner);
		// depends on city
		if (pWorkingCity != NULL)
		{
			const CvCity& city = *pWorkingCity;

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

	}
	else // not in a city
	{

	}

	return yieldChange;
}






































