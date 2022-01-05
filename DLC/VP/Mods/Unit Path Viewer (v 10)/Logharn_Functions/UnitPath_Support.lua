-- <-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><->
-- |                         SUPPORT FUNCTIONS                         |
-- <-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><-><->
function FupCommonUnitValues(TupUnitHead) --> Called inside some functions to populate most unit used variables
	TupCommonUnitValues = {tCurrentPlot = TupUnitHead:GetPlot(),
								  tMissionLastPlot = TupUnitHead:LastMissionPlot(),
								  tUnitHead = TupUnitHead,
								  bIsAutomated = TupUnitHead:IsAutomated(),
								  bIsGreatPerson = TupUnitHead:IsGreatPerson(),
								  bIsMilitary = TupUnitHead:IsCombatUnit(),
								  bIsReadyToMove = TupUnitHead:IsReadyToMove(),
								  vID = TupUnitHead:GetID(),
								  vTeam = TupUnitHead:GetTeam(),
								  vViewRange = (TupUnitHead:VisibilityRange() - 1),
								  sName = TupUnitHead:GetName(),
								  sType = GameInfo.Units[TupUnitHead:GetUnitType()].Type,};

	return TupCommonUnitValues;
end --> FupCommonUnitValues

function FupColorConverter(VupRed, VupGreen, VupBlue, VupAlpha) --> Values between 255 and 0
	return Color((256 - VupRed), (256 - VupGreen), (256 - VupBlue), (256 - VupAlpha));
end --> FupColorConverter

function FupHexHighlighter(VupHexToHighlightX, VupHexToHighlightY, VupHighlightColour, SupHexHighlightingStyle) --> Called inside functions to
	local VupHexToBeHighlighted = ToHexFromGrid(Vector2(VupHexToHighlightX, VupHexToHighlightY))						 --  highlight plots

	Events.SerialEventHexHighlight(VupHexToBeHighlighted, true, VupHighlightColour, SupHexHighlightingStyle);
end --> FupHexHighlighter

function FupEndTurnCheck() --> Called whenever "Enter" is pressed or the "End Turn Button" is clicked
	local VupEndTurnButtonText = ContextPtr:LookUpControl("/InGame/WorldView/ActionInfoPanel/EndTurnText"):GetText()
	local VupNextTurnText = Locale.ConvertTextKey("TXT_KEY_NEXT_TURN");

	if (VupEndTurnButtonText == VupNextTurnText) then	--> If text on the "End Turn Button" is "Next Turn"
		Game.CycleUnits(true)									--> Deselect unit if one selected
		gTupGlobalVariables.bIsEndTurn = true;				--> Assign to global variable the "TRUE" value
	end

	FupOnEndTurnClicked(); --> Calling developer function to process end turn
	
end --> FupEndTurnCheck

function FupPathChangerNotifications(TupMainUnitPath, TupCommonUnitValues, BupUnitAlreadyInLastPlot) --> Called inside "FupPathChanger" to show
	local VupUnitPlotX = TupCommonUnitValues.tCurrentPlot:GetX()												  --  in-game notifications
	local VupUnitPlotY = TupCommonUnitValues.tCurrentPlot:GetY()
	local VupNotificationType, SupNotificationText, SupNotificationTitle;

	if TupMainUnitPath.bCanSeeNewPlot and not BupUnitAlreadyInLastPlot then --> If our unit is near its new destination
		VupNotificationType = NotificationTypes.NOTIFICATION_TRADE_ROUTE_BROKEN
		SupNotificationText = "[COLOR_UNIT_TEXT]"..(TupCommonUnitValues.sName).."'s[ENDCOLOR] path blocked![NEWLINE]"..
									 "[COLOR_RED]Unit is near its destination, no action taken.[ENDCOLOR]"
		SupNotificationTitle = "Unit's destination blocked![NEWLINE]"..
									  "[COLOR_RED]Must be moved manually...[ENDCOLOR]";
	elseif BupUnitAlreadyInLastPlot then --> If our unit is already on the first good tile
		VupNotificationType = NotificationTypes.NOTIFICATION_TRADE_ROUTE_BROKEN
		SupNotificationText = "[COLOR_UNIT_TEXT]"..(TupCommonUnitValues.sName).."'s[ENDCOLOR] path blocked![NEWLINE]"..
									 "[COLOR_RED]Unit already occupy the first good plot.[ENDCOLOR]"
		SupNotificationTitle = "Unit's destination blocked![NEWLINE]"..
									  "[COLOR_RED]Must be moved manually...[ENDCOLOR]";
	elseif not TupMainUnitPath.bCanSeeNewPlot then --> If our unit has been redirected to a new destination
		VupUnitPlotX = -1
		VupUnitPlotY = -1
		VupNotificationType = NotificationTypes.NOTIFICATION_TRADE_ROUTE
		SupNotificationText = "[COLOR_UNIT_TEXT]"..(TupCommonUnitValues.sName).."'s[ENDCOLOR] path blocked![NEWLINE]"..
									 "[COLOR_FONT_GREEN]It has been redirected to a new good plot![ENDCOLOR]"
		SupNotificationTitle = "Unit's destination blocked![NEWLINE]"..
									  "[COLOR_FONT_GREEN]Rerouted automatically.[ENDCOLOR]";
	end

	Players[Game.GetActivePlayer()]:AddNotification(VupNotificationType,
																	SupNotificationText,
																	SupNotificationTitle,
																	VupUnitPlotX,
																	VupUnitPlotY);
