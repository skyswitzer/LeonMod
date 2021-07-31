/*	-------------------------------------------------------------------------------------------------------
	� 1991-2012 Take-Two Interactive Software and its subsidiaries.  Developed by Firaxis Games.  
	Sid Meier's Civilization V, Civ, Civilization, 2K Games, Firaxis Games, Take-Two Interactive Software 
	and their respective logos are all trademarks of Take-Two interactive Software, Inc.  
	All other marks and trademarks are the property of their respective owners.  
	All rights reserved. 
	------------------------------------------------------------------------------------------------------- */
#pragma once

#ifndef CIV5_BUILDER_TASKING_AI_H
#define CIV5_BUILDER_TASKING_AI_H

#define SAFE_ESTIMATE_NUM_EXTRA_PLOTS 64

class CvPlayer;
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  CLASS:      CvBuilderTaskingAI
//!  \brief		Deals with what builders need to deal with
//
//!  Key Attributes:
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
struct BuilderDirective
{
	typedef enum BuilderDirectiveType
	{
	    BUILD_IMPROVEMENT_ON_RESOURCE, // enabling a special resource
	    BUILD_IMPROVEMENT,			   // improving a tile
	    BUILD_ROUTE,				   // build a route on a tile
	    REPAIR,						   // repairing a pillaged route or improvement
	    CHOP,						   // remove a feature to improve production
	    REMOVE_ROAD,				   // remove a road from a plot
	    NUM_DIRECTIVES
#ifdef AUI_WARNING_FIXES
	} _BuilderDirectiveType;
#else
	};
#endif

	BuilderDirective() :
		m_eDirective(NUM_DIRECTIVES)
		, m_eBuild(NO_BUILD)
		, m_eResource(NO_RESOURCE)
		, m_sX(-1)
		, m_sY(-1)
		, m_sMoveTurnsAway(-1)
	{
	}

	BuilderDirectiveType m_eDirective;

	BuildTypes m_eBuild;
	ResourceTypes m_eResource;
#ifdef AUI_WARNING_FIXES
	int m_sX;
	int m_sY;
#else
	short m_sX;
	short m_sY;
#endif
	//int m_iGoldCost;
#ifdef AUI_WARNING_FIXES
	int m_sMoveTurnsAway;
#else
	short m_sMoveTurnsAway;
#endif
};

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//  CLASS:      CvBuilderTaskingAI
//!  \brief		Deals with what builders need to deal with
//
//!  Key Attributes:
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
class CvBuilderTaskingAI
{
public:
	CvBuilderTaskingAI(void);
	~CvBuilderTaskingAI(void);

	void Init(CvPlayer* pPlayer);
	void Uninit(void);

	//// Serialization routines
	void Read(FDataStream& kStream);
	void Write(FDataStream& kStream);

	void Update(void);
	void UpdateRoutePlots(void);

	bool EvaluateBuilder(CvUnit* pUnit, BuilderDirective* paDirectives, UINT uaDirectives, bool bKeepOnlyBest = false, bool bOnlyEvaluateWorkersPlot = false);

	void AddImprovingResourcesDirectives(CvUnit* pUnit, CvPlot* pPlot, int iMoveTurnsAway);
	void AddImprovingPlotsDirectives(CvUnit* pUnit, CvPlot* pPlot, int iMoveTurnsAway);
#ifdef AUI_WORKER_ADD_IMPROVING_MINOR_PLOTS_DIRECTIVES
	void AddImprovingMinorPlotsDirectives(CvUnit* pUnit, CvPlot* pPlot, int iMoveTurnsAway);
#endif
	void AddRouteDirectives(CvUnit* pUnit, CvPlot* pPlot, int iMoveTurnsAway);
	void AddRepairDirectives(CvUnit* pUnit, CvPlot* pPlot, int iMoveTurnsAway);
	void AddChopDirectives(CvUnit* pUnit, CvPlot* pPlot, int iMoveTurnsAway);
	void AddRemoveUselessRoadDirectives(CvUnit* pUnit, CvPlot* pPlot, int iMoveTurnsAway);
	void AddScrubFalloutDirectives(CvUnit* pUnit, CvPlot* pPlot, int iMoveTurnsAway);

	bool ShouldBuilderConsiderPlot(CvUnit* pUnit, CvPlot* pPlot);  // determines all the logistics if the builder should get to the plot
	int FindTurnsAway(CvUnit* pUnit, CvPlot* pPlot);  // returns -1 if no path can be found, otherwise it returns the # of turns to get there

