// ============================================================================
// MODULE: bank.pwn
// Physical bank system: ATM & bank locations loaded from DB (dev-managed)
// ATM: FREE transactions (no fee, unlike M-Banking)
// ATM shows actual ATM object (model 2942), no floating map icons
// Bank office: Create bank account
// ============================================================================

// ============================================================================
// LOAD FROM DB
// ============================================================================

static _bnk_msg[256];

stock LoadATMLocations()
{
    mysql_function_query(MySQL_C1, "SELECT * FROM `atm_locations` ORDER BY `id` ASC", true, "OnATMLocationsLoaded", "");
}

publics: OnATMLocationsLoaded()
{
    new rows, fields;
    cache_get_data(rows, fields);
    TotalATMs = 0;
    for(new i = 0; i < rows && i < MAX_ATM_LOCATIONS; i++)
    {
        ATMData[i][atmDBID] = cache_get_field_content_int(i, "id", MySQL_C1);
        ATMData[i][atmX] = cache_get_field_content_float(i, "pos_x", MySQL_C1);
        ATMData[i][atmY] = cache_get_field_content_float(i, "pos_y", MySQL_C1);
        ATMData[i][atmZ] = cache_get_field_content_float(i, "pos_z", MySQL_C1);
        ATMData[i][atmRotZ] = cache_get_field_content_float(i, "rot_z", MySQL_C1);
        CreateATMWorld(i);
        TotalATMs++;
    }
    printf("[Bank] ATM loaded: %d locations.", TotalATMs);
}

stock LoadBankLocations()
{
    mysql_function_query(MySQL_C1, "SELECT * FROM `bank_locations` ORDER BY `id` ASC", true, "OnBankLocationsLoaded", "");
}

publics: OnBankLocationsLoaded()
{
    new rows, fields;
    cache_get_data(rows, fields);
    TotalBanks = 0;
    for(new i = 0; i < rows && i < MAX_BANK_LOCATIONS; i++)
    {
        BankData[i][bnkDBID] = cache_get_field_content_int(i, "id", MySQL_C1);
        cache_get_field_content(i, "name", BankData[i][bnkName], MySQL_C1, 32);
        BankData[i][bnkX] = cache_get_field_content_float(i, "pos_x", MySQL_C1);
        BankData[i][bnkY] = cache_get_field_content_float(i, "pos_y", MySQL_C1);
        BankData[i][bnkZ] = cache_get_field_content_float(i, "pos_z", MySQL_C1);
        BankData[i][bnkRotZ] = cache_get_field_content_float(i, "rot_z", MySQL_C1);
        CreateBankWorld(i);
        TotalBanks++;
    }
    printf("[Bank] Bank loaded: %d locations.", TotalBanks);
}

stock CreateATMWorld(idx)
{
    ATMData[idx][atmObjectID] = CreateObject(ATM_OBJECT_MODEL, ATMData[idx][atmX], ATMData[idx][atmY], ATMData[idx][atmZ], 0.0, 0.0, ATMData[idx][atmRotZ]);
    ATMData[idx][atmLabelID] = Create3DTextLabel("{00CC00}ATM\n{FFFFFF}/atm", 0x00CC00FF, ATMData[idx][atmX], ATMData[idx][atmY], ATMData[idx][atmZ] + 1.2, 10.0, 0);
    ATMData[idx][atmPickupID] = CreatePickup(1274, 23, ATMData[idx][atmX], ATMData[idx][atmY], ATMData[idx][atmZ], -1);
}

stock DestroyATMWorld(idx)
{
    if(ATMData[idx][atmObjectID]) { DestroyObject(ATMData[idx][atmObjectID]); ATMData[idx][atmObjectID] = 0; }
    if(ATMData[idx][atmLabelID] != Text3D:INVALID_3DTEXT_ID) { Delete3DTextLabel(ATMData[idx][atmLabelID]); ATMData[idx][atmLabelID] = Text3D:INVALID_3DTEXT_ID; }
    if(ATMData[idx][atmPickupID]) { DestroyPickup(ATMData[idx][atmPickupID]); ATMData[idx][atmPickupID] = 0; }
}

