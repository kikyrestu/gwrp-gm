// ============================================================================
// MODULE: phone_twitter.pwn
// Wittiter (Twitter parody) — Registration required, timeline, post, comments
// DB tables: twitter_accounts, phone_tweets, twitter_comments
// ============================================================================

stock OpenPhoneTwitter(playerid)
{
    if(!PlayerInfo[playerid][pPhoneOpen]) return 0;

    PlayerInfo[playerid][pPhoneApp] = PHONE_APP_TWITTER;

    // Clear badge on open
    UpdateBadge(playerid, 2, 0);

    // Check if registered
    if(PlayerInfo[playerid][pTwitterID] == 0)
    {
        // Not registered — show register prompt
        PlayerInfo[playerid][pPhoneScreen] = PHONE_SCREEN_TW_REGISTER;
        ShowAppScreen(playerid, 0x1565C0DD, "~b~Wittiter");
        HideAppBtns(playerid);

        SetAppLine(playerid, 0, "~b~Selamat datang di Wittiter!");
        SetAppLine(playerid, 1, "~w~Kamu belum punya akun.");
        SetAppLine(playerid, 2, "~b~> ~w~Daftar Akun Baru");
        SetAppLine(playerid, 3, "~b~> ~w~Login");
        for(new i = 4; i < MAX_APP_LINES; i++)
            HideAppLine(playerid, i);
        ShowAppScroll(playerid, false, false);
        return 1;
    }

    // Registered — go straight to timeline
    ShowTwitterTimelineScreen(playerid);
    return 1;
}

// Handle line click on register screen
stock HandleTwitterRegLineClick(playerid, lineIdx)
{
    switch(lineIdx)
    {
        case 2: // Daftar
        {
            ShowPlayerDialog(playerid, DIALOG_PHONE_TW_REG_USER, DIALOG_STYLE_INPUT,
                "{1DA1F2}Wittiter - Daftar",
                "{FFFFFF}Buat username (3-20 karakter, tanpa spasi):",
                "Lanjut", "Batal");
        }
        case 3: // Login
        {
            ShowPlayerDialog(playerid, DIALOG_PHONE_TW_LOGIN_USER, DIALOG_STYLE_INPUT,
                "{1DA1F2}Wittiter - Login",
                "{FFFFFF}Masukkan username kamu:",
                "Lanjut", "Batal");
        }
    }
    return 1;
}

// ============================================================================
// REGISTRATION
// ============================================================================

stock HandleTWRegUserResponse(playerid, response, inputtext[])
{
    if(!response) { if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT); return 1; }

    if(strlen(inputtext) < 3 || strlen(inputtext) > 20)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Username harus 3-20 karakter!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    // Check if username contains spaces
    for(new i = 0; i < strlen(inputtext); i++)
    {
        if(inputtext[i] == ' ')
        {
            SendClientFormattedMessage(playerid, COLOR_RED, "Username tidak boleh mengandung spasi!");
            if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
            return 1;
        }
    }

    // Store temp username
    strmid(PlayerInfo[playerid][pTwitterUser], inputtext, 0, strlen(inputtext), 24);

    ShowPlayerDialog(playerid, DIALOG_PHONE_TW_REG_PASS, DIALOG_STYLE_PASSWORD,
        "{1DA1F2}Wittiter - Password",
        "{FFFFFF}Buat password untuk akun Wittiter:",
        "Daftar", "Batal");
    return 1;
}

stock HandleTWRegPassResponse(playerid, response, inputtext[])
{
    if(!response) { if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT); return 1; }

    if(strlen(inputtext) < 3 || strlen(inputtext) > 24)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Password harus 3-24 karakter!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    // Check if username already exists
    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT id FROM `twitter_accounts` WHERE `username` = '%e' LIMIT 1",
        PlayerInfo[playerid][pTwitterUser]);
    mysql_function_query(MySQL_C1, query, true, "OnTWRegCheck", "ds", playerid, inputtext);
    return 1;
}

publics: OnTWRegCheck(playerid, pass[])
{
    new rows, fields;
    cache_get_data(rows, fields);

    if(rows > 0)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Username @%s sudah dipakai!", PlayerInfo[playerid][pTwitterUser]);
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    // Create account
    mysql_format(MySQL_C1, query, sizeof(query),
        "INSERT INTO `twitter_accounts` (`player_id`, `username`, `password`) VALUES ('%d', '%e', MD5('%e'))",
        PlayerInfo[playerid][pID], PlayerInfo[playerid][pTwitterUser], pass);
    mysql_function_query(MySQL_C1, query, true, "OnTWRegCreated", "d", playerid);
    return 1;
}

