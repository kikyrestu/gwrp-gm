// ============================================================================
// MODULE: gofood.pwn
// Go Food Delivery System — Multi-item cart, M-Banking, locker codes, etc.
// ============================================================================

// Per-player mapping: which ItemTable index each phone line represents
new GoFoodItemMap[MAX_PLAYERS][MAX_APP_LINES];

// Notification textdraws (per player, created/destroyed on demand)
new PlayerText:GoFoodNotifBG[MAX_PLAYERS];
new PlayerText:GoFoodNotifTitle[MAX_PLAYERS];
new PlayerText:GoFoodNotifBody[MAX_PLAYERS];
new GoFoodNotifTimer[MAX_PLAYERS];

// ============================================================================
// INIT (call once per player in ResetPlayerInfo)
// ============================================================================

stock ResetGoFoodData(playerid)
{
    for(new i = 0; i < MAX_GOFOOD_CART; i++)
    {
        PlayerInfo[playerid][pGoFoodCart][i] = -1;
        PlayerInfo[playerid][pGoFoodCartQty][i] = 0;
    }
    PlayerInfo[playerid][pGoFoodCartCount] = 0;
    PlayerInfo[playerid][pGoFoodOrderLocker] = -1;

    if(PlayerInfo[playerid][pGoFoodTimer] != 0)
    {
        KillTimer(PlayerInfo[playerid][pGoFoodTimer]);
        PlayerInfo[playerid][pGoFoodTimer] = 0;
    }
    PlayerInfo[playerid][pGoFoodReady] = false;

    if(PlayerInfo[playerid][pGoFoodActorTimer] != 0)
    {
        KillTimer(PlayerInfo[playerid][pGoFoodActorTimer]);
        PlayerInfo[playerid][pGoFoodActorTimer] = 0;
    }
    if(IsValidActor(PlayerInfo[playerid][pGoFoodActorID]))
        DestroyActor(PlayerInfo[playerid][pGoFoodActorID]);
    PlayerInfo[playerid][pGoFoodActorID] = INVALID_ACTOR_ID;

    PlayerInfo[playerid][pGoFoodLockerCode] = 0;
    PlayerInfo[playerid][pGoFoodOrderStart] = 0;
    PlayerInfo[playerid][pGoFoodDeliveryTime] = 0;

    if(PlayerInfo[playerid][pGoFoodMapIconSet])
    {
        RemovePlayerMapIcon(playerid, GOFOOD_MAP_ICON_ID);
        PlayerInfo[playerid][pGoFoodMapIconSet] = false;
    }

    GoFoodNotifBG[playerid] = INVALID_PLAYER_TD;
    GoFoodNotifTitle[playerid] = INVALID_PLAYER_TD;
    GoFoodNotifBody[playerid] = INVALID_PLAYER_TD;
    GoFoodNotifTimer[playerid] = 0;
}

// ============================================================================
// LOCKER LOADING (from DB)
// ============================================================================

stock LoadGoFoodLockers()
{
    mysql_function_query(MySQL_C1, "SELECT `id`, `city`, `x`, `y`, `z`, `rot_z` FROM `gofood_lockers` ORDER BY `id` ASC", true, "OnGoFoodLockersLoaded", "");
}

publics: OnGoFoodLockersLoaded()
{
    new rows, fields;
    cache_get_data(rows, fields);
    TotalLockers = 0;

    for(new i = 0; i < rows && i < MAX_GOFOOD_LOCKERS; i++)
    {
        LockerData[i][lkDBID] = cache_get_field_content_int(i, "id", MySQL_C1);
        LockerData[i][lkCity] = cache_get_field_content_int(i, "city", MySQL_C1);
        LockerData[i][lkX] = cache_get_field_content_float(i, "x", MySQL_C1);
        LockerData[i][lkY] = cache_get_field_content_float(i, "y", MySQL_C1);
        LockerData[i][lkZ] = cache_get_field_content_float(i, "z", MySQL_C1);
        LockerData[i][lkRotZ] = cache_get_field_content_float(i, "rot_z", MySQL_C1);

        LockerData[i][lkObjectID] = CreateDynamicObject(LOCKER_OBJECT_MODEL,
            LockerData[i][lkX], LockerData[i][lkY], LockerData[i][lkZ],
            0.0, 0.0, LockerData[i][lkRotZ]);

        new lbl[48];
        format(lbl, sizeof(lbl), "Loker Go Food #%d", i + 1);
        LockerData[i][lkLabelID] = Create3DTextLabel(lbl, 0xFF6600FF,
            LockerData[i][lkX], LockerData[i][lkY], LockerData[i][lkZ] + 0.8, 15.0, 0);

        LockerData[i][lkOccupied] = 0;
        LockerData[i][lkOwnerID] = INVALID_PLAYER_ID;
        TotalLockers++;
    }
    printf("[GoFood] Lockers loaded: %d locations.", TotalLockers);
    return 1;
}

// ============================================================================
// FIND NEAREST LOCKER (empty)
// ============================================================================

stock FindNearestLocker(playerid)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    new bestIdx = -1;
    new Float:bestDist = 99999.0;

    for(new i = 0; i < TotalLockers; i++)
    {
        if(LockerData[i][lkOccupied]) continue;

        new Float:dx = px - LockerData[i][lkX];
        new Float:dy = py - LockerData[i][lkY];
        new Float:dist = floatsqroot(dx * dx + dy * dy);

        if(dist < bestDist)
        {
            bestDist = dist;
            bestIdx = i;
        }
    }
    return bestIdx;
}

// Get distance from player to a locker
stock Float:GetPlayerLockerDistance(playerid, lockerIdx)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    new Float:dx = px - LockerData[lockerIdx][lkX];
    new Float:dy = py - LockerData[lockerIdx][lkY];
    return floatsqroot(dx * dx + dy * dy);
}

// ============================================================================
// CUSTOM NOTIFICATION (non-chat, textdraw banner)
// ============================================================================

