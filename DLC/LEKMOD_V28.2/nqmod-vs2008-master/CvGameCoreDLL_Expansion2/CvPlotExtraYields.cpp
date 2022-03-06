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
	// city that is/could work this tile
	const CvCity* pWorkingCity = getWorkingCity();
	// true if a is/could work this tile
	const bool hasAWorkingCity = pWorkingCity != NULL;
	// true if this tile is not pillaged
	const bool isNotPillaged = !IsRoutePillaged() && !IsImprovementPillaged();
	// true if we have a road or railroad
	const bool hasAnyRoute = eRouteType != NO_ROUTE && isNotPillaged;
	// true if this tile has any improvements
	const bool hasAnyImprovement = eImprovement != NO_IMPROVEMENT;
	// true if this is the actual city tile (not just a surrounding tile)
	const bool isCityCenter = getPlotCity() != NULL;
	// true if this tile has any atoll on it
	const bool hasAnyAtoll = HasAnyAtoll();
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

			// Dance of Aura - on tundra tiles only - gives +1 production to bonus tiles, +1 culture to luxury tiles, +1 Gold to Strategic, and +1 faith to every other tundra tile
			const bool hasBeliefdanceofaura = city.HasBelief("BELIEF_DANCE_AURORA"); 
			const bool hasBeliefdesertfolklore = city.HasBelief("BELIEF_DESERT_FOLKLORE");
			const bool istundra = HasTerrain(TERRAIN_TUNDRA);
			const bool isdesert = HasTerrain(TERRAIN_DESERT);
			const bool isbonus = HasResourceClass("RESOURCECLASS_BONUS");
			const bool isluxury = HasResourceClass("RESOURCECLASS_LUXURY");
			const bool isstrat1 = HasResourceClass("RESOURCECLASS_RUSH");
			const bool isstrat2 = HasResourceClass("RESOURCECLASS_MODERN");
			
			if (eYieldType == YIELD_FAITH && hasBeliefdanceofaura && istundra)
			{
				yieldChange += 1;
			}
			if (eYieldType == YIELD_PRODUCTION && hasBeliefdanceofaura && istundra && isbonus)
			{
				yieldChange += 1;
			}
			if (eYieldType == YIELD_FAITH && hasBeliefdanceofaura && istundra && isbonus)
			{
				yieldChange -= 1;
			}
			if (eYieldType == YIELD_CULTURE && hasBeliefdanceofaura && istundra && isluxury)
			{
				yieldChange += 1;
			}
			if (eYieldType == YIELD_FAITH && hasBeliefdanceofaura && istundra && isluxury)
			{
				yieldChange -= 1;
			}
			if (eYieldType == YIELD_GOLD && hasBeliefdanceofaura && istundra && (isstrat1 || isstrat2))
			{
				yieldChange += 1;
			}
			if (eYieldType == YIELD_FAITH && hasBeliefdanceofaura && istundra && (isstrat1 || isstrat2))
			{
				yieldChange -= 1;
			}
			

			// Desert Folklore - on Desert tiles only - gives +1 production to bonus tiles, +1 culture to luxury tiles, +1 Gold to Strategic, and +1 faith to every other Desert tile
			
			if (eYieldType == YIELD_FAITH && hasBeliefdesertfolklore && isdesert)
			{
				yieldChange += 1;
			}
			if (eYieldType == YIELD_PRODUCTION && hasBeliefdesertfolklore && isdesert && isbonus)
			{
				yieldChange += 1;
			}
			if (eYieldType == YIELD_FAITH && hasBeliefdesertfolklore && isdesert && isbonus)
			{
				yieldChange -= 1;
			}
			if (eYieldType == YIELD_CULTURE && hasBeliefdesertfolklore && isdesert && isluxury)
			{
				yieldChange += 1;
			}
			if (eYieldType == YIELD_FAITH && hasBeliefdesertfolklore && isdesert && isluxury)
			{
				yieldChange -= 1;
			}
			if (eYieldType == YIELD_GOLD && hasBeliefdesertfolklore && isdesert && (isstrat1 || isstrat2))
			{
				yieldChange += 1;
			}
			if (eYieldType == YIELD_FAITH && hasBeliefdesertfolklore && isdesert && (isstrat1 || isstrat2))
			{
				yieldChange -= 1;
			}
			
		}
	}
	else // does not depend on player
	{

		{ // don't stack lake and atoll yields
			if (isLake() && hasAnyAtoll)
			{
				// remove whatever the lake would have given
				const CvYieldInfo& kYield = *GC.getYieldInfo(eYieldType);
				yieldChange -= kYield.getLakeChange();
			}
		}

	}

	return yieldChange;
}













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

	if (pCity != NULL)
	{
		const CvCity& city = *pCity;

	}
	else // not in a city
	{

	}

	return yieldChange;
}






































