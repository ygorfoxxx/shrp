#if defined _SHRP_MISSOES_HOOKS_INCLUDED
    #endinput
#endif
#define _SHRP_MISSOES_HOOKS_INCLUDED

// ==========================================================
// SHRP - Missoes - Hooks extraidos de callbacks
//  - OnPlayerEnterCheckpoint
//  - OnPlayerClickPlayerTextDraw
//  - OnDialogResponse
// ==========================================================

stock Missoes_OnPlayerEnterCheckpoint(playerid)
{
// === Kages Miss?o Kirigakure
    if(RamenCPKageKiri[playerid] && FinalizandoKageMissao[playerid] == 1)
    {
        FinalizandoKageMissao[playerid] = 2;
        SendClientMessage(playerid, -1, "{AB7C4E}(MISS?O) Entregue o relatorio na sala do Kage");
    }
    if(RamenCPKageIwag[playerid] && FinalizandoKageMissao[playerid] == 5)
    {
        FinalizandoKageMissao[playerid] = 6;
        SendClientMessage(playerid, -1, "{AB7C4E}(MISS?O) Entregue o relatorio na sala do Kage");
        SetPlayerCheckpoint(playerid, -1731.9889, 1742.6711, 135.4218, 1.0);
    }
    if(RamenCPKageKumo[playerid] && FinalizandoKageMissao[playerid] == 7)
    {
        FinalizandoKageMissao[playerid] = 8;
        UsandoKit[playerid] = 1;
        SendClientMessage(playerid, -1, "{AB7C4E}(MISS?O) Entregue o relatorio na sala do Kage");
        SetTimerEx("LimparKitU", 500, false, "d", playerid);
    }
    // CheckPoint Miss?o Kage Ingredientes
    if(KonohaCPIng[playerid])
    {
        if(IdentEntregaMissaoKage[playerid] == 1) // Ingredientes Konoha
        {
            ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.1, 0, 0, 0, 0, 1000, 1);
            RemovePlayerAttachedObject(playerid, 9);
            IdentEntregaMissaoKage[playerid] = 2;
        }
        if(IdentEntregaMissaoKage[playerid] == 5) // Ingredientes Kiri
        {
            ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.1, 0, 0, 0, 0, 1000, 1);
            RemovePlayerAttachedObject(playerid, 9);
            IdentEntregaMissaoKage[playerid] = 6;
        }
        if(IdentEntregaMissaoKage[playerid] == 3) // Medicamentos Konoha
        {
            ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.1, 0, 0, 0, 0, 1000, 1);
            RemovePlayerAttachedObject(playerid, 9);
            IdentEntregaMissaoKage[playerid] = 4;
        }
        if(IdentEntregaMissaoKage[playerid] == 7) // Medicamentos Kiri
        {
            ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.1, 0, 0, 0, 0, 1000, 1);
            RemovePlayerAttachedObject(playerid, 9);
            IdentEntregaMissaoKage[playerid] = 8;
        }
    }
    // Inicio dos CheckPoint da Miss?o de Guarda
    else if(GuardaKonohaCP[playerid])
    {
        if(GuardaKiriNM[playerid] >= 1){
            GuardaKonohaNM[playerid] ++;
            GivePlayerCash(playerid, 11);
            GivePlayerExperiencia(playerid, 19);
            SubirDLevel(playerid);
            TimingGuardaKonoha[playerid] = SetTimerEx("KonohaCP2", 100, 1, "i", playerid);
        }
    }
    else if(GuardaKiriCP[playerid])
    {
        if(GuardaKiriNM[playerid] >= 1){
            GuardaKiriNM[playerid] ++;
            GivePlayerCash(playerid, 11);
            GivePlayerExperiencia(playerid, 19);
            SubirDLevel(playerid);
            TimingGuardaKiri[playerid] = SetTimerEx("KiriCP2", 100, 1, "i", playerid);
        }
    }
    // Final dos CheckPoint da Miss?o de Guarda

    // === Nevada Excessod e Neve === //
    if(NevadaCPMissao[playerid])
    {
        if(IdentMissaoNormal[playerid] == 1){
            NevadaCPMissaoNM[playerid] ++;
            TimingNevadaCP[playerid] = SetTimerEx("NumerosNevacaCP", 100, 1, "i", playerid);
        }
    }
    if(NevadaPeixesCP[playerid])
    {
        if(IdentMissaoNormal[playerid] == 2){
            MissaoNormalFinalizada[playerid] = 1;
        }
        //TimingCPMissao1[playerid] = SetTimerEx("MissaoPeixesNevada", 100, 1, "i", playerid);
    }
    if(KirigakureMissao1CP[playerid])
    {
        if(IdentMissaoNormal[playerid] == 3){
            new stringki[200];
            MissaoNormalFinalizada[playerid] = 1;
            format(stringki, sizeof(stringki), "{AB7C4E}(MISS?O) {FFFFFF}Voc? entregou a {AB7C4E}carta{FFFFFF} ao assistente entregue o {AB7C4E}relatorio{FFFFFF} na academia!");
            SendClientMessage(playerid, COLOR_WHITE, stringki);
        }
    }
    // === Nevada Excessod e Neve Final === //
    // === Kirigakure Missoes Sensei === //
    if(KirigakureHospitalCP[playerid])
    {
        if(IdentMissaoNormal[playerid] == 5){
            new stringki[200];
            MissaoNormalFinalizada[playerid] = 1;
            format(stringki, sizeof(stringki), "{AB7C4E}(MISS?O) {FFFFFF}Entregue a {AB7C4E}encomenda{FFFFFF} ao {AB7C4E}sensei{FFFFFF} na academia ninja.");
            SendClientMessage(playerid, COLOR_WHITE, stringki);
        }
    }
    // === Kirigakure Missoes Sensei Final === //
    // === Iwagakure Missoes Sensei === //
    //Delegacia
    new stringiwa[168];
    if(IwagakureDelegaciaCP[playerid])
    {
        if(IdentMissaoNormal[playerid] == 6 && IwagakureIdentMissao[playerid] == 1) // Primeira ida Delegacia
        {
            IwagakureIdentMissao[playerid] = 2;
            IwagakureCPNum[playerid] = 2;
            format(stringiwa, sizeof(stringiwa), "{AB7C4E}(MISS?O) {FFFFFF}Voc? pegou os {AB7C4E}documentos{FFFFFF} que estava em cima da mesa. Leve para academia!");
            SendClientMessage(playerid, COLOR_WHITE, stringiwa);
            TimingIwagakureCP[playerid] = SetTimerEx("IwagakureCPS", 200, 0, "i", playerid);
        }
        else if(IdentMissaoNormal[playerid] == 6 && IwagakureIdentMissao[playerid] == 2) // Primeira Volta Academia
        {
            IwagakureIdentMissao[playerid] = 3;
            IwagakureCPNum[playerid] = 3;
            format(stringiwa, sizeof(stringiwa), "{AB7C4E}(MISS?O) {FFFFFF}Voc? entregou os {AB7C4E}documentos e logo recebe os documentos assinados{FFFFFF}. Leve para a delegacia!");
            SendClientMessage(playerid, COLOR_WHITE, stringiwa);
            TimingIwagakureCP[playerid] = SetTimerEx("IwagakureCPS", 250, 0, "i", playerid);
        }
        else if(IdentMissaoNormal[playerid] == 6 && IwagakureIdentMissao[playerid] == 3) // Segunda ida Delegacia
        {
            MissaoNormalFinalizada[playerid] = 1;
            IwagakureIdentMissao[playerid] = 4;
            format(stringiwa, sizeof(stringiwa), "{AB7C4E}(MISS?O) {FFFFFF}Entregue o {AB7C4E}relatorio da miss?o{FFFFFF} na academia!");
            SendClientMessage(playerid, COLOR_WHITE, stringiwa);
        }
    }
    //Ichiraku
    if(IwagakureIchirakuCP[playerid]){
         if(IdentMissaoNormal[playerid] == 7 && IwagakureIchirakuNUM[playerid] == 1){
            IwagakureIchirakuNUM[playerid] = 2;
            format(stringiwa, sizeof(stringiwa), "{AB7C4E}(MISS?O) Leve a encomenda de volta pra vila e entregue ao {AB7C4E}Ichiraku de Iwagakure{FFFFFF}!");
            SendClientMessage(playerid, COLOR_WHITE, stringiwa);
            TimingIwagakureIchirakuCP[playerid] = SetTimerEx("IwagakureIchirakuCPS", 200, 1, "i", playerid);
         }
         else if(IdentMissaoNormal[playerid] == 7 && IwagakureIchirakuNUM[playerid] == 2)
         {
            MissaoNormalFinalizada[playerid] = 1;
            IwagakureIchirakuNUM[playerid] = 3;
            format(stringiwa, sizeof(stringiwa), "{AB7C4E}(MISS?O) {FFFFFF}Entregue o {AB7C4E}relatorio da miss?o{FFFFFF} na academia!");
            SendClientMessage(playerid, COLOR_WHITE, stringiwa);
         }
    }
    //Tobby Desaparecido
    if(CPDogDP[playerid] && MissaoTobyIdent[playerid] == 6){
        new dogPos = random(2);
        switch(dogPos)
        {
            case 0:{
                MissaoTobyIdent[playerid] = 1;
                DogTobbyObj[playerid] = CreateDynamicActor(298, -1362.1615, 1761.4929, 29.1797+0.2);
                ApplyDynamicActorAnimation(DogTobbyObj[playerid], "Dog", "dog_uivo", 4.1, 0, 0, 1, 1, 1);
            }
            case 1:{
                MissaoTobyIdent[playerid] = 2;
                DogTobbyObj[playerid] = CreateDynamicActor(298, -1846.6541, 1957.2054, 22.1299+0.2);
                ApplyDynamicActorAnimation(DogTobbyObj[playerid], "Dog", "dog_uivo", 4.1, 0, 0, 1, 1, 1);
            }
        }
        SetTimerEx("CheckpoinTobby", 250, false, "d", playerid);
        format(stringiwa, sizeof(stringiwa), "{AB7C4E}(MISS?O) O cachorro possui pelagem {FFFFFF}Marrom com Branco{AB7C4E}. E se chama {FFFFFF}Tobby{AB7C4E}. Encontre-o!");
        SendClientMessage(playerid, COLOR_WHITE, stringiwa);
    }
    else if(CPDogTobby[playerid])
    {
        if(MissaoTobyIdent[playerid] == 1 || MissaoTobyIdent[playerid] == 2){
            DestroyDynamicActor(DogTobbyObj[playerid]);
            MissaoTobyIdent[playerid] = 3;
            format(stringiwa, sizeof(stringiwa), "{AB7C4E}(MISS?O) Voc? encontrou {FFFFFF}Tobby{AB7C4E}! Devolva a delegacia antes que ele fuja novamente!");
            SendClientMessage(playerid, COLOR_WHITE, stringiwa);
            SetTimerEx("CheckpoinTobby", 250, false, "d", playerid);
        }
    }
    if(CPDogFinalizar[playerid] && MissaoTobyIdent[playerid] == 4)
    {
        MissaoTobyIdent[playerid] = 5;
        MissaoNormalFinalizada[playerid] = 1;
        format(stringiwa, sizeof(stringiwa), "{AB7C4E}(MISS?O) Entregue o {FFFFFF}Relatorio{AB7C4E}. Na academia de Iwagakure.");
        SendClientMessage(playerid, COLOR_WHITE, stringiwa);
    }
    // === Iwagakure Missoes Sensei Final === //
    return 1;
}