publics: OnTWRegCreated(playerid)
{
    PlayerInfo[playerid][pTwitterID] = cache_insert_id();

    SendClientFormattedMessage(playerid, 0x1DA1F2FF, "[Wittiter] Akun @%s berhasil dibuat!", PlayerInfo[playerid][pTwitterUser]);

    if(PlayerInfo[playerid][pPhoneOpen])
    {
        ShowTwitterTimelineScreen(playerid);
        SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
    }
    return 1;
}

// ============================================================================
// LOGIN
// ============================================================================

stock HandleTWLoginUserResponse(playerid, response, inputtext[])
{
    if(!response) { if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT); return 1; }

    strmid(PlayerInfo[playerid][pTwitterUser], inputtext, 0, strlen(inputtext), 24);

    ShowPlayerDialog(playerid, DIALOG_PHONE_TW_LOGIN_PASS, DIALOG_STYLE_PASSWORD,
        "{1DA1F2}Wittiter - Login",
        "{FFFFFF}Masukkan password:",
        "Login", "Batal");
    return 1;
}

stock HandleTWLoginPassResponse(playerid, response, inputtext[])
{
    if(!response) { if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT); return 1; }

    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT id, username FROM `twitter_accounts` WHERE `username` = '%e' AND `password` = MD5('%e') AND `player_id` = '%d' LIMIT 1",
        PlayerInfo[playerid][pTwitterUser], inputtext, PlayerInfo[playerid][pID]);
    mysql_function_query(MySQL_C1, query, true, "OnTWLoginCheck", "d", playerid);
    return 1;
}

publics: OnTWLoginCheck(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);

    if(!rows)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Username atau password salah!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    PlayerInfo[playerid][pTwitterID] = cache_get_field_content_int(0, "id", MySQL_C1);
    cache_get_field_content(0, "username", PlayerInfo[playerid][pTwitterUser], MySQL_C1, 24);

    SendClientFormattedMessage(playerid, 0x1DA1F2FF, "[Wittiter] Login berhasil! Selamat datang @%s.", PlayerInfo[playerid][pTwitterUser]);

    if(PlayerInfo[playerid][pPhoneOpen])
    {
        ShowTwitterTimelineScreen(playerid);
        SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
    }
    return 1;
}

// ============================================================================
// TIMELINE — Direct view (no menu)
// ============================================================================

stock ShowTwitterTimelineScreen(playerid)
{
    PlayerInfo[playerid][pPhoneScreen] = PHONE_SCREEN_TW_TL;
    PlayerInfo[playerid][pPhoneScrollPos] = 0;

    ShowAppScreen(playerid, 0x1565C0DD, "~b~Timeline");
    ShowAppBtn(playerid, 1, "~b~Post");
    HideAppBtns(playerid);
    ShowAppBtn(playerid, 1, "~b~Post");

    // Load from DB
    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT t.id, a.username, t.content FROM `phone_tweets` t \
JOIN `twitter_accounts` a ON t.author_id = a.id \
ORDER BY t.id DESC LIMIT 30");
    mysql_function_query(MySQL_C1, query, true, "OnTimelineViewLoaded", "d", playerid);
}

