------------------------------------------------------------------------------
--	FILE:	 Lekmapv2.2.lua (Modified Pangaea_Plus.lua)
--	AUTHOR:  Original Bob Thomas, Changes HellBlazer, lek10, EnormousApplePie, Cirra, Meota
--	PURPOSE: Global map script - Simulates a Pan-Earth Supercontinent, with
--           numerous tectonic island chains.
------------------------------------------------------------------------------
--	Copyright (c) 2011 Firaxis Games, Inc. All rights reserved.
------------------------------------------------------------------------------

include("MapGenerator");
include("FractalWorld");
include("FeatureGenerator");
include("TerrainGenerator");



------------------------------------------------------------------------------
------------------------------------------------------------------------------
ContinentsFractalWorld = {};
------------------------------------------------------------------------------
function ContinentsFractalWorld.Create(fracXExp, fracYExp)
	local gridWidth, gridHeight = Map.GetGridSize();
	
	local data = {
		InitFractal = FractalWorld.InitFractal,
		ShiftPlotTypes = FractalWorld.ShiftPlotTypes,
		ShiftPlotTypesBy = FractalWorld.ShiftPlotTypesBy,
		DetermineXShift = FractalWorld.DetermineXShift,
		DetermineYShift = FractalWorld.DetermineYShift,
		GenerateCenterRift = FractalWorld.GenerateCenterRift,
		GeneratePlotTypes = ContinentsFractalWorld.GeneratePlotTypes,	-- Custom method
		
		iFlags = Map.GetFractalFlags(),
		
		fracXExp = fracXExp,
		fracYExp = fracYExp,
		
		iNumPlotsX = gridWidth,
		iNumPlotsY = gridHeight,
		plotTypes = table.fill(PlotTypes.PLOT_OCEAN, gridWidth * gridHeight)
	};
		
	return data;
