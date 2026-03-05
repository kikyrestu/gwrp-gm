// Westfield RolePlay Gamemode
// Modular structure with #include based components
// open.mp compatible

// ============================================================================
// LIBRARY INCLUDES
// ============================================================================

#include <a_samp>
#include <streamer>
#include <a_mysql>
#include <zcmd>
#define SSCANF_NO_NICE_FEATURES
#include <sscanf2>
#include <colors>

// ============================================================================
// MODULE INCLUDES
// ============================================================================

#include "modules/defines.pwn"
#include "modules/utils.pwn"
#include "modules/database.pwn"
#include "modules/hud.pwn"
#include "modules/spawn.pwn"
#include "modules/hunger.pwn"
#include "modules/account.pwn"
#include "modules/inventory.pwn"
#include "modules/phone.pwn"
#include "modules/phone_wa.pwn"
#include "modules/phone_twitter.pwn"
#include "modules/phone_market.pwn"
#include "modules/bank.pwn"
#include "modules/phone_bank.pwn"
#include "modules/phone_gps.pwn"
#include "modules/phone_settings.pwn"
#include "modules/phone_notepad.pwn"
#include "modules/phone_call.pwn"
#include "modules/wallet.pwn"
#include "modules/admin.pwn"
#include "modules/flymode.pwn"
#include "modules/ktp_service.pwn"
#include "modules/interiors.pwn"
#include "modules/sim_service.pwn"
#include "modules/gofood.pwn"
#include "modules/factions.pwn"
#include "modules/jobs.pwn"
#include "modules/property.pwn"
#include "modules/locations.pwn"
#include "modules/ht_radio.pwn"
#include "modules/hospital_mapping.pwn"
#include "modules/commands.pwn"

// Stack+heap safety — MUST be after all includes to ensure final value
#pragma dynamic 65536

// ============================================================================
// GAMEMODE INIT / EXIT
// ============================================================================

public OnGameModeInit()
{
    new launchtime = GetTickCount();
    MySQLConnect();

    if(mysql_errno())
    {
        SendRconCommand("hostname "GAMEMODE_HOSTNAME" | *error*");
        SetGameModeText(""GAMEMODE_NAME" | *error*");
        return MysqlErrorMessage(INVALID_PLAYER_ID);
    }
    else
    {
        SendRconCommand("hostname "GAMEMODE_HOSTNAME"");
        SetGameModeText(""GAMEMODE_NAME"");
        mysql_log(MYSQL_LOG_TYPE);

        EnableStuntBonusForAll(0);
        ShowPlayerMarkers(2);
        ShowNameTags(0);
        DisableInteriorEnterExits();

        AddPlayerClass(0, 0.0, 0.0, 4.0, 0.0, -1, -1, -1, -1, -1, -1);

        // Init bank system (load from DB)
        LoadATMLocations();
        LoadBankLocations();

        // Load tweets module
        LoadTweetsOnInit();

        // WIB Day/Night Cycle — sync world time every 60 seconds
        SetTimer("OnWIBTimeSync", 60000, true);
        // Set initial time
        new hour, minute, second;
        gettime(hour, minute, second);
        SetWorldTime(hour);

        CreatePickup(1239, 23, 1757.0731,-1943.8488,13.5688, -1);
        DynamicZone[zSpawnFAQ] = CreateDynamicSphere(1757.0731,-1943.8488,13.5688,0.8,0,0,-1);
        Create3DTextLabel("Informasi Awal", 0xFF9900FF, 1757.0731,-1943.8488,14.2, 25.0, 0);
        Create3DTextLabel("_____________________", 0xFF9900FF, 1757.0731,-1943.8488,14.17, 25.0, 0);

        printf("-> Gamemode ("GAMEMODE_NAME") successfully launched! (%d ms)", GetTickCount() - launchtime);

        // Load dynamic locations
        LoadLocations();

        // Load Mall Pelayanan from DB
        LoadMallPelayanan();

        // Load interiors from DB
        LoadInteriors();

        // Load SIM stations from DB
        LoadSIMStations();

        // Load Go Food lockers from DB
        LoadGoFoodLockers();

        // Hospital County General mapping (by Arnathz)
        CreateHospitalMapping();

        // Load factions from DB
        LoadFactions();

        // Load job system data
        LoadTruckerCompanies();
        LoadTruckerRoutes();
        LoadFishMarkets();

        // Fish price fluctuation every 30 minutes
        SetTimer("OnFishPriceFluctuate", 1800000, true);

        // Load properties from DB
        LoadProperties();

        // HT Radio global TextDraws
        CreateHTRadioTextDraws();
    }
    return true;
}

