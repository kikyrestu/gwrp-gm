// ============================================================================
// MODULE: phone_market.pwn
// Marketplace — Full TextDraw UI inside phone frame
// Browse/Sell/NPC Shop as clickable lines, price input via dialog
// ============================================================================

// Temp storage for browse results (per player)
new MarketBrowseIds[MAX_PLAYERS][20];
new MarketBrowseCount[MAX_PLAYERS];

stock OpenPhoneMarket(playerid)
{
    if(!PlayerInfo[playerid][pPhoneOpen]) return 0;

    PlayerInfo[playerid][pPhoneApp] = PHONE_APP_MARKET;
    PlayerInfo[playerid][pPhoneScreen] = PHONE_SCREEN_MK_MAIN;
    PlayerInfo[playerid][pPhoneScrollPos] = 0;

    ShowAppScreen(playerid, 0xE65100DD, "~y~Market");
    HideAppBtns(playerid);

    SetAppLine(playerid, 0, "~y~> ~w~Browse Listing");
    SetAppLine(playerid, 1, "~y~> ~w~Jual Item");
    SetAppLine(playerid, 2, "~o~> ~w~Go Food");
    for(new i = 3; i < MAX_APP_LINES; i++)
        HideAppLine(playerid, i);

    ShowAppScroll(playerid, false, false);
    return 1;
}

stock HandleMarketLineClick(playerid, lineIdx)
{
    switch(lineIdx)
    {
        case 0: ShowMarketBrowseScreen(playerid);
        case 1: ShowMarketSellScreen(playerid);
        case 2: ShowGoFoodScreen(playerid);
    }
    return 1;
}

// ============================================================================
// BROWSE LISTINGS
// ============================================================================

stock ShowMarketBrowseScreen(playerid)
{
    PlayerInfo[playerid][pPhoneScreen] = PHONE_SCREEN_MK_BROWSE;
    PlayerInfo[playerid][pPhoneScrollPos] = 0;
    MarketBrowseCount[playerid] = 0;

    ShowAppScreen(playerid, 0xE65100DD, "~y~Browse");
    HideAppBtns(playerid);

    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT id, seller_name, item_id, amount, price FROM `marketplace_listings` WHERE `active` = 1 ORDER BY id DESC LIMIT 20");
    mysql_function_query(MySQL_C1, query, true, "OnMarketBrowseView", "d", playerid);
}

