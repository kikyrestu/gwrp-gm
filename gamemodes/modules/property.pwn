// ============================================================================
// MODULE: property.pwn
// Property System — Apartemen, Kostan, Gudang, Ruko/Biz, Tanah
// Features: rent/buy, key system, storage, lock, VA payment, spawn
// ============================================================================

// ============================================================================
// DEFINES
// ============================================================================

#define MAX_PROPERTIES          200
#define MAX_PROP_STORAGE        50
#define MAX_PROP_KEYS           5

#define PROP_APARTEMEN          1
#define PROP_KOSTAN             2
#define PROP_GUDANG             3
#define PROP_RUKO               4
#define PROP_TANAH              5

#define COLOR_PROP              0x33CCFFFF  // property cyan
#define COLOR_PROP_INFO         0x00CC66FF  // property green

// Dialog IDs (230+)
#define DIALOG_PROP_MENU        230
#define DIALOG_PROP_RENT        231
#define DIALOG_PROP_BUY         232
#define DIALOG_PROP_MANAGE      233
#define DIALOG_PROP_STORAGE     234
#define DIALOG_PROP_STORE_ITEM  235
#define DIALOG_PROP_TAKE_ITEM   236
#define DIALOG_PROP_KEYS        237
#define DIALOG_PROP_KEY_ADD     238
#define DIALOG_PROP_KEY_REMOVE  239

// Admin dialogs
#define DIALOG_PROP_CREATE_TYPE 240
#define DIALOG_PROP_CREATE_NAME 241
#define DIALOG_PROP_CREATE_PRICE 242

// ============================================================================
// PROPERTY DATA (loaded from DB)
// ============================================================================

enum ePropertyData {
    propID,
    propName[64],
    propType,                   // PROP_*
    propOwnerID,
    propOwnerName[32],
    propPrice,
    propRentPrice,
    propRentDue[20],            // timestamp string
    Float:propEntryX,
    Float:propEntryY,
    Float:propEntryZ,
    Float:propEntryAngle,
    Float:propExitX,
    Float:propExitY,
    Float:propExitZ,
    Float:propExitAngle,
    propInterior,
    propVW,
    bool:propLocked,
    propStorageSlots,
    bool:propHasNIB,
    // Runtime
    Text3D:propEntryLabel,
    propEntryPickup
};
new PropertyData[MAX_PROPERTIES][ePropertyData];
new TotalProperties = 0;

// Storage items (loaded per-property on demand)
enum ePropStorageItem {
    psDBID,
    psPropID,
    psItemID,
    psAmount
};

// Player property tracking
new pCurrentProperty[MAX_PLAYERS];        // property index player is inside (-1 = none)
new pOwnedPropertyID[MAX_PLAYERS];        // property DB id the player owns (0 = none)
new pTempPropIdx[MAX_PLAYERS];            // temp for dialogs

// Temp storage for viewing storage (per-player to avoid async race)
new PropStorageItems[MAX_PLAYERS][MAX_PROP_STORAGE][ePropStorageItem];
new PropStorageCount[MAX_PLAYERS];

// Temp for property creation
new pTempPropType[MAX_PLAYERS];
new pTempPropName[MAX_PLAYERS][64];

// ============================================================================
// LOAD PROPERTIES
// ============================================================================

stock LoadProperties()
{
    format(query, sizeof(query), "SELECT * FROM properties ORDER BY id");
    mysql_function_query(MySQL_C1, query, true, "OnPropertiesLoaded", "");
}

publics: OnPropertiesLoaded()
{
    new rows, fields;
    cache_get_data(rows, fields);
    TotalProperties = 0;

    for(new i = 0; i < rows && i < MAX_PROPERTIES; i++)
    {
        PropertyData[i][propID] = cache_get_field_content_int(i, "id", MySQL_C1);
        cache_get_field_content(i, "name", PropertyData[i][propName], MySQL_C1, 64);
        PropertyData[i][propType] = cache_get_field_content_int(i, "type", MySQL_C1);
        PropertyData[i][propOwnerID] = cache_get_field_content_int(i, "owner_id", MySQL_C1);
        cache_get_field_content(i, "owner_name", PropertyData[i][propOwnerName], MySQL_C1, 32);
        PropertyData[i][propPrice] = cache_get_field_content_int(i, "price", MySQL_C1);
        PropertyData[i][propRentPrice] = cache_get_field_content_int(i, "rent_price", MySQL_C1);
        cache_get_field_content(i, "rent_due_date", PropertyData[i][propRentDue], MySQL_C1, 20);
        PropertyData[i][propEntryX] = cache_get_field_content_float(i, "entry_x", MySQL_C1);
        PropertyData[i][propEntryY] = cache_get_field_content_float(i, "entry_y", MySQL_C1);
        PropertyData[i][propEntryZ] = cache_get_field_content_float(i, "entry_z", MySQL_C1);
        PropertyData[i][propEntryAngle] = cache_get_field_content_float(i, "entry_angle", MySQL_C1);
        PropertyData[i][propExitX] = cache_get_field_content_float(i, "exit_x", MySQL_C1);
        PropertyData[i][propExitY] = cache_get_field_content_float(i, "exit_y", MySQL_C1);
        PropertyData[i][propExitZ] = cache_get_field_content_float(i, "exit_z", MySQL_C1);
        PropertyData[i][propExitAngle] = cache_get_field_content_float(i, "exit_angle", MySQL_C1);
        PropertyData[i][propInterior] = cache_get_field_content_int(i, "interior", MySQL_C1);
        PropertyData[i][propVW] = cache_get_field_content_int(i, "vw", MySQL_C1);
        PropertyData[i][propLocked] = bool:cache_get_field_content_int(i, "locked", MySQL_C1);
        PropertyData[i][propStorageSlots] = cache_get_field_content_int(i, "storage_slots", MySQL_C1);
        PropertyData[i][propHasNIB] = bool:cache_get_field_content_int(i, "has_nib", MySQL_C1);

        // Create entry label & pickup
        CreatePropertyMarker(i);
        TotalProperties++;
    }
    printf("[Property] Loaded: %d properties.", TotalProperties);
    return 1;
}

