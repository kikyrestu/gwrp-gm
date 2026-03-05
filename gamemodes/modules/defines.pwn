// ============================================================================
// MODULE: defines.pwn
// All defines, enums, constants, and global variables
// ============================================================================

// ============================================================================
// DEFINES
// ============================================================================

#define MYSQL_HOST              "127.0.0.1"
#define MYSQL_USER              "root"
#define MYSQL_DB                "astawnew"
#define MYSQL_PASS              ""
#define MYSQL_LOG_TYPE          LOG_ERROR

#define TABLE_ACCOUNTS          "accounts"

#define GAMEMODE_HOSTNAME       "Westfield RolePlay"
#define GAMEMODE_NAME           "Westfield-RP"
#define SUPPORT_EMAIL           "test@sa-mp.com"

#undef MAX_PLAYERS
#define MAX_PLAYERS             50

#define INVALID_PLAYER_DATA     -1
#define MAX_IC_NAME_LEN         32
#define MAX_PASSWORD_LEN        36
#define MAX_IPADRESS_LEN        40
#define MAX_CHATMESS_LEN        144
#define BYTES_PER_CELL          (cellbits / 8)

#define PlayerName(%1)          PlayerInfo[%1][pName]
#define publics:%0(%1)          forward %0(%1); public %0(%1)
#define HidePlayerDialog(%1)    ShowPlayerDialog(%1,-1,0,"","","","")

// Colors
#define COLOR_FADE1             0xE6E6E6E6
#define COLOR_FADE2             0xC8C8C8C8
#define COLOR_FADE3             0xAAAAAAAA
#define COLOR_FADE4             0x8C8C8C8C
#define COLOR_FADE5             0x6E6E6E6E
#define COLOR_RED               0xFF0000FF
#define COLOR_YELLOW            0xFFFF00FF
#define COLOR_HOSPITAL          0x00CED1FF
#define COLOR_ME                0xC2A2DAFF  // /me /ame purple
#define COLOR_DO                0x6699FFFF  // /do blue-ish
#define COLOR_SHOUT             0xFFFF00FF  // /shout yellow
#define COLOR_WHISPER           0xFFFF00FF  // /whisper yellow
#define COLOR_OOC               0xA9C4E4FF  // /b OOC chat
#define COLOR_ADMIN             0xFF6347FF  // admin chat
#define COLOR_ANNOUNCE          0x00CC00FF  // global announcement
#define COLOR_REPORT            0xFFAA00FF  // report notif

// Admin levels (new hierarchy)
#define ADMIN_MANAGEMENT        1   // Moderation, player management, ban/kick/jail
#define ADMIN_DEVMAP            2   // Management + server build/setup + mapping tools
#define ADMIN_DEVELOPER         3   // Highest — same access as DevMap

// Admin dialog IDs
#define DIALOG_REPORTS          120
#define DIALOG_REPORT_DETAIL    121
#define DIALOG_HELP_MANAGEMENT  170
#define DIALOG_HELP_DEVMAP      171
#define DIALOG_HELP_DEVELOPER   172

// Location system
#define MAX_LOCATIONS           100
#define DIALOG_LOC_TYPE         130
#define DIALOG_LOC_NAME         131
#define DIALOG_LOC_ICON         132
#define DIALOG_LOC_LIST         133

// KTP Service system
#define DIALOG_KTP_SERVICE      140
#define DIALOG_KTP_QUEUE        141
#define DIALOG_KTP_BIRTHPLACE   142
#define DIALOG_KTP_ADDRESS      143
#define DIALOG_KTP_MARITAL      144
#define DIALOG_KTP_OCCUPATION   145
#define DIALOG_KTP_BLOOD        146
#define DIALOG_KTP_FULLNAME     148
#define DIALOG_KTP_CONFIRM      147

#define MAX_KTP_QUEUE           10
#define MAX_MALL_PELAYANAN      10

// Interior system
#define MAX_INTERIORS           50
#define INTERIOR_RANGE          1.5

// SIM License system
#define MAX_SIM_STATIONS        10
#define DIALOG_SIM_SERVICE      150
#define DIALOG_SIM_TYPE         151
#define DIALOG_SIM_QUIZ         152
#define DIALOG_SIM_RESULT       153
#define SIM_QUIZ_TOTAL          10
#define SIM_QUIZ_PASS_SCORE     7
#define SIM_TYPE_A              1
#define SIM_TYPE_B              2
#define SIM_TYPE_C              3

