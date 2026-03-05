// ============================================================================
// MODULE: inventory.pwn
// Inventory system: Kantong (5 slots) + Tas (15 slots, purchasable at shop)
// UI: TextDraw grid with 3D model previews, clickable slots
// Key: Y (KEY_YES) to open/close
// ============================================================================

// --- TextDraw storage arrays ---
new PlayerText:InvTD_BG[MAX_PLAYERS];
new PlayerText:InvTD_Title[MAX_PLAYERS];
new PlayerText:InvTD_TasLabel[MAX_PLAYERS];
new PlayerText:InvTD_ItemInfo[MAX_PLAYERS];
new PlayerText:InvTD_BtnAction[MAX_PLAYERS]; // Makan/Minum/Gunakan (contextual)
new PlayerText:InvTD_BtnGive[MAX_PLAYERS];   // Kasih ke Player
new PlayerText:InvTD_BtnDrop[MAX_PLAYERS];   // Buang
new PlayerText:InvTD_BtnClose[MAX_PLAYERS];  // Tutup

new PlayerText:InvTD_SlotBG[MAX_PLAYERS][MAX_INVENTORY_SLOTS];
new PlayerText:InvTD_SlotModel[MAX_PLAYERS][MAX_INVENTORY_SLOTS];
new PlayerText:InvTD_SlotQty[MAX_PLAYERS][MAX_INVENTORY_SLOTS];

// ============================================================================
// ITEM DATA HELPERS
// ============================================================================

stock GetItemTableIndex(itemid)
{
    for(new i = 0; i < sizeof(ItemTable); i++)
        if(ItemTable[i][itmID] == itemid) return i;
    return 0; // ITEM_NONE
}

// ============================================================================
// INVENTORY LOGIC
// ============================================================================

stock GetMaxSlots(playerid)
{
    return PlayerInfo[playerid][pHasTas] ? MAX_INVENTORY_SLOTS : MAX_KANTONG_SLOTS;
}

stock AddInventoryItem(playerid, itemid, amount = 1)
{
    if(itemid <= ITEM_NONE || itemid >= MAX_ITEM_TYPES) return 0;
    new idx = GetItemTableIndex(itemid);
    new maxstack = ItemTable[idx][itmMaxStack];
    new maxslots = GetMaxSlots(playerid);

    // First try to stack onto existing slots with same item
    for(new i = 0; i < maxslots; i++)
    {
        if(PlayerInfo[playerid][pInvItems][i] == itemid)
        {
            new space = maxstack - PlayerInfo[playerid][pInvAmounts][i];
            if(space > 0)
            {
                new add = (amount > space) ? space : amount;
                PlayerInfo[playerid][pInvAmounts][i] += add;
                amount -= add;
                if(amount <= 0) return 1;
            }
        }
    }

    // Then try empty slots for remaining
    for(new i = 0; i < maxslots; i++)
    {
        if(PlayerInfo[playerid][pInvItems][i] == ITEM_NONE)
        {
            new add = (amount > maxstack) ? maxstack : amount;
            PlayerInfo[playerid][pInvItems][i] = itemid;
            PlayerInfo[playerid][pInvAmounts][i] = add;
            amount -= add;
            if(amount <= 0) return 1;
        }
    }

    return (amount <= 0) ? 1 : 0;
}

stock RemoveInventoryItem(playerid, slot, amount = 1)
{
    if(slot < 0 || slot >= MAX_INVENTORY_SLOTS) return 0;
    if(PlayerInfo[playerid][pInvItems][slot] == ITEM_NONE) return 0;

    PlayerInfo[playerid][pInvAmounts][slot] -= amount;
    if(PlayerInfo[playerid][pInvAmounts][slot] <= 0)
    {
        PlayerInfo[playerid][pInvItems][slot] = ITEM_NONE;
        PlayerInfo[playerid][pInvAmounts][slot] = 0;
    }
    return 1;
}