stock CreatePropertyMarker(idx)
{
    if(PropertyData[idx][propEntryX] == 0.0 && PropertyData[idx][propEntryY] == 0.0) return;

    new label[128], typeStr[16];
    GetPropertyTypeName(PropertyData[idx][propType], typeStr, sizeof(typeStr));

    if(PropertyData[idx][propOwnerID] > 0)
    {
        format(label, sizeof(label), "{33CCFF}[%s] %s\n{FFFFFF}Pemilik: %s\n%s",
            typeStr, PropertyData[idx][propName],
            PropertyData[idx][propOwnerName],
            PropertyData[idx][propLocked] ? ("{FF0000}Terkunci") : ("{00FF00}Terbuka"));
    }
    else
    {
        format(label, sizeof(label), "{33CCFF}[%s] %s\n{FFFF00}DIJUAL / DISEWA\n{FFFFFF}Harga: $%d | Sewa: $%d/bulan",
            typeStr, PropertyData[idx][propName],
            PropertyData[idx][propPrice], PropertyData[idx][propRentPrice]);
    }

    PropertyData[idx][propEntryLabel] = Create3DTextLabel(label, 0x33CCFFFF,
        PropertyData[idx][propEntryX], PropertyData[idx][propEntryY],
        PropertyData[idx][propEntryZ] + 0.5, 15.0, 0, 1);

    PropertyData[idx][propEntryPickup] = CreatePickup(1239, 23,
        PropertyData[idx][propEntryX], PropertyData[idx][propEntryY],
        PropertyData[idx][propEntryZ], -1);
}

stock RefreshPropertyLabel(idx)
{
    if(PropertyData[idx][propEntryLabel] != Text3D:INVALID_3DTEXT_ID)
        Delete3DTextLabel(PropertyData[idx][propEntryLabel]);
    if(PropertyData[idx][propEntryPickup] != -1)
        DestroyPickup(PropertyData[idx][propEntryPickup]);

    CreatePropertyMarker(idx);
}

stock GetPropertyTypeName(type, output[], maxlen)
{
    switch(type)
    {
        case PROP_APARTEMEN: strmid(output, "Apartemen", 0, 10, maxlen);
        case PROP_KOSTAN:    strmid(output, "Kostan", 0, 7, maxlen);
        case PROP_GUDANG:    strmid(output, "Gudang", 0, 7, maxlen);
        case PROP_RUKO:      strmid(output, "Ruko", 0, 5, maxlen);
        case PROP_TANAH:     strmid(output, "Tanah", 0, 6, maxlen);
        default:             strmid(output, "Properti", 0, 9, maxlen);
    }
}

// ============================================================================
// UTILITY
// ============================================================================

stock GetNearestProperty(playerid)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    for(new i = 0; i < TotalProperties; i++)
    {
        new Float:dist = floatsqroot(
            (px - PropertyData[i][propEntryX]) * (px - PropertyData[i][propEntryX]) +
            (py - PropertyData[i][propEntryY]) * (py - PropertyData[i][propEntryY]) +
            (pz - PropertyData[i][propEntryZ]) * (pz - PropertyData[i][propEntryZ])
        );
        if(dist < 3.0) return i;
    }
    return -1;
}

stock GetPlayerPropertyIndex(playerid)
{
    if(pOwnedPropertyID[playerid] <= 0) return -1;
    for(new i = 0; i < TotalProperties; i++)
    {
        if(PropertyData[i][propID] == pOwnedPropertyID[playerid]) return i;
    }
    return -1;
}

stock PlayerHasKey(playerid, propIdx)
{
    // Owner always has key
    if(PropertyData[propIdx][propOwnerID] == PlayerInfo[playerid][pID]) return 1;

    // Check key table (runtime check via DB)
    // For quick check, we'd need a cache, but for now just check ownership
    return 0;
}

stock SaveProperty(idx)
{
    mysql_format(MySQL_C1, query, sizeof(query),
        "UPDATE properties SET owner_id='%d', owner_name='%e', locked='%d', \
has_nib='%d' WHERE id='%d'",
        PropertyData[idx][propOwnerID], PropertyData[idx][propOwnerName],
        PropertyData[idx][propLocked] ? 1 : 0,
        PropertyData[idx][propHasNIB] ? 1 : 0,
        PropertyData[idx][propID]);
    mysql_function_query(MySQL_C1, query, false, "", "");
}

