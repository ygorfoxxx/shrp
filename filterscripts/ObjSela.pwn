#include <a_samp>
#include <zcmd>
#include <streamer>
#include <sscanf2>
new OBJGATOTESTE[MAX_PLAYERS];
CMD:objteste(playerid)
{
	//ApplyAnimation(playerid, "Shinobi_Anim", "Nara_01", 3.0, 0, 1, 1, 1, 0, 1);
	SetPlayerAttachedObject(playerid, 0, 15783, 1, 0.005999, -0.200000, 0.500000, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0);
	EditAttachedObject(playerid, 0);
	//new GatoID = 15821;
	//OBJGATOTESTE[playerid] = CreateObject(GatoID, 2876.1316, -2652.3762, 34.5156, 0.0, 0.0, 96.0, 300.0); // OK

    //SetPlayerCheckpoint(playerid, 2876.1316, -2652.3762, 34.5156, 2.0);

	//ApplyAnimation(playerid, "Shinobi_Anim", "Nara_01", 3.0, 0, 1, 1, 1, 0, 1);
	//SetPlayerAttachedObject(playerid, 9, 15405, 9, 0.1, -0.29, 0.5, 0.0, 90.0, 155.0, 1.0, 0.3, -0.3);
	//SetPlayerAttachedObject(playerid, 9, 15400, 9, 0.1, -0.2, 0.5, 0.0, 90.0, 0.0, 1.0, 1.0, 0.0);
	//SetPlayerAttachedObject(playerid, 8, 15402, 9, 0.2, -0.2, 0.5, 0.0, -90.0, 155.0, 0.7, 0.7, 1.0);
    return 1;
}
CMD:objdele(playerid)
{
	//DestroyObject(OBJGATOTESTE[playerid]);
	RemovePlayerAttachedObject(playerid, 0);
	return 1;
}
CMD:testobj(playerid)
{
	//SetPlayerAttachedObject(playerid, 4, 15418, 5, 0.082999, -0.002000, -0.002500, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0);
    SetPlayerAttachedObject(playerid, 4, 15116, 1, 1.050999, 0.000000, 0.000000, 82.399955, -99.700134, 86.400016, 1.0, 1.0, 1.0);
	EditAttachedObject(playerid, 4);
	return 1;
}
CMD:testobj1(playerid)
{
    SetPlayerAttachedObject(playerid, 5, 15117, 1, 1.209998, 0.175000, 0.466999, -87.100067, -87.100120, -108.199829, 1.0, 1.0, 1.0);
    EditAttachedObject(playerid, 5);
	return 1;
}
CMD:l(playerid)
{
	ClearAnimations(playerid);
	return 1;
}
CMD:t1(playerid)
{
    ApplyAnimation(playerid, "Mtr_mnt", "Minato_4", 4.1, 0, 0, 0, 1, 0, 1);
    return 1;
}
CMD:t2(playerid)
{
    ApplyAnimation(playerid, "Shinobi_Anim","JumpR_2", 4.0, 0, 1, 1, 1, 1500, 1);
    return 1;
}
CMD:t3(playerid)
{
    ApplyAnimation(playerid, "Mtr_nt","NWE_NARUTO_3", 4.0, 0, 1, 1, 0, 1500, 1);
    return 1;
}
CMD:t4(playerid)
{
    ApplyAnimation(playerid, "Mtr_nt","NWE_NARUTO_4", 4.0, 0, 1, 1, 0, 5000, 1);
    return 1;
}
CMD:t5(playerid)
{
    ApplyAnimation(playerid, "Mtr_nt","NWE_NARUTO_5", 4.0, 0, 1, 1, 0, 1500, 1);
    return 1;
}
CMD:t6(playerid)
{
    ApplyAnimation(playerid, "Mtr_nt","NWE_NARUTO_6", 4.0, 0, 1, 1, 0, 1500, 1);
    return 1;
}
CMD:t7(playerid)
{
    ApplyAnimation(playerid, "Mtr_nt","NWE_NARUTO_7", 4.0, 0, 1, 1, 0, 1500, 1);
    return 1;
}
CMD:t8(playerid)
{
    ApplyAnimation(playerid, "Mtr_nt","NWE_NARUTO_8", 4.0, 0, 1, 1, 0, 1500, 1);
    return 1;
}
CMD:t9(playerid)
{
    ApplyAnimation(playerid, "Mtr_nt","NWE_NARUTO_9", 4.0, 0, 1, 1, 0, 1500, 1);
    return 1;
}
CMD:t10(playerid)
{
    ApplyAnimation(playerid, "Mtr_nt","NWE_NARUTO_10", 4.0, 0, 1, 1, 0, 1500, 1);
    return 1;
}