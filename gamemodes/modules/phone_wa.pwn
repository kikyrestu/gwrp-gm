// ============================================================================
// MODULE: phone_wa.pwn
// WitApp (WhatsApp parody) — Full TextDraw UI inside phone frame
// Contacts list + chat view rendered as TextDraws
// Only SEND message and ADD NUMBER use SA-MP dialogs for text input
// ============================================================================

stock OpenPhoneWA(playerid)
{
    if(!PlayerInfo[playerid][pPhoneOpen]) return 0;

    PlayerInfo[playerid][pPhoneApp] = PHONE_APP_WA;
    PlayerInfo[playerid][pPhoneScreen] = PHONE_SCREEN_WA_MAIN;
    PlayerInfo[playerid][pPhoneScrollPos] = 0;

    ShowAppScreen(playerid, 0x075E54DD, "~g~WitApp");
    ShowAppBtn(playerid, 1, "~g~+ Kontak");
    ShowAppBtn(playerid, 2, "~g~Profil");
    ShowWAContactsList(playerid);
    return 1;
}

stock ShowWAContactsList(playerid)
{
    new scroll = PlayerInfo[playerid][pPhoneScrollPos];
    new total = PlayerInfo[playerid][pPhoneContactCount];

    // Clamp scroll
    if(scroll > total - MAX_APP_LINES && total > MAX_APP_LINES)
        scroll = total - MAX_APP_LINES;
    if(scroll < 0) scroll = 0;
    PlayerInfo[playerid][pPhoneScrollPos] = scroll;

    new shown = 0;
    for(new i = 0; i < MAX_APP_LINES; i++)
    {
        new idx = scroll + i;
        if(idx < total)
        {
            new linebuf[48];
            format(linebuf, sizeof(linebuf), "~w~%s", PhoneContactNames[playerid][idx]);
            SetAppLine(playerid, i, linebuf);
            shown++;
        }
        else
        {
            HideAppLine(playerid, i);
        }
    }

    ShowAppScroll(playerid, scroll > 0, (scroll + MAX_APP_LINES) < total);

    if(total == 0)
    {
        SetAppLine(playerid, 0, "~w~Belum ada kontak");
        for(new i = 1; i < MAX_APP_LINES; i++)
            HideAppLine(playerid, i);
    }
}

stock HandleWALineClick(playerid, lineIdx)
{
    new scroll = PlayerInfo[playerid][pPhoneScrollPos];
    new contactIdx = scroll + lineIdx;

    if(contactIdx >= PlayerInfo[playerid][pPhoneContactCount]) return 1;

    // Open chat with this contact
    PlayerInfo[playerid][pTempTarget] = PlayerInfo[playerid][pPhoneContacts][contactIdx];
    PlayerInfo[playerid][pPhoneChatContact] = contactIdx;
    ShowWAChatView(playerid, contactIdx);
    return 1;
}

// ============================================================================
// CHAT VIEW — TextDraw based, messages as lines
// ============================================================================

stock ShowWAChatView(playerid, contactIdx)
{
    PlayerInfo[playerid][pPhoneScreen] = PHONE_SCREEN_WA_CHAT;
    PlayerInfo[playerid][pPhoneScrollPos] = 0;
    PlayerInfo[playerid][pPhoneChatContact] = contactIdx;

    new titlestr[48];
    format(titlestr, sizeof(titlestr), "~g~%s", PhoneContactNames[playerid][contactIdx]);
    ShowAppScreen(playerid, 0x075E54DD, titlestr);
    ShowAppBtn(playerid, 1, "~g~Kirim Pesan");
    ShowAppBtn(playerid, 1, "~g~Kirim Pesan");
    ShowAppBtn(playerid, 2, "~g~Panggil");

    // Load chat from DB
    new contactDbId = PlayerInfo[playerid][pPhoneContacts][contactIdx];
    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT sender_id, message FROM `phone_messages` WHERE \
(sender_id = '%d' AND receiver_id = '%d') OR \
(sender_id = '%d' AND receiver_id = '%d') \
ORDER BY id DESC LIMIT 20",
        PlayerInfo[playerid][pID], contactDbId,
        contactDbId, PlayerInfo[playerid][pID]);
    mysql_function_query(MySQL_C1, query, true, "OnWAChatViewLoaded", "dd", playerid, contactIdx);
}