end	
------------------------------------------------------------------------------
function ContinentsFractalWorld:GeneratePlotTypes(args)
	if(args == nil) then args = {}; end
	
	--
	local extra_mountains = args.extra_mountains;
	local grain_amount = args.continent_grain;
	local adjust_plates = args.adjust_plates;
	local shift_plot_types = true;
	local tectonic_islands = args.tectonic_islands;
	local hills_ridge_flags = self.iFlags;
	local peaks_ridge_flags = self.iFlags;
	local has_center_rift = args.has_center_rift;
	

	-- Set Sea Level according to user selection.
	local water_percent = args.sea_level;

	-- Set values for hills and mountains according to World Age chosen by user.
	local adjustment = 3;
	local world_age = args.world_age;
	if world_age == 3 then -- 5 Billion Years
		adjustment = 2;
		adjust_plates = adjust_plates * 0.75;
	elseif world_age == 1 then -- 3 Billion Years
		adjustment = 5;
		adjust_plates = adjust_plates * 1.5;
	else -- 4 Billion Years
	end
	-- Apply adjustment to hills and peaks settings.
	local hillsBottom1 = 28 - adjustment;
	local hillsTop1 = 28 + adjustment;
	local hillsBottom2 = 72 - adjustment;
	local hillsTop2 = 72 + adjustment;
	local hillsClumps = 1 + adjustment;
	local hillsNearMountains = 91 - (adjustment * 2) - extra_mountains;
	local mountains = 97 - adjustment - extra_mountains;

	-- Hills and Mountains handled differently according to map size
	local WorldSizeTypes = {};
	for row in GameInfo.Worlds() do
		WorldSizeTypes[row.Type] = row.ID;
	end
	local sizekey = Map.GetWorldSize();
	-- Fractal Grains
	local sizevalues = {
		[WorldSizeTypes.WORLDSIZE_DUEL]     = 3,
		[WorldSizeTypes.WORLDSIZE_TINY]     = 3,
		[WorldSizeTypes.WORLDSIZE_SMALL]    = 4,
		[WorldSizeTypes.WORLDSIZE_STANDARD] = 4,
		[WorldSizeTypes.WORLDSIZE_LARGE]    = 5,
		[WorldSizeTypes.WORLDSIZE_HUGE]		= 5
	};
	local grain = sizevalues[sizekey] or 3;
	-- Tectonics Plate Counts
	local platevalues = {
		[WorldSizeTypes.WORLDSIZE_DUEL]		= 6,
		[WorldSizeTypes.WORLDSIZE_TINY]     = 9,
		[WorldSizeTypes.WORLDSIZE_SMALL]    = 12,
		[WorldSizeTypes.WORLDSIZE_STANDARD] = 18,
		[WorldSizeTypes.WORLDSIZE_LARGE]    = 24,
		[WorldSizeTypes.WORLDSIZE_HUGE]     = 30
	};
	local numPlates = platevalues[sizekey] or 5;
	-- Add in any plate count modifications passed in from the map script.
	numPlates = numPlates * adjust_plates;

	-- Generate continental fractal layer and examine the largest landmass. Reject
	-- the result until the largest landmass occupies 58% or less of the total land.
	local done = false;
	local iAttempts = 0;
	local iWaterThreshold, biggest_area, iNumTotalLandTiles, iNumBiggestAreaTiles, iBiggestID;
	while done == false do
		local grain_dice = Map.Rand(7, "Continental Grain roll - LUA Continents");
		if grain_dice < 4 then
			grain_dice = 2;
		else
			grain_dice = 1;
		end
		local rift_dice = Map.Rand(3, "Rift Grain roll - LUA Continents");
		if rift_dice < 1 then
			rift_dice = -1;
		end
		
		self.continentsFrac = nil;
		self:InitFractal{continent_grain = grain_dice, rift_grain = rift_dice};
		iWaterThreshold = self.continentsFrac:GetHeight(water_percent);
		
		iNumTotalLandTiles = 0;
		for x = 0, self.iNumPlotsX - 1 do
			for y = 0, self.iNumPlotsY - 1 do
				local i = y * self.iNumPlotsX + x;
				local val = self.continentsFrac:GetHeight(x, y);
				if(val <= iWaterThreshold) then
					self.plotTypes[i] = PlotTypes.PLOT_OCEAN;
				else
					self.plotTypes[i] = PlotTypes.PLOT_LAND;
					iNumTotalLandTiles = iNumTotalLandTiles + 1;
				end
			end
		end

		self:ShiftPlotTypes();
		self:GenerateCenterRift()

		SetPlotTypes(self.plotTypes);
		Map.RecalculateAreas();
		
		biggest_area = Map.FindBiggestArea(false);
		iNumBiggestAreaTiles = biggest_area:GetNumTiles();
		-- Now test the biggest landmass to see if it is large enough.
		if iNumBiggestAreaTiles <= iNumTotalLandTiles * 0.58 then
			done = true;
			iBiggestID = biggest_area:GetID();
		end
		iAttempts = iAttempts + 1;
		
		--[[ Printout for debug use only
		print("-"); print("--- Continents landmass generation, Attempt#", iAttempts, "---");
		print("- This attempt successful: ", done);
		print("- Total Land Plots in world:", iNumTotalLandTiles);
		print("- Land Plots belonging to biggest landmass:", iNumBiggestAreaTiles);
		print("- Percentage of land belonging to biggest: ", 100 * iNumBiggestAreaTiles / iNumTotalLandTiles);
		print("- Continent Grain for this attempt: ", grain_dice);
		print("- Rift Grain for this attempt: ", rift_dice);
		print("- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -");
		print(".");
		]]--
	end
	
	-- Generate fractals to govern hills and mountains
	self.hillsFrac = Fractal.Create(self.iNumPlotsX, self.iNumPlotsY, grain, self.iFlags, self.fracXExp, self.fracYExp);
	self.mountainsFrac = Fractal.Create(self.iNumPlotsX, self.iNumPlotsY, grain, self.iFlags, self.fracXExp, self.fracYExp);
	self.hillsFrac:BuildRidges(numPlates, hills_ridge_flags, 1, 2);
	self.mountainsFrac:BuildRidges((numPlates * 2) / 3, peaks_ridge_flags, 6, 1);
	-- Get height values
	local iHillsBottom1 = self.hillsFrac:GetHeight(hillsBottom1);
	local iHillsTop1 = self.hillsFrac:GetHeight(hillsTop1);
	local iHillsBottom2 = self.hillsFrac:GetHeight(hillsBottom2);
	local iHillsTop2 = self.hillsFrac:GetHeight(hillsTop2);
	local iHillsClumps = self.mountainsFrac:GetHeight(hillsClumps);
	local iHillsNearMountains = self.mountainsFrac:GetHeight(hillsNearMountains);
	local iMountainThreshold = self.mountainsFrac:GetHeight(mountains);
	local iPassThreshold = self.hillsFrac:GetHeight(hillsNearMountains);
	
	-- Set Hills and Mountains
	for x = 0, self.iNumPlotsX - 1 do
		for y = 0, self.iNumPlotsY - 1 do
			local plot = Map.GetPlot(x, y);
			local mountainVal = self.mountainsFrac:GetHeight(x, y);
			local hillVal = self.hillsFrac:GetHeight(x, y);
	
			if plot:GetPlotType() ~= PlotTypes.PLOT_OCEAN then
				if (mountainVal >= iMountainThreshold) then
					if (hillVal >= iPassThreshold) then -- Mountain Pass though the ridgeline
						plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
					else -- Mountain
						plot:SetPlotType(PlotTypes.PLOT_MOUNTAIN, false, false);
					end
				elseif (mountainVal >= iHillsNearMountains) then
					plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
				elseif ((hillVal >= iHillsBottom1 and hillVal <= iHillsTop1) or (hillVal >= iHillsBottom2 and hillVal <= iHillsTop2)) then
					plot:SetPlotType(PlotTypes.PLOT_HILLS, false, false);
				end
			end
		end
	end
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------

