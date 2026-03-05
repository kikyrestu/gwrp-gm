// ============================================================================
// MODULE: phone_notepad.pwn
// Notepad App — Create, read, delete notes stored in DB
// ============================================================================

stock OpenPhoneNotepad(playerid)
{
    if(!PlayerInfo[playerid][pPhoneOpen]) return 0;

    PlayerInfo[playerid][pPhoneApp] = PHONE_APP_NOTEPAD;
    PlayerInfo[playerid][pPhoneScreen] = PHONE_SCREEN_NOTEPAD;
    PlayerInfo[playerid][pPhoneScrollPos] = 0;

    ShowAppScreen(playerid, 0xF57F17DD, "~y~Notepad");
    ShowAppBtn(playerid, 1, "~y~+ Catatan");
    ShowAppBtn(playerid, 2, "~r~Hapus");

    // Load notes from DB
    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT id, title FROM `phone_notes` WHERE `player_id` = '%d' ORDER BY id DESC LIMIT 30",
        PlayerInfo[playerid][pID]);
    mysql_function_query(MySQL_C1, query, true, "OnNotepadListLoaded", "d", playerid);
    return 1;
}

publics: OnNotepadListLoaded(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);

    if(PlayerInfo[playerid][pPhoneScreen] != PHONE_SCREEN_NOTEPAD) return 1;

    new scroll = PlayerInfo[playerid][pPhoneScrollPos];

    if(scroll > rows - MAX_APP_LINES && rows > MAX_APP_LINES)
        scroll = rows - MAX_APP_LINES;
    if(scroll < 0) scroll = 0;
    PlayerInfo[playerid][pPhoneScrollPos] = scroll;

    if(rows == 0)
    {
        SetAppLine(playerid, 0, "~w~Belum ada catatan");
        for(new i = 1; i < MAX_APP_LINES; i++)
            HideAppLine(playerid, i);
        ShowAppScroll(playerid, false, false);
        return 1;
    }

    for(new i = 0; i < MAX_APP_LINES; i++)
    {
        new idx = scroll + i;
        if(idx < rows)
        {
            new title[48];
            cache_get_field_content(idx, "title", title, MySQL_C1, 48);
            new linebuf[64];
            format(linebuf, sizeof(linebuf), "~y~> ~w~%s", title);
            SetAppLine(playerid, i, linebuf);
        }
        else
        {
            HideAppLine(playerid, i);
        }
    }

    ShowAppScroll(playerid, scroll > 0, (scroll + MAX_APP_LINES) < rows);
    return 1;
}

stock RefreshNotepadList(playerid)
{
    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT id, title FROM `phone_notes` WHERE `player_id` = '%d' ORDER BY id DESC LIMIT 30",
        PlayerInfo[playerid][pID]);
    mysql_function_query(MySQL_C1, query, true, "OnNotepadListLoaded", "d", playerid);
}

stock HandleNotepadLineClick(playerid, lineIdx)
{
    // View the clicked note
    new scroll = PlayerInfo[playerid][pPhoneScrollPos];
    new noteIdx = scroll + lineIdx;

    // Load note by index from the same query order
    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT id, title, body FROM `phone_notes` WHERE `player_id` = '%d' ORDER BY id DESC LIMIT %d, 1",
        PlayerInfo[playerid][pID], noteIdx);
    mysql_function_query(MySQL_C1, query, true, "OnNotepadViewLoaded", "d", playerid);
    return 1;
}