// Go Food locker system
#define MAX_GOFOOD_LOCKERS      60
#define LOCKER_PER_CITY         20
#define LOCKER_OBJECT_MODEL     2003
#define LOCKER_RANGE            2.0
#define GOFOOD_ACTOR_SKIN       261
#define MAX_GOFOOD_CART         5
#define GOFOOD_MAP_ICON_ID      100
#define GOFOOD_MIN_DELIVERY     30000   // 30 detik minimum
#define GOFOOD_MAX_DELIVERY     180000  // 3 menit maximum
#define GOFOOD_REFUND_CUTOFF    80      // % waktu sebelum refund ditolak

// Death system
#define DEATH_TIME              1800 // 30 menit dalam detik
#define DEATH_RESPAWN_HP        25.0 // HP saat respawn di RS
#define REVIVE_DISTANCE         3.0  // Jarak max untuk revive

// Kota
#define CITY_MEKAR_PURA         1 // Los Santos
#define CITY_MADYA_RAYA         2 // Las Venturas
#define CITY_MOJOSONO           3 // San Fierro

// Spawn location types
#define SPAWN_TERMINAL          0
#define SPAWN_BANDARA           1
#define SPAWN_STASIUN           2

// Hunger & Thirst system
#define THIRST_DECREASE_TIME    900000  // 15 menit dalam ms
#define THIRST_DECREASE_AMOUNT  10      // 10% per tick
#define HUNGER_DECREASE_TIME    1800000 // 30 menit dalam ms
#define HUNGER_DECREASE_AMOUNT  15      // 15% per tick
#define THIRST_CANT_RUN         20      // Tidak bisa lari jika <= 20%
#define HUNGER_PINGSAN          10      // Pingsan jika <= 10%

// HUD Bar positions (kanan bawah, di atas chat area)
#define BAR_X_START             548.0
#define BAR_X_END               610.0
#define BAR_WIDTH_HUD           62.0
#define BAR_THIRST_Y            380.0
#define BAR_HUNGER_Y            395.0
#define ICON_X                  527.0
#define ICON_THIRST_Y           376.0
#define ICON_HUNGER_Y           391.0
#define PCT_X                   612.0

// Money HUD (above bars)
#define MONEY_HUD_X             610.0
#define MONEY_HUD_Y             363.0

#define INVALID_PLAYER_TD       (PlayerText:0xFFFF)

// GTA SA Model IDs
#define MODEL_SPRUNK            1546
#define MODEL_BURGER            2703

// Custom phone models (artconfig.txt)
#define MODEL_PHONEFRAME        19800
#define MODEL_PHONEWP           19801
#define MODEL_ICONWA            19802
#define MODEL_ICONTW            19803

// ============================================================================
// INVENTORY SYSTEM
// ============================================================================

#define MAX_KANTONG_SLOTS       5
#define MAX_TAS_SLOTS           15
#define MAX_INVENTORY_SLOTS     20  // 5 + 15
#define TAS_PRICE               1000
#define MAX_ITEM_TYPES          9

// Item Types
#define ITEM_TYPE_NONE          0
#define ITEM_TYPE_FOOD          1
#define ITEM_TYPE_DRINK         2
#define ITEM_TYPE_MEDICAL       3
#define ITEM_TYPE_MISC          4

// Item IDs
#define ITEM_NONE               0
#define ITEM_NASI_BUNGKUS       1
#define ITEM_BURGER_ITEM        2
#define ITEM_AIR_MINERAL        3
#define ITEM_SPRUNK_ITEM        4
#define ITEM_P3K                5
#define ITEM_HANDPHONE          6
#define ITEM_HT_RADIO           7
#define ITEM_FISHING_ROD        8

// HT Radio system
#define MAX_HT_FREQ             999.9
#define MIN_HT_FREQ             100.0
#define HT_RADIO_RANGE          0.0     // global (same freq)
#define COLOR_RADIO             0x8ED1FCFF  // light blue radio color
#define COLOR_RADIO_ACTION      0xC2A2DAFF  // proximity radio action
#define HT_RADIO_TD_COUNT       23
#define DIALOG_HT_SETFREQ       160