stock ShowGoFoodNotif(playerid, title[], body[], duration = 6000)
{
    // Kill existing notif
    HideGoFoodNotif(playerid);

    // Background box (top-center, wide banner)
    GoFoodNotifBG[playerid] = CreatePlayerTextDraw(playerid, 320.0, 8.0, "_");
    PlayerTextDrawFont(playerid, GoFoodNotifBG[playerid], 1);
    PlayerTextDrawAlignment(playerid, GoFoodNotifBG[playerid], 2);
    PlayerTextDrawUseBox(playerid, GoFoodNotifBG[playerid], 1);
    PlayerTextDrawBoxColor(playerid, GoFoodNotifBG[playerid], 0xFF6600DD);
    PlayerTextDrawTextSize(playerid, GoFoodNotifBG[playerid], 0.0, 300.0);
    PlayerTextDrawLetterSize(playerid, GoFoodNotifBG[playerid], 0.0, 3.8);
    PlayerTextDrawColor(playerid, GoFoodNotifBG[playerid], 0x00000000);
    PlayerTextDrawSetShadow(playerid, GoFoodNotifBG[playerid], 0);
    PlayerTextDrawShow(playerid, GoFoodNotifBG[playerid]);

    // Title line
    GoFoodNotifTitle[playerid] = CreatePlayerTextDraw(playerid, 320.0, 10.0, title);
    PlayerTextDrawFont(playerid, GoFoodNotifTitle[playerid], 2);
    PlayerTextDrawAlignment(playerid, GoFoodNotifTitle[playerid], 2);
    PlayerTextDrawLetterSize(playerid, GoFoodNotifTitle[playerid], 0.25, 1.2);
    PlayerTextDrawColor(playerid, GoFoodNotifTitle[playerid], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, GoFoodNotifTitle[playerid], 0);
    PlayerTextDrawSetOutline(playerid, GoFoodNotifTitle[playerid], 1);
    PlayerTextDrawShow(playerid, GoFoodNotifTitle[playerid]);

    // Body line
    GoFoodNotifBody[playerid] = CreatePlayerTextDraw(playerid, 320.0, 24.0, body);
    PlayerTextDrawFont(playerid, GoFoodNotifBody[playerid], 1);
    PlayerTextDrawAlignment(playerid, GoFoodNotifBody[playerid], 2);
    PlayerTextDrawLetterSize(playerid, GoFoodNotifBody[playerid], 0.2, 1.0);
    PlayerTextDrawColor(playerid, GoFoodNotifBody[playerid], 0xFFFFDDFF);
    PlayerTextDrawSetShadow(playerid, GoFoodNotifBody[playerid], 0);
    PlayerTextDrawShow(playerid, GoFoodNotifBody[playerid]);

    // Sound
    PlayerPlaySound(playerid, 1058, 0.0, 0.0, 0.0);

    // Auto-hide after duration
    GoFoodNotifTimer[playerid] = SetTimerEx("OnGoFoodNotifExpire", duration, false, "d", playerid);
}

publics: OnGoFoodNotifExpire(playerid)
{
    HideGoFoodNotif(playerid);
}

stock HideGoFoodNotif(playerid)
{
    if(GoFoodNotifTimer[playerid] != 0)
    {
        KillTimer(GoFoodNotifTimer[playerid]);
        GoFoodNotifTimer[playerid] = 0;
    }
    if(GoFoodNotifBG[playerid] != INVALID_PLAYER_TD)
    {
        PlayerTextDrawDestroy(playerid, GoFoodNotifBG[playerid]);
        GoFoodNotifBG[playerid] = INVALID_PLAYER_TD;
    }
    if(GoFoodNotifTitle[playerid] != INVALID_PLAYER_TD)
    {
        PlayerTextDrawDestroy(playerid, GoFoodNotifTitle[playerid]);
        GoFoodNotifTitle[playerid] = INVALID_PLAYER_TD;
    }
    if(GoFoodNotifBody[playerid] != INVALID_PLAYER_TD)
    {
        PlayerTextDrawDestroy(playerid, GoFoodNotifBody[playerid]);
        GoFoodNotifBody[playerid] = INVALID_PLAYER_TD;
    }
}

// ============================================================================
// CART MANAGEMENT
// ============================================================================

stock AddToGoFoodCart(playerid, tableIdx)
{
    // Check if already in cart — increment qty
    for(new i = 0; i < PlayerInfo[playerid][pGoFoodCartCount]; i++)
    {
        if(PlayerInfo[playerid][pGoFoodCart][i] == tableIdx)
        {
            if(PlayerInfo[playerid][pGoFoodCartQty][i] >= 5)
            {
                ShowPhoneToast(playerid, "~r~Maksimal 5 per item!", 0xFF3300DD);
                return 0;
            }
            PlayerInfo[playerid][pGoFoodCartQty][i]++;
            new msg[64];
            format(msg, sizeof(msg), "~o~+1 %s ~w~(x%d)", ItemTable[tableIdx][itmName], PlayerInfo[playerid][pGoFoodCartQty][i]);
            ShowPhoneToast(playerid, msg, 0xFF6600DD);
            return 1;
        }
    }

    // New item — check space
    if(PlayerInfo[playerid][pGoFoodCartCount] >= MAX_GOFOOD_CART)
    {
        ShowPhoneToast(playerid, "~r~Keranjang penuh! Maks 5 item.", 0xFF3300DD);
        return 0;
    }

    new idx = PlayerInfo[playerid][pGoFoodCartCount];
    PlayerInfo[playerid][pGoFoodCart][idx] = tableIdx;
    PlayerInfo[playerid][pGoFoodCartQty][idx] = 1;
    PlayerInfo[playerid][pGoFoodCartCount]++;

    new msg[64];
    format(msg, sizeof(msg), "~o~%s ~w~ditambahkan!", ItemTable[tableIdx][itmName]);
    ShowPhoneToast(playerid, msg, 0xFF6600DD);
    return 1;
}

stock ClearGoFoodCart(playerid)
{
    for(new i = 0; i < MAX_GOFOOD_CART; i++)
    {
        PlayerInfo[playerid][pGoFoodCart][i] = -1;
        PlayerInfo[playerid][pGoFoodCartQty][i] = 0;
    }
    PlayerInfo[playerid][pGoFoodCartCount] = 0;
}

stock GetGoFoodCartTotal(playerid)
{
    new total = 0;
    for(new i = 0; i < PlayerInfo[playerid][pGoFoodCartCount]; i++)
    {
        new ti = PlayerInfo[playerid][pGoFoodCart][i];
        if(ti > 0 && ti < sizeof(ItemTable))
            total += ItemTable[ti][itmValue] * 5 * PlayerInfo[playerid][pGoFoodCartQty][i];
    }
    return total;
}

