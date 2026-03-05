// ============================================================================
// MODULE: wallet.pwn
// Dompet (Wallet) system — TextDraw GUI with card slots + cash display
// Open via: LEFT ALT + Y combo OR /dompet
// Cards: KTP (auto), Kartu Bank (if has account), future slots
// Features: Lihat (view detail), Perlihatkan (show to nearby player)
// ============================================================================

// Wallet layout constants
#define WALLET_X                180.0
#define WALLET_X_END            460.0
#define WALLET_Y                200.0
#define WALLET_TITLE_Y          203.0
#define WALLET_CASH_Y           220.0
#define WALLET_GRID_Y           240.0
#define WALLET_SLOT_W           80.0
#define WALLET_SLOT_H           50.0
#define WALLET_SLOT_GAP         10.0
#define WALLET_GRID_X           195.0
#define WALLET_BTN_Y            360.0
#define WALLET_INFO_Y           380.0
#define WALLET_PANEL_H          20.0

#define WALLET_COLOR_BG         0x111111DD
#define WALLET_COLOR_SLOT       0x333333AA
#define WALLET_COLOR_SLOT_FILL  0x444444CC
#define WALLET_COLOR_SLOT_SEL   0xFF8800CC
#define WALLET_COLOR_TITLE      0xFFAA00FF
#define WALLET_COLOR_BTN        0x555555CC

// Card names for labels
stock GetWalletCardName(slot)
{
    new name[16];
    switch(slot)
    {
        case 0: name = "KTP";
        case 1: name = "Kartu Bank";
        case 2: name = "SIM";
        case 3: name = "BPJS";
        case 4: name = "Lisensi";
        default: name = "-";
    }
    return name;
}

stock HasWalletCard(playerid, slot)
{
    switch(slot)
    {
        case WALLET_CARD_KTP: return PlayerInfo[playerid][pHasKTP] ? 1 : 0;
        case WALLET_CARD_BANK: return (strlen(PlayerInfo[playerid][pBankAccount]) > 0) ? 1 : 0;
        case WALLET_CARD_SIM: return (PlayerInfo[playerid][pHasSIMA] || PlayerInfo[playerid][pHasSIMB] || PlayerInfo[playerid][pHasSIMC]) ? 1 : 0;
    }
    return 0;
}

// ============================================================================
// OPEN / CLOSE WALLET
// ============================================================================