stock UseInventoryItem(playerid, slot)
{
    if(slot < 0 || slot >= GetMaxSlots(playerid)) return 0;
    new itemid = PlayerInfo[playerid][pInvItems][slot];
    if(itemid == ITEM_NONE) return 0;

    new idx = GetItemTableIndex(itemid);
    new val = ItemTable[idx][itmValue];

    switch(ItemTable[idx][itmType])
    {
        case ITEM_TYPE_FOOD:
        {
            PlayerInfo[playerid][pHunger] += val;
            if(PlayerInfo[playerid][pHunger] > 100) PlayerInfo[playerid][pHunger] = 100;
            if(PlayerInfo[playerid][pHudCreated]) UpdateHungerBar(playerid);
            SendClientFormattedMessage(playerid, 0x33FF33FF, "Kamu memakan %s. Lapar +%d%%", ItemTable[idx][itmName], val);
        }
        case ITEM_TYPE_DRINK:
        {
            PlayerInfo[playerid][pThirst] += val;
            if(PlayerInfo[playerid][pThirst] > 100) PlayerInfo[playerid][pThirst] = 100;
            if(PlayerInfo[playerid][pHudCreated]) UpdateThirstBar(playerid);
            SendClientFormattedMessage(playerid, 0x33CCFFFF, "Kamu meminum %s. Haus +%d%%", ItemTable[idx][itmName], val);
        }
        case ITEM_TYPE_MEDICAL:
        {
            new Float:hp;
            GetPlayerHealth(playerid, hp);
            hp += float(val);
            if(hp > 100.0) hp = 100.0;
            SetPlayerHealth(playerid, hp);
            SendClientFormattedMessage(playerid, 0xFFFF00FF, "Kamu menggunakan %s. HP +%d", ItemTable[idx][itmName], val);
        }
        default:
        {
            SendClientFormattedMessage(playerid, -1, "Item ini tidak bisa digunakan.");
            return 0;
        }
    }

    RemoveInventoryItem(playerid, slot, 1);
    return 1;
}

stock GiveInventoryItem(playerid, slot)
{
    if(slot < 0 || slot >= GetMaxSlots(playerid)) return 0;
    new itemid = PlayerInfo[playerid][pInvItems][slot];
    if(itemid == ITEM_NONE) return 0;

    // Build list of nearby players within 5.0 range
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    new liststr[512];
    liststr[0] = EOS;
    new count = 0;

    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(i == playerid) continue;
        if(!IsPlayerConnected(i)) continue;
        if(!PlayerInfo[i][pLogged]) continue;

        new Float:tx, Float:ty, Float:tz;
        GetPlayerPos(i, tx, ty, tz);
        new Float:dist = floatsqroot((px-tx)*(px-tx) + (py-ty)*(py-ty) + (pz-tz)*(pz-tz));
        if(dist <= 5.0)
        {
            new tmp[64];
            format(tmp, sizeof(tmp), "%s (ID: %d) - %.1fm\n", PlayerName(i), i, dist);
            strcat(liststr, tmp, sizeof(liststr));
            count++;
        }
    }

    if(count == 0)
    {
        SendClientFormattedMessage(playerid, COLOR_YELLOW, "Tidak ada pemain di dekatmu (radius 5m)!");
        return 0;
    }

    // Save selected slot for later use
    PlayerInfo[playerid][pTempListingSlot] = slot;

    // Close inventory UI first, then show dialog
    CloseInventory(playerid);
    ShowPlayerDialog(playerid, DIALOG_INV_GIVE_LIST, DIALOG_STYLE_LIST,
        "{FFFFFF}Kasih Item ke Siapa?", liststr, "Kasih", "Batal");
    return 1;
}

stock ProcessGiveItem(playerid, listitem)
{
    new slot = PlayerInfo[playerid][pTempListingSlot];
    if(slot < 0 || PlayerInfo[playerid][pInvItems][slot] == ITEM_NONE) return 0;

    new itemid = PlayerInfo[playerid][pInvItems][slot];
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    // Rebuild nearby list to find target by listitem index
    new count = 0;
    new target = INVALID_PLAYER_ID;

    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(i == playerid) continue;
        if(!IsPlayerConnected(i)) continue;
        if(!PlayerInfo[i][pLogged]) continue;

        new Float:tx, Float:ty, Float:tz;
        GetPlayerPos(i, tx, ty, tz);
        new Float:dist = floatsqroot((px-tx)*(px-tx) + (py-ty)*(py-ty) + (pz-tz)*(pz-tz));
        if(dist <= 5.0)
        {
            if(count == listitem)
            {
                target = i;
                break;
            }
            count++;
        }
    }

    if(target == INVALID_PLAYER_ID)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Pemain tidak ditemukan atau sudah menjauh!");
        return 0;
    }

    new idx = GetItemTableIndex(itemid);
    if(!AddInventoryItem(target, itemid, 1))
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Kantong/Tas pemain tersebut penuh!");
        return 0;
    }

    RemoveInventoryItem(playerid, slot, 1);
    SendClientFormattedMessage(playerid, 0x33FF33FF, "Kamu memberikan %s kepada %s.", ItemTable[idx][itmName], PlayerName(target));
    SendClientFormattedMessage(target, 0x33FF33FF, "%s memberikanmu %s.", PlayerName(playerid), ItemTable[idx][itmName]);
    return 1;
}

// ============================================================================
// INVENTORY SERIALIZATION (for DB save/load)
// ============================================================================