stock LoadPlayerProperty(playerid)
{
    pOwnedPropertyID[playerid] = 0;
    pCurrentProperty[playerid] = -1;

    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT id FROM properties WHERE owner_id = '%d' LIMIT 1",
        PlayerInfo[playerid][pID]);
    mysql_function_query(MySQL_C1, query, true, "OnPlayerPropertyLoaded", "d", playerid);
}

publics: OnPlayerPropertyLoaded(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);
    if(!rows) return 1;

    pOwnedPropertyID[playerid] = cache_get_field_content_int(0, "id", MySQL_C1);

    new idx = GetPlayerPropertyIndex(playerid);
    if(idx >= 0)
    {
        new typeStr[16];
        GetPropertyTypeName(PropertyData[idx][propType], typeStr, sizeof(typeStr));
        SendClientFormattedMessage(playerid, COLOR_PROP_INFO,
            "[Properti] Kamu memiliki: %s - %s",
            typeStr, PropertyData[idx][propName]);
    }
    return 1;
}

// ============================================================================
// COMMANDS — Property Interaction
// ============================================================================

COMMAND:properti(playerid, params[])
{
    new propIdx = GetNearestProperty(playerid);
    if(propIdx == -1)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu tidak berada di dekat properti!"), true;

    pTempPropIdx[playerid] = propIdx;

    if(PropertyData[propIdx][propOwnerID] == 0)
    {
        // Unowned — show buy/rent option
        new typeStr[16];
        GetPropertyTypeName(PropertyData[propIdx][propType], typeStr, sizeof(typeStr));

        new dlg[256];
        format(dlg, sizeof(dlg),
            "{33CCFF}%s - %s\n\n{FFFFFF}Harga Beli: {00FF00}$%d\n{FFFFFF}Harga Sewa: {00FF00}$%d/bulan\n{FFFFFF}Slot Penyimpanan: %d\n\nPilih aksi:",
            typeStr, PropertyData[propIdx][propName],
            PropertyData[propIdx][propPrice],
            PropertyData[propIdx][propRentPrice],
            PropertyData[propIdx][propStorageSlots]);

        ShowPlayerDialog(playerid, DIALOG_PROP_MENU, DIALOG_STYLE_LIST,
            "Properti", "Beli\nSewa\nBatal", "Pilih", "Tutup");
    }
    else if(PropertyData[propIdx][propOwnerID] == PlayerInfo[playerid][pID])
    {
        // Own property
        ShowPlayerDialog(playerid, DIALOG_PROP_MANAGE, DIALOG_STYLE_LIST,
            PropertyData[propIdx][propName],
            "Masuk\nKunci / Buka Kunci\nPenyimpanan\nKelola Kunci\nJual Properti",
            "Pilih", "Tutup");
    }
    else
    {
        // Someone else's property
        if(PropertyData[propIdx][propLocked])
            return SendClientFormattedMessage(playerid, COLOR_RED, "Properti ini terkunci!"), true;
        else
        {
            // Enter unlocked property
            EnterProperty(playerid, propIdx);
        }
    }
    return true;
}

COMMAND:keluar(playerid, params[])
{
    new propIdx = pCurrentProperty[playerid];
    if(propIdx < 0)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu tidak di dalam properti!"), true;

    ExitProperty(playerid, propIdx);
    return true;
}

COMMAND:kunci(playerid, params[])
{
    new propIdx = GetNearestProperty(playerid);
    if(propIdx == -1)
    {
        propIdx = GetPlayerPropertyIndex(playerid);
        if(propIdx < 0 || pCurrentProperty[playerid] != propIdx)
            return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu tidak berada di properti milikmu!"), true;
    }

    if(PropertyData[propIdx][propOwnerID] != PlayerInfo[playerid][pID])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Ini bukan properti kamu!"), true;

    PropertyData[propIdx][propLocked] = !PropertyData[propIdx][propLocked];
    SaveProperty(propIdx);
    RefreshPropertyLabel(propIdx);

    if(PropertyData[propIdx][propLocked])
        SendClientFormattedMessage(playerid, COLOR_PROP, "[Properti] Kamu mengunci properti.");
    else
        SendClientFormattedMessage(playerid, COLOR_PROP, "[Properti] Kamu membuka kunci properti.");

    new rptext[80];
    format(rptext, sizeof(rptext), "* %s %s properti.", PlayerInfo[playerid][pICName],
        PropertyData[propIdx][propLocked] ? "mengunci" : "membuka");
    ProxDetector(10.0, playerid, rptext, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);
    return true;
}

COMMAND:storage(playerid, params[])
{
    new propIdx = pCurrentProperty[playerid];
    if(propIdx < 0)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu harus di dalam properti!"), true;

    if(PropertyData[propIdx][propOwnerID] != PlayerInfo[playerid][pID])
        return SendClientFormattedMessage(playerid, COLOR_RED, "Ini bukan properti kamu!"), true;

    // Load storage from DB
    pTempPropIdx[playerid] = propIdx;
    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT * FROM property_storage WHERE property_id = '%d' ORDER BY id",
        PropertyData[propIdx][propID]);
    mysql_function_query(MySQL_C1, query, true, "OnPropStorageLoaded", "d", playerid);
    return true;
}