public OnGameModeExit()
{
    return true;
}

// ============================================================================
// PLAYER CONNECT / DISCONNECT
// ============================================================================

public OnPlayerConnect(playerid)
{
    ResetFlyData(playerid);
    ResetPlayerInfo(playerid);
    ResetInventoryTDs(playerid);
    ResetPhoneTDs(playerid);
    ResetWalletTDs(playerid);
    GetPlayerName(playerid, PlayerInfo[playerid][pName], MAX_PLAYER_NAME);

    // Reset phone call data
    ResetCallData(playerid);

    // Reset faction data (runtime)
    ResetPlayerFaction(playerid);

    // Reset job data
    ResetPlayerJobData(playerid);

    // Reset property data
    pCurrentProperty[playerid] = -1;
    pOwnedPropertyID[playerid] = 0;

    // Reset mall pelayanan tracking
    pInsideMall[playerid] = -1;

    // Reset HT Radio
    ResetHTRadio(playerid);

    // Hospital mapping removals (by Arnathz)
    LoadHospitalRemoveBuildings(playerid);

    // Remove breakable street objects (poles, lampposts, traffic lights, hydrants, etc.)
    // They will be invisible — GTA:SA has no way to make map objects truly indestructible
    // Common breakable pole/lamppost models
    RemoveBuildingForPlayer(playerid, 615, 0.0, 0.0, 0.0, 6000.0);   // pole_streetlight01
    RemoveBuildingForPlayer(playerid, 616, 0.0, 0.0, 0.0, 6000.0);   // pole_streetlight02
    RemoveBuildingForPlayer(playerid, 617, 0.0, 0.0, 0.0, 6000.0);   // pole_streetlight03
    RemoveBuildingForPlayer(playerid, 618, 0.0, 0.0, 0.0, 6000.0);   // pole_streetlight04
    RemoveBuildingForPlayer(playerid, 619, 0.0, 0.0, 0.0, 6000.0);   // pole_streetlight05
    RemoveBuildingForPlayer(playerid, 620, 0.0, 0.0, 0.0, 6000.0);   // pole_streetlight06
    RemoveBuildingForPlayer(playerid, 625, 0.0, 0.0, 0.0, 6000.0);   // streetlamp1
    RemoveBuildingForPlayer(playerid, 626, 0.0, 0.0, 0.0, 6000.0);   // streetlamp2
    RemoveBuildingForPlayer(playerid, 627, 0.0, 0.0, 0.0, 6000.0);   // lamppost1
    RemoveBuildingForPlayer(playerid, 628, 0.0, 0.0, 0.0, 6000.0);   // lamppost2
    RemoveBuildingForPlayer(playerid, 629, 0.0, 0.0, 0.0, 6000.0);   // lamppost3
    RemoveBuildingForPlayer(playerid, 631, 0.0, 0.0, 0.0, 6000.0);   // lamppost4
    RemoveBuildingForPlayer(playerid, 632, 0.0, 0.0, 0.0, 6000.0);   // lamppost5

    // Traffic lights
    RemoveBuildingForPlayer(playerid, 1315, 0.0, 0.0, 0.0, 6000.0);  // trafficlight1
    RemoveBuildingForPlayer(playerid, 1316, 0.0, 0.0, 0.0, 6000.0);  // trafficlight2
    RemoveBuildingForPlayer(playerid, 1317, 0.0, 0.0, 0.0, 6000.0);  // trafficlight3
    RemoveBuildingForPlayer(playerid, 1318, 0.0, 0.0, 0.0, 6000.0);  // trafficlight4

    // Additional breakable lampposts and street lights
    RemoveBuildingForPlayer(playerid, 1226, 0.0, 0.0, 0.0, 6000.0);  // lamppost_tall
    RemoveBuildingForPlayer(playerid, 3745, 0.0, 0.0, 0.0, 6000.0);  // vgs_lamppost
    RemoveBuildingForPlayer(playerid, 3637, 0.0, 0.0, 0.0, 6000.0);  // lamppost_la

    // Fire hydrants & parking meters
    RemoveBuildingForPlayer(playerid, 1285, 0.0, 0.0, 0.0, 6000.0);  // fire_hydrant
    RemoveBuildingForPlayer(playerid, 1270, 0.0, 0.0, 0.0, 6000.0);  // parkingmeter1
    RemoveBuildingForPlayer(playerid, 1271, 0.0, 0.0, 0.0, 6000.0);  // parkingmeter2

    // Breakable barriers/fences
    RemoveBuildingForPlayer(playerid, 978, 0.0, 0.0, 0.0, 6000.0);   // barrier_1
    RemoveBuildingForPlayer(playerid, 979, 0.0, 0.0, 0.0, 6000.0);   // barrier_2
    RemoveBuildingForPlayer(playerid, 980, 0.0, 0.0, 0.0, 6000.0);   // barrier_3
    RemoveBuildingForPlayer(playerid, 981, 0.0, 0.0, 0.0, 6000.0);   // barrier_4
    RemoveBuildingForPlayer(playerid, 3578, 0.0, 0.0, 0.0, 6000.0);  // barrier_toll

    SetTimerEx("OnPlayerJoin", 150, false, "d", playerid);
    return true;
}