// Build a short summary of cart items for display
stock BuildCartSummary(playerid, out[], size)
{
    out[0] = EOS;
    for(new i = 0; i < PlayerInfo[playerid][pGoFoodCartCount]; i++)
    {
        new ti = PlayerInfo[playerid][pGoFoodCart][i];
        if(ti <= 0 || ti >= sizeof(ItemTable)) continue;

        new tmp[48];
        if(PlayerInfo[playerid][pGoFoodCartQty][i] > 1)
            format(tmp, sizeof(tmp), "%s x%d", ItemTable[ti][itmName], PlayerInfo[playerid][pGoFoodCartQty][i]);
        else
            format(tmp, sizeof(tmp), "%s", ItemTable[ti][itmName]);

        if(strlen(out) > 0) strcat(out, ", ", size);
        strcat(out, tmp, size);
    }
}

// Check if player has active Go Food order
stock bool:HasGoFoodOrder(playerid)
{
    return (PlayerInfo[playerid][pGoFoodOrderLocker] != -1);
}

// ============================================================================
// PLACE ORDER (from cart, using M-Banking)
// ============================================================================

stock GoFoodPlaceOrder(playerid)
{
    if(HasGoFoodOrder(playerid))
    {
        ShowGoFoodNotif(playerid, "~r~Go Food", "Kamu masih punya pesanan aktif!");
        return 0;
    }

    if(PlayerInfo[playerid][pGoFoodCartCount] <= 0)
    {
        ShowGoFoodNotif(playerid, "~r~Go Food", "Keranjang kosong! Pilih menu dulu.");
        return 0;
    }

    // Must have bank account
    if(strlen(PlayerInfo[playerid][pBankAccount]) < 5)
    {
        ShowGoFoodNotif(playerid, "~r~Go Food", "Kamu belum punya rekening M-Banking!");
        return 0;
    }

    new totalPrice = GetGoFoodCartTotal(playerid);

    // Check M-Banking balance
    if(PlayerInfo[playerid][pBank] < totalPrice)
    {
        new msg[80];
        format(msg, sizeof(msg), "Saldo M-Banking tidak cukup! Butuh Rp %d", totalPrice);
        ShowGoFoodNotif(playerid, "~r~Go Food", msg);
        return 0;
    }

    // Find nearest empty locker
    new lockerIdx = FindNearestLocker(playerid);
    if(lockerIdx == -1)
    {
        ShowGoFoodNotif(playerid, "~r~Go Food", "Semua loker penuh! Coba lagi nanti.");
        return 0;
    }

    // Check inventory space — count total items to add
    new totalItems = 0;
    for(new i = 0; i < PlayerInfo[playerid][pGoFoodCartCount]; i++)
        totalItems += PlayerInfo[playerid][pGoFoodCartQty][i];

    // Deduct from M-Banking
    PlayerInfo[playerid][pBank] -= totalPrice;
    LogBankTransaction(playerid, 0, "gofood", totalPrice, 0, PlayerInfo[playerid][pBank]);

    // Reserve locker
    LockerData[lockerIdx][lkOccupied] = 1;
    LockerData[lockerIdx][lkOwnerID] = playerid;

    // Generate 4-digit locker code
    PlayerInfo[playerid][pGoFoodLockerCode] = 1000 + random(9000); // 1000-9999

    // Store order info
    PlayerInfo[playerid][pGoFoodOrderLocker] = lockerIdx;
    PlayerInfo[playerid][pGoFoodReady] = false;

    // Calculate delivery time based on distance
    new Float:dist = GetPlayerLockerDistance(playerid, lockerIdx);
    new deliveryTime = 30000 + floatround(dist * 20.0); // 30s base + 20ms per unit distance
    if(deliveryTime < GOFOOD_MIN_DELIVERY) deliveryTime = GOFOOD_MIN_DELIVERY;
    if(deliveryTime > GOFOOD_MAX_DELIVERY) deliveryTime = GOFOOD_MAX_DELIVERY;

    PlayerInfo[playerid][pGoFoodDeliveryTime] = deliveryTime;
    PlayerInfo[playerid][pGoFoodOrderStart] = GetTickCount();

    // Start delivery timer
    PlayerInfo[playerid][pGoFoodTimer] = SetTimerEx("OnGoFoodDelivered", deliveryTime, false, "d", playerid);

    // Notify via custom notification
    new body[128], summary[96];
    BuildCartSummary(playerid, summary, sizeof(summary));
    format(body, sizeof(body), "%s~n~Loker #%d | Kode: %d | ~y~%d detik",
        summary, lockerIdx + 1, PlayerInfo[playerid][pGoFoodLockerCode], deliveryTime / 1000);
    ShowGoFoodNotif(playerid, "~w~Go Food - Pesanan Diterima", body, 8000);

    return 1;
}

// ============================================================================
// DELIVERY CALLBACK — food arrives at locker
// ============================================================================

publics: OnGoFoodDelivered(playerid)
{
    if(!IsPlayerConnected(playerid)) return CancelGoFoodOrder(playerid);
    if(!PlayerInfo[playerid][pLogged]) return CancelGoFoodOrder(playerid);

    PlayerInfo[playerid][pGoFoodTimer] = 0;
    PlayerInfo[playerid][pGoFoodReady] = true;

    new lockerIdx = PlayerInfo[playerid][pGoFoodOrderLocker];
    if(lockerIdx < 0 || lockerIdx >= TotalLockers) return CancelGoFoodOrder(playerid);

    // Spawn delivery actor near locker
    new Float:angle = LockerData[lockerIdx][lkRotZ];
    new Float:ax = LockerData[lockerIdx][lkX] + 1.2 * floatcos(angle + 90.0, degrees);
    new Float:ay = LockerData[lockerIdx][lkY] + 1.2 * floatsin(angle + 90.0, degrees);
    new Float:az = LockerData[lockerIdx][lkZ];
    new Float:aangle = atan2(LockerData[lockerIdx][lkY] - ay, LockerData[lockerIdx][lkX] - ax);

    PlayerInfo[playerid][pGoFoodActorID] = CreateActor(GOFOOD_ACTOR_SKIN, ax, ay, az, aangle);
    if(IsValidActor(PlayerInfo[playerid][pGoFoodActorID]))
    {
        SetActorInvulnerable(PlayerInfo[playerid][pGoFoodActorID], true);
        ApplyActorAnimation(PlayerInfo[playerid][pGoFoodActorID], "CARRY", "putdwn05", 4.1, 0, 1, 1, 1, 3000);
        // Start visibility check timer (despawn when no player can see)
        PlayerInfo[playerid][pGoFoodActorTimer] = SetTimerEx("OnGoFoodActorCheck", 5000, false, "d", playerid);
    }

    // Update locker label
    new lbl[64];
    format(lbl, sizeof(lbl), "Loker Go Food #%d\n{00FF00}[Pesanan Siap]", lockerIdx + 1);
    Update3DTextLabelText(LockerData[lockerIdx][lkLabelID], 0x00FF00FF, lbl);

    // Set map icon on minimap
    SetPlayerMapIcon(playerid, GOFOOD_MAP_ICON_ID,
        LockerData[lockerIdx][lkX], LockerData[lockerIdx][lkY], LockerData[lockerIdx][lkZ],
        0, 0xFF6600FF, MAPICON_GLOBAL);
    PlayerInfo[playerid][pGoFoodMapIconSet] = true;

    // Custom notification (NOT chat)
    new body[128];
    format(body, sizeof(body), "Pesanan sampai di Loker #%d~n~Kode: ~g~%d~n~~w~Tekan ~y~F ~w~di dekat loker",
        lockerIdx + 1, PlayerInfo[playerid][pGoFoodLockerCode]);
    ShowGoFoodNotif(playerid, "~g~Go Food - Pesanan Siap!", body, 10000);

    return 1;
}