stock SerializeInventory(playerid, output[], maxlen)
{
    output[0] = EOS;
    new tmp[12];
    for(new i = 0; i < MAX_INVENTORY_SLOTS; i++)
    {
        if(i > 0) strcat(output, ",", maxlen);
        format(tmp, sizeof(tmp), "%d:%d", PlayerInfo[playerid][pInvItems][i], PlayerInfo[playerid][pInvAmounts][i]);
        strcat(output, tmp, maxlen);
    }
}

stock DeserializeInventory(playerid, const input[])
{
    for(new i = 0; i < MAX_INVENTORY_SLOTS; i++)
    {
        PlayerInfo[playerid][pInvItems][i] = ITEM_NONE;
        PlayerInfo[playerid][pInvAmounts][i] = 0;
    }

    if(strlen(input) < 3) return;

    new slot = 0;
    new pos = 0;
    new len = strlen(input);

    while(pos < len && slot < MAX_INVENTORY_SLOTS)
    {
        new itemid = 0;
        while(pos < len && input[pos] != ':')
        {
            if(input[pos] >= '0' && input[pos] <= '9')
                itemid = itemid * 10 + (input[pos] - '0');
            pos++;
        }
        pos++;

        new amount = 0;
        while(pos < len && input[pos] != ',')
        {
            if(input[pos] >= '0' && input[pos] <= '9')
                amount = amount * 10 + (input[pos] - '0');
            pos++;
        }
        pos++;

        PlayerInfo[playerid][pInvItems][slot] = itemid;
        PlayerInfo[playerid][pInvAmounts][slot] = amount;
        slot++;
    }
}

// ============================================================================
// INVENTORY UI - TEXTDRAW GRID
// ============================================================================

stock Float:GetSlotXF(col)
{
    return INV_GRID_START_X + float(col) * (INV_SLOT_SIZE + INV_SLOT_GAP);
}

stock Float:GetSlotYF(row)
{
    switch(row)
    {
        case 0: return INV_ROW0_Y;
        case 1: return INV_ROW1_Y;
        case 2: return INV_ROW2_Y;
        case 3: return INV_ROW3_Y;
    }
    return INV_ROW0_Y;
}