publics: OnPlayerJoin(playerid)
{
    PlayerClearChat(playerid, 50);
    SendClientFormattedMessage(playerid, -1, "Selamat datang di server - {FF6600}Westfield RolePlay");

    // Check if player is banned
    CheckPlayerBan(playerid);

    mysql_format(MySQL_C1, query, sizeof(query), "SELECT `name` FROM `"TABLE_ACCOUNTS"` WHERE `name` = '%e'", PlayerName(playerid));
    mysql_function_query(MySQL_C1, query, true, "PlayerCheckRegister", "d", playerid);

    if(mysql_errno()) return MysqlErrorMessage(playerid);
    return true;
}

public OnPlayerDisconnect(playerid, reason)
{
    // Cancel fly mode if active (restore saved pos before saving)
    if(FlyData[playerid][flyCamMode] == FLY_CAM_FLY)
        StopFlyMode(playerid);

    if(PlayerInfo[playerid][pLogged] == true)
    {
        // Save last position
        new Float:x, Float:y, Float:z, Float:angle;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, angle);
        PlayerInfo[playerid][pLastX] = x;
        PlayerInfo[playerid][pLastY] = y;
        PlayerInfo[playerid][pLastZ] = z;
        PlayerInfo[playerid][pLastAngle] = angle;
        PlayerInfo[playerid][pLastInterior] = GetPlayerInterior(playerid);
        PlayerInfo[playerid][pLastVW] = GetPlayerVirtualWorld(playerid);

        // Kill death timer if active
        if(PlayerInfo[playerid][pDeathTimer] != 0)
        {
            KillTimer(PlayerInfo[playerid][pDeathTimer]);
            PlayerInfo[playerid][pDeathTimer] = 0;
        }

        // Kill hunger/thirst timers
        if(PlayerInfo[playerid][pHungerTimer] != 0)
        {
            KillTimer(PlayerInfo[playerid][pHungerTimer]);
            PlayerInfo[playerid][pHungerTimer] = 0;
        }
        if(PlayerInfo[playerid][pThirstTimer] != 0)
        {
            KillTimer(PlayerInfo[playerid][pThirstTimer]);
            PlayerInfo[playerid][pThirstTimer] = 0;
        }

        // Close inventory if open
        CloseInventory(playerid);

        // Stop GPS tracking if active (before ClosePhone)
        if(PlayerInfo[playerid][pGPSActive]) StopGPSTracking(playerid);

        // Close phone if open
        ClosePhone(playerid);

        // End phone call if active
        HandleCallDisconnect(playerid);

        // Close wallet if open
        CloseWallet(playerid);

        // Stop spectating if active
        if(PlayerInfo[playerid][pSpecMode])
        {
            TogglePlayerSpectating(playerid, 0);
            PlayerInfo[playerid][pSpecMode] = false;
            PlayerInfo[playerid][pSpecTarget] = INVALID_PLAYER_ID;
        }

        // Kill jail timer if active
        if(PlayerInfo[playerid][pJailTimer] != 0)
        {
            KillTimer(PlayerInfo[playerid][pJailTimer]);
            PlayerInfo[playerid][pJailTimer] = 0;
        }

        // Destroy AME label if exists
        if(PlayerInfo[playerid][pAMETimer] != 0)
        {
            KillTimer(PlayerInfo[playerid][pAMETimer]);
            PlayerInfo[playerid][pAMETimer] = 0;
        }
        if(PlayerInfo[playerid][pAMELabel] != Text3D:INVALID_3DTEXT_ID)
        {
            Delete3DTextLabel(PlayerInfo[playerid][pAMELabel]);
            PlayerInfo[playerid][pAMELabel] = Text3D:INVALID_3DTEXT_ID;
        }

        // Save faction data & end duty on disconnect
        if(pFactionID[playerid] > 0)
        {
            EndDuty(playerid, false);
            SavePlayerFactionData(playerid);
        }

        // Handle job disconnect (stop activity, save)
        HandleJobDisconnect(playerid);

        // Reset property data on disconnect
        pCurrentProperty[playerid] = -1;

        // Reset mall pelayanan + remove from queue
        if(pInsideMall[playerid] >= 0)
            pInsideMall[playerid] = -1;
        RemoveFromKTPQueue(playerid);

        // Kill GoFood actor timer if active
        if(PlayerInfo[playerid][pGoFoodActorTimer] != 0)
        {
            KillTimer(PlayerInfo[playerid][pGoFoodActorTimer]);
            PlayerInfo[playerid][pGoFoodActorTimer] = 0;
        }

        // Hide HT Radio UI
        HideHTRadioUI(playerid);

        // Destroy HUD
        DestroyHungerThirstHUD(playerid);

        PlayerSaveData(playerid);
    }
    return true;
}