publics: OnPropStorageLoaded(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);
    PropStorageCount[playerid] = 0;

    for(new i = 0; i < rows && i < MAX_PROP_STORAGE; i++)
    {
        PropStorageItems[playerid][i][psDBID] = cache_get_field_content_int(i, "id", MySQL_C1);
        PropStorageItems[playerid][i][psPropID] = cache_get_field_content_int(i, "property_id", MySQL_C1);
        PropStorageItems[playerid][i][psItemID] = cache_get_field_content_int(i, "item_id", MySQL_C1);
        PropStorageItems[playerid][i][psAmount] = cache_get_field_content_int(i, "amount", MySQL_C1);
        PropStorageCount[playerid]++;
    }

    new dlg[512];
    format(dlg, sizeof(dlg), "Item\tJumlah\n");
    if(PropStorageCount[playerid] == 0)
    {
        strcat(dlg, "(Kosong)\t-\n", sizeof(dlg));
    }
    else
    {
        for(new i = 0; i < PropStorageCount[playerid]; i++)
        {
            new itemName[24];
            GetItemName(PropStorageItems[playerid][i][psItemID], itemName, sizeof(itemName));
            new line[64];
            format(line, sizeof(line), "%s\t%d\n", itemName, PropStorageItems[playerid][i][psAmount]);
            strcat(dlg, line, sizeof(dlg));
        }
    }

    strcat(dlg, "\n{00FF00}+ Simpan Item dari Inventory", sizeof(dlg));

    ShowPlayerDialog(playerid, DIALOG_PROP_STORAGE, DIALOG_STYLE_TABLIST_HEADERS,
        "Penyimpanan Properti", dlg, "Ambil", "Tutup");
    return 1;
}

stock GetItemName(itemId, output[], maxlen)
{
    for(new i = 0; i < sizeof(ItemTable); i++)
    {
        if(ItemTable[i][itmID] == itemId)
        {
            strmid(output, ItemTable[i][itmName], 0, strlen(ItemTable[i][itmName]), maxlen);
            return;
        }
    }
    strmid(output, "Unknown", 0, 8, maxlen);
}

// ============================================================================
// ENTER / EXIT PROPERTY
// ============================================================================

stock EnterProperty(playerid, propIdx)
{
    if(PropertyData[propIdx][propExitX] == 0.0 && PropertyData[propIdx][propExitY] == 0.0)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Properti ini belum dikonfigurasi interior-nya!");
        return;
    }

    SetPlayerPos(playerid, PropertyData[propIdx][propExitX],
                           PropertyData[propIdx][propExitY],
                           PropertyData[propIdx][propExitZ]);
    SetPlayerFacingAngle(playerid, PropertyData[propIdx][propExitAngle]);
    SetPlayerInterior(playerid, PropertyData[propIdx][propInterior]);
    SetPlayerVirtualWorld(playerid, PropertyData[propIdx][propVW]);

    pCurrentProperty[playerid] = propIdx;

    new typeStr[16];
    GetPropertyTypeName(PropertyData[propIdx][propType], typeStr, sizeof(typeStr));
    SendClientFormattedMessage(playerid, COLOR_PROP,
        "[Properti] Masuk ke %s - %s.", typeStr, PropertyData[propIdx][propName]);
}

stock ExitProperty(playerid, propIdx)
{
    SetPlayerPos(playerid, PropertyData[propIdx][propEntryX],
                           PropertyData[propIdx][propEntryY],
                           PropertyData[propIdx][propEntryZ]);
    SetPlayerFacingAngle(playerid, PropertyData[propIdx][propEntryAngle]);
    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, 0);

    pCurrentProperty[playerid] = -1;

    SendClientFormattedMessage(playerid, COLOR_PROP, "[Properti] Keluar dari properti.");
}

// ============================================================================
// PROPERTY DIALOG HANDLER
// ============================================================================