stock CreateBankWorld(idx)
{
    new lbl[128];
    format(lbl, sizeof(lbl), "{FFD700}%s\n{FFFFFF}/bank untuk buka rekening", BankData[idx][bnkName]);
    BankData[idx][bnkLabelID] = Create3DTextLabel(lbl, 0xFFAA00FF, BankData[idx][bnkX], BankData[idx][bnkY], BankData[idx][bnkZ] + 0.5, 10.0, 0);
    BankData[idx][bnkPickupID] = CreatePickup(1274, 23, BankData[idx][bnkX], BankData[idx][bnkY], BankData[idx][bnkZ], -1);
}

stock DestroyBankWorld(idx)
{
    if(BankData[idx][bnkLabelID] != Text3D:INVALID_3DTEXT_ID) { Delete3DTextLabel(BankData[idx][bnkLabelID]); BankData[idx][bnkLabelID] = Text3D:INVALID_3DTEXT_ID; }
    if(BankData[idx][bnkPickupID]) { DestroyPickup(BankData[idx][bnkPickupID]); BankData[idx][bnkPickupID] = 0; }
}

// ============================================================================
// ATM/BANK CHECK - Is player near?
// ============================================================================

stock IsPlayerNearATM(playerid)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    for(new i = 0; i < TotalATMs; i++)
    {
        new Float:dist = floatsqroot((px - ATMData[i][atmX]) * (px - ATMData[i][atmX]) + (py - ATMData[i][atmY]) * (py - ATMData[i][atmY]) + (pz - ATMData[i][atmZ]) * (pz - ATMData[i][atmZ]));
        if(dist <= ATM_INTERACT_RANGE) return 1;
    }
    return 0;
}

stock IsPlayerNearBank(playerid)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    for(new i = 0; i < TotalBanks; i++)
    {
        new Float:dist = floatsqroot((px - BankData[i][bnkX]) * (px - BankData[i][bnkX]) + (py - BankData[i][bnkY]) * (py - BankData[i][bnkY]) + (pz - BankData[i][bnkZ]) * (pz - BankData[i][bnkZ]));
        if(dist <= BANK_INTERACT_RANGE) return 1;
    }
    return 0;
}

// ============================================================================
// ATM MENU (FREE - no fees)
// ============================================================================

stock OpenATMMenu(playerid)
{
    if(strlen(PlayerInfo[playerid][pBankAccount]) < 5)
    {
        SendClientMessage(playerid, COLOR_YELLOW, "Kamu belum punya rekening bank! Buat di kantor bank.");
        return 0;
    }

    new menustr[256];
    format(menustr, sizeof(menustr),
        "Cek Saldo\nSetor Uang\nTarik Uang\nTransfer\nMutasi Rekening");

    ShowPlayerDialog(playerid, DIALOG_BANK_MENU, DIALOG_STYLE_LIST,
        "{00CC00}ATM - Bank Westfield", menustr, "Pilih", "Tutup");
    return 1;
}

stock HandleATMMenuResponse(playerid, response, listitem)
{
    if(!response) return 1;

    switch(listitem)
    {
        case 0: // Cek Saldo
        {
            new msg[128];
            format(msg, sizeof(msg), "{FFFFFF}Rekening: %s\nSaldo Bank: {00FF00}Rp %d\n\nCash: Rp %d",
                PlayerInfo[playerid][pBankAccount], PlayerInfo[playerid][pBank], PlayerInfo[playerid][pMoney]);
            ShowPlayerDialog(playerid, DIALOG_BANK_MENU + 100, DIALOG_STYLE_MSGBOX,
                "{00CC00}ATM - Saldo", msg, "OK", "");
        }
        case 1: // Setor
        {
            new prompt[128];
            format(prompt, sizeof(prompt), "{FFFFFF}Cash kamu: Rp %d\n{00FF00}GRATIS tanpa biaya admin\n\n{FFFFFF}Masukkan jumlah setor:",
                PlayerInfo[playerid][pMoney]);
            ShowPlayerDialog(playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT,
                "{00CC00}ATM - Setor", prompt, "Setor", "Batal");
        }
        case 2: // Tarik
        {
            new prompt[128];
            format(prompt, sizeof(prompt), "{FFFFFF}Saldo bank: Rp %d\n{00FF00}GRATIS tanpa biaya admin\n\n{FFFFFF}Masukkan jumlah tarik:",
                PlayerInfo[playerid][pBank]);
            ShowPlayerDialog(playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT,
                "{00CC00}ATM - Tarik", prompt, "Tarik", "Batal");
        }
        case 3: // Transfer
        {
            ShowPlayerDialog(playerid, DIALOG_BANK_TRANSFER, DIALOG_STYLE_INPUT,
                "{00CC00}ATM - Transfer",
                "{FFFFFF}Masukkan nomor rekening tujuan:\n{00FF00}GRATIS tanpa biaya admin",
                "Lanjut", "Batal");
        }
        case 4: // Mutasi
        {
            ShowBankHistory(playerid, false);
        }
    }
    return 1;
}

