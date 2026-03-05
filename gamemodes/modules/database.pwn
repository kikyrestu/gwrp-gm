// ============================================================================
// MODULE: database.pwn
// MySQL connection
// ============================================================================

stock MySQLConnect()
{
    new connecttime = GetTickCount();
    MySQL_C1 = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_DB, MYSQL_PASS);
    if(mysql_errno()) return print("-> Connect to database '"MYSQL_DB"' has not been established!");
    else printf("-> Connect to database '"MYSQL_DB"' was successfully installed. (%d ms)", GetTickCount() - connecttime);
    return true;
}

stock MysqlErrorMessage(playerid)
{
    if(playerid == INVALID_PLAYER_ID) return printf("-> Error sending the query to the database! (Error Code: #%d)",mysql_errno());
    else
    {
        PlayerClearChat(playerid, 50);
        new mysqlerror[MAX_CHATMESS_LEN];
        format(mysqlerror,sizeof(mysqlerror),"Server sedang mengalami masalah dengan database. (Kode error: #%d)",mysql_errno());
        SendClientFormattedMessage(playerid, -1, mysqlerror);
        SendClientFormattedMessage(playerid, -1, "Coba lagi nanti, laporkan masalah ini ke - "SUPPORT_EMAIL"");
        PlayerKick(playerid);
        printf("-> Error sending the query to the database! (Error Code: #%d) | (Player: %s[%d])",mysql_errno(),PlayerName(playerid),playerid);
    }
    return true;
}