------------------------------------------------------------------------------
function GetMapScriptInfo()
	local world_age, temperature, rainfall, sea_level, resources = GetCoreMapOptions()
	return {
		Name = "Custom",
		Description = "Very customizeable map script.",
		IsAdvancedMap = false,
		IconIndex = 1,
		SortIndex = 2,
		SupportsMultiplayer = true,
	CustomOptions = {
			{
				Name = "TXT_KEY_MAP_OPTION_WORLD_AGE", -- 1
				Values = {
					"TXT_KEY_MAP_OPTION_THREE_BILLION_YEARS",
					"TXT_KEY_MAP_OPTION_FOUR_BILLION_YEARS",
					"TXT_KEY_MAP_OPTION_FIVE_BILLION_YEARS",
					"No Mountains",
					"TXT_KEY_MAP_OPTION_RANDOM",
				},
				DefaultValue = 2,
				SortPriority = -200,
			},

			{
				Name = "TXT_KEY_MAP_OPTION_TEMPERATURE",	-- 2 add temperature defaults to random
				Values = {
					"TXT_KEY_MAP_OPTION_COOL",
					"TXT_KEY_MAP_OPTION_TEMPERATE",
					"TXT_KEY_MAP_OPTION_HOT",
					"TXT_KEY_MAP_OPTION_RANDOM",
				},
				DefaultValue = 2,
				SortPriority = -180,
			},

			{
				Name = "TXT_KEY_MAP_OPTION_RAINFALL",	-- 3 add rainfall defaults to random
				Values = {
					"TXT_KEY_MAP_OPTION_ARID",
					"TXT_KEY_MAP_OPTION_NORMAL",
					"TXT_KEY_MAP_OPTION_WET",
					"TXT_KEY_MAP_OPTION_RANDOM",
				},
				DefaultValue = 2,
				SortPriority = -170,
			},

			{
				Name = "Sea Level",--  (4)
				Values = {
					"50", -- 1
					"52",
					"54",
					"56",
					"58", --5
					"60",
					"62",
					"64",
					"66 (Low)",
					"68", --10
					"70",
					"72",
					"74",
					"76 (Medium)", --14
					"78", --15
					"80",
					"82",
					"84", --30
					"86 (High)",
					"88",
					"90",
					"92", --30
				},

				DefaultValue = 13,
				SortPriority = -160,
			},

			{
				Name = "Start Quality",	-- 5 add resources defaults to random
				Values = {
					"Legendary Start - Strat Balance",
					"Legendary - Strat Balance + Uranium",
					"TXT_KEY_MAP_OPTION_STRATEGIC_BALANCE",
					"Strategic Balance With Coal",
					"Strategic Balance With Aluminum",
					"Strategic Balance With Coal & Aluminum",
					"TXT_KEY_MAP_OPTION_RANDOM",
				},
				DefaultValue = 2,
				SortPriority = -95,
			},

			{
				Name = "Start Distance",	-- 6 add resources defaults to random
				Values = {
					"Close",
					"Normal",
					"Far - Warning: May sometimes crash during map generation",
				},
				DefaultValue = 2,
				SortPriority = -94,
			},

			{
				Name = "Natural Wonders", -- 7 number of natural wonders to spawn
				Values = {
					"0",
					"1",
					"2",
					"3",
					"4",
					"5",
					"6",
					"7",
					"8",
					"9",
					"10",
					"11",
					"12",
					"Random",
					"Default",
				},
				DefaultValue = 15,
				SortPriority = -93,
			},

			{
				Name = "Grass Moisture",	-- add setting for grassland mositure (8)
				Values = {
					"Wet",
					"Normal",
					"Dry",
				},

				DefaultValue = 2,
				SortPriority = -92,
			},

			{
				Name = "Rivers",	-- add setting for rivers (9)
				Values = {
					"Sparse",
					"Average",
					"Plentiful",
				},

				DefaultValue = 2,
				SortPriority = -91,
			},

			{
				Name = "Tundra",	-- add setting for tundra (10)
				Values = {
					"Sparse",
					"Average",
					"Plentiful",
				},

				DefaultValue = 1,
				SortPriority = -90,
			},

			{
				Name = "Land Size X",	-- add setting for land type (11) +28
				Values = {
					"30",
					"32",
					"34",
					"36",
					"38",
					"40 (Duel)",
					"42",
					"44",
					"46",
					"48", --10
					"50",
					"52",
					"54",
					"56 (Tiny)",
					"58", --15
					"60",
					"62",
					"64",
					"66 (Small)",
					"68", --20
					"70",
					"72",
					"74",
					"76",
					"78", --25
					"80 (Standard)",
					"82",
					"84",
					"86",
					"88", --30
					"90",
					"92",
					"94",
					"96",
					"98",
					"100",
					"102",
					"104 (Large)",
					"106",
					"108",
					"110",
					"112",
					"114",
					"116",
					"118",
					"120",
					"122",
					"124",
					"126",
					"128 (Huge)",
				},

				DefaultValue = 23,
				SortPriority = -89,
			},

			{
				Name = "Land Size Y",	-- add setting for land type (12) +18
				Values = {
					"20",
					"22",
					"24 (Duel)",
					"26",
					"28",
					"30",
					"32",
					"34",
					"36 (Tiny)",
					"38", --10
					"40",
					"42 (Small)",
					"44",
					"46",
					"48", --15
					"50",
					"52 (Standard)",
					"54",
					"56",
					"58", --20
					"60",
					"62",
					"64 (Large)",
					"66",
					"68",
					"70",
					"72",
					"74",
					"76", --30
					"78",
					"80 (Huge)",
				},

				DefaultValue = 20,
				SortPriority = -88,
			},

			{
				Name = "TXT_KEY_MAP_OPTION_RESOURCES",	-- add setting for resources (13)
				Values = {
					"1 -- Nearly Nothing",
					"2",
					"3",
					"4",
					"5 -- Default",
					"6",
					"7",
					"8",
					"9",
					"10 -- Almost no normal tiles left",
				},

				DefaultValue = 5,
				SortPriority = -87,
			},

			{
				Name = "Balanced Regionals",	-- add setting for removing OP luxes from regional pool (14)
				Values = {
					"Yes",
					"No",
				},

				DefaultValue = 1,
				SortPriority = -85,
			},

			{
				Name = "Continent Type",	-- add setting for removing OP luxes from regional pool (15)
				Values = {
					"Pangea",
					"Continents",
					"Small Continents",
					"Fractal",
					"Fractal Super",
				},

				DefaultValue = 2,
				SortPriority = -75,
			},

			{
				Name = "Less Polar Land",	-- add setting for removing OP luxes from regional pool (16)
				Values = {
					"Yes",
					"No",
				},

				DefaultValue = 1,
				SortPriority = -70,
			},

			{
				Name = "Islands Per 1000",	-- odds of generating an island (17)
				Values = {
					"0",
					"2",
					"4",
					"6",
					"8",
					"10",
					"12",
					"14",
					"16",
					"18",
					"20",
					"22",
					"24",
					"26",
					"28", --15
					"30", --16
					"32",
					"34",
					"36",
					"38",
					"40",
					"42",
					"44",
					"46",
					"48",
					"50",
				},

				DefaultValue = 16,
				SortPriority = -65,
			},

			{
				Name = "Island Max Size",	-- (18)
				Values = {
					"1",
					"3",
					"5",
					"7",
					"9",
					"11",
					"13",
					"15",
					"17",
					"19",
					"21", --11
					"23",
					"25",
					"27",
					"29",
				},

				DefaultValue = 11,
				SortPriority = -60,
			},

			{
				Name = "Sea Level Modifier",	-- (19)
				Values = {
					"-1",
					" 0",
					"+1",
				},

				DefaultValue = 2,
				SortPriority = -155,
			},

			{
				Name = "Size Odds Exponent",--  (20)
				Values = {
					"(0.30^Size)%",
					"(0.40^Size)%",
					"(0.50^Size)%",
					"(0.75^Size)%", -- 4
					"(0.82^Size)%", -- 5
					"(0.86^Size)%",
					"(0.88^Size)%", -- 7
					"(0.90^Size)%",
					"(0.91^Size)%",
					"(0.92^Size)%",
					"(0.93^Size)%",
					"(0.99^Size)%",
				},

				DefaultValue = 4,
				SortPriority = -55,
			},

			{
				Name = "Mountains",	-- add setting for rivers (9)
				Values = {
					"Few",
					"Average",
					"Many",
					"Tons",
				},

				DefaultValue = 2,
				SortPriority = -120,
			},
		},
	};
