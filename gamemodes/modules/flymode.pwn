// ============================================================================
// MODULE: flymode.pwn
// Developer fly/noclip mode — integrated from SA-MP flymode filterscript (h02)
// Usage: /fly — toggle fly mode (Developer only)
// ============================================================================

// Movement speeds
#define FLY_MOVE_SPEED      100.0
#define FLY_ACCEL_RATE      0.03

// Camera modes
#define FLY_CAM_NONE        0
#define FLY_CAM_FLY         1

// Move directions
#define FLY_FORWARD         1
#define FLY_BACK            2
#define FLY_LEFT            3
#define FLY_RIGHT           4
#define FLY_FWD_LEFT        5
#define FLY_FWD_RIGHT       6
#define FLY_BACK_LEFT       7
#define FLY_BACK_RIGHT      8

// Per-player fly data
enum eFlyData {
    flyCamMode,
    flyObjID,
    flyMoveDir,
    flyLROld,
    flyUDOld,
    flyLastMove,
    Float:flyAccelMul,
    Float:flySavedX,
    Float:flySavedY,
    Float:flySavedZ,
    Float:flySavedAngle,
    flySavedInt,
    flySavedVW
};
new FlyData[MAX_PLAYERS][eFlyData];

// ============================================================================
// INIT / RESET
// ============================================================================

stock ResetFlyData(playerid)
{
    FlyData[playerid][flyCamMode]   = FLY_CAM_NONE;
    FlyData[playerid][flyObjID]     = INVALID_OBJECT_ID;
    FlyData[playerid][flyMoveDir]   = 0;
    FlyData[playerid][flyLROld]     = 0;
    FlyData[playerid][flyUDOld]     = 0;
    FlyData[playerid][flyLastMove]  = 0;
    FlyData[playerid][flyAccelMul]  = 0.0;
}

// ============================================================================
// FLY MODE TOGGLE
// ============================================================================

stock StartFlyMode(playerid)
{
    // Save current position
    GetPlayerPos(playerid, FlyData[playerid][flySavedX], FlyData[playerid][flySavedY], FlyData[playerid][flySavedZ]);
    GetPlayerFacingAngle(playerid, FlyData[playerid][flySavedAngle]);
    FlyData[playerid][flySavedInt] = GetPlayerInterior(playerid);
    FlyData[playerid][flySavedVW]  = GetPlayerVirtualWorld(playerid);

    // Create invisible object for camera attach
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    FlyData[playerid][flyObjID] = CreatePlayerObject(playerid, 19300, x, y, z, 0.0, 0.0, 0.0);

    // Spectate mode (streams objects based on camera, not player pos)
    TogglePlayerSpectating(playerid, true);

    // Attach camera to object
    AttachCameraToPlayerObject(playerid, FlyData[playerid][flyObjID]);

    FlyData[playerid][flyCamMode]  = FLY_CAM_FLY;
    FlyData[playerid][flyAccelMul] = 0.0;

    SendClientFormattedMessage(playerid, COLOR_ADMIN, "[Dev] Fly Mode: ON — WASD untuk gerak, mouse untuk arah. Ketik /fly lagi untuk berhenti.");
    return 1;
}

stock StopFlyMode(playerid)
{
    // Ambil posisi kamera terakhir (posisi tujuan terbang) SEBELUM spectating dimatikan
    new Float:camX, Float:camY, Float:camZ;
    GetPlayerCameraPos(playerid, camX, camY, camZ);

    CancelEdit(playerid);
    TogglePlayerSpectating(playerid, false);

    if(FlyData[playerid][flyObjID] != INVALID_OBJECT_ID)
    {
        DestroyPlayerObject(playerid, FlyData[playerid][flyObjID]);
        FlyData[playerid][flyObjID] = INVALID_OBJECT_ID;
    }

    FlyData[playerid][flyCamMode] = FLY_CAM_NONE;

    // Turunkan player di posisi kamera terakhir (posisi tujuan), bukan posisi awal
    // Sedikit turunkan Z agar tidak melayang
    SetPlayerPos(playerid, camX, camY, camZ - 1.0);
    // Arahkan facing angle sesuai arah kamera
    new Float:fvX, Float:fvY, Float:fvZ;
    // Gunakan saved angle sebagai fallback
    fvX = camX - FlyData[playerid][flySavedX];
    fvY = camY - FlyData[playerid][flySavedY];
    fvZ = 0.0;
    #pragma unused fvZ
    new Float:ang = atan2(fvX, fvY);
    SetPlayerFacingAngle(playerid, ang);
    // Pertahankan interior & VW dari saat mulai terbang
    SetPlayerInterior(playerid, FlyData[playerid][flySavedInt]);
    SetPlayerVirtualWorld(playerid, FlyData[playerid][flySavedVW]);
    SetCameraBehindPlayer(playerid);

    SendClientFormattedMessage(playerid, COLOR_ADMIN, "[Dev] Fly Mode: OFF — Kamu turun di posisi tujuan.");
    return 1;
}

