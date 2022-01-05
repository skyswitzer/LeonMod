--[[###############################################################
# Informations # ================================================	#
#																						#
# Author:			Black.Cobra a.k.a. Logharn								#
# Creation Date:	29/03/2013				 									#
#																						#
# Description:								 										#
# This MOD lets the player to view the Path chosen by units			#
# when using the "Move To" command ("M") or right clicking on		#
# the map. To view the Path just click on a moving unit.				#
# This MOD also tries to avoid the psychic behaviour that units	#
# have when on the destination plot, that they don't see, is 		#
# present a unit forcing players to choose a newer destination.	#
# 																						#
# Notes:																				#
# Integrates the scripts made by Pazyryk to save the content of	#
# tables.																			#
# 																						#
# ===============================================================	#
###############################################################--]]

include("FLuaVector.lua");
include("UnitPath_Support.lua");
include("UnitPath_Options.lua");
include("TableSaverLoader.lua"); --> Pazyryk's script

-- <-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><->
-- |                    GLOBAL TABLES AND VARIABLES                    |
-- <-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><->

gTupMainPathStore = {bTableInitializer = true}; --> Stores the path and other informations of units' movement

gTupGlobalVariables = {bIsEndTurn = false, --> Stores Colour constants and some variables used to check game-play events
							  bCTRLSHIFTPressed = false,
							  tColourForStandardPath = {tWhite = FupColorConverter(CupWhite_R,CupWhite_G,CupWhite_B,CupWhite_A),
																 tWhiteAlpha = FupColorConverter(CupWhiteA_R,CupWhiteA_G,CupWhiteA_B,CupWhiteA_A),
																 -- tDarkCyan = FupColorConverter(0,100,255,255),
																 tCyan = FupColorConverter(CupCyan_R,CupCyan_G,CupCyan_B,CupCyan_A),
																 tRed = FupColorConverter(CupRed_R,CupRed_G,CupRed_B,CupRed_A),
																 -- tRedAlpha = FupColorConverter(255,0,0,112),
																 tOrange = FupColorConverter(CupOrange_R,CupOrange_G,CupOrange_B,CupOrange_A),
																 -- tOrangeAlpha = FupColorConverter(255,112,0,112),
																 tYellow = FupColorConverter(CupYellow_R,CupYellow_G,CupYellow_B,CupYellow_A),
																 tGreen = FupColorConverter(CupGreen_R,CupGreen_G,CupGreen_B,CupGreen_A),
																 tDarkGreen = FupColorConverter(CupDarkGreen_R,CupDarkGreen_G,CupDarkGreen_B,CupDarkGreen_A),
																 tFuchsia = FupColorConverter(CupFuchsia_R,CupFuchsia_G,CupFuchsia_B,CupFuchsia_A),
																 -- tFuchsiaAlpha = FupColorConverter(255,0,255,112),
																 -- tBlue = FupColorConverter(0,0,255,255)
																 },
							  tHighlightsStyles = {sBigHexHighlight = "EditorHexStyle1",
														  sInnerHexHighlight = "TempBorder",
														  sOuterHexHighlight = "EditorHexStyle2"},
							  tForCTRLSHIFT = {tPlotsToHighlight = {Destinations = {RedPlots = {},
																									  FuchsiaPlots = {}},
																				 Units = {}},
													 tXY = {}}};

-- <-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><->
-- |                  FUNCTIONS CALLED BY GAME EVENTS                  |
-- <-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><->
function FupRemovePathGraphics() --> Called by Events: "ActivePlayerTurnEnd";
											--							 "SerialEventCityCreated";
											--							 "SerialEventEnterCityScreen";

	local TupHighlightsStyles = gTupGlobalVariables.tHighlightsStyles

	Events.ClearHexHighlightStyle(TupHighlightsStyles.sBigHexHighlight)
	Events.ClearHexHighlightStyle(TupHighlightsStyles.sInnerHexHighlight)
	Events.ClearHexHighlightStyle(TupHighlightsStyles.sOuterHexHighlight)
	Events.RemoveAllArrowsEvent();
end --> FupRemovePathGraphics

function FupClearUnitPathTable() --> Called by Events: "ActivePlayerTurnStart"
	local VupActivePlayer = Players[Game.GetActivePlayer()]
	local TupMainPathStore = gTupMainPathStore
	gTupGlobalVariables.bIsEndTurn = false;

	FupRemovePathGraphics();

	for k, _ in pairs(TupMainPathStore) do --> Iterate through the table and check if the unit exists
		if type(k) == "number" then
			if (VupActivePlayer:GetUnitByID(k) == nil) then	--> If one unit dies is removed from the table when turn start
				gTupMainPathStore[k] = nil;
			end
		end
	end
end --> FupClearUnitPathTable

function FupUnitPathViewer(VupVariablePassedByEventA, VupVariablePassedByEventB, VupVariablePassedByEventC) --> Called by Events: "UnitSelectionChanged";
																																				--							 "SerialEventUnitFlagSelected";
																														
	if gTupGlobalVariables.bCTRLSHIFTPressed then --> If we select a unit while having CTRL+SHIFT pressed exit the function
		return;
	end

	FupRemovePathGraphics();

	local TupUnitHead = UI.GetHeadSelectedUnit();

	if (TupUnitHead ~= nil) then
		local TupCommonUnitValues = FupCommonUnitValues(TupUnitHead);
		local TupGlobalVariables = gTupGlobalVariables
		local TupColourForStandardPath = TupGlobalVariables.tColourForStandardPath
		local TupHighlightsStyles = TupGlobalVariables.tHighlightsStyles
		
		if (gTupMainPathStore[TupCommonUnitValues.vID] ~= nil) and not TupCommonUnitValues.bIsAutomated then --> We have a table and unit isn't automated
			local TupMainUnitPath = gTupMainPathStore[TupCommonUnitValues.vID]
			local TupUnitLastPathPlot --> DO NOT USE LAST MISSION PLOT
			local VupEnumMainUnitPath = table.maxn(TupMainUnitPath.tPath)
			local VupCurrentTurn = Game.GetGameTurn();
			
			if (VupEnumMainUnitPath > 0) then
				TupUnitLastPathPlot = Map.GetPlot(TupMainUnitPath.tPath[TupMainUnitPath.vIndexes].x,
															 TupMainUnitPath.tPath[TupMainUnitPath.vIndexes].y);
			end

			if not TupMainUnitPath.bIsBuildingRoute then --> Unit is not building a route
				if (TupGlobalVariables.bIsEndTurn --> Unit must be selected after the End Turn check, if so it will be re-routed if not already
				and TupCommonUnitValues.bIsReadyToMove
				and not TupMainUnitPath.bCanSeeNewPlot
				and not (TupMainUnitPath.vRedirectedInTurn == VupCurrentTurn)
				and not (TupCommonUnitValues.tCurrentPlot == TupUnitLastPathPlot)) then
					TupMainUnitPath.vArrivedInTurn = -1
					FupPathChanger(TupMainUnitPath, TupCommonUnitValues)
					return;
				end

				if ((TupCommonUnitValues.tCurrentPlot == TupUnitLastPathPlot) --> If unit reached its last path plot or is on its last mission plot
			   or (TupCommonUnitValues.tCurrentPlot == TupCommonUnitValues.tMissionLastPlot) -- its "Arrival" variable is filled with the current game turn
			   or (TupUnitLastPathPlot ~= TupCommonUnitValues.tMissionLastPlot)) then
					if (TupMainUnitPath.vArrivedInTurn == -1) then
						TupMainUnitPath.vArrivedInTurn = VupCurrentTurn;
					elseif ((VupCurrentTurn - TupMainUnitPath.vArrivedInTurn) > 2) then --> If Current Game Turn minus Game Turn of Arrival is
						FupRemovePathGraphics()														  --  greater than two the path table is removed
						gTupMainPathStore[TupCommonUnitValues.vID] = nil
						return;
					end
				end

				for c = 1, VupEnumMainUnitPath do --> Loop to highlight the stored path
					if (c == 1) then --> First path plot in DarkCyan
						FupHexHighlighter(TupMainUnitPath.tPath[c].x,
												TupMainUnitPath.tPath[c].y,
												TupColourForStandardPath.tYellow,
												TupHighlightsStyles.sBigHexHighlight);
												
					elseif (c == TupMainUnitPath.vIndexes) then --> Last path plot in Red
						FupHexHighlighter(TupMainUnitPath.tPath[c].x,
												TupMainUnitPath.tPath[c].y,
												TupColourForStandardPath.tRed,
												TupHighlightsStyles.sBigHexHighlight);
												
					elseif (c > TupMainUnitPath.vIndexes) then --> Discarded path plots in White
						FupHexHighlighter(TupMainUnitPath.tPath[c].x,
												TupMainUnitPath.tPath[c].y,
												TupColourForStandardPath.tWhite,
												TupHighlightsStyles.sOuterHexHighlight);
												
					else --> Path plots between first and last in Cyan
						FupHexHighlighter(TupMainUnitPath.tPath[c].x,
												TupMainUnitPath.tPath[c].y,
												TupColourForStandardPath.tCyan,
												TupHighlightsStyles.sOuterHexHighlight);
												
					end
				end

				if (VupVariablePassedByEventC == nil) then --> "Events.SerialEventUnitFlagSelected" pass only two function parameters so if the third 
																		 --  is nil means that we clicked upon the unit flag and the ETA is shown
																		 
					FupShowDestinationsWithETA(TupMainUnitPath, TupCommonUnitValues);
				end
				
				return;
			else --> Our unit is building a route
				local VupBuildTypeDescription = GameInfo.Builds[TupUnitHead:GetBuildType()].Description;

				if (VupBuildTypeDescription == "TXT_KEY_BUILD_ROAD") or (VupBuildTypeDescription == "TXT_KEY_BUILD_RAILROAD") then
					VupBuildTypeDescription = 1;
				end

				if (TupCommonUnitValues.tCurrentPlot == TupCommonUnitValues.tMissionLastPlot) or (VupBuildTypeDescription ~= 1) then
					gTupMainPathStore[TupCommonUnitValues.vID] = nil --> If our unit is in its last plot or is building something else for 
					return;														 --  some reason remove the stored table and exit function
				end

				if (VupEnumMainUnitPath == 0) then --> If we don't have a stored path, it's highlighted only the last plot
					FupHexHighlighter(TupCommonUnitValues.tMissionLastPlot:GetX(),
											TupCommonUnitValues.tMissionLastPlot:GetY(),
											TupColourForStandardPath.tGreen,
											TupHighlightsStyles.sBigHexHighlight)
											
					Events.SpawnArrowEvent(TupCommonUnitValues.tCurrentPlot:GetX(),
												  TupCommonUnitValues.tCurrentPlot:GetY(),
												  TupCommonUnitValues.tMissionLastPlot:GetX(),
												  TupCommonUnitValues.tMissionLastPlot:GetY());
												  
				else --> If we have a table and a stored path
					if (TupUnitLastPathPlot ~= TupCommonUnitValues.tMissionLastPlot) then --> If the last plot in the stored table is different from the mission
						TupMainUnitPath.tPath = {}														 --  last plot of the unit means that we changed something so the stored
																												 --  table is cleared and is highlighted only the last plot.
						FupHexHighlighter(TupCommonUnitValues.tMissionLastPlot:GetX(),
												TupCommonUnitValues.tMissionLastPlot:GetY(),
												TupColourForStandardPath.tGreen,
												TupHighlightsStyles.sBigHexHighlight)
						
						Events.SpawnArrowEvent(TupCommonUnitValues.tCurrentPlot:GetX(),
													  TupCommonUnitValues.tCurrentPlot:GetY(),
													  TupCommonUnitValues.tMissionLastPlot:GetX(),
													  TupCommonUnitValues.tMissionLastPlot:GetY());
													  
					else --> Stored last plot and Mission last plot are the same, so we highlight all the path
						for c = 1, VupEnumMainUnitPath do --> Loop to highlight the stored path
							if (c == VupEnumMainUnitPath) then --> Last path plot in Green
								FupHexHighlighter(TupMainUnitPath.tPath[c].x,
														TupMainUnitPath.tPath[c].y,
														TupColourForStandardPath.tGreen,
														TupHighlightsStyles.sBigHexHighlight);
														
							else
								FupHexHighlighter(TupMainUnitPath.tPath[c].x,
														TupMainUnitPath.tPath[c].y,
														TupColourForStandardPath.tDarkGreen,
														TupHighlightsStyles.sOuterHexHighlight);
							end
						end
					end
					
					return;
				end --> if (VupEnumMainUnitPath == 0)
			end --> if not TupMainUnitPath.bIsBuildingRoute
		elseif (TupCommonUnitValues.tCurrentPlot ~= TupCommonUnitValues.tMissionLastPlot) and TupCommonUnitValues.bIsAutomated then --> Unit is automated and 
																																									       --  its destination is far
			gTupMainPathStore[TupCommonUnitValues.vID] = nil --> Clear any potential table referred to the automated worker
			
			FupHexHighlighter(TupCommonUnitValues.tMissionLastPlot:GetX(),
									TupCommonUnitValues.tMissionLastPlot:GetY(),
									TupColourForStandardPath.tRed,
									TupHighlightsStyles.sBigHexHighlight)
									
			Events.SpawnArrowEvent(TupCommonUnitValues.tCurrentPlot:GetX(),
										  TupCommonUnitValues.tCurrentPlot:GetY(),
										  TupCommonUnitValues.tMissionLastPlot:GetX(),
										  TupCommonUnitValues.tMissionLastPlot:GetY());
			
			return;
		end --> if (gTupMainPathStore[TupCommonUnitValues.vID] ~= nil) and not TupCommonUnitValues.bIsAutomated
	end --> if (TupUnitHead ~= nil)
end --> FupUnitPathViewer

function FupCatchUnitPathfinder(TupUnitPathfinder) --> Called by Events: "UIPathFinderUpdate";
	local VupEnumUnitPathfinder = table.maxn(TupUnitPathfinder);

	if (VupEnumUnitPathfinder > 0) then --> Since Game Pathfinder is called frequently I check how many indexes have the table
		local TupUnitHead = UI.GetHeadSelectedUnit()
		local TupCommonUnitValues = FupCommonUnitValues(TupUnitHead)
		local VupLastTurnMove = TupUnitPathfinder[VupEnumUnitPathfinder].turn;

		while (gTupMainPathStore[TupCommonUnitValues.vID] ~= nil) do --> Just to be sure to delete the table
			gTupMainPathStore[TupCommonUnitValues.vID] = nil;
		end

		if (VupLastTurnMove > 1) then --> Moves that will take one turn are useless to be stored
			gTupMainPathStore[TupCommonUnitValues.vID] = {tPath = TupUnitPathfinder,
																		 bCanSeeNewPlot = false,
																		 bIsBuildingRoute = false,
																		 bIsMilitary = TupUnitHead:IsCombatUnit(),
																		 vArrivedInTurn = -1,
																		 vETA = (Game.GetGameTurn() + VupLastTurnMove),
																		 vIndexes = VupEnumUnitPathfinder,
																		 vMovedInTurn = Game.GetGameTurn(),
																		 vRedirectedInTurn = -1};

			if (TupCommonUnitValues.sType == "UNIT_GREAT_GENERAL") or (TupCommonUnitValues.sType == "UNIT_GREAT_ADMIRAL") then
				gTupMainPathStore[TupCommonUnitValues.vID].bIsMilitary = true;
			end

			return;
		end
	end
end --> FupCatchUnitPathfinder

function FupUnitBuildRouteTo(VupOldInterface, VupNewInterface) --> Called by Events: "InterfaceModeChanged";
	if (VupOldInterface == 6) then --> If we clicked on a tile after using the "Route to" command (6)
		local TupUnitHead = UI.GetHeadSelectedUnit()
		local TupCommonUnitValues = FupCommonUnitValues(TupUnitHead);

		if (gTupMainPathStore[TupCommonUnitValues.vID] == nil) then --> If selected unit doesn't have a path table, one is created with basic needs
			gTupMainPathStore[TupCommonUnitValues.vID] = {tPath = {},
															  bIsBuildingRoute = true,
															  bIsMilitary = false};
		else --> If selected unit has already a "path table" is changed one variable
			gTupMainPathStore[TupCommonUnitValues.vID].bIsBuildingRoute = true;
		end
	end
end --> FupUnitBuildRouteTo

function FupHighlightPathCursorPlot(VupUnderCursorX, VupUnderCursorY) --> Called by Events: "SerialEventMouseOverHex";
	if gTupGlobalVariables.bCTRLSHIFTPressed then --> CTRL + SHIFT must be pressed, if so fill some variables
		local TupGlobalVariables = gTupGlobalVariables
		local TupColourForStandardPath = TupGlobalVariables.tColourForStandardPath
		local TupHighlightsStyles = TupGlobalVariables.tHighlightsStyles
		local TupPlotsToHighlight = TupGlobalVariables.tForCTRLSHIFT.tPlotsToHighlight
		local TupXY = TupGlobalVariables.tForCTRLSHIFT.tXY
		local TupCurrentPlotUnderCursor = Map.GetPlot(VupUnderCursorX, VupUnderCursorY)
		local VupActivePlayer = Players[Game.GetActivePlayer()]
		local VupEnumXY = table.maxn(TupXY)

		local function FupAllDestinationHexesInWhite(SupWhatMustBeBlanked, TupPlotsToHighlight) --> function used only to make all stored plots white
			if (SupWhatMustBeBlanked == "Destinations") and (TupPlotsToHighlight ~= nil) then
				for k, v in pairs(TupPlotsToHighlight) do
					if (k == "FuchsiaPlots") or (k == "RedPlots") then
						FupAllDestinationHexesInWhite("Destinations", v)
					elseif type(k) == "number" then
						FupHexHighlighter(TupPlotsToHighlight[k]:GetX(),
												TupPlotsToHighlight[k]:GetY(),
												TupColourForStandardPath.tWhiteAlpha,
												TupHighlightsStyles.sBigHexHighlight)
					end
				end
			elseif (SupWhatMustBeBlanked == "Units") and (TupPlotsToHighlight ~= nil) then
				for k, _ in pairs(TupPlotsToHighlight) do
					FupHexHighlighter(TupPlotsToHighlight[k]:GetX(),
											TupPlotsToHighlight[k]:GetY(),
											TupColourForStandardPath.tWhiteAlpha,
											TupHighlightsStyles.sOuterHexHighlight)
				end
			end
		end
		
		for c = 1, VupEnumXY do --> Iterate from 1 to the number of Keys contained in the reference table to check the plots under the cursor
			if (TupCurrentPlotUnderCursor == TupXY[c].tMissionLastPlot) then --> If the plot under is as one of the last plots contained into the table
				local TupMainUnitPath
				local TupCommonUnitValues
				local TupHexToMakeGamePlayFX
				local VupEnumMainUnitPathByIndexes

				FupRemovePathGraphics() --> Remove all graphics
				FupAllDestinationHexesInWhite("Destinations", TupPlotsToHighlight.Destinations) --> Make destinations plots in white
				FupAllDestinationHexesInWhite("Units", TupPlotsToHighlight.Units) --> Make units plot in white
				
				if (TupXY[c].vMultiplier == 1) then --> If the reference key of the table has the vMultiplier key with a value of one
					for k, _ in pairs(TupXY[c]) do --> Iterate through that table
						if type(k) == "number" then --> The only numeric key inside the table is our unit ID!! Now fill the variables!!!
							TupMainUnitPath = gTupMainPathStore[k]
							TupCommonUnitValues = FupCommonUnitValues(VupActivePlayer:GetUnitByID(k))
							VupEnumMainUnitPathByIndexes = TupMainUnitPath.vIndexes;
						end
					end

					if (TupXY[c].tMissionLastPlot ~= TupCommonUnitValues.tCurrentPlot) then --> Also the last plot must be not the same plot of that unit
						TupHexToMakeGamePlayFX = ToHexFromGrid(Vector2(TupCommonUnitValues.tCurrentPlot:GetX(),
																					  TupCommonUnitValues.tCurrentPlot:GetY()));
					
						for i = 1, VupEnumMainUnitPathByIndexes do --> If so lets highlight all its path!
							local TupPlotToBeHighlighted = Map.GetPlot(TupMainUnitPath.tPath[i].x, TupMainUnitPath.tPath[i].y);
						
							if not FupCompareValueAgainstTable(TupPlotToBeHighlighted, TupPlotsToHighlight) then --> If the plot that is currently taken in
								if (i == 1) then --> First path plot in Yellow												 --  consideration if is not inside the
									FupHexHighlighter(TupMainUnitPath.tPath[i].x,											 --  reference table means that we can use
															TupMainUnitPath.tPath[i].y,											 --  the bigger and outer highlight styles
															TupColourForStandardPath.tYellow,
															TupHighlightsStyles.sBigHexHighlight);
															
								elseif (i < VupEnumMainUnitPathByIndexes) then --> Path plots between first and last in Cyan
									FupHexHighlighter(TupMainUnitPath.tPath[i].x,
															TupMainUnitPath.tPath[i].y,
															TupColourForStandardPath.tCyan,
															TupHighlightsStyles.sOuterHexHighlight);
								elseif (i == VupEnumMainUnitPathByIndexes) then
									FupHexHighlighter(TupMainUnitPath.tPath[i].x,
															TupMainUnitPath.tPath[i].y,
															TupColourForStandardPath.tRed,
															TupHighlightsStyles.sBigHexHighlight);
								end
							else --> If the plot is inside the reference table we use smaller highlight styles so white hexes are still visible!
								if (i == 1) then --> First path plot in Yellow
									FupHexHighlighter(TupMainUnitPath.tPath[i].x,
															TupMainUnitPath.tPath[i].y,
															TupColourForStandardPath.tYellow,
															TupHighlightsStyles.sInnerHexHighlight);
															
								elseif (i < VupEnumMainUnitPathByIndexes) then --> Path plots between first and last in Cyan
									FupHexHighlighter(TupMainUnitPath.tPath[i].x,
															TupMainUnitPath.tPath[i].y,
															TupGlobalVariables.tColourForStandardPath.tCyan,
															TupGlobalVariables.tHighlightsStyles.sInnerHexHighlight);
								
								elseif (i == VupEnumMainUnitPathByIndexes) then
									FupHexHighlighter(TupMainUnitPath.tPath[i].x,
															TupMainUnitPath.tPath[i].y,
															TupColourForStandardPath.tRed,
															TupHighlightsStyles.sBigHexHighlight);
								end
							end	
						end
						
						if FupCompareValueAgainstTable(TupCommonUnitValues.tCurrentPlot, TupPlotsToHighlight.Units) then --> Finishing the above iteration we
							FupHexHighlighter(TupCommonUnitValues.tCurrentPlot:GetX(),												 --  also check that the unit plot is
													TupCommonUnitValues.tCurrentPlot:GetY(),												 --  inside the unit's plot table, if 
													TupColourForStandardPath.tOrange,														 --  so we highlight also its plot in
													TupHighlightsStyles.sOuterHexHighlight);												 --  orange
						end
						
						UI.AddPopupText(VupUnderCursorX, VupUnderCursorY, --> Since our cursor is on the destination of the unit we show popups like pressing CTRL + SHIFT
											 TupXY[c][TupCommonUnitValues.vID].sPopupText01,
											 TupXY[c][TupCommonUnitValues.vID].vPopupDelay01)
						UI.AddPopupText(VupUnderCursorX, VupUnderCursorY,
											 TupXY[c][TupCommonUnitValues.vID].sPopupText02,
											 TupXY[c][TupCommonUnitValues.vID].vPopupDelay02);
						Events.GameplayFX(TupHexToMakeGamePlayFX.x, TupHexToMakeGamePlayFX.y, -1); --> Do some fireworks!
					else --> If our unit stands on its last mission plot, simply show a popup and highlight the plot in red
						FupHexHighlighter(TupCommonUnitValues.tCurrentPlot:GetX(),
												TupCommonUnitValues.tCurrentPlot:GetY(),
												TupColourForStandardPath.tRed,
												TupHighlightsStyles.sBigHexHighlight);
						UI.AddPopupText(VupUnderCursorX, VupUnderCursorY,
											 TupXY[c][TupCommonUnitValues.vID].sPopupText02, 0.00);
					end
				else --> If the reference key of the table has the vMultiplier key with a value greater than one
					for k, _ in pairs(TupXY[c]) do --> Iterate through the table and for every numeric key highlight plots and show popups
						if type(k) == "number" then
							TupCommonUnitValues = FupCommonUnitValues(VupActivePlayer:GetUnitByID(k))
							TupHexToMakeGamePlayFX = ToHexFromGrid(Vector2(TupCommonUnitValues.tCurrentPlot:GetX(),
																						  TupCommonUnitValues.tCurrentPlot:GetY()));
							
							if FupCompareValueAgainstTable(TupCommonUnitValues.tCurrentPlot, TupPlotsToHighlight.Units) then
								FupHexHighlighter(TupCommonUnitValues.tCurrentPlot:GetX(),
														TupCommonUnitValues.tCurrentPlot:GetY(),
														TupColourForStandardPath.tOrange,
														TupHighlightsStyles.sOuterHexHighlight);
							end
							
							FupHexHighlighter(TupCommonUnitValues.tMissionLastPlot:GetX(),
													TupCommonUnitValues.tMissionLastPlot:GetY(),
													TupColourForStandardPath.tFuchsia,
													TupHighlightsStyles.sBigHexHighlight);
							UI.AddPopupText(VupUnderCursorX, VupUnderCursorY,
												 TupXY[c][TupCommonUnitValues.vID].sPopupText01,
												 TupXY[c][TupCommonUnitValues.vID].vPopupDelay01)
							UI.AddPopupText(VupUnderCursorX, VupUnderCursorY,
												 TupXY[c][TupCommonUnitValues.vID].sPopupText02,
												 TupXY[c][TupCommonUnitValues.vID].vPopupDelay02);
							Events.GameplayFX(TupHexToMakeGamePlayFX.x, TupHexToMakeGamePlayFX.y, -1); --> Do some fireworks!
						end
					end
				end
			elseif (TupCurrentPlotUnderCursor:GetUnit() ~= nil) then --> If the plot under the cursor has got a unit
				local VupUnitID = TupCurrentPlotUnderCursor:GetUnit():GetID() --> Get the ID of this unit
	
				if (TupXY[c][VupUnitID] ~= nil) then --> If the key contains a table with the unit ID lets highlight!
					local TupMainUnitPath = gTupMainPathStore[(VupUnitID)]
					local TupCommonUnitValues = FupCommonUnitValues(VupActivePlayer:GetUnitByID(VupUnitID))
					local VupEnumMainUnitPathByIndexes = TupMainUnitPath.vIndexes;
					local TupHexToMakeGamePlayFX = ToHexFromGrid(Vector2(TupCommonUnitValues.tMissionLastPlot:GetX(),
																						  TupCommonUnitValues.tMissionLastPlot:GetY()));

					FupRemovePathGraphics()
					FupAllDestinationHexesInWhite("Destinations", TupPlotsToHighlight.Destinations)
					FupAllDestinationHexesInWhite("Units", TupPlotsToHighlight.Units)

					for i = 1, VupEnumMainUnitPathByIndexes do
						local TupPlotToBeHighlighted = Map.GetPlot(TupMainUnitPath.tPath[i].x, TupMainUnitPath.tPath[i].y);
					
						if not FupCompareValueAgainstTable(TupPlotToBeHighlighted, TupPlotsToHighlight) then 
							if (i == 1) then --> First path plot in Yellow
								FupHexHighlighter(TupMainUnitPath.tPath[i].x,
														TupMainUnitPath.tPath[i].y,
														TupColourForStandardPath.tYellow,
														TupHighlightsStyles.sBigHexHighlight);
														
							else --> Path plots between first and last in Cyan
								FupHexHighlighter(TupMainUnitPath.tPath[i].x,
														TupMainUnitPath.tPath[i].y,
														TupColourForStandardPath.tCyan,
														TupHighlightsStyles.sOuterHexHighlight);
							end
						else
							if (i == 1) then --> First path plot in Yellow
								FupHexHighlighter(TupMainUnitPath.tPath[i].x,
														TupMainUnitPath.tPath[i].y,
														TupColourForStandardPath.tYellow,
														TupHighlightsStyles.sInnerHexHighlight);
														
							elseif (i < VupEnumMainUnitPathByIndexes) then --> Path plots between first and last in Cyan
								FupHexHighlighter(TupMainUnitPath.tPath[i].x,
														TupMainUnitPath.tPath[i].y,
														TupGlobalVariables.tColourForStandardPath.tCyan,
														TupGlobalVariables.tHighlightsStyles.sInnerHexHighlight);
							
							elseif (i == VupEnumMainUnitPathByIndexes) then
								if (TupXY[c].vMultiplier == 1) then
									FupHexHighlighter(TupMainUnitPath.tPath[i].x,
															TupMainUnitPath.tPath[i].y,
															TupColourForStandardPath.tRed,
															TupHighlightsStyles.sBigHexHighlight);
															
								else
									FupHexHighlighter(TupMainUnitPath.tPath[i].x,
															TupMainUnitPath.tPath[i].y,
															TupColourForStandardPath.tFuchsia,
															TupHighlightsStyles.sBigHexHighlight);
								end					
							end
						end	
					end

					if FupCompareValueAgainstTable(TupCommonUnitValues.tCurrentPlot, TupPlotsToHighlight.Units) then
						FupHexHighlighter(TupCommonUnitValues.tCurrentPlot:GetX(),
												TupCommonUnitValues.tCurrentPlot:GetY(),
												TupColourForStandardPath.tOrange,
												TupHighlightsStyles.sOuterHexHighlight);
					end
					
					UI.AddPopupText(VupUnderCursorX, VupUnderCursorY,
										 TupXY[c][VupUnitID].sPopupText02, 0.00);
					Events.GameplayFX(TupHexToMakeGamePlayFX.x, TupHexToMakeGamePlayFX.y, -1); --> Do some fireworks!
				end
			end
		end
	end
end --> FupHighlightPathCursorPlot

-- <-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><->
-- |                     EVENTS CALLING FUNCTIONS                      |
-- <-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><->

Events.ActivePlayerTurnEnd.Add(FupRemovePathGraphics);
Events.SerialEventCityCreated.Add(FupRemovePathGraphics);
Events.SerialEventEnterCityScreen.Add(FupRemovePathGraphics);

Events.ActivePlayerTurnStart.Add(FupClearUnitPathTable);

Events.UnitSelectionChanged.Add(FupUnitPathViewer);
Events.SerialEventUnitFlagSelected.Add(FupUnitPathViewer);

Events.UIPathFinderUpdate.Add(FupCatchUnitPathfinder);

Events.InterfaceModeChanged.Add(FupUnitBuildRouteTo);

Events.SerialEventMouseOverHex.Add(FupHighlightPathCursorPlot);

-- <-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><->
-- |                 TABLE SAVER FUNCTIONS by PAZYRYK                  |
-- <-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><->
-- Functions modified a bit by me
function PazyrykOnEnterGame()
	local DBQuery = Modding.OpenSaveData().Query
	print ("Player entering game ...")
	RegisterOnSaveCallback()
	-- we need to know if this is after a load from a saved game; use the presence of MyMod_Info table to do this
	local bNewGame = true
	for row in DBQuery("SELECT name FROM sqlite_master WHERE name='upMainPathStore_Info'") do		--change 'MyMod' to prefix used in TableSaverLoader.lua
		if row.name then bNewGame = false end
	end
	if bNewGame then
		TableSave(gTupMainPathStore, "upMainPathStore")		--here to make sure save happens before any attempts to load
	else
		TableLoad(gTupMainPathStore, "upMainPathStore")
	end

	Players[Game.GetActivePlayer()]:AddNotification(-1, --> NotificationTypes.NOTIFICATION_GENERIC
																	"[COLOR_PLAYER_YELLOW_TEXT]UNIT PATH VIEWER[ENDCOLOR][COLOR_LIGHT_GREY] by [ENDCOLOR][COLOR_PLAYER_BARBARIAN_ICON]Black.Cobra[ENDCOLOR][NEWLINE]"..
																	"[COLOR_LIGHT_GREY]Thanks for using my MOD![ENDCOLOR][NEWLINE][NEWLINE]"..
																	"[COLOR_GREEN]INSTRUCTIONS:[ENDCOLOR][NEWLINE]"..
																	"[COLOR_LIGHT_GREY]Most of the features of this MOD are naturally activated, just play as usual or refer to the MOD description for details. Here I will cover only the use of hotkeys.[ENDCOLOR][NEWLINE][NEWLINE]"..
																	"[COLOR_PLAYER_ORANGE_TEXT]Hotkeys[ENDCOLOR][NEWLINE]"..
																	"[COLOR_PLAYER_LIGHT_ORANGE_TEXT]CTRL+SHIFT:[ENDCOLOR][COLOR_LIGHT_GREY] will highlight all destination tiles of military units in red or fuchsia (if two or more units share the same plot) and from every tile will appear a pop up telling you their names and ETA. In orange the plots where these units stand, but only if that hex isn't already a destination of another unit. Lastly, while keeping CTRL+SHIFT, if you go over a red or orange hex the path of that unit is shown. Good game![ENDCOLOR]",
																	"[COLOR_PLAYER_YELLOW_TEXT]UNIT PATH VIEWER[ENDCOLOR][NEWLINE]"..
																	"by [COLOR_PLAYER_BARBARIAN_ICON]Black.Cobra[ENDCOLOR]",
																	-1,
																	-1)
end
Events.LoadScreenClose.Add(PazyrykOnEnterGame)

function PazyrykOnEndActivePlayerTurn()
	TableSave(gTupMainPathStore, "upMainPathStore")			--this could be less frequent if we know autosave frequency
end
Events.ActivePlayerTurnEnd.Add(PazyrykOnEndActivePlayerTurn)

----------------------------------------------------------------
-- Save Handler
----------------------------------------------------------------
function UnitPathInptHdlr(uiMsg, wParam, lParam)

	if uiMsg == KeyEvents.KeyDown then

		if wParam == Keys.VK_F11 then
			TableSave(gTupMainPathStore, "upMainPathStore")
		    print("Quicksaving...")
			UI.QuickSave()
        	return true

		elseif wParam == Keys.S and UIManager:GetControl() then
			print("ctrl-s detected")
			PazyrykOnSaveClicked()
			return true

		elseif wParam == Keys.VK_RETURN then --> When "Return" is pressed check button text for "End Turn"
			local VupEndTurnButtonText = ContextPtr:LookUpControl("/InGame/WorldView/ActionInfoPanel/EndTurnText"):GetText()
			local VupNextTurnText = Locale.ConvertTextKey("TXT_KEY_NEXT_TURN")

			if (VupEndTurnButtonText == VupNextTurnText) then
				Game.CycleUnits(true)			 		  --> Cycle units so if one unit is selected it will be deselected
				gTupGlobalVariables.bIsEndTurn = true --> Change global variable
				FupOnEndTurnClicked()			 		  --> Call developer function
				return true
			end
			
			return true;

		elseif UI.CtrlKeyDown() and UI.ShiftKeyDown() then --> Show all units destination hotkey
			if not gTupGlobalVariables.bCTRLSHIFTPressed then
				gTupGlobalVariables.bCTRLSHIFTPressed = true
				FupShowDestinationsWithETA()
				return true;
			end
		end

	elseif (uiMsg == KeyEvents.KeyUp) then
		if gTupGlobalVariables.bCTRLSHIFTPressed and (wParam == Keys.VK_CONTROL or wParam == Keys.VK_SHIFT) then
			gTupGlobalVariables.bCTRLSHIFTPressed = false
			gTupGlobalVariables.tForCTRLSHIFT.tPlotsToHighlight.Destinations.FuchsiaPlots = {}
			gTupGlobalVariables.tForCTRLSHIFT.tPlotsToHighlight.Destinations.RedPlots = {}
			gTupGlobalVariables.tForCTRLSHIFT.tPlotsToHighlight.Units = {}
			gTupGlobalVariables.tForCTRLSHIFT.tXY = {}
			FupRemovePathGraphics()

			if (UI.GetSelectedUnitID() ~= nil) then --> If one unit have a stored table and is selected while CTRL or SHIFT is
				FupUnitPathViewer(1, 1, 1)				 --  released its path will be shown
			end

			return true;
		end
	end
end
ContextPtr:SetInputHandler(UnitPathInptHdlr)

-- Modified by Logharn to keep the standard behaviour for Save Games
function PazyrykOnSaveClicked()
	print("SaveGame clicked")
	TableSave(gTupMainPathStore, "upMainPathStore")
	UIManager:QueuePopup(ContextPtr:LookUpControl("/InGame/GameMenu/SaveMenu"), PopupPriority.SaveMenu)
end

function PazyrykOnQuickSaveClicked()
	print("QuickSaveGame clicked")
	TableSave(gTupMainPathStore, "upMainPathStore")
	UI.QuickSave()
end

function RegisterOnSaveCallback()
	local QuickSaveButton = ContextPtr:LookUpControl("/InGame/GameMenu/QuickSaveButton")
	local SaveCtrlButton = ContextPtr:LookUpControl("/InGame/GameMenu/SaveGameButton")
	local VupEndTurnButtonControl = ContextPtr:LookUpControl("/InGame/WorldView/ActionInfoPanel/EndTurnButton") --> Lookup the "End Turn Button"
	QuickSaveButton:RegisterCallback( Mouse.eLClick, PazyrykOnQuickSaveClicked )
	SaveCtrlButton:RegisterCallback( Mouse.eLClick, PazyrykOnSaveClicked )
	VupEndTurnButtonControl:RegisterCallback(Mouse.eLClick, FupEndTurnCheck) --> Get any left click on the "End Turn Button"
	print ("SaveGame Buttons callbacks registered...")
end

-- <-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><->
-- |                   MODIFIED DEVELOPER FUNCTIONS                    |
-- <-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><->
-- Jaii der Herr changed how End Turn blocking types are handled
function FupOnEndTurnClicked()
	
	local player = Players[Game.GetActivePlayer()];
	if not player:IsTurnActive() then
		print("Player's turn not active");
		return;
	end
	if Game.IsProcessingMessages() then
		print("The game is busy processing messages");
		return;
	end
	-- Have we already signaled that we are done?
	if Network.HasSentNetTurnComplete() and PreGame.IsMultiplayerGame() then
		if Network.SendTurnUnready() then
			-- Success
			OnEndTurnDirty();
		end
		return;
	end
	
	local blockingType = player:GetEndTurnBlockingType();
	local blockingNotificationIndex = player:GetEndTurnBlockingNotificationIndex();
	
	if (blockingType < 0 or blockingType >= EndTurnBlockingTypes.NUM_ENDTURN_BLOCKING_TYPES) then
		if (not UI.CanEndTurn()) then
			print("UI thinks that we can't end turn, but the notification system disagrees");
		end
		
		local iEndTurnControl = GameInfoTypes.CONTROL_ENDTURN;
		Game.DoControl(iEndTurnControl)
	elseif (blockingType == EndTurnBlockingTypes.ENDTURN_BLOCKING_UNIT_PROMOTION) then
		for v in player:Units() do
			if (v:IsPromotionReady()) then
				local pPlot = v:GetPlot();
				UI.LookAt(pPlot, 0);
				UI.SelectUnit(v);
				local hex = ToHexFromGrid( Vector2(pPlot:GetX(), pPlot:GetY() ) );
				Events.GameplayFX(hex.x, hex.y, -1);
				break;
			end
		end
	elseif (blockingType == EndTurnBlockingTypes.ENDTURN_BLOCKING_STACKED_UNITS
		or blockingType == EndTurnBlockingTypes.ENDTURN_BLOCKING_UNIT_NEEDS_ORDERS
		or blockingType == EndTurnBlockingTypes.ENDTURN_BLOCKING_UNITS) then
		local pUnit = player:GetFirstReadyUnit();
		if (pUnit) then
			local pPlot = pUnit:GetPlot();
			UI.LookAt(pPlot, 0);
			UI.SelectUnit(pUnit);
			local hex = ToHexFromGrid( Vector2(pPlot:GetX(), pPlot:GetY() ) );
			Events.GameplayFX(hex.x, hex.y, -1);
--			Events.UnitSelectionChanged(Game.GetActivePlayer(), UI.GetSelectedUnitID(), 0, 0, 0, true, true);
		end
		
	elseif (blockingType == EndTurnBlockingTypes.ENDTURN_BLOCKING_CITY_RANGE_ATTACK) then
		local pCity = UI.GetHeadSelectedCity();
		if (pCity) then
			UI.LookAt(pCity:Plot(), 0);
		end
	--elseif (blockingType == EndTurnBlockingTypes.ENDTURN_BLOCKING_UNITS) then
	--	-- Skip active Unit's turn
	--	local pUnit = UI.GetHeadSelectedUnit();
	--	if (pUnit ~= nil) then
	--		local iSkipUnitMission = GameInfoTypes.MISSION_SKIP;
	--		Game.SelectionListGameNetMessage(GameMessageTypes.GAMEMESSAGE_PUSH_MISSION, GameInfoTypes.MISSION_SKIP, pUnit:GetID(), 0, 0, false);
	--	end
	else
		UI.ActivateNotification(blockingNotificationIndex);
	end
end