stock HandleATMDepositResponse(playerid, response, inputtext[])
{
    if(!response) { OpenATMMenu(playerid); return 1; }

    new amount = strval(inputtext);
    if(amount < 1)
    {
        SendClientMessage(playerid, COLOR_RED, "Jumlah tidak valid!");
        OpenATMMenu(playerid);
        return 1;
    }

    if(PlayerInfo[playerid][pMoney] < amount)
    {
        SendClientMessage(playerid, COLOR_RED, "Uang cash tidak cukup!");
        OpenATMMenu(playerid);
        return 1;
    }

    PlayerInfo[playerid][pMoney] -= amount;
    PlayerInfo[playerid][pBank] += amount;
    if(PlayerInfo[playerid][pHudCreated]) UpdateMoneyHUD(playerid);

    LogBankTransaction(playerid, 0, "deposit", amount, 0, PlayerInfo[playerid][pBank]);

    format(_bnk_msg, sizeof(_bnk_msg), "[ATM] Setor Rp %d. Saldo: Rp %d", amount, PlayerInfo[playerid][pBank]);
    SendClientMessage(playerid, 0x00CC00FF, _bnk_msg);
    OpenATMMenu(playerid);
    return 1;
}

stock HandleATMWithdrawResponse(playerid, response, inputtext[])
{
    if(!response) { OpenATMMenu(playerid); return 1; }

    new amount = strval(inputtext);
    if(amount < 1)
    {
        SendClientMessage(playerid, COLOR_RED, "Jumlah tidak valid!");
        OpenATMMenu(playerid);
        return 1;
    }

    if(PlayerInfo[playerid][pBank] < amount)
    {
        SendClientMessage(playerid, COLOR_RED, "Saldo bank tidak cukup!");
        OpenATMMenu(playerid);
        return 1;
    }

    PlayerInfo[playerid][pBank] -= amount;
    PlayerInfo[playerid][pMoney] += amount;
    if(PlayerInfo[playerid][pHudCreated]) UpdateMoneyHUD(playerid);

    LogBankTransaction(playerid, 0, "withdraw", amount, 0, PlayerInfo[playerid][pBank]);

    format(_bnk_msg, sizeof(_bnk_msg), "[ATM] Tarik Rp %d. Saldo: Rp %d", amount, PlayerInfo[playerid][pBank]);
    SendClientMessage(playerid, 0x00CC00FF, _bnk_msg);
    OpenATMMenu(playerid);
    return 1;
}

stock HandleATMTransferResponse(playerid, response, inputtext[])
{
    if(!response) { OpenATMMenu(playerid); return 1; }

    if(strlen(inputtext) < 5)
    {
        SendClientMessage(playerid, COLOR_RED, "Nomor rekening tidak valid!");
        OpenATMMenu(playerid);
        return 1;
    }

    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT id, ic_name FROM `accounts` WHERE `bank_account` = '%e' LIMIT 1",
        inputtext);
    mysql_function_query(MySQL_C1, query, true, "OnATMTransferCheck", "d", playerid);
    return 1;
}

publics: OnATMTransferCheck(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);

    if(!rows)
    {
        SendClientMessage(playerid, COLOR_RED, "Nomor rekening tidak ditemukan!");
        OpenATMMenu(playerid);
        return 1;
    }

    new targetid = cache_get_field_content_int(0, "id", MySQL_C1);
    new targetname[24];
    cache_get_field_content(0, "ic_name", targetname, MySQL_C1, 24);

    if(targetid == PlayerInfo[playerid][pID])
    {
        SendClientMessage(playerid, COLOR_YELLOW, "Tidak bisa transfer ke rekening sendiri!");
        OpenATMMenu(playerid);
        return 1;
    }

    PlayerInfo[playerid][pTempTarget] = targetid;

    new prompt[128];
    format(prompt, sizeof(prompt), "{FFFFFF}Transfer ke: %s\n{00FF00}GRATIS tanpa biaya admin\n\n{FFFFFF}Masukkan jumlah:",
        targetname);
    ShowPlayerDialog(playerid, DIALOG_BANK_TRANSFER_AMT, DIALOG_STYLE_INPUT,
        "{00CC00}ATM - Jumlah Transfer", prompt, "Transfer", "Batal");
    return 1;
}