publics: OnWAChatViewLoaded(playerid, contactIdx)
{
    new rows, fields;
    cache_get_data(rows, fields);

    if(PlayerInfo[playerid][pPhoneScreen] != PHONE_SCREEN_WA_CHAT) return 1;

    new scroll = PlayerInfo[playerid][pPhoneScrollPos];

    // Messages come in reverse (newest first), display oldest first
    new totalMsgs = rows;

    // Clamp scroll
    if(scroll > totalMsgs - MAX_APP_LINES && totalMsgs > MAX_APP_LINES)
        scroll = totalMsgs - MAX_APP_LINES;
    if(scroll < 0) scroll = 0;
    PlayerInfo[playerid][pPhoneScrollPos] = scroll;

    for(new i = 0; i < MAX_APP_LINES; i++)
    {
        // Show from oldest to newest: reverse index
        new msgIdx = (totalMsgs - 1) - scroll - i;
        if(msgIdx >= 0 && msgIdx < totalMsgs)
        {
            new senderid = cache_get_field_content_int(msgIdx, "sender_id", MySQL_C1);
            new msg[80];
            cache_get_field_content(msgIdx, "message", msg, MySQL_C1, 80);

            new linebuf[96];
            if(senderid == PlayerInfo[playerid][pID])
                format(linebuf, sizeof(linebuf), "~g~> ~w~%s", msg);
            else
                format(linebuf, sizeof(linebuf), "~b~< ~w~%s", msg);
            SetAppLine(playerid, i, linebuf);
        }
        else
        {
            if(i == 0 && totalMsgs == 0)
                SetAppLine(playerid, i, "~w~Belum ada pesan");
            else
                HideAppLine(playerid, i);
        }
    }

    ShowAppScroll(playerid, scroll > 0, (scroll + MAX_APP_LINES) < totalMsgs);
    return 1;
}

stock RefreshWAChat(playerid)
{
    new contactIdx = PlayerInfo[playerid][pPhoneChatContact];
    if(contactIdx < 0 || contactIdx >= PlayerInfo[playerid][pPhoneContactCount]) return;

    new contactDbId = PlayerInfo[playerid][pPhoneContacts][contactIdx];
    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT sender_id, message FROM `phone_messages` WHERE \
(sender_id = '%d' AND receiver_id = '%d') OR \
(sender_id = '%d' AND receiver_id = '%d') \
ORDER BY id DESC LIMIT 20",
        PlayerInfo[playerid][pID], contactDbId,
        contactDbId, PlayerInfo[playerid][pID]);
    mysql_function_query(MySQL_C1, query, true, "OnWAChatViewLoaded", "dd", playerid, contactIdx);
}

// ============================================================================
// ADD CONTACT — Manual name + number input
// ============================================================================

stock ShowWAAddContact(playerid)
{
    ShowPlayerDialog(playerid, DIALOG_PHONE_WA_ADDCONTACT, DIALOG_STYLE_INPUT,
        "{25D366}WitApp - Tambah Kontak",
        "{FFFFFF}Masukkan nama kontak:",
        "Lanjut", "Batal");
}