// Inventory UI Layout (bottom-center, clear of chat)
#define INV_PANEL_X             170.0
#define INV_PANEL_X_END         470.0
#define INV_SLOT_SIZE           45.0
#define INV_SLOT_GAP            6.0
#define INV_GRID_START_X        196.0
#define INV_PANEL_Y             240.0
#define INV_TITLE_Y             243.0
#define INV_ROW0_Y              260.0
#define INV_TAS_LABEL_Y         310.0
#define INV_ROW1_Y              327.0
#define INV_ROW2_Y              378.0
#define INV_ROW3_Y              429.0
#define INV_INFO_Y_NOTAS        312.0
#define INV_INFO_Y_TAS          484.0
#define INV_BTN_Y_NOTAS         329.0
#define INV_BTN_Y_TAS           501.0
#define INV_PANEL_H_NOTAS       10.5
#define INV_PANEL_H_TAS         29.0

// Inventory UI Colors
#define INV_COLOR_PANEL         0x111111DD
#define INV_COLOR_SLOT_EMPTY    0x333333AA
#define INV_COLOR_SLOT_FILLED   0x444444CC
#define INV_COLOR_SLOT_SELECTED 0xFF8800CC
#define INV_COLOR_BTN           0x555555CC
#define INV_COLOR_BTN_TEXT      0xCCCCCCFF
#define INV_COLOR_TITLE         0xFFAA00FF
#define INV_COLOR_HIGHLIGHT     0xAABBFFFF

// ============================================================================
// PHONE SYSTEM
// ============================================================================

#define PHONE_KEY               KEY_NO  // N key = 131072

// Phone HUD Layout - Slim Android style (9:18 ratio)
// Outer frame (phone body)
#define PHONE_FRAME_X           490.0
#define PHONE_FRAME_Y           60.0
#define PHONE_FRAME_W           120.0
#define PHONE_FRAME_H           280.0
#define PHONE_FRAME_X_END       610.0
// Inner screen area (inset ~4px)
#define PHONE_X                 494.0
#define PHONE_Y                 72.0
#define PHONE_W                 112.0
#define PHONE_H                 256.0
#define PHONE_X_END             606.0
// Status bar
#define PHONE_STATUS_H          12.0
// Nav bar (bottom 3-button area)
#define PHONE_NAV_H             14.0

// In-app content layout
#define MAX_APP_LINES           7
#define PHONE_APP_HDR_Y         84.0
#define PHONE_APP_LINE_START    102.0
#define PHONE_APP_LINE_GAP      22.0
#define PHONE_APP_BTN_Y         262.0

// Phone colors (material dark theme)
#define PHONE_COLOR_FRAME       0x2C2C2CFF
#define PHONE_COLOR_BG          0x121212EE
#define PHONE_COLOR_STATUS      0x000000BB
#define PHONE_COLOR_HEADER      0x1F1F1FFF
#define PHONE_COLOR_WALLPAPER   0x1A237EDD
#define PHONE_COLOR_APP_BG      0x2A2A2ADD
#define PHONE_COLOR_APP_HOVER   0x424242DD
#define PHONE_COLOR_TEXT        0xE0E0E0FF
#define PHONE_COLOR_WHITE       0xFFFFFFFF
#define PHONE_COLOR_ACCENT      0xBB86FCFF
#define PHONE_COLOR_NAV         0x1A1A1AFF
#define PHONE_COLOR_WA          0x25D366FF
#define PHONE_COLOR_TWITTER     0x1DA1F2FF
#define PHONE_COLOR_MARKET      0xFF9800FF
#define PHONE_COLOR_MBANK       0x7C4DFFFF
#define PHONE_COLOR_LINE_BG     0x222222AA
#define PHONE_COLOR_LINE_HL     0x333333CC
#define PHONE_COLOR_GPS         0xF44336FF
#define PHONE_COLOR_SETTINGS    0x607D8BFF
#define PHONE_COLOR_NOTEPAD    0xFFC107FF

// Phone apps
#define PHONE_APP_NONE          0
#define PHONE_APP_WA            1
#define PHONE_APP_TWITTER       2
#define PHONE_APP_MARKET        3
#define PHONE_APP_MBANK         4
#define PHONE_APP_GPS           5
#define PHONE_APP_SETTINGS      6
#define PHONE_APP_NOTEPAD       7