stock HandleATMTransferAmtResponse(playerid, response, inputtext[])
{
    if(!response) { OpenATMMenu(playerid); return 1; }

    new amount = strval(inputtext);
    if(amount < 1)
    {
        SendClientMessage(playerid, COLOR_RED, "Jumlah tidak valid!");
        OpenATMMenu(playerid);
        return 1;
    }

    if(PlayerInfo[playerid][pBank] < amount)
    {
        SendClientMessage(playerid, COLOR_RED, "Saldo tidak cukup!");
        OpenATMMenu(playerid);
        return 1;
    }

    new targetDbId = PlayerInfo[playerid][pTempTarget];

    PlayerInfo[playerid][pBank] -= amount;
    LogBankTransaction(playerid, targetDbId, "tf_out", amount, 0, PlayerInfo[playerid][pBank]);

    // Credit target in DB
    mysql_format(MySQL_C1, query, sizeof(query),
        "UPDATE `accounts` SET `bank_balance` = `bank_balance` + '%d' WHERE `id` = '%d'",
        amount, targetDbId);
    mysql_function_query(MySQL_C1, query, false, "", "");

    LogBankTransactionByDbId(targetDbId, PlayerInfo[playerid][pID], "tf_in", amount, 0);

    // If target is online, update
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        if(!PlayerInfo[i][pLogged]) continue;
        if(PlayerInfo[i][pID] == targetDbId)
        {
            PlayerInfo[i][pBank] += amount;
            format(_bnk_msg, sizeof(_bnk_msg), "[Bank] Menerima transfer Rp %d dari %s.",
                amount, PlayerInfo[playerid][pICName]);
            SendClientMessage(i, 0x00CC00FF, _bnk_msg);
            break;
        }
    }

    format(_bnk_msg, sizeof(_bnk_msg), "[ATM] Transfer Rp %d berhasil. Saldo: Rp %d",
        amount, PlayerInfo[playerid][pBank]);
    SendClientMessage(playerid, 0x00CC00FF, _bnk_msg);
    OpenATMMenu(playerid);
    return 1;
}

// ============================================================================
// BANK ACCOUNT CREATION
// ============================================================================

stock HandleBankCreateResponse(playerid, response)
{
    if(!response) return 1;

    if(strlen(PlayerInfo[playerid][pBankAccount]) >= 5)
    {
        format(_bnk_msg, sizeof(_bnk_msg), "Kamu sudah punya rekening: %s", PlayerInfo[playerid][pBankAccount]);
        SendClientMessage(playerid, COLOR_YELLOW, _bnk_msg);
        return 1;
    }

    // Generate account number
    new accnum[12];
    GenerateBankAccountNumber(accnum, sizeof(accnum));
    strmid(PlayerInfo[playerid][pBankAccount], accnum, 0, strlen(accnum), 12);
    PlayerInfo[playerid][pBank] = 0;

    // Save to DB
    mysql_format(MySQL_C1, query, sizeof(query),
        "UPDATE `accounts` SET `bank_account` = '%e', `bank_balance` = '0' WHERE `id` = '%d'",
        accnum, PlayerInfo[playerid][pID]);
    mysql_function_query(MySQL_C1, query, false, "", "");

    format(_bnk_msg, sizeof(_bnk_msg), "Rekening berhasil dibuat! Nomor rekening: %s", accnum);
    SendClientMessage(playerid, 0x00CC00FF, _bnk_msg);
    SendClientMessage(playerid, 0xFFFF00FF, "Simpan nomor rekening kamu baik-baik.");
    return 1;
}

// ============================================================================
// SHARED: Bank History & Transaction Logging
// ============================================================================

stock LogBankTransaction(playerid, targetDbId, const type[], amount, fee, balanceAfter)
{
    mysql_format(MySQL_C1, query, sizeof(query),
        "INSERT INTO `bank_transactions` (`player_id`, `target_id`, `type`, `amount`, `fee`, `balance_after`, `ts`) \
VALUES ('%d', '%d', '%e', '%d', '%d', '%d', '%d')",
        PlayerInfo[playerid][pID], targetDbId, type, amount, fee, balanceAfter, gettime());
    mysql_function_query(MySQL_C1, query, false, "", "");
}