// ============================================================================
// ACTOR VISIBILITY CHECK — despawn when no player can see it
// ============================================================================

publics: OnGoFoodActorCheck(playerid)
{
    PlayerInfo[playerid][pGoFoodActorTimer] = 0;

    if(!IsPlayerConnected(playerid))
    {
        return 1;
    }

    new actorId = PlayerInfo[playerid][pGoFoodActorID];
    if(!IsValidActor(actorId)) return 1;

    new Float:ax, Float:ay, Float:az;
    GetActorPos(actorId, ax, ay, az);

    // Check if ANY connected player is within streaming distance (~150 units)
    new bool:anyoneNearby = false;
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        if(!PlayerInfo[i][pLogged]) continue;
        if(IsPlayerInRangeOfPoint(i, 150.0, ax, ay, az))
        {
            anyoneNearby = true;
            break;
        }
    }

    if(!anyoneNearby)
    {
        // No one can see — destroy actor
        DestroyActor(actorId);
        PlayerInfo[playerid][pGoFoodActorID] = INVALID_ACTOR_ID;
        return 1;
    }

    // Someone nearby — keep checking every 5 seconds
    PlayerInfo[playerid][pGoFoodActorTimer] = SetTimerEx("OnGoFoodActorCheck", 5000, false, "d", playerid);
    return 1;
}

// ============================================================================
// LOCKER PICKUP — press F near locker → enter code dialog
// ============================================================================

stock HandleGoFoodPickup(playerid)
{
    if(!PlayerInfo[playerid][pGoFoodReady]) return 0;

    new lockerIdx = PlayerInfo[playerid][pGoFoodOrderLocker];
    if(lockerIdx < 0 || lockerIdx >= TotalLockers) return 0;

    if(!IsPlayerInRangeOfPoint(playerid, LOCKER_RANGE,
        LockerData[lockerIdx][lkX], LockerData[lockerIdx][lkY], LockerData[lockerIdx][lkZ]))
        return 0;

    // Show code input dialog
    new prompt[128];
    format(prompt, sizeof(prompt),
        "{FF6600}Go Food - Loker #%d\n\n{FFFFFF}Masukkan kode loker 4 digit\nyang diberikan saat pemesanan:",
        lockerIdx + 1);
    ShowPlayerDialog(playerid, DIALOG_GOFOOD_CODE, DIALOG_STYLE_INPUT,
        "{FF6600}Kode Loker", prompt, "Buka", "Batal");
    return 1;
}

