// ============================================================================
// MODULE: phone_bank.pwn
// M-Bank (Mobile Banking) — Full TextDraw UI inside phone frame
// Menu rendered as clickable lines, amount inputs via dialog
// ============================================================================
static _pb_msg[256];

stock OpenPhoneMBank(playerid)
{
    if(!PlayerInfo[playerid][pPhoneOpen]) return 0;

    if(strlen(PlayerInfo[playerid][pBankAccount]) < 5)
    {
        SendClientMessage(playerid, COLOR_YELLOW, "Kamu belum punya rekening bank! Buat di kantor bank.");
        return 0;
    }

    PlayerInfo[playerid][pPhoneApp] = PHONE_APP_MBANK;
    PlayerInfo[playerid][pPhoneScreen] = PHONE_SCREEN_MB_MAIN;
    PlayerInfo[playerid][pPhoneScrollPos] = 0;

    ShowAppScreen(playerid, 0x4A148CDD, "~p~M-Bank");
    HideAppBtns(playerid);

    // Show account info + menu
    new infoline[64];
    format(infoline, sizeof(infoline), "~p~Rek: ~w~%s", PlayerInfo[playerid][pBankAccount]);
    SetAppLine(playerid, 0, infoline);

    new saldoline[64];
    format(saldoline, sizeof(saldoline), "~p~Saldo: ~g~Rp %d", PlayerInfo[playerid][pBank]);
    SetAppLine(playerid, 1, saldoline);

    SetAppLine(playerid, 2, "~p~> ~w~Setor Uang");
    SetAppLine(playerid, 3, "~p~> ~w~Tarik Uang");
    SetAppLine(playerid, 4, "~p~> ~w~Transfer");
    SetAppLine(playerid, 5, "~p~> ~w~Mutasi Rekening");

    new kuotaline[64];
    new kuotaStr[16];
    FormatKuota(PlayerInfo[playerid][pKuota], kuotaStr, sizeof(kuotaStr));
    format(kuotaline, sizeof(kuotaline), "~p~> ~w~Beli Kuota ~g~(%s)", kuotaStr);
    SetAppLine(playerid, 6, kuotaline);

    ShowAppScroll(playerid, false, false);
    return 1;
}

stock HandleMBankLineClick(playerid, lineIdx)
{
    switch(lineIdx)
    {
        case 0, 1: return 1; // Info lines, not actionable
        case 2: // Setor
        {
            new prompt[128];
            format(prompt, sizeof(prompt), "{FFFFFF}Cash: Rp %d\n{AAAAAA}Biaya admin 2%%\n\n{FFFFFF}Jumlah setor:",
                PlayerInfo[playerid][pMoney]);
            ShowPlayerDialog(playerid, DIALOG_PHONE_MBANK_DEPOSIT, DIALOG_STYLE_INPUT,
                "{6A1B9A}M-Bank - Setor", prompt, "Setor", "Batal");
        }
        case 3: // Tarik
        {
            new prompt[128];
            format(prompt, sizeof(prompt), "{FFFFFF}Saldo: Rp %d\n{AAAAAA}Biaya admin 2%%\n\n{FFFFFF}Jumlah tarik:",
                PlayerInfo[playerid][pBank]);
            ShowPlayerDialog(playerid, DIALOG_PHONE_MBANK_WITHDRAW, DIALOG_STYLE_INPUT,
                "{6A1B9A}M-Bank - Tarik", prompt, "Tarik", "Batal");
        }
        case 4: // Transfer
        {
            ShowPlayerDialog(playerid, DIALOG_PHONE_MBANK_TRANSFER, DIALOG_STYLE_INPUT,
                "{6A1B9A}M-Bank - Transfer",
                "{FFFFFF}Masukkan nomor rekening tujuan:\n{AAAAAA}Biaya admin 2%%",
                "Lanjut", "Batal");
        }
        case 5: // Mutasi
        {
            ShowBankHistoryScreen(playerid);
        }
        case 6: // Beli Kuota
        {
            ShowPlayerDialog(playerid, DIALOG_PHONE_MBANK_KUOTA, DIALOG_STYLE_LIST,
                "{6A1B9A}M-Bank - Beli Kuota",
                "Paket Hemat - 1 GB - Rp 500\nPaket Reguler - 5 GB - Rp 2.000\nPaket Pro - 10 GB - Rp 3.500",
                "Beli", "Batal");
        }
    }
    return 1;
}

// ============================================================================
// BANK HISTORY — TextDraw based
// ============================================================================