stock OpenInventory(playerid)
{
    if(!PlayerInfo[playerid][pLogged] || PlayerInfo[playerid][pIsDead]) return 0;
    if(PlayerInfo[playerid][pInvOpen]) { CloseInventory(playerid); return 0; }

    PlayerInfo[playerid][pInvOpen] = true;
    PlayerInfo[playerid][pInvSelected] = -1;

    new bool:hasTas = PlayerInfo[playerid][pHasTas];
    new Float:panelH = hasTas ? INV_PANEL_H_TAS : INV_PANEL_H_NOTAS;

    // =============================================
    // LAYER 1: Background panel (created FIRST = behind)
    // =============================================
    InvTD_BG[playerid] = CreatePlayerTextDraw(playerid, INV_PANEL_X, INV_PANEL_Y, "_");
    PlayerTextDrawUseBox(playerid, InvTD_BG[playerid], 1);
    PlayerTextDrawBoxColor(playerid, InvTD_BG[playerid], INV_COLOR_PANEL);
    PlayerTextDrawTextSize(playerid, InvTD_BG[playerid], INV_PANEL_X_END, 0.0);
    PlayerTextDrawLetterSize(playerid, InvTD_BG[playerid], 0.0, panelH);
    PlayerTextDrawColor(playerid, InvTD_BG[playerid], 0);
    PlayerTextDrawSetShadow(playerid, InvTD_BG[playerid], 0);
    PlayerTextDrawShow(playerid, InvTD_BG[playerid]);

    // =============================================
    // LAYER 2: Title
    // =============================================
    new titlestr[64];
    new kantongUsed = 0;
    for(new i = 0; i < MAX_KANTONG_SLOTS; i++)
        if(PlayerInfo[playerid][pInvItems][i] != ITEM_NONE) kantongUsed++;
    format(titlestr, sizeof(titlestr), "KANTONG (%d/%d)", kantongUsed, MAX_KANTONG_SLOTS);

    InvTD_Title[playerid] = CreatePlayerTextDraw(playerid, INV_PANEL_X + 10.0, INV_TITLE_Y, titlestr);
    PlayerTextDrawFont(playerid, InvTD_Title[playerid], 2);
    PlayerTextDrawLetterSize(playerid, InvTD_Title[playerid], 0.25, 1.2);
    PlayerTextDrawColor(playerid, InvTD_Title[playerid], INV_COLOR_TITLE);
    PlayerTextDrawSetOutline(playerid, InvTD_Title[playerid], 1);
    PlayerTextDrawShow(playerid, InvTD_Title[playerid]);

    // =============================================
    // LAYER 3: Kantong Slots (Row 0, 5 slots)
    // =============================================
    for(new i = 0; i < MAX_KANTONG_SLOTS; i++)
    {
        CreateInventorySlotTD(playerid, i, 0, i);
    }

    // =============================================
    // LAYER 4: Tas section
    // =============================================
    if(hasTas)
    {
        new tasUsed = 0;
        for(new i = MAX_KANTONG_SLOTS; i < MAX_INVENTORY_SLOTS; i++)
            if(PlayerInfo[playerid][pInvItems][i] != ITEM_NONE) tasUsed++;
        new taslabel[64];
        format(taslabel, sizeof(taslabel), "TAS (%d/%d)", tasUsed, MAX_TAS_SLOTS);

        InvTD_TasLabel[playerid] = CreatePlayerTextDraw(playerid, INV_PANEL_X + 10.0, INV_TAS_LABEL_Y, taslabel);
        PlayerTextDrawFont(playerid, InvTD_TasLabel[playerid], 2);
        PlayerTextDrawLetterSize(playerid, InvTD_TasLabel[playerid], 0.25, 1.2);
        PlayerTextDrawColor(playerid, InvTD_TasLabel[playerid], INV_COLOR_TITLE);
        PlayerTextDrawSetOutline(playerid, InvTD_TasLabel[playerid], 1);
        PlayerTextDrawShow(playerid, InvTD_TasLabel[playerid]);

        for(new i = 0; i < MAX_TAS_SLOTS; i++)
        {
            new row = 1 + (i / 5);
            new col = i % 5;
            CreateInventorySlotTD(playerid, MAX_KANTONG_SLOTS + i, row, col);
        }
    }
    else
    {
        InvTD_TasLabel[playerid] = CreatePlayerTextDraw(playerid, INV_PANEL_X + 10.0,
            INV_ROW0_Y + INV_SLOT_SIZE + 5.0, "Tas belum dimiliki. Beli di toko!");
        PlayerTextDrawFont(playerid, InvTD_TasLabel[playerid], 1);
        PlayerTextDrawLetterSize(playerid, InvTD_TasLabel[playerid], 0.18, 0.9);
        PlayerTextDrawColor(playerid, InvTD_TasLabel[playerid], 0x888888FF);
        PlayerTextDrawSetOutline(playerid, InvTD_TasLabel[playerid], 0);
        PlayerTextDrawSetShadow(playerid, InvTD_TasLabel[playerid], 1);
        PlayerTextDrawShow(playerid, InvTD_TasLabel[playerid]);
    }

    // =============================================
    // LAYER 5: Info + buttons (created LAST = on TOP)
    // =============================================
    new Float:infoY = hasTas ? INV_INFO_Y_TAS : INV_INFO_Y_NOTAS;
    InvTD_ItemInfo[playerid] = CreatePlayerTextDraw(playerid, INV_PANEL_X + 10.0, infoY, "Klik slot untuk melihat item.");
    PlayerTextDrawFont(playerid, InvTD_ItemInfo[playerid], 1);
    PlayerTextDrawLetterSize(playerid, InvTD_ItemInfo[playerid], 0.2, 0.9);
    PlayerTextDrawColor(playerid, InvTD_ItemInfo[playerid], 0xCCCCCCFF);
    PlayerTextDrawSetOutline(playerid, InvTD_ItemInfo[playerid], 0);
    PlayerTextDrawSetShadow(playerid, InvTD_ItemInfo[playerid], 1);
    PlayerTextDrawShow(playerid, InvTD_ItemInfo[playerid]);

    // --- Buttons (created last = highest z-order) ---
    new Float:btnY = hasTas ? INV_BTN_Y_TAS : INV_BTN_Y_NOTAS;
    new Float:btnW = 65.0;
    new Float:btnGap = 6.0;
    new Float:btnStartX = INV_PANEL_X + 15.0;

    // Action button (Makan/Minum/Gunakan - contextual)
    InvTD_BtnAction[playerid] = CreatePlayerTextDraw(playerid, btnStartX + btnW/2.0, btnY, "Gunakan");
    PlayerTextDrawUseBox(playerid, InvTD_BtnAction[playerid], 1);
    PlayerTextDrawBoxColor(playerid, InvTD_BtnAction[playerid], 0x336633CC);
    PlayerTextDrawAlignment(playerid, InvTD_BtnAction[playerid], 2);
    PlayerTextDrawTextSize(playerid, InvTD_BtnAction[playerid], 12.0, btnW);
    PlayerTextDrawFont(playerid, InvTD_BtnAction[playerid], 1);
    PlayerTextDrawLetterSize(playerid, InvTD_BtnAction[playerid], 0.20, 1.0);
    PlayerTextDrawColor(playerid, InvTD_BtnAction[playerid], 0x66FF66FF);
    PlayerTextDrawSetShadow(playerid, InvTD_BtnAction[playerid], 0);
    PlayerTextDrawSetSelectable(playerid, InvTD_BtnAction[playerid], 1);
    PlayerTextDrawShow(playerid, InvTD_BtnAction[playerid]);

    // Give button (Kasih ke Player)
    new Float:giveX = btnStartX + btnW + btnGap + btnW/2.0;
    InvTD_BtnGive[playerid] = CreatePlayerTextDraw(playerid, giveX, btnY, "Kasih");
    PlayerTextDrawUseBox(playerid, InvTD_BtnGive[playerid], 1);
    PlayerTextDrawBoxColor(playerid, InvTD_BtnGive[playerid], 0x335588CC);
    PlayerTextDrawAlignment(playerid, InvTD_BtnGive[playerid], 2);
    PlayerTextDrawTextSize(playerid, InvTD_BtnGive[playerid], 12.0, btnW);
    PlayerTextDrawFont(playerid, InvTD_BtnGive[playerid], 1);
    PlayerTextDrawLetterSize(playerid, InvTD_BtnGive[playerid], 0.20, 1.0);
    PlayerTextDrawColor(playerid, InvTD_BtnGive[playerid], 0x88CCFFFF);
    PlayerTextDrawSetShadow(playerid, InvTD_BtnGive[playerid], 0);
    PlayerTextDrawSetSelectable(playerid, InvTD_BtnGive[playerid], 1);
    PlayerTextDrawShow(playerid, InvTD_BtnGive[playerid]);

    // Drop button (Buang)
    new Float:dropX = btnStartX + 2.0*(btnW + btnGap) + btnW/2.0;
    InvTD_BtnDrop[playerid] = CreatePlayerTextDraw(playerid, dropX, btnY, "Buang");
    PlayerTextDrawUseBox(playerid, InvTD_BtnDrop[playerid], 1);
    PlayerTextDrawBoxColor(playerid, InvTD_BtnDrop[playerid], 0x663333CC);
    PlayerTextDrawAlignment(playerid, InvTD_BtnDrop[playerid], 2);
    PlayerTextDrawTextSize(playerid, InvTD_BtnDrop[playerid], 12.0, btnW);
    PlayerTextDrawFont(playerid, InvTD_BtnDrop[playerid], 1);
    PlayerTextDrawLetterSize(playerid, InvTD_BtnDrop[playerid], 0.20, 1.0);
    PlayerTextDrawColor(playerid, InvTD_BtnDrop[playerid], 0xFF6666FF);
    PlayerTextDrawSetShadow(playerid, InvTD_BtnDrop[playerid], 0);
    PlayerTextDrawSetSelectable(playerid, InvTD_BtnDrop[playerid], 1);
    PlayerTextDrawShow(playerid, InvTD_BtnDrop[playerid]);

    // Close button (Tutup)
    new Float:closeX = btnStartX + 3.0*(btnW + btnGap) + btnW/2.0;
    InvTD_BtnClose[playerid] = CreatePlayerTextDraw(playerid, closeX, btnY, "Tutup");
    PlayerTextDrawUseBox(playerid, InvTD_BtnClose[playerid], 1);
    PlayerTextDrawBoxColor(playerid, InvTD_BtnClose[playerid], INV_COLOR_BTN);
    PlayerTextDrawAlignment(playerid, InvTD_BtnClose[playerid], 2);
    PlayerTextDrawTextSize(playerid, InvTD_BtnClose[playerid], 12.0, btnW);
    PlayerTextDrawFont(playerid, InvTD_BtnClose[playerid], 1);
    PlayerTextDrawLetterSize(playerid, InvTD_BtnClose[playerid], 0.20, 1.0);
    PlayerTextDrawColor(playerid, InvTD_BtnClose[playerid], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, InvTD_BtnClose[playerid], 0);
    PlayerTextDrawSetSelectable(playerid, InvTD_BtnClose[playerid], 1);
    PlayerTextDrawShow(playerid, InvTD_BtnClose[playerid]);

    // Enable mouse cursor for clicking
    SelectTextDraw(playerid, INV_COLOR_HIGHLIGHT);
    return 1;
}