public OnPlayerRequestClass(playerid, classid)
{
    return 1;
}

// ============================================================================
// PLAYER SPAWN
// ============================================================================

public OnPlayerSpawn(playerid)
{
    if(!PlayerInfo[playerid][pLogged]) return SendClientFormattedMessage(playerid,-1,"Kamu harus login terlebih dahulu!"),PlayerKick(playerid);

    // Skin is already set via SetSpawnInfo — do NOT call SetPlayerSkin here (causes freeze)
    SetPlayerScore(playerid, PlayerInfo[playerid][pLevel]);
    ResetPlayerMoney(playerid); // Hide default $ HUD, we use Rp TextDraw

    // Spawn at last saved position (SetSpawnInfo already positions, but ensure interior/VW)
    if(PlayerInfo[playerid][pLastX] != 0.0 || PlayerInfo[playerid][pLastY] != 0.0)
    {
        SetPlayerInterior(playerid, PlayerInfo[playerid][pLastInterior]);
        SetPlayerVirtualWorld(playerid, PlayerInfo[playerid][pLastVW]);
    }

    SetCameraBehindPlayer(playerid);

    // If player was dead/pingsan, restore death state
    if(PlayerInfo[playerid][pIsDead])
    {
        SetPlayerDeathState(playerid);
    }
    else
    {
        // Ensure player is controllable after spawn (fixes class selection freeze)
        TogglePlayerControllable(playerid, 1);
    }

    // Create hunger/thirst HUD and start timers
    CreateHungerThirstHUD(playerid);
    StartHungerThirstTimers(playerid);

    // Notify new player about KTP
    NotifyNewPlayerKTP(playerid);

    return true;
}

// ============================================================================
// DEATH CALLBACK -> delegates to spawn module
// ============================================================================

public OnPlayerDeath(playerid, killerid, reason)
{
    return HandlePlayerDeath(playerid, killerid, reason);
}

// ============================================================================
// KEY STATE -> Revive system
// ============================================================================

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    // KEY_SECONDARY_ATTACK (F) to enter/exit interiors, pickup go food, or revive
    if((newkeys & KEY_SECONDARY_ATTACK) && !(oldkeys & KEY_SECONDARY_ATTACK))
    {
        if(!HandleMallKeyPress(playerid))
            if(!HandleInteriorKeyPress(playerid))
                if(!HandleGoFoodPickup(playerid))
                    HandleReviveKey(playerid);
    }

    // KEY_YES (Y) — if LEFT ALT held -> wallet, else -> inventory
    if((newkeys & KEY_YES) && !(oldkeys & KEY_YES))
    {
        new keys, ud, lr;
        GetPlayerKeys(playerid, keys, ud, lr);
        if(keys & KEY_WALK) // Left Alt held
            HandleWalletKey(playerid, newkeys, oldkeys);
        else
            HandleInventoryKey(playerid);
    }

    // KEY_NO (N) to toggle phone
    if((newkeys & KEY_NO) && !(oldkeys & KEY_NO))
    {
        HandlePhoneKey(playerid);
    }
    return true;
}