publics: OnNotepadViewLoaded(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);

    if(!rows)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Catatan tidak ditemukan!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    new noteId = cache_get_field_content_int(0, "id", MySQL_C1);
    new title[48], body[256];
    cache_get_field_content(0, "title", title, MySQL_C1, 48);
    cache_get_field_content(0, "body", body, MySQL_C1, 256);

    PlayerInfo[playerid][pNotepadEditID] = noteId;
    PlayerInfo[playerid][pPhoneScreen] = PHONE_SCREEN_NOTE_VIEW;

    ShowAppScreen(playerid, 0xF57F17DD, "~y~Catatan");
    HideAppBtns(playerid);

    // Split body into lines (max 7)
    new headerLine[64];
    format(headerLine, sizeof(headerLine), "~y~%s", title);
    SetAppLine(playerid, 0, headerLine);

    // Show body in lines 1-6 (up to ~50 chars each)
    new bodyLen = strlen(body);
    new lineNum = 1;
    new pos = 0;
    while(pos < bodyLen && lineNum < MAX_APP_LINES)
    {
        new chunk[52];
        new chunkLen = 50;
        if(pos + chunkLen > bodyLen) chunkLen = bodyLen - pos;
        strmid(chunk, body, pos, pos + chunkLen, sizeof(chunk));

        new linebuf[56];
        format(linebuf, sizeof(linebuf), "~w~%s", chunk);
        SetAppLine(playerid, lineNum, linebuf);
        lineNum++;
        pos += chunkLen;
    }
    for(new i = lineNum; i < MAX_APP_LINES; i++)
        HideAppLine(playerid, i);

    ShowAppScroll(playerid, false, false);
    return 1;
}

// ============================================================================
// DIALOG HANDLERS
// ============================================================================

stock HandleNotepadTitleResponse(playerid, response, inputtext[])
{
    if(!response)
    {
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    if(strlen(inputtext) < 1 || strlen(inputtext) > 47)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Judul harus 1-47 karakter!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    strmid(PlayerInfo[playerid][pNotepadTempTitle], inputtext, 0, strlen(inputtext), 48);

    ShowPlayerDialog(playerid, DIALOG_PHONE_NOTEPAD_BODY, DIALOG_STYLE_INPUT,
        "{FFC107}Notepad - Isi Catatan",
        "{FFFFFF}Masukkan isi catatan:",
        "Simpan", "Batal");
    return 1;
}

stock HandleNotepadBodyResponse(playerid, response, inputtext[])
{
    if(!response)
    {
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    if(strlen(inputtext) < 1 || strlen(inputtext) > 255)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Isi catatan harus 1-255 karakter!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    // Save to DB
    mysql_format(MySQL_C1, query, sizeof(query),
        "INSERT INTO `phone_notes` (`player_id`, `title`, `body`, `ts`) VALUES ('%d', '%e', '%e', '%d')",
        PlayerInfo[playerid][pID], PlayerInfo[playerid][pNotepadTempTitle], inputtext, gettime());
    mysql_function_query(MySQL_C1, query, false, "", "");

    SendClientFormattedMessage(playerid, 0xFFC107FF, "[Notepad] Catatan '%s' berhasil disimpan!", PlayerInfo[playerid][pNotepadTempTitle]);

    if(PlayerInfo[playerid][pPhoneOpen])
    {
        OpenPhoneNotepad(playerid);
        SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
    }
    return 1;
}

// Delete note — Btn2 "Hapus" deletes first selected/viewed note
stock HandleNotepadDelete(playerid)
{
    if(PlayerInfo[playerid][pNotepadEditID] <= 0)
    {
        SendClientFormattedMessage(playerid, COLOR_YELLOW, "Buka catatan dulu untuk menghapus!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    mysql_format(MySQL_C1, query, sizeof(query),
        "DELETE FROM `phone_notes` WHERE `id` = '%d' AND `player_id` = '%d' LIMIT 1",
        PlayerInfo[playerid][pNotepadEditID], PlayerInfo[playerid][pID]);
    mysql_function_query(MySQL_C1, query, false, "", "");

    SendClientFormattedMessage(playerid, 0xFFC107FF, "[Notepad] Catatan berhasil dihapus!");
    PlayerInfo[playerid][pNotepadEditID] = -1;

    if(PlayerInfo[playerid][pPhoneOpen])
    {
        OpenPhoneNotepad(playerid);
        SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
    }
    return 1;
}