stock CreateInventorySlotTD(playerid, slot, row, col)
{
    new Float:sx = GetSlotXF(col);
    new Float:sy = GetSlotYF(row);
    new itemid = PlayerInfo[playerid][pInvItems][slot];
    new amount = PlayerInfo[playerid][pInvAmounts][slot];

    new boxcolor = (itemid != ITEM_NONE) ? INV_COLOR_SLOT_FILLED : INV_COLOR_SLOT_EMPTY;

    // Slot background (clickable)
    InvTD_SlotBG[playerid][slot] = CreatePlayerTextDraw(playerid, sx, sy, "_");
    PlayerTextDrawUseBox(playerid, InvTD_SlotBG[playerid][slot], 1);
    PlayerTextDrawBoxColor(playerid, InvTD_SlotBG[playerid][slot], boxcolor);
    PlayerTextDrawTextSize(playerid, InvTD_SlotBG[playerid][slot], sx + INV_SLOT_SIZE, 0.0);
    PlayerTextDrawLetterSize(playerid, InvTD_SlotBG[playerid][slot], 0.0, 3.7);
    PlayerTextDrawColor(playerid, InvTD_SlotBG[playerid][slot], 0);
    PlayerTextDrawSetShadow(playerid, InvTD_SlotBG[playerid][slot], 0);
    PlayerTextDrawSetSelectable(playerid, InvTD_SlotBG[playerid][slot], 1);
    PlayerTextDrawShow(playerid, InvTD_SlotBG[playerid][slot]);

    // Model preview (non-clickable, on top of slot bg)
    if(itemid != ITEM_NONE)
    {
        new idx = GetItemTableIndex(itemid);
        InvTD_SlotModel[playerid][slot] = CreatePlayerTextDraw(playerid, sx + 2.0, sy + 1.0, "");
        PlayerTextDrawFont(playerid, InvTD_SlotModel[playerid][slot], 5);
        PlayerTextDrawTextSize(playerid, InvTD_SlotModel[playerid][slot], INV_SLOT_SIZE - 4.0, INV_SLOT_SIZE - 8.0);
        PlayerTextDrawSetPreviewModel(playerid, InvTD_SlotModel[playerid][slot], ItemTable[idx][itmModel]);
        PlayerTextDrawSetPreviewRot(playerid, InvTD_SlotModel[playerid][slot], -16.0, 0.0, -55.0, 1.0);
        PlayerTextDrawBackgroundColor(playerid, InvTD_SlotModel[playerid][slot], 0x00000033);
        PlayerTextDrawColor(playerid, InvTD_SlotModel[playerid][slot], 0xFFFFFFFF);
        PlayerTextDrawSetSelectable(playerid, InvTD_SlotModel[playerid][slot], 0);
        PlayerTextDrawShow(playerid, InvTD_SlotModel[playerid][slot]);

        if(amount > 1)
        {
            new qtystr[8];
            format(qtystr, sizeof(qtystr), "x%d", amount);
            InvTD_SlotQty[playerid][slot] = CreatePlayerTextDraw(playerid, sx + INV_SLOT_SIZE - 3.0, sy + INV_SLOT_SIZE - 14.0, qtystr);
            PlayerTextDrawFont(playerid, InvTD_SlotQty[playerid][slot], 1);
            PlayerTextDrawLetterSize(playerid, InvTD_SlotQty[playerid][slot], 0.15, 0.7);
            PlayerTextDrawColor(playerid, InvTD_SlotQty[playerid][slot], 0xFFFFFFFF);
            PlayerTextDrawAlignment(playerid, InvTD_SlotQty[playerid][slot], 3);
            PlayerTextDrawSetOutline(playerid, InvTD_SlotQty[playerid][slot], 1);
            PlayerTextDrawSetSelectable(playerid, InvTD_SlotQty[playerid][slot], 0);
            PlayerTextDrawShow(playerid, InvTD_SlotQty[playerid][slot]);
        }
        else
        {
            InvTD_SlotQty[playerid][slot] = INVALID_PLAYER_TD;
        }
    }
    else
    {
        InvTD_SlotModel[playerid][slot] = INVALID_PLAYER_TD;
        InvTD_SlotQty[playerid][slot] = INVALID_PLAYER_TD;
    }
}