stock HandlePropertyDialogs(playerid, dialogid, response, listitem, inputtext[])
{
    switch(dialogid)
    {
        case DIALOG_PROP_MENU:
        {
            if(!response) return 1;
            new propIdx = pTempPropIdx[playerid];
            if(propIdx < 0 || propIdx >= TotalProperties) return 1;

            switch(listitem)
            {
                case 0: // Beli
                {
                    if(pOwnedPropertyID[playerid] > 0)
                        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu sudah punya properti!"), 1;

                    new price = PropertyData[propIdx][propPrice];
                    if(PlayerInfo[playerid][pBank] < price)
                        return SendClientFormattedMessage(playerid, COLOR_RED, "Saldo bank tidak cukup! Butuh: $%d", price), 1;

                    PlayerInfo[playerid][pBank] -= price;
                    PropertyData[propIdx][propOwnerID] = PlayerInfo[playerid][pID];
                    strmid(PropertyData[propIdx][propOwnerName], PlayerInfo[playerid][pICName], 0,
                        strlen(PlayerInfo[playerid][pICName]), 32);
                    PropertyData[propIdx][propLocked] = true;
                    SaveProperty(propIdx);
                    RefreshPropertyLabel(propIdx);

                    pOwnedPropertyID[playerid] = PropertyData[propIdx][propID];

                    new typeStr[16];
                    GetPropertyTypeName(PropertyData[propIdx][propType], typeStr, sizeof(typeStr));
                    SendClientFormattedMessage(playerid, COLOR_PROP_INFO,
                        "[Properti] Selamat! Kamu membeli %s - %s seharga $%d.",
                        typeStr, PropertyData[propIdx][propName], price);
                }
                case 1: // Sewa
                {
                    if(pOwnedPropertyID[playerid] > 0)
                        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu sudah punya properti!"), 1;

                    new rent = PropertyData[propIdx][propRentPrice];
                    if(PlayerInfo[playerid][pBank] < rent)
                        return SendClientFormattedMessage(playerid, COLOR_RED, "Saldo bank tidak cukup! Butuh: $%d/bulan", rent), 1;

                    PlayerInfo[playerid][pBank] -= rent;
                    PropertyData[propIdx][propOwnerID] = PlayerInfo[playerid][pID];
                    strmid(PropertyData[propIdx][propOwnerName], PlayerInfo[playerid][pICName], 0,
                        strlen(PlayerInfo[playerid][pICName]), 32);
                    PropertyData[propIdx][propLocked] = true;

                    // Set rent due date to 30 days from now
                    mysql_format(MySQL_C1, query, sizeof(query),
                        "UPDATE properties SET owner_id='%d', owner_name='%e', locked=1, \
rent_due_date=DATE_ADD(NOW(), INTERVAL 30 DAY) WHERE id='%d'",
                        PlayerInfo[playerid][pID], PlayerInfo[playerid][pICName],
                        PropertyData[propIdx][propID]);
                    mysql_function_query(MySQL_C1, query, false, "", "");

                    RefreshPropertyLabel(propIdx);
                    pOwnedPropertyID[playerid] = PropertyData[propIdx][propID];

                    new typeStr[16];
                    GetPropertyTypeName(PropertyData[propIdx][propType], typeStr, sizeof(typeStr));
                    SendClientFormattedMessage(playerid, COLOR_PROP_INFO,
                        "[Properti] Kamu menyewa %s - %s seharga $%d/bulan.",
                        typeStr, PropertyData[propIdx][propName], rent);
                }
                case 2: // Batal
                    return 1;
            }
            return 1;
        }
        case DIALOG_PROP_MANAGE:
        {
            if(!response) return 1;
            new propIdx = pTempPropIdx[playerid];
            if(propIdx < 0 || propIdx >= TotalProperties) return 1;

            switch(listitem)
            {
                case 0: // Masuk
                    EnterProperty(playerid, propIdx);
                case 1: // Kunci / Buka
                {
                    PropertyData[propIdx][propLocked] = !PropertyData[propIdx][propLocked];
                    SaveProperty(propIdx);
                    RefreshPropertyLabel(propIdx);

                    SendClientFormattedMessage(playerid, COLOR_PROP,
                        "[Properti] Properti %s.", PropertyData[propIdx][propLocked] ? "dikunci" : "dibuka");
                }
                case 2: // Penyimpanan
                    cmd_storage(playerid, "");
                case 3: // Kelola Kunci
                {
                    // Show key management
                    mysql_format(MySQL_C1, query, sizeof(query),
                        "SELECT player_name FROM property_keys WHERE property_id = '%d'",
                        PropertyData[propIdx][propID]);
                    mysql_function_query(MySQL_C1, query, true, "OnPropKeysLoaded", "d", playerid);
                }
                case 4: // Jual Properti
                {
                    new sellPrice = PropertyData[propIdx][propPrice] / 2;
                    PlayerInfo[playerid][pBank] += sellPrice;

                    PropertyData[propIdx][propOwnerID] = 0;
                    PropertyData[propIdx][propOwnerName][0] = EOS;
                    PropertyData[propIdx][propLocked] = true;
                    SaveProperty(propIdx);
                    RefreshPropertyLabel(propIdx);

                    // Delete storage & keys
                    mysql_format(MySQL_C1, query, sizeof(query),
                        "DELETE FROM property_storage WHERE property_id = '%d'",
                        PropertyData[propIdx][propID]);
                    mysql_function_query(MySQL_C1, query, false, "", "");
                    mysql_format(MySQL_C1, query, sizeof(query),
                        "DELETE FROM property_keys WHERE property_id = '%d'",
                        PropertyData[propIdx][propID]);
                    mysql_function_query(MySQL_C1, query, false, "", "");

                    // Reset rent date
                    mysql_format(MySQL_C1, query, sizeof(query),
                        "UPDATE properties SET rent_due_date = NULL WHERE id = '%d'",
                        PropertyData[propIdx][propID]);
                    mysql_function_query(MySQL_C1, query, false, "", "");

                    pOwnedPropertyID[playerid] = 0;

                    SendClientFormattedMessage(playerid, COLOR_PROP,
                        "[Properti] Properti dijual. Kamu menerima $%d (50%% harga).", sellPrice);
                }
            }
            return 1;
        }
        case DIALOG_PROP_STORAGE:
        {
            if(!response) return 1;
            new propIdx = pTempPropIdx[playerid];
            if(propIdx < 0) return 1;

            // Last item = "Simpan from inventory"
            if(listitem >= PropStorageCount[playerid])
            {
                // Show inventory items to store
                ShowStoreItemDialog(playerid);
                return 1;
            }

            // Take item
            if(listitem < PropStorageCount[playerid] && PropStorageItems[playerid][listitem][psAmount] > 0)
            {
                new itemId = PropStorageItems[playerid][listitem][psItemID];
                new amount = PropStorageItems[playerid][listitem][psAmount];

                // Add to inventory
                new added = AddInventoryItem(playerid, itemId, amount);
                if(added > 0)
                {
                    PropStorageItems[playerid][listitem][psAmount] -= added;
                    if(PropStorageItems[playerid][listitem][psAmount] <= 0)
                    {
                        // Delete from DB
                        mysql_format(MySQL_C1, query, sizeof(query),
                            "DELETE FROM property_storage WHERE id = '%d'",
                            PropStorageItems[playerid][listitem][psDBID]);
                    }
                    else
                    {
                        mysql_format(MySQL_C1, query, sizeof(query),
                            "UPDATE property_storage SET amount = '%d' WHERE id = '%d'",
                            PropStorageItems[playerid][listitem][psAmount], PropStorageItems[playerid][listitem][psDBID]);
                    }
                    mysql_function_query(MySQL_C1, query, false, "", "");

                    new itemName[24];
                    GetItemName(itemId, itemName, sizeof(itemName));
                    SendClientFormattedMessage(playerid, COLOR_PROP,
                        "[Properti] Mengambil %dx %s dari penyimpanan.", added, itemName);
                }
                else
                {
                    SendClientFormattedMessage(playerid, COLOR_RED, "Inventory penuh!");
                }
            }
            return 1;
        }
        case DIALOG_PROP_STORE_ITEM:
        {
            if(!response) return 1;
            new propIdx = pTempPropIdx[playerid];
            if(propIdx < 0) return 1;

            // Find the nth non-empty inventory slot
            new count = 0;
            for(new s = 0; s < MAX_INVENTORY_SLOTS; s++)
            {
                if(PlayerInfo[playerid][pInvItems][s] != ITEM_NONE)
                {
                    if(count == listitem)
                    {
                        new itemId = PlayerInfo[playerid][pInvItems][s];
                        new amount = PlayerInfo[playerid][pInvAmounts][s];

                        // Check storage slots
                        if(PropStorageCount[playerid] >= PropertyData[propIdx][propStorageSlots])
                        {
                            SendClientFormattedMessage(playerid, COLOR_RED, "Penyimpanan penuh!");
                            return 1;
                        }

                        // Add to property storage DB
                        mysql_format(MySQL_C1, query, sizeof(query),
                            "INSERT INTO property_storage (property_id, item_id, amount) VALUES ('%d', '%d', '%d')",
                            PropertyData[propIdx][propID], itemId, amount);
                        mysql_function_query(MySQL_C1, query, false, "", "");

                        // Remove from inventory
                        PlayerInfo[playerid][pInvItems][s] = ITEM_NONE;
                        PlayerInfo[playerid][pInvAmounts][s] = 0;

                        new itemName[24];
                        GetItemName(itemId, itemName, sizeof(itemName));
                        SendClientFormattedMessage(playerid, COLOR_PROP,
                            "[Properti] Menyimpan %dx %s ke penyimpanan.", amount, itemName);
                        return 1;
                    }
                    count++;
                }
            }
            return 1;
        }
        case DIALOG_PROP_KEY_ADD:
        {
            if(!response) return 1;
            new propIdx = pTempPropIdx[playerid];
            if(propIdx < 0) return 1;

            new targetid = strval(inputtext);
            if(!IsPlayerConnected(targetid) || !PlayerInfo[targetid][pLogged])
                return SendClientFormattedMessage(playerid, COLOR_RED, "Player tidak valid!"), 1;

            // Add key to DB
            mysql_format(MySQL_C1, query, sizeof(query),
                "INSERT IGNORE INTO property_keys (property_id, player_id, player_name) VALUES ('%d', '%d', '%e')",
                PropertyData[propIdx][propID], PlayerInfo[targetid][pID], PlayerInfo[targetid][pICName]);
            mysql_function_query(MySQL_C1, query, false, "", "");

            SendClientFormattedMessage(playerid, COLOR_PROP,
                "[Properti] Kunci diberikan ke %s.", PlayerInfo[targetid][pICName]);
            SendClientFormattedMessage(targetid, COLOR_PROP,
                "[Properti] %s memberimu kunci properti miliknya.", PlayerInfo[playerid][pICName]);
            return 1;
        }
        // Admin property creation
        case DIALOG_PROP_CREATE_TYPE:
        {
            if(!response) return 1;
            pTempPropType[playerid] = listitem + 1;
            ShowPlayerDialog(playerid, DIALOG_PROP_CREATE_NAME, DIALOG_STYLE_INPUT,
                "Nama Properti", "Masukkan nama properti:", "Lanjut", "Batal");
            return 1;
        }
        case DIALOG_PROP_CREATE_NAME:
        {
            if(!response) return 1;
            if(!strlen(inputtext) || strlen(inputtext) > 60)
                return SendClientFormattedMessage(playerid, COLOR_RED, "Nama harus 1-60 karakter!"), 1;
            strmid(pTempPropName[playerid], inputtext, 0, strlen(inputtext), 64);
            ShowPlayerDialog(playerid, DIALOG_PROP_CREATE_PRICE, DIALOG_STYLE_INPUT,
                "Harga Properti", "Masukkan harga beli (angka):", "Buat", "Batal");
            return 1;
        }
        case DIALOG_PROP_CREATE_PRICE:
        {
            if(!response) return 1;
            new price = strval(inputtext);
            if(price < 0) return SendClientFormattedMessage(playerid, COLOR_RED, "Harga tidak valid!"), 1;

            new Float:px, Float:py, Float:pz, Float:pa;
            GetPlayerPos(playerid, px, py, pz);
            GetPlayerFacingAngle(playerid, pa);

            new propType = pTempPropType[playerid];
            new slots = 10;
            if(propType == PROP_GUDANG) slots = 50;
            else if(propType == PROP_RUKO) slots = 20;
            new rent = price / 10; // rent = 10% of price/month

            mysql_format(MySQL_C1, query, sizeof(query),
                "INSERT INTO properties (name, type, price, rent_price, entry_x, entry_y, entry_z, entry_angle, storage_slots) \
VALUES ('%e', '%d', '%d', '%d', '%f', '%f', '%f', '%f', '%d')",
                pTempPropName[playerid], propType, price, rent, px, py, pz, pa, slots);
            mysql_function_query(MySQL_C1, query, true, "OnPropertyCreated", "d", playerid);
            return 1;
        }
    }
    return 0;
}