end --> FupPathChangerNotifications

function FupPathChanger(TupMainUnitPath, TupCommonUnitValues) --> Called inside "FupUnitPathViewer" to redirect blocked units
	local VupUnitPlotType = TupCommonUnitValues.tCurrentPlot:GetPlotType();

	if (VupUnitPlotType < 3) then	--> Assign a fixed value to the current unit plot type
		VupUnitPlotType = 1;			--  to separate land from water (3 = water)
	else
		VupUnitPlotType = 2;
	end

	for c = TupMainUnitPath.vIndexes, 1, -1 do --> Do a backwards loop to find first good plot!
		local TupNewLastPlot = Map.GetPlot(TupMainUnitPath.tPath[c].x, TupMainUnitPath.tPath[c].y)
		local VupNewLastPlotOccupied = TupNewLastPlot:GetNumUnits()
		local VupNewLastPlotType = TupNewLastPlot:GetPlotType()
		local BupNewLastPlotCanBeSeen = TupCommonUnitValues.tCurrentPlot:CanSeePlot(TupNewLastPlot,
																											 TupCommonUnitValues.vTeam,
																											 TupCommonUnitValues.vViewRange, -1)
		local BupNewLastPlotCanBeWalked = TupCommonUnitValues.tUnitHead:CanMoveThrough(TupNewLastPlot);

		if (VupNewLastPlotOccupied == 0) then --> New last plot must not be occupied
			if (VupNewLastPlotType < 3) then --> Same as above but having the new last plot as reference
				VupNewLastPlotType = 1;
			else
				VupNewLastPlotType = 2;
			end

			if (VupUnitPlotType == VupNewLastPlotType) then --> New last plot is of same type as our unit's plot
				if BupNewLastPlotCanBeWalked then --> Unit can move to new last plot
					if BupNewLastPlotCanBeSeen then --> Unit can see new last plot
						TupMainUnitPath.bCanSeeNewPlot = true
						TupMainUnitPath.vIndexes = c
						FupUnitPathViewer()
						FupPathChangerNotifications(TupMainUnitPath, TupCommonUnitValues, false)
						return; --> No action taken, exit loop and function
					else --> Unit cannot see new last plot
						TupMainUnitPath.vRedirectedInTurn = Game.GetGameTurn()
						TupMainUnitPath.vIndexes = c
						TupMainUnitPath.vETA = (TupMainUnitPath.vMovedInTurn) + (TupMainUnitPath.tPath[c].turn)
						Game.SelectionListMove(TupNewLastPlot) --> Redirect selected unit
						FupPathChangerNotifications(TupMainUnitPath, TupCommonUnitValues, false)
						return; --> Unit redirected then exit loop and function
					end
				end
			else --> New last plot is of different type than our unit's plot
				if BupNewLastPlotCanBeSeen then --> Unit can see new last plot
					TupMainUnitPath.bCanSeeNewPlot = true
					TupMainUnitPath.vIndexes = c
					FupUnitPathViewer()
					FupPathChangerNotifications(TupMainUnitPath, TupCommonUnitValues, false)
					return; --> No action taken, exit loop and function
				else --> Unit cannot see new last plot
					TupMainUnitPath.vRedirectedInTurn = Game.GetGameTurn()
					TupMainUnitPath.vIndexes = c
					TupMainUnitPath.vETA = (TupMainUnitPath.vMovedInTurn) + (TupMainUnitPath.tPath[c].turn)
					Game.SelectionListMove(TupNewLastPlot) --> Redirect selected unit
					FupPathChangerNotifications(TupMainUnitPath, TupCommonUnitValues, false)
					return; --> Unit redirected then exit loop and function
				end
			end
		else --> New last plot is occupied
			if (TupCommonUnitValues.tUnitHead == TupNewLastPlot:GetUnit()) then -- New last plot is occupied by our unit
				TupMainUnitPath.bCanSeeNewPlot = true
				TupMainUnitPath.vIndexes = c
				FupUnitPathViewer()
				FupPathChangerNotifications(TupMainUnitPath, TupCommonUnitValues, true)
				return; --> New destination is where the unit stands, no action taken, exit loop and function
			end
		end
	end