// Phone screen states
#define PHONE_SCREEN_HOME       0
#define PHONE_SCREEN_WA_MAIN    1
#define PHONE_SCREEN_WA_CHAT    2
#define PHONE_SCREEN_TW_MAIN    3
#define PHONE_SCREEN_TW_TL      4
#define PHONE_SCREEN_MK_MAIN    5
#define PHONE_SCREEN_MK_BROWSE  6
#define PHONE_SCREEN_MK_SELL    7
#define PHONE_SCREEN_MK_NPC     8
#define PHONE_SCREEN_MB_MAIN    9
#define PHONE_SCREEN_MB_HISTORY 10
#define PHONE_SCREEN_GPS_MAIN   11
#define PHONE_SCREEN_SETTINGS   12
#define PHONE_SCREEN_NOTEPAD    13
#define PHONE_SCREEN_NOTE_VIEW  14
#define PHONE_SCREEN_TW_REGISTER 15
#define PHONE_SCREEN_TW_DETAIL  16
#define PHONE_SCREEN_MK_GOFOOD  17
#define PHONE_SCREEN_MK_GOFOOD_CART 18

// Kuota system (stored in KB)
#define KUOTA_DEFAULT           1048576   // 1 GB in KB
#define KUOTA_PER_ACTION        20480     // 20 MB per action (msg/tweet/buy)
#define KUOTA_BROWSE_INTERVAL   10000     // 10 seconds
#define KUOTA_BROWSE_AMOUNT     100       // 100 KB per tick (=10 KB/s)

// Phone contacts
#define MAX_CONTACTS            30

// Marketplace
#define MAX_LISTINGS            100
#define LISTING_FEE             50

// M-Banking fee
#define MBANK_FEE_PCT           2  // 2% fee

// ============================================================================
// BANK SYSTEM
// ============================================================================

// Dynamic ATM/Bank (loaded from DB, dev-managed)
#define MAX_ATM_LOCATIONS       20
#define MAX_BANK_LOCATIONS      10
#define ATM_INTERACT_RANGE      2.5
#define BANK_INTERACT_RANGE     2.5
#define ATM_OBJECT_MODEL        2942

// ============================================================================
// DIALOG IDS (phone/bank)
// ============================================================================

#define DIALOG_PHONE_WA_CONTACTS    50
#define DIALOG_PHONE_WA_CHAT        51
#define DIALOG_PHONE_WA_SEND        52
#define DIALOG_PHONE_WA_ADDCONTACT  53
#define DIALOG_PHONE_WA_ADDNUM      54
#define DIALOG_PHONE_TWITTER_MENU   60
#define DIALOG_PHONE_TWITTER_COMPOSE 61
#define DIALOG_PHONE_TWITTER_TL     62
#define DIALOG_PHONE_MARKET_MENU    70
#define DIALOG_PHONE_MARKET_BROWSE  71
#define DIALOG_PHONE_MARKET_SELL    72
#define DIALOG_PHONE_MARKET_PRICE   73
#define DIALOG_PHONE_MARKET_NPC     74
#define DIALOG_GOFOOD_CONFIRM       75
#define DIALOG_GOFOOD_PICKUP        76
#define DIALOG_GOFOOD_CODE          77
#define DIALOG_PHONE_MBANK_MENU     80
#define DIALOG_PHONE_MBANK_DEPOSIT  81
#define DIALOG_PHONE_MBANK_WITHDRAW 82
#define DIALOG_PHONE_MBANK_TRANSFER 83
#define DIALOG_PHONE_MBANK_TRAMT    84
#define DIALOG_PHONE_MBANK_HISTORY  85
#define DIALOG_PHONE_MBANK_KUOTA   86

// Notepad dialogs
#define DIALOG_PHONE_NOTEPAD_TITLE  87
#define DIALOG_PHONE_NOTEPAD_BODY   88

// Twitter registration dialogs
#define DIALOG_PHONE_TW_REG_USER    100
#define DIALOG_PHONE_TW_REG_PASS    101
#define DIALOG_PHONE_TW_LOGIN_USER  102
#define DIALOG_PHONE_TW_LOGIN_PASS  103
#define DIALOG_PHONE_TW_COMPOSE     104
#define DIALOG_PHONE_TW_COMMENT     105

// GPS
#define MAX_GPS_DISTANCE_TDS        2
#define GPS_UPDATE_INTERVAL         1000