stock CloseInventory(playerid)
{
    if(!PlayerInfo[playerid][pInvOpen]) return 0;

    for(new i = 0; i < MAX_INVENTORY_SLOTS; i++)
    {
        if(InvTD_SlotBG[playerid][i] != INVALID_PLAYER_TD)
            PlayerTextDrawDestroy(playerid, InvTD_SlotBG[playerid][i]);
        if(InvTD_SlotModel[playerid][i] != INVALID_PLAYER_TD)
            PlayerTextDrawDestroy(playerid, InvTD_SlotModel[playerid][i]);
        if(InvTD_SlotQty[playerid][i] != INVALID_PLAYER_TD)
            PlayerTextDrawDestroy(playerid, InvTD_SlotQty[playerid][i]);
        InvTD_SlotBG[playerid][i] = INVALID_PLAYER_TD;
        InvTD_SlotModel[playerid][i] = INVALID_PLAYER_TD;
        InvTD_SlotQty[playerid][i] = INVALID_PLAYER_TD;
    }

    if(InvTD_BG[playerid] != INVALID_PLAYER_TD)
        PlayerTextDrawDestroy(playerid, InvTD_BG[playerid]);
    if(InvTD_Title[playerid] != INVALID_PLAYER_TD)
        PlayerTextDrawDestroy(playerid, InvTD_Title[playerid]);
    if(InvTD_TasLabel[playerid] != INVALID_PLAYER_TD)
        PlayerTextDrawDestroy(playerid, InvTD_TasLabel[playerid]);
    if(InvTD_ItemInfo[playerid] != INVALID_PLAYER_TD)
        PlayerTextDrawDestroy(playerid, InvTD_ItemInfo[playerid]);
    if(InvTD_BtnAction[playerid] != INVALID_PLAYER_TD)
        PlayerTextDrawDestroy(playerid, InvTD_BtnAction[playerid]);
    if(InvTD_BtnGive[playerid] != INVALID_PLAYER_TD)
        PlayerTextDrawDestroy(playerid, InvTD_BtnGive[playerid]);
    if(InvTD_BtnDrop[playerid] != INVALID_PLAYER_TD)
        PlayerTextDrawDestroy(playerid, InvTD_BtnDrop[playerid]);
    if(InvTD_BtnClose[playerid] != INVALID_PLAYER_TD)
        PlayerTextDrawDestroy(playerid, InvTD_BtnClose[playerid]);

    InvTD_BG[playerid] = INVALID_PLAYER_TD;
    InvTD_Title[playerid] = INVALID_PLAYER_TD;
    InvTD_TasLabel[playerid] = INVALID_PLAYER_TD;
    InvTD_ItemInfo[playerid] = INVALID_PLAYER_TD;
    InvTD_BtnAction[playerid] = INVALID_PLAYER_TD;
    InvTD_BtnGive[playerid] = INVALID_PLAYER_TD;
    InvTD_BtnDrop[playerid] = INVALID_PLAYER_TD;
    InvTD_BtnClose[playerid] = INVALID_PLAYER_TD;

    PlayerInfo[playerid][pInvOpen] = false;
    PlayerInfo[playerid][pInvSelected] = -1;

    CancelSelectTextDraw(playerid);
    return 1;
}