// ============================================================================
// DYNAMIC AREA
// ============================================================================

public OnPlayerEnterDynamicArea(playerid, areaid)
{
    if(areaid == DynamicZone[zSpawnFAQ]) return ShowPlayerDialog(playerid,dNull,DIALOG_STYLE_MSGBOX,"Informasi Awal","Informasi awal mengenai fitur server..\n...\n...\n...","Tutup","");
    return true;
}

// ============================================================================
// COMMANDS HANDLER
// ============================================================================

public OnPlayerCommandReceived(playerid, cmdtext[])
{
    if(!PlayerInfo[playerid][pLogged]) { SendClientFormattedMessage(playerid, -1,"* Kamu harus login terlebih dahulu!"); return false; }
    // Allow /heal even when dead (developer self-heal)
    if(PlayerInfo[playerid][pIsDead] && strcmp(cmdtext, "/heal", true) != 0) { SendClientFormattedMessage(playerid, COLOR_RED,"* Kamu sedang pingsan!"); return false; }
    return true;
}

public OnPlayerCommandPerformed(playerid, cmdtext[], success)
{
    if(success == -1)
    {
        return SendClientFormattedMessage(playerid, -1, "Error! Perintah tidak ditemukan!");
    }
    printf("Pemain %s baru saja menggunakan perintah \"%s\"", PlayerName(playerid), cmdtext);
    return true;
}

public OnPlayerCommandText(playerid, cmdtext[]) return true;