end

------------------------------------------------------------------------------
function GetSizeExponent()
	local choice = Map.GetCustomOption(20);
	local vals = {
		0.30,
		0.40,
		0.50,
		0.75,
		0.82,
		0.86,
		0.88,
		0.90,
		0.91,
		0.92,
		0.93,
		0.99
	};

	return vals[choice];
end

------------------------------------------------------------------------------
function GetMapInitData(worldSize)
	
	local LandSizeX = 28 + (Map.GetCustomOption(11) * 2);
	local LandSizeY = 18 + (Map.GetCustomOption(12) * 2);

	local worldsizes = {};

	worldsizes = {

		[GameInfo.Worlds.WORLDSIZE_DUEL.ID] = {LandSizeX, LandSizeY}, -- 720
		[GameInfo.Worlds.WORLDSIZE_TINY.ID] = {LandSizeX, LandSizeY}, -- 1664
		[GameInfo.Worlds.WORLDSIZE_SMALL.ID] = {LandSizeX, LandSizeY}, -- 2480
		[GameInfo.Worlds.WORLDSIZE_STANDARD.ID] = {LandSizeX, LandSizeY}, -- 3900
		[GameInfo.Worlds.WORLDSIZE_LARGE.ID] = {LandSizeX, LandSizeY}, -- 6076
		[GameInfo.Worlds.WORLDSIZE_HUGE.ID] = {LandSizeX, LandSizeY} -- 9424
		}
		
	local grid_size = worldsizes[worldSize];
	--
	local world = GameInfo.Worlds[worldSize];
	if (world ~= nil) then
		return {
			Width = grid_size[1],
			Height = grid_size[2],
			WrapX = true,
		}; 
	end

