int g_iLevelExpReq[MAX_LEVEL + 1];
float g_iInterfaceHeight;

// Player Stats
enum SCORE
{
	GOOD = 0, 
	PERFECT, 
	MISS, 
	COMBO, 
	TOTAL, 
	MAX_COMBO, 
	BAD, 
	LIFE, 
	COMBO_REGEN, 
	bool:INGAME
};

int g_iPlayers[MAXPLAYERS + 1][SCORE];

enum DIFFICULTY
{
	dID,
	String:upperName[64],
	String:lowerName[64],
	String:shortName[4],
	String:color[32],
	Float:arrowSpeed,
	Float:multiplicator,
	Float:perfectCombo,
	Float:perfectComboDiff
};

int g_iDifficulty[DIFFICULTY_COUNT][DIFFICULTY];

// Team Scores
int g_iScoreTeam1, g_iScoreTeam2;

// Player Database
Handle g_hDatabase = null;

// Player Database Stats
enum PLAYER_DATAS
{
	DATABASE_ID = 0, 
	EXPERIENCE, 
	LEVEL
}
int g_PlayerDatas[MAXPLAYERS + 1][PLAYER_DATAS];

// Bot/Viewcontrol
Handle g_hBotFreeze = null;
int view_control = -1;
int g_iViewControlTriggerEntity = -1;
int g_iBot = -1;

// Status stuff
int status;
bool g_bIsInGame = false;
bool g_bIsGameTeam = false;
bool g_bTestingSong = false;
bool g_bIsInRecord = false;
int g_iRecordingClient = -1;
bool g_bSongSelected = false;
bool g_bAllowStop = false;
bool g_bInEnding = false;

bool g_bDev = false;

// Recording Sequence
int g_iRecordedNote = 0;
char g_sFileRecord[256];
Handle g_hFileRecord = null;

// Timer to check game status
Handle g_hTimerCheckMode = null;

// Songlist
ArrayList ArrayMusicName = null;
ArrayList ArrayMusicFile = null;
ArrayList ArrayBackgroundCat = null;

// Song Waitlist
ArrayList ArrayWaitListSongIDClientID = null;
ArrayList ArrayWaitListSongID = null;
ArrayList ArrayWaitListDifficulty = null;

// Incoming Song
int g_iComingSongId; // Incoming Song ID
int g_iComingSongDifficulty; // Incoming difficulty
int g_iCountdown; // How many seconds left
int g_iNextClient; // Who selected the next song
char g_sNextMusic[64]; // Song name

// Last Song
int g_iLastPlayedId = -1;
int g_iLastPlayedDifficulty = -1;

// Running Sequence
Handle g_hDelayedSong = null;
Handle g_hMissedTimer = null;
Handle g_hSequenceTimer[MAX_SEQUENCE_LINES] =  { null, ... }; // Each arrow has it's own timer to lunch it
ArrayList ArrayEntityInUse[MAXPLAYERS + 1] =  { null, ... };
ArrayList ArrayEntityButton[MAXPLAYERS + 1] =  { null, ... };
int g_iTicksCount = 0; // How long is the current sequence
float g_fPlayStartTime = 0.0; // When did the sequence start

Handle g_hRankRefresh = null; // Timer to sort players by points
Handle g_hHint = null; // Timer to show current stats

// Players Ingame
ArrayList ArrayPlayerId;
ArrayList ArrayPlayerScore;

// Player Teams
ArrayList g_hArrayTeam_1 = null;
ArrayList g_hArrayTeam_2 = null;
ArrayList g_hArrayTeam_Solo = null;

int g_iTicks[MAXPLAYERS + 1] =  { 0, ... };

int oldButtons[MAXPLAYERS + 1] =  { 0, ... };
int g_iRecordTicksAntiDoublons[MAXPLAYERS + 1] =  { 0, ... };
float g_fAvgPing[MAXPLAYERS + 1] =  { 0.0, ... };

float afLastUsed[MAXPLAYERS + 1];

Handle g_hMsg[MAXPLAYERS + 1] =  { null, ... };

int g_iMenuPick[MAXPLAYERS + 1] =  { 0, ... };
int g_iMenuDifficulty[MAXPLAYERS + 1] =  { 0, ... };

// HUD Background
char g_StringLastTableau[64];

// HUD Arrows
enum ARROWS
{
	ARROW_LEFT = 0, 
	ARROW_DOWN, 
	ARROW_UP, 
	ARROW_RIGHT
}

int g_iArrowsInUse[ARROWS] = 0;

// HUD Combo Word
int g_iHUDComboWordEntity = -1; //Combo word entity
bool g_bHUDComboWordCanView[MAXPLAYERS + 1] =  { false, ... };

// HUD Combo Counter
int g_iHUDComboCounterEntity[3][10];
int g_iHUDComboValues[MAXPLAYERS + 1][3];
Handle g_hClientComboView[MAXPLAYERS + 1] =  { null, ... };

// HUD Healthbar
int g_iHUDHealthBarEntity[10];
int g_iHUDHealthBarLoading;
int g_iHUDHealthBarValue[MAXPLAYERS + 1] =  { -1, ... };

// HUD Static Arrows
int g_iHUDGhostArrowEntity[4];
int g_iHUDGhostArrowActiveEntity[4];
bool g_bHUDGhostArrowCanView[MAXPLAYERS + 1][4];

// HUD Moving Arrows
int g_iHUDArrowEntitys[ARROWS][MAX_ARROWS_PER_TRACK];
bool g_bHUDArrowCanView[MAXPLAYERS + 1][MAX_SEQUENCE_LINES];

// HUD Score View Timer
Handle g_hClientEntityScore = null;

// HUD Score
int g_EntityScore[5][10];
int g_iClientScoreEntity[MAXPLAYERS + 1][5];

// HUD Effects
int g_SmokeSprite = -1;

// Count players in team
int g_iTeam1, g_iTeam2, g_iSolo;

// Platform trigger entities
int g_iTriggerSolo;
int g_iTriggerTeam1;
int g_iTriggerTeam2;
int g_iTriggerSpec;
int g_iTriggerVip;

// NPC trigger entities
int g_iTriggerBar;
int g_iTriggerDJ;
int g_iTriggerShop;
int g_iTriggerDealer;
int g_iTriggerGames;

// Platform origins
float g_fTeleLobby[3];
float g_fTeleSolo[3];
float g_fTeleTeam1[3];
float g_fTeleTeam2[3];

// Where is player
bool g_bSolo[MAXPLAYERS + 1];
bool g_bTeam1[MAXPLAYERS + 1];
bool g_bTeam2[MAXPLAYERS + 1];
bool g_bSpec[MAXPLAYERS + 1];
bool g_bVip[MAXPLAYERS + 1];

// perfect combo
int g_iPerfect[MAXPLAYERS + 1] =  { 0, ... };

// optional plugins
bool g_bXenForo = false;
bool g_bCPS = false;

// block mouse1+mouse2
int m_flNextPrimaryAttack = -1;
int m_flNextSecondaryAttack = -1;

// forwards
Handle g_hClientEnterSong = null;
Handle g_hClientLeftSong = null;
Handle g_hOnSongStart = null;
Handle g_hOnSongEnd = null;

char g_sLogo[MAXPLAYERS + 1][64];

ConVar g_cImmunityAlpha = null;

bool g_bLights = false;