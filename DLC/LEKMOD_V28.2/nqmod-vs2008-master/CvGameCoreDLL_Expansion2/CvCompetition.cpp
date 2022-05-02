

#include <algorithm>
#include "CvGameCoreDLLPCH.h"
#include "FStlContainerSerialization.h"
#include "CvGameCoreUtils.h"


struct CompetitionDelegates
{
	virtual int EvalScore(const CvPlayer& player) const = 0;
	virtual string DescReward(const CvCompetition& rCompetition) const = 0;
	virtual string Desc(const CvCompetition& rCompetition, const PlayerTypes ePlayer) const = 0;
	virtual string DescShort(int iWinningScore) const = 0;
};

const int INVALID_SCORE = 0;
string tryAddCurrentScore(const CvCompetition& rCompetition, const PlayerTypes ePlayer)
{
	stringstream ss;
	if (ePlayer != NO_PLAYER)
	{
		ss << "[NEWLINE][NEWLINE]You currently have [COLOR_WARNING_TEXT]" << rCompetition.GetScoreOfPlayer(ePlayer) << "[ENDCOLOR].";
	}
	return ss.str();
}


// COMPETITION_TRADE_ROUTES_INTERNATIONAL
struct TradeRoutes : CompetitionDelegates
{
	virtual string DescShort(int iWinningScore) const
	{
		stringstream ss;
		ss << "Most International {TRADE_ROUTE}s: [COLOR_POSITIVE_TEXT]" << iWinningScore << "[ENDCOLOR]";
		return ss.str();
	}
	virtual string DescReward(const CvCompetition& rCompetition) const
	{
		stringstream ss;
		ss << "+20 {DIPLOMATIC_INFLUENCE}";
		return ss.str();
	}
	virtual string Desc(const CvCompetition& rCompetition, const PlayerTypes ePlayer) const
	{
		stringstream ss;
		ss << "The civilization with the most International {TRADE_ROUTE}s (routes ending on another Civilization or City State)";
		ss << tryAddCurrentScore(rCompetition, ePlayer);
		return ss.str();
	}
	virtual int EvalScore(const CvPlayer& player) const
	{
		int score = player.GetTrade()->GetNumForeignTradeRoutes(player.GetID());
		return score;
	}
};
// COMPETITION_ALLIES
struct Allies : CompetitionDelegates
{
	virtual string DescShort(int iWinningScore) const
	{
		stringstream ss;
		ss << "Most Controlled {CITY_STATE}s: [COLOR_POSITIVE_TEXT]" << iWinningScore << "[ENDCOLOR]";
		return ss.str();
	}
	virtual string DescReward(const CvCompetition& rCompetition) const
	{
		stringstream ss;
		ss << "+20 {DIPLOMATIC_INFLUENCE}";
		return ss.str();
	}
	virtual string Desc(const CvCompetition& rCompetition, const PlayerTypes ePlayer) const
	{
		stringstream ss;
		ss << "The civilization with the most {CITY_STATE}s controlled (allies or conquered)";
		ss << tryAddCurrentScore(rCompetition, ePlayer);
		return ss.str();
	}
	virtual int EvalScore(const CvPlayer& player) const
	{
		int perTurn, numControlled;
		player.GetDiplomaticInfluencePerTurn(&perTurn, &numControlled);
		return numControlled;
	}
};
// COMPETITION_GOLD_GIFTS
struct GoldGifts : CompetitionDelegates
{
	virtual string DescShort(int iWinningScore) const
	{
		stringstream ss;
		ss << "Most [ICON_INVEST] Gold Gifted: [COLOR_POSITIVE_TEXT]" << iWinningScore << "[ENDCOLOR]";
		return ss.str();
	}
	virtual string DescReward(const CvCompetition& rCompetition) const
	{
		stringstream ss;
		ss << "+20 {DIPLOMATIC_INFLUENCE}";
		return ss.str();
	}
	virtual string Desc(const CvCompetition& rCompetition, const PlayerTypes ePlayer) const
	{
		stringstream ss;
		ss << "The civilization with the most total [ICON_GOLD] Gold gifted to city states";
		ss << tryAddCurrentScore(rCompetition, ePlayer);
		return ss.str();
	}
	virtual int EvalScore(const CvPlayer& player) const
	{
		int iScore = player.GetNumGoldGiftedToMinors();
		return iScore;
	}
};
// COMPETITION_NUCLEAR_STOCKPILE
struct Nukes : CompetitionDelegates
{
	virtual string DescShort(int iWinningScore) const
	{
		stringstream ss;
		ss << "Largest [ICON_RES_URANIUM] Nuclear Arsenal: [COLOR_POSITIVE_TEXT]" << iWinningScore << "[ENDCOLOR]";
		return ss.str();
	}
	virtual string DescReward(const CvCompetition& rCompetition) const
	{
		stringstream ss;
		ss << "+20 {DIPLOMATIC_INFLUENCE}";
		return ss.str();
	}
	virtual string Desc(const CvCompetition& rCompetition, const PlayerTypes ePlayer) const
	{
		stringstream ss;
		ss << "The civilization with the largest [ICON_RES_URANIUM] Nuclear Arsenal";
		ss << tryAddCurrentScore(rCompetition, ePlayer);
		return ss.str();
	}
	virtual int EvalScore(const CvPlayer& player) const
	{
		int iScore = player.GetNumNuclearWeapons();
		return iScore;
	}
};
// COMPETITION_SCIENCE_SPECIALISTS
struct ScienceSpecialists : CompetitionDelegates
{
	virtual string DescShort(int iWinningScore) const
	{
		stringstream ss;
		ss << "Most [ICON_GREAT_PEOPLE] Scientists: [COLOR_POSITIVE_TEXT]" << iWinningScore << "[ENDCOLOR]";
		return ss.str();
	}
	virtual string DescReward(const CvCompetition& rCompetition) const
	{
		stringstream ss;
		ss << "+20 {SCIENTIFIC_INFLUENCE}";
		return ss.str();
	}
	virtual string Desc(const CvCompetition& rCompetition, const PlayerTypes ePlayer) const
	{
		stringstream ss;
		ss << "The civilization with the most working science specialists";
		ss << tryAddCurrentScore(rCompetition, ePlayer);
		return ss.str();
	}
	virtual int EvalScore(const CvPlayer& player) const
	{
		int iScore = player.GetNumScienceSpecialists();
		return iScore;
	}
};
void CvGlobals::initCompetitions()
{
	GetDelegatesFor.push_back(new TradeRoutes());
	GetDelegatesFor.push_back(new Allies());
	GetDelegatesFor.push_back(new GoldGifts());
	GetDelegatesFor.push_back(new Nukes());

	GetDelegatesFor.push_back(new ScienceSpecialists());
}
void CvGlobals::uninitCompetitions()
{
	for (int i = 0; i < GetDelegatesFor.size(); ++i)
	{
		delete GetDelegatesFor[i];
	}
	GetDelegatesFor.clear();
}
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
	kStream << data.eType;
	kStream << data.ePlayer;
	kStream << data.iScore;
	return kStream;
}
FDataStream& operator >>(FDataStream& kStream, CvCompetitionEntry& data)
{
	kStream >> data.eType;
	kStream >> data.ePlayer;
	kStream >> data.iScore;
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
CvCompetition::CvCompetition()
{

}
CvCompetition::CvCompetition(const int iNumPlayers, const MiniCompetitionTypes eCompetition)
{
	for (int i = 0; i < iNumPlayers; ++i) // add an entry for each player
		m_entries.push_back(CvCompetitionEntry((PlayerTypes)i, eCompetition));

	m_eCompetitionType = eCompetition;
}
PlayerTypes CvCompetition::GetPlayerOfRank(const int iRank) const
{
	if (iRank < 0 || iRank >= m_entries.size())
		return NO_PLAYER;

	//if (m_entries[iRank].iScore == INVALID_SCORE) // no score is always last place
	//	return NO_PLAYER;
	//else
	return m_entries[iRank].ePlayer;
}
int CvCompetition::GetRankOfPlayer(const PlayerTypes ePlayer) const
{
	int result = m_entries.size() - 1;
	for (int i = 0; i < m_entries.size(); ++i)
	{
		if (m_entries[i].ePlayer == ePlayer) // found player entry
		{
			//if (m_entries[i].iScore > INVALID_SCORE) // no score is always last place
			result = i;
			//else // automatically set up top
			//	result = m_entries.size() - 1;
			break;
		}
	}
	return result;
}
int CvCompetition::GetScoreOfPlayer(const PlayerTypes ePlayer) const
{
	int result = 0;
	for (int i = 0; i < m_entries.size(); ++i)
	{
		if (m_entries[i].ePlayer == ePlayer) // found player entry
		{
			result = m_entries[i].iScore;
			break;
		}
	}
	return result;
}
bool compareEntries(const CvCompetitionEntry& lhs, const CvCompetitionEntry& rhs)
{
	if (lhs.iScore == rhs.iScore) // randomly determine a tie
	{
		unsigned long seed = 0;
		seed += 98456213594 * lhs.eType;
		seed += 98615 * lhs.iScore;
		seed += 321891373 * lhs.ePlayer;
		seed += 96429789 * rhs.ePlayer;
		int randomTieResolution = GC.rand(1, "Competition Tie Resolution", NULL, seed);
		return (bool)randomTieResolution;
	}
	else // higher values go earlier in the array
		return lhs.iScore > rhs.iScore;
}
int CvCompetition::GetCompetitionWinnerScore() const
{
	return GetScoreOfPlayer(GetPlayerOfRank(0));
}
string CvCompetition::GetDescriptionShort() const
{
	return GetLocalizedText(GC.GetDelegatesFor[(int)m_eCompetitionType]->DescShort(GetCompetitionWinnerScore()).c_str());
}
string CvCompetition::GetDescriptionReward() const
{
	return GetLocalizedText(GC.GetDelegatesFor[(int)m_eCompetitionType]->DescReward(*this).c_str());
}
string CvCompetition::GetDescription(const PlayerTypes ePlayer) const
{
	return GetLocalizedText(GC.GetDelegatesFor[(int)m_eCompetitionType]->Desc(*this, ePlayer).c_str());
}
void CvCompetition::UpdateAndSort()
{
	// update
	for (int i = 0; i < m_entries.size(); ++i)
	{
		const CvPlayer& player = GET_PLAYER(m_entries[i].ePlayer);
		int score = 0; // no score for dead or minor civs
		if (player.isAlive() && player.isMajorCiv())
			score = GC.GetDelegatesFor[(int)m_eCompetitionType]->EvalScore(player);

		m_entries[i].iScore = score;
	}
	// sort
	sort(m_entries.begin(), m_entries.end(), compareEntries);
}