// Handle code input response
stock HandleGoFoodCodeDialog(playerid, response, inputtext[])
{
    if(!response)
    {
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    new code = strval(inputtext);
    if(code != PlayerInfo[playerid][pGoFoodLockerCode])
    {
        ShowGoFoodNotif(playerid, "~r~Go Food", "Kode loker salah! Coba lagi.", 4000);
        return 1;
    }

    // Correct code — deliver items to inventory
    new lockerIdx = PlayerInfo[playerid][pGoFoodOrderLocker];
    new itemsAdded = 0;
    new itemsFailed = 0;

    for(new i = 0; i < PlayerInfo[playerid][pGoFoodCartCount]; i++)
    {
        new ti = PlayerInfo[playerid][pGoFoodCart][i];
        if(ti <= 0 || ti >= sizeof(ItemTable)) continue;

        new qty = PlayerInfo[playerid][pGoFoodCartQty][i];
        for(new q = 0; q < qty; q++)
        {
            if(AddInventoryItem(playerid, ItemTable[ti][itmID], 1))
                itemsAdded++;
            else
                itemsFailed++;
        }
    }

    // Notification
    if(itemsFailed > 0)
    {
        new msg[80];
        format(msg, sizeof(msg), "%d item diambil, %d gagal (tas penuh)", itemsAdded, itemsFailed);
        ShowGoFoodNotif(playerid, "~y~Go Food", msg);
    }
    else
    {
        new msg[64];
        format(msg, sizeof(msg), "%d item berhasil diambil dari Loker #%d!", itemsAdded, lockerIdx + 1);
        ShowGoFoodNotif(playerid, "~g~Go Food", msg);
    }

    // Cleanup
    FreeLocker(lockerIdx);

    // Remove actor if still there
    if(IsValidActor(PlayerInfo[playerid][pGoFoodActorID]))
    {
        DestroyActor(PlayerInfo[playerid][pGoFoodActorID]);
        PlayerInfo[playerid][pGoFoodActorID] = INVALID_ACTOR_ID;
    }
    if(PlayerInfo[playerid][pGoFoodActorTimer] != 0)
    {
        KillTimer(PlayerInfo[playerid][pGoFoodActorTimer]);
        PlayerInfo[playerid][pGoFoodActorTimer] = 0;
    }

    // Remove map icon
    if(PlayerInfo[playerid][pGoFoodMapIconSet])
    {
        RemovePlayerMapIcon(playerid, GOFOOD_MAP_ICON_ID);
        PlayerInfo[playerid][pGoFoodMapIconSet] = false;
    }

    // Reset order state (but keep cart for reorder convenience)
    PlayerInfo[playerid][pGoFoodOrderLocker] = -1;
    PlayerInfo[playerid][pGoFoodReady] = false;
    PlayerInfo[playerid][pGoFoodLockerCode] = 0;
    PlayerInfo[playerid][pGoFoodOrderStart] = 0;
    PlayerInfo[playerid][pGoFoodDeliveryTime] = 0;
    ClearGoFoodCart(playerid);

    return 1;
}

// ============================================================================
// CANCEL ORDER (with refund check)
// ============================================================================

stock CancelGoFoodOrder(playerid)
{
    new lockerIdx = PlayerInfo[playerid][pGoFoodOrderLocker];
    if(lockerIdx >= 0 && lockerIdx < TotalLockers)
        FreeLocker(lockerIdx);

    if(PlayerInfo[playerid][pGoFoodTimer] != 0)
    {
        KillTimer(PlayerInfo[playerid][pGoFoodTimer]);
        PlayerInfo[playerid][pGoFoodTimer] = 0;
    }
    if(PlayerInfo[playerid][pGoFoodActorTimer] != 0)
    {
        KillTimer(PlayerInfo[playerid][pGoFoodActorTimer]);
        PlayerInfo[playerid][pGoFoodActorTimer] = 0;
    }
    if(IsValidActor(PlayerInfo[playerid][pGoFoodActorID]))
    {
        DestroyActor(PlayerInfo[playerid][pGoFoodActorID]);
        PlayerInfo[playerid][pGoFoodActorID] = INVALID_ACTOR_ID;
    }
    if(PlayerInfo[playerid][pGoFoodMapIconSet])
    {
        RemovePlayerMapIcon(playerid, GOFOOD_MAP_ICON_ID);
        PlayerInfo[playerid][pGoFoodMapIconSet] = false;
    }

    PlayerInfo[playerid][pGoFoodOrderLocker] = -1;
    PlayerInfo[playerid][pGoFoodReady] = false;
    PlayerInfo[playerid][pGoFoodLockerCode] = 0;
    PlayerInfo[playerid][pGoFoodOrderStart] = 0;
    PlayerInfo[playerid][pGoFoodDeliveryTime] = 0;
    return 1;
}

// Cancel with refund — returns 1 if allowed, 0 if not
stock TryCancelWithRefund(playerid)
{
    if(!HasGoFoodOrder(playerid)) return 0;

    // If already ready (delivered), can't cancel
    if(PlayerInfo[playerid][pGoFoodReady])
    {
        ShowGoFoodNotif(playerid, "~r~Go Food", "Pesanan sudah sampai! Ambil di loker.", 4000);
        return 0;
    }

    // Check elapsed time — if > GOFOOD_REFUND_CUTOFF% elapsed, deny
    new elapsed = GetTickCount() - PlayerInfo[playerid][pGoFoodOrderStart];
    new totalTime = PlayerInfo[playerid][pGoFoodDeliveryTime];
    new pct = 0;
    if(totalTime > 0) pct = (elapsed * 100) / totalTime;

    if(pct >= GOFOOD_REFUND_CUTOFF)
    {
        ShowGoFoodNotif(playerid, "~r~Go Food", "Kurir sudah dekat! Tidak bisa dibatalkan.", 4000);
        return 0;
    }

    // Refund to M-Banking
    new refund = GetGoFoodCartTotal(playerid);
    PlayerInfo[playerid][pBank] += refund;
    LogBankTransaction(playerid, 0, "gofood_refund", refund, 0, PlayerInfo[playerid][pBank]);

    CancelGoFoodOrder(playerid);

    new msg[64];
    format(msg, sizeof(msg), "Pesanan dibatalkan. Refund Rp %d ke M-Banking.", refund);
    ShowGoFoodNotif(playerid, "~y~Go Food", msg);

    ClearGoFoodCart(playerid);
    return 1;
}

stock FreeLocker(lockerIdx)
{
    LockerData[lockerIdx][lkOccupied] = 0;
    LockerData[lockerIdx][lkOwnerID] = INVALID_PLAYER_ID;

    new lbl[48];
    format(lbl, sizeof(lbl), "Loker Go Food #%d", lockerIdx + 1);
    Update3DTextLabelText(LockerData[lockerIdx][lkLabelID], 0xFF6600FF, lbl);
}

// ============================================================================
// GO FOOD PHONE UI — Main Screen
// ============================================================================

stock ShowGoFoodScreen(playerid)
{
    PlayerInfo[playerid][pPhoneScreen] = PHONE_SCREEN_MK_GOFOOD;
    PlayerInfo[playerid][pPhoneScrollPos] = 0;

    ShowAppScreen(playerid, 0xFF6600DD, "~o~Go Food");
    HideAppBtns(playerid);

    // If active order → show status screen
    if(HasGoFoodOrder(playerid))
    {
        ShowGoFoodStatusScreen(playerid);
        return 1;
    }

    // No active order → show menu with cart header
    ShowGoFoodList(playerid);
    return 1;
}

// ============================================================================
// STATUS SCREEN (active order)
// ============================================================================

stock ShowGoFoodStatusScreen(playerid)
{
    new lockerIdx = PlayerInfo[playerid][pGoFoodOrderLocker];

    // Line 0: title
    SetAppLine(playerid, 0, "~y~--- Pesanan Aktif ---");

    // Line 1: items summary
    new summary[96];
    BuildCartSummary(playerid, summary, sizeof(summary));
    new sumline[96];
    format(sumline, sizeof(sumline), "~w~%s", summary);
    SetAppLine(playerid, 1, sumline);

    // Line 2: locker + code
    new info[64];
    format(info, sizeof(info), "~w~Loker #%d | Kode: ~g~%d", lockerIdx + 1, PlayerInfo[playerid][pGoFoodLockerCode]);
    SetAppLine(playerid, 2, info);

    // Line 3: status
    if(PlayerInfo[playerid][pGoFoodReady])
    {
        SetAppLine(playerid, 3, "~g~Status: Pesanan siap diambil!");
    }
    else
    {
        new elapsed = GetTickCount() - PlayerInfo[playerid][pGoFoodOrderStart];
        new remaining = PlayerInfo[playerid][pGoFoodDeliveryTime] - elapsed;
        if(remaining < 0) remaining = 0;

        new statusline[64];
        format(statusline, sizeof(statusline), "~y~Status: Sedang diantar... ~w~%d detik", remaining / 1000);
        SetAppLine(playerid, 3, statusline);
    }

    // Line 4: total price
    new priceline[48];
    format(priceline, sizeof(priceline), "~w~Total: ~g~Rp %d", GetGoFoodCartTotal(playerid));
    SetAppLine(playerid, 4, priceline);

    // Line 5: empty
    HideAppLine(playerid, 5);

    // Line 6: cancel button (check if allowed)
    if(PlayerInfo[playerid][pGoFoodReady])
    {
        SetAppLine(playerid, 6, "~w~Ambil pesanan di loker (tekan F)");
    }
    else
    {
        new elapsed = GetTickCount() - PlayerInfo[playerid][pGoFoodOrderStart];
        new totalTime = PlayerInfo[playerid][pGoFoodDeliveryTime];
        new pct = 0;
        if(totalTime > 0) pct = (elapsed * 100) / totalTime;

        if(pct >= GOFOOD_REFUND_CUTOFF)
            SetAppLine(playerid, 6, "~w~Kurir hampir sampai...");
        else
            SetAppLine(playerid, 6, "~r~> Batalkan Pesanan");
    }

    ShowAppScroll(playerid, false, false);
}

// ============================================================================
// MENU LIST (food items with cart header)
// ============================================================================

stock ShowGoFoodList(playerid)
{
    new scroll = PlayerInfo[playerid][pPhoneScrollPos];

    // Count food/drink items
    new shopItems = 0;
    for(new i = 1; i < sizeof(ItemTable); i++)
    {
        if(ItemTable[i][itmType] == ITEM_TYPE_FOOD ||
           ItemTable[i][itmType] == ITEM_TYPE_DRINK)
            shopItems++;
    }

    // Line 0 is always cart indicator
    new cartCount = PlayerInfo[playerid][pGoFoodCartCount];
    if(cartCount > 0)
    {
        new cartTotal = GetGoFoodCartTotal(playerid);
        new cartline[64];
        format(cartline, sizeof(cartline), "~g~[Keranjang: %d item | Rp %d] >", cartCount, cartTotal);
        SetAppLine(playerid, 0, cartline);
    }
    else
    {
        SetAppLine(playerid, 0, "~w~[Keranjang kosong]");
    }

    // Lines 1-6: food items (6 visible slots for menu)
    new maxLines = MAX_APP_LINES - 1; // 6 lines for items
    if(scroll > shopItems - maxLines && shopItems > maxLines)
        scroll = shopItems - maxLines;
    if(scroll < 0) scroll = 0;
    PlayerInfo[playerid][pPhoneScrollPos] = scroll;

    if(shopItems == 0)
    {
        SetAppLine(playerid, 1, "~w~Tidak ada menu tersedia.");
        for(new i = 2; i < MAX_APP_LINES; i++)
            HideAppLine(playerid, i);
        ShowAppScroll(playerid, false, false);
        return;
    }

    new shown = 0;
    new skipped = 0;
    for(new i = 1; i < sizeof(ItemTable); i++)
    {
        if(ItemTable[i][itmType] != ITEM_TYPE_FOOD &&
           ItemTable[i][itmType] != ITEM_TYPE_DRINK) continue;

        if(skipped < scroll) { skipped++; continue; }
        if(shown >= maxLines) break;

        new npcprice = ItemTable[i][itmValue] * 5;
        new linebuf[64];
        format(linebuf, sizeof(linebuf), "~w~%s - ~g~Rp %d", ItemTable[i][itmName], npcprice);
        SetAppLine(playerid, shown + 1, linebuf); // +1 because line 0 is cart
        GoFoodItemMap[playerid][shown] = i;
        shown++;
    }

    for(new j = shown + 1; j < MAX_APP_LINES; j++)
        HideAppLine(playerid, j);

    ShowAppScroll(playerid, scroll > 0, (scroll + maxLines) < shopItems);
}

// ============================================================================
// CART VIEW SCREEN
// ============================================================================

stock ShowGoFoodCartScreen(playerid)
{
    PlayerInfo[playerid][pPhoneScreen] = PHONE_SCREEN_MK_GOFOOD_CART;
    ShowAppScreen(playerid, 0xFF6600DD, "~o~Keranjang");
    HideAppBtns(playerid);

    new cartCount = PlayerInfo[playerid][pGoFoodCartCount];

    if(cartCount == 0)
    {
        SetAppLine(playerid, 0, "~w~Keranjang kosong.");
        SetAppLine(playerid, 1, "~w~Pilih menu dari Go Food.");
        for(new i = 2; i < MAX_APP_LINES; i++)
            HideAppLine(playerid, i);
        ShowAppScroll(playerid, false, false);
        return;
    }

    // Show cart items (lines 0..cartCount-1)
    new lineIdx = 0;
    for(new i = 0; i < cartCount && lineIdx < 5; i++)
    {
        new ti = PlayerInfo[playerid][pGoFoodCart][i];
        if(ti <= 0 || ti >= sizeof(ItemTable)) continue;

        new price = ItemTable[ti][itmValue] * 5 * PlayerInfo[playerid][pGoFoodCartQty][i];
        new linebuf[64];
        format(linebuf, sizeof(linebuf), "~r~x ~w~%s x%d - ~g~Rp %d",
            ItemTable[ti][itmName], PlayerInfo[playerid][pGoFoodCartQty][i], price);
        SetAppLine(playerid, lineIdx, linebuf);
        lineIdx++;
    }

    // Total line
    new totalline[48];
    format(totalline, sizeof(totalline), "~w~Total: ~g~Rp %d", GetGoFoodCartTotal(playerid));
    if(lineIdx < MAX_APP_LINES)
    {
        SetAppLine(playerid, lineIdx, totalline);
        lineIdx++;
    }

    // Order button
    if(lineIdx < MAX_APP_LINES)
    {
        SetAppLine(playerid, lineIdx, "~g~> Pesan Sekarang");
        lineIdx++;
    }

    // Clear cart button
    if(lineIdx < MAX_APP_LINES)
    {
        SetAppLine(playerid, lineIdx, "~r~> Kosongkan Keranjang");
        lineIdx++;
    }

    for(new j = lineIdx; j < MAX_APP_LINES; j++)
        HideAppLine(playerid, j);

    ShowAppScroll(playerid, false, false);
}

// ============================================================================
// LINE CLICK HANDLERS
// ============================================================================

stock HandleGoFoodLineClick(playerid, lineIdx)
{
    // If showing active order status
    if(HasGoFoodOrder(playerid))
    {
        if(lineIdx == 6) // Cancel button
        {
            TryCancelWithRefund(playerid);
            ShowGoFoodScreen(playerid);
        }
        return 1;
    }

    // Normal menu mode
    if(lineIdx == 0)
    {
        // Cart header clicked → go to cart screen
        ShowGoFoodCartScreen(playerid);
        return 1;
    }

    // Food item clicked (lineIdx 1..6 → GoFoodItemMap index 0..5)
    new mapIdx = lineIdx - 1;
    if(mapIdx < 0 || mapIdx >= MAX_APP_LINES) return 1;

    new tableIdx = GoFoodItemMap[playerid][mapIdx];
    if(tableIdx <= 0 || tableIdx >= sizeof(ItemTable)) return 1;

    // Add to cart
    AddToGoFoodCart(playerid, tableIdx);

    // Refresh the screen to update cart header
    ShowGoFoodList(playerid);
    return 1;
}

stock HandleGoFoodCartClick(playerid, lineIdx)
{
    new cartCount = PlayerInfo[playerid][pGoFoodCartCount];

    if(cartCount == 0) return 1;

    // Lines 0..cartCount-1 = cart items (click to remove)
    if(lineIdx < cartCount)
    {
        // Remove this item from cart
        new ti = PlayerInfo[playerid][pGoFoodCart][lineIdx];
        if(ti > 0 && ti < sizeof(ItemTable))
        {
            new msg[64];
            format(msg, sizeof(msg), "~r~%s ~w~dihapus dari keranjang", ItemTable[ti][itmName]);
            ShowPhoneToast(playerid, msg, 0xFF3300DD);
        }

        // Shift cart items
        for(new i = lineIdx; i < cartCount - 1; i++)
        {
            PlayerInfo[playerid][pGoFoodCart][i] = PlayerInfo[playerid][pGoFoodCart][i + 1];
            PlayerInfo[playerid][pGoFoodCartQty][i] = PlayerInfo[playerid][pGoFoodCartQty][i + 1];
        }
        PlayerInfo[playerid][pGoFoodCartCount]--;
        PlayerInfo[playerid][pGoFoodCart][PlayerInfo[playerid][pGoFoodCartCount]] = -1;
        PlayerInfo[playerid][pGoFoodCartQty][PlayerInfo[playerid][pGoFoodCartCount]] = 0;

        ShowGoFoodCartScreen(playerid);
        return 1;
    }

    // After cart items: total line, then order button, then clear button
    new btnBase = cartCount; // total line index
    // btnBase + 1 = "Pesan Sekarang"
    // btnBase + 2 = "Kosongkan Keranjang"

    if(lineIdx == btnBase + 1)
    {
        // Order Now → confirm dialog
        new prompt[180], summary[96];
        BuildCartSummary(playerid, summary, sizeof(summary));
        new totalPrice = GetGoFoodCartTotal(playerid);
        format(prompt, sizeof(prompt),
            "{FF6600}Go Food - Konfirmasi Pesanan\n\n{FFFFFF}%s\n\n{00FF00}Total: Rp %d\n{FFFFFF}Pembayaran via M-Banking.\nMakanan diantar ke loker terdekat.",
            summary, totalPrice);
        ShowPlayerDialog(playerid, DIALOG_GOFOOD_CONFIRM, DIALOG_STYLE_MSGBOX,
            "{FF6600}Go Food - Order", prompt, "Pesan", "Batal");
        return 1;
    }

    if(lineIdx == btnBase + 2)
    {
        // Clear cart
        ClearGoFoodCart(playerid);
        ShowPhoneToast(playerid, "~r~Keranjang dikosongkan", 0xFF3300DD);
        ShowGoFoodCartScreen(playerid);
        return 1;
    }

    return 1;
}

// ============================================================================
// CONFIRM DIALOG (from cart screen)
// ============================================================================

stock HandleGoFoodConfirmDialog(playerid, response)
{
    if(!response)
    {
        if(PlayerInfo[playerid][pPhoneOpen])
        {
            ShowGoFoodCartScreen(playerid);
            SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        }
        return 1;
    }

    GoFoodPlaceOrder(playerid);

    if(PlayerInfo[playerid][pPhoneOpen])
    {
        ShowGoFoodScreen(playerid);
        SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
    }
    return 1;
}

// ============================================================================
// DEV COMMANDS (Level 6+)
// ============================================================================

COMMAND:setlocker(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP) return SendClientFormattedMessage(playerid, COLOR_RED, "DevMap/Developer only."), true;

    new city;
    if(sscanf(params, "d", city)) return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /setlocker [kota: 1=MekarPura 2=MadyaRaya 3=Mojosono]"), true;
    if(city < 1 || city > 3) return SendClientFormattedMessage(playerid, COLOR_RED, "Kota harus 1-3."), true;
    if(TotalLockers >= MAX_GOFOOD_LOCKERS) return SendClientFormattedMessage(playerid, COLOR_RED, "Maks locker tercapai!"), true;

    new Float:px, Float:py, Float:pz, Float:pa;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerFacingAngle(playerid, pa);

    mysql_format(MySQL_C1, query, sizeof(query),
        "INSERT INTO `gofood_lockers` (`city`, `x`, `y`, `z`, `rot_z`) VALUES ('%d', '%f', '%f', '%f', '%f')",
        city, px, py, pz, pa);
    mysql_function_query(MySQL_C1, query, true, "OnLockerCreated", "dffffd", playerid, px, py, pz, pa, city);
    return true;
}