// Retorna 1 quando consumiu o clique (deve dar return 1 no callback)
stock Missoes_OnPlayerClickPlayerTextDraw_VilaKage(playerid, PlayerText:playertextid)
{
//=== Inicio Sistema de Miss?o Vila/Kage ===//
    new str[500];
    new pName[MAX_PLAYER_NAME];
    GetPlayerName(playerid, pName, sizeof(pName));
    if(playertextid == MissoesVilaTXD[playerid][5]) // Pegar Miss?o
    {
        //Missoes de Kage
        if(AceitarRecusarMissaoKage[playerid] == 1) // Miss?o Ingredientes Kage
        {
            if(Info[playerid][pMember] == 1) // Konoha
            {
                if(EmMissao[playerid] == 1) return SendClientMessage(playerid, COLOR_WHITE, "[AVISO]: Voc? j? est? em uma miss?o.");
                Audio_Play(playerid, 58);
                InMissaoKage[playerid] = 1;
                AceitarRecusarMissaoKage[playerid] = 0;
                TogglePlayerControllable(playerid, 1);
                CancelSelectTextDraw(playerid);
                PlayerTextDrawShow(playerid, PlayerText:MiraHUD[playerid][0]); // Mira
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][0]); // Background Missao Pegar
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][1]); // Nome da Miss?o
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][2]); // Descri??o da Miss?o
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][3]); // Background BotaoP
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][4]); // Background BotaoPP
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][5]); // Botao Pegar
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][6]); // Botao Recusar
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][7]); // Ryos
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][8]); // XP
                format(str, sizeof(str), "{5FDE35}(AVISO){FFFFFF} O jogador {E9FE23}%s{FFFFFF} aceitou a miss?o {E9FE23}Ingredientes{FFFFFF}.", PlayerNameDados(playerid));
                AvisoEntregaKage(COLOR_COMBINEDCHAT, str);
                //Inicio Do CheckPoint
                KonohaCPIng[playerid] = SetPlayerCheckpoint(playerid, 272.4548, 1241.3326, 3.4160, 10.0);
            }
        }
        else if(AceitarRecusarMissaoKage[playerid] == 4) // Miss?o Ingredientes Kage
        {
            if(Info[playerid][pMember] == 3) // Kiri
            {
                if(EmMissao[playerid] == 1) return SendClientMessage(playerid, COLOR_WHITE, "[AVISO]: Voc? j? est? em uma miss?o.");
                Audio_Play(playerid, 58);
                InMissaoKage[playerid] = 1;
                AceitarRecusarMissaoKage[playerid] = 0;
                TogglePlayerControllable(playerid, 1);
                CancelSelectTextDraw(playerid);
                PlayerTextDrawShow(playerid, PlayerText:MiraHUD[playerid][0]); // Mira
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][0]); // Background Missao Pegar
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][1]); // Nome da Miss?o
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][2]); // Descri??o da Miss?o
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][3]); // Background BotaoP
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][4]); // Background BotaoPP
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][5]); // Botao Pegar
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][6]); // Botao Recusar
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][7]); // Ryos
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][8]); // XP
                format(str, sizeof(str), "{5FDE35}(AVISO){FFFFFF} O jogador {E9FE23}%s{FFFFFF} aceitou a miss?o {E9FE23}Ingredientes{FFFFFF}.", PlayerNameDados(playerid));
                AvisoEntregaKage2(COLOR_COMBINEDCHAT, str);
                //Inicio Do CheckPoint
                KonohaCPIng[playerid] = SetPlayerCheckpoint(playerid, 1404.9886, -1512.7532, 7.9219, 10.0);
            }
        }
        else if(AceitarRecusarMissaoKage[playerid] == 3) // Miss?o Ingredientes Kage
        {
            if(Info[playerid][pMember] == 1) // Konoha
            {
                if(EmMissao[playerid] == 1) return SendClientMessage(playerid, COLOR_WHITE, "[AVISO]: Voc? j? est? em uma miss?o.");
                Audio_Play(playerid, 58);
                InMissaoKage[playerid] = 1;
                AceitarRecusarMissaoKage[playerid] = 0;
                TogglePlayerControllable(playerid, 1);
                CancelSelectTextDraw(playerid);
                PlayerTextDrawShow(playerid, PlayerText:MiraHUD[playerid][0]); // Mira
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][0]); // Background Missao Pegar
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][1]); // Nome da Miss?o
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][2]); // Descri??o da Miss?o
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][3]); // Background BotaoP
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][4]); // Background BotaoPP
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][5]); // Botao Pegar
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][6]); // Botao Recusar
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][7]); // Ryos
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][8]); // XP
                format(str, sizeof(str), "{5FDE35}(AVISO){FFFFFF} O jogador {E9FE23}%s{FFFFFF} aceitou a miss?o {E9FE23}Medicamentos{FFFFFF}.", PlayerNameDados(playerid));
                AvisoEntregaKage(COLOR_COMBINEDCHAT, str);
                //Inicio Do CheckPoint
                KonohaCPIng[playerid] = SetPlayerCheckpoint(playerid, 79.5390, 1327.8228, 24.1027, 10.0);
            }
        }
        else if(AceitarRecusarMissaoKage[playerid] == 6) // Miss?o Ingredientes Kage
        {
            if(Info[playerid][pMember] == 3) // Kiri
            {
                if(EmMissao[playerid] == 1) return SendClientMessage(playerid, COLOR_WHITE, "[AVISO]: Voc? j? est? em uma miss?o.");
                Audio_Play(playerid, 58);
                InMissaoKage[playerid] = 1;
                AceitarRecusarMissaoKage[playerid] = 0;
                TogglePlayerControllable(playerid, 1);
                CancelSelectTextDraw(playerid);
                PlayerTextDrawShow(playerid, PlayerText:MiraHUD[playerid][0]); // Mira
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][0]); // Background Missao Pegar
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][1]); // Nome da Miss?o
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][2]); // Descri??o da Miss?o
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][3]); // Background BotaoP
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][4]); // Background BotaoPP
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][5]); // Botao Pegar
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][6]); // Botao Recusar
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][7]); // Ryos
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][8]); // XP
                format(str, sizeof(str), "{5FDE35}(AVISO){FFFFFF} O jogador {E9FE23}%s{FFFFFF} aceitou a miss?o {E9FE23}Medicamentos{FFFFFF}.", PlayerNameDados(playerid));
                AvisoEntregaKage2(COLOR_COMBINEDCHAT, str);
                //Inicio Do CheckPoint
                KonohaCPIng[playerid] = SetPlayerCheckpoint(playerid, 79.5390, 1327.8228, 24.1027, 10.0);
            }
        }
        else if(IdentMissao[playerid] == 1) // Missao de Guarda
        {
            if(Info[playerid][pMember] == 1)
            {
                if(InMissaoKage[playerid] == 1) return SendClientMessage(playerid, COLOR_WHITE, "[AVISO]: Voc? j? est? em uma miss?o.");
                Audio_Play(playerid, 58);
                EmMissao[playerid] = 1;
                TogglePlayerControllable(playerid, 1);
                CancelSelectTextDraw(playerid);
                PlayerTextDrawShow(playerid, PlayerText:MiraHUD[playerid][0]); // Mira
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][0]); // Background Missao Pegar
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][1]); // Nome da Miss?o
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][2]); // Descri??o da Miss?o
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][3]); // Background BotaoP
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][4]); // Background BotaoPP
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][5]); // Botao Pegar
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][6]); // Botao Recusar
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][7]); // Ryos
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][8]); // XP
                //Inicio Do CheckPoint
                GuardaKonohaCP[playerid] = SetPlayerCheckpoint(playerid, 55.0114, -882.9900, 8.1666, 2.0);
            }
            if(Info[playerid][pMember] == 3)
            {
                if(InMissaoKage[playerid] == 1) return SendClientMessage(playerid, COLOR_WHITE, "[AVISO]: Voc? j? est? em uma miss?o.");
                Audio_Play(playerid, 58);
                EmMissao[playerid] = 1;
                TogglePlayerControllable(playerid, 1);
                CancelSelectTextDraw(playerid);
                PlayerTextDrawShow(playerid, PlayerText:MiraHUD[playerid][0]); // Mira
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][0]); // Background Missao Pegar
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][1]); // Nome da Miss?o
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][2]); // Descri??o da Miss?o
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][3]); // Background BotaoP
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][4]); // Background BotaoPP
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][5]); // Botao Pegar
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][6]); // Botao Recusar
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][7]); // Ryos
                PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][8]); // XP
                //Inicio Do CheckPoint
                GuardaKiriCP[playerid] = SetPlayerCheckpoint(playerid, 2194.1113, -2314.5515, 30.1967, 2.0);
            }
        }
    }
    if(playertextid == MissoesVilaTXD[playerid][6]) // Recusar Miss?o
    {
        if(AceitarRecusarMissaoKage[playerid] == 1) // Miss?o Ingredientes Kage
        {
            Audio_Play(playerid, 58);
            InMissaoKage[playerid] = 0;
            IdentMissaoKage[playerid] = 0;
            AceitarRecusarMissaoKage[playerid] = 0;
            TogglePlayerControllable(playerid, 1);
            CancelSelectTextDraw(playerid);
            PlayerTextDrawShow(playerid, PlayerText:MiraHUD[playerid][0]); // Mira
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][0]); // Background Missao Pegar
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][1]); // Nome da Miss?o
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][2]); // Descri??o da Miss?o
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][3]); // Background BotaoP
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][4]); // Background BotaoPP
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][5]); // Botao Pegar
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][6]); // Botao Recusar
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][7]); // Ryos
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][8]); // XP
            format(str, sizeof(str), "{5FDE35}(AVISO){FFFFFF} O jogador {E9FE23}%s{FFFFFF} recusou a miss?o {E9FE23}Ingredientes{FFFFFF}.", PlayerNameDados(playerid));
            AvisoEntregaKage(COLOR_COMBINEDCHAT, str);
        }
        else if(AceitarRecusarMissaoKage[playerid] == 4) // Miss?o Ingredientes Kage
        {
            Audio_Play(playerid, 58);
            InMissaoKage[playerid] = 0;
            IdentMissaoKage[playerid] = 0;
            AceitarRecusarMissaoKage[playerid] = 0;
            TogglePlayerControllable(playerid, 1);
            CancelSelectTextDraw(playerid);
            PlayerTextDrawShow(playerid, PlayerText:MiraHUD[playerid][0]); // Mira
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][0]); // Background Missao Pegar
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][1]); // Nome da Miss?o
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][2]); // Descri??o da Miss?o
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][3]); // Background BotaoP
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][4]); // Background BotaoPP
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][5]); // Botao Pegar
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][6]); // Botao Recusar
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][7]); // Ryos
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][8]); // XP
            format(str, sizeof(str), "{5FDE35}(AVISO){FFFFFF} O jogador {E9FE23}%s{FFFFFF} recusou a miss?o {E9FE23}Ingredientes{FFFFFF}.", PlayerNameDados(playerid));
            AvisoEntregaKage2(COLOR_COMBINEDCHAT, str);
        }
        else if(AceitarRecusarMissaoKage[playerid] == 3) // Miss?o Medicamentos Kage
        {
            Audio_Play(playerid, 58);
            InMissaoKage[playerid] = 0;
            IdentMissaoKage[playerid] = 0;
            AceitarRecusarMissaoKage[playerid] = 0;
            TogglePlayerControllable(playerid, 1);
            CancelSelectTextDraw(playerid);
            PlayerTextDrawShow(playerid, PlayerText:MiraHUD[playerid][0]); // Mira
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][0]); // Background Missao Pegar
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][1]); // Nome da Miss?o
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][2]); // Descri??o da Miss?o
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][3]); // Background BotaoP
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][4]); // Background BotaoPP
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][5]); // Botao Pegar
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][6]); // Botao Recusar
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][7]); // Ryos
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][8]); // XP
            format(str, sizeof(str), "{5FDE35}(AVISO){FFFFFF} O jogador {E9FE23}%s{FFFFFF} recusou a miss?o {E9FE23}Medicamentos{FFFFFF}.", PlayerNameDados(playerid));
            AvisoEntregaKage(COLOR_COMBINEDCHAT, str);
        }
        else if(AceitarRecusarMissaoKage[playerid] == 6) // Miss?o Medicamentos Kage
        {
            Audio_Play(playerid, 58);
            InMissaoKage[playerid] = 0;
            IdentMissaoKage[playerid] = 0;
            AceitarRecusarMissaoKage[playerid] = 0;
            TogglePlayerControllable(playerid, 1);
            CancelSelectTextDraw(playerid);
            PlayerTextDrawShow(playerid, PlayerText:MiraHUD[playerid][0]); // Mira
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][0]); // Background Missao Pegar
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][1]); // Nome da Miss?o
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][2]); // Descri??o da Miss?o
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][3]); // Background BotaoP
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][4]); // Background BotaoPP
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][5]); // Botao Pegar
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][6]); // Botao Recusar
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][7]); // Ryos
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][8]); // XP
            format(str, sizeof(str), "{5FDE35}(AVISO){FFFFFF} O jogador {E9FE23}%s{FFFFFF} recusou a miss?o {E9FE23}Medicamentos{FFFFFF}.", PlayerNameDados(playerid));
            AvisoEntregaKage2(COLOR_COMBINEDCHAT, str);
        }
        else if(IdentMissao[playerid] == 1) // Missao de Guarda
        {
            Audio_Play(playerid, 58);
            EmMissao[playerid] = 0;
            IdentMissao[playerid] = 0;
            TogglePlayerControllable(playerid, 1);
            CancelSelectTextDraw(playerid);
            PlayerTextDrawShow(playerid, PlayerText:MiraHUD[playerid][0]); // Mira
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][0]); // Background Missao Pegar
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][1]); // Nome da Miss?o
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][2]); // Descri??o da Miss?o
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][3]); // Background BotaoP
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][4]); // Background BotaoPP
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][5]); // Botao Pegar
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][6]); // Botao Recusar
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][7]); // Ryos
            PlayerTextDrawHide(playerid, MissoesVilaTXD[playerid][8]); // XP
        }
    }
    //=== Final Sistema de Miss?o Vila/Kage ===//
    return 0;
}