stock OpenWallet(playerid)
{
    if(PlayerInfo[playerid][pWalletOpen]) return 0;
    if(PlayerInfo[playerid][pIsDead]) return 0;
    if(PlayerInfo[playerid][pPhoneOpen]) return 0;
    if(PlayerInfo[playerid][pInvOpen]) return 0;

    PlayerInfo[playerid][pWalletOpen] = true;
    PlayerInfo[playerid][pWalletSelected] = -1;

    // Auto RP
    new rpmsg[80];
    format(rpmsg, sizeof(rpmsg), "* %s membuka dompetnya.", PlayerInfo[playerid][pICName]);
    ProxDetector(15.0, playerid, rpmsg, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);

    // Background panel
    PlayerInfo[playerid][ptdWalletBG] = CreatePlayerTextDraw(playerid, WALLET_X, WALLET_Y, "_");
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdWalletBG], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdWalletBG], WALLET_COLOR_BG);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdWalletBG], WALLET_X_END, 0.0);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdWalletBG], 0.0, WALLET_PANEL_H);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdWalletBG], 0);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdWalletBG], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdWalletBG]);

    // Title
    PlayerInfo[playerid][ptdWalletTitle] = CreatePlayerTextDraw(playerid, 320.0, WALLET_TITLE_Y, "~y~DOMPET");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdWalletTitle], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdWalletTitle], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdWalletTitle], 0.3, 1.4);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdWalletTitle], WALLET_COLOR_TITLE);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdWalletTitle], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdWalletTitle]);

    // Cash display
    new cashstr[48];
    new moneyFmt[32];
    FormatMoney(PlayerInfo[playerid][pMoney], moneyFmt, sizeof(moneyFmt));
    format(cashstr, sizeof(cashstr), "~w~Uang Tunai: ~g~%s", moneyFmt);
    PlayerInfo[playerid][ptdWalletCash] = CreatePlayerTextDraw(playerid, 320.0, WALLET_CASH_Y, cashstr);
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdWalletCash], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdWalletCash], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdWalletCash], 0.22, 1.1);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdWalletCash], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdWalletCash], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdWalletCash]);

    // Create 2x3 grid (6 slots)
    for(new row = 0; row < 2; row++)
    {
        for(new col = 0; col < 3; col++)
        {
            new slot = row * 3 + col;
            new Float:sx = WALLET_GRID_X + (WALLET_SLOT_W + WALLET_SLOT_GAP) * float(col);
            new Float:sy = WALLET_GRID_Y + (WALLET_SLOT_H + WALLET_SLOT_GAP) * float(row);
            new bool:hasCard = HasWalletCard(playerid, slot) != 0;

            // Slot BG (clickable)
            PlayerInfo[playerid][ptdWalletSlotBG][slot] = CreatePlayerTextDraw(playerid, sx, sy, "_");
            PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdWalletSlotBG][slot], 1);
            PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdWalletSlotBG][slot], hasCard ? WALLET_COLOR_SLOT_FILL : WALLET_COLOR_SLOT);
            PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdWalletSlotBG][slot], sx + WALLET_SLOT_W, 10.0);
            PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdWalletSlotBG][slot], 0.0, 4.6);
            PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdWalletSlotBG][slot], 0);
            PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdWalletSlotBG][slot], 0);
            PlayerTextDrawSetSelectable(playerid, PlayerInfo[playerid][ptdWalletSlotBG][slot], 1);
            PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdWalletSlotBG][slot]);

            // Icon text inside slot
            new iconStr[16];
            if(hasCard)
            {
                switch(slot)
                {
                    case 0: iconStr = "~y~KTP";
                    case 1: iconStr = "~p~BANK";
                    case 2: iconStr = "~b~SIM";
                    case 3: iconStr = "~g~BPJS";
                    case 4: iconStr = "~r~LIC";
                    default: iconStr = "~w~-";
                }
            }
            else
            {
                iconStr = "~w~-";
            }

            PlayerInfo[playerid][ptdWalletSlotIcon][slot] = CreatePlayerTextDraw(playerid, sx + WALLET_SLOT_W/2.0, sy + 5.0, iconStr);
            PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdWalletSlotIcon][slot], 2);
            PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdWalletSlotIcon][slot], 2);
            PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdWalletSlotIcon][slot], 0.28, 1.4);
            PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdWalletSlotIcon][slot], 0xFFFFFFFF);
            PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdWalletSlotIcon][slot], 0);
            PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdWalletSlotIcon][slot]);

            // Label below icon
            new lblStr[16];
            if(hasCard)
            {
                switch(slot)
                {
                    case 0: lblStr = "~w~KTP";
                    case 1: lblStr = "~w~Bank";
                    case 2: lblStr = "~w~SIM";
                    case 3: lblStr = "~w~BPJS";
                    case 4: lblStr = "~w~Lisensi";
                    default: lblStr = "~w~Kosong";
                }
            }
            else
            {
                lblStr = "~w~Kosong";
            }

            PlayerInfo[playerid][ptdWalletSlotLbl][slot] = CreatePlayerTextDraw(playerid, sx + WALLET_SLOT_W/2.0, sy + 32.0, lblStr);
            PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdWalletSlotLbl][slot], 2);
            PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdWalletSlotLbl][slot], 2);
            PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdWalletSlotLbl][slot], 0.16, 0.9);
            PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdWalletSlotLbl][slot], 0xCCCCCCFF);
            PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdWalletSlotLbl][slot], 0);
            PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdWalletSlotLbl][slot]);
        }
    }

    // Buttons: Lihat | Perlihatkan | Tutup
    new Float:btnW = 80.0;
    new Float:btnGap = 10.0;
    new Float:btnStartX = 200.0;

    // Btn Lihat
    PlayerInfo[playerid][ptdWalletBtnLihat] = CreatePlayerTextDraw(playerid, btnStartX, WALLET_BTN_Y, "~y~Lihat");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdWalletBtnLihat], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdWalletBtnLihat], 2);
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdWalletBtnLihat], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdWalletBtnLihat], WALLET_COLOR_BTN);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdWalletBtnLihat], 15.0, btnW);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdWalletBtnLihat], 0.22, 1.2);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdWalletBtnLihat], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdWalletBtnLihat], 0);
    PlayerTextDrawSetSelectable(playerid, PlayerInfo[playerid][ptdWalletBtnLihat], 1);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdWalletBtnLihat]);

    // Btn Perlihatkan
    PlayerInfo[playerid][ptdWalletBtnShow] = CreatePlayerTextDraw(playerid, btnStartX + btnW + btnGap, WALLET_BTN_Y, "~y~Perlihatkan");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdWalletBtnShow], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdWalletBtnShow], 2);
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdWalletBtnShow], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdWalletBtnShow], WALLET_COLOR_BTN);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdWalletBtnShow], 15.0, btnW + 10.0);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdWalletBtnShow], 0.22, 1.2);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdWalletBtnShow], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdWalletBtnShow], 0);
    PlayerTextDrawSetSelectable(playerid, PlayerInfo[playerid][ptdWalletBtnShow], 1);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdWalletBtnShow]);

    // Btn Tutup
    PlayerInfo[playerid][ptdWalletBtnClose] = CreatePlayerTextDraw(playerid, btnStartX + 2.0 * (btnW + btnGap), WALLET_BTN_Y, "~r~Tutup");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdWalletBtnClose], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdWalletBtnClose], 2);
    PlayerTextDrawUseBox(playerid, PlayerInfo[playerid][ptdWalletBtnClose], 1);
    PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdWalletBtnClose], WALLET_COLOR_BTN);
    PlayerTextDrawTextSize(playerid, PlayerInfo[playerid][ptdWalletBtnClose], 15.0, btnW);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdWalletBtnClose], 0.22, 1.2);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdWalletBtnClose], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdWalletBtnClose], 0);
    PlayerTextDrawSetSelectable(playerid, PlayerInfo[playerid][ptdWalletBtnClose], 1);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdWalletBtnClose]);

    // Info text (shown when a card is selected)
    PlayerInfo[playerid][ptdWalletInfo] = CreatePlayerTextDraw(playerid, 320.0, WALLET_INFO_Y, "~w~Pilih kartu untuk melihat detail");
    PlayerTextDrawFont(playerid, PlayerInfo[playerid][ptdWalletInfo], 2);
    PlayerTextDrawAlignment(playerid, PlayerInfo[playerid][ptdWalletInfo], 2);
    PlayerTextDrawLetterSize(playerid, PlayerInfo[playerid][ptdWalletInfo], 0.2, 1.0);
    PlayerTextDrawColor(playerid, PlayerInfo[playerid][ptdWalletInfo], 0xCCCCCCFF);
    PlayerTextDrawSetShadow(playerid, PlayerInfo[playerid][ptdWalletInfo], 0);
    PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdWalletInfo]);

    SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
    return 1;
}