stock ResetInventoryTDs(playerid)
{
    for(new i = 0; i < MAX_INVENTORY_SLOTS; i++)
    {
        InvTD_SlotBG[playerid][i] = INVALID_PLAYER_TD;
        InvTD_SlotModel[playerid][i] = INVALID_PLAYER_TD;
        InvTD_SlotQty[playerid][i] = INVALID_PLAYER_TD;
    }
    InvTD_BG[playerid] = INVALID_PLAYER_TD;
    InvTD_Title[playerid] = INVALID_PLAYER_TD;
    InvTD_TasLabel[playerid] = INVALID_PLAYER_TD;
    InvTD_ItemInfo[playerid] = INVALID_PLAYER_TD;
    InvTD_BtnAction[playerid] = INVALID_PLAYER_TD;
    InvTD_BtnGive[playerid] = INVALID_PLAYER_TD;
    InvTD_BtnDrop[playerid] = INVALID_PLAYER_TD;
    InvTD_BtnClose[playerid] = INVALID_PLAYER_TD;
}

stock HandleInventoryKey(playerid)
{
    if(!PlayerInfo[playerid][pLogged] || PlayerInfo[playerid][pIsDead]) return 0;

    if(PlayerInfo[playerid][pInvOpen])
        CloseInventory(playerid);
    else
        OpenInventory(playerid);
    return 1;
}

// ============================================================================
// HANDLE CLICK ON PLAYER TEXTDRAW
// ============================================================================

