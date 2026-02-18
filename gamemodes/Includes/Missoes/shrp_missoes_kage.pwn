#if defined _SHRP_MISSOES_KAGE_INCLUDED
    #endinput
#endif
#define _SHRP_MISSOES_KAGE_INCLUDED

// ==========================================================
// SHRP - Missoes de Kage (Ramen / Ingredientes / Entrega)
// Extraido do SHRP.pwn (refactor automatico)
// ==========================================================

function TeclaBotaoMissaoKage(playerid, newkeys, oldkeys)
{
    if(BtnDireito[playerid] == 1) return 0;

    if(PRESSED(KEY_CTRL_BACK))
    {
        if(Missoes_AcademiaGate_Deny(playerid)) return 1;
        MissoesKagaFalas(playerid);
    }
    return 1;
}
function MissoesKagaFalas(playerid)
{
    if(IsPlayerInRangeOfPoint(playerid, 1.5, 1404.9886, -1512.7532, 7.9219)) // Ingredientes
    {
        if(IdentMissaoKage[playerid] == 1 && Info[playerid][pMember] == 1) // Ingredientes Konoha
        {
            SetPlayerAttachedObject(playerid, 9, 15783, 5);
            ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.1, 0, 0, 0, 0, 1000, 1);
            IdentEntregaMissaoKage[playerid] = 1;
            SendClientMessage(playerid, COLOR_WHITE, "Irin: Leve os ingredientes o mais rapido possivel!");
            KonohaCPIng[playerid] = SetPlayerCheckpoint(playerid, -1549.6923, 1627.0927, 2.1217, 2.0);
        }
        if(IdentMissaoKage[playerid] == 4 && Info[playerid][pMember] == 3) // Ingredientes Kiri
        {
            SetPlayerAttachedObject(playerid, 9, 15783, 5);
            ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.1, 0, 0, 0, 0, 1000, 1);
            IdentEntregaMissaoKage[playerid] = 5;
            SendClientMessage(playerid, COLOR_WHITE, "Irin: Leve os ingredientes o mais rapido possivel!");
            KonohaCPIng[playerid] = SetPlayerCheckpoint(playerid, 2660.2820, -2696.3665, 35.5160, 2.0);
        }
    }
    if(IsPlayerInRangeOfPoint(playerid, 1.5, 79.5390, 1327.8228, 24.1027)) // Medicamentos
    {
        if(IdentMissaoKage[playerid] == 3 && Info[playerid][pMember] == 1) // Medicamentos Konoha
        {
            SetPlayerAttachedObject(playerid, 9, 15783, 5);
            ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.1, 0, 0, 0, 0, 1000, 1);
            SendClientMessage(playerid, COLOR_WHITE, "Aika: Melhor levar esses medicamentos o mais rapido possivel!");
            IdentEntregaMissaoKage[playerid] = 3;
            KonohaCPIng[playerid] = SetPlayerCheckpoint(playerid, -1650.1456, 1928.2588, 2.0320, 2.0);
        }
    }
    if(IsPlayerInRangeOfPoint(playerid, 1.5, 79.5390, 1327.8228, 24.1027)) // Medicamentos
    {
        if(IdentMissaoKage[playerid] == 6 && Info[playerid][pMember] == 3) // Medicamentos Kiri
        {
            SetPlayerAttachedObject(playerid, 9, 15783, 5);
            ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.1, 0, 0, 0, 0, 1000, 1);
            SendClientMessage(playerid, COLOR_WHITE, "Aika: Melhor levar esses medicamentos o mais rapido possivel!");
            IdentEntregaMissaoKage[playerid] = 7;
            KonohaCPIng[playerid] = SetPlayerCheckpoint(playerid, 2847.7170, -2590.1882, 35.8323, 2.0);
        }
    }
    return 1;
}
function TeclaEntregaMissaoKage(playerid, newkeys, oldkeys)
{
    if(BtnDireito[playerid] == 1) return 0;

    if(PRESSED(KEY_CTRL_BACK))
    {
        if(Missoes_AcademiaGate_Deny(playerid)) return 1;
        EntregaKageMissao(playerid);
    }
    return 1;
}
function EntregaKageMissao(playerid)
{
    MissoesLegacyUI_Ensure(playerid);
    new str[124];
    new pName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, pName, sizeof(pName));
    if(IsPlayerInRangeOfPoint(playerid, 1.5, -1650.1456, 1928.2588, 2.0320))
    {
        if(IdentEntregaMissaoKage[playerid] == 2 && IdentMissaoKage[playerid] == 1) // Ingredientes Konoha
        {
            Audio_Play(playerid, 59);
            KageRecompensa(playerid, GetPVarInt(playerid, "KageQuePassou"));
            IdentEntregaMissaoKage[playerid] = 0;
            InMissaoKage[playerid] = 0;
            IdentMissaoKage[playerid] = 0;
            GivePlayerCash(playerid, 120);
            GivePlayerExperiencia(playerid, 2080);
            SubirDLevel(playerid);
            TogglePlayerControllable(playerid, 0);
            format(str, sizeof(str), "120", str); // Ryos da Miss?o
            PlayerTextDrawSetString(playerid, FinalizarMissao[playerid][8], str);
            format(str, sizeof(str), "280", str); // XP da Miss?o
            PlayerTextDrawSetString(playerid, FinalizarMissao[playerid][9], str);
            format(str, sizeof(str), "0", str); // XP Extra da Miss?o
            PlayerTextDrawSetString(playerid, FinalizarMissao[playerid][10], str);
            format(str, sizeof(str), "120", str); // Ryos da Miss?o
            PlayerTextDrawSetString(playerid, FinalizarMissao[playerid][11], str);
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][0]); // SUCESSO
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][1]); // BACKGROUND MISSAO COMPLETA
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][5]); // rank D
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][7]); // CARIMBO
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][8]); // Ryos da Miss?o
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][9]); // XP da Miss?o
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][10]); // XP extra da Miss?o
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][11]); // Ryos da Miss?o
            TimingMissaoEnd[playerid] = SetTimerEx("HideGuardaCompleta", 3500, 1, "i", playerid);
            format(str, sizeof(str), "{5FDE35}(AVISO){FFFFFF} O jogador {E9FE23}%s{FFFFFF} completou a miss?o {E9FE23}Ingredientes{FFFFFF}.", PlayerNameDados(playerid));
            AvisoEntregaKage(COLOR_COMBINEDCHAT, str);
        }
        if(IdentEntregaMissaoKage[playerid] == 4 && IdentMissaoKage[playerid] == 3) // Medicamentos Konoha
        {
            Audio_Play(playerid, 59);
            KageRecompensa(playerid, GetPVarInt(playerid, "KageQuePassou"));
            IdentEntregaMissaoKage[playerid] = 0;
            InMissaoKage[playerid] = 0;
            IdentMissaoKage[playerid] = 0;
            GivePlayerCash(playerid, 250);
            GivePlayerExperiencia(playerid, 3015);
            SubirDLevel(playerid);
            TogglePlayerControllable(playerid, 0);
            format(str, sizeof(str), "250", str); // Ryos da Miss?o
            PlayerTextDrawSetString(playerid, FinalizarMissao[playerid][8], str);
            format(str, sizeof(str), "315", str); // XP da Miss?o
            PlayerTextDrawSetString(playerid, FinalizarMissao[playerid][9], str);
            format(str, sizeof(str), "0", str); // XP Extra da Miss?o
            PlayerTextDrawSetString(playerid, FinalizarMissao[playerid][10], str);
            format(str, sizeof(str), "250", str); // Ryos da Miss?o
            PlayerTextDrawSetString(playerid, FinalizarMissao[playerid][11], str);
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][0]); // SUCESSO
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][1]); // BACKGROUND MISSAO COMPLETA
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][5]); // rank D
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][7]); // CARIMBO
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][8]); // Ryos da Miss?o
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][9]); // XP da Miss?o
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][10]); // XP extra da Miss?o
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][11]); // Ryos da Miss?o
            TimingMissaoEnd[playerid] = SetTimerEx("HideGuardaCompleta", 3500, 1, "i", playerid);
            format(str, sizeof(str), "{5FDE35}(AVISO){FFFFFF} O jogador {E9FE23}%s{FFFFFF} completou a miss?o {E9FE23}Medicamentos{FFFFFF}.", PlayerNameDados(playerid));
            AvisoEntregaKage(COLOR_COMBINEDCHAT, str);
        }
    }
    if(IsPlayerInRangeOfPoint(playerid, 1.5, 2582.9031, -2301.9678, 64.5547)) // Kirigakure
    {
        if(IdentEntregaMissaoKage[playerid] == 6 && IdentMissaoKage[playerid] == 4) // Ingredientes Kiri
        {
            Audio_Play(playerid, 59);
            KageRecompensa(playerid, GetPVarInt(playerid, "KageQuePassou"));
            IdentEntregaMissaoKage[playerid] = 0;
            InMissaoKage[playerid] = 0;
            IdentMissaoKage[playerid] = 0;
            GivePlayerCash(playerid, 120);
            GivePlayerExperiencia(playerid, 2080);
            SubirDLevel(playerid);
            TogglePlayerControllable(playerid, 0);
            format(str, sizeof(str), "120", str); // Ryos da Miss?o
            PlayerTextDrawSetString(playerid, FinalizarMissao[playerid][8], str);
            format(str, sizeof(str), "280", str); // XP da Miss?o
            PlayerTextDrawSetString(playerid, FinalizarMissao[playerid][9], str);
            format(str, sizeof(str), "0", str); // XP Extra da Miss?o
            PlayerTextDrawSetString(playerid, FinalizarMissao[playerid][10], str);
            format(str, sizeof(str), "120", str); // Ryos da Miss?o
            PlayerTextDrawSetString(playerid, FinalizarMissao[playerid][11], str);
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][0]); // SUCESSO
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][1]); // BACKGROUND MISSAO COMPLETA
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][5]); // rank D
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][7]); // CARIMBO
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][8]); // Ryos da Miss?o
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][9]); // XP da Miss?o
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][10]); // XP extra da Miss?o
            PlayerTextDrawShow(playerid, FinalizarMissao[playerid][11]); // Ryos da Miss?o
            TimingMissaoEnd[playerid] = SetTimerEx("HideGuardaCompleta", 3500, 1, "i", playerid);
            format(str, sizeof(str), "{5FDE35}(AVISO){FFFFFF} O jogador {E9FE23}%s{FFFFFF} completou a miss?o {E9FE23}Ingredientes{FFFFFF}.", PlayerNameDados(playerid));
            AvisoEntregaKage2(COLOR_COMBINEDCHAT, str);
        }
        if(IdentEntregaMissaoKage[playerid] == 8 && IdentMissaoKage[playerid] == 6) // Medicamentos Kiri
        {
                Audio_Play(playerid, 59);
                KageRecompensa(playerid, GetPVarInt(playerid, "KageQuePassou"));
                IdentEntregaMissaoKage[playerid] = 0;
                InMissaoKage[playerid] = 0;
                IdentMissaoKage[playerid] = 0;
                GivePlayerCash(playerid, 250);
                GivePlayerExperiencia(playerid, 3015);
                SubirDLevel(playerid);
                TogglePlayerControllable(playerid, 0);
                format(str, sizeof(str), "250", str); // Ryos da Miss?o
                PlayerTextDrawSetString(playerid, FinalizarMissao[playerid][8], str);
                format(str, sizeof(str), "315", str); // XP da Miss?o
                PlayerTextDrawSetString(playerid, FinalizarMissao[playerid][9], str);
                format(str, sizeof(str), "0", str); // XP Extra da Miss?o
                PlayerTextDrawSetString(playerid, FinalizarMissao[playerid][10], str);
                format(str, sizeof(str), "250", str); // Ryos da Miss?o
                PlayerTextDrawSetString(playerid, FinalizarMissao[playerid][11], str);
                PlayerTextDrawShow(playerid, FinalizarMissao[playerid][0]); // SUCESSO
                PlayerTextDrawShow(playerid, FinalizarMissao[playerid][1]); // BACKGROUND MISSAO COMPLETA
                PlayerTextDrawShow(playerid, FinalizarMissao[playerid][5]); // rank D
                PlayerTextDrawShow(playerid, FinalizarMissao[playerid][7]); // CARIMBO
                PlayerTextDrawShow(playerid, FinalizarMissao[playerid][8]); // Ryos da Miss?o
                PlayerTextDrawShow(playerid, FinalizarMissao[playerid][9]); // XP da Miss?o
                PlayerTextDrawShow(playerid, FinalizarMissao[playerid][10]); // XP extra da Miss?o
                PlayerTextDrawShow(playerid, FinalizarMissao[playerid][11]); // Ryos da Miss?o
                TimingMissaoEnd[playerid] = SetTimerEx("HideGuardaCompleta", 3500, 1, "i", playerid);
                format(str, sizeof(str), "{5FDE35}(AVISO){FFFFFF} O jogador {E9FE23}%s{FFFFFF} completou a miss?o {E9FE23}Medicamentos{FFFFFF}.", PlayerNameDados(playerid));
                AvisoEntregaKage2(COLOR_COMBINEDCHAT, str);
        }
    }
    return 1;
}