stock CloseWallet(playerid)
{
    if(!PlayerInfo[playerid][pWalletOpen]) return 0;

    PlayerInfo[playerid][pWalletOpen] = false;
    PlayerInfo[playerid][pWalletSelected] = -1;

    // Destroy all TDs
    if(PlayerInfo[playerid][ptdWalletBG] != PlayerText:INVALID_TEXT_DRAW)
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdWalletBG]);
    if(PlayerInfo[playerid][ptdWalletTitle] != PlayerText:INVALID_TEXT_DRAW)
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdWalletTitle]);
    if(PlayerInfo[playerid][ptdWalletCash] != PlayerText:INVALID_TEXT_DRAW)
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdWalletCash]);
    if(PlayerInfo[playerid][ptdWalletInfo] != PlayerText:INVALID_TEXT_DRAW)
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdWalletInfo]);
    if(PlayerInfo[playerid][ptdWalletBtnLihat] != PlayerText:INVALID_TEXT_DRAW)
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdWalletBtnLihat]);
    if(PlayerInfo[playerid][ptdWalletBtnShow] != PlayerText:INVALID_TEXT_DRAW)
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdWalletBtnShow]);
    if(PlayerInfo[playerid][ptdWalletBtnClose] != PlayerText:INVALID_TEXT_DRAW)
        PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdWalletBtnClose]);

    for(new i = 0; i < MAX_WALLET_SLOTS; i++)
    {
        if(PlayerInfo[playerid][ptdWalletSlotBG][i] != PlayerText:INVALID_TEXT_DRAW)
            PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdWalletSlotBG][i]);
        if(PlayerInfo[playerid][ptdWalletSlotIcon][i] != PlayerText:INVALID_TEXT_DRAW)
            PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdWalletSlotIcon][i]);
        if(PlayerInfo[playerid][ptdWalletSlotLbl][i] != PlayerText:INVALID_TEXT_DRAW)
            PlayerTextDrawDestroy(playerid, PlayerInfo[playerid][ptdWalletSlotLbl][i]);
    }

    ResetWalletTDs(playerid);
    CancelSelectTextDraw(playerid);
    return 1;
}