stock LogBankTransactionByDbId(playerDbId, targetDbId, const type[], amount, fee)
{
    // For offline target logging, we don't know balance_after, use -1
    mysql_format(MySQL_C1, query, sizeof(query),
        "INSERT INTO `bank_transactions` (`player_id`, `target_id`, `type`, `amount`, `fee`, `balance_after`, `ts`) \
VALUES ('%d', '%d', '%e', '%d', '%d', '-1', '%d')",
        playerDbId, targetDbId, type, amount, fee, gettime());
    mysql_function_query(MySQL_C1, query, false, "", "");
}

stock ShowBankHistory(playerid, bool:isMBank)
{
    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT type, amount, fee, balance_after FROM `bank_transactions` WHERE `player_id` = '%d' ORDER BY id DESC LIMIT 10",
        PlayerInfo[playerid][pID]);
    mysql_function_query(MySQL_C1, query, true, "OnBankHistoryLoaded", "dd", playerid, isMBank);
}

publics: OnBankHistoryLoaded(playerid, isMBank)
{
    new rows, fields;
    cache_get_data(rows, fields);

    new histstr[2048];
    histstr[0] = EOS;

    if(rows == 0)
    {
        strcat(histstr, "{888888}Belum ada transaksi.\n");
    }
    else
    {
        for(new i = 0; i < rows; i++)
        {
            new type[16], amount, fee, bal;
            cache_get_field_content(i, "type", type, MySQL_C1, 16);
            amount = cache_get_field_content_int(i, "amount", MySQL_C1);
            fee = cache_get_field_content_int(i, "fee", MySQL_C1);
            bal = cache_get_field_content_int(i, "balance_after", MySQL_C1);

            new typestr[20];
            if(!strcmp(type, "deposit")) format(typestr, sizeof(typestr), "{00FF00}Setor");
            else if(!strcmp(type, "withdraw")) format(typestr, sizeof(typestr), "{FF6600}Tarik");
            else if(!strcmp(type, "tf_out")) format(typestr, sizeof(typestr), "{FF0000}TF Keluar");
            else if(!strcmp(type, "tf_in")) format(typestr, sizeof(typestr), "{00FF00}TF Masuk");
            else format(typestr, sizeof(typestr), "{FFFFFF}Lainnya");

            new line[128];
            if(fee > 0)
                format(line, sizeof(line), "%s{FFFFFF} Rp %d (fee: %d) Saldo: %d\n", typestr, amount, fee, bal);
            else
                format(line, sizeof(line), "%s{FFFFFF} Rp %d Saldo: %d\n", typestr, amount, bal);

            strcat(histstr, line, sizeof(histstr));
        }
    }

    new dlgid = isMBank ? DIALOG_PHONE_MBANK_HISTORY : DIALOG_BANK_HISTORY;
    new title[48];
    format(title, sizeof(title), "%s - Mutasi Rekening", isMBank ? ("{6A1B9A}M-Banking") : ("{00CC00}ATM"));

    ShowPlayerDialog(playerid, dlgid, DIALOG_STYLE_MSGBOX, title, histstr, "Kembali", "");
    return 1;
}

// ============================================================================
// COMMANDS
// ============================================================================

COMMAND:atm(playerid, params[])
{
    if(!IsPlayerNearATM(playerid))
        return SendClientMessage(playerid, COLOR_RED, "Kamu tidak berada di dekat ATM!"), true;
    OpenATMMenu(playerid);
    return true;
}

COMMAND:bank(playerid, params[])
{
    if(!IsPlayerNearBank(playerid))
        return SendClientMessage(playerid, COLOR_RED, "Kamu tidak berada di kantor bank!"), true;

    if(strlen(PlayerInfo[playerid][pBankAccount]) >= 5)
    {
        format(_bnk_msg, sizeof(_bnk_msg), "Kamu sudah punya rekening: %s", PlayerInfo[playerid][pBankAccount]);
        SendClientMessage(playerid, COLOR_YELLOW, _bnk_msg);
        return true;
    }

    ShowPlayerDialog(playerid, DIALOG_BANK_CREATE, DIALOG_STYLE_MSGBOX,
        "{FFD700}Bank Westfield",
        "{FFFFFF}Selamat datang di Bank Westfield!\n\nApakah kamu ingin membuka rekening bank?\nRekening diperlukan untuk menggunakan ATM dan M-Banking.",
        "Buat", "Tidak");
    return true;
}