// Wallet system
#define MAX_WALLET_SLOTS            6
#define WALLET_CARD_KTP             0
#define WALLET_CARD_BANK            1
#define WALLET_CARD_SIM             2
// Slots 3-5 reserved for future (BPJS, Lisensi Senjata, etc)
#define MAX_CASH                    3000000 // 3 juta max cash

// Wallet dialog IDs
#define DIALOG_WALLET_SHOW_LIST     110
#define DIALOG_WALLET_KTP_VIEW      111
#define DIALOG_WALLET_BANK_VIEW     112
#define DIALOG_WALLET_SIM_VIEW      113

// Auto RP color
#define COLOR_RP                    0xC2A2DAFF

#define DIALOG_BANK_MENU            90
#define DIALOG_BANK_DEPOSIT         91
#define DIALOG_BANK_WITHDRAW        92
#define DIALOG_BANK_TRANSFER        93
#define DIALOG_BANK_TRANSFER_AMT    94
#define DIALOG_BANK_HISTORY         95
#define DIALOG_BANK_CREATE          96
#define DIALOG_INV_GIVE_LIST        97

main(){}

// ============================================================================
// ENUMS
// ============================================================================

enum dZone
{
    zSpawnFAQ,
};

enum pInfo
{
    pID,
    pName[MAX_PLAYER_NAME],
    pICName[MAX_IC_NAME_LEN],
    pICAge,
    pRegDate,
    pRegIP[MAX_IPADRESS_LEN],
    pLastDate,
    pLastIP[MAX_IPADRESS_LEN],
    pRegistered,
    pGender,
    //
    bool:pLogged,
    pLevel,
    pMoney,
    pSkin,
    // Last position
    Float:pLastX,
    Float:pLastY,
    Float:pLastZ,
    Float:pLastAngle,
    pLastInterior,
    pLastVW,
    // Death system
    bool:pIsDead,
    pDeathTick,
    pDeathTimer,
    // Hunger & Thirst
    pHunger,
    pThirst,
    pHungerTimer,
    pThirstTimer,
    bool:pHudCreated,
    // HUD TextDraws
    PlayerText:ptdThirstIcon,
    PlayerText:ptdThirstBG,
    PlayerText:ptdThirstBar,
    PlayerText:ptdThirstPct,
    PlayerText:ptdHungerIcon,
    PlayerText:ptdHungerBG,
    PlayerText:ptdHungerBar,
    PlayerText:ptdHungerPct,
    // Money HUD
    PlayerText:ptdMoneyText,
    // Inventory
    pInvItems[MAX_INVENTORY_SLOTS],
    pInvAmounts[MAX_INVENTORY_SLOTS],
    bool:pHasTas,
    bool:pInvOpen,
    pInvSelected,
    // Phone
    bool:pPhoneOpen,
    pPhoneApp,           // Current open app (PHONE_APP_*)
    pPhoneNumber[12],    // 08xxxxxxxxxx
    pPhoneContacts[MAX_CONTACTS],  // DB IDs of contacts
    pPhoneContactCount,
    // Bank
    pBank,               // Bank balance
    pBankAccount[12],    // 10-digit account number, '' = no account
    // Phone HUD TDs
    PlayerText:ptdPhoneFrame,     // outer phone body
    PlayerText:ptdPhoneBG,        // inner screen bg
    PlayerText:ptdPhoneStatus,    // status bar bg
    PlayerText:ptdPhoneStatusTxt, // status bar text (time, signal, battery)
    PlayerText:ptdPhoneWallpaper, // wallpaper gradient area
    PlayerText:ptdPhoneTitle,     // clock / phone number
    PlayerText:ptdPhoneApp1,      // WA icon box
    PlayerText:ptdPhoneApp1Lbl,   // WA label
    PlayerText:ptdPhoneApp2,      // Twitter icon box
    PlayerText:ptdPhoneApp2Lbl,   // Twitter label
    PlayerText:ptdPhoneApp3,      // Market icon box
    PlayerText:ptdPhoneApp3Lbl,   // Market label
    PlayerText:ptdPhoneApp4,      // M-Bank icon box
    PlayerText:ptdPhoneApp4Lbl,   // M-Bank label
    PlayerText:ptdPhoneApp5,      // GPS icon box
    PlayerText:ptdPhoneApp5Lbl,   // GPS label
    PlayerText:ptdPhoneApp6,      // Settings icon box
    PlayerText:ptdPhoneApp6Lbl,   // Settings label
    PlayerText:ptdPhoneNav,       // bottom nav bar
    PlayerText:ptdPhoneBack,      // back nav button
    PlayerText:ptdPhoneHome,      // home nav button
    PlayerText:ptdPhoneRecent,    // recent nav button
    PlayerText:ptdPhoneSpeaker,   // top speaker detail
    PlayerText:ptdPhoneNotch,     // notch / camera
    // In-app content TDs
    PlayerText:ptdAppHeader,      // app header bar bg
    PlayerText:ptdAppTitle,       // app header title text
    PlayerText:ptdAppScrollUp,    // scroll up arrow
    PlayerText:ptdAppScrollDn,    // scroll down arrow
    PlayerText:ptdAppBtn1,        // action button 1
    PlayerText:ptdAppBtn2,        // action button 2
    // Phone state
    pPhoneScreen,                 // current screen (PHONE_SCREEN_*)
    pPhoneScrollPos,              // scroll offset for lists
    pPhoneChatContact,            // WA chat contact index
    // Kuota
    pKuota,                       // Internet kuota in KB
    pKuotaTimer,                  // Timer for browsing drain
    // Notepad home TDs
    PlayerText:ptdPhoneApp7,      // Notepad icon box
    PlayerText:ptdPhoneApp7Lbl,   // Notepad label
    PlayerText:ptdPhoneApp8,      // Empty slot 8 (future)
    PlayerText:ptdPhoneApp8Lbl,   // Empty slot 8 label
    // Badge TDs (notification count on icon)
    PlayerText:ptdBadge1,
    PlayerText:ptdBadge2,
    // Toast notification TD
    PlayerText:ptdToast,
    pToastTimer,
    // Badge counts
    pBadgeWA,
    pBadgeTW,
    // GPS navigation
    PlayerText:ptdGPSDistance,
    PlayerText:ptdGPSArrow,
    pGPSMapIconID,
    pGPSTimer,
    Float:pGPSTargetX,
    Float:pGPSTargetY,
    Float:pGPSTargetZ,
    pGPSTargetName[32],
    bool:pGPSActive,
    // Twitter account
    pTwitterID,                   // 0 = not registered
    pTwitterUser[24],
    // Notepad
    pNotepadEditID,               // -1 = new note, else note DB id
    pNotepadTempTitle[48],
    // Temp vars for dialogs
    pTempTarget,
    pTempListingSlot,
    pTempTweetID,                 // for viewing tweet detail/commenting
    // Wallet
    bool:pWalletOpen,
    pWalletSelected,              // selected card slot (0-5)
    PlayerText:ptdWalletBG,
    PlayerText:ptdWalletTitle,
    PlayerText:ptdWalletCash,
    PlayerText:ptdWalletSlotBG[6],
    PlayerText:ptdWalletSlotIcon[6],
    PlayerText:ptdWalletSlotLbl[6],
    PlayerText:ptdWalletBtnLihat,
    PlayerText:ptdWalletBtnShow,
    PlayerText:ptdWalletBtnClose,
    PlayerText:ptdWalletInfo,
    pWalletShowTarget,            // target player for 'perlihatkan'
    // AME (action above head)
    Text3D:pAMELabel,
    pAMETimer,
    // Admin
    pAdmin,                       // admin level 0-3 (0=player, 1=management, 2=devmap, 3=developer)
    bool:pMuted,                  // muted by admin
    bool:pFrozen,                 // frozen by admin
    bool:pJailed,                 // jailed by admin
    pJailTimer,                   // jail timer id
    bool:pAdminDuty,              // on admin duty
    bool:pSpecMode,               // spectating
    pSpecTarget,                  // spectate target
    // KTP data
    bool:pHasKTP,                 // has KTP card
    pKTPNIK[16],                  // NIK number
    pKTPFullName[64],             // nama lengkap di KTP
    pBirthPlace[32],              // tempat lahir
    pAddress[64],                 // alamat
    pMaritalStatus[16],           // status perkawinan
    pOccupation[32],              // pekerjaan
    pBloodType[4],                // golongan darah
    // SIM data
    bool:pHasSIMA,                // SIM A (mobil)
    bool:pHasSIMB,                // SIM B (truk/bus)
    bool:pHasSIMC,                // SIM C (motor)
    pSIMNumber[16],               // nomor SIM
    // SIM temp
    pSIMQuizScore,                // quiz score during test
    pSIMQuizQuestion,             // current question index
    pSIMQuizType,                 // type being tested (A/B/C)
    // Go Food cart system
    pGoFoodCart[MAX_GOFOOD_CART],      // item table indices in cart (-1 = empty)
    pGoFoodCartQty[MAX_GOFOOD_CART],   // quantity per cart slot
    pGoFoodCartCount,                  // items in cart
    pGoFoodOrderLocker,                // locker index assigned (-1 = none)
    pGoFoodTimer,                      // delivery timer
    bool:pGoFoodReady,                 // food ready for pickup
    pGoFoodActorID,                    // delivery actor id
    pGoFoodActorTimer,                 // actor visibility check timer
    pGoFoodLockerCode,                 // 4-digit pickup code
    pGoFoodOrderStart,                 // GetTickCount when ordered
    pGoFoodDeliveryTime,               // total delivery time in ms
    bool:pGoFoodMapIconSet,            // map icon showing
    // HT Radio
    bool:pHTActive,                    // radio on/off
    Float:pHTFreq,                     // current frequency (100.0-999.9)
    bool:pHTUIShown,                   // textdraw UI visible
};