stock ResetWalletTDs(playerid)
{
    PlayerInfo[playerid][ptdWalletBG] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdWalletTitle] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdWalletCash] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdWalletInfo] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdWalletBtnLihat] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdWalletBtnShow] = PlayerText:INVALID_TEXT_DRAW;
    PlayerInfo[playerid][ptdWalletBtnClose] = PlayerText:INVALID_TEXT_DRAW;
    for(new i = 0; i < MAX_WALLET_SLOTS; i++)
    {
        PlayerInfo[playerid][ptdWalletSlotBG][i] = PlayerText:INVALID_TEXT_DRAW;
        PlayerInfo[playerid][ptdWalletSlotIcon][i] = PlayerText:INVALID_TEXT_DRAW;
        PlayerInfo[playerid][ptdWalletSlotLbl][i] = PlayerText:INVALID_TEXT_DRAW;
    }
}

// ============================================================================
// CLICK HANDLING
// ============================================================================

stock HandleWalletClick(playerid, PlayerText:playertextid)
{
    if(!PlayerInfo[playerid][pWalletOpen]) return 0;

    // Check slot clicks
    for(new i = 0; i < MAX_WALLET_SLOTS; i++)
    {
        if(playertextid == PlayerInfo[playerid][ptdWalletSlotBG][i])
        {
            WalletSelectSlot(playerid, i);
            return 1;
        }
    }

    // Button clicks
    if(playertextid == PlayerInfo[playerid][ptdWalletBtnLihat])
    {
        WalletViewCard(playerid);
        return 1;
    }
    if(playertextid == PlayerInfo[playerid][ptdWalletBtnShow])
    {
        WalletShowCardToPlayer(playerid);
        return 1;
    }
    if(playertextid == PlayerInfo[playerid][ptdWalletBtnClose])
    {
        CloseWallet(playerid);
        return 1;
    }

    return 0;
}

stock HandleWalletEsc(playerid)
{
    if(PlayerInfo[playerid][pWalletOpen])
    {
        CloseWallet(playerid);
        return 1;
    }
    return 0;
}

// ============================================================================
// SLOT SELECTION
// ============================================================================

stock WalletSelectSlot(playerid, slot)
{
    // Deselect previous
    if(PlayerInfo[playerid][pWalletSelected] >= 0 && PlayerInfo[playerid][pWalletSelected] < MAX_WALLET_SLOTS)
    {
        new old = PlayerInfo[playerid][pWalletSelected];
        new bool:hadCard = HasWalletCard(playerid, old) != 0;
        if(PlayerInfo[playerid][ptdWalletSlotBG][old] != PlayerText:INVALID_TEXT_DRAW)
        {
            PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdWalletSlotBG][old], hadCard ? WALLET_COLOR_SLOT_FILL : WALLET_COLOR_SLOT);
            PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdWalletSlotBG][old]);
        }
    }

    PlayerInfo[playerid][pWalletSelected] = slot;

    // Highlight new
    if(PlayerInfo[playerid][ptdWalletSlotBG][slot] != PlayerText:INVALID_TEXT_DRAW)
    {
        PlayerTextDrawBoxColor(playerid, PlayerInfo[playerid][ptdWalletSlotBG][slot], WALLET_COLOR_SLOT_SEL);
        PlayerTextDrawShow(playerid, PlayerInfo[playerid][ptdWalletSlotBG][slot]);
    }

    // Update info text
    if(HasWalletCard(playerid, slot))
    {
        new infoStr[48];
        switch(slot)
        {
            case 0:
            {
                if(PlayerInfo[playerid][pHasKTP])
                    format(infoStr, sizeof(infoStr), "~y~KTP ~w~- %s", PlayerInfo[playerid][pICName]);
                else
                    infoStr = "~r~Belum punya KTP";
            }
            case 1: format(infoStr, sizeof(infoStr), "~p~Kartu Bank ~w~- %s", PlayerInfo[playerid][pBankAccount]);
            default: infoStr = "~w~Kartu ini belum tersedia";
        }
        PlayerTextDrawSetString(playerid, PlayerInfo[playerid][ptdWalletInfo], infoStr);
    }
    else
    {
        PlayerTextDrawSetString(playerid, PlayerInfo[playerid][ptdWalletInfo], "~w~Slot kosong");
    }
}