end --> FupPathChanger

function FupShowDestinationsWithETA(TupMainUnitPath, TupCommonUnitValues) --> Called pressing CTRL+SHIFT or clicking on unit flag
	local VupCurrentTurn = Game.GetGameTurn();

	if ((TupMainUnitPath == nil) and (TupCommonUnitValues == nil)) then --> If function is called without parameters means that CTRL + SHIFT is pressed
		local TupMainPathStore = gTupMainPathStore							  --  so pass through some checks and iterate the main path table to highlight unit last mission plots
		local TupColourForStandardPath = gTupGlobalVariables.tColourForStandardPath
		local TupHighlightsStyles = gTupGlobalVariables.tHighlightsStyles
		local VupActivePlayer = Players[Game.GetActivePlayer()]
		
		FupRemovePathGraphics();											

		for k, _ in pairs(TupMainPathStore) do --> Iterate through the "Main Path Store" table and get all UnitIDs 
			if type(k) == "number" then
				local TupMainUnitPath = TupMainPathStore[k]

				if not TupMainUnitPath.bIsBuildingRoute and TupMainUnitPath.bIsMilitary then --> The unit must not be building a route then fill variables
					local TupCommonUnitValues = FupCommonUnitValues(VupActivePlayer:GetUnitByID(k))
					local TupLastPlotHighlightColour = TupColourForStandardPath.tRed
					local TupXY = gTupGlobalVariables.tForCTRLSHIFT.tXY
					local VupUnitMoveTurnsLeft = (TupMainUnitPath.vETA - VupCurrentTurn)
					local VupEnumXY = table.maxn(TupXY)
					local VupPopupDelay01 = 0.00
					local VupPopupDelay02 = 0.42
					local SupPopupText01 = "[COLOR_UNIT_TEXT]"..(TupCommonUnitValues.sName).."[ENDCOLOR]"
					local SupPopupText02;

					if (TupCommonUnitValues.tCurrentPlot == TupCommonUnitValues.tMissionLastPlot) then
						SupPopupText02 = "IN POSITION";
					else
						if (VupUnitMoveTurnsLeft > 2) then
							SupPopupText02 = "[COLOR_RED]ETA: "..VupUnitMoveTurnsLeft.." turns[ENDCOLOR]";
						elseif (VupUnitMoveTurnsLeft == 2) then
							SupPopupText02 = "[COLOR_GREEN]ETA: "..VupUnitMoveTurnsLeft.." turns[ENDCOLOR]";
						elseif (VupUnitMoveTurnsLeft == 1) then
							SupPopupText02 = "[COLOR_GREEN]ETA: "..VupUnitMoveTurnsLeft.." turn[ENDCOLOR]";
						elseif (VupUnitMoveTurnsLeft == 0) then
							SupPopupText02 = "Isn't it here?";
						elseif (VupUnitMoveTurnsLeft == -1) then
							SupPopupText02 = "Is in late...";
						elseif (VupUnitMoveTurnsLeft < -1) then
							SupPopupText01 = "[COLOR_UNIT_TEXT]SCOOBY-DOO[ENDCOLOR]"
							SupPopupText02 = "[COLOR_PLAYER_DARK_BLUE]Where are you?![ENDCOLOR]";
						end
					end

					if (VupEnumXY == 0) then --> First unit isn't compared against XY Table, instead it creates some values
						gTupGlobalVariables.tForCTRLSHIFT.tXY[1] = {tMissionLastPlot = TupCommonUnitValues.tMissionLastPlot,
																				  vMultiplier = 1}
						gTupGlobalVariables.tForCTRLSHIFT.tXY[1][TupCommonUnitValues.vID] = {vPopupDelay01 = VupPopupDelay01,
																													vPopupDelay02 = VupPopupDelay02,
																													sPopupText01 = SupPopupText01,
																													sPopupText02 = SupPopupText02};
					else --> All other units are compared against the above table
						for c = 1, VupEnumXY do
							if ((TupXY[c].tMissionLastPlot == TupCommonUnitValues.tMissionLastPlot)) then --> If "X" and "Y" coord. are the same then highlight
								TupLastPlotHighlightColour = TupColourForStandardPath.tFuchsia					--  colour will be fuchsia and some delay is added
								VupPopupDelay01 = ((0.93 * TupXY[c].vMultiplier) + VupPopupDelay01)
								VupPopupDelay02 = ((0.93 * TupXY[c].vMultiplier) + VupPopupDelay02)
								gTupGlobalVariables.tForCTRLSHIFT.tXY[c].vMultiplier = (TupXY[c].vMultiplier + 1)
								gTupGlobalVariables.tForCTRLSHIFT.tXY[c][TupCommonUnitValues.vID] = {vPopupDelay01 = VupPopupDelay01,
																															vPopupDelay02 = VupPopupDelay02,
																															sPopupText01 = SupPopupText01,
																															sPopupText02 = SupPopupText02};

								if (TupXY[c].vMultiplier < 3) then --> Since Multiplier is 1 by default when it's 2 then do a plot graphical effect
									local TupHexToMakeGamePlayFX = ToHexFromGrid(Vector2(TupXY[c].tMissionLastPlot:GetX(), TupXY[c].tMissionLastPlot:GetY()));

									Events.GameplayFX(TupHexToMakeGamePlayFX.x, TupHexToMakeGamePlayFX.y, -1); --> Do some fireworks!
								end
								
							elseif (c == VupEnumXY) and (TupLastPlotHighlightColour == TupColourForStandardPath.tRed) then	--> Unit have no coordinates in
																																							--  common with others fill table
								gTupGlobalVariables.tForCTRLSHIFT.tXY[(c + 1)] = {tMissionLastPlot = TupCommonUnitValues.tMissionLastPlot,
																								  vMultiplier = 1}											
								gTupGlobalVariables.tForCTRLSHIFT.tXY[(c + 1)][TupCommonUnitValues.vID] = {vPopupDelay01 = VupPopupDelay01,
																																	vPopupDelay02 = VupPopupDelay02,
																																	sPopupText01 = SupPopupText01,
																																	sPopupText02 = SupPopupText02};														  
							end
						end --> FOR
					end

					if not FupCompareValueAgainstTable(TupCommonUnitValues.tCurrentPlot, TupXY) then --> If the plot where unit stands isn't inside the XY 
						FupHexHighlighter(TupCommonUnitValues.tCurrentPlot:GetX(),							--  table its plot is highlighted in Orange
												TupCommonUnitValues.tCurrentPlot:GetY(),
												TupColourForStandardPath.tOrange,
												TupHighlightsStyles.sOuterHexHighlight)
						table.insert(gTupGlobalVariables.tForCTRLSHIFT.tPlotsToHighlight.Units, TupCommonUnitValues.tCurrentPlot) --> Insert plot values in
					end																																			 --  another table that is
																																									 --  used when hovering with 
					local TupDestinations = gTupGlobalVariables.tForCTRLSHIFT.tPlotsToHighlight.Destinations							 --  mouse cursor

					if (TupLastPlotHighlightColour == TupColourForStandardPath.tRed) then --> If plot colore is red means that destination is only for one unit
						table.insert(gTupGlobalVariables.tForCTRLSHIFT.tPlotsToHighlight.Destinations.RedPlots, TupCommonUnitValues.tMissionLastPlot)
					elseif (TupLastPlotHighlightColour == TupColourForStandardPath.tFuchsia) then --> If plot color is fuchsia more units share that plot
						for c = 1, table.maxn(TupDestinations.RedPlots) do --> Iterate through red plots table
							if (TupCommonUnitValues.tMissionLastPlot == TupDestinations.RedPlots[c]) then --> If the same plot is found is removed
								table.remove(gTupGlobalVariables.tForCTRLSHIFT.tPlotsToHighlight.Destinations.RedPlots, c)
							end
						end
						
						for c = 1, table.maxn(TupDestinations.FuchsiaPlots) do --> Iterate also through fuchsia table, we want only one plot to be stored
							if (TupCommonUnitValues.tMissionLastPlot == TupDestinations.FuchsiaPlots[c]) then --> Same as above
								table.remove(gTupGlobalVariables.tForCTRLSHIFT.tPlotsToHighlight.Destinations.FuchsiaPlots, c)
							end
						end
						
						table.insert(gTupGlobalVariables.tForCTRLSHIFT.tPlotsToHighlight.Destinations.FuchsiaPlots, TupCommonUnitValues.tMissionLastPlot)
					end
					
					FupHexHighlighter(TupCommonUnitValues.tMissionLastPlot:GetX(), --> Highlight Unit Last plot with the colour got from the checks
											TupCommonUnitValues.tMissionLastPlot:GetY(),
											TupLastPlotHighlightColour,
											TupHighlightsStyles.sBigHexHighlight)
					UI.AddPopupText(TupCommonUnitValues.tMissionLastPlot:GetX(), --> Add a first popup with the delay got through the checks
										 TupCommonUnitValues.tMissionLastPlot:GetY(), --  this PopUp contains the name of the unit
										 SupPopupText01,
										 VupPopupDelay01)
					UI.AddPopupText(TupCommonUnitValues.tMissionLastPlot:GetX(), --> Add a second popup with the delay got through the checks
										 TupCommonUnitValues.tMissionLastPlot:GetY(), --  this PopUp contains the ETA of the unit
										 SupPopupText02,
										 VupPopupDelay02);
				end --> if not TupMainUnitPath.bIsBuildingRoute
			end --> if type(k) == "number"
		end --> for k, _ in pairs(TupMainPathStore)
	else --> If function is called with parameters means that we clicked upon the Unit's Flag
		if not TupMainUnitPath.bIsBuildingRoute then --> The unit must not be building a route then fill some variables
			local VupUnitMoveTurnsLeft = (TupMainUnitPath.vETA - VupCurrentTurn);

			if (TupCommonUnitValues.tCurrentPlot == TupCommonUnitValues.tMissionLastPlot) then
				SupPopupText01 = "IN POSITION";
			else
				if (VupUnitMoveTurnsLeft > 2) then
					SupPopupText01 = "[COLOR_RED]ETA: "..VupUnitMoveTurnsLeft.." turns[ENDCOLOR]";
				elseif (VupUnitMoveTurnsLeft == 2) then
					SupPopupText01 = "[COLOR_GREEN]ETA: "..VupUnitMoveTurnsLeft.." turns[ENDCOLOR]";
				elseif (VupUnitMoveTurnsLeft == 1) then
					SupPopupText01 = "[COLOR_GREEN]ETA: "..VupUnitMoveTurnsLeft.." turn[ENDCOLOR]";
				elseif (VupUnitMoveTurnsLeft == 0) then
					SupPopupText01 = "I'm a bit late...";
				elseif (VupUnitMoveTurnsLeft == -1) then
					SupPopupText01 = "I must be near...";
				elseif (VupUnitMoveTurnsLeft < -1) then
					SupPopupText01 = "[COLOR_PLAYER_DARK_BLUE]I'M LOST!![ENDCOLOR]";
				end
			end
		end --> if not TupMainUnitPath.bIsBuildingRoute

		UI.AddPopupText(TupCommonUnitValues.tCurrentPlot:GetX(), TupCommonUnitValues.tCurrentPlot:GetY(), SupPopupText01, 0.00);
	end
