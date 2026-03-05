// ============================================================================
// MODULE: account.pwn
// Register, login, save, load account data
// ============================================================================

publics: PlayerCheckRegister(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);

    if(rows) ShowPlayerDialog(playerid, dLogin, DIALOG_STYLE_PASSWORD, "{FFFFFF}Login","{FFFFFF}Akun {006400}sudah terdaftar{FFFFFF}, masukkan password kamu:","Lanjut","Batal");
    else ShowPlayerDialog(playerid, dRegister, DIALOG_STYLE_PASSWORD, "{FFFFFF}Registrasi","{FFFFFF}Akun {8B0000}belum terdaftar{FFFFFF}, masukkan password kamu:","Lanjut","Batal");
    return true;
}

publics: PlayerCreateAccount(playerid)
{
    new regip[MAX_IPADRESS_LEN];
    GetPlayerIp(playerid, regip, sizeof(regip));

    // Get spawn position based on chosen city and spawn location
    new Float:spawnX, Float:spawnY, Float:spawnZ, Float:spawnA;
    GetCitySpawn(TempInfo[playerid][pRegCity], TempInfo[playerid][pRegSpawn], spawnX, spawnY, spawnZ, spawnA);

    // Generate phone number for new account
    GeneratePhoneNumber(PlayerInfo[playerid][pPhoneNumber], 12);

    new bigquery[1024];
    format(bigquery, sizeof(bigquery), "INSERT INTO `accounts` (\
`name`,`ic_name`,`ic_age`,`email`,\
`password`,`regdate`,`regip`,\
`lastdate`,`lastip`,`registered`,\
`invited`,`gender`,`logged`,\
`level`,`money`,`skin`,\
`last_x`,`last_y`,`last_z`,`last_angle`,\
`last_interior`,`last_vw`,\
`is_dead`,`death_tick`,\
`hunger`,`thirst`,`has_tas`,\
`inventory`,`bank_balance`,\
`bank_account`,`phone_number`,`phone_kuota`) VALUES (");

    new vals[512];
    mysql_format(MySQL_C1, vals, sizeof(vals), "\
'%e','%e','%d','',MD5('%e'),\
'%i','%e','0','','0','',\
'%d','0','1','50000','%d',\
'%f','%f','%f','%f',\
'0','0','0','0',\
'100','100','0','',\
'0','','%e','%d')",
        PlayerName(playerid),
        TempInfo[playerid][pRegICName],
        TempInfo[playerid][pRegICAge],
        TempInfo[playerid][pRegPassword],
        gettime(),
        regip,
        TempInfo[playerid][pRegGender],
        TempInfo[playerid][pRegSkin],
        spawnX, spawnY, spawnZ, spawnA,
        PlayerInfo[playerid][pPhoneNumber],
        KUOTA_DEFAULT
    );
    strcat(bigquery, vals, sizeof(bigquery));
    mysql_function_query(MySQL_C1, bigquery, true, "OnAccountCreated", "d", playerid);

    if(mysql_errno()) return MysqlErrorMessage(playerid);

    // Clear temp
    TempInfo[playerid][pRegPassword][0] = EOS;
    TempInfo[playerid][pRegICName][0] = EOS;
    TempInfo[playerid][pRegICAge] = 0;
    TempInfo[playerid][pRegGender] = 0;
    TempInfo[playerid][pRegSkin] = 0;
    TempInfo[playerid][pRegCity] = 0;
    TempInfo[playerid][pRegSpawn] = 0;

    return true;
}

publics: OnAccountCreated(playerid)
{
    mysql_format(MySQL_C1, query, sizeof(query), "SELECT * FROM `"TABLE_ACCOUNTS"` WHERE `name` = '%e' LIMIT 0,1", PlayerName(playerid));
    mysql_function_query(MySQL_C1, query, true, "PlayerLogin", "d", playerid);

    if(mysql_errno()) return MysqlErrorMessage(playerid);
    return true;
}

publics: PlayerLogin(playerid)
{
    new rows, fields;
    cache_get_data(rows, fields);
    if(!rows)
    {
        SendClientFormattedMessage(playerid, -1, "Password salah! Coba lagi.");
        return ShowPlayerDialog(playerid, dLogin, DIALOG_STYLE_PASSWORD, "{FFFFFF}Login","{FFFFFF}Akun sudah terdaftar, masukkan password kamu:","Lanjut","Batal");
    }
    else PlayerLoadData(playerid);
    return true;
}