publics: OnLockerCreated(playerid, Float:px, Float:py, Float:pz, Float:pa, city)
{
    new insertid = cache_insert_id();
    if(insertid <= 0)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "[GoFood] Gagal menyimpan locker.");
        return 1;
    }

    new idx = TotalLockers;
    LockerData[idx][lkDBID] = insertid;
    LockerData[idx][lkCity] = city;
    LockerData[idx][lkX] = px;
    LockerData[idx][lkY] = py;
    LockerData[idx][lkZ] = pz;
    LockerData[idx][lkRotZ] = pa;

    LockerData[idx][lkObjectID] = CreateDynamicObject(LOCKER_OBJECT_MODEL, px, py, pz, 0.0, 0.0, pa);

    new lbl[48];
    format(lbl, sizeof(lbl), "Loker Go Food #%d", idx + 1);
    LockerData[idx][lkLabelID] = Create3DTextLabel(lbl, 0xFF6600FF, px, py, pz + 0.8, 15.0, 0);

    LockerData[idx][lkOccupied] = 0;
    LockerData[idx][lkOwnerID] = INVALID_PLAYER_ID;
    TotalLockers++;

    new cityname[16];
    if(city == CITY_MEKAR_PURA) cityname = "MekarPura";
    else if(city == CITY_MADYA_RAYA) cityname = "MadyaRaya";
    else cityname = "Mojosono";

    SendClientFormattedMessage(playerid, 0x00CC00FF, "[GoFood] Locker #%d dibuat di %s (DB ID: %d).", idx + 1, cityname, insertid);
    return 1;
}