// ============================================================================
// DEVELOPER COMMANDS - ATM
// ============================================================================

COMMAND:setatm(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP) return SendClientMessage(playerid, COLOR_RED, "DevMap/Developer only."), true;
    if(TotalATMs >= MAX_ATM_LOCATIONS) { format(_bnk_msg, sizeof(_bnk_msg), "Max ATM tercapai (%d).", MAX_ATM_LOCATIONS); return SendClientMessage(playerid, COLOR_RED, _bnk_msg), true; }

    new Float:px, Float:py, Float:pz, Float:pa;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerFacingAngle(playerid, pa);

    mysql_format(MySQL_C1, query, sizeof(query), "INSERT INTO `atm_locations` (`pos_x`,`pos_y`,`pos_z`,`rot_z`,`created_by`,`created_at`) VALUES ('%f','%f','%f','%f','%e','%d')", px, py, pz, pa, PlayerName(playerid), gettime());
    mysql_function_query(MySQL_C1, query, true, "OnATMCreated", "dfff", playerid, px, py, pz);
    return true;
}

publics: OnATMCreated(playerid, Float:px, Float:py, Float:pz)
{
    new idx = TotalATMs;
    ATMData[idx][atmDBID] = cache_insert_id();
    ATMData[idx][atmX] = px;
    ATMData[idx][atmY] = py;
    ATMData[idx][atmZ] = pz;
    new Float:pa;
    GetPlayerFacingAngle(playerid, pa);
    ATMData[idx][atmRotZ] = pa;
    CreateATMWorld(idx);
    TotalATMs++;
    format(_bnk_msg, sizeof(_bnk_msg), "[ATM] ATM #%d berhasil dibuat di posisi kamu.", ATMData[idx][atmDBID]);
    SendClientMessage(playerid, 0x00CC00FF, _bnk_msg);
    return 1;
}

COMMAND:delatm(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP) return SendClientMessage(playerid, COLOR_RED, "DevMap/Developer only."), true;
    new atmid;
    if(sscanf(params, "d", atmid)) return SendClientMessage(playerid, COLOR_YELLOW, "Gunakan: /delatm [DB ID]"), true;

    new found = -1;
    for(new i = 0; i < TotalATMs; i++)
    {
        if(ATMData[i][atmDBID] == atmid) { found = i; break; }
    }
    if(found == -1) { format(_bnk_msg, sizeof(_bnk_msg), "ATM ID %d tidak ditemukan.", atmid); return SendClientMessage(playerid, COLOR_RED, _bnk_msg), true; }

    DestroyATMWorld(found);
    mysql_format(MySQL_C1, query, sizeof(query), "DELETE FROM `atm_locations` WHERE `id` = '%d'", atmid);
    mysql_function_query(MySQL_C1, query, false, "", "");

    // Shift array
    for(new i = found; i < TotalATMs - 1; i++)
    {
        ATMData[i][atmDBID] = ATMData[i+1][atmDBID];
        ATMData[i][atmX] = ATMData[i+1][atmX];
        ATMData[i][atmY] = ATMData[i+1][atmY];
        ATMData[i][atmZ] = ATMData[i+1][atmZ];
        ATMData[i][atmRotZ] = ATMData[i+1][atmRotZ];
        ATMData[i][atmObjectID] = ATMData[i+1][atmObjectID];
        ATMData[i][atmLabelID] = ATMData[i+1][atmLabelID];
        ATMData[i][atmPickupID] = ATMData[i+1][atmPickupID];
    }
    TotalATMs--;
    format(_bnk_msg, sizeof(_bnk_msg), "[ATM] ATM #%d berhasil dihapus.", atmid);
    SendClientMessage(playerid, 0x00CC00FF, _bnk_msg);
    return true;
}

