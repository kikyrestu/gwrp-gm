// ============================================================================
// MODULE: hospital_mapping.pwn
// Hospital Mapping — County General Hospital area (Mekar Pura)
// Created by: Arnathz
// Exported with Texture Studio By: [uL]Pottus and Crayder
// ============================================================================

stock LoadHospitalRemoveBuildings(playerid)
{
    RemoveBuildingForPlayer(playerid, 617, 1178.599, -1332.069, 12.890, 0.250);
    RemoveBuildingForPlayer(playerid, 618, 1177.729, -1315.660, 13.296, 0.250);
    RemoveBuildingForPlayer(playerid, 1440, 1148.680, -1385.189, 13.265, 0.250);
    RemoveBuildingForPlayer(playerid, 1440, 1141.979, -1346.109, 13.265, 0.250);
    RemoveBuildingForPlayer(playerid, 5993, 1110.900, -1328.810, 13.851, 0.250);
    RemoveBuildingForPlayer(playerid, 1297, 1190.770, -1320.859, 15.945, 0.250);
    RemoveBuildingForPlayer(playerid, 620, 1222.660, -1300.920, 12.296, 0.250);
    RemoveBuildingForPlayer(playerid, 620, 1222.660, -1317.739, 12.296, 0.250);
    RemoveBuildingForPlayer(playerid, 620, 1222.660, -1335.050, 12.296, 0.250);
    RemoveBuildingForPlayer(playerid, 620, 1222.660, -1374.609, 12.296, 0.250);
    RemoveBuildingForPlayer(playerid, 620, 1222.660, -1356.550, 12.296, 0.250);
    RemoveBuildingForPlayer(playerid, 620, 1240.920, -1374.609, 12.296, 0.250);
    RemoveBuildingForPlayer(playerid, 620, 1240.920, -1356.550, 12.296, 0.250);
    RemoveBuildingForPlayer(playerid, 620, 1240.920, -1335.050, 12.296, 0.250);
    RemoveBuildingForPlayer(playerid, 620, 1240.920, -1317.739, 12.296, 0.250);
    RemoveBuildingForPlayer(playerid, 620, 1240.920, -1300.920, 12.296, 0.250);
    RemoveBuildingForPlayer(playerid, 739, 1231.140, -1328.089, 12.734, 0.250);
    RemoveBuildingForPlayer(playerid, 739, 1231.140, -1341.849, 12.734, 0.250);
    RemoveBuildingForPlayer(playerid, 739, 1231.140, -1356.209, 12.734, 0.250);
    RemoveBuildingForPlayer(playerid, 5812, 1230.890, -1337.979, 12.539, 0.250);
    RemoveBuildingForPlayer(playerid, 5929, 1230.890, -1337.979, 12.539, 0.250);
    RemoveBuildingForPlayer(playerid, 620, 1184.010, -1343.270, 12.578, 0.250);
    RemoveBuildingForPlayer(playerid, 620, 1184.010, -1353.500, 12.578, 0.250);
}

