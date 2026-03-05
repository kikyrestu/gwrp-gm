// ============================================================================
// MODULE: hud.pwn
// HUD TextDraw: Hunger/Thirst bars with 3D icons + Rp money display
// Position: bottom-right (above chat area)
// ============================================================================

stock CreateHungerThirstHUD(playerid)
{
    // Destroy old HUD first (prevents duplicates on respawn)
    DestroyHungerThirstHUD(playerid);

    // --- THIRST (Sprunk Can icon) ---
    // 3D Model Icon
    PlayerInfo[playerid][ptdThirstIcon] = CreatePlayerTextDraw(playerid, ICON_X, ICON_THIRST_Y, "");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdThirstIcon], 5); // Font 5 = model preview
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdThirstIcon], 19.0, 19.0);
    PlayerTextDrawSetPreviewModel(playerid, PlayerInfo[playerid][ptdThirstIcon], MODEL_SPRUNK);
    PlayerTextDrawSetPreviewRot(playerid, PlayerInfo[playerid][ptdThirstIcon], -16.0, 0.0, -55.0, 1.0);
    PlayerTextDrawBackgroundColor(playerid, PlayerInfo[playerid][ptdThirstIcon], 0x00000033);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdThirstIcon]);

    // Background bar (dark)
    PlayerInfo[playerid][ptdThirstBG] = CreatePlayerTextDraw(playerid, BAR_X_START, BAR_THIRST_Y, "_");
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdThirstBG], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdThirstBG], 0x00000088);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdThirstBG], BAR_X_END, 0.0);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdThirstBG], 0.0, 0.45);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdThirstBG], 0x00000000);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdThirstBG], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdThirstBG]);

    // Percentage text (inside bar area)
    new pctstr[8];
    format(pctstr, sizeof(pctstr), "%d%%", PlayerInfo[playerid][pThirst]);
    PlayerInfo[playerid][ptdThirstPct] = CreatePlayerTextDraw(playerid, PCT_X, BAR_THIRST_Y - 2.0, pctstr);
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdThirstPct], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdThirstPct], 0.15, 0.8);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdThirstPct], 0xFFFFFFFF);
    PlayerTextDrawSetOutline(playerid, PlayerInfo[playerid][ptdThirstPct], 1);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdThirstPct]);

    // Foreground bar
    UpdateThirstBar(playerid);

    // --- HUNGER (Burger icon) ---
    // 3D Model Icon
    PlayerInfo[playerid][ptdHungerIcon] = CreatePlayerTextDraw(playerid, ICON_X, ICON_HUNGER_Y, "");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdHungerIcon], 5); // Font 5 = model preview
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdHungerIcon], 19.0, 19.0);
    PlayerTextDrawSetPreviewModel(playerid, PlayerInfo[playerid][ptdHungerIcon], MODEL_BURGER);
    PlayerTextDrawSetPreviewRot(playerid, PlayerInfo[playerid][ptdHungerIcon], -16.0, 0.0, -55.0, 1.0);
    PlayerTextDrawBackgroundColor(playerid, PlayerInfo[playerid][ptdHungerIcon], 0x00000033);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdHungerIcon]);

    // Background bar (dark)
    PlayerInfo[playerid][ptdHungerBG] = CreatePlayerTextDraw(playerid, BAR_X_START, BAR_HUNGER_Y, "_");
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdHungerBG], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdHungerBG], 0x00000088);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdHungerBG], BAR_X_END, 0.0);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdHungerBG], 0.0, 0.45);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdHungerBG], 0x00000000);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdHungerBG], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdHungerBG]);

    // Percentage text
    format(pctstr, sizeof(pctstr), "%d%%", PlayerInfo[playerid][pHunger]);
    PlayerInfo[playerid][ptdHungerPct] = CreatePlayerTextDraw(playerid, PCT_X, BAR_HUNGER_Y - 2.0, pctstr);
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdHungerPct], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdHungerPct], 0.15, 0.8);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdHungerPct], 0xFFFFFFFF);
    PlayerTextDrawSetOutline(playerid, PlayerInfo[playerid][ptdHungerPct], 1);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdHungerPct]);

    // Foreground bar
    UpdateHungerBar(playerid);

    // --- MONEY display removed (only visible in Wallet) ---
    // CreateMoneyHUD(playerid);

    PlayerInfo[playerid][pHudCreated] = true;
}