publics: OnMarketBrowseView(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);

    if(PlayerInfo[playerid][pPhoneScreen] != PHONE_SCREEN_MK_BROWSE) return 1;

    MarketBrowseCount[playerid] = rows;

    if(rows == 0)
    {
        SetAppLine(playerid, 0, "~w~Tidak ada listing aktif.");
        for(new i = 1; i < MAX_APP_LINES; i++)
            HideAppLine(playerid, i);
        ShowAppScroll(playerid, false, false);
        return 1;
    }

    new scroll = PlayerInfo[playerid][pPhoneScrollPos];
    if(scroll > rows - MAX_APP_LINES && rows > MAX_APP_LINES)
        scroll = rows - MAX_APP_LINES;
    if(scroll < 0) scroll = 0;
    PlayerInfo[playerid][pPhoneScrollPos] = scroll;

    for(new i = 0; i < MAX_APP_LINES; i++)
    {
        new idx = scroll + i;
        if(idx < rows)
        {
            new lid = cache_get_field_content_int(idx, "id", MySQL_C1);
            new seller[24];
            cache_get_field_content(idx, "seller_name", seller, MySQL_C1, 24);
            new itemid = cache_get_field_content_int(idx, "item_id", MySQL_C1);
            new amt = cache_get_field_content_int(idx, "amount", MySQL_C1);
            new price = cache_get_field_content_int(idx, "price", MySQL_C1);

            if(i < 20) MarketBrowseIds[playerid][i] = lid;

            new itIdx = GetItemTableIndex(itemid);
            new linebuf[96];
            format(linebuf, sizeof(linebuf), "~y~%s~w~ x%d ~g~Rp%d ~w~(%s)", ItemTable[itIdx][itmName], amt, price, seller);
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

stock RefreshMarketBrowse(playerid)
{
    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT id, seller_name, item_id, amount, price FROM `marketplace_listings` WHERE `active` = 1 ORDER BY id DESC LIMIT 20");
    mysql_function_query(MySQL_C1, query, true, "OnMarketBrowseView", "d", playerid);
}

stock HandleMarketBrowseLineClick(playerid, lineIdx)
{
    new scroll = PlayerInfo[playerid][pPhoneScrollPos];
    new idx = scroll + lineIdx;

    if(idx >= MarketBrowseCount[playerid]) return 1;

    // Re-query to buy
    PlayerInfo[playerid][pTempListingSlot] = idx;
    mysql_format(MySQL_C1, query, sizeof(query),
        "SELECT id, seller_id, seller_name, item_id, amount, price FROM `marketplace_listings` WHERE `active` = 1 ORDER BY id DESC LIMIT 20");
    mysql_function_query(MySQL_C1, query, true, "OnMarketBuyClicked", "dd", playerid, idx);
    return 1;
}

publics: OnMarketBuyClicked(playerid, listIdx)
{
    new rows, fields;
    cache_get_data(rows, fields);

    if(listIdx >= rows)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Listing tidak ditemukan!");
        return 1;
    }

    new lid = cache_get_field_content_int(listIdx, "id", MySQL_C1);
    new sellerid = cache_get_field_content_int(listIdx, "seller_id", MySQL_C1);
    new sellername[24];
    cache_get_field_content(listIdx, "seller_name", sellername, MySQL_C1, 24);
    new itemid = cache_get_field_content_int(listIdx, "item_id", MySQL_C1);
    new amt = cache_get_field_content_int(listIdx, "amount", MySQL_C1);
    new price = cache_get_field_content_int(listIdx, "price", MySQL_C1);

    if(sellerid == PlayerInfo[playerid][pID])
    {
        SendClientFormattedMessage(playerid, COLOR_YELLOW, "Ini listing kamu sendiri!");
        return 1;
    }

    if(PlayerInfo[playerid][pMoney] < price)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Uang tidak cukup! Butuh Rp %d.", price);
        return 1;
    }

    if(!AddInventoryItem(playerid, itemid, amt))
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Kantong/Tas penuh!");
        return 1;
    }

    PlayerInfo[playerid][pMoney] -= price;
    if(PlayerInfo[playerid][pHudCreated]) UpdateMoneyHUD(playerid);

    mysql_format(MySQL_C1, query, sizeof(query),
        "UPDATE `marketplace_listings` SET `active` = 0 WHERE `id` = '%d'", lid);
    mysql_function_query(MySQL_C1, query, false, "", "");

    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        if(!PlayerInfo[i][pLogged]) continue;
        if(PlayerInfo[i][pID] == sellerid)
        {
            PlayerInfo[i][pMoney] += price;
            if(PlayerInfo[i][pHudCreated]) UpdateMoneyHUD(i);
            SendClientFormattedMessage(i, 0xFF9800FF, "[Market] %s membeli %s milikmu seharga Rp %d!",
                PlayerInfo[playerid][pICName], ItemTable[GetItemTableIndex(itemid)][itmName], price);
            break;
        }
    }

    mysql_format(MySQL_C1, query, sizeof(query),
        "UPDATE `accounts` SET `money` = `money` + '%d' WHERE `id` = '%d'", price, sellerid);
    mysql_function_query(MySQL_C1, query, false, "", "");

    new itIdx = GetItemTableIndex(itemid);
    SendClientFormattedMessage(playerid, 0xFF9800FF, "Berhasil membeli %s x%d seharga Rp %d dari %s!",
        ItemTable[itIdx][itmName], amt, price, sellername);

    // Refresh browse
    if(PlayerInfo[playerid][pPhoneOpen] && PlayerInfo[playerid][pPhoneScreen] == PHONE_SCREEN_MK_BROWSE)
        RefreshMarketBrowse(playerid);
    return 1;
}

// ============================================================================
// SELL ITEM
// ============================================================================