stock PlayerLoadData(playerid)
{
    new rowid = 0;

    // Basic info
    PlayerInfo[playerid][pID] = cache_get_field_content_int(rowid, "id", MySQL_C1);
    cache_get_field_content(rowid, "ic_name", PlayerInfo[playerid][pICName], MySQL_C1, MAX_IC_NAME_LEN);
    PlayerInfo[playerid][pICAge] = cache_get_field_content_int(rowid, "ic_age", MySQL_C1);
    PlayerInfo[playerid][pRegDate] = cache_get_field_content_int(rowid, "regdate", MySQL_C1);
    cache_get_field_content(rowid, "regip", PlayerInfo[playerid][pRegIP], MySQL_C1, MAX_IPADRESS_LEN);
    PlayerInfo[playerid][pLastDate] = cache_get_field_content_int(rowid, "lastdate", MySQL_C1);
    cache_get_field_content(rowid, "lastip", PlayerInfo[playerid][pLastIP], MySQL_C1, MAX_IPADRESS_LEN);
    PlayerInfo[playerid][pRegistered] = cache_get_field_content_int(rowid, "registered", MySQL_C1);
    PlayerInfo[playerid][pGender] = cache_get_field_content_int(rowid, "gender", MySQL_C1);

    PlayerInfo[playerid][pLevel] = cache_get_field_content_int(rowid, "level", MySQL_C1);
    PlayerInfo[playerid][pAdmin] = cache_get_field_content_int(rowid, "admin_level", MySQL_C1);
    PlayerInfo[playerid][pMoney] = cache_get_field_content_int(rowid, "money", MySQL_C1);
    PlayerInfo[playerid][pSkin] = cache_get_field_content_int(rowid, "skin", MySQL_C1);

    // Last position
    PlayerInfo[playerid][pLastX] = cache_get_field_content_float(rowid, "last_x", MySQL_C1);
    PlayerInfo[playerid][pLastY] = cache_get_field_content_float(rowid, "last_y", MySQL_C1);
    PlayerInfo[playerid][pLastZ] = cache_get_field_content_float(rowid, "last_z", MySQL_C1);
    PlayerInfo[playerid][pLastAngle] = cache_get_field_content_float(rowid, "last_angle", MySQL_C1);
    PlayerInfo[playerid][pLastInterior] = cache_get_field_content_int(rowid, "last_interior", MySQL_C1);
    PlayerInfo[playerid][pLastVW] = cache_get_field_content_int(rowid, "last_vw", MySQL_C1);

    // Death state
    PlayerInfo[playerid][pIsDead] = bool:cache_get_field_content_int(rowid, "is_dead", MySQL_C1);
    PlayerInfo[playerid][pDeathTick] = cache_get_field_content_int(rowid, "death_tick", MySQL_C1);

    // Hunger & Thirst
    PlayerInfo[playerid][pHunger] = cache_get_field_content_int(rowid, "hunger", MySQL_C1);
    PlayerInfo[playerid][pThirst] = cache_get_field_content_int(rowid, "thirst", MySQL_C1);

    // Inventory
    PlayerInfo[playerid][pHasTas] = bool:cache_get_field_content_int(rowid, "has_tas", MySQL_C1);
    new inv_data[256];
    cache_get_field_content(rowid, "inventory", inv_data, MySQL_C1, sizeof(inv_data));
    DeserializeInventory(playerid, inv_data);

    // Bank
    PlayerInfo[playerid][pBank] = cache_get_field_content_int(rowid, "bank_balance", MySQL_C1);
    cache_get_field_content(rowid, "bank_account", PlayerInfo[playerid][pBankAccount], MySQL_C1, 12);

    // Phone
    cache_get_field_content(rowid, "phone_number", PlayerInfo[playerid][pPhoneNumber], MySQL_C1, 12);
    PlayerInfo[playerid][pKuota] = cache_get_field_content_int(rowid, "phone_kuota", MySQL_C1);
    if(PlayerInfo[playerid][pKuota] <= 0) PlayerInfo[playerid][pKuota] = KUOTA_DEFAULT;

    // KTP data
    PlayerInfo[playerid][pHasKTP] = bool:cache_get_field_content_int(rowid, "has_ktp", MySQL_C1);
    cache_get_field_content(rowid, "ktp_nik", PlayerInfo[playerid][pKTPNIK], MySQL_C1, 16);
    cache_get_field_content(rowid, "ktp_fullname", PlayerInfo[playerid][pKTPFullName], MySQL_C1, 64);
    cache_get_field_content(rowid, "birth_place", PlayerInfo[playerid][pBirthPlace], MySQL_C1, 32);
    cache_get_field_content(rowid, "address", PlayerInfo[playerid][pAddress], MySQL_C1, 64);
    cache_get_field_content(rowid, "marital_status", PlayerInfo[playerid][pMaritalStatus], MySQL_C1, 16);
    cache_get_field_content(rowid, "occupation", PlayerInfo[playerid][pOccupation], MySQL_C1, 32);
    cache_get_field_content(rowid, "blood_type", PlayerInfo[playerid][pBloodType], MySQL_C1, 4);

    // SIM data
    PlayerInfo[playerid][pHasSIMA] = bool:cache_get_field_content_int(rowid, "has_sim_a", MySQL_C1);
    PlayerInfo[playerid][pHasSIMB] = bool:cache_get_field_content_int(rowid, "has_sim_b", MySQL_C1);
    PlayerInfo[playerid][pHasSIMC] = bool:cache_get_field_content_int(rowid, "has_sim_c", MySQL_C1);
    cache_get_field_content(rowid, "sim_number", PlayerInfo[playerid][pSIMNumber], MySQL_C1, 16);

    // Load contacts from DB
    LoadContacts(playerid);

    // Load twitter account
    LoadTwitterAccount(playerid);

    // Load faction membership
    LoadPlayerFaction(playerid);

    // Load player job
    LoadPlayerJob(playerid);

    // Load player property
    LoadPlayerProperty(playerid);

    // Check death timer
    if(PlayerInfo[playerid][pIsDead])
    {
        new elapsed = gettime() - PlayerInfo[playerid][pDeathTick];
        if(elapsed >= DEATH_TIME)
        {
            // Timer expired while offline -> hospital respawn after spawn
            PlayerInfo[playerid][pIsDead] = false;
            SetPVarInt(playerid, "NeedHospitalRespawn", 1);
        }
        else
        {
            // Still has time remaining
            new remaining = DEATH_TIME - elapsed;
            PlayerInfo[playerid][pDeathTimer] = SetTimerEx("OnDeathTimerExpire", remaining * 1000, false, "d", playerid);
        }
    }

    if(PlayerInfo[playerid][pRegistered] == 0)
    {
        PlayerInfo[playerid][pLevel] = 1;
        PlayerInfo[playerid][pMoney] = 250;
        PlayerInfo[playerid][pRegistered] = 1;

        mysql_format(MySQL_C1, query, sizeof(query), "UPDATE `"TABLE_ACCOUNTS"` SET `registered` = '1', `level` = '1', `money` = '250' WHERE `name` = '%e'", PlayerName(playerid));
        mysql_function_query(MySQL_C1, query, false, "", "");

        if(mysql_errno()) return MysqlErrorMessage(playerid);

        SetPlayerHealth(playerid, 100);
        SendClientFormattedMessage(playerid, -1, "Registrasi akun berhasil! Selamat bermain.");
    }
    else
    {
        SetPlayerHealth(playerid, 100);
        SendClientFormattedMessage(playerid, -1, "Login berhasil! Selamat datang kembali.");
    }

    PlayerInfo[playerid][pLogged] = true;

    // Set spawn info first (avoids SetPlayerSkin freeze in OnPlayerSpawn)
    new Float:spX = PlayerInfo[playerid][pLastX];
    new Float:spY = PlayerInfo[playerid][pLastY];
    new Float:spZ = PlayerInfo[playerid][pLastZ];
    new Float:spA = PlayerInfo[playerid][pLastAngle];
    if(spX == 0.0 && spY == 0.0) { spX = 1757.07; spY = -1943.84; spZ = 13.56; spA = 0.0; }
    SetSpawnInfo(playerid, 0, PlayerInfo[playerid][pSkin], spX, spY, spZ, spA, -1, -1, -1, -1, -1, -1);
    SpawnPlayer(playerid);

    // Hospital respawn if death timer expired while offline
    if(GetPVarInt(playerid, "NeedHospitalRespawn") == 1)
    {
        DeletePVar(playerid, "NeedHospitalRespawn");
        SetTimerEx("DelayedHospitalRespawn", 1000, false, "d", playerid);
    }

    new lastip[MAX_IPADRESS_LEN];
    GetPlayerIp(playerid, lastip, sizeof(lastip));
    mysql_format(MySQL_C1, query, sizeof(query), "UPDATE `"TABLE_ACCOUNTS"` SET `lastdate` = '%i', `lastip` = '%e', `logged` = '1' WHERE `name` = '%e'", gettime(), lastip, PlayerName(playerid));
    mysql_function_query(MySQL_C1, query, false, "", "");

    if(mysql_errno()) return MysqlErrorMessage(playerid);

    return true;
}

