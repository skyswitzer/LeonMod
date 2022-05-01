#pragma once
#include <vector>
#include <FireWorks/FAutoArchive.h>
#include "CvEnums.h"





class CvCompetitionEntry
{
public:
	CvCompetitionEntry() {}
	CvCompetitionEntry(PlayerTypes _ePlayer)
	{
		ePlayer = _ePlayer;
		iScore = 0;
	}
	// player this score is for
	PlayerTypes ePlayer;
	// score in the competition
	int iScore;
};
FDataStream& operator <<(FDataStream& kStream, const CvCompetitionEntry& data);
FDataStream& operator >>(FDataStream& kStream, CvCompetitionEntry& data);
class CvCompetition
{
public:
	CvCompetition();
	CvCompetition(const int iNumPlayers, const MiniCompetitionTypes eCompetition);


	// 0 is first place. NO_PLAYER if iRank is invalid
	PlayerTypes GetPlayerOfRank(const int iRank) const;
	// get what place a player is in (0 is first place)
	int GetRankOfPlayer(const PlayerTypes ePlayer) const;
	// get what competition value this player has
	int GetScoreOfPlayer(const PlayerTypes ePlayer) const;
	// get first place score
	int GetCompetitionWinnerScore() const;
	// get the short description of this competition
	string GetDescriptionShort() const;
	// get the short description of this competition
	string GetDescriptionReward() const;
	// get the description of this competition
	string GetDescription(const PlayerTypes ePlayer = NO_PLAYER) const;


	// calculates values for the competition and sorts the values
	void UpdateAndSort();

	// which type of competition is this?
	MiniCompetitionTypes m_eCompetitionType;
	// list of entries in the competition
	std::vector<CvCompetitionEntry> m_entries;
};
FDataStream& operator <<(FDataStream& kStream, const CvCompetition& data);
FDataStream& operator >>(FDataStream& kStream, CvCompetition& data);