enum tInfo
{
    pRegPassword[MAX_PASSWORD_LEN],
    pRegICName[MAX_IC_NAME_LEN],
    pRegICAge,
    pRegGender,
    pRegSkin,
    pRegCity,
    pRegSpawn,
};

// Dialog IDs
enum
{
    dNull,
    //
    dRegister,
    dRegICName,
    dRegICAge,
    dRegGender,
    dRegSkinMale,
    dRegSkinFemale,
    dRegCity,
    dRegSpawn,
    dLogin,
    //
}

// ============================================================================
// GLOBAL VARIABLES
// ============================================================================

new MySQL_C1;
new query[1024];
new RolePlayChat = 1;

new DynamicZone[dZone];
new PlayerInfo[MAX_PLAYERS][pInfo];
new TempInfo[MAX_PLAYERS][tInfo];
new PhoneContactNames[MAX_PLAYERS][MAX_CONTACTS][24];
new PlayerText:PhoneAppLines[MAX_PLAYERS][MAX_APP_LINES];
new TempContactName[MAX_PLAYERS][24];

// ATM data (loaded from DB)
enum eATMData {
    atmDBID,
    Float:atmX,
    Float:atmY,
    Float:atmZ,
    Float:atmRotZ,
    atmObjectID,
    Text3D:atmLabelID,
    atmPickupID
};
new ATMData[MAX_ATM_LOCATIONS][eATMData];
new TotalATMs = 0;