// ============================================================================
// VIEW CARD DETAIL
// ============================================================================

stock WalletViewCard(playerid)
{
    new slot = PlayerInfo[playerid][pWalletSelected];
    if(slot < 0 || !HasWalletCard(playerid, slot))
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Pilih kartu terlebih dahulu!");
        return;
    }

    // Auto RP
    new rpmsg[80];
    new cardN[16];
    switch(slot)
    {
        case 0: cardN = "KTP";
        case 1: cardN = "Kartu Bank";
        case 2: cardN = "SIM";
        default: cardN = "kartu";
    }
    format(rpmsg, sizeof(rpmsg), "* %s melihat %s-nya.", PlayerInfo[playerid][pICName], cardN);
    ProxDetector(15.0, playerid, rpmsg, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);

    switch(slot)
    {
        case WALLET_CARD_KTP:
        {
            new genderStr[12];
            if(PlayerInfo[playerid][pGender] == 1) genderStr = "Laki-laki";
            else genderStr = "Perempuan";

            new dlg[512];
            new part1[256], part2[256];
            format(part1, sizeof(part1), "{FFFFFF}=== KARTU TANDA PENDUDUK ===\n\n{AAAAAA}NIK: {FFFFFF}%s\n{AAAAAA}Nama Lengkap: {FFFFFF}%s\n{AAAAAA}Tempat Lahir: {FFFFFF}%s\n{AAAAAA}Umur: {FFFFFF}%d tahun\n{AAAAAA}Jenis Kelamin: {FFFFFF}%s\n", PlayerInfo[playerid][pKTPNIK], PlayerInfo[playerid][pKTPFullName], PlayerInfo[playerid][pBirthPlace], PlayerInfo[playerid][pICAge], genderStr);
            format(part2, sizeof(part2), "{AAAAAA}Alamat: {FFFFFF}%s\n{AAAAAA}Status Kawin: {FFFFFF}%s\n{AAAAAA}Pekerjaan: {FFFFFF}%s\n{AAAAAA}Gol. Darah: {FFFFFF}%s\n{AAAAAA}No. HP: {FFFFFF}%s", PlayerInfo[playerid][pAddress], PlayerInfo[playerid][pMaritalStatus], PlayerInfo[playerid][pOccupation], PlayerInfo[playerid][pBloodType], PlayerInfo[playerid][pPhoneNumber]);
            dlg[0] = EOS;
            strcat(dlg, part1, sizeof(dlg));
            strcat(dlg, part2, sizeof(dlg));
            ShowPlayerDialog(playerid, DIALOG_WALLET_KTP_VIEW, DIALOG_STYLE_MSGBOX,
                "{FFAA00}KTP", dlg, "Tutup", "");
        }
        case WALLET_CARD_BANK:
        {
            new moneyFmt[32];
            FormatMoney(PlayerInfo[playerid][pBank], moneyFmt, sizeof(moneyFmt));

            new dlg[256];
            format(dlg, sizeof(dlg),
                "{FFFFFF}=== KARTU BANK ===\n\n\
{AAAAAA}Pemilik: {FFFFFF}%s\n\
{AAAAAA}No. Rekening: {FFFFFF}%s\n\
{AAAAAA}Saldo: {FFFFFF}%s",
                PlayerInfo[playerid][pICName],
                PlayerInfo[playerid][pBankAccount],
                moneyFmt);
            ShowPlayerDialog(playerid, DIALOG_WALLET_BANK_VIEW, DIALOG_STYLE_MSGBOX,
                "{FFAA00}Kartu Bank", dlg, "Tutup", "");
        }
        case WALLET_CARD_SIM:
        {
            new siminfo[256];
            GetSIMInfo(playerid, siminfo, sizeof(siminfo));
            new dlg[512];
            format(dlg, sizeof(dlg), "{FFFFFF}=== SURAT IZIN MENGEMUDI ===\n\n%s", siminfo);
            ShowPlayerDialog(playerid, DIALOG_WALLET_SIM_VIEW, DIALOG_STYLE_MSGBOX,
                "{4169E1}SIM", dlg, "Tutup", "");
        }
    }
}