// ============================================================================
// DIALOG RESPONSE
// ============================================================================

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch(dialogid)
    {
        case dRegister:
        {
            if(!response) return SendClientFormattedMessage(playerid, -1, "Kamu membatalkan registrasi."),PlayerKick(playerid);
            if(!strlen(inputtext) || strlen(inputtext) < 3 || strlen(inputtext) > MAX_PASSWORD_LEN)
            {
                SendClientFormattedMessage(playerid, -1, "Panjang password harus antara 3 hingga 36 karakter!");
                return ShowPlayerDialog(playerid, dRegister, DIALOG_STYLE_PASSWORD, "{FFFFFF}Registrasi","{FFFFFF}Akun {8B0000}belum terdaftar{FFFFFF}, masukkan password kamu:","Lanjut","Batal");
            }
            strmid(TempInfo[playerid][pRegPassword], inputtext, 0, strlen(inputtext), MAX_PASSWORD_LEN);
            ShowPlayerDialog(playerid, dRegICName, DIALOG_STYLE_INPUT, "{FFFFFF}Registrasi - Nama IC","{FFFFFF}Masukkan nama depan karakter kamu (In-Character):","Lanjut","Batal");
            return true;
        }
        case dRegICName:
        {
            if(!response) return SendClientFormattedMessage(playerid, -1, "Kamu membatalkan registrasi."),PlayerKick(playerid);
            if(!strlen(inputtext) || strlen(inputtext) < 2 || strlen(inputtext) > MAX_IC_NAME_LEN)
            {
                SendClientFormattedMessage(playerid, -1, "Nama IC harus 2-32 karakter!");
                return ShowPlayerDialog(playerid, dRegICName, DIALOG_STYLE_INPUT, "{FFFFFF}Registrasi - Nama IC","{FFFFFF}Masukkan nama depan karakter kamu (In-Character):","Lanjut","Batal");
            }
            strmid(TempInfo[playerid][pRegICName], inputtext, 0, strlen(inputtext), MAX_IC_NAME_LEN);
            ShowPlayerDialog(playerid, dRegICAge, DIALOG_STYLE_INPUT, "{FFFFFF}Registrasi - Umur IC","{FFFFFF}Masukkan umur karakter kamu (18 - 24):","Lanjut","Batal");
            return true;
        }
        case dRegICAge:
        {
            if(!response) return SendClientFormattedMessage(playerid, -1, "Kamu membatalkan registrasi."),PlayerKick(playerid);
            new age = strval(inputtext);
            if(age < 18 || age > 24)
            {
                SendClientFormattedMessage(playerid, -1, "Umur harus antara 18 - 24 tahun!");
                return ShowPlayerDialog(playerid, dRegICAge, DIALOG_STYLE_INPUT, "{FFFFFF}Registrasi - Umur IC","{FFFFFF}Masukkan umur karakter kamu (18 - 24):","Lanjut","Batal");
            }
            TempInfo[playerid][pRegICAge] = age;
            ShowPlayerDialog(playerid, dRegGender, DIALOG_STYLE_LIST, "{FFFFFF}Registrasi - Jenis Kelamin","Laki-laki\nPerempuan","Pilih","Batal");
            return true;
        }
        case dRegGender:
        {
            if(!response) return SendClientFormattedMessage(playerid, -1, "Kamu membatalkan registrasi."),PlayerKick(playerid);
            switch(listitem)
            {
                case 0: TempInfo[playerid][pRegGender] = 1;
                case 1: TempInfo[playerid][pRegGender] = 2;
                default: TempInfo[playerid][pRegGender] = 1;
            }
            if(TempInfo[playerid][pRegGender] == 1) ShowMaleSkinDialog(playerid);
            else ShowFemaleSkinDialog(playerid);
            return true;
        }
        case dRegSkinMale:
        {
            if(!response) return SendClientFormattedMessage(playerid, -1, "Kamu membatalkan registrasi."),PlayerKick(playerid);
            if(listitem >= 0 && listitem < sizeof(MaleSkins))
                TempInfo[playerid][pRegSkin] = MaleSkins[listitem];
            else
                TempInfo[playerid][pRegSkin] = MaleSkins[0];
            ShowCityDialog(playerid);
            return true;
        }
        case dRegSkinFemale:
        {
            if(!response) return SendClientFormattedMessage(playerid, -1, "Kamu membatalkan registrasi."),PlayerKick(playerid);
            if(listitem >= 0 && listitem < sizeof(FemaleSkins))
                TempInfo[playerid][pRegSkin] = FemaleSkins[listitem];
            else
                TempInfo[playerid][pRegSkin] = FemaleSkins[0];
            ShowCityDialog(playerid);
            return true;
        }
        case dRegCity:
        {
            if(!response) return SendClientFormattedMessage(playerid, -1, "Kamu membatalkan registrasi."),PlayerKick(playerid);
            switch(listitem)
            {
                case 0: TempInfo[playerid][pRegCity] = CITY_MEKAR_PURA;
                case 1: TempInfo[playerid][pRegCity] = CITY_MADYA_RAYA;
                case 2: TempInfo[playerid][pRegCity] = CITY_MOJOSONO;
                default: TempInfo[playerid][pRegCity] = CITY_MEKAR_PURA;
            }
            ShowSpawnLocationDialog(playerid);
            return true;
        }
        case dRegSpawn:
        {
            if(!response) { ShowCityDialog(playerid); return true; }
            switch(listitem)
            {
                case 0: TempInfo[playerid][pRegSpawn] = SPAWN_TERMINAL;
                case 1: TempInfo[playerid][pRegSpawn] = SPAWN_BANDARA;
                case 2: TempInfo[playerid][pRegSpawn] = SPAWN_STASIUN;
                default: TempInfo[playerid][pRegSpawn] = SPAWN_TERMINAL;
            }
            PlayerCreateAccount(playerid);
            return true;
        }
        case dLogin:
        {
            if(!response) return SendClientFormattedMessage(playerid, -1, "Kamu membatalkan login."),PlayerKick(playerid);
            if(!strlen(inputtext) || strlen(inputtext) < 3 || strlen(inputtext) > MAX_PASSWORD_LEN)
            {
                SendClientFormattedMessage(playerid, -1, "Panjang password harus antara 3 hingga 36 karakter!");
                return ShowPlayerDialog(playerid, dLogin, DIALOG_STYLE_PASSWORD, "{FFFFFF}Login","{FFFFFF}Akun {006400}sudah terdaftar{FFFFFF}, masukkan password kamu:","Lanjut","Batal");
            }
            mysql_format(MySQL_C1, query, sizeof(query), "SELECT * FROM `"TABLE_ACCOUNTS"` WHERE `name` = '%e' AND `password` = MD5('%e') LIMIT 0,1", PlayerName(playerid), inputtext);
            mysql_function_query(MySQL_C1, query, true, "PlayerLogin", "d", playerid);

            if(mysql_errno()) return MysqlErrorMessage(playerid);
            return true;
        }

        // ---- Phone: WhatsApp (text input dialogs only) ----
        case DIALOG_PHONE_WA_SEND: return HandleWASendResponse(playerid, response, inputtext);
        case DIALOG_PHONE_WA_ADDCONTACT: return HandleAddContactResponse(playerid, response, inputtext);
        case DIALOG_PHONE_WA_ADDNUM: return HandleAddByNumberResponse(playerid, response, inputtext);

        // ---- Phone: Twitter ----
        case DIALOG_PHONE_TW_REG_USER: return HandleTWRegUserResponse(playerid, response, inputtext);
        case DIALOG_PHONE_TW_REG_PASS: return HandleTWRegPassResponse(playerid, response, inputtext);
        case DIALOG_PHONE_TW_LOGIN_USER: return HandleTWLoginUserResponse(playerid, response, inputtext);
        case DIALOG_PHONE_TW_LOGIN_PASS: return HandleTWLoginPassResponse(playerid, response, inputtext);
        case DIALOG_PHONE_TW_COMPOSE: return HandleTwitterComposeResponse(playerid, response, inputtext);
        case DIALOG_PHONE_TW_COMMENT: return HandleTWCommentResponse(playerid, response, inputtext);

        // ---- Phone: Notepad ----
        case DIALOG_PHONE_NOTEPAD_TITLE: return HandleNotepadTitleResponse(playerid, response, inputtext);
        case DIALOG_PHONE_NOTEPAD_BODY: return HandleNotepadBodyResponse(playerid, response, inputtext);

        // ---- Phone: Marketplace (price input only) ----
        case DIALOG_PHONE_MARKET_PRICE: return HandleMarketPriceResponse(playerid, response, inputtext);

        // ---- Go Food ----
        case DIALOG_GOFOOD_CONFIRM: return HandleGoFoodConfirmDialog(playerid, response);
        case DIALOG_GOFOOD_CODE: return HandleGoFoodCodeDialog(playerid, response, inputtext);

        // ---- Phone: M-Banking (amount/transfer input only) ----
        case DIALOG_PHONE_MBANK_DEPOSIT: return HandleMBankDepositResponse(playerid, response, inputtext);
        case DIALOG_PHONE_MBANK_WITHDRAW: return HandleMBankWithdrawResponse(playerid, response, inputtext);
        case DIALOG_PHONE_MBANK_TRANSFER: return HandleMBankTransferResponse(playerid, response, inputtext);
        case DIALOG_PHONE_MBANK_TRAMT: return HandleMBankTransferAmtResponse(playerid, response, inputtext);
        case DIALOG_PHONE_MBANK_KUOTA: return HandleMBankKuotaResponse(playerid, response, listitem);
        case DIALOG_PHONE_MBANK_HISTORY:
        {
            // History shown as dialog, return to M-Bank menu
            if(PlayerInfo[playerid][pPhoneOpen]) { OpenPhoneMBank(playerid); SelectTextDraw(playerid, PHONE_COLOR_ACCENT); }
            return 1;
        }

        // ---- ATM / Bank ----
        case DIALOG_BANK_MENU: return HandleATMMenuResponse(playerid, response, listitem);
        case DIALOG_BANK_DEPOSIT: return HandleATMDepositResponse(playerid, response, inputtext);
        case DIALOG_BANK_WITHDRAW: return HandleATMWithdrawResponse(playerid, response, inputtext);
        case DIALOG_BANK_TRANSFER: return HandleATMTransferResponse(playerid, response, inputtext);
        case DIALOG_BANK_TRANSFER_AMT: return HandleATMTransferAmtResponse(playerid, response, inputtext);
        case DIALOG_BANK_HISTORY: { return true; } // just close
        case DIALOG_BANK_CREATE: return HandleBankCreateResponse(playerid, response);

        // ---- Inventory: Give item player list ----
        case DIALOG_INV_GIVE_LIST:
        {
            if(!response) return SendClientFormattedMessage(playerid, -1, "Batal memberikan item.");
            return ProcessGiveItem(playerid, listitem);
        }

        // ---- Wallet: Show card to player list ----
        case DIALOG_WALLET_SHOW_LIST: return HandleWalletShowResponse(playerid, response, listitem);
        case DIALOG_WALLET_KTP_VIEW, DIALOG_WALLET_BANK_VIEW, DIALOG_WALLET_SIM_VIEW: return 1; // just close
    }

    // Location dialogs (handled outside switch)
    if(HandleLocationDialogs(playerid, dialogid, response, listitem, inputtext)) return 1;

    // KTP service dialogs
    if(HandleKTPDialogs(playerid, dialogid, response, listitem, inputtext)) return 1;

    // SIM service dialogs
    if(HandleSIMDialogs(playerid, dialogid, response, listitem, inputtext)) return 1;

    // Job dialogs
    if(HandleJobDialogs(playerid, dialogid, response, listitem)) return 1;

    // Property dialogs
    if(HandlePropertyDialogs(playerid, dialogid, response, listitem, inputtext)) return 1;

    return 1;
}