// Bank data (loaded from DB)
enum eBankData {
    bnkDBID,
    bnkName[32],
    Float:bnkX,
    Float:bnkY,
    Float:bnkZ,
    Float:bnkRotZ,
    Text3D:bnkLabelID,
    bnkPickupID
};
new BankData[MAX_BANK_LOCATIONS][eBankData];
new TotalBanks = 0;

// Interior data (loaded from DB)
enum eInteriorData {
    intDBID,
    intName[48],
    Float:intEntryX,
    Float:intEntryY,
    Float:intEntryZ,
    Float:intEntryAngle,
    Float:intExitX,
    Float:intExitY,
    Float:intExitZ,
    Float:intExitAngle,
    intInterior,
    intVW,
    intEntryPickup,
    Text3D:intEntryLabel,
    intExitPickup,
    Text3D:intExitLabel
};
new InteriorData[MAX_INTERIORS][eInteriorData];
new TotalInteriors = 0;

// SIM Station data (loaded from DB)
enum eSIMStation {
    simDBID,
    simName[48],
    Float:simX,
    Float:simY,
    Float:simZ,
    Float:simAngle,
    simInterior,
    simVW,
    simActorID,
    simPickupID,
    Text3D:simLabelID
};
new SIMStationData[MAX_SIM_STATIONS][eSIMStation];
new TotalSIMStations = 0;

// GoFood Locker data (loaded from DB)
enum eLockerData {
    lkDBID,
    lkCity,
    Float:lkX,
    Float:lkY,
    Float:lkZ,
    Float:lkRotZ,
    lkObjectID,
    Text3D:lkLabelID,
    lkOccupied,
    lkOwnerID
};
new LockerData[MAX_GOFOOD_LOCKERS][eLockerData];
new TotalLockers = 0;