// Temp: map display line to actual inventory slot
new MarketSellSlotMap[MAX_PLAYERS][MAX_APP_LINES];

stock ShowMarketSellScreen(playerid)
{
    PlayerInfo[playerid][pPhoneScreen] = PHONE_SCREEN_MK_SELL;
    PlayerInfo[playerid][pPhoneScrollPos] = 0;

    ShowAppScreen(playerid, 0xE65100DD, "~y~Jual Item");
    HideAppBtns(playerid);
    ShowMarketSellList(playerid);
}

stock ShowMarketSellList(playerid)
{
    new maxslots = GetMaxSlots(playerid);
    new scroll = PlayerInfo[playerid][pPhoneScrollPos];

    // Count items
    new itemCount = 0;
    for(new i = 0; i < maxslots; i++)
    {
        if(PlayerInfo[playerid][pInvItems][i] != ITEM_NONE)
            itemCount++;
    }

    if(scroll > itemCount - MAX_APP_LINES && itemCount > MAX_APP_LINES)
        scroll = itemCount - MAX_APP_LINES;
    if(scroll < 0) scroll = 0;
    PlayerInfo[playerid][pPhoneScrollPos] = scroll;

    if(itemCount == 0)
    {
        SetAppLine(playerid, 0, "~w~Tidak ada item untuk dijual.");
        for(new i = 1; i < MAX_APP_LINES; i++)
            HideAppLine(playerid, i);
        ShowAppScroll(playerid, false, false);
        return;
    }

    new shown = 0;
    new skipped = 0;
    for(new i = 0; i < maxslots; i++)
    {
        if(PlayerInfo[playerid][pInvItems][i] == ITEM_NONE) continue;

        if(skipped < scroll) { skipped++; continue; }

        if(shown >= MAX_APP_LINES) break;

        new itIdx = GetItemTableIndex(PlayerInfo[playerid][pInvItems][i]);
        new linebuf[64];
        format(linebuf, sizeof(linebuf), "~y~[%d] ~w~%s x%d", i+1, ItemTable[itIdx][itmName], PlayerInfo[playerid][pInvAmounts][i]);
        SetAppLine(playerid, shown, linebuf);
        MarketSellSlotMap[playerid][shown] = i;
        shown++;
    }

    for(new j = shown; j < MAX_APP_LINES; j++)
        HideAppLine(playerid, j);

    ShowAppScroll(playerid, scroll > 0, (scroll + MAX_APP_LINES) < itemCount);
}

stock HandleMarketSellLineClick(playerid, lineIdx)
{
    new slot = MarketSellSlotMap[playerid][lineIdx];
    if(PlayerInfo[playerid][pInvItems][slot] == ITEM_NONE) return 1;

    PlayerInfo[playerid][pTempListingSlot] = slot;
    new itIdx = GetItemTableIndex(PlayerInfo[playerid][pInvItems][slot]);
    new prompt[128];
    format(prompt, sizeof(prompt), "{FFFFFF}Jual %s x1\nMasukkan harga jual (Rp):", ItemTable[itIdx][itmName]);
    ShowPlayerDialog(playerid, DIALOG_PHONE_MARKET_PRICE, DIALOG_STYLE_INPUT,
        "{FF9800}Market - Harga", prompt, "Jual", "Batal");
    return 1;
}

stock HandleMarketPriceResponse(playerid, response, inputtext[])
{
    if(!response)
    {
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    new price = strval(inputtext);
    if(price < 1 || price > 999999)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Harga harus 1 - 999999!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    new slot = PlayerInfo[playerid][pTempListingSlot];
    if(PlayerInfo[playerid][pInvItems][slot] == ITEM_NONE)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Item tidak ada di slot!");
        if(PlayerInfo[playerid][pPhoneOpen]) SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
        return 1;
    }

    new itemid = PlayerInfo[playerid][pInvItems][slot];
    new itIdx = GetItemTableIndex(itemid);

    RemoveInventoryItem(playerid, slot, 1);

    mysql_format(MySQL_C1, query, sizeof(query),
        "INSERT INTO `marketplace_listings` (`seller_id`, `seller_name`, `item_id`, `amount`, `price`, `active`, `ts`) \
VALUES ('%d', '%e', '%d', '1', '%d', '1', '%d')",
        PlayerInfo[playerid][pID], PlayerInfo[playerid][pICName], itemid, price, gettime());
    mysql_function_query(MySQL_C1, query, false, "", "");

    SendClientFormattedMessage(playerid, 0xFF9800FF, "Listing berhasil! %s dijual seharga Rp %d.",
        ItemTable[itIdx][itmName], price);

    if(PlayerInfo[playerid][pPhoneOpen])
    {
        if(PlayerInfo[playerid][pPhoneScreen] == PHONE_SCREEN_MK_SELL)
            ShowMarketSellList(playerid);
        SelectTextDraw(playerid, PHONE_COLOR_ACCENT);
    }
    return 1;
}