stock HandleInventoryClick(playerid, PlayerText:playertextid)
{
    if(!PlayerInfo[playerid][pInvOpen]) return 0;

    // --- Close button ---
    if(playertextid == InvTD_BtnClose[playerid])
    {
        CloseInventory(playerid);
        return 1;
    }

    // --- Action button (Makan/Minum/Gunakan) ---
    if(playertextid == InvTD_BtnAction[playerid])
    {
        new sel = PlayerInfo[playerid][pInvSelected];
        if(sel >= 0 && PlayerInfo[playerid][pInvItems][sel] != ITEM_NONE)
        {
            UseInventoryItem(playerid, sel);
            CloseInventory(playerid);
            OpenInventory(playerid);
        }
        else
        {
            SendClientFormattedMessage(playerid, COLOR_YELLOW, "Pilih slot item terlebih dahulu!");
            SelectTextDraw(playerid, INV_COLOR_HIGHLIGHT);
        }
        return 1;
    }

    // --- Give button (Kasih ke Player) ---
    if(playertextid == InvTD_BtnGive[playerid])
    {
        new sel = PlayerInfo[playerid][pInvSelected];
        if(sel >= 0 && PlayerInfo[playerid][pInvItems][sel] != ITEM_NONE)
        {
            GiveInventoryItem(playerid, sel);
            // Dialog will handle the rest, inventory already closed by GiveInventoryItem
        }
        else
        {
            SendClientFormattedMessage(playerid, COLOR_YELLOW, "Pilih slot item terlebih dahulu!");
            SelectTextDraw(playerid, INV_COLOR_HIGHLIGHT);
        }
        return 1;
    }

    // --- Drop button (Buang) ---
    if(playertextid == InvTD_BtnDrop[playerid])
    {
        new sel = PlayerInfo[playerid][pInvSelected];
        if(sel >= 0 && PlayerInfo[playerid][pInvItems][sel] != ITEM_NONE)
        {
            new idx = GetItemTableIndex(PlayerInfo[playerid][pInvItems][sel]);
            SendClientFormattedMessage(playerid, 0xFF8800FF, "Kamu membuang 1x %s.", ItemTable[idx][itmName]);
            RemoveInventoryItem(playerid, sel, 1);
            CloseInventory(playerid);
            OpenInventory(playerid);
        }
        else
        {
            SendClientFormattedMessage(playerid, COLOR_YELLOW, "Pilih slot item terlebih dahulu!");
            SelectTextDraw(playerid, INV_COLOR_HIGHLIGHT);
        }
        return 1;
    }

    // --- Slot clicks ---
    new maxslots = GetMaxSlots(playerid);
    for(new i = 0; i < maxslots; i++)
    {
        if(playertextid == InvTD_SlotBG[playerid][i])
        {
            SelectInventorySlot(playerid, i);
            SelectTextDraw(playerid, INV_COLOR_HIGHLIGHT);
            return 1;
        }
    }

    return 0;
}

stock SelectInventorySlot(playerid, slot)
{
    new oldsel = PlayerInfo[playerid][pInvSelected];

    // Deselect old slot
    if(oldsel >= 0 && InvTD_SlotBG[playerid][oldsel] != INVALID_PLAYER_TD)
    {
        new oldcolor = (PlayerInfo[playerid][pInvItems][oldsel] != ITEM_NONE) ? INV_COLOR_SLOT_FILLED : INV_COLOR_SLOT_EMPTY;
        PlayerTextDrawBoxColor(playerid, InvTD_SlotBG[playerid][oldsel], oldcolor);
        PlayerTextDrawShow(playerid, InvTD_SlotBG[playerid][oldsel]);
    }

    PlayerInfo[playerid][pInvSelected] = slot;

    // Highlight new slot
    if(InvTD_SlotBG[playerid][slot] != INVALID_PLAYER_TD)
    {
        PlayerTextDrawBoxColor(playerid, InvTD_SlotBG[playerid][slot], INV_COLOR_SLOT_SELECTED);
        PlayerTextDrawShow(playerid, InvTD_SlotBG[playerid][slot]);
    }

    // Update info text & contextual action button
    new itemid = PlayerInfo[playerid][pInvItems][slot];
    if(itemid != ITEM_NONE)
    {
        new idx = GetItemTableIndex(itemid);
        new infostr[64];
        new typestr[16];
        new actionstr[16];

        switch(ItemTable[idx][itmType])
        {
            case ITEM_TYPE_FOOD:
            {
                typestr = "Makanan";
                actionstr = "Makan";
            }
            case ITEM_TYPE_DRINK:
            {
                typestr = "Minuman";
                actionstr = "Minum";
            }
            case ITEM_TYPE_MEDICAL:
            {
                typestr = "Medis";
                actionstr = "Gunakan";
            }
            default:
            {
                typestr = "Lainnya";
                actionstr = "Gunakan";
            }
        }

        format(infostr, sizeof(infostr), "%s (%s) x%d", ItemTable[idx][itmName], typestr, PlayerInfo[playerid][pInvAmounts][slot]);
        PlayerTextDrawSetString(playerid, InvTD_ItemInfo[playerid], infostr);

        // Change action button text contextually
        PlayerTextDrawSetString(playerid, InvTD_BtnAction[playerid], actionstr);
    }
    else
    {
        PlayerTextDrawSetString(playerid, InvTD_ItemInfo[playerid], "Slot kosong.");
        PlayerTextDrawSetString(playerid, InvTD_BtnAction[playerid], "Gunakan");
    }
}

// ============================================================================
// HANDLE ESC
// ============================================================================

stock HandleInventoryEsc(playerid)
{
    if(PlayerInfo[playerid][pInvOpen])
    {
        CloseInventory(playerid);
        return 1;
    }
    return 0;
}

// ============================================================================
// COMMANDS
// ============================================================================

COMMAND:inv(playerid, params[])
{
    HandleInventoryKey(playerid);
    return true;
}