// ============================================================================
// SHOW CARD TO NEARBY PLAYER (Perlihatkan)
// ============================================================================

stock WalletShowCardToPlayer(playerid)
{
    new slot = PlayerInfo[playerid][pWalletSelected];
    if(slot < 0 || !HasWalletCard(playerid, slot))
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Pilih kartu terlebih dahulu!");
        return;
    }

    // Build list of nearby players within 3m + facing each other
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    new liststr[512];
    liststr[0] = EOS;
    new count = 0;

    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(i == playerid || !IsPlayerConnected(i) || !PlayerInfo[i][pLogged]) continue;

        new Float:tx, Float:ty, Float:tz;
        GetPlayerPos(i, tx, ty, tz);
        new Float:dist = floatsqroot((px-tx)*(px-tx) + (py-ty)*(py-ty) + (pz-tz)*(pz-tz));

        if(dist <= 3.0)
        {
            new tmp[64];
            format(tmp, sizeof(tmp), "%s (ID: %d) - %.1fm\n", PlayerInfo[i][pICName], i, dist);
            strcat(liststr, tmp, sizeof(liststr));
            count++;
        }
    }

    if(count == 0)
    {
        SendClientFormattedMessage(playerid, COLOR_YELLOW, "Tidak ada pemain dalam jarak dekat (3m)!");
        return;
    }

    PlayerInfo[playerid][pWalletShowTarget] = slot; // store which card to show
    CloseWallet(playerid);
    ShowPlayerDialog(playerid, DIALOG_WALLET_SHOW_LIST, DIALOG_STYLE_LIST,
        "{FFAA00}Perlihatkan Kartu", liststr, "Tunjukkan", "Batal");
}