end

------------------------------------------------------------------------------
function GetSeaLevel()
	return Map.GetCustomOption(4) * 2 + 48 + (Map.GetCustomOption(19)-2);
end

------------------------------------------------------------------------------
function GeneratePlotTypes()
	print("Generating Plot Types (Lua Small Continents) ...");

	local inverse_continent_sizes = Map.GetCustomOption(15); -- 1 means pangea, 2 means continents, 3, means small cont, etc.
	local sea = GetSeaLevel();
	local age = Map.GetCustomOption(1);
	local maxX = Map.GetCustomOption(11)*2+28; -- get map x size
	local maxY = Map.GetCustomOption(12)*2+18; -- get map y size
	local islandSizeMin = 2;
	local islandSizeMax = Map.GetCustomOption(18)*2-1;
	local islandChance = Map.GetCustomOption(17)*2; -- chance in 1000 that an island will start generating (Standard size does 4000 checks)
	local polesIslandChance = islandChance / 2; -- chance in 1000 that an island will start generating in polar region
	local poleClearDist = 7; -- clear all land at this range
	local polesAddDist =  3; -- add small islands up to this range 
	local geometricReduction = GetSizeExponent();

	if age == 4 then
		age = 1 + Map.Rand(3, "Random World Age - Lua");
	end

	print("Sea Level: " .. sea);
	local args = {
		sea_level = 1,
		world_age = age,
		sea_level_low = sea,
		sea_level_normal = 75,
		sea_level_high = 85,
		extra_mountains = 3 * (Map.GetCustomOption(21)-1), -- at 0, very few mountains, at 40, ~15% of all land is mountains
		adjust_plates = 1.65, -- overlapping plates form mountains 0 forms giant mountain regions
		-- 1.5 pushes them apart a lot
		tectonic_islands = false, -- should we form islands where plates overlap?
		has_center_rift = false,
		continent_grain = inverse_continent_sizes
	}

	-- generate using primary continent algorithm
	local fractal_world = FractalWorld.Create();
	fractal_world:InitFractal{
		continent_grain = inverse_continent_sizes,
		has_center_rift = false
	};
	local plotTypes = fractal_world:GeneratePlotTypes(args);


	-- add random islands
	for x = 0, maxX - 1 do
		for y = 0, maxY - 1 do
			local i = GetI(x,y,maxX);
			if plotTypes[i] == PlotTypes.PLOT_OCEAN then
				if Map.Rand(1000, "Island Chance") < islandChance then
					RandomIsland(plotTypes,x,y,maxX,GenIslandSize(islandSizeMin,islandSizeMax,geometricReduction))
				end
			end
		end
	end

	-- remove near poles
	-- re add small stuff near poles 
	if Map.GetCustomOption(16)==1 then
		for x = 0, maxX - 1 do
			for y = 0, maxY - 1 do
				local i = y * maxX + x + 1;
				if y < poleClearDist or y > maxY-poleClearDist then
					plotTypes[i] = PlotTypes.PLOT_OCEAN; -- clear land
				end
				if y == poleClearDist or y == maxY-poleClearDist then
					if Map.Rand(1000, "Pole Clear Chance") < 500 then
						plotTypes[i] = PlotTypes.PLOT_OCEAN; -- make it semi random
						-- so no one concludes intelligent design
					end
				end
				if y <= polesAddDist or y >= maxY-polesAddDist then
					if Map.Rand(1000, "Pole Island Chance") < polesIslandChance then
						RandomIsland(plotTypes,x,y,maxX,Map.Rand(6, "Pole Size")+1)
					end
				end
			end
		end
	end
	SetPlotTypes(plotTypes);

	local args = {expansion_diceroll_table = {10, 4, 4}};
	GenerateCoasts(args);
