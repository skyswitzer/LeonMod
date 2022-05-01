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
		iValue = 0;
	}
	// player this score is for
	PlayerTypes ePlayer;
	// score in the competition
	int iValue;
};
FDataStream& operator <<(FDataStream& kStream, const CvCompetitionEntry& data);
FDataStream& operator >>(FDataStream& kStream, CvCompetitionEntry& data);
class CvCompetition
{
public:
	CvCompetition() {};
	CvCompetition(const int iNumPlayers, const MiniCompetitionTypes eCompetition);

	// 0 is first place NO_PLAYER if
	PlayerTypes GetPlayer(const int iPlace) const;
	// get what place a player is in (0 is first place)
	int GetPlace(const PlayerTypes ePlayer) const;
	// get what competition value this player has
	int GetValue(const PlayerTypes ePlayer) const;
	// calculates values for the competition and sorts the values
	void updateAndSort();

	// which type of competition is this?
	MiniCompetitionTypes m_eCompetitionType;
	// list of entries in the competition
	std::vector<CvCompetitionEntry> m_entries;
};
FDataStream& operator <<(FDataStream& kStream, const CvCompetition& data);
FDataStream& operator >>(FDataStream& kStream, CvCompetition& data);