COMMAND:dellocker(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP) return SendClientFormattedMessage(playerid, COLOR_RED, "DevMap/Developer only."), true;

    new idx;
    if(sscanf(params, "d", idx)) return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /dellocker [nomor_loker]"), true;
    idx -= 1;
    if(idx < 0 || idx >= TotalLockers) return SendClientFormattedMessage(playerid, COLOR_RED, "Locker tidak ditemukan."), true;

    mysql_format(MySQL_C1, query, sizeof(query), "DELETE FROM `gofood_lockers` WHERE `id` = '%d'", LockerData[idx][lkDBID]);
    mysql_function_query(MySQL_C1, query, false, "", "");

    DestroyDynamicObject(LockerData[idx][lkObjectID]);
    Delete3DTextLabel(LockerData[idx][lkLabelID]);

    // Refund anyone using this locker
    for(new p = 0; p < MAX_PLAYERS; p++)
    {
        if(!IsPlayerConnected(p)) continue;
        if(PlayerInfo[p][pGoFoodOrderLocker] == idx)
        {
            new refund = GetGoFoodCartTotal(p);
            CancelGoFoodOrder(p);
            if(refund > 0)
            {
                PlayerInfo[p][pBank] += refund;
                LogBankTransaction(p, 0, "gofood_refund", refund, 0, PlayerInfo[p][pBank]);
                ShowGoFoodNotif(p, "~y~Go Food", "Loker dihapus admin. Refund ke M-Banking.");
            }
            ClearGoFoodCart(p);
        }
    }

    SendClientFormattedMessage(playerid, 0x00CC00FF, "[GoFood] Locker #%d (DB: %d) dihapus.", idx + 1, LockerData[idx][lkDBID]);

    // Shift array
    for(new j = idx; j < TotalLockers - 1; j++)
    {
        LockerData[j] = LockerData[j + 1];
        new lbl[48];
        format(lbl, sizeof(lbl), "Loker Go Food #%d", j + 1);
        Update3DTextLabelText(LockerData[j][lkLabelID], 0xFF6600FF, lbl);
    }
    TotalLockers--;

    for(new p = 0; p < MAX_PLAYERS; p++)
    {
        if(!IsPlayerConnected(p)) continue;
        if(PlayerInfo[p][pGoFoodOrderLocker] > idx)
            PlayerInfo[p][pGoFoodOrderLocker]--;
    }
    return true;
}

