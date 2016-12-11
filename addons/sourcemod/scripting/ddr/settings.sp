/////////// DEBUG ////////////////

#define DEBUG 0

/////////// SOUND VOLUME ///////////////

#define DDR_VOLUME_MUSIC        1.0
#define DDR_VOLUME_COMBO        1.0
#define DDR_VOLUME_FAIL         1.0
#define DDR_VOLUME_COUNTDOWN    1.0
#define DDR_VOLUME_READY        1.0
#define DDR_VOLUME_INSANE       1.0
#define DDR_VOLUME_LVLUP        1.0

/////////// ARRAYS ///////////////

#define MAX_ARROWS_PER_TRACK    16 // 4x16 = 64
#define MAX_SEQUENCE_LINES      2048

////////// INTERFACE /////////////

#define OVERLAY_DURATION        0.2
#define COMBO_VIEWTIME          1.0
#define START_SONG_DELAY        3.15
#define DELAY_UNBLOCK_BUTTON    0.25

/////////// EFFECTS //////////////

#define EFFECT_MISS             0
#define EFFECT_BAD              1
#define EFFECT_GOOD             2
#define EFFECT_PERFECT          3
#define EFFECT_DEAD             4

//////// PLAYER INPUT ////////////

#define DOUBLE_CLICK_PROTECTION_TICKS 5

#define FIX_HEIGHT              2.0 // Adjust Display hight

#define TOLERANCE_PERFECT_MIN   2.5 // Max distance to count as perfect
#define TOLERANCE_GOOD_MIN      12.5 // Max distance to count as good
#define TOLERANCE_MISS_MIN      20.0 // Min distance to get a miss

// Tolerance added depending on each players average ping to the server
#define TOLMUL_PERFECT          0.015
#define TOLMUL_GOOD             0.07
#define TOLMUL_MISS             0.1

/////////// STATUS ///////////////

#define STATUS_NO_WAITLIST      0
#define STATUS_GAME_COUNTDOWN   1
#define STATUS_IN_GAME          2

//////////// LOBBY ///////////////

#define GAME_COUNTDOWN          30

///////// RANK HINT //////////////

#define RANK_HINT_LIMIT_PLAYERS 6
#define RANK_HINT_REFRESH_RATE  1.0
#define RANK_REFRESH_RATE       0.5

///////// DIFFICULTY /////////////

#define DIFFICULTY_EASY         0
#define DIFFICULTY_NORMAL       1
#define DIFFICULTY_HARD         2
#define DIFFICULTY_INSANE       3
#define DIFFICULTY_INSANE_PLUS  4
#define DIFFICULTY_CHAOS        5
#define DIFFICULTY_ULTIMATE     6

#define DIFFICULTY_COUNT        7

/////////// TEAMS ////////////////

#define TEAMS_LOSE_EXP_PERCENT  5
#define TEAMS_DRAW_EXP_PERCENT  10
#define TEAMS_WIN_EXP_PERCENT   20

#define TEAMS_NONE              0
#define TEAMS_TEAM1             1
#define TEAMS_TEAM2             2
#define TEAMS_SOLO              3

/////////// SCORE ////////////////

#define SCORE_POINTS 200

///////////// EXP ////////////////

#define MAX_LEVEL               100
#define EXP_VALUE               40
#define EXP_SCALE               1.1337

//////////// LIFE ////////////////

#define LIFE_TOTAL              100
#define LIFE_START              100
#define LIFE_LOSE_MISS          6
#define LIFE_LOSE_BAD           4
#define LIFE_WIN_PERFECT        2
#define LIFE_WIN_GOOD           1
#define LIFE_WIN_COMBO_AMOUNT   10
#define LIFE_WIN_COMBO_LIFE     5

/////////// COMBO ////////////////

#define COMBO_SUPER             100
#define COMBO_KILLER            200
#define COMBO_TRIPLE            300
#define COMBO_MASTER            400
#define COMBO_ULTRA             500

/////////// POINTS ////////////////

#define POINTS_PERFECT          12
#define POINTS_OK               7

#define POINTS_SUPER_PERFECT    14
#define POINTS_SUPER_OK         8
#define POINTS_SUPER            200

#define POINTS_KILLER_PERFECT   16
#define POINTS_KILLER_OK        9
#define POINTS_KILLER           300

#define POINTS_TRIPLE_PERFECT   18
#define POINTS_TRIPLE_OK        10
#define POINTS_TRIPLE           600

#define POINTS_MASTER_PERFECT 	20
#define POINTS_MASTER_OK        11
#define POINTS_MASTER           1000

#define POINTS_ULTRA_PERFECT    23
#define POINTS_ULTRA_OK         12
#define POINTS_ULTRA            1500

//////////// PERFECT ///////////////

#define PERFECT_POINTS_BASE     1000.0
#define PERFECT_MAX_COMBO       5

#define PERFECT_NO_COMBO        1.2
#define PERFECT_SUPER           1.4
#define PERFECT_KILLER          1.6
#define PERFECT_TRIPLE          1.8
#define PERFECT_MASTER          2.0
#define PERFECT_ULTRA           2.2

////////////// PATH /////////////////

#define PATH_SOUND_SONGS        "DDR2/songs"
#define PATH_SOUND_EVENTS       "DDR2/events"
#define PATH_SONGS_CONFIG       "configs/DDR2/songs"
#define PATH_CONFIG             "configs/DDR2"

////////////// NPC MODELS ///////////////
#define NPC_MODEL_SHOP     "models/characters/hostage_02.mdl"
#define NPC_MODEL_DEALER   "models/hostage/hostage_variantb.mdl"
#define NPC_MODEL_BAR      "models/characters/hostage_03.mdl"
#define NPC_MODEL_DJ       "models/characters/hostage_01.mdl"
#define NPC_MODEL_GAMES    "models/characters/hostage_04.mdl"

////////////// VIP ZONE /////////////////

#define ZONE_VIP_LEVEL          20

///////////// HIDEHUD ////////////////

#define HIDE_HUD_HEALTH_AND_CROSSHAIR ( 1<<4 )
#define HIDE_HUD_RADAR      ( 1<<12 )


// Commands
char g_sStopCMD[][] =  { "stop", "end", "afk", "giveup", "leave", "exit" };
char g_sRankCMD[][] =  { "rank", "rankme", "stats", "statsme", "top", "top10" };
char g_sLevelCMD[][] =  { "level", "lvl" };
char g_sResetCMD[][] =  { "reset", "r", "fr", "fullreset" };

// Event Sounds
char g_sSoundsEvents[][] =  { "combo_breaker", "lvl_up", "ready", "insane" };

// Combo Sounds
char g_sComboSound[][64] =  { "super_combo", "killer_combo", "triple_combo", "master_combo", "ultra_combo" };

// Overlays for combo and dead players
char g_sOverlay[5][256] =  { "nsnf/ddr/miss", "nsnf/ddr/bad", "nsnf/ddr/good", "nsnf/ddr/perfect", "nsnf/ddr/yuv" };

// Game Buttons
int d_Buttons[] =  { IN_MOVELEFT, IN_BACK, IN_FORWARD, IN_MOVERIGHT };