stock ShowBankHistoryScreen(playerid)
{
    PlayerInfo[playerid][pPhoneScreen] = PHONE_SCREEN_MB_HISTORY;
    PlayerInfo[playerid][pPhoneScrollPos] = 0;

    ShowAppScreen(playerid, 0x4A148CDD, "~p~Mutasi");
    HideAppBtns(playerid);

    ShowBankHistory(playerid, true);
}

stock RefreshBankHistory(playerid)
{
    ShowBankHistory(playerid, true);
}

// Note: ShowBankHistory is defined in bank.pwn
// It will use dialog or textdraw based on flag. We override for in-phone display.

// ============================================================================
// DIALOG HANDLERS
// ============================================================================

stock HandleMBankDepositResponse(playerid, response, inputtext[])
{
    if(!response)
    {
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    new amount = strval(inputtext);
    if(amount < 1)
    {
        SendClientMessage(playerid, COLOR_RED, "Jumlah tidak valid!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    new fee = (amount * MBANK_FEE_PCT) / 100;
    if(fee < 1) fee = 1;
    new total = amount + fee;

    if(PlayerInfo[playerid][pMoney] < total)
    {
        format(_pb_msg, sizeof(_pb_msg), "Uang tidak cukup! Butuh Rp %d (+ fee Rp %d).", amount, fee);
        SendClientMessage(playerid, COLOR_RED, _pb_msg);
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    PlayerInfo[playerid][pMoney] -= total;
    PlayerInfo[playerid][pBank] += amount;
    if(PlayerInfo[playerid][pHudCreated]) UpdateMoneyHUD(playerid);

    LogBankTransaction(playerid, 0, "deposit", amount, fee, PlayerInfo[playerid][pBank]);

    format(_pb_msg, sizeof(_pb_msg), "[M-Bank] Setor Rp %d (fee Rp %d). Saldo: Rp %d", amount, fee, PlayerInfo[playerid][pBank]);
    SendClientMessage(playerid, 0x6A1B9AFF, _pb_msg);

    if(PlayerInfo[playerid][pPhoneOpen])
    {
        OpenPhoneMBank(playerid);
        SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
    }
    return 1;
}

stock HandleMBankWithdrawResponse(playerid, response, inputtext[])
{
    if(!response)
    {
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    new amount = strval(inputtext);
    if(amount < 1)
    {
        SendClientMessage(playerid, COLOR_RED, "Jumlah tidak valid!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    new fee = (amount * MBANK_FEE_PCT) / 100;
    if(fee < 1) fee = 1;
    new total = amount + fee;

    if(PlayerInfo[playerid][pBank] < total)
    {
        format(_pb_msg, sizeof(_pb_msg), "Saldo tidak cukup! Butuh Rp %d (+ fee Rp %d).", amount, fee);
        SendClientMessage(playerid, COLOR_RED, _pb_msg);
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    PlayerInfo[playerid][pBank] -= total;
    PlayerInfo[playerid][pMoney] += amount;
    if(PlayerInfo[playerid][pHudCreated]) UpdateMoneyHUD(playerid);

    LogBankTransaction(playerid, 0, "withdraw", amount, fee, PlayerInfo[playerid][pBank]);

    format(_pb_msg, sizeof(_pb_msg), "[M-Bank] Tarik Rp %d (fee Rp %d). Saldo: Rp %d", amount, fee, PlayerInfo[playerid][pBank]);
    SendClientMessage(playerid, 0x6A1B9AFF, _pb_msg);

    if(PlayerInfo[playerid][pPhoneOpen])
    {
        OpenPhoneMBank(playerid);
        SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
    }
    return 1;
}

stock HandleMBankTransferResponse(playerid, response, inputtext[])
{
    if(!response)
    {
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    if(strlen(inputtext) < 5)
    {
        SendClientMessage(playerid, COLOR_RED, "Nomor rekening tidak valid!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT id, ic_name, bank_account FROM `accounts` WHERE `bank_account` = '%e' LIMIT 1",
        inputtext);
    mysql_function_query(MySQL_C1, query, true, "OnMBankTransferCheck", "d", playerid);
    return 1;
}

publics: OnMBankTransferCheck(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);

    if(!rows)
    {
        SendClientMessage(playerid, COLOR_RED, "Nomor rekening tidak ditemukan!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    new targetid = cache_get_field_content_int(0, "id", MySQL_C1);
    new targetname[24];
    cache_get_field_content(0, "ic_name", targetname, MySQL_C1, 24);

    if(targetid == PlayerInfo[playerid][pID])
    {
        SendClientMessage(playerid, COLOR_YELLOW, "Tidak bisa transfer ke rekening sendiri!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    PlayerInfo[playerid][pTempTarget] = targetid;

    new prompt[128];
    format(prompt, sizeof(prompt), "{FFFFFF}Transfer ke: %s\n{AAAAAA}Biaya admin 2%%\n\n{FFFFFF}Jumlah transfer:", targetname);
    ShowPlayerDialog(playerid, DIALOG_PHONE_MBANK_TRAMT, DIALOG_STYLE_INPUT,
        "{6A1B9A}M-Bank - Jumlah", prompt, "Transfer", "Batal");
    return 1;
}

stock HandleMBankTransferAmtResponse(playerid, response, inputtext[])
{
    if(!response)
    {
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    new amount = strval(inputtext);
    if(amount < 1)
    {
        SendClientMessage(playerid, COLOR_RED, "Jumlah tidak valid!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    new fee = (amount * MBANK_FEE_PCT) / 100;
    if(fee < 1) fee = 1;
    new total = amount + fee;

    if(PlayerInfo[playerid][pBank] < total)
    {
        format(_pb_msg, sizeof(_pb_msg), "Saldo tidak cukup! Butuh Rp %d (+ fee Rp %d).", amount, fee);
        SendClientMessage(playerid, COLOR_RED, _pb_msg);
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    new targetDbId = PlayerInfo[playerid][pTempTarget];

    PlayerInfo[playerid][pBank] -= total;
    LogBankTransaction(playerid, targetDbId, "tf_out", amount, fee, PlayerInfo[playerid][pBank]);

    mysql_format(MySQL_C1, query, sizeof(query),
        "UPDATE `accounts` SET `bank_balance` = `bank_balance` + '%d' WHERE `id` = '%d'",
        amount, targetDbId);
    mysql_function_query(MySQL_C1, query, false, "", "");

    LogBankTransactionByDbId(targetDbId, PlayerInfo[playerid][pID], "tf_in", amount, 0);

    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        if(!PlayerInfo[i][pLogged]) continue;
        if(PlayerInfo[i][pID] == targetDbId)
        {
            PlayerInfo[i][pBank] += amount;
            format(_pb_msg, sizeof(_pb_msg), "[Bank] Menerima transfer Rp %d dari %s.", amount, PlayerInfo[playerid][pICName]);
            SendClientMessage(i, 0x6A1B9AFF, _pb_msg);
            break;
        }
    }

    format(_pb_msg, sizeof(_pb_msg), "[M-Bank] Transfer Rp %d berhasil (fee Rp %d). Saldo: Rp %d", amount, fee, PlayerInfo[playerid][pBank]);
    SendClientMessage(playerid, 0x6A1B9AFF, _pb_msg);

    if(PlayerInfo[playerid][pPhoneOpen])
    {
        OpenPhoneMBank(playerid);
        SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
    }
    return 1;
}

// ============================================================================
// KUOTA PURCHASE
// ============================================================================

stock HandleMBankKuotaResponse(playerid, response, listitem)
{
    if(!response)
    {
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    new kuota_amount, price;
    switch(listitem)
    {
        case 0: { kuota_amount = 1048576;  price = 500;  }   // 1 GB
        case 1: { kuota_amount = 5242880;  price = 2000; }   // 5 GB
        case 2: { kuota_amount = 10485760; price = 3500; }   // 10 GB
        default:
        {
            if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
            return 1;
        }
    }

    if(PlayerInfo[playerid][pBank] < price)
    {
        format(_pb_msg, sizeof(_pb_msg), "Saldo tidak cukup! Butuh Rp %d. Saldo: Rp %d.", price, PlayerInfo[playerid][pBank]);
        SendClientMessage(playerid, COLOR_RED, _pb_msg);
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    PlayerInfo[playerid][pBank] -= price;
    PlayerInfo[playerid][pKuota] += kuota_amount;

    LogBankTransaction(playerid, 0, "kuota", price, 0, PlayerInfo[playerid][pBank]);

    new kuotaStr[16];
    FormatKuota(PlayerInfo[playerid][pKuota], kuotaStr, sizeof(kuotaStr));
    format(_pb_msg, sizeof(_pb_msg), "[M-Bank] Beli kuota berhasil! Kuota: %s. Saldo: Rp %d", kuotaStr, PlayerInfo[playerid][pBank]);
    SendClientMessage(playerid, 0x6A1B9AFF, _pb_msg);

    // Refresh status bar
    if(PlayerInfo[playerid][pPhoneOpen])
    {
        UpdatePhoneStatusBar(playerid);
        OpenPhoneMBank(playerid);
        SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
    }
    return 1;
}