stock CreateHospitalMapping()
{
    new tmpobjid;
    // --- Floor / Roof panels ---
    tmpobjid = CreateObject(18981, 1233.697265, -1303.037841, 12.138991, 0.000000, 89.999992, -0.300000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 18800, "mroadhelix1", "road1-3", 0x00000000);
    tmpobjid = CreateObject(18981, 1228.486206, -1303.010620, 12.138991, 0.000000, 89.999992, -0.300000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 18800, "mroadhelix1", "road1-3", 0x00000000);
    tmpobjid = CreateObject(18981, 1233.577148, -1328.007202, 12.138991, 0.000000, 90.000007, -0.299998, 300.00);
    SetObjectMaterial(tmpobjid, 0, 18800, "mroadhelix1", "road1-3", 0x00000000);
    tmpobjid = CreateObject(18981, 1228.366088, -1327.979980, 12.138991, 0.000000, 90.000007, -0.299998, 300.00);
    SetObjectMaterial(tmpobjid, 0, 18800, "mroadhelix1", "road1-3", 0x00000000);
    tmpobjid = CreateObject(18981, 1233.568237, -1347.925537, 12.138991, 0.000000, 90.000022, 0.199999, 300.00);
    SetObjectMaterial(tmpobjid, 0, 18800, "mroadhelix1", "road1-3", 0x00000000);
    tmpobjid = CreateObject(18981, 1228.357299, -1347.943847, 12.138991, 0.000000, 90.000022, 0.199999, 300.00);
    SetObjectMaterial(tmpobjid, 0, 18800, "mroadhelix1", "road1-3", 0x00000000);
    tmpobjid = CreateObject(18981, 1233.666015, -1372.895019, 12.138991, 0.000000, 90.000038, 0.199999, 300.00);
    SetObjectMaterial(tmpobjid, 0, 18800, "mroadhelix1", "road1-3", 0x00000000);
    tmpobjid = CreateObject(18981, 1228.455078, -1372.913330, 12.138991, 0.000000, 90.000038, 0.199999, 300.00);
    SetObjectMaterial(tmpobjid, 0, 18800, "mroadhelix1", "road1-3", 0x00000000);

    // --- Roof panels ---
    tmpobjid = CreateObject(18981, 1233.697265, -1303.037841, 19.879024, 0.000000, 90.000000, -0.299998, 300.00);
    SetObjectMaterial(tmpobjid, 0, 13628, "8stad", "stadroof", 0x00000000);
    tmpobjid = CreateObject(18981, 1228.486206, -1303.010620, 19.879024, 0.000000, 90.000000, -0.299998, 300.00);
    SetObjectMaterial(tmpobjid, 0, 13628, "8stad", "stadroof", 0x00000000);
    tmpobjid = CreateObject(18981, 1233.577148, -1328.007202, 19.879024, 0.000000, 90.000015, -0.299998, 300.00);
    SetObjectMaterial(tmpobjid, 0, 13628, "8stad", "stadroof", 0x00000000);
    tmpobjid = CreateObject(18981, 1228.366088, -1327.979980, 19.879024, 0.000000, 90.000015, -0.299998, 300.00);
    SetObjectMaterial(tmpobjid, 0, 13628, "8stad", "stadroof", 0x00000000);
    tmpobjid = CreateObject(18981, 1233.568237, -1347.925537, 19.879024, 0.000000, 90.000030, 0.199999, 300.00);
    SetObjectMaterial(tmpobjid, 0, 13628, "8stad", "stadroof", 0x00000000);
    tmpobjid = CreateObject(18981, 1228.357299, -1347.943847, 19.879024, 0.000000, 90.000030, 0.199999, 300.00);
    SetObjectMaterial(tmpobjid, 0, 13628, "8stad", "stadroof", 0x00000000);
    tmpobjid = CreateObject(18981, 1233.666015, -1372.895019, 19.879024, 0.000000, 90.000045, 0.199999, 300.00);
    SetObjectMaterial(tmpobjid, 0, 13628, "8stad", "stadroof", 0x00000000);
    tmpobjid = CreateObject(18981, 1228.455078, -1372.913330, 19.879024, 0.000000, 90.000045, 0.199999, 300.00);
    SetObjectMaterial(tmpobjid, 0, 13628, "8stad", "stadroof", 0x00000000);

    // --- Hospital tower windows ---
    tmpobjid = CreateObject(18765, 1161.768920, -1332.405273, 32.919921, 0.000000, 0.000000, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10871, "blacksky_sfse", "ws_skywinsgreen", 0x00000000);
    tmpobjid = CreateObject(18765, 1161.768920, -1322.445434, 32.919921, 0.000000, 0.000000, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10871, "blacksky_sfse", "ws_skywinsgreen", 0x00000000);
    tmpobjid = CreateObject(18765, 1161.768920, -1332.405273, 37.869972, 0.000000, 0.000007, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10871, "blacksky_sfse", "ws_skywinsgreen", 0x00000000);
    tmpobjid = CreateObject(18765, 1161.768920, -1322.445434, 37.869972, 0.000000, 0.000007, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10871, "blacksky_sfse", "ws_skywinsgreen", 0x00000000);
    tmpobjid = CreateObject(18765, 1161.768920, -1332.405273, 42.849998, 0.000000, 0.000007, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10871, "blacksky_sfse", "ws_skywinsgreen", 0x00000000);

    // --- Tower roof/panels ---
    tmpobjid = CreateObject(19449, 1166.692260, -1332.232788, 42.932182, 0.000000, 0.000000, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "white", 0x00000000);
    tmpobjid = CreateObject(19449, 1166.692260, -1335.293334, 36.372192, 90.000000, 0.000000, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "white", 0x00000000);
    tmpobjid = CreateObject(19449, 1166.692260, -1335.293334, 26.742170, 90.000000, 0.000000, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "white", 0x00000000);
    tmpobjid = CreateObject(19449, 1156.830078, -1332.232788, 42.932182, 0.000000, 0.000007, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "white", 0x00000000);
    tmpobjid = CreateObject(19449, 1156.830078, -1335.293334, 36.372192, 89.999992, 89.999992, -89.999992, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "white", 0x00000000);
    tmpobjid = CreateObject(19449, 1156.830078, -1335.293334, 26.742170, 89.999992, 89.999992, -89.999992, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "white", 0x00000000);
    tmpobjid = CreateObject(19449, 1164.962158, -1323.433959, 42.023216, -32.799995, 90.000007, 0.000003, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "white", 0x00000000);
    tmpobjid = CreateObject(19449, 1163.292602, -1324.333740, 40.627883, -32.799995, 180.000015, 0.000003, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "white", 0x00000000);
    tmpobjid = CreateObject(19449, 1166.633056, -1324.333740, 40.627883, -32.799995, 180.000015, 0.000003, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "white", 0x00000000);
    tmpobjid = CreateObject(19449, 1158.530395, -1323.433959, 42.023216, -32.799995, 90.000015, 0.000009, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "white", 0x00000000);
    tmpobjid = CreateObject(19449, 1156.860839, -1324.333740, 40.627883, -32.799995, 180.000030, 0.000009, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "white", 0x00000000);
    tmpobjid = CreateObject(19449, 1160.201293, -1324.333740, 40.627883, -32.799995, 180.000030, 0.000009, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "white", 0x00000000);
    tmpobjid = CreateObject(19449, 1161.760009, -1323.433959, 42.023216, -32.799995, 90.000022, 0.000014, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "white", 0x00000000);
    tmpobjid = CreateObject(19449, 1160.090454, -1324.333740, 40.627883, -32.799995, 180.000045, 0.000014, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "white", 0x00000000);
    tmpobjid = CreateObject(19449, 1163.430908, -1324.333740, 40.627883, -32.799995, 180.000045, 0.000014, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "white", 0x00000000);
    tmpobjid = CreateObject(19449, 1166.682250, -1332.953735, 39.548076, 57.399963, 0.000000, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "white", 0x00000000);
    tmpobjid = CreateObject(19449, 1156.831909, -1332.953735, 39.548076, 57.399963, 0.000000, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "white", 0x00000000);
    tmpobjid = CreateObject(19449, 1166.692260, -1332.232788, 42.082214, 0.000000, 0.000000, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "white", 0x00000000);
    tmpobjid = CreateObject(19449, 1156.843139, -1332.232788, 42.082214, 0.000000, 0.000000, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10765, "airportgnd_sfse", "white", 0x00000000);

    // --- Glass canopy (ambulance/lobby) ---
    tmpobjid = CreateObject(19379, 1176.821289, -1355.926757, 18.330373, 0.000000, 90.000000, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 17588, "lae2coast_alpha", "plainglass", 0x00000000);
    tmpobjid = CreateObject(19379, 1176.821289, -1365.547851, 18.330373, 0.000000, 90.000000, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 17588, "lae2coast_alpha", "plainglass", 0x00000000);

    // --- Yellow bollards ---
    tmpobjid = CreateObject(997, 1193.806518, -1304.761474, 12.437631, 0.000000, 0.000000, 90.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 5168, "lashops6_las2", "yellow2_128", 0x00000000);
    tmpobjid = CreateObject(997, 1193.806518, -1308.301635, 12.437631, 0.000000, 0.000000, 90.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 5168, "lashops6_las2", "yellow2_128", 0x00000000);
    tmpobjid = CreateObject(997, 1193.806518, -1311.842285, 12.437631, 0.000000, 0.000000, 90.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 5168, "lashops6_las2", "yellow2_128", 0x00000000);
    tmpobjid = CreateObject(997, 1193.806518, -1315.443115, 12.437631, 0.000000, 0.000000, 90.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 5168, "lashops6_las2", "yellow2_128", 0x00000000);
    tmpobjid = CreateObject(997, 1193.806518, -1319.073120, 12.437631, 0.000000, 0.000000, 90.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 5168, "lashops6_las2", "yellow2_128", 0x00000000);
    tmpobjid = CreateObject(997, 1193.806518, -1332.015380, 12.437631, 0.000022, 0.000000, 89.999931, 300.00);
    SetObjectMaterial(tmpobjid, 0, 5168, "lashops6_las2", "yellow2_128", 0x00000000);
    tmpobjid = CreateObject(997, 1193.806518, -1335.555541, 12.437631, 0.000022, 0.000000, 89.999931, 300.00);
    SetObjectMaterial(tmpobjid, 0, 5168, "lashops6_las2", "yellow2_128", 0x00000000);
    tmpobjid = CreateObject(997, 1193.806518, -1346.327026, 12.437631, 0.000022, 0.000000, 89.999931, 300.00);
    SetObjectMaterial(tmpobjid, 0, 5168, "lashops6_las2", "yellow2_128", 0x00000000);
    tmpobjid = CreateObject(997, 1190.265014, -1304.761474, 12.437631, 0.000007, 0.000000, 89.999977, 300.00);
    SetObjectMaterial(tmpobjid, 0, 5168, "lashops6_las2", "yellow2_128", 0x00000000);
    tmpobjid = CreateObject(997, 1190.265014, -1308.301635, 12.437631, 0.000007, 0.000000, 89.999977, 300.00);
    SetObjectMaterial(tmpobjid, 0, 5168, "lashops6_las2", "yellow2_128", 0x00000000);
    tmpobjid = CreateObject(997, 1190.265014, -1311.842285, 12.437631, 0.000007, 0.000000, 89.999977, 300.00);
    SetObjectMaterial(tmpobjid, 0, 5168, "lashops6_las2", "yellow2_128", 0x00000000);
    tmpobjid = CreateObject(997, 1190.265014, -1315.443115, 12.437631, 0.000007, 0.000000, 89.999977, 300.00);
    SetObjectMaterial(tmpobjid, 0, 5168, "lashops6_las2", "yellow2_128", 0x00000000);
    tmpobjid = CreateObject(997, 1190.265014, -1319.073120, 12.437631, 0.000007, 0.000000, 89.999977, 300.00);
    SetObjectMaterial(tmpobjid, 0, 5168, "lashops6_las2", "yellow2_128", 0x00000000);
    tmpobjid = CreateObject(997, 1190.265014, -1332.015380, 12.437631, 0.000029, 0.000000, 89.999908, 300.00);
    SetObjectMaterial(tmpobjid, 0, 5168, "lashops6_las2", "yellow2_128", 0x00000000);
    tmpobjid = CreateObject(997, 1190.265014, -1335.555541, 12.437631, 0.000029, 0.000000, 89.999908, 300.00);
    SetObjectMaterial(tmpobjid, 0, 5168, "lashops6_las2", "yellow2_128", 0x00000000);
    tmpobjid = CreateObject(997, 1190.265014, -1346.327026, 12.437631, 0.000029, 0.000000, 89.999908, 300.00);
    SetObjectMaterial(tmpobjid, 0, 5168, "lashops6_las2", "yellow2_128", 0x00000000);

    // --- Drop-off zone & walkway ---
    tmpobjid = CreateObject(19447, 1193.812500, -1323.912841, 10.648432, 0.000000, 0.000000, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 18835, "mickytextures", "whiteforletters", 0x00000000);
    tmpobjid = CreateObject(19447, 1190.442138, -1323.912841, 10.648432, 0.000000, 0.000000, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 18835, "mickytextures", "whiteforletters", 0x00000000);
    tmpobjid = CreateObject(19447, 1191.972412, -1323.912841, 12.308441, 0.000000, 90.000000, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 14534, "ab_wooziea", "ab_fabricRed", 0x00000000);

    // --- Text signs ---
    tmpobjid = CreateObject(19482, 1178.182617, -1338.981933, 12.898822, 0.000000, -87.500030, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "ferry_build14", 0x00000000);
    SetObjectMaterialText(tmpobjid, "{ffffff} EMERGENCY", 0, 130, "Calibri", 100, 1, 0x00000000, 0x00000000, 1);
    tmpobjid = CreateObject(19482, 1179.171997, -1339.232177, 12.855641, 0.000000, -87.500030, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "ferry_build14", 0x00000000);
    SetObjectMaterialText(tmpobjid, "{ff2828} ONLY", 0, 130, "Calibri", 199, 1, 0x00000000, 0x00000000, 1);
    tmpobjid = CreateObject(19482, 1192.192993, -1324.478027, 12.398449, 0.000007, 270.000000, 89.999977, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "ferry_build14", 0x00000000);
    SetObjectMaterialText(tmpobjid, "{ffffff} DROP-OFF", 0, 130, "Ariel", 60, 1, 0x00000000, 0x00000000, 1);
    tmpobjid = CreateObject(19482, 1192.192993, -1323.767700, 12.398449, 0.000007, 270.000000, 89.999977, 300.00);
    SetObjectMaterial(tmpobjid, 0, 10101, "2notherbuildsfe", "ferry_build14", 0x00000000);
    SetObjectMaterialText(tmpobjid, "{ffffff}ONLY", 0, 130, "Ariel", 110, 1, 0x00000000, 0x00000000, 1);

    // --- Awnings / Canopy panels (blue dusky) ---
    tmpobjid = CreateObject(19448, 1174.362792, -1305.880126, 21.757839, 0.000000, 90.000000, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 1675, "wshxrefhse", "duskyblue_128", 0x00000000);
    tmpobjid = CreateObject(19448, 1174.362792, -1305.880126, 20.987823, 0.000000, 90.000000, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 1675, "wshxrefhse", "duskyblue_128", 0x00000000);
    tmpobjid = CreateObject(19448, 1174.362792, -1315.272216, 20.679372, 13.300000, 90.000000, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 1675, "wshxrefhse", "duskyblue_128", 0x00000000);
    tmpobjid = CreateObject(19448, 1174.362792, -1315.095092, 19.930009, 13.300000, 90.000000, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 1675, "wshxrefhse", "duskyblue_128", 0x00000000);
    tmpobjid = CreateObject(19448, 1174.362792, -1324.588256, 19.607852, 0.000000, 90.000007, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 1675, "wshxrefhse", "duskyblue_128", 0x00000000);
    tmpobjid = CreateObject(19448, 1174.362792, -1324.588256, 18.837837, 0.000000, 90.000007, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 1675, "wshxrefhse", "duskyblue_128", 0x00000000);
    tmpobjid = CreateObject(19448, 1174.362792, -1334.148803, 19.607852, 0.000000, 90.000015, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 1675, "wshxrefhse", "duskyblue_128", 0x00000000);
    tmpobjid = CreateObject(19448, 1174.362792, -1334.148803, 18.837837, 0.000000, 90.000015, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 1675, "wshxrefhse", "duskyblue_128", 0x00000000);
    tmpobjid = CreateObject(19448, 1174.362792, -1343.779174, 19.607852, 0.000000, 90.000022, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 1675, "wshxrefhse", "duskyblue_128", 0x00000000);
    tmpobjid = CreateObject(19448, 1174.362792, -1343.779174, 18.837837, 0.000000, 90.000022, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 1675, "wshxrefhse", "duskyblue_128", 0x00000000);
    tmpobjid = CreateObject(19448, 1174.362792, -1353.122558, 20.374225, -9.499992, 90.000022, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 1675, "wshxrefhse", "duskyblue_128", 0x00000000);
    tmpobjid = CreateObject(19448, 1174.362792, -1353.249633, 19.614770, -9.499992, 90.000022, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 1675, "wshxrefhse", "duskyblue_128", 0x00000000);
    tmpobjid = CreateObject(19448, 1174.362792, -1362.630249, 21.167877, 0.000000, 90.000030, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 1675, "wshxrefhse", "duskyblue_128", 0x00000000);
    tmpobjid = CreateObject(19448, 1174.362792, -1362.630249, 20.397861, 0.000000, 90.000030, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 1675, "wshxrefhse", "duskyblue_128", 0x00000000);
    tmpobjid = CreateObject(19448, 1174.362792, -1371.939819, 21.167877, 0.000000, 90.000038, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 1675, "wshxrefhse", "duskyblue_128", 0x00000000);
    tmpobjid = CreateObject(19448, 1174.362792, -1371.939819, 20.397861, 0.000000, 90.000038, 0.000000, 300.00);
    SetObjectMaterial(tmpobjid, 0, 1675, "wshxrefhse", "duskyblue_128", 0x00000000);

    // --- Parking structure pillars & floors ---
    tmpobjid = CreateObject(18980, 1217.429199, -1383.957885, 7.868984, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1217.429199, -1292.016967, 7.868984, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1244.448974, -1383.957885, 7.868984, 0.000000, 0.000007, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1244.448974, -1292.016967, 7.868984, 0.000000, 0.000007, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1217.429199, -1309.577636, 7.868984, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1217.429199, -1364.848022, 7.868984, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1217.429199, -1336.297607, 7.868984, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1244.448974, -1309.577636, 7.868984, 0.000000, 0.000007, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1244.448974, -1364.848022, 7.868984, 0.000000, 0.000007, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1244.448974, -1336.297607, 7.868984, 0.000000, 0.000007, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1229.609741, -1292.016967, 14.268967, 0.000000, 90.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1232.451049, -1292.016967, 14.268967, 0.000000, 90.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1229.609741, -1383.957763, 14.268967, 0.000000, 90.000007, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1232.451049, -1383.957763, 14.268967, 0.000000, 90.000007, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1217.428955, -1304.016113, 14.268967, 0.000000, 90.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(18980, 1217.428955, -1371.945434, 14.268967, 0.000000, 90.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(4638, 1218.245605, -1317.541870, 14.298437, 0.000000, 0.000000, 180.000000, 300.00);
    tmpobjid = CreateObject(18980, 1217.428955, -1337.086303, 14.268967, 0.000000, 90.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(4638, 1218.245605, -1358.424072, 14.298437, 0.000000, 0.000000, 360.000000, 300.00);
    tmpobjid = CreateObject(18980, 1217.429199, -1325.076416, 7.868984, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1217.429199, -1349.088989, 7.868984, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1244.412231, -1304.016113, 14.268967, 0.000007, 90.000000, 89.999977, 300.00);
    tmpobjid = CreateObject(18980, 1244.412231, -1371.945434, 14.268967, 0.000007, 90.000000, 89.999977, 300.00);
    tmpobjid = CreateObject(4638, 1243.818725, -1317.541870, 14.298437, 0.000000, -0.000007, 539.999938, 300.00);
    tmpobjid = CreateObject(18980, 1244.412231, -1337.086303, 14.268967, 0.000007, 90.000000, 89.999977, 300.00);
    tmpobjid = CreateObject(4638, 1243.608642, -1358.424072, 14.298437, 0.000000, 0.000007, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1244.412475, -1325.076416, 7.868984, 0.000000, 0.000007, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1244.412475, -1349.088989, 7.868984, 0.000000, 0.000007, 0.000000, 300.00);

    // --- Barriers / ramp guards ---
    tmpobjid = CreateObject(19425, 1246.171630, -1323.099365, 12.374778, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(19425, 1246.171630, -1319.889526, 12.374778, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(19425, 1246.171630, -1355.180541, 12.374778, 0.000007, 0.000000, 89.999977, 300.00);
    tmpobjid = CreateObject(19425, 1246.171630, -1351.970703, 12.374778, 0.000007, 0.000000, 89.999977, 300.00);
    tmpobjid = CreateObject(19425, 1215.731079, -1355.180541, 12.554774, 0.000014, 0.000000, 89.999954, 300.00);
    tmpobjid = CreateObject(19425, 1215.731079, -1351.970703, 12.554774, 0.000014, 0.000000, 89.999954, 300.00);
    tmpobjid = CreateObject(19425, 1215.731079, -1322.909179, 12.554774, 0.000022, 0.000000, 89.999931, 300.00);
    tmpobjid = CreateObject(19425, 1215.731079, -1319.699340, 12.554774, 0.000022, 0.000000, 89.999931, 300.00);

    // --- Hospital cross / helipad / decoration ---
    tmpobjid = CreateObject(3934, 1161.031494, -1372.888671, 25.651712, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(3934, 1161.031494, -1355.798950, 25.681713, 0.000000, 0.000000, 0.000000, 300.00);

    // --- Ramp / stairwell ---
    tmpobjid = CreateObject(18981, 1141.416259, -1367.846191, 11.907449, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(3361, 1149.098876, -1347.211059, 16.369707, 0.000000, 0.000000, -90.000000, 300.00);
    tmpobjid = CreateObject(3361, 1149.098876, -1355.290893, 12.399708, 0.000000, 0.000000, -90.000000, 300.00);
    tmpobjid = CreateObject(3361, 1149.098876, -1333.329101, 23.559734, 0.000000, 0.000000, 89.999938, 300.00);
    tmpobjid = CreateObject(3361, 1149.098876, -1325.249267, 19.589736, 0.000000, 0.000000, 89.999938, 300.00);
    tmpobjid = CreateObject(18766, 1147.765991, -1343.246093, 25.157705, 90.000000, 0.000000, 90.000000, 300.00);

    // --- Railings ---
    tmpobjid = CreateObject(970, 1145.950927, -1339.868041, 18.824810, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(970, 1145.950927, -1335.267456, 18.824810, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(970, 1145.950927, -1330.686401, 18.824810, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(970, 1145.950927, -1325.935668, 18.824810, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(970, 1145.950927, -1321.414794, 18.824810, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(970, 1148.040893, -1319.354003, 18.824810, 0.000000, 0.000000, 180.000000, 300.00);
    tmpobjid = CreateObject(970, 1147.784423, -1347.473144, 26.187704, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(970, 1145.693603, -1345.392944, 26.187704, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(970, 1145.693603, -1340.972534, 26.187704, 0.000000, 0.000000, 90.000000, 300.00);

    // --- Rooftop objects ---
    tmpobjid = CreateObject(13725, 1168.555175, -1323.837524, 23.037317, 0.000000, 0.000000, 0.000000, 300.00);

    // --- Garden / landscaping ---
    tmpobjid = CreateObject(869, 1174.928710, -1356.380249, 13.420492, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(869, 1178.808593, -1356.380249, 13.420492, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(869, 1180.117919, -1356.380249, 13.420492, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(869, 1175.113037, -1365.701660, 13.420492, 0.000000, 0.000000, -19.800001, 300.00);
    tmpobjid = CreateObject(869, 1183.282958, -1365.844970, 13.560495, 0.000000, 0.000000, -4.800000, 300.00);
    tmpobjid = CreateObject(1280, 1179.197753, -1366.179443, 13.470743, 0.000000, 0.000000, 270.000000, 300.00);
    tmpobjid = CreateObject(3515, 1178.928100, -1361.402221, 12.434746, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(1223, 1176.459350, -1366.060302, 12.386957, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(1223, 1172.808837, -1356.399414, 10.996953, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(1223, 1172.808837, -1366.170532, 10.996953, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(870, 1182.219604, -1355.992187, 13.456715, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(870, 1182.219604, -1353.091918, 13.456715, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(870, 1182.570312, -1350.536499, 13.456715, 0.000000, 0.000000, -85.500015, 300.00);
    tmpobjid = CreateObject(870, 1182.403198, -1348.528808, 13.456715, 0.000000, 0.000000, -11.200028, 300.00);
    tmpobjid = CreateObject(870, 1182.314697, -1346.196655, 13.456715, 0.000000, 0.000000, -11.200028, 300.00);

    // --- Fence / walkway lights ---
    tmpobjid = CreateObject(640, 1185.105346, -1364.832763, 13.911964, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(640, 1185.105346, -1359.471679, 13.911964, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(640, 1185.105346, -1354.100708, 13.911964, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(640, 1185.105346, -1348.729492, 13.911964, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(640, 1185.105346, -1345.148071, 13.911964, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(970, 1185.802856, -1365.454711, 13.778830, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(970, 1185.802856, -1361.284545, 13.778830, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(970, 1185.802856, -1357.123168, 13.778830, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(970, 1185.802856, -1352.952758, 13.778830, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(970, 1185.802856, -1348.792480, 13.778830, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(970, 1185.802856, -1344.631469, 13.778830, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(18762, 1183.309814, -1342.211303, 12.486807, 0.000000, 90.000000, 0.000000, 300.00);

    // --- Entry details & decorations ---
    tmpobjid = CreateObject(19967, 1193.807617, -1335.670288, 12.188440, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(19967, 1193.807617, -1343.021240, 12.188440, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(19967, 1193.807617, -1346.392944, 12.188440, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(19967, 1190.267089, -1346.392944, 12.188440, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(19968, 1193.796630, -1301.411254, 12.344945, 0.000000, 0.000000, 180.000000, 300.00);
    tmpobjid = CreateObject(19957, 1193.793090, -1301.410156, 12.987018, 0.000000, 0.000000, 180.000000, 300.00);
    tmpobjid = CreateObject(1233, 1193.800048, -1301.417968, 13.946235, 0.000000, 0.000000, 180.000000, 300.00);
    tmpobjid = CreateObject(638, 1194.054809, -1327.406250, 13.058444, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(638, 1194.054809, -1320.445190, 13.058444, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(3352, 1172.849243, -1339.043701, 14.187099, 0.000000, 0.000000, 0.000000, 300.00);
    tmpobjid = CreateObject(18553, 1172.889282, -1332.610107, 14.186404, 0.000000, 0.000000, 0.000000, 300.00);

    // --- Parking lights ---
    tmpobjid = CreateObject(1231, 1243.172119, -1336.318725, 15.288995, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(1231, 1243.172119, -1349.179809, 15.288995, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(1231, 1243.172119, -1364.880615, 15.288995, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(1231, 1243.172119, -1383.020874, 15.288995, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(1231, 1243.172119, -1309.570922, 15.288995, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(1231, 1243.172119, -1292.840942, 15.288995, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(1231, 1243.172119, -1325.021972, 15.288995, 0.000000, 0.000000, 90.000000, 300.00);
    tmpobjid = CreateObject(1231, 1231.561401, -1336.318725, 15.288995, 0.000014, 0.000000, 89.999954, 300.00);
    tmpobjid = CreateObject(1231, 1231.561401, -1349.179809, 15.288995, 0.000014, 0.000000, 89.999954, 300.00);
    tmpobjid = CreateObject(1231, 1231.561401, -1364.880615, 15.288995, 0.000014, 0.000000, 89.999954, 300.00);
    tmpobjid = CreateObject(1231, 1231.561401, -1383.020874, 15.288995, 0.000014, 0.000000, 89.999954, 300.00);
    tmpobjid = CreateObject(1231, 1231.561401, -1309.570922, 15.288995, 0.000014, 0.000000, 89.999954, 300.00);
    tmpobjid = CreateObject(1231, 1231.561401, -1292.840942, 15.288995, 0.000014, 0.000000, 89.999954, 300.00);
    tmpobjid = CreateObject(1231, 1231.561401, -1325.021972, 15.288995, 0.000014, 0.000000, 89.999954, 300.00);
    tmpobjid = CreateObject(1231, 1218.151245, -1336.318725, 15.288995, 0.000022, 0.000000, 89.999931, 300.00);
    tmpobjid = CreateObject(1231, 1218.151245, -1349.179809, 15.288995, 0.000022, 0.000000, 89.999931, 300.00);
    tmpobjid = CreateObject(1231, 1218.151245, -1364.880615, 15.288995, 0.000022, 0.000000, 89.999931, 300.00);
    tmpobjid = CreateObject(1231, 1218.151245, -1383.020874, 15.288995, 0.000022, 0.000000, 89.999931, 300.00);
    tmpobjid = CreateObject(1231, 1218.151245, -1309.570922, 15.288995, 0.000022, 0.000000, 89.999931, 300.00);
    tmpobjid = CreateObject(1231, 1218.151245, -1292.840942, 15.288995, 0.000022, 0.000000, 89.999931, 300.00);
    tmpobjid = CreateObject(1231, 1218.151245, -1325.021972, 15.288995, 0.000022, 0.000000, 89.999931, 300.00);

    // --- Additional parking structure beams ---
    tmpobjid = CreateObject(18980, 1229.609741, -1292.016967, 12.708949, 0.000000, 90.000015, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1232.451049, -1292.016967, 12.708949, 0.000000, 90.000015, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1229.609741, -1383.957763, 12.708949, 0.000000, 90.000022, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1232.451049, -1383.957763, 12.708949, 0.000000, 90.000022, 0.000000, 300.00);
    tmpobjid = CreateObject(18980, 1217.428955, -1304.016113, 12.708949, 0.000014, 90.000000, 89.999954, 300.00);
    tmpobjid = CreateObject(18980, 1217.428955, -1371.945434, 12.708949, 0.000014, 90.000000, 89.999954, 300.00);
    tmpobjid = CreateObject(18980, 1217.428955, -1337.086303, 12.708949, 0.000014, 90.000000, 89.999954, 300.00);
    tmpobjid = CreateObject(18980, 1244.412231, -1304.016113, 12.708949, 0.000022, 90.000000, 89.999931, 300.00);
    tmpobjid = CreateObject(18980, 1244.412231, -1371.945434, 12.708949, 0.000022, 90.000000, 89.999931, 300.00);
    tmpobjid = CreateObject(18980, 1244.412231, -1337.086303, 12.708949, 0.000022, 90.000000, 89.999931, 300.00);

    printf("[Mapping] Hospital County General loaded. (by Arnathz)");
    #pragma unused tmpobjid
}