// ============================================================================
// PLAYER UPDATE
// ============================================================================

public OnPlayerUpdate(playerid)
{
    // Fly mode intercept (skips normal processing while flying)
    if(FlyData[playerid][flyCamMode] == FLY_CAM_FLY)
        return ProcessFlyMode(playerid);

    PlayerUpdateMoney(playerid);

    // Sprint restriction when thirst <= 20%
    if(PlayerInfo[playerid][pLogged] && !PlayerInfo[playerid][pIsDead] && PlayerInfo[playerid][pThirst] <= THIRST_CANT_RUN)
    {
        if(!IsPlayerInAnyVehicle(playerid))
        {
            new keys, ud, lr;
            GetPlayerKeys(playerid, keys, ud, lr);
            if(keys & KEY_SPRINT) // only block sprinting, allow normal walk/jog
            {
                new Float:vx, Float:vy, Float:vz;
                GetPlayerVelocity(playerid, vx, vy, vz);
                new Float:speed = floatsqroot(vx*vx + vy*vy);
                if(speed > 0.035) // above jog speed
                {
                    new Float:factor = 0.035 / speed;
                    SetPlayerVelocity(playerid, vx * factor, vy * factor, vz);
                }
            }
        }
    }
    return 1;
}

// ============================================================================
// CHECKPOINT
// ============================================================================