publics: OnPropKeysLoaded(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);

    new dlg[256];
    format(dlg, sizeof(dlg), "Pemegang Kunci:\n\n");
    for(new i = 0; i < rows; i++)
    {
        new name[32];
        cache_get_field_content(i, "player_name", name, MySQL_C1, 32);
        new line[48];
        format(line, sizeof(line), "- %s\n", name);
        strcat(dlg, line, sizeof(dlg));
    }
    strcat(dlg, "\nMasukkan Player ID untuk menambah kunci:", sizeof(dlg));

    ShowPlayerDialog(playerid, DIALOG_PROP_KEY_ADD, DIALOG_STYLE_INPUT,
        "Kelola Kunci", dlg, "Tambah", "Tutup");
    return 1;
}

publics: OnPropertyCreated(playerid)
{
    new insertId = cache_insert_id();
    if(insertId <= 0)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Gagal membuat properti!"), 1;

    // Reload properties
    LoadProperties();

    new typeStr[16];
    GetPropertyTypeName(pTempPropType[playerid], typeStr, sizeof(typeStr));
    SendClientFormattedMessage(playerid, COLOR_PROP_INFO,
        "[Admin] Properti '%s' (%s) ID:%d berhasil dibuat di posisi saat ini.",
        pTempPropName[playerid], typeStr, insertId);
    return 1;
}