// ============================================================================
// MOVEMENT LOGIC (called from OnPlayerUpdate)
// ============================================================================

stock Fly_GetMoveDirection(ud, lr)
{
    new direction = 0;
    if(lr < 0)
    {
        if(ud < 0)      direction = FLY_FWD_LEFT;
        else if(ud > 0)  direction = FLY_BACK_LEFT;
        else             direction = FLY_LEFT;
    }
    else if(lr > 0)
    {
        if(ud < 0)      direction = FLY_FWD_RIGHT;
        else if(ud > 0)  direction = FLY_BACK_RIGHT;
        else             direction = FLY_RIGHT;
    }
    else if(ud < 0)      direction = FLY_FORWARD;
    else if(ud > 0)      direction = FLY_BACK;
    return direction;
}

stock Fly_GetNextPos(move_dir, Float:CP[3], Float:FV[3], &Float:X, &Float:Y, &Float:Z)
{
    new Float:oX = FV[0] * 6000.0;
    new Float:oY = FV[1] * 6000.0;
    new Float:oZ = FV[2] * 6000.0;

    switch(move_dir)
    {
        case FLY_FORWARD:       { X = CP[0]+oX; Y = CP[1]+oY; Z = CP[2]+oZ; }
        case FLY_BACK:          { X = CP[0]-oX; Y = CP[1]-oY; Z = CP[2]-oZ; }
        case FLY_LEFT:          { X = CP[0]-oY; Y = CP[1]+oX; Z = CP[2]; }
        case FLY_RIGHT:         { X = CP[0]+oY; Y = CP[1]-oX; Z = CP[2]; }
        case FLY_FWD_LEFT:      { X = CP[0]+(oX-oY); Y = CP[1]+(oY+oX); Z = CP[2]+oZ; }
        case FLY_FWD_RIGHT:     { X = CP[0]+(oX+oY); Y = CP[1]+(oY-oX); Z = CP[2]+oZ; }
        case FLY_BACK_LEFT:     { X = CP[0]+(-oX-oY); Y = CP[1]+(-oY+oX); Z = CP[2]-oZ; }
        case FLY_BACK_RIGHT:    { X = CP[0]+(-oX+oY); Y = CP[1]+(-oY-oX); Z = CP[2]-oZ; }
    }
}

stock Fly_MoveCamera(playerid)
{
    new Float:FV[3], Float:CP[3];
    GetPlayerCameraPos(playerid, CP[0], CP[1], CP[2]);
    GetPlayerCameraFrontVector(playerid, FV[0], FV[1], FV[2]);

    if(FlyData[playerid][flyAccelMul] <= 1.0)
        FlyData[playerid][flyAccelMul] += FLY_ACCEL_RATE;

    new Float:speed = FLY_MOVE_SPEED * FlyData[playerid][flyAccelMul];

    new Float:X, Float:Y, Float:Z;
    Fly_GetNextPos(FlyData[playerid][flyMoveDir], CP, FV, X, Y, Z);
    MovePlayerObject(playerid, FlyData[playerid][flyObjID], X, Y, Z, speed);

    FlyData[playerid][flyLastMove] = GetTickCount();
    return 1;
}

// Called from OnPlayerUpdate in new.pwn
stock ProcessFlyMode(playerid)
{
    if(FlyData[playerid][flyCamMode] != FLY_CAM_FLY) return 1; // not flying, normal update

    new keys, ud, lr;
    GetPlayerKeys(playerid, keys, ud, lr);

    if(FlyData[playerid][flyMoveDir] && (GetTickCount() - FlyData[playerid][flyLastMove] > 100))
    {
        Fly_MoveCamera(playerid);
    }

    if(FlyData[playerid][flyUDOld] != ud || FlyData[playerid][flyLROld] != lr)
    {
        if((FlyData[playerid][flyUDOld] != 0 || FlyData[playerid][flyLROld] != 0) && ud == 0 && lr == 0)
        {
            StopPlayerObject(playerid, FlyData[playerid][flyObjID]);
            FlyData[playerid][flyMoveDir]  = 0;
            FlyData[playerid][flyAccelMul] = 0.0;
        }
        else
        {
            FlyData[playerid][flyMoveDir] = Fly_GetMoveDirection(ud, lr);
            Fly_MoveCamera(playerid);
        }
    }

    FlyData[playerid][flyUDOld] = ud;
    FlyData[playerid][flyLROld] = lr;
    return 0; // return 0 to skip normal OnPlayerUpdate processing while flying
}

// ============================================================================
// COMMAND
// ============================================================================

// /fly — toggle developer fly/noclip mode
COMMAND:fly(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan DevMap/Developer!"), true;

    if(FlyData[playerid][flyCamMode] == FLY_CAM_FLY)
        StopFlyMode(playerid);
    else
        StartFlyMode(playerid);

    return true;
}