// Missoes de Kage (dialogs do ramen/ingredientes)
// Retorna 1 se o dialogid pertencer a esse conjunto.
stock Missoes_OnDialogResponse_KageRamen(playerid, dialogid, response, listitem, inputtext[])
{
    new string[256];
// === MISS?ES KAGE - IWAGAKURE
    if(dialogid == DIALOG_KAGEIWAGMISSAORAMEN)
    {
        if(response)
        {
            Audio_Play(playerid, 58);
            if(isNumber(inputtext))
            if(IsPlayerConnected(strval(inputtext)))
            if(strval(inputtext) == playerid) return SendClientMessage(playerid, -1, "(AVISO) Voc? n?o pode fazer isso com voc? mesmo.");
            if(Info[strval(inputtext)][pMember] == 3 || Info[strval(inputtext)][pMember] == 6 || Info[strval(inputtext)][pMember] == 7 || Info[strval(inputtext)][pMember] == 5 || Info[strval(inputtext)][pMember] == 8 || Info[strval(inputtext)][pMember] == 9 || Info[strval(inputtext)][pMember] == 10 ||
               Info[strval(inputtext)][pMember] == 11) return SendClientMessage(playerid, -1, "(AVISO) O ninja n?o faz parte de sua vila.");
            if(MissaoKageID[strval(inputtext)] != 0) return SendClientMessage(playerid, -1, "{AB7C4E}(KAGE) Esse ninja j? est? com uma miss?o ativa.");
            if(ProxDetectorS(2.0, playerid, strval(inputtext)))
            {
                format(string, sizeof(string), "{AB7C4E}O Kage {FFFFFF}%s{AB7C4E} lhe passou a miss?o de ({FFFFFF}ESTOQUE RAMEN{AB7C4E}).", PlayerNameDados(playerid));
                SendClientMessage(strval(inputtext), -1, string);
                AbriuMissaoKage[strval(inputtext)] = 0; // Reseta a Variavel
                KageQuePassouM[strval(inputtext)] = playerid; // Salva o ID do KAGE
                MostrarMissoes(strval(inputtext), 5); // MOSTRA A MISS?O
            }
        }else{Audio_Play(playerid, 58);}
    }
    // === MISS?ES KAGE - KUMOGAKURE
    if(dialogid == DIALOG_KAGEKUMOMISSAORAMEN)
        {
            if(response)
            {
                Audio_Play(playerid, 58);
                if(isNumber(inputtext))
                if(IsPlayerConnected(strval(inputtext)))
                //if(strval(inputtext) == playerid) return SendClientMessage(playerid, -1, "(AVISO) Voc? n?o pode fazer isso com voc? mesmo.");
                if(Info[strval(inputtext)][pMember] == 3 || Info[strval(inputtext)][pMember] == 6 || Info[strval(inputtext)][pMember] == 7 || Info[strval(inputtext)][pMember] == 1 || Info[strval(inputtext)][pMember] == 8 || Info[strval(inputtext)][pMember] == 9 || Info[strval(inputtext)][pMember] == 10 ||
                   Info[strval(inputtext)][pMember] == 11) return SendClientMessage(playerid, -1, "(AVISO) O ninja n?o faz parte de sua vila.");
                if(MissaoKageID[strval(inputtext)] != 0) return SendClientMessage(playerid, -1, "{AB7C4E}(KAGE) Esse ninja j? est? com uma miss?o ativa.");
                if(ProxDetectorS(2.0, playerid, strval(inputtext)))
                {
                    format(string, sizeof(string), "{AB7C4E}O Kage {FFFFFF}%s{AB7C4E} lhe passou a miss?o de ({FFFFFF}ESTOQUE RAMEN{AB7C4E}).", PlayerNameDados(playerid));
                    SendClientMessage(strval(inputtext), -1, string);
                    AbriuMissaoKage[strval(inputtext)] = 0; // Reseta a Variavel
                    KageQuePassouM[strval(inputtext)] = playerid; // Salva o ID do KAGE
                    MostrarMissoes(strval(inputtext), 5); // MOSTRA A MISS?O
                }
            }else{Audio_Play(playerid, 58);}
        }
    // === MISS?ES KAGE - KIRIGAKURE
    if(dialogid == DIALOG_KAGEKIRIMISSAORAMEN)
    {
        if(response)
        {
            Audio_Play(playerid, 58);
            if(isNumber(inputtext))
            if(IsPlayerConnected(strval(inputtext)))
            if(strval(inputtext) == playerid) return SendClientMessage(playerid, -1, "(AVISO) Voc? n?o pode fazer isso com voc? mesmo.");
            if(Info[strval(inputtext)][pMember] == 1 || Info[strval(inputtext)][pMember] == 6 || Info[strval(inputtext)][pMember] == 7 || Info[strval(inputtext)][pMember] == 5 || Info[strval(inputtext)][pMember] == 8 || Info[strval(inputtext)][pMember] == 9 || Info[strval(inputtext)][pMember] == 10 ||
               Info[strval(inputtext)][pMember] == 11) return SendClientMessage(playerid, -1, "(AVISO) O ninja n?o faz parte de sua vila.");
            if(MissaoKageID[strval(inputtext)] != 0) return SendClientMessage(playerid, -1, "{AB7C4E}(KAGE) Esse ninja j? est? com uma miss?o ativa.");
            if(ProxDetectorS(2.0, playerid, strval(inputtext)))
            {
                format(string, sizeof(string), "{AB7C4E}O Kage {FFFFFF}%s{AB7C4E} lhe passou a miss?o de ({FFFFFF}ESTOQUE RAMEN{AB7C4E}).", PlayerNameDados(playerid));
                SendClientMessage(strval(inputtext), -1, string);
                AbriuMissaoKage[strval(inputtext)] = 0; // Reseta a Variavel
                KageQuePassouM[strval(inputtext)] = playerid; // Salva o ID do KAGE
                MostrarMissoes(strval(inputtext), 5); // MOSTRA A MISS?O
            }
        }else{Audio_Play(playerid, 58);}
    }
    return (dialogid == DIALOG_KAGEIWAGMISSAORAMEN || dialogid == DIALOG_KAGEKUMOMISSAORAMEN || dialogid == DIALOG_KAGEKIRIMISSAORAMEN);
}