stock ShowStoreItemDialog(playerid)
{
    new dlg[512] = "";
    new count = 0;
    for(new s = 0; s < MAX_INVENTORY_SLOTS; s++)
    {
        if(PlayerInfo[playerid][pInvItems][s] != ITEM_NONE)
        {
            new itemName[24];
            GetItemName(PlayerInfo[playerid][pInvItems][s], itemName, sizeof(itemName));
            new line[48];
            format(line, sizeof(line), "%s x%d\n", itemName, PlayerInfo[playerid][pInvAmounts][s]);
            strcat(dlg, line, sizeof(dlg));
            count++;
        }
    }

    if(count == 0)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Inventory kosong!");
        return;
    }

    ShowPlayerDialog(playerid, DIALOG_PROP_STORE_ITEM, DIALOG_STYLE_LIST,
        "Simpan Item ke Penyimpanan", dlg, "Simpan", "Batal");
}

// ============================================================================
// ADMIN COMMANDS
// ============================================================================

COMMAND:createproperty(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    ShowPlayerDialog(playerid, DIALOG_PROP_CREATE_TYPE, DIALOG_STYLE_LIST,
        "Buat Properti - Tipe",
        "Apartemen\nKostan\nGudang\nRuko/Bisnis\nTanah",
        "Pilih", "Batal");
    return true;
}

COMMAND:setpropinterior(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new propId;
    if(sscanf(params, "d", propId))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /setpropinterior [property_id]"), true;

    new propIdx = -1;
    for(new i = 0; i < TotalProperties; i++)
    {
        if(PropertyData[i][propID] == propId) { propIdx = i; break; }
    }
    if(propIdx == -1)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Properti tidak ditemukan!"), true;

    new Float:px, Float:py, Float:pz, Float:pa;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerFacingAngle(playerid, pa);
    new interior = GetPlayerInterior(playerid);
    new vw = GetPlayerVirtualWorld(playerid);

    PropertyData[propIdx][propExitX] = px;
    PropertyData[propIdx][propExitY] = py;
    PropertyData[propIdx][propExitZ] = pz;
    PropertyData[propIdx][propExitAngle] = pa;
    PropertyData[propIdx][propInterior] = interior;
    PropertyData[propIdx][propVW] = vw;

    mysql_format(MySQL_C1, query, sizeof(query),
        "UPDATE properties SET exit_x='%f', exit_y='%f', exit_z='%f', \
exit_angle='%f', interior='%d', vw='%d' WHERE id='%d'",
        px, py, pz, pa, interior, vw, propId);
    mysql_function_query(MySQL_C1, query, false, "", "");

    SendClientFormattedMessage(playerid, COLOR_PROP_INFO,
        "[Admin] Interior properti ID:%d diatur di posisi saat ini (Interior:%d VW:%d).",
        propId, interior, vw);
    return true;
}