// ============================================================================
// NPC SHOP
// ============================================================================

// Map display line to ItemTable index
new NPCShopItemMap[MAX_PLAYERS][MAX_APP_LINES];

stock ShowNPCShopScreen(playerid)
{
    // Redirected to Go Food
    ShowGoFoodScreen(playerid);
    return;
}

stock ShowNPCShopList(playerid)
{
    ShowGoFoodList(playerid);
}

stock ShowNPCShopListOld(playerid)
{
    new scroll = PlayerInfo[playerid][pPhoneScrollPos];

    // Count purchasable items
    new shopItems = 0;
    for(new i = 1; i < sizeof(ItemTable); i++)
    {
        if(ItemTable[i][itmType] == ITEM_TYPE_FOOD ||
           ItemTable[i][itmType] == ITEM_TYPE_DRINK ||
           ItemTable[i][itmType] == ITEM_TYPE_MEDICAL)
            shopItems++;
    }

    if(scroll > shopItems - MAX_APP_LINES && shopItems > MAX_APP_LINES)
        scroll = shopItems - MAX_APP_LINES;
    if(scroll < 0) scroll = 0;
    PlayerInfo[playerid][pPhoneScrollPos] = scroll;

    new shown = 0;
    new skipped = 0;
    for(new i = 1; i < sizeof(ItemTable); i++)
    {
        if(ItemTable[i][itmType] != ITEM_TYPE_FOOD &&
           ItemTable[i][itmType] != ITEM_TYPE_DRINK &&
           ItemTable[i][itmType] != ITEM_TYPE_MEDICAL) continue;

        if(skipped < scroll) { skipped++; continue; }
        if(shown >= MAX_APP_LINES) break;

        new npcprice = ItemTable[i][itmValue] * 5;
        new linebuf[64];
        format(linebuf, sizeof(linebuf), "~w~%s - ~g~Rp %d", ItemTable[i][itmName], npcprice);
        SetAppLine(playerid, shown, linebuf);
        NPCShopItemMap[playerid][shown] = i;
        shown++;
    }

    for(new j = shown; j < MAX_APP_LINES; j++)
        HideAppLine(playerid, j);

    ShowAppScroll(playerid, scroll > 0, (scroll + MAX_APP_LINES) < shopItems);
}

stock HandleMarketNPCLineClick(playerid, lineIdx)
{
    new tableIdx = NPCShopItemMap[playerid][lineIdx];
    if(tableIdx <= 0 || tableIdx >= sizeof(ItemTable)) return 1;

    new npcprice = ItemTable[tableIdx][itmValue] * 5;

    if(PlayerInfo[playerid][pMoney] < npcprice)
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Uang tidak cukup! Butuh Rp %d.", npcprice);
        return 1;
    }

    if(!AddInventoryItem(playerid, ItemTable[tableIdx][itmID], 1))
    {
        SendClientFormattedMessage(playerid, COLOR_RED, "Kantong/Tas penuh!");
        return 1;
    }

    PlayerInfo[playerid][pMoney] -= npcprice;
    if(PlayerInfo[playerid][pHudCreated]) UpdateMoneyHUD(playerid);
    SendClientFormattedMessage(playerid, 0xFF9800FF, "Membeli %s seharga Rp %d.", ItemTable[tableIdx][itmName], npcprice);

    return 1;
}