end --> FupShowDestinationsWithETA

function FupTableIterator(tree) --> Found at "http://forum.luahub.com/index.php?topic=1956.0" made by Youka
	if type(tree) ~= "table" then
		error("table expected", 2)
	end

	local node_collection = {}
	local function node_collector(node, parent_node)
		for key, value in pairs(node) do
			table.insert(node_collection, {key = key, value = value, node = node, parent = parent_node})
			if type(value) == "table" then
				node_collector(value, node)
			end
		end
	end
	node_collector(tree, nil)

	local iterator_index = 1
	local function iterator()
		if iterator_index > #node_collection then
			return nil
		else
			local node = node_collection[iterator_index]
			iterator_index = iterator_index + 1
			return node
		end
	end

	return iterator
end --> FupTableIterator

function FupCompareValueAgainstTable(VupValueToCheck, TupComparisonTable) --> Called inside some functions to retrieve if a value is contained in the reference table
	for VupTableValues in FupTableIterator(TupComparisonTable) do
		if (VupTableValues.value == VupValueToCheck) or (VupTableValues.node == VupValueToCheck) then
			return true;
		end
		--print(
			--"Key: " .. tostring(VupTableValues.key),
			--"Value: " .. tostring(VupTableValues.value)--,
			--"Node: " .. tostring(VupTableValues.node),
			--"Parent:" .. tostring(VupTableValues.parent)
		--)
	end

	return false;
end --> FupCompareValueAgainstTable