COMMAND:proplist(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan admin!"), true;

    SendClientFormattedMessage(playerid, COLOR_PROP_INFO, "======= Daftar Properti =======");
    for(new i = 0; i < TotalProperties; i++)
    {
        new typeStr[16];
        GetPropertyTypeName(PropertyData[i][propType], typeStr, sizeof(typeStr));

        new owner[32] = "Kosong";
        if(PropertyData[i][propOwnerID] > 0)
            strmid(owner, PropertyData[i][propOwnerName], 0, strlen(PropertyData[i][propOwnerName]), 32);

        SendClientFormattedMessage(playerid, -1, "  [%d] %s (%s) | Pemilik: %s | Harga: $%d",
            PropertyData[i][propID], PropertyData[i][propName], typeStr, owner, PropertyData[i][propPrice]);
    }
    SendClientFormattedMessage(playerid, COLOR_PROP_INFO, "Total: %d properti.", TotalProperties);
    return true;
}

COMMAND:deleteproperty(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_MANAGEMENT)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Kamu bukan Management!"), true;

    new propId;
    if(sscanf(params, "d", propId))
        return SendClientFormattedMessage(playerid, COLOR_YELLOW, "Gunakan: /deleteproperty [property_id]"), true;

    new propIdx = -1;
    for(new i = 0; i < TotalProperties; i++)
    {
        if(PropertyData[i][propID] == propId) { propIdx = i; break; }
    }
    if(propIdx == -1)
        return SendClientFormattedMessage(playerid, COLOR_RED, "Properti tidak ditemukan!"), true;

    // Reset online owner
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        if(pOwnedPropertyID[i] == propId) pOwnedPropertyID[i] = 0;
    }

    // Clean up label & pickup
    if(PropertyData[propIdx][propEntryLabel] != Text3D:INVALID_3DTEXT_ID)
        Delete3DTextLabel(PropertyData[propIdx][propEntryLabel]);
    if(PropertyData[propIdx][propEntryPickup] != -1)
        DestroyPickup(PropertyData[propIdx][propEntryPickup]);

    mysql_format(MySQL_C1, query, sizeof(query),
        "DELETE FROM properties WHERE id = '%d'", propId);
    mysql_function_query(MySQL_C1, query, false, "", "");

    SendClientFormattedMessage(playerid, COLOR_PROP_INFO,
        "[Admin] Properti ID:%d dihapus.", propId);

    // Reload
    LoadProperties();
    return true;
}

// ============================================================================
// SPAWN AT PROPERTY (check on spawn)
// ============================================================================

stock CheckPropertySpawn(playerid)
{
    if(pOwnedPropertyID[playerid] <= 0) return 0;

    // Check if player logged out near their property
    new propIdx = GetPlayerPropertyIndex(playerid);
    if(propIdx < 0) return 0;

    // Only Apartemen and Kostan provide spawn
    if(PropertyData[propIdx][propType] != PROP_APARTEMEN &&
       PropertyData[propIdx][propType] != PROP_KOSTAN) return 0;

    new Float:lastX = PlayerInfo[playerid][pLastX];
    new Float:lastY = PlayerInfo[playerid][pLastY];

    if(lastX == 0.0 && lastY == 0.0) return 0;

    // Check distance from property entry
    new Float:dist = floatsqroot(
        (lastX - PropertyData[propIdx][propEntryX]) * (lastX - PropertyData[propIdx][propEntryX]) +
        (lastY - PropertyData[propIdx][propEntryY]) * (lastY - PropertyData[propIdx][propEntryY])
    );

    // If within 100m of property, spawn inside
    if(dist < 100.0)
    {
        if(PropertyData[propIdx][propExitX] != 0.0 || PropertyData[propIdx][propExitY] != 0.0)
        {
            SetPlayerPos(playerid, PropertyData[propIdx][propExitX],
                                   PropertyData[propIdx][propExitY],
                                   PropertyData[propIdx][propExitZ]);
            SetPlayerFacingAngle(playerid, PropertyData[propIdx][propExitAngle]);
            SetPlayerInterior(playerid, PropertyData[propIdx][propInterior]);
            SetPlayerVirtualWorld(playerid, PropertyData[propIdx][propVW]);
            pCurrentProperty[playerid] = propIdx;

            new typeStr[16];
            GetPropertyTypeName(PropertyData[propIdx][propType], typeStr, sizeof(typeStr));
            SendClientFormattedMessage(playerid, COLOR_PROP,
                "[Properti] Kamu bangun di %s - %s.", typeStr, PropertyData[propIdx][propName]);
            return 1;
        }
    }
    return 0;
}