	int GetBuildCostWeight(int iWeight, CvPlot* pPlot, BuildTypes eBuild);
	int GetBuildTimeWeight(CvUnit* pUnit, CvPlot* pPlot, BuildTypes eBuild, bool bIgnoreFeatureTime = false, int iAdditionalTime = 0);
	int GetResourceWeight(ResourceTypes eResource, ImprovementTypes eImprovement, int iQuantity);
#ifndef NQM_PRUNING
	bool IsImprovementBeneficial(CvPlot* pPlot, const CvBuildInfo& kBuild, YieldTypes eYield, bool bIsBreakEvenOK = false);
#endif

	CvCity* GetWorkingCity(CvPlot* pPlot);
	bool DoesBuildHelpRush(CvUnit* pUnit, CvPlot* pPlot, BuildTypes eBuild);

#ifdef AUI_WORKER_SCORE_PLOT_CHOP
	int ScorePlot(BuildTypes eBuild) const;
#elif defined(AUI_CONSTIFY)
	int ScorePlot() const;
#else
	int ScorePlot();
#endif

#ifdef AUI_CONSTIFY
	BuildTypes GetBuildTypeFromImprovement(ImprovementTypes eImprovement) const;
	BuildTypes GetRepairBuild() const;
	FeatureTypes GetFalloutFeature() const;
	BuildTypes GetFalloutRemove() const;
#else
	BuildTypes GetBuildTypeFromImprovement(ImprovementTypes eImprovement);
	//static YieldTypes GetDeficientYield (CvCity* pCity, bool bIgnoreHappiness = false); // this is different from the CityStrategy one because it checks unhappiness before declaring a food emergency
	BuildTypes GetRepairBuild(void);
	FeatureTypes GetFalloutFeature(void);
	BuildTypes GetFalloutRemove(void);
#endif

#ifdef AUI_WARNING_FIXES
	static void LogInfo(const CvString& str, CvPlayer* pPlayer, bool bWriteToOutput = false);
	static void LogYieldInfo(const CvString& strNewLogStr, CvPlayer* pPlayer); //Log yield related info to BuilderTaskingYieldLog.csv.
#else
	static void LogInfo(CvString str, CvPlayer* pPlayer, bool bWriteToOutput = false);
	static void LogYieldInfo(CvString strNewLogStr, CvPlayer* pPlayer); //Log yield related info to BuilderTaskingYieldLog.csv.
#endif

	static CvWeightedVector<BuilderDirective, 100, true> m_aDirectives;
	static FStaticVector<int, SAFE_ESTIMATE_NUM_EXTRA_PLOTS, true, c_eCiv5GameplayDLL, 0> m_aiNonTerritoryPlots; // plots that we need to evaluate that are outside of our territory

	//---------------------------------------PROTECTED MEMBER VARIABLES---------------------------------
protected:

	void LogFlavors(FlavorTypes eFlavor);
	void LogDirectives(CvUnit* pUnit);
	void LogDirective(BuilderDirective directive, CvUnit* pUnit, int iWeight, bool bChosen = false);

	void ConnectCitiesToCapital(CvCity* pPlayerCapital, CvCity* pTargetCity, RouteTypes eRoute);
	void ConnectCitiesForScenario(CvCity* pFirstCity, CvCity* pSecondCity, RouteTypes eRoute);

	void UpdateCurrentPlotYields(CvPlot* pPlot);
	void UpdateProjectedPlotYields(CvPlot* pPlot, BuildTypes eBuild);

	CvPlayer* m_pPlayer;
	BuildTypes m_eRepairBuild;
	CvPlotsVector m_aiPlots;
	bool m_bLogging;
	int m_iNumCities;

	CvPlot* m_pTargetPlot;
	int m_aiCurrentPlotYields[NUM_YIELD_TYPES];
	int m_aiProjectedPlotYields[NUM_YIELD_TYPES];

	FeatureTypes m_eFalloutFeature;
	BuildTypes m_eFalloutRemove;

#ifndef AUI_WORKER_UNHARDCODE_NO_REMOVE_FEATURE_THAT_IS_REQUIRED_FOR_UNIQUE_IMPROVEMENT
	bool m_bKeepMarshes;
	bool m_bKeepJungle;
#endif
};

#endif //CIV5_BUILDER_TASKING_AI_H