end
------------------------------------------------------------------------------
-- creates a random island starting with x,y and going around that point 
-- bouncing positive and negative until numLandTiles is reached
-- maxX needs to be the width of the map
-- plotTypes needs to be the linear array of tile types
------------------------------------------------------------------------------
function RandomIsland(plotTypes,x,y,maxX,numLandTiles)
	local remaining = numLandTiles;
	local start = GetI(x,y,maxX);
	if plotTypes[start] == PlotTypes.PLOT_OCEAN then
		plotTypes[start] = RandomPlot(40,40,8*numLandTiles-8,0);
	end
	for d = 1, 15 do -- (start with 1 since we already did 0)
		for u = 0, d do
			local xOffA=Switch(u);
			local yOffA=Switch(d - u);
			local i = GetI(x+xOffA,y+yOffA,maxX);
			-- don't replace an existing non ocean tile
			if plotTypes[i] == PlotTypes.PLOT_OCEAN then
				plotTypes[i] = RandomPlot(40,40,18,20);
			end
			-- reduce count if we added/already have a land tile here
			if plotTypes[i] ~= PlotTypes.PLOT_OCEAN then
				remaining = remaining - 1;
			end
			-- we are done making the island
			if remaining <= 0 then
				return;
			end
		end
	end
end

function GenIslandSize(min,max,c)
	return GeometricRand(min, max, c);
end
-------------------------------------------------
-- https://www.wolframalpha.com/input/?i=y%3D0.8%5Ex+from+1+to+10
-------------------------------------------------
function GeometricRand(a,b,c)
	local odds = math.floor(c*1000);

	val = a;
	while val<b do
		-- return [0,x-1] -- so a 99% chance should be possible
		if Map.Rand(1000, "Geometric Random") >= odds then
			return val;
		end
		val = val + 1;
	end
	return b