stock HandleWalletShowResponse(playerid, response, listitem)
{
    if(!response) return 1;

    new slot = PlayerInfo[playerid][pWalletShowTarget];

    // Find target player by listitem index (rebuild nearby list)
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    new count = 0;
    new target = INVALID_PLAYER_ID;

    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(i == playerid || !IsPlayerConnected(i) || !PlayerInfo[i][pLogged]) continue;

        new Float:tx, Float:ty, Float:tz;
        GetPlayerPos(i, tx, ty, tz);
        new Float:dist = floatsqroot((px-tx)*(px-tx) + (py-ty)*(py-ty) + (pz-tz)*(pz-tz));

        if(dist <= 3.0)
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
        return 1;
    }

    // Auto RP
    new cardN[16];
    switch(slot)
    {
        case 0: cardN = "KTP";
        case 1: cardN = "Kartu Bank";
        case 2: cardN = "SIM";
        default: cardN = "kartu";
    }
    new rpmsg[96];
    format(rpmsg, sizeof(rpmsg), "* %s menunjukkan %s kepada %s.", PlayerInfo[playerid][pICName], cardN, PlayerInfo[target][pICName]);
    ProxDetector(15.0, playerid, rpmsg, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP, COLOR_RP);

    // Show card content to target player
    switch(slot)
    {
        case WALLET_CARD_KTP:
        {
            new genderStr[12];
            if(PlayerInfo[playerid][pGender] == 1) genderStr = "Laki-laki";
            else genderStr = "Perempuan";

            new dlg[512];
            new p1[256], p2[256];
            format(p1, sizeof(p1), "{FFFFFF}%s menunjukkan KTP:\n\n{AAAAAA}NIK: {FFFFFF}%s\n{AAAAAA}Nama Lengkap: {FFFFFF}%s\n{AAAAAA}Tempat Lahir: {FFFFFF}%s\n{AAAAAA}Umur: {FFFFFF}%d tahun\n{AAAAAA}Jenis Kelamin: {FFFFFF}%s\n", PlayerInfo[playerid][pICName], PlayerInfo[playerid][pKTPNIK], PlayerInfo[playerid][pKTPFullName], PlayerInfo[playerid][pBirthPlace], PlayerInfo[playerid][pICAge], genderStr);
            format(p2, sizeof(p2), "{AAAAAA}Alamat: {FFFFFF}%s\n{AAAAAA}Status Kawin: {FFFFFF}%s\n{AAAAAA}Pekerjaan: {FFFFFF}%s\n{AAAAAA}Gol. Darah: {FFFFFF}%s\n{AAAAAA}No. HP: {FFFFFF}%s", PlayerInfo[playerid][pAddress], PlayerInfo[playerid][pMaritalStatus], PlayerInfo[playerid][pOccupation], PlayerInfo[playerid][pBloodType], PlayerInfo[playerid][pPhoneNumber]);
            dlg[0] = EOS;
            strcat(dlg, p1, sizeof(dlg));
            strcat(dlg, p2, sizeof(dlg));
            ShowPlayerDialog(target, DIALOG_WALLET_KTP_VIEW, DIALOG_STYLE_MSGBOX,
                "{FFAA00}KTP Orang Lain", dlg, "Tutup", "");
        }
        case WALLET_CARD_BANK:
        {
            new dlg[256];
            format(dlg, sizeof(dlg),
                "{FFFFFF}%s menunjukkan Kartu Bank:\n\n\
{AAAAAA}Pemilik: {FFFFFF}%s\n\
{AAAAAA}No. Rekening: {FFFFFF}%s",
                PlayerInfo[playerid][pICName],
                PlayerInfo[playerid][pICName],
                PlayerInfo[playerid][pBankAccount]);
            ShowPlayerDialog(target, DIALOG_WALLET_BANK_VIEW, DIALOG_STYLE_MSGBOX,
                "{FFAA00}Kartu Bank Orang Lain", dlg, "Tutup", "");
        }
        case WALLET_CARD_SIM:
        {
            new siminfo[256];
            GetSIMInfo(playerid, siminfo, sizeof(siminfo));
            new dlg[512];
            format(dlg, sizeof(dlg), "{FFFFFF}%s menunjukkan SIM:\n\n%s", PlayerInfo[playerid][pICName], siminfo);
            ShowPlayerDialog(target, DIALOG_WALLET_SIM_VIEW, DIALOG_STYLE_MSGBOX,
                "{4169E1}SIM Orang Lain", dlg, "Tutup", "");
        }
    }

    SendClientFormattedMessage(playerid, 0xFFAA00FF, "Kamu menunjukkan %s kepada %s.", cardN, PlayerInfo[target][pICName]);
    return 1;
}

// ============================================================================
// WALLET KEY HANDLER (Left Alt + Y combo)
// ============================================================================

stock HandleWalletKey(playerid, newkeys, oldkeys)
{
    // KEY_WALK = Left Alt (0x400 = 1024)
    // KEY_YES = Y
    if((newkeys & KEY_YES) && !(oldkeys & KEY_YES))
    {
        new keys, ud, lr;
        GetPlayerKeys(playerid, keys, ud, lr);
        if(keys & KEY_WALK) // Alt held while pressing Y
        {
            if(PlayerInfo[playerid][pWalletOpen])
                CloseWallet(playerid);
            else
                OpenWallet(playerid);
            return 1;
        }
    }
    return 0;
}

// ============================================================================
// CASH MANAGEMENT with 3M limit
// ============================================================================

stock GivePlayerCash(playerid, amount)
{
    new newAmount = PlayerInfo[playerid][pMoney] + amount;
    if(newAmount > MAX_CASH)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Uang tunai tidak boleh lebih dari Rp 3.000.000! Simpan di bank.");
        return 0;
    }
    if(newAmount < 0) newAmount = 0;
    PlayerInfo[playerid][pMoney] = newAmount;
    return 1;
}
