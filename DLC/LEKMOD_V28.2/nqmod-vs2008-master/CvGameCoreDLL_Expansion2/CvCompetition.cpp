

#include <algorithm>
#include "CvGameCoreDLLPCH.h"
#include "FStlContainerSerialization.h"


typedef int(*EvaluateScoreDelegate)(const CvPlayer&);
typedef string(*CreateDescriptionDelegate)(const CvPlayer&);
typedef string(*CreateRewardDescriptionDelegate)(const CvPlayer&); 


// COMPETITION_TRADE_ROUTES_MOST_INTERNATIONAL
int ScoreTradeRoutes(const CvPlayer& player)
{
	// number of trade routes we have with other civ players and city states
	int score = player.GetTrade()->GetNumForeignTradeRoutes(player.GetID());
	return score;
}
int ScoreNumAllies(const CvPlayer& player)
{
	// number of trade routes we have with other civ players and city states
	int score = player.GetNumMinorAllies();
	return score;
}

struct x
{
	EvaluateScoreDelegate Del;
	string desc;
};
x GetScoreDelegateForX[] = {
	{&ScoreTradeRoutes, ""},
};

// List of score calculations.
// Should match number of MiniCompetitionTypes
EvaluateScoreDelegate GetScoreDelegateFor[] = {
	&ScoreTradeRoutes,
	&ScoreNumAllies,
	&ScoreNumAllies,
	&ScoreNumAllies,
	&ScoreNumAllies,

	&ScoreNumAllies,
	&ScoreNumAllies,
	&ScoreNumAllies,
	&ScoreNumAllies,
	&ScoreNumAllies,

	&ScoreNumAllies,
	&ScoreNumAllies,
	&ScoreNumAllies,
	&ScoreNumAllies,
	&ScoreNumAllies,
};



FDataStream& operator<<(FDataStream& kStream, const MiniCompetitionTypes& data)
{
	kStream << (int)data;
	return kStream;
}
FDataStream& operator>>(FDataStream& kStream, MiniCompetitionTypes& data)
{
	int temp;
	kStream >> temp;
	data = (MiniCompetitionTypes)temp;
	return kStream;
}
FDataStream& operator <<(FDataStream& kStream, const CvCompetitionEntry& data)
{
	kStream << data.ePlayer;
	kStream << data.iValue;
	return kStream;
}
FDataStream& operator >>(FDataStream& kStream, CvCompetitionEntry& data)
{
	kStream >> data.ePlayer;
	kStream >> data.iValue;
	return kStream;
}
FDataStream& operator <<(FDataStream& kStream, const CvCompetition& data)
{
	kStream << data.m_eCompetitionType;
	kStream << data.m_entries;
	return kStream;
}
FDataStream& operator >>(FDataStream& kStream, CvCompetition& data)
{
	kStream >> data.m_eCompetitionType;
	kStream >> data.m_entries;
	return kStream;
}
CvCompetition::CvCompetition(const int iNumPlayers, const MiniCompetitionTypes eCompetition)
{
	for (int i = 0; i < iNumPlayers; ++i) // add an entry for each player
		m_entries.push_back(CvCompetitionEntry((PlayerTypes)i));

	m_eCompetitionType = eCompetition;
}
PlayerTypes CvCompetition::GetPlayer(const int iPlace) const
{
	if (iPlace < 0 || iPlace >= m_entries.size())
		return NO_PLAYER;

	if (m_entries[iPlace].iValue == 0) // no score is always last place
		return NO_PLAYER;
	else
		return m_entries[iPlace].ePlayer;
}
int CvCompetition::GetPlace(const PlayerTypes ePlayer) const
{
	int result = m_entries.size() - 1;
	for (int i = 0; i < m_entries.size(); ++i)
	{
		if (m_entries[i].ePlayer == ePlayer) // found player entry
		{
			if (m_entries[i].iValue > 0) // no score is always last place
				result = i;
			break;
		}
	}
	return result;
}
// get what place a player is in (0 is first place)
int CvCompetition::GetValue(const PlayerTypes ePlayer) const
{
	int result = 0;
	for (int i = 0; i < m_entries.size(); ++i)
	{
		if (m_entries[i].ePlayer == ePlayer) // found player entry
		{
			result = m_entries[i].iValue;
			break;
		}
	}
	return result;
}
// sorts competition entries
bool compareEntries(const CvCompetitionEntry& lhs, const CvCompetitionEntry& rhs)
{
	if (lhs.iValue == rhs.iValue) // randomly determine a tie
	{
		unsigned long seed = 0;
		seed += 321891373 + lhs.ePlayer;
		seed += 98615 * lhs.iValue;
		seed += 96429789 + rhs.ePlayer;
		seed += 927 * rhs.iValue;
		int randomTieResolution = GC.rand(1, "Competition Tie Resolution", NULL, seed);
		return (bool)randomTieResolution;
	}
	else // higher values go earlier in the array
		return lhs.iValue > rhs.iValue;
}
void CvCompetition::updateAndSort()
{
	// update
	for (int i = 0; i < m_entries.size(); ++i)
	{
		const CvPlayer& player = GET_PLAYER(m_entries[i].ePlayer);
		int score = 0; // no score for dead or minor civs
		if (player.isAlive() && player.isMajorCiv())
			score = GetScoreDelegateFor[(int)m_eCompetitionType](player);

		m_entries[i].iValue = score;
	}
	// sort
	sort(m_entries.begin(), m_entries.end(), compareEntries);
}