stock HandleAddContactResponse(playerid, response, inputtext[])
{
    if(!response)
    {
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    if(strlen(inputtext) < 1 || strlen(inputtext) > 23)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Nama kontak harus 1-23 karakter!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    // Store name temporarily, then ask for phone number
    strmid(TempContactName[playerid], inputtext, 0, strlen(inputtext), 24);

    ShowPlayerDialog(playerid, DIALOG_PHONE_WA_ADDNUM, DIALOG_STYLE_INPUT,
        "{25D366}WitApp - Nomor Kontak",
        "{FFFFFF}Masukkan nomor HP kontak:\n{AAAAAA}(Format: 08xxxxxxxxxx)",
        "Simpan", "Batal");
    return 1;
}

stock HandleAddByNumberResponse(playerid, response, inputtext[])
{
    if(!response)
    {
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    if(strlen(inputtext) < 10)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Format nomor tidak valid!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT id, ic_name FROM `accounts` WHERE `phone_number` = '%e' LIMIT 1",
        inputtext);
    mysql_function_query(MySQL_C1, query, true, "OnPhoneNumberSearch", "ds", playerid, inputtext);
    return 1;
}

publics: OnPhoneNumberSearch(playerid, searchnum[])
{
    new rows, fields;
    cache_get_data(rows, fields);

    if(!rows)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Nomor HP tidak ditemukan!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    new dbid = cache_get_field_content_int(0, "id", MySQL_C1);
    new dbname[24];
    cache_get_field_content(0, "ic_name", dbname, MySQL_C1, 24);

    if(dbid == PlayerInfo[playerid][pID])
    {
        SendClientFormattedMessage(playerid, COLOR_YELLOW, "Itu nomor HP kamu sendiri!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    // Use custom name from TempContactName if set, else use DB ic_name
    new contactname[24];
    if(strlen(TempContactName[playerid]) > 0)
    {
        strmid(contactname, TempContactName[playerid], 0, strlen(TempContactName[playerid]), 24);
        TempContactName[playerid][0] = EOS; // clear
    }
    else
    {
        strmid(contactname, dbname, 0, strlen(dbname), 24);
    }

    AddContact(playerid, dbid, contactname);
    SendClientFormattedMessage(playerid, 0x25D366FF, "Kontak %s (%s) berhasil ditambahkan!", contactname, searchnum);

    if(PlayerInfo[playerid][pPhoneOpen] && PlayerInfo[playerid][pPhoneScreen] == PHONE_SCREEN_WA_MAIN)
    {
        ShowWAContactsList(playerid);
        SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
    }
    return 1;
}

// ============================================================================
// SEND MESSAGE — Dialog response handler
// ============================================================================

stock HandleWASendResponse(playerid, response, inputtext[])
{
    if(!response)
    {
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    if(strlen(inputtext) < 1 || strlen(inputtext) > 140)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Pesan harus 1-140 karakter!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    new targetDbId = PlayerInfo[playerid][pTempTarget];

    mysql_format(MySQL_C1, query, sizeof(query),
        "INSERT INTO `phone_messages` (`sender_id`, `receiver_id`, `message`, `ts`) VALUES ('%d', '%d', '%e', '%d')",
        PlayerInfo[playerid][pID], targetDbId, inputtext, gettime());
    mysql_function_query(MySQL_C1, query, false, "", "");

    SendClientFormattedMessage(playerid, 0x25D366FF, "Pesan terkirim!");

    // Auto RP
    new rpmsg[80];
    format(rpmsg, sizeof(rpmsg), "* %s mengetik pesan di handphonenya.", PlayerInfo[playerid][pICName]);
    ProxDetector(15.0, playerid, rpmsg, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);

    // Notify target if online
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        if(!PlayerInfo[i][pLogged]) continue;
        if(PlayerInfo[i][pID] == targetDbId)
        {
            SendClientFormattedMessage(i, 0x25D366FF, "[WitApp] Pesan baru dari %s", PlayerInfo[playerid][pICName]);
            new toasttxt[80];
            format(toasttxt, sizeof(toasttxt), "~g~WitApp: ~w~%s", inputtext);
            ShowPhoneToast(i, toasttxt, 0x25D366DD);
            PlayerInfo[i][pBadgeWA]++;
            UpdateBadge(i, 1, PlayerInfo[i][pBadgeWA]);
            break;
        }
    }

    // Refresh chat view
    if(PlayerInfo[playerid][pPhoneOpen] && PlayerInfo[playerid][pPhoneScreen] == PHONE_SCREEN_WA_CHAT)
    {
        RefreshWAChat(playerid);
        SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
    }
    return 1;
}

// ============================================================================
// CONTACT MANAGEMENT
// ============================================================================

stock AddContact(playerid, contactDbId, const contactName[])
{
    for(new i = 0; i < PlayerInfo[playerid][pPhoneContactCount]; i++)
    {
        if(PlayerInfo[playerid][pPhoneContacts][i] == contactDbId) return 0;
    }

    if(PlayerInfo[playerid][pPhoneContactCount] >= MAX_CONTACTS)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Kontak penuh! Maksimum %d kontak.", MAX_CONTACTS);
        return 0;
    }

    new idx = PlayerInfo[playerid][pPhoneContactCount];
    PlayerInfo[playerid][pPhoneContacts][idx] = contactDbId;
    strmid(PhoneContactNames[playerid][idx], contactName, 0, strlen(contactName), 24);
    PlayerInfo[playerid][pPhoneContactCount]++;

    mysql_format(MySQL_C1, query, sizeof(query),
        "INSERT IGNORE INTO `phone_contacts` (`player_id`, `contact_db_id`, `contact_name`) VALUES ('%d', '%d', '%e')",
        PlayerInfo[playerid][pID], contactDbId, contactName);
    mysql_function_query(MySQL_C1, query, false, "", "");
    return 1;
}

stock LoadContacts(playerid)
{
    PlayerInfo[playerid][pPhoneContactCount] = 0;
    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT contact_db_id, contact_name FROM `phone_contacts` WHERE `player_id` = '%d' ORDER BY id LIMIT %d",
        PlayerInfo[playerid][pID], MAX_CONTACTS);
    mysql_function_query(MySQL_C1, query, true, "OnContactsLoaded", "d", playerid);
}

publics: OnContactsLoaded(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);

    PlayerInfo[playerid][pPhoneContactCount] = 0;
    for(new i = 0; i < rows && i < MAX_CONTACTS; i++)
    {
        PlayerInfo[playerid][pPhoneContacts][i] = cache_get_field_content_int(i, "contact_db_id", MySQL_C1);
        cache_get_field_content(i, "contact_name", PhoneContactNames[playerid][i], MySQL_C1, 24);
        PlayerInfo[playerid][pPhoneContactCount]++;
    }
    return 1;
}

// ============================================================================
// COMMAND
// ============================================================================

COMMAND:tukerkontak(playerid, params[])
{
    ShowWAAddContact(playerid);
    return true;
}