stock DestroyHungerThirstHUD(playerid)
{
    if(!PlayerInfo[playerid][pHudCreated]) return;

    if(PlayerInfo[playerid][ptdThirstIcon] != INVALID_PLAYER_TD)
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdThirstIcon]);
    if(PlayerInfo[playerid][ptdThirstBG] != INVALID_PLAYER_TD)
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdThirstBG]);
    if(PlayerInfo[playerid][ptdThirstBar] != INVALID_PLAYER_TD)
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdThirstBar]);
    if(PlayerInfo[playerid][ptdThirstPct] != INVALID_PLAYER_TD)
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdThirstPct]);
    if(PlayerInfo[playerid][ptdHungerIcon] != INVALID_PLAYER_TD)
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdHungerIcon]);
    if(PlayerInfo[playerid][ptdHungerBG] != INVALID_PLAYER_TD)
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdHungerBG]);
    if(PlayerInfo[playerid][ptdHungerBar] != INVALID_PLAYER_TD)
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdHungerBar]);
    if(PlayerInfo[playerid][ptdHungerPct] != INVALID_PLAYER_TD)
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdHungerPct]);
    // ptdMoneyText no longer created, skip destroy
    // if(PlayerInfo[playerid][ptdMoneyText] != INVALID_PLAYER_TD)
    //     PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdMoneyText]);

    PlayerInfo[playerid][ptdThirstIcon] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdThirstBG] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdThirstBar] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdThirstPct] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdHungerIcon] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdHungerBG] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdHungerBar] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdHungerPct] = INVALID_PLAYER_TD;
    PlayerInfo[playerid][ptdMoneyText] = INVALID_PLAYER_TD;

    PlayerInfo[playerid][pHudCreated] = false;
}

stock UpdateThirstBar(playerid)
{
    // Destroy old bar if exists
    if(PlayerInfo[playerid][ptdThirstBar] != INVALID_PLAYER_TD)
    {
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdThirstBar]);
        PlayerInfo[playerid][ptdThirstBar] = INVALID_PLAYER_TD;
    }

    new thirst = PlayerInfo[playerid][pThirst];
    if(thirst < 0) thirst = 0;
    if(thirst > 100) thirst = 100;

    new Float:barEnd = BAR_X_START + (BAR_WIDTH_HUD * float(thirst) / 100.0);

    new color;
    if(thirst > 50) color = 0x2196F3BB;         // Blue
    else if(thirst > THIRST_CANT_RUN) color = 0xFFC107BB; // Amber
    else color = 0xF44336BB;                      // Red

    if(thirst > 0)
    {
        PlayerInfo[playerid][ptdThirstBar] = CreatePlayerTextDraw(playerid, BAR_X_START, BAR_THIRST_Y, "_");
        PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdThirstBar], 1);
        PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdThirstBar], color);
        PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdThirstBar], barEnd, 0.0);
        PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdThirstBar], 0.0, 0.45);
        PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdThirstBar], 0x00000000);
        PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdThirstBar], 0);
        PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdThirstBar]);
    }

    // Update percentage text
    if(PlayerInfo[playerid][ptdThirstPct] != INVALID_PLAYER_TD)
    {
        new pctstr[8];
        format(pctstr, sizeof(pctstr), "%d%%", thirst);
        PlayerTextDrawSetString(playerid, PlayerInfo[playerid][ptdThirstPct], pctstr);
    }
}