publics: OnTimelineViewLoaded(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);

    if(PlayerInfo[playerid][pPhoneScreen] != PHONE_SCREEN_TW_TL) return 1;

    new scroll = PlayerInfo[playerid][pPhoneScrollPos];

    if(scroll > rows - MAX_APP_LINES && rows > MAX_APP_LINES)
        scroll = rows - MAX_APP_LINES;
    if(scroll < 0) scroll = 0;
    PlayerInfo[playerid][pPhoneScrollPos] = scroll;

    if(rows == 0)
    {
        SetAppLine(playerid, 0, "~w~Belum ada tweet.");
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
            new username[24], content[64];
            cache_get_field_content(idx, "username", username, MySQL_C1, 24);
            cache_get_field_content(idx, "content", content, MySQL_C1, 64);

            new linebuf[96];
            format(linebuf, sizeof(linebuf), "~b~@%s~n~~w~%s", username, content);
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

stock HandleTimelineLineClick(playerid, lineIdx)
{
    // Show tweet detail + comments
    new scroll = PlayerInfo[playerid][pPhoneScrollPos];
    new tweetIdx = scroll + lineIdx;

    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT t.id, a.username, t.content FROM `phone_tweets` t \
JOIN `twitter_accounts` a ON t.author_id = a.id \
ORDER BY t.id DESC LIMIT %d, 1", tweetIdx);
    mysql_function_query(MySQL_C1, query, true, "OnTweetDetailLoaded", "d", playerid);
    return 1;
}

publics: OnTweetDetailLoaded(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);

    if(!rows) { if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT); return 1; }

    new tweetId = cache_get_field_content_int(0, "id", MySQL_C1);
    new username[24], content[128];
    cache_get_field_content(0, "username", username, MySQL_C1, 24);
    cache_get_field_content(0, "content", content, MySQL_C1, 128);

    PlayerInfo[playerid][pTempTweetID] = tweetId;
    PlayerInfo[playerid][pPhoneScreen] = PHONE_SCREEN_TW_DETAIL;

    ShowAppScreen(playerid, 0x1565C0DD, "~b~Detail");
    ShowAppBtn(playerid, 1, "~b~Komentar");
    HideAppBtns(playerid);
    ShowAppBtn(playerid, 1, "~b~Komentar");

    // Line 0: tweet header
    new hdr[64];
    format(hdr, sizeof(hdr), "~b~@%s", username);
    SetAppLine(playerid, 0, hdr);

    // Line 1: tweet content
    new cont[64];
    strmid(cont, content, 0, 60, sizeof(cont));
    new contline[72];
    format(contline, sizeof(contline), "~w~%s", cont);
    SetAppLine(playerid, 1, contline);

    // Line 2: separator
    SetAppLine(playerid, 2, "~b~--- Komentar ---");

    // Load comments for lines 3-6
    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT a.username, c.content FROM `twitter_comments` c \
JOIN `twitter_accounts` a ON c.author_id = a.id \
WHERE c.tweet_id = '%d' ORDER BY c.id DESC LIMIT 4", tweetId);
    mysql_function_query(MySQL_C1, query, true, "OnTweetCommentsLoaded", "d", playerid);
    return 1;
}

publics: OnTweetCommentsLoaded(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);

    if(PlayerInfo[playerid][pPhoneScreen] != PHONE_SCREEN_TW_DETAIL) return 1;

    if(rows == 0)
    {
        SetAppLine(playerid, 3, "~w~Belum ada komentar");
        for(new i = 4; i < MAX_APP_LINES; i++)
            HideAppLine(playerid, i);
    }
    else
    {
        for(new i = 0; i < 4; i++)
        {
            if(i < rows)
            {
                new cusername[24], ccontent[48];
                cache_get_field_content(i, "username", cusername, MySQL_C1, 24);
                cache_get_field_content(i, "content", ccontent, MySQL_C1, 48);
                new linebuf[80];
                format(linebuf, sizeof(linebuf), "~b~@%s: ~w~%s", cusername, ccontent);
                SetAppLine(playerid, 3 + i, linebuf);
            }
            else
            {
                HideAppLine(playerid, 3 + i);
            }
        }
    }

    ShowAppScroll(playerid, false, false);
    return 1;
}

stock RefreshTwitterTL(playerid)
{
    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT t.id, a.username, t.content FROM `phone_tweets` t \
JOIN `twitter_accounts` a ON t.author_id = a.id \
ORDER BY t.id DESC LIMIT 30");
    mysql_function_query(MySQL_C1, query, true, "OnTimelineViewLoaded", "d", playerid);
}

// ============================================================================
// COMPOSE / POST
// ============================================================================