COMMAND:moveatm(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP) return SendClientMessage(playerid, COLOR_RED, "DevMap/Developer only."), true;
    new atmid;
    if(sscanf(params, "d", atmid)) return SendClientMessage(playerid, COLOR_YELLOW, "Gunakan: /moveatm [DB ID]"), true;

    new found = -1;
    for(new i = 0; i < TotalATMs; i++)
    {
        if(ATMData[i][atmDBID] == atmid) { found = i; break; }
    }
    if(found == -1) { format(_bnk_msg, sizeof(_bnk_msg), "ATM ID %d tidak ditemukan.", atmid); return SendClientMessage(playerid, COLOR_RED, _bnk_msg), true; }

    DestroyATMWorld(found);
    new Float:px, Float:py, Float:pz, Float:pa;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerFacingAngle(playerid, pa);
    ATMData[found][atmX] = px;
    ATMData[found][atmY] = py;
    ATMData[found][atmZ] = pz;
    ATMData[found][atmRotZ] = pa;
    CreateATMWorld(found);

    mysql_format(MySQL_C1, query, sizeof(query), "UPDATE `atm_locations` SET `pos_x`='%f',`pos_y`='%f',`pos_z`='%f',`rot_z`='%f' WHERE `id`='%d'", px, py, pz, pa, atmid);
    mysql_function_query(MySQL_C1, query, false, "", "");
    format(_bnk_msg, sizeof(_bnk_msg), "[ATM] ATM #%d dipindahkan ke posisi kamu.", atmid);
    SendClientMessage(playerid, 0x00CC00FF, _bnk_msg);
    return true;
}

COMMAND:atmlist(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP) return SendClientMessage(playerid, COLOR_RED, "DevMap/Developer only."), true;
    if(TotalATMs == 0) return SendClientMessage(playerid, COLOR_YELLOW, "Belum ada ATM yang di-set."), true;
    format(_bnk_msg, sizeof(_bnk_msg), "=== ATM Locations (%d) ===", TotalATMs);
    SendClientMessage(playerid, 0x00CC00FF, _bnk_msg);
    for(new i = 0; i < TotalATMs; i++)
    {
        format(_bnk_msg, sizeof(_bnk_msg), "#%d | Pos: %.1f, %.1f, %.1f | Rot: %.1f", ATMData[i][atmDBID], ATMData[i][atmX], ATMData[i][atmY], ATMData[i][atmZ], ATMData[i][atmRotZ]);
        SendClientMessage(playerid, -1, _bnk_msg);
    }
    return true;
}

// ============================================================================
// DEVELOPER COMMANDS - BANK
// ============================================================================

COMMAND:setbank(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP) return SendClientMessage(playerid, COLOR_RED, "DevMap/Developer only."), true;
    if(TotalBanks >= MAX_BANK_LOCATIONS) { format(_bnk_msg, sizeof(_bnk_msg), "Max bank tercapai (%d).", MAX_BANK_LOCATIONS); return SendClientMessage(playerid, COLOR_RED, _bnk_msg), true; }

    new bname[32];
    if(sscanf(params, "s[32]", bname)) format(bname, sizeof(bname), "Bank Westfield");

    new Float:px, Float:py, Float:pz, Float:pa;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerFacingAngle(playerid, pa);

    mysql_format(MySQL_C1, query, sizeof(query), "INSERT INTO `bank_locations` (`name`,`pos_x`,`pos_y`,`pos_z`,`rot_z`,`created_by`,`created_at`) VALUES ('%e','%f','%f','%f','%f','%e','%d')", bname, px, py, pz, pa, PlayerName(playerid), gettime());
    mysql_function_query(MySQL_C1, query, true, "OnBankCreated", "ds[32]", playerid, bname);
    return true;
}

publics: OnBankCreated(playerid, bname[])
{
    new idx = TotalBanks;
    BankData[idx][bnkDBID] = cache_insert_id();
    strmid(BankData[idx][bnkName], bname, 0, strlen(bname), 32);
    new Float:px, Float:py, Float:pz, Float:pa;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerFacingAngle(playerid, pa);
    BankData[idx][bnkX] = px;
    BankData[idx][bnkY] = py;
    BankData[idx][bnkZ] = pz;
    BankData[idx][bnkRotZ] = pa;
    CreateBankWorld(idx);
    TotalBanks++;
    format(_bnk_msg, sizeof(_bnk_msg), "[Bank] Bank '%s' #%d berhasil dibuat.", bname, BankData[idx][bnkDBID]);
    SendClientMessage(playerid, 0x00CC00FF, _bnk_msg);
    return 1;
}