stock UpdateHungerBar(playerid)
{
    // Destroy old bar if exists
    if(PlayerInfo[playerid][ptdHungerBar] != INVALID_PLAYER_TD)
    {
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdHungerBar]);
        PlayerInfo[playerid][ptdHungerBar] = INVALID_PLAYER_TD;
    }

    new hunger = PlayerInfo[playerid][pHunger];
    if(hunger < 0) hunger = 0;
    if(hunger > 100) hunger = 100;

    new Float:barEnd = BAR_X_START + (BAR_WIDTH_HUD * float(hunger) / 100.0);

    new color;
    if(hunger > 30) color = 0x4CAF50BB;          // Green
    else if(hunger > HUNGER_PINGSAN) color = 0xFFC107BB; // Amber
    else color = 0xF44336BB;                       // Red

    if(hunger > 0)
    {
        PlayerInfo[playerid][ptdHungerBar] = CreatePlayerTextDraw(playerid, BAR_X_START, BAR_HUNGER_Y, "_");
        PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdHungerBar], 1);
        PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdHungerBar], color);
        PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdHungerBar], barEnd, 0.0);
        PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdHungerBar], 0.0, 0.45);
        PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdHungerBar], 0x00000000);
        PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdHungerBar], 0);
        PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdHungerBar]);
    }

    // Update percentage text
    if(PlayerInfo[playerid][ptdHungerPct] != INVALID_PLAYER_TD)
    {
        new pctstr[8];
        format(pctstr, sizeof(pctstr), "%d%%", hunger);
        PlayerTextDrawSetString(playerid, PlayerInfo[playerid][ptdHungerPct], pctstr);
    }
}

// ============================================================================
// MONEY HUD (Rp)
// ============================================================================

stock CreateMoneyHUD(playerid)
{
    if(PlayerInfo[playerid][ptdMoneyText] != INVALID_PLAYER_TD)
    {
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdMoneyText]);
        PlayerInfo[playerid][ptdMoneyText] = INVALID_PLAYER_TD;
    }

    new moneystr[32];
    FormatMoney(PlayerInfo[playerid][pMoney], moneystr, sizeof(moneystr));

    PlayerInfo[playerid][ptdMoneyText] = CreatePlayerTextDraw(playerid, MONEY_HUD_X, MONEY_HUD_Y, moneystr);
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdMoneyText], 1);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdMoneyText], 0.23, 1.1);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdMoneyText], 3); // Right-aligned

    if(PlayerInfo[playerid][pMoney] >= 0)
        PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdMoneyText], 0x2E8B57FF); // Green
    else
        PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdMoneyText], 0xCC3333FF); // Red

    PlayerTextDrawSetOutline(playerid, PlayerInfo[playerid][ptdMoneyText], 1);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdMoneyText], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdMoneyText]);
}

stock UpdateMoneyHUD(playerid)
{
    if(PlayerInfo[playerid][ptdMoneyText] == INVALID_PLAYER_TD) return;

    new moneystr[32];
    FormatMoney(PlayerInfo[playerid][pMoney], moneystr, sizeof(moneystr));
    PlayerTextDrawSetString(playerid, PlayerInfo[playerid][ptdMoneyText], moneystr);

    if(PlayerInfo[playerid][pMoney] >= 0)
        PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdMoneyText], 0x2E8B57FF);
    else
        PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdMoneyText], 0xCC3333FF);

    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdMoneyText]);
}

stock FormatMoney(amount, output[], maxlen)
{
    new absval = (amount < 0) ? -amount : amount;
    new prefix[4];

    if(amount < 0) prefix = "- ";
    else prefix = "";

    // Format with thousand separator
    if(absval >= 1000000)
        format(output, maxlen, "%sRp %d.%03d.%03d", prefix, absval/1000000, (absval%1000000)/1000, absval%1000);
    else if(absval >= 1000)
        format(output, maxlen, "%sRp %d.%03d", prefix, absval/1000, absval%1000);
    else
        format(output, maxlen, "%sRp %d", prefix, absval);
}