stock HandleTwitterComposeResponse(playerid, response, inputtext[])
{
    if(!response)
    {
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    if(strlen(inputtext) < 1 || strlen(inputtext) > 140)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Tweet harus 1-140 karakter!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    if(PlayerInfo[playerid][pTwitterID] == 0)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Kamu belum terdaftar di Wittiter!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    // Save to DB (new schema with author_id as twitter account id)
    mysql_format(MySQL_C1, query, sizeof(query),
        "INSERT INTO `phone_tweets` (`player_id`, `player_name`, `author_id`, `content`, `ts`) VALUES ('%d', '%e', '%d', '%e', '%d')",
        PlayerInfo[playerid][pID], PlayerInfo[playerid][pTwitterUser], PlayerInfo[playerid][pTwitterID], inputtext, gettime());
    mysql_function_query(MySQL_C1, query, false, "", "");

    // Broadcast with username
    new tweetmsg[180];
    format(tweetmsg, sizeof(tweetmsg), "{1DA1F2}[Wittiter] {FFFFFF}@%s: %s", PlayerInfo[playerid][pTwitterUser], inputtext);
    SendClientMessageToAll(-1, tweetmsg);

    // Send toast notification + badge to all online players
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i) || !PlayerInfo[i][pLogged] || i == playerid) continue;
        new toasttxt[80];
        format(toasttxt, sizeof(toasttxt), "~b~@%s: ~w~%s", PlayerInfo[playerid][pTwitterUser], inputtext);
        ShowPhoneToast(i, toasttxt, 0x1DA1F2DD);
        PlayerInfo[i][pBadgeTW]++;
        UpdateBadge(i, 2, PlayerInfo[i][pBadgeTW]);
    }

    SendClientFormattedMessage(playerid, 0x1DA1F2FF, "Tweet berhasil diposting!");

    // Auto RP
    new rpmsg[80];
    format(rpmsg, sizeof(rpmsg), "* %s bermain sosial media di handphonenya.", PlayerInfo[playerid][pICName]);
    ProxDetector(15.0, playerid, rpmsg, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);

    if(PlayerInfo[playerid][pPhoneOpen])
    {
        ShowTwitterTimelineScreen(playerid);
        SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
    }
    return 1;
}

// ============================================================================
// COMMENT
// ============================================================================

stock HandleTWCommentResponse(playerid, response, inputtext[])
{
    if(!response)
    {
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    if(strlen(inputtext) < 1 || strlen(inputtext) > 100)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Komentar harus 1-100 karakter!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    if(PlayerInfo[playerid][pTwitterID] == 0 || PlayerInfo[playerid][pTempTweetID] == 0)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Error: tidak bisa berkomentar.");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    mysql_format(MySQL_C1, query, sizeof(query),
        "INSERT INTO `twitter_comments` (`tweet_id`, `author_id`, `content`, `ts`) VALUES ('%d', '%d', '%e', '%d')",
        PlayerInfo[playerid][pTempTweetID], PlayerInfo[playerid][pTwitterID], inputtext, gettime());
    mysql_function_query(MySQL_C1, query, false, "", "");

    SendClientFormattedMessage(playerid, 0x1DA1F2FF, "Komentar berhasil ditambahkan!");

    // Refresh detail view
    if(PlayerInfo[playerid][pPhoneOpen] && PlayerInfo[playerid][pPhoneScreen] == PHONE_SCREEN_TW_DETAIL)
    {
        // Reload comments
        mysql_format(MySQL_C1, query, sizeof(query),
            "SELECT a.username, c.content FROM `twitter_comments` c \
JOIN `twitter_accounts` a ON c.author_id = a.id \
WHERE c.tweet_id = '%d' ORDER BY c.id DESC LIMIT 4", PlayerInfo[playerid][pTempTweetID]);
        mysql_function_query(MySQL_C1, query, true, "OnTweetCommentsLoaded", "d", playerid);
        SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
    }
    return 1;
}

// ============================================================================
// HandleTwitterLineClick — dispatches from TW_MAIN (register) or TW_TL screens
// ============================================================================

stock HandleTwitterLineClick(playerid, lineIdx)
{
    // This is for the PHONE_SCREEN_TW_MAIN which is now the register/menu screen
    return HandleTwitterRegLineClick(playerid, lineIdx);
}

// ============================================================================
// INIT — Load twitter account on player login
// ============================================================================

stock LoadTwitterAccount(playerid)
{
    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT id, username FROM `twitter_accounts` WHERE `player_id` = '%d' LIMIT 1",
        PlayerInfo[playerid][pID]);
    mysql_function_query(MySQL_C1, query, true, "OnTwitterAccountLoaded", "d", playerid);
}

publics: OnTwitterAccountLoaded(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);

    if(rows > 0)
    {
        PlayerInfo[playerid][pTwitterID] = cache_get_field_content_int(0, "id", MySQL_C1);
        cache_get_field_content(0, "username", PlayerInfo[playerid][pTwitterUser], MySQL_C1, 24);
    }
    return 1;
}

stock LoadTweetsOnInit()
{
    // No longer needed for in-memory cache — we load from DB each time
    printf("-> Wittiter module loaded (DB-based timeline).");
    return 1;
}
