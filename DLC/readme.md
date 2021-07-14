# Leon Mod
A CIV V mod starting with Lekmod V28.2. Requires all DLC.
* [Lekmod v28.2](https://docs.google.com/document/d/1-i_9E7hD_56WwNgj7LzrkbX7tCuNmud3AVyONijydWs/edit)
* [DLL Code Here](https://github.com/lfricken/nqmod-vs2008)
* Text changes should go in /LEKMOD_V28.2/Override/CIV5Units_Mongol.xml
* Most changes are in /LEKMOD_V28.2/Override/CIV5Units.xml
* AnyWithIslands.lua map file requires this mod and needs to be put in `\Sid Meier's Civilization V\Assets\Maps`



# TODO
Create [Lekmod v28.2](https://docs.google.com/document/d/1-i_9E7hD_56WwNgj7LzrkbX7tCuNmud3AVyONijydWs/edit) Mirror
Create vs2008 iso files and patch Mirror

release v1
	captured cities Urbanization buildings
	make sure wonders do what they claim (like the great wall and terracotta army)
	tech level palace defense bonus

release v2
	make good leaders worse
	fix gimmic leaders
	add messages to notification log
	fix air strike damage notifications
	city state purchasing improvements
	provide way to keep improving internet defense












GetNotifications()->Add
ai investment, see if(sGift.iGoldAmount > 0 && iGoldLeft >= (iGoldReserve / 2))
	which eventually calls DoGoldGiftFromMajor


make priorities, then draw straws and Z draft, with placeholders for humans
once conflicts are handled the same way 


Have AI identify player with most city states, and then divvy up taking that player down
matrix 
	At beginning of game, Use flavor, distance, etc. to get a matrix with some amount of randomness added. Draw straws to divvy up this many CS: floor(#AI * (#CS/#civs)). We'll go through and for the selected civ, boost their favorite 

Static Preference Matrix that gets scaled so each player divies up the CSs to be highest on 2 each (actually, not 2, but 
	for each civ turn, use GPT, Current Influence, and # CS Allies as percent of total to multiply and get a
	So if a civ has a bunch of city states, it will be devalued

Dynamic Preference Matrix
	Use preference Matrix to make purchases, where we compare our preferences to others, and make gifts to those we have the highest relative preference until we are allies, then move on to second highest preference


4 city states and 2 civs
  1 2 3 4 5 6 7 8
1 4 3 2 1
2 1 2 3 4

while some remain, divy up
12
  12
    12
Pick on next guy if none remaining, preferencing his lower priority one first
1243
  12
    12
 ...
1243
  1243
    12
 ...
1243
  1243
43  12
 ...
124365
  1243
43  12
 ...
124365
651243
43  12
 ...
124365
651243
436512

 1 2 3
 3 1 2
 2 3 1


BUILDING_POLICY_BONUS_SEA_PRODUCTION


TOURISM_COMBAT_MAX
TOURISM_COMBAT_DIVISOR
MAX_CITY_HIT_POINTS_AI_BONUS
test tourism combat
test ai city health
ironclad takes iron not coal
Battleship and Carrier description
zoo require horses
Add global xml to adjust tourism combat
great firewall dll changes
stade horse requirement, remove culture and gold changes
great lighthouse shuld give gold per tile
3 gpt for mausoleum
800 health cities
evasion 50 > 40
evasion 100 > 75
remove logistics (multiple attacks promotion)
improve air sweep description
improve evasion description
improve interception description
new air mechanics
interceptor damage modifier
interceptor damage modifier xml
stealth bomber use oil
bomber use aluminum
double check missile evasion Requires 1 [ICON_RES_ALUMINUM] Aluminum.[NEWLINE]
spearman bowmen catapult
remove no intercept for self restriction
figure out GetInterceptionDamage
salt and marble for Rock Formation
panama canal 3 gpt -1 culture per tile
Petra +1 gold per tile
8 science porcelain tower, +5 culture
move porcelain tower down
red fort 6 culture
make sure city strength scales appropriately
Revert Honor
revert honor
National Epic 2 culture
--
Liberty
Remove Happiness Colloseum bonus
Settler +1+1 in Liberty-Collective Rule.
Meritocracy Palace +4 Happiness at palace
City Hall +1 Happiness Representation
City Hall +1 science Liberty Finisher
City Hall +1 Gold in Opener
City Hall starts in opener.
--
Exploration > rename Urbanization
Treasure Fleets:
	Iron Works +5 prod, 4 culture, 2 gold
Opener:	
	+10% when constructing buildings --
Finisher: 
	+1 Gold per sea
	Earn Great admiralls

Maritime Infrastructure:
	+2 prod per mountain, +2 prod per city, +15% prod in capital	-- POLICY_MARITIME_INFRASTRUCTURE BUILDING_POLICY_BONUS_MOUNTAIN_PRODUCTION
Colonialism:
	Strategic and Bonus Resources +1 Production
Navigation School:
	+1 prod per Sea
Naval Tradition:
	+2 science per Forge, Windmill, workshop
	
RESOURCE_STONE
RESOURCE_RUBBER
RESOURCE_HARDWOOD
RESOURCE_WHEAT

RESOURCE_MAIZE
RESOURCE_COW
RESOURCE_FISH

RESOURCE_DEER
RESOURCE_BISON
RESOURCE_SHEEP

RESOURCE_BANANA
RESOURCE_HORSE
RESOURCE_URANIUM

RESOURCE_IRON
RESOURCE_OIL
RESOURCE_ALUMINUM

remove great war bomber recon
policies glitched
missile high evasion
Louvre to public
Decrease culture policy cost by 20%
Worlds fair 50 rather than 66%.
commerce internal to 50%
25 instead of 20 gold purchase price reduction

"D:\SteamLibrary\steamapps\common\Sid Meier's Civilization V\Assets\DLC\LEKMOD_V28.2\Override\CIV5Units.xml"

City Hall - An inscribed stone at the center of a city, declaring the common law that citizens of a large empire must obey and cooperate under.

<Row> 
	<PromotionType>PROMOTION_FASTER_HEAL</PromotionType> 
	<UnitCombatType>UNITCOMBAT_SUBMARINE</UnitCombatType> 
</Row>
<Row> 
	<PromotionType>PROMOTION_FASTER_HEAL</PromotionType> 
	<UnitCombatType>UNITCOMBAT_CARRIER</UnitCombatType> 
</Row>
<Row> 
	<PromotionType>PROMOTION_FASTER_HEAL</PromotionType> 
	<UnitCombatType>UNITCOMBAT_NAVALRANGED</UnitCombatType> 
</Row>
<Row> 
	<PromotionType>PROMOTION_FASTER_HEAL</PromotionType> 
	<UnitCombatType>UNITCOMBAT_NAVALMELEE</UnitCombatType> 
</Row>

defense buildings need to add more health
TXT_KEY_BUILDING_GOVERNORS_MANSION_DESC



















island gen avoid colliding with other land masses with below algorithm - you can detect isthmuses via tile types by looping over adjacents and detecting # of changes
HELICOPTERS and SUBMARINES should be bad vs eachother
Most Natural wonders kinda suck
Move louve to low aesthetics
Move uffizi down
Move porcelain tower down and buff a bit
civ 5 minor civ priorities
Piety boost?
Pentagon insta units with upgrade reduction
Nuclear missile less damage, cheaper, less pop damage

buff naval melee strength (including sub and destroyer strength)
subs cannot see other subs
Destroyer 50% bonus vs ranged
Sub 100% bonus vs ranged

Subs and Destroyers <-- for sea domination
Battleships, Carrier, Embarked <-- For attacking land

Destroyers are better than subs in that:
they can take cities
they can defend friendly units against air
they can see subs at a distance

# Useful Info
Embed other data like so: {TEXT_KEY}


[ICON_HAPPINESS_1]
[ICON_GOLD]
[ICON_RESEARCH]
[ICON_CULTURE]
[ICON_TOURISM]
[ICON_PRODUCTION]PROMOTION_NO_CITY_ATTACK


Epic.Access.Referrals.ReferralLookup.Web.ReferralContext
2.75 - 3 - 0.25
2.00 - 2 - 1
1.25 - 1 - 0.25

{self.uranium_ID, uran_amt, 50, 10, 0} };

res_ID[index] = resource_data[1];
res_quantity[index] = resource_data[2];
res_weight[index] = resource_data[3];
res_min[index] = resource_data[4]; -- 10
res_max[index] = resource_data[5]; -- 0



function random(center, range)

rounded = math.floor(0.5 + val);
getResourceAmount
PlaceSpecificNumberOfResources

SetResourceType


elseif resourceType == "RESOURCE_IRON" then
	self.iron_ID = resourceID;
elseif resourceType == "RESOURCE_HORSE" then
	self.horse_ID = resourceID;
elseif resourceType == "RESOURCE_COAL" then
	self.coal_ID = resourceID;
elseif resourceType == "RESOURCE_OIL" then
	self.oil_ID = resourceID;
elseif resourceType == "RESOURCE_ALUMINUM" then
	self.aluminum_ID = resourceID;
elseif resourceType == "RESOURCE_URANIUM" then
	self.uranium_ID = resourceID;

ROUTE_RAILROAD
			<RouteType>ROUTE_RAILROAD</RouteType> 