end
-------------------------------------------------
-- maps positive integers: 0, 1, 2, 3, 4 etc.
-- to alternating signed:  0,-1, 1,-2, 2 etc.
-------------------------------------------------
function Switch(offset)
	if (offset % 2 == 0) then -- is even number
		return offset/2;
	else                      -- is odd number
		return (1+offset)/-2
	end
end
------------------------------------------------------------------------------
-- randomly generates a plot type weighted by (l)and, (h)ills, (m)ountain, (o)cean
------------------------------------------------------------------------------
function RandomPlot(l,h,m,o)
	local rand = Map.Rand(l+h+m+o, "Random Plot");
	if rand < l then                -- first part of probability distribution
		return PlotTypes.PLOT_LAND
	elseif rand < l+h then          -- second part
		return PlotTypes.PLOT_HILLS
	elseif rand < l+h+m then
		return PlotTypes.PLOT_MOUNTAIN
	else
		return PlotTypes.PLOT_OCEAN
	end
end
------------------------------------------------------------------------------
-- converts an x,y coordinate into an linear index
------------------------------------------------------------------------------
function GetI(x,y,maxX)
	return y * maxX + x + 1;
end
------------------------------------------------------------------------------
function GenerateTerrain()

	local DesertPercent = 28;

	-- Get Temperature setting input by user.
	local temp = Map.GetCustomOption(2);
	if temp == 4 then
		temp = 1 + Map.Rand(3, "Random Temperature - Lua");
	end

	local grassMoist = Map.GetCustomOption(8);

	local args = {
			temperature = temp,
			iDesertPercent = DesertPercent,
			iGrassMoist = grassMoist,
			};

	local terraingen = TerrainGenerator.Create(args);

	terrainTypes = terraingen:GenerateTerrain();
	
	SetTerrainTypes(terrainTypes);


end

------------------------------------------------------------------------------
function AddFeatures()

	-- Get Rainfall setting input by user.
	local rain = Map.GetCustomOption(3)
	if rain == 4 then
		rain = 1 + Map.Rand(3, "Random Rainfall - Lua");
	end
	
	local args = {rainfall = rain}
	local featuregen = FeatureGenerator.Create(args);

	-- False parameter removes mountains from coastlines.
	featuregen:AddFeatures(false);
end
------------------------------------------------------------------------------

------------------------------------------------------------------------------
function StartPlotSystem()

	local RegionalMethod = 2;

	-- Get Resources setting input by user.
	local res = Map.GetCustomOption(13)
	local starts = Map.GetCustomOption(5)
	--if starts == 7 then
		--starts = 1 + Map.Rand(8, "Random Resources Option - Lua");
	--end

	-- Handle coastal spawns and start bias
	MixedBias = false;
	BalancedCoastal = false;
	OnlyCoastal = false;
	CoastLux = false;

	print("Creating start plot database.");
	local start_plot_database = AssignStartingPlots.Create()
	
	print("Dividing the map in to Regions.");
	-- Regional Division Method 1: Biggest Landmass
	local args = {
		method = RegionalMethod,
		start_locations = starts,
		resources = res,
		CoastLux = CoastLux,
		NoCoastInland = OnlyCoastal,
		BalancedCoastal = BalancedCoastal,
		MixedBias = MixedBias;
		};
	start_plot_database:GenerateRegions(args)

	print("Choosing start locations for civilizations.");
	start_plot_database:ChooseLocations()
	
	print("Normalizing start locations and assigning them to Players.");
	start_plot_database:BalanceAndAssign(args)

	print("Placing Natural Wonders.");
	local wonders = Map.GetCustomOption(7)
	if wonders == 14 then
		wonders = Map.Rand(13, "Number of Wonders To Spawn - Lua");
	else
		wonders = wonders - 1;
	end

	print("########## Wonders ##########");
	print("Natural Wonders To Place: ", wonders);

	local wonderargs = {
		wonderamt = wonders,
	};
	start_plot_database:PlaceNaturalWonders(wonderargs);
	print("Placing Resources and City States.");
	start_plot_database:PlaceResourcesAndCityStates()

	-- tell the AI that we should treat this as a naval expansion map
	Map.ChangeAIMapHint(4);

end
------------------------------------------------------------------------------