COMMAND:movelocker(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP) return SendClientFormattedMessage(playerid, COLOR_RED, "DevMap/Developer only."), true;

    new idx;
    if(sscanf(params, "d", idx)) return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /movelocker [nomor_loker]"), true;
    idx -= 1;
    if(idx < 0 || idx >= TotalLockers) return SendClientFormattedMessage(playerid, COLOR_RED, "Locker tidak ditemukan."), true;

    new Float:px, Float:py, Float:pz, Float:pa;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerFacingAngle(playerid, pa);

    LockerData[idx][lkX] = px;
    LockerData[idx][lkY] = py;
    LockerData[idx][lkZ] = pz;
    LockerData[idx][lkRotZ] = pa;

    SetDynamicObjectPos(LockerData[idx][lkObjectID], px, py, pz);
    SetDynamicObjectRot(LockerData[idx][lkObjectID], 0.0, 0.0, pa);
    Delete3DTextLabel(LockerData[idx][lkLabelID]);

    new lbl[48];
    format(lbl, sizeof(lbl), "Loker Go Food #%d", idx + 1);
    LockerData[idx][lkLabelID] = Create3DTextLabel(lbl, 0xFF6600FF, px, py, pz + 0.8, 15.0, 0);

    mysql_format(MySQL_C1, query, sizeof(query),
        "UPDATE `gofood_lockers` SET `x` = '%f', `y` = '%f', `z` = '%f', `rot_z` = '%f' WHERE `id` = '%d'",
        px, py, pz, pa, LockerData[idx][lkDBID]);
    mysql_function_query(MySQL_C1, query, false, "", "");

    SendClientFormattedMessage(playerid, 0x00CC00FF, "[GoFood] Locker #%d dipindahkan.", idx + 1);
    return true;
}

COMMAND:lockerlist(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP) return SendClientFormattedMessage(playerid, COLOR_RED, "DevMap/Developer only."), true;

    if(TotalLockers == 0) return SendClientFormattedMessage(playerid, COLOR_YELLOW, "[GoFood] Belum ada locker."), true;

    SendClientFormattedMessage(playerid, 0xFF6600FF, "=== Go Food Lockers (%d) ===", TotalLockers);
    for(new i = 0; i < TotalLockers; i++)
    {
        new cityname[16];
        if(LockerData[i][lkCity] == CITY_MEKAR_PURA) cityname = "MekarPura";
        else if(LockerData[i][lkCity] == CITY_MADYA_RAYA) cityname = "MadyaRaya";
        else cityname = "Mojosono";

        new status[16];
        if(LockerData[i][lkOccupied]) status = "{FF0000}Terisi";
        else status = "{00FF00}Kosong";

        SendClientFormattedMessage(playerid, -1, "#%d | %s | DB:%d | %s | %.1f, %.1f, %.1f",
            i + 1, cityname, LockerData[i][lkDBID], status,
            LockerData[i][lkX], LockerData[i][lkY], LockerData[i][lkZ]);
    }
    return true;
}

COMMAND:gotolocker(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP) return SendClientFormattedMessage(playerid, COLOR_RED, "DevMap/Developer only."), true;

    new idx;
    if(sscanf(params, "d", idx)) return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /gotolocker [nomor_loker]"), true;
    idx -= 1;
    if(idx < 0 || idx >= TotalLockers) return SendClientFormattedMessage(playerid, COLOR_RED, "Locker tidak ditemukan."), true;

    SetPlayerPos(playerid, LockerData[idx][lkX] + 1.5, LockerData[idx][lkY], LockerData[idx][lkZ] + 0.5);
    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, 0);
    SendClientFormattedMessage(playerid, 0x00CC00FF, "[GoFood] Teleport ke Locker #%d.", idx + 1);
    return true;
}