public OnPlayerEnterCheckpoint(playerid)
{
    if(PlayerInfo[playerid][pGPSActive])
    {
        HandleGPSCheckpointReached(playerid);
        return 1;
    }
    // Job checkpoints (trucker, bus)
    if(HandleJobCheckpoint(playerid)) return 1;
    return 1;
}

// ============================================================================
// WIB TIME SYNC
// ============================================================================

publics: OnWIBTimeSync()
{
    new hour, minute, second;
    gettime(hour, minute, second);
    SetWorldTime(hour);
    return 1;
}

// ============================================================================
// CHAT
// ============================================================================

// TextDraw click callbacks for inventory
public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
    if(HandleInventoryClick(playerid, playertextid)) return 1;
    if(HandlePhoneClick(playerid, playertextid)) return 1;
    if(HandleWalletClick(playerid, playertextid)) return 1;
    return 0;
}

public OnPlayerClickTextDraw(playerid, Text:clickedid)
{
    // ESC pressed while SelectTextDraw is active
    if(clickedid == Text:INVALID_TEXT_DRAW)
    {
        HandlePhoneEsc(playerid);
        HandleInventoryEsc(playerid);
        HandleWalletEsc(playerid);
        return 1;
    }
    return 0;
}

public OnPlayerText(playerid, text[])
{
    if(!PlayerInfo[playerid][pLogged]) return SendClientFormattedMessage(playerid, -1, "Kamu harus login terlebih dahulu!"), false;
    if(PlayerInfo[playerid][pIsDead]) return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu sedang pingsan, tidak bisa bicara!"), false;
    if(PlayerInfo[playerid][pMuted]) return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu sedang di-mute! Tidak bisa berbicara."), false;

    // Phone call intercept — if in active call, route chat to phone
    if(HandleCallChat(playerid, text)) return false;

    new chattext[MAX_CHATMESS_LEN];
    if(RolePlayChat)
    {
        if(strlen(text) < 1 || strlen(text) > MAX_CHATMESS_LEN) return SendClientFormattedMessage(playerid, -1,"Pesan tidak sesuai panjang yang diizinkan!"), false;

        format(chattext,sizeof(chattext),"%s berkata: %s",PlayerInfo[playerid][pICName],text);
        ProxDetector(20.0, playerid, chattext,COLOR_FADE1,COLOR_FADE2,COLOR_FADE3,COLOR_FADE4,COLOR_FADE5);
        SetPlayerChatBubble(playerid, text, COLOR_WHITE, 20.0, 7000);
        ApplyAnim(playerid, "PED", "IDLE_CHAT",4.1,0,1,1,1,1,1);
        SetTimerEx("ClearAnim", 100*strlen(text), false, "d", playerid);
        return false;
    }
    return true;
}