// Marketplace listing enum (for DB queries)
enum eMarketListing {
    mlActive,
    mlSellerID,     // account DB id
    mlSellerName[24],
    mlItemID,
    mlAmount,
    mlPrice
};

// Tweets — now fully DB-based (no in-memory cache needed)\n// twitter_accounts + phone_tweets + twitter_comments tables

// ============================================================================
// DATA TABLES
// ============================================================================

// Spawn positions per city per type [Terminal, Bandara, Stasiun]
// Mekar Pura (Los Santos)
new Float:SpawnMekarPura[][4] =
{
    {1710.2136, -1879.4221, 13.5662, 135.0},
    {1642.1328, -2334.7468, 13.5469, 0.0},
    {1757.0731, -1943.8488, 13.5688, 270.0}
};
// Madya Raya (Las Venturas)
new Float:SpawnMadyaRaya[][4] =
{
    {2543.3567, 2077.1234, 10.8203, 0.0},
    {1327.3452, 1484.7231, 10.8203, 270.0},
    {2862.4521, 1290.1342, 11.3906, 90.0}
};
// Mojosono (San Fierro)
new Float:SpawnMojosono[][4] =
{
    {-2033.2345, -116.4562, 35.1719, 180.0},
    {-1429.5123, -290.0342, 14.1484, 315.0},
    {-1949.5674, 164.4213, 27.6875, 90.0}
};

// Hospital locations
new Float:Hospitals[][] =
{
    {2034.0764, -1401.9221, 17.2422, 140.0},   // Mekar Pura - All Saints
    {1183.5107, -1323.0625, 13.5813, 270.0},   // Mekar Pura - County General
    {1607.3848, 1815.9243, 10.8203, 0.0},      // Madya Raya
    {-2655.0542, 640.1834, 14.4531, 180.0}     // Mojosono
};

// GPS Locations
enum eGPSLoc {
    gpsName[32],
    Float:gpsX,
    Float:gpsY,
    Float:gpsZ
};
new const GPSLocations[][eGPSLoc] = {
    {"RS All Saints",       2034.0,  -1401.9, 17.2},
    {"RS County General",   1183.5,  -1323.0, 13.6},
    {"RS Madya Raya",       1607.4,  1815.9,  10.8},
    {"RS Mojosono",        -2655.0,  640.2,   14.5},
    {"Polisi Mekar Pura",   1553.6, -1675.6,  16.2}
};

// Male skins
new MaleSkins[] = {1, 2, 3, 4, 6, 7, 14, 15, 17, 18, 19, 20, 21, 22, 23, 26, 28, 29, 30, 32};
// Female skins
new FemaleSkins[] = {9, 10, 11, 12, 13, 31, 38, 39, 40, 41, 52, 54, 55, 56, 65, 69, 76, 91, 93, 141};

// ============================================================================
// ITEM DATA TABLE
// ============================================================================
// { ItemID, "Name", ModelID, Type, MaxStack, EffectValue }
enum eItemData {
    itmID,
    itmName[24],
    itmModel,
    itmType,
    itmMaxStack,
    itmValue
};

new const ItemTable[][eItemData] = {
    {ITEM_NONE,         "Kosong",       0,    ITEM_TYPE_NONE,    0,  0},
    {ITEM_NASI_BUNGKUS, "Nasi Bungkus", 2768, ITEM_TYPE_FOOD,    5,  30},
    {ITEM_BURGER_ITEM,  "Burger",       2703, ITEM_TYPE_FOOD,    5,  25},
    {ITEM_AIR_MINERAL,  "Air Mineral",  1484, ITEM_TYPE_DRINK,   5,  30},
    {ITEM_SPRUNK_ITEM,  "Sprunk",       1546, ITEM_TYPE_DRINK,   5,  25},
    {ITEM_P3K,          "Kotak P3K",    1580, ITEM_TYPE_MEDICAL, 3,  25},
    {ITEM_HANDPHONE,    "Handphone",    330,  ITEM_TYPE_MISC,    1,  0},
    {ITEM_HT_RADIO,     "HT Radio",    18865,ITEM_TYPE_MISC,    1,  0},
    {ITEM_FISHING_ROD,  "Pancing",      18632,ITEM_TYPE_MISC,    1,  0}
};
