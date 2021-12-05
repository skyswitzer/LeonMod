-- Opener -- Free Science per city, additional per policy taken. Closer grants 33% boost to GS, 25% boost to Growth.
-- Unlock Time
UPDATE PolicyBranchTypes
SET EraPrereq = 'ERA_INDUSTRIAL'
WHERE Type = 'POLICY_BRANCH_RATIONALISM' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );


UPDATE Policies
SET HappinessToScience = '0'
WHERE Type = 'POLICY_RATIONALISM' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

-- Humanism (now Enlightenment) -- boost when happy

UPDATE Policies
SET GreatScientistRateModifier = '0'
WHERE Type = 'POLICY_HUMANISM' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

UPDATE Policies
SET GoldenAgeTurns = '0'
WHERE Type = 'POLICY_HUMANISM' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

UPDATE Policies
SET NumFreeTechs = '1'
WHERE Type = 'POLICY_HUMANISM' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

-- Scientific Revolution
UPDATE Policies
SET OneShot = '0'
WHERE Type = 'POLICY_SCIENTIFIC_REVOLUTION' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

UPDATE Policies
SET MedianTechPercentChange = '0'
WHERE Type = 'POLICY_SCIENTIFIC_REVOLUTION' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );


-- Secularism
DELETE FROM Policy_SpecialistExtraYields
WHERE PolicyType = 'POLICY_SECULARISM';

UPDATE Buildings
SET PolicyType = 'POLICY_SECULARISM'
WHERE Type = 'BUILDING_OBSERVATORY' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

-- Sovereignty
DELETE FROM Policy_BuildingClassYieldChanges
WHERE PolicyType = 'POLICY_SOVEREIGNTY' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

UPDATE Policies
SET HappinessPerTradeRoute = '0'
WHERE Type = 'POLICY_SOVEREIGNTY' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

UPDATE Policies
SET ExtraHappiness = '0'
WHERE Type = 'POLICY_SOVEREIGNTY' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

UPDATE Policies
SET EspionageModifier = '-34'
WHERE Type = 'POLICY_SOVEREIGNTY' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

UPDATE Policies
SET TechCostXCitiesMod = '0'
WHERE Type = 'POLICY_SOVEREIGNTY' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

UPDATE Policies
SET SpecialistFoodChange = '-1'
WHERE Type = 'POLICY_SOVEREIGNTY' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

-- Free Thought
DELETE FROM Policy_BuildingClassYieldModifiers
WHERE PolicyType = 'POLICY_FREE_THOUGHT' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

DELETE FROM Policy_ImprovementYieldChanges
WHERE PolicyType = 'POLICY_FREE_THOUGHT' AND YieldType = 'YIELD_SCIENCE' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

UPDATE Policies
SET GreatScientistBeakerModifier = '25'
WHERE Type = 'POLICY_FREE_THOUGHT' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

UPDATE Policies
SET GreatEngineerHurryModifier = '0'
WHERE Type = 'POLICY_FREE_THOUGHT' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

UPDATE Policies
SET MinorityHappinessMod = '-100'
WHERE Type = 'POLICY_FREE_THOUGHT' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

-- Finisher
UPDATE Policies
SET GreatScientistRateModifier = '33'
WHERE Type = 'POLICY_RATIONALISM_FINISHER' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

UPDATE Policies
SET CityGrowthMod = '25'
WHERE Type = 'POLICY_RATIONALISM_FINISHER' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

UPDATE Policies
SET OneShot = '0'
WHERE Type = 'POLICY_RATIONALISM_FINISHER' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

UPDATE Policies
SET NumFreeTechs = '0'
WHERE Type = 'POLICY_RATIONALISM_FINISHER' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

-- Finisher
--UPDATE Policies
--SET IdeologyPoint = '1'
--WHERE Type = 'POLICY_RATIONALISM_FINISHER' AND EXISTS (SELECT * FROM COMMUNITY WHERE Type='COMMUNITY_CORE_BALANCE_POLICIES' AND Value= 1 );

INSERT INTO Policy_YieldModifiers
	(PolicyType, YieldType, Yield)
VALUES
	('POLICY_RATIONALISM', 'YIELD_SCIENCE', 5),
	('POLICY_HUMANISM', 'YIELD_SCIENCE', 1),
	('POLICY_SCIENTIFIC_REVOLUTION', 'YIELD_SCIENCE', 1),
	('POLICY_FREE_THOUGHT', 'YIELD_SCIENCE', 1),
	('POLICY_SOVEREIGNTY', 'YIELD_SCIENCE', 1),
	('POLICY_SECULARISM', 'YIELD_SCIENCE', 1);

-- NEW
INSERT INTO Policy_BuildingClassHappiness
	(PolicyType, BuildingClassType, Happiness)
VALUES
	('POLICY_HUMANISM', 'BUILDINGCLASS_UNIVERSITY', 1);

INSERT INTO Policy_YieldModifierFromGreatWorks
	(PolicyType, YieldType, Yield)
VALUES
	('POLICY_SECULARISM', 'YIELD_SCIENCE', 3);

INSERT INTO Policy_WLTKDYieldMod
	(PolicyType, YieldType, Yield)
VALUES
	('POLICY_HUMANISM', 'YIELD_CULTURE', 15),
	('POLICY_HUMANISM', 'YIELD_FOOD', 15);

INSERT INTO Policy_ResourceYieldChanges
	(PolicyType, ResourceType, YieldType, Yield)
VALUES
	('POLICY_RATIONALISM', 'RESOURCE_IRON', 'YIELD_SCIENCE', 3),
	('POLICY_RATIONALISM', 'RESOURCE_IRON', 'YIELD_PRODUCTION', 2),
	('POLICY_RATIONALISM', 'RESOURCE_HORSE', 'YIELD_SCIENCE', 3),
	('POLICY_RATIONALISM', 'RESOURCE_HORSE', 'YIELD_PRODUCTION', 2),
	('POLICY_RATIONALISM', 'RESOURCE_COAL', 'YIELD_SCIENCE', 3),
	('POLICY_RATIONALISM', 'RESOURCE_COAL', 'YIELD_PRODUCTION', 2),
	('POLICY_RATIONALISM', 'RESOURCE_OIL', 'YIELD_SCIENCE', 3),
	('POLICY_RATIONALISM', 'RESOURCE_OIL', 'YIELD_PRODUCTION', 2),
	('POLICY_RATIONALISM', 'RESOURCE_ALUMINUM', 'YIELD_SCIENCE', 3),
	('POLICY_RATIONALISM', 'RESOURCE_ALUMINUM', 'YIELD_PRODUCTION', 2),
	('POLICY_RATIONALISM', 'RESOURCE_URANIUM', 'YIELD_SCIENCE', 3),
	('POLICY_RATIONALISM', 'RESOURCE_URANIUM', 'YIELD_PRODUCTION', 2);

INSERT INTO Policy_YieldFromNonSpecialistCitizens
	(PolicyType, YieldType, Yield)
VALUES
	('POLICY_SCIENTIFIC_REVOLUTION', 'YIELD_FOOD', 50);

INSERT INTO Policy_ImprovementYieldChanges
	(PolicyType, ImprovementType, YieldType, Yield)
VALUES
	('POLICY_SCIENTIFIC_REVOLUTION', 'IMPROVEMENT_TRADING_POST', 'YIELD_PRODUCTION', 2),
	('POLICY_SCIENTIFIC_REVOLUTION', 'IMPROVEMENT_TRADING_POST', 'YIELD_GOLD', 1);