stock PlayerSaveData(playerid)
{
    PlayerInfo[playerid][pLogged] = false;

    new inv_save[256];
    SerializeInventory(playerid, inv_save, sizeof(inv_save));

    new q1[2048], q2[512];
    mysql_format(MySQL_C1, q1, sizeof(q1), "UPDATE `"TABLE_ACCOUNTS"` SET `logged` = '0', `level` = '%d', `admin_level` = '%d', `money` = '%d', `skin` = '%d',", PlayerInfo[playerid][pLevel], PlayerInfo[playerid][pAdmin], PlayerInfo[playerid][pMoney], PlayerInfo[playerid][pSkin]);

    mysql_format(MySQL_C1, q2, sizeof(q2), " `last_x` = '%f', `last_y` = '%f', `last_z` = '%f', `last_angle` = '%f', `last_interior` = '%d', `last_vw` = '%d',", PlayerInfo[playerid][pLastX], PlayerInfo[playerid][pLastY], PlayerInfo[playerid][pLastZ], PlayerInfo[playerid][pLastAngle], PlayerInfo[playerid][pLastInterior], PlayerInfo[playerid][pLastVW]);
    strcat(q1, q2, sizeof(q1));

    mysql_format(MySQL_C1, q2, sizeof(q2), " `is_dead` = '%d', `death_tick` = '%d', `hunger` = '%d', `thirst` = '%d', `has_tas` = '%d', `inventory` = '%e',", PlayerInfo[playerid][pIsDead], PlayerInfo[playerid][pDeathTick], PlayerInfo[playerid][pHunger], PlayerInfo[playerid][pThirst], PlayerInfo[playerid][pHasTas], inv_save);
    strcat(q1, q2, sizeof(q1));

    mysql_format(MySQL_C1, q2, sizeof(q2), " `bank_balance` = '%d', `bank_account` = '%e', `phone_number` = '%e', `phone_kuota` = '%d',", PlayerInfo[playerid][pBank], PlayerInfo[playerid][pBankAccount], PlayerInfo[playerid][pPhoneNumber], PlayerInfo[playerid][pKuota]);
    strcat(q1, q2, sizeof(q1));

    mysql_format(MySQL_C1, q2, sizeof(q2), " `has_ktp` = '%d', `ktp_nik` = '%e', `ktp_fullname` = '%e',", PlayerInfo[playerid][pHasKTP], PlayerInfo[playerid][pKTPNIK], PlayerInfo[playerid][pKTPFullName]);
    strcat(q1, q2, sizeof(q1));

    mysql_format(MySQL_C1, q2, sizeof(q2), " `birth_place` = '%e', `address` = '%e',", PlayerInfo[playerid][pBirthPlace], PlayerInfo[playerid][pAddress]);
    strcat(q1, q2, sizeof(q1));

    mysql_format(MySQL_C1, q2, sizeof(q2), " `marital_status` = '%e', `occupation` = '%e', `blood_type` = '%e',", PlayerInfo[playerid][pMaritalStatus], PlayerInfo[playerid][pOccupation], PlayerInfo[playerid][pBloodType]);
    strcat(q1, q2, sizeof(q1));

    mysql_format(MySQL_C1, q2, sizeof(q2), " `has_sim_a` = '%d', `has_sim_b` = '%d', `has_sim_c` = '%d', `sim_number` = '%e' WHERE `name` = '%e'", PlayerInfo[playerid][pHasSIMA], PlayerInfo[playerid][pHasSIMB], PlayerInfo[playerid][pHasSIMC], PlayerInfo[playerid][pSIMNumber], PlayerInfo[playerid][pName]);
    strcat(q1, q2, sizeof(q1));

    mysql_tquery(MySQL_C1, q1, "", "");

    if(mysql_errno()) return MysqlErrorMessage(playerid);
    return true;
}