COMMAND:delbank(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP) return SendClientMessage(playerid, COLOR_RED, "DevMap/Developer only."), true;
    new bnkid;
    if(sscanf(params, "d", bnkid)) return SendClientMessage(playerid, COLOR_YELLOW, "Gunakan: /delbank [DB ID]"), true;

    new found = -1;
    for(new i = 0; i < TotalBanks; i++)
    {
        if(BankData[i][bnkDBID] == bnkid) { found = i; break; }
    }
    if(found == -1) { format(_bnk_msg, sizeof(_bnk_msg), "Bank ID %d tidak ditemukan.", bnkid); return SendClientMessage(playerid, COLOR_RED, _bnk_msg), true; }

    DestroyBankWorld(found);
    mysql_format(MySQL_C1, query, sizeof(query), "DELETE FROM `bank_locations` WHERE `id` = '%d'", bnkid);
    mysql_function_query(MySQL_C1, query, false, "", "");

    for(new i = found; i < TotalBanks - 1; i++)
    {
        BankData[i][bnkDBID] = BankData[i+1][bnkDBID];
        strmid(BankData[i][bnkName], BankData[i+1][bnkName], 0, strlen(BankData[i+1][bnkName]), 32);
        BankData[i][bnkX] = BankData[i+1][bnkX];
        BankData[i][bnkY] = BankData[i+1][bnkY];
        BankData[i][bnkZ] = BankData[i+1][bnkZ];
        BankData[i][bnkRotZ] = BankData[i+1][bnkRotZ];
        BankData[i][bnkLabelID] = BankData[i+1][bnkLabelID];
        BankData[i][bnkPickupID] = BankData[i+1][bnkPickupID];
    }
    TotalBanks--;
    format(_bnk_msg, sizeof(_bnk_msg), "[Bank] Bank #%d berhasil dihapus.", bnkid);
    SendClientMessage(playerid, 0x00CC00FF, _bnk_msg);
    return true;
}

COMMAND:movebank(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP) return SendClientMessage(playerid, COLOR_RED, "DevMap/Developer only."), true;
    new bnkid;
    if(sscanf(params, "d", bnkid)) return SendClientMessage(playerid, COLOR_YELLOW, "Gunakan: /movebank [DB ID]"), true;

    new found = -1;
    for(new i = 0; i < TotalBanks; i++)
    {
        if(BankData[i][bnkDBID] == bnkid) { found = i; break; }
    }
    if(found == -1) { format(_bnk_msg, sizeof(_bnk_msg), "Bank ID %d tidak ditemukan.", bnkid); return SendClientMessage(playerid, COLOR_RED, _bnk_msg), true; }

    DestroyBankWorld(found);
    new Float:px, Float:py, Float:pz, Float:pa;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerFacingAngle(playerid, pa);
    BankData[found][bnkX] = px;
    BankData[found][bnkY] = py;
    BankData[found][bnkZ] = pz;
    BankData[found][bnkRotZ] = pa;
    CreateBankWorld(found);

    mysql_format(MySQL_C1, query, sizeof(query), "UPDATE `bank_locations` SET `pos_x`='%f',`pos_y`='%f',`pos_z`='%f',`rot_z`='%f' WHERE `id`='%d'", px, py, pz, pa, bnkid);
    mysql_function_query(MySQL_C1, query, false, "", "");
    format(_bnk_msg, sizeof(_bnk_msg), "[Bank] Bank #%d dipindahkan ke posisi kamu.", bnkid);
    SendClientMessage(playerid, 0x00CC00FF, _bnk_msg);
    return true;
}

COMMAND:banklist(playerid, params[])
{
    if(PlayerInfo[playerid][pAdmin] < ADMIN_DEVMAP) return SendClientMessage(playerid, COLOR_RED, "DevMap/Developer only."), true;
    if(TotalBanks == 0) return SendClientMessage(playerid, COLOR_YELLOW, "Belum ada bank yang di-set."), true;
    format(_bnk_msg, sizeof(_bnk_msg), "=== Bank Locations (%d) ===", TotalBanks);
    SendClientMessage(playerid, 0x00CC00FF, _bnk_msg);
    for(new i = 0; i < TotalBanks; i++)
    {
        format(_bnk_msg, sizeof(_bnk_msg), "#%d | %s | Pos: %.1f, %.1f, %.1f", BankData[i][bnkDBID], BankData[i][bnkName], BankData[i][bnkX], BankData[i][bnkY], BankData[i][bnkZ]);
        SendClientMessage(playerid, -1, _bnk_msg);
    }
    return true;
}
