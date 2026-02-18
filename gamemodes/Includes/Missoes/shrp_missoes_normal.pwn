#if defined _SHRP_MISSOES_NORMAL_INCLUDED
    #endinput
#endif
#define _SHRP_MISSOES_NORMAL_INCLUDED


// Quadro de Missoes Diarias (precisa vir ANTES da tecla R para ter prioridade)
#include "diarias_rank_txd.pwn"

// Wrapper publico definido em shrp_academiamissao1 (para nao precisar mexer no gamemode)
forward AcaM1_ClickHandler(playerid, PlayerText:playertextid);

// ==========================================================
// SHRP - Missoes Normais (Sensei / MissoesNew)
// Extraido do SHRP.pwn (refactor automatico)
// ==========================================================
// ==========================================================
// ACADEMIA GATE (bloqueia outras missoes ate concluir a Missao 1 da Academia)
// Regra atual: enquanto Info[playerid][pClan] == 0, o player ainda nao escolheu clan
// (Missao 1 da Academia). Nesse periodo, ao apertar R no instrutor da Academia
// (Iwa/Kiri), a missao da Academia abre automaticamente. Em outros locais, bloqueia.
// ==========================================================

// (PROTOTIPO) Implementado no include da Academia Missao 1.
// Serve pra abrir a missao pelo botao R no mesmo NPC/local.
stock AcaM1_TryOpenFromKey(playerid);

static gMissoes_AcademiaMsgCd[MAX_PLAYERS];

stock Missoes_AcademiaGate_ShouldBlock(playerid)
{
    // Criterio de desbloqueio geral:
    // - Missao 1 da Academia exige escolha de clan no final.
    // - Depois disso (pClan != 0), libera todas as outras missoes normais.
    return (Info[playerid][pClan] == 0);
}

// Retorna 1 se bloqueou (consumiu), 0 se liberou.
stock Missoes_AcademiaGate_Deny(playerid)
{
    if(!Missoes_AcademiaGate_ShouldBlock(playerid)) return 0;

    // EXCECAO: se estiver no instrutor da Academia, abre a Missao 1 automaticamente
    // (em vez de mostrar "bloqueado").
    if(AcaM1_TryOpenFromKey(playerid))
        return 1;

    // Anti-flood simples (2s)
    if(gMissoes_AcademiaMsgCd[playerid] > gettime())
        return 1;

    gMissoes_AcademiaMsgCd[playerid] = gettime() + 2;

    SendClientMessage(playerid, COLOR_WHITE,
        "{AB7C4E}(ACADEMIA){FFFFFF} Conclua a {AB7C4E}Missao 1 da Academia{FFFFFF} antes de pegar outras missoes. Va ate o instrutor e pressione {AB7C4E}R{FFFFFF}.");
    return 1;
}

function MissoesPosicao(playerid)
{
    new Missoes = IdentMissaoNormal[playerid];
    //Nevada
    if(IsPlayerInRangeOfPoint(playerid, 1.5, 0.0, 0.0, 0.0)) // Guy Sensei Kiri e Iwagakure
    {
        if(EmMissaoNormal[playerid] == 0 && IdentMissaoNormal[playerid] == 0 && MissoesNormalOpen[playerid] == 0 && MissaoNormalFinalizada[playerid] == 0)
        {
            MostrarMissoes(playerid, 1);
        }else if(MissaoNormalFinalizada[playerid] == 1){
            switch(Missoes)
            {
                case 1:{//Excesso de Neve
                    EmMissaoNormal[playerid] = 0;
                    IdentMissaoNormal[playerid] = 0;
                    MissoesNormalOpen[playerid] = 0;
                    MissaoNormalFinalizada[playerid] = 0;
                    Info[playerid][pMissaoN] = 1;
                    GivePlayerCash(playerid, 25);
                    if(BuffAtivado == 0){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 25);} // 0 porcento de xp
                    if(BuffAtivado == 1){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 25);} // 5 porcento de xp
                    if(BuffAtivado == 2){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 25);} // 7 porcento de xp
                    if(BuffAtivado == 3){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 25);} // 10 porcento de xp
                    if(BuffAtivado == 4){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 25);} // 15 porcento de xp
                    Audio_Play(playerid, 59);
                    SubirDLevel(playerid);
                    SalvarConta(playerid);
                }
                case 2:{//Carga de Peixes
                    EmMissaoNormal[playerid] = 0;
                    IdentMissaoNormal[playerid] = 0;
                    MissoesNormalOpen[playerid] = 0;
                    MissaoNormalFinalizada[playerid] = 0;
                    Info[playerid][pMissaoN] = 0;
                    GivePlayerCash(playerid, 35);
                    if(BuffAtivado == 0){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 35);} // 0 porcento de xp
                    if(BuffAtivado == 1){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 35);} // 5 porcento de xp
                    if(BuffAtivado == 2){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 35);} // 7 porcento de xp
                    if(BuffAtivado == 3){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 35);} // 10 porcento de xp
                    if(BuffAtivado == 4){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 35);} // 15 porcento de xp
                    Audio_Play(playerid, 59);
                    SubirDLevel(playerid);
                    SalvarConta(playerid);
                    //SendClientMessage(playerid, -1, "carga de peixes");
                }
            }
            //SendClientMessage(playerid, COLOR_WHITE, "Entregar miss?o");
        }
    }else if(IsPlayerInRangeOfPoint(playerid, 1.5, 2830.6045, -2433.5054, 29.6660) && Info[playerid][pMember] == 3){// Kirigakure
        if(EmMissaoNormal[playerid] == 0 && IdentMissaoNormal[playerid] == 0 && MissoesNormalOpen[playerid] == 0 && MissaoNormalFinalizada[playerid] == 0)
        {
            // Prioridade: Quadro de Missoes Diarias (Rank -> sorteio -> oferta)
            if(Daily_TryOpenBoard(playerid)) return 1;

            MostrarMissoes(playerid, 2);
        }else if(MissaoNormalFinalizada[playerid] == 1){
            switch(Missoes)
            {
                case 3:{///Mensagem ao Assistente - Kirigakure
                    EmMissaoNormal[playerid] = 0;
                    IdentMissaoNormal[playerid] = 0;
                    MissoesNormalOpen[playerid] = 0;
                    MissaoNormalFinalizada[playerid] = 0;
                    Info[playerid][pMissaoKiri] = 1;
                    GivePlayerCash(playerid, 100);
                    if(BuffAtivado == 0){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 100);} // 0 porcento de xp
                    if(BuffAtivado == 1){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 100);} // 5 porcento de xp
                    if(BuffAtivado == 2){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 100);} // 7 porcento de xp
                    if(BuffAtivado == 3){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 100);} // 10 porcento de xp
                    if(BuffAtivado == 4){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 100);} // 15 porcento de xp
                    Audio_Play(playerid, 59);
                    SubirDLevel(playerid);
                    SalvarConta(playerid);
                    //SendClientMessage(playerid, -1, "Mensagem ao Assistente - Kirigakure");
                }
                case 4:{//Missoes do Gato - Kirigakure
                    EmMissaoNormal[playerid] = 0;
                    IdentMissaoNormal[playerid] = 0;
                    MissoesNormalOpen[playerid] = 0;
                    MissaoNormalFinalizada[playerid] = 0;
                    Info[playerid][pMissaoKiri] = 2;
                    GivePlayerCash(playerid, 150);
                    if(BuffAtivado == 0){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 150);} // 0 porcento de xp
                    if(BuffAtivado == 1){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 150);} // 5 porcento de xp
                    if(BuffAtivado == 2){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 150);} // 7 porcento de xp
                    if(BuffAtivado == 3){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 150);} // 10 porcento de xp
                    if(BuffAtivado == 4){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 150);} // 15 porcento de xp
                    Audio_Play(playerid, 59);
                    SubirDLevel(playerid);
                    SalvarConta(playerid);
                    //SendClientMessage(playerid, -1, "Missoes do Gato - Kirigakure");
                }
                case 5:{//Encomenda Hospital - Kirigakure
                    EmMissaoNormal[playerid] = 0;
                    IdentMissaoNormal[playerid] = 0;
                    MissoesNormalOpen[playerid] = 0;
                    MissaoNormalFinalizada[playerid] = 0;
                    Info[playerid][pMissaoKiri] = 0;
                    GivePlayerCash(playerid, 150);
                    if(BuffAtivado == 0){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 150);} // 0 porcento de xp
                    if(BuffAtivado == 1){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 150);} // 5 porcento de xp
                    if(BuffAtivado == 2){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 150);} // 7 porcento de xp
                    if(BuffAtivado == 3){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 150);} // 10 porcento de xp
                    if(BuffAtivado == 4){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 150);} // 15 porcento de xp
                    Audio_Play(playerid, 59);
                    SubirDLevel(playerid);
                    SalvarConta(playerid);
                    //SendClientMessage(playerid, -1, "Encomenda Hospital - Kirigakure");
                }
            }
        }
    }else if(IsPlayerInRangeOfPoint(playerid, 1.5, -1824.5286, 1882.3031, 2.0111) && Info[playerid][pMember] == 1){// Iwagakure
        if(EmMissaoNormal[playerid] == 0 && IdentMissaoNormal[playerid] == 0 && MissoesNormalOpen[playerid] == 0 && MissaoNormalFinalizada[playerid] == 0)
        {
            // Prioridade: Quadro de Missoes Diarias (Rank -> sorteio -> oferta)
            if(Daily_TryOpenBoard(playerid)) return 1;

            MostrarMissoes(playerid, 3);
        }else if(MissaoNormalFinalizada[playerid] == 1){
            switch(Missoes)
            {
                case 6:{///Documentos Delegacia - Iwagakure
                    EmMissaoNormal[playerid] = 0;
                    IdentMissaoNormal[playerid] = 0;
                    MissoesNormalOpen[playerid] = 0;
                    MissaoNormalFinalizada[playerid] = 0;
                    IwagakureIdentMissao[playerid] = 0;
                    IwagakureCPNum[playerid] = 0;
                    Info[playerid][pMissaoIwa] = 1;
                    GivePlayerCash(playerid, 100);
                    if(BuffAtivado == 0){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 500);} // 0 porcento de xp
                    if(BuffAtivado == 1){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 500);} // 5 porcento de xp
                    if(BuffAtivado == 2){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 500);} // 7 porcento de xp
                    if(BuffAtivado == 3){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 500);} // 10 porcento de xp
                    if(BuffAtivado == 4){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 500);} // 15 porcento de xp
                    Audio_Play(playerid, 59);
                    SubirDLevel(playerid);
                    SalvarConta(playerid);
                    //SendClientMessage(playerid, -1, "Documentos Delegacia - Iwagakure");
                }
                case 7:{///Encomenda Ichiraku - Iwagakure
                    EmMissaoNormal[playerid] = 0;
                    IdentMissaoNormal[playerid] = 0;
                    MissoesNormalOpen[playerid] = 0;
                    MissaoNormalFinalizada[playerid] = 0;
                    IwagakureCPNum[playerid] = 0;
                    Info[playerid][pMissaoIwa] = 2;
                    GivePlayerCash(playerid, 500);
                    if(BuffAtivado == 0){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 500);} // 0 porcento de xp
                    if(BuffAtivado == 1){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 500);} // 5 porcento de xp
                    if(BuffAtivado == 2){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 500);} // 7 porcento de xp
                    if(BuffAtivado == 3){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 500);} // 10 porcento de xp
                    if(BuffAtivado == 4){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 500);} // 15 porcento de xp
                    Audio_Play(playerid, 59);
                    SubirDLevel(playerid);
                    SalvarConta(playerid);
                    //SendClientMessage(playerid, -1, "Encomenda Ichiraku - Iwagakure");
                }
                case 9:{
                    EmMissaoNormal[playerid] = 0;
                    IdentMissaoNormal[playerid] = 0;
                    MissoesNormalOpen[playerid] = 0;
                    MissaoNormalFinalizada[playerid] = 0;
                    IwagakureCPNum[playerid] = 0;
                    Info[playerid][pMissaoIwa] = 0;
                    MissaoTobyIdent[playerid] = 0;
                    DestroyDynamicActor(DogTobbyObj[playerid]);
                    GivePlayerCash(playerid, 550);
                    if(BuffAtivado == 0){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 550);} // 0 porcento de xp
                    if(BuffAtivado == 1){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 550);} // 5 porcento de xp
                    if(BuffAtivado == 2){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 550);} // 7 porcento de xp
                    if(BuffAtivado == 3){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 550);} // 10 porcento de xp
                    if(BuffAtivado == 4){GivePlayerExperiencia(playerid, 1000); RyoseXPTxd(playerid, 1000, 550);} // 15 porcento de xp
                    Audio_Play(playerid, 59);
                    SubirDLevel(playerid);
                    SalvarConta(playerid);
                }
            }
        }
    }
    else if(IsPlayerInRangeOfPoint(playerid, 1.5, 205.5668, -769.1435, 13.9882)) // Konoha
    {
        if(EmMissaoNormal[playerid] == 0 && IdentMissaoNormal[playerid] == 0 && MissoesNormalOpen[playerid] == 0 && MissaoNormalFinalizada[playerid] == 0)
        {
            //MostrarMissoes(playerid, 4);
        }
        // Miss?o Concluida
    }
    return 1;
}
function TeclaMissoes(playerid, newkeys, oldkeys)
{
    if(BtnDireito[playerid] == 1) return 0;


    // Prioridade: Quadro de Missoes Diarias (Rank -> sorteio -> oferta)
    if(Daily_OnKey(playerid, newkeys, oldkeys)) return 1;

    if(PRESSED(KEY_CTRL_BACK))
    {
        // BLOQUEIO: enquanto nao graduar (nao escolheu clan), nao abre outras missoes.
        // A primeira experiencia do player deve ser /instrutor (Academia Missao 1).
        if(Missoes_AcademiaGate_Deny(playerid)) return 1;
    MissoesNew_UIEnsure(playerid);

        MissoesPosicao(playerid);
    }
    return 1;
}
function MostrarMissoes(playerid, type)
{
    if(Missoes_AcademiaGate_Deny(playerid)) return 1;
new string[200];
    switch(type)
    {
        //Nevada
        case 1:
        {
            if(Info[playerid][pMissaoN] == 0){
                MissoesNormalOpen[playerid] = 1;
                TextDrawShowForPlayer(playerid, MissoesBKG[0]);
                format(string, sizeof(string), "Aula de Movimentacao (RANK E)");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][0], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][0]); // Nome da Miss?o
                format(string, sizeof(string), "Ola jovem ninja! Antes de tudo, voce deve dominar as tecnicas basicas de movimentacao. Vamos comecar?");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][1], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][1]); // Descri??o da Miss?o
                format(string, sizeof(string), "1000");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][2], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][2]); // Ryos Miss?o
                format(string, sizeof(string), "1000");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][3], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][3]); // XP Completa
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][4], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][4]); // Bonus XP Carta
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][5], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][5]); // Bonus XP Dia
                PlayerTextDrawShow(playerid, MissoesNew[playerid][6]); // Recusar
                PlayerTextDrawShow(playerid, MissoesNew[playerid][7]); // Aceitar
                SelectTextDraw(playerid, 0xFF4040AA); // Ativar Sele??o
                Audio_Play(playerid, 58);
            }else if(Info[playerid][pMissaoN] == 1){
                MissoesNormalOpen[playerid] = 2;
                TextDrawShowForPlayer(playerid, MissoesBKG[0]);
                format(string, sizeof(string), "Carga de Peixes (Rank D)");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][0], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][0]); // Nome da Miss?o
                format(string, sizeof(string), "Eu preciso que voce leve esta encomenda de peixes para a fazenda aqui proximo la voce vai entregar e voltar ate mim para que eu possa lhe recompensar.");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][1], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][1]); // Descri??o da Miss?o
                format(string, sizeof(string), "1000");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][2], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][2]); // Ryos Miss?o
                format(string, sizeof(string), "1000");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][3], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][3]); // XP Completa
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][4], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][4]); // Bonus XP Carta
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][5], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][5]); // Bonus XP Dia
                PlayerTextDrawShow(playerid, MissoesNew[playerid][6]); // Recusar
                PlayerTextDrawShow(playerid, MissoesNew[playerid][7]); // Aceitar
                SelectTextDraw(playerid, 0xFF4040AA); // Ativar Sele??o
                Audio_Play(playerid, 58);
            }
            return 1;
        }
        //Nevada Final
        //Kirigakure
        case 2:
        {
            if(Info[playerid][pMissaoKiri] == 0){
                MissoesNormalOpen[playerid] = 3;
                TextDrawShowForPlayer(playerid, MissoesBKG[0]);
                format(string, sizeof(string), "Mensagem ao Assistente (Rank D)");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][0], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][0]); // Nome da Miss?o
                format(string, sizeof(string), "Preciso que leve esta carta ao Assistente que se encontra na sala do Kage, va e volte aqui para que eu possa lhe recompensar. Cuidado com esta carta!");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][1], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][1]); // Descri??o da Miss?o
                format(string, sizeof(string), "1000");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][2], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][2]); // Ryos Miss?o
                format(string, sizeof(string), "1000");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][3], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][3]); // XP Completa
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][4], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][4]); // Bonus XP Carta
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][5], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][5]); // Bonus XP Dia
                PlayerTextDrawShow(playerid, MissoesNew[playerid][6]); // Recusar
                PlayerTextDrawShow(playerid, MissoesNew[playerid][7]); // Aceitar
                SelectTextDraw(playerid, 0xFF4040AA); // Ativar Sele??o
                Audio_Play(playerid, 58);
            }else if(Info[playerid][pMissaoKiri] == 1){
                MissoesNormalOpen[playerid] = 4;
                TextDrawShowForPlayer(playerid, MissoesBKG[0]);
                format(string, sizeof(string), "Gato perdido (Rank D)");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][0], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][0]); // Nome da Miss?o
                format(string, sizeof(string), "Um gato de uma garota fugiu de sua casa temos uma boa recompensa para aqueles que conseguir achar este gato!");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][1], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][1]); // Descri??o da Miss?o
                format(string, sizeof(string), "1000");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][2], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][2]); // Ryos Miss?o
                format(string, sizeof(string), "1000");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][3], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][3]); // XP Completa
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][4], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][4]); // Bonus XP Carta
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][5], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][5]); // Bonus XP Dia
                PlayerTextDrawShow(playerid, MissoesNew[playerid][6]); // Recusar
                PlayerTextDrawShow(playerid, MissoesNew[playerid][7]); // Aceitar
                SelectTextDraw(playerid, 0xFF4040AA); // Ativar Sele??o
                Audio_Play(playerid, 58);
            }
            else if(Info[playerid][pMissaoKiri] == 2){
                MissoesNormalOpen[playerid] = 5;
                TextDrawShowForPlayer(playerid, MissoesBKG[0]);
                format(string, sizeof(string), "Encomenda Hospital (Rank D)");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][0], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][0]); // Nome da Miss?o
                format(string, sizeof(string), "Preciso de sua ajuda para uma emergencia, um policial nosso esta passando por alguns problemas de saude precisamos que busque uma encomenda de medicamentos e entregue no hospital!");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][1], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][1]); // Descri??o da Miss?o
                format(string, sizeof(string), "1000");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][2], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][2]); // Ryos Miss?o
                format(string, sizeof(string), "1000");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][3], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][3]); // XP Completa
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][4], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][4]); // Bonus XP Carta
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][5], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][5]); // Bonus XP Dia
                PlayerTextDrawShow(playerid, MissoesNew[playerid][6]); // Recusar
                PlayerTextDrawShow(playerid, MissoesNew[playerid][7]); // Aceitar
                SelectTextDraw(playerid, 0xFF4040AA); // Ativar Sele??o
                Audio_Play(playerid, 58);
            }
        }
        //Kirigakure Final
        //Iwagakure Inicio
        //Iwagakure Final
        case 3:{
            if(Info[playerid][pMissaoIwa] == 0){
                MissoesNormalOpen[playerid] = 6;
                TextDrawShowForPlayer(playerid, MissoesBKG[0]);
                format(string, sizeof(string), "Documentos Delegacia (Rank D)");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][0], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][0]); // Nome da Miss?o
                format(string, sizeof(string), "Recebemos uma solicitacao da delegacia para autorizar alguns procedimentos pela vila, por favor va ate a delegacia e pegue os documentos que esta com o policial e traga pra mim pra eu assinar!");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][1], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][1]); // Descri??o da Miss?o
                format(string, sizeof(string), "1000");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][2], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][2]); // Ryos Miss?o
                format(string, sizeof(string), "1000");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][3], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][3]); // XP Completa
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][4], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][4]); // Bonus XP Carta
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][5], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][5]); // Bonus XP Dia
                PlayerTextDrawShow(playerid, MissoesNew[playerid][6]); // Recusar
                PlayerTextDrawShow(playerid, MissoesNew[playerid][7]); // Aceitar
                SelectTextDraw(playerid, 0xFF4040AA); // Ativar Sele??o
                Audio_Play(playerid, 58);
            }
            if(Info[playerid][pMissaoIwa] == 1){
                MissoesNormalOpen[playerid] = 7;
                TextDrawShowForPlayer(playerid, MissoesBKG[0]);
                format(string, sizeof(string), "Encomenda Ichiraku (Rank D)");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][0], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][0]); // Nome da Miss?o
                format(string, sizeof(string), "Pegue uma encomenda que se encontra na vila da cachoeira e leve ela ate o Ichiraku apos volte aqui que irei lhe recompensar!");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][1], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][1]); // Descri??o da Miss?o
                format(string, sizeof(string), "1000");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][2], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][2]); // Ryos Miss?o
                format(string, sizeof(string), "1000");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][3], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][3]); // XP Completa
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][4], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][4]); // Bonus XP Carta
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][5], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][5]); // Bonus XP Dia
                PlayerTextDrawShow(playerid, MissoesNew[playerid][6]); // Recusar
                PlayerTextDrawShow(playerid, MissoesNew[playerid][7]); // Aceitar
                SelectTextDraw(playerid, 0xFF4040AA); // Ativar Sele??o
                Audio_Play(playerid, 58);
            }
            if(Info[playerid][pMissaoIwa] == 2)
            {
                MissoesNormalOpen[playerid] = 9;
                TextDrawShowForPlayer(playerid, MissoesBKG[0]);
                format(string, sizeof(string), "Resgate (Rank D)");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][0], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][0]); // Nome da Miss?o
                format(string, sizeof(string), "Um dos cachorros do departamento de policia de Iwagakure fugiu do treinamento, a sua missao e encontra-lo. Va para a delegacia pegar as informacoes sobre o cachorro!");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][1], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][1]); // Descri??o da Miss?o
                format(string, sizeof(string), "1000");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][2], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][2]); // Ryos Miss?o
                format(string, sizeof(string), "1000");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][3], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][3]); // XP Completa
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][4], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][4]); // Bonus XP Carta
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][5], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][5]); // Bonus XP Dia
                PlayerTextDrawShow(playerid, MissoesNew[playerid][6]); // Recusar
                PlayerTextDrawShow(playerid, MissoesNew[playerid][7]); // Aceitar
                SelectTextDraw(playerid, 0xFF4040AA); // Ativar Sele??o
                Audio_Play(playerid, 58);
            }
        }
        //Konoha Inicio
        case 4:
        {
            if(Info[playerid][pMissaoKonoha] == 0){
                MissoesNormalOpen[playerid] = 8;
                TextDrawShowForPlayer(playerid, MissoesBKG[0]);
                format(string, sizeof(string), "Missao da Flor da Lua (Rank S)");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][0], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][0]); // Nome da Miss?o
                format(string, sizeof(string), "Neste mundo ha uma lenda sobre uma flor rara chamada Flor da Lua que floresce apenas umas vez por mes em um local secreto a lenda diz que esta flor tem o poder de selar o amor verdadeiro e fortalecer os lacos entre as pessoas. Voce quer ir encontrar-la?");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][1], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][1]); // Descri??o da Miss?o
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][2], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][2]); // Ryos Miss?o
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][3], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][3]); // XP Completa
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][4], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][4]); // Bonus XP Carta
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][5], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][5]); // Bonus XP Dia
                PlayerTextDrawShow(playerid, MissoesNew[playerid][6]); // Recusar
                PlayerTextDrawShow(playerid, MissoesNew[playerid][7]); // Aceitar
                SelectTextDraw(playerid, 0xFF4040AA); // Ativar Sele??o
                Audio_Play(playerid, 58);
            }
        }
        case 5: // MISS?O KAGE (Ramen)
        {
            if(MissaoKageID[playerid] == 0)
            {
                AbriuMissaoKage[playerid] = 1;
                TextDrawShowForPlayer(playerid, MissoesBKG[0]);
                format(string, sizeof(string), "Missao Ramen (Estoque) (RANK E)");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][0], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][0]); // Nome da Miss?o
                format(string, sizeof(string), "Busque uma encomenda de alimentos no Velho Tronco e leve para o Ichiraku");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][1], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][1]); // Descri??o da Miss?o
                if(Info[playerid][pMember] == 1)
                {
                    format(string, sizeof(string), "1000");
                    PlayerTextDrawSetString(playerid, MissoesNew[playerid][2], string);
                }
                if(Info[playerid][pMember] == 3 || Info[playerid][pMember] == 5)
                {
                    format(string, sizeof(string), "1000");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][2], string);
                }
                PlayerTextDrawShow(playerid, MissoesNew[playerid][2]); // Ryos Miss?o
                if(Info[playerid][pMember] == 1)
                {
                    format(string, sizeof(string), "1000");
                    PlayerTextDrawSetString(playerid, MissoesNew[playerid][3], string);
                }
                if(Info[playerid][pMember] == 3 || Info[playerid][pMember] == 5)
                {
                    format(string, sizeof(string), "1000");
                    PlayerTextDrawSetString(playerid, MissoesNew[playerid][3], string);
                }
                PlayerTextDrawShow(playerid, MissoesNew[playerid][3]); // XP Completa
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][4], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][4]); // Bonus XP Carta
                format(string, sizeof(string), "0");
                PlayerTextDrawSetString(playerid, MissoesNew[playerid][5], string);
                PlayerTextDrawShow(playerid, MissoesNew[playerid][5]); // Bonus XP Dia
                PlayerTextDrawShow(playerid, MissoesNew[playerid][6]); // Recusar
                PlayerTextDrawShow(playerid, MissoesNew[playerid][7]); // Aceitar
                SelectTextDraw(playerid, 0xFF4040AA); // Ativar Sele??o
                Audio_Play(playerid, 58);
            }
        }

    }
    return 0;
}
AoClicarNaMissoes(playerid, PlayerText:playertextid)
{
        // Se o painel aberto for o da Missao 1 da Academia, deixa ela tratar Aceitar/Recusar.
    if(GetPVarInt(playerid, "ACA_M1_TXDOPEN") == 1)
    {
        return AcaM1_ClickHandler(playerid, playertextid);
    }

new string[128],
        Missoes = MissoesNormalOpen[playerid], stringki[220];
    new MissoesKage = AbriuMissaoKage[playerid];
    new SenseiNome[64];
    if(playertextid == MissoesNew[playerid][6]) // Recusar
    {
        TogglePlayerControllable(playerid, true);
        MissoesNormalOpen[playerid] = 0;
        AbriuMissaoKage[playerid] = 0;
        TextDrawHideForPlayer(playerid, MissoesBKG[0]);
        PlayerTextDrawHide(playerid, MissoesNew[playerid][0]);
        PlayerTextDrawHide(playerid, MissoesNew[playerid][1]);
        PlayerTextDrawHide(playerid, MissoesNew[playerid][2]);
        PlayerTextDrawHide(playerid, MissoesNew[playerid][3]);
        PlayerTextDrawHide(playerid, MissoesNew[playerid][4]);
        PlayerTextDrawHide(playerid, MissoesNew[playerid][5]);
        PlayerTextDrawHide(playerid, MissoesNew[playerid][6]);
        PlayerTextDrawHide(playerid, MissoesNew[playerid][7]);
        CancelSelectTextDraw(playerid);
        BarrasNarutoOn(playerid);
        Audio_Play(playerid, 58);
        return 1;
    }
    if(playertextid == MissoesNew[playerid][7]) // Aceitar
    {
        if(MissoesKage == 1)
        {
            //Miss?o ESTOQUE RAMEN KIRI
                if(Info[playerid][pMember] == 1){MissaoKageID[playerid] = 3;}// Iwagakure
                else if(Info[playerid][pMember] == 3){MissaoKageID[playerid] = 1;}// Kirigakure
                else if(Info[playerid][pMember] == 5){MissaoKageID[playerid] = 4;}// Kumogakure

                format(stringki, sizeof(stringki), "{AB7C4E}(MISS?O) Voc? recebeu a miss?o de ir buscar uma encomenda de alimentos.");
                SendClientMessage(playerid, 1, stringki);
                format(stringki, sizeof(stringki), "{AB7C4E}(KAGE) O ninja {FFFFFF}%s{AB7C4E} aceitou a miss?o (ESTOQUE RAMEN).", PlayerNameDados(playerid));
                SendClientMessage(KageQuePassouM[playerid], 1, stringki);
                AbriuMissaoKage[playerid] = 0;
                SetPlayerCheckpoint(playerid, 1358.3079, -1502.4524, 8.2853, 5.0);

                TextDrawHideForPlayer(playerid, MissoesBKG[0]);
                PlayerTextDrawHide(playerid, MissoesNew[playerid][0]);
                PlayerTextDrawHide(playerid, MissoesNew[playerid][1]);
                PlayerTextDrawHide(playerid, MissoesNew[playerid][2]);
                PlayerTextDrawHide(playerid, MissoesNew[playerid][3]);
                PlayerTextDrawHide(playerid, MissoesNew[playerid][4]);
                PlayerTextDrawHide(playerid, MissoesNew[playerid][5]);
                PlayerTextDrawHide(playerid, MissoesNew[playerid][6]);
                PlayerTextDrawHide(playerid, MissoesNew[playerid][7]);
                CancelSelectTextDraw(playerid);
        BarrasNarutoOn(playerid);
        Audio_Play(playerid, 58);
        }
        /*switch(MissoesKage)
        {
            case 0: return 0;
            case 1:{
                //Miss?o ESTOQUE RAMEN KIRI
                if(Info[playerid][pMember] == 1){MissaoKageID[playerid] = 3;}// Iwagakure
                else if(Info[playerid][pMember] == 3){MissaoKageID[playerid] = 1;}// Kirigakure

                format(stringki, sizeof(stringki), "{AB7C4E}(MISS?O) Voc? recebeu a miss?o de ir buscar uma encomenda de alimentos.");
                SendClientMessage(playerid, 1, stringki);
                format(stringki, sizeof(stringki), "{AB7C4E}(KAGE) O ninja {FFFFFF}%s{AB7C4E} aceitou a miss?o (ESTOQUE RAMEN).", PlayerNameDados(playerid));
                SendClientMessage(KageQuePassouM[playerid], 1, stringki);
                AbriuMissaoKage[playerid] = 0;
                SetPlayerCheckpoint(playerid, 1358.3079, -1502.4524, 8.2853, 5.0);

                TextDrawHideForPlayer(playerid, MissoesBKG[0]);
                PlayerTextDrawHide(playerid, MissoesNew[playerid][0]);
                PlayerTextDrawHide(playerid, MissoesNew[playerid][1]);
                PlayerTextDrawHide(playerid, MissoesNew[playerid][2]);
                PlayerTextDrawHide(playerid, MissoesNew[playerid][3]);
                PlayerTextDrawHide(playerid, MissoesNew[playerid][4]);
                PlayerTextDrawHide(playerid, MissoesNew[playerid][5]);
                PlayerTextDrawHide(playerid, MissoesNew[playerid][6]);
                PlayerTextDrawHide(playerid, MissoesNew[playerid][7]);
                CancelSelectTextDraw(playerid);
        BarrasNarutoOn(playerid);
        Audio_Play(playerid, 58);
            }
        }*/
        switch(Missoes)
        {
            case 0: return 0;
            case 1:{//Movimentacao Miss?o
                KillTimer(TimerCPAcademia[playerid]);
                KillTimer(TimerNPCAcademia[playerid]);
                EmMissaoNormal[playerid] = 1;
                IdentMissaoNormal[playerid] = 1;
                MissaoCPAcademia[playerid] = 0;
                TogglePlayerControllable(playerid, false);
                //Dialogo
                SenseiNome = "Guy Sensei";
                PlayerTextDrawShow(playerid, MissaoDialogo[playerid][0]); // Dialogo
                format(stringki, sizeof(stringki), "%s", SenseiNome);
                PlayerTextDrawSetString(playerid, MissaoDialogo[playerid][1], stringki);
                PlayerTextDrawShow(playerid, MissaoDialogo[playerid][1]); // Nome
                format(stringki, sizeof(stringki), "Estarei lhe esperando no local para iniciarmos o treinamento de movimentacao.");
                PlayerTextDrawShow(playerid, MissaoDialogo[playerid][2]); // Texto
                SetPlayerVirtualWorld(playerid, 50);
                NPCMissaoAcademia[playerid] = CreateDynamicActor(125, 2865.6816, -2411.9387, 41.4118, 222.9284, 1, 100.0, 50, -1, playerid, 50);
                TimerNPCAcademia[playerid] = SetTimerEx("InicioMissaoMove", 2500, false, "d", playerid);
                //Tempo para npc

            }
            case 2:{
                //Encomenda de Peixes
                EmMissaoNormal[playerid] = 2;
                IdentMissaoNormal[playerid] = 2;
                format(stringki, sizeof(stringki), "{AB7C4E}(MISS?O) {FFFFFF}Voc? recebeu uma {AB7C4E}Encomenda de Peixes{FFFFFF}, entregue-a em uma fazenda proxima!");
                SendClientMessage(playerid, COLOR_WHITE, stringki);
                NevadaPeixesCP[playerid] = SetPlayerCheckpoint(playerid, 2107.3193, -952.6356, 80.7842, 2.0);
            }
            //Nevada Final
            //Kirigakure Inicio
            case 3:{//Mensagem ao Assistente
                EmMissaoNormal[playerid] = 3;
                IdentMissaoNormal[playerid] = 3;
                format(stringki, sizeof(stringki), "{AB7C4E}(MISS?O) {FFFFFF}Voc? recebeu uma {AB7C4E}carta{FFFFFF} leve para o assistente na sala do Kage!");
                SendClientMessage(playerid, COLOR_WHITE, stringki);
                KirigakureMissao1CP[playerid] = SetPlayerCheckpoint(playerid, 2583.4741, -2301.5586, 64.5547, 2.0);
            }
            case 4:{//Gato perdido
                new GatoPos = random(6);
                new GatoID = 15821;
                switch(GatoPos)
                {
                    case 0:{
                        EmMissaoNormal[playerid] = 4;
                        IdentMissaoNormal[playerid] = 4;

                        KirigakureMissao2NM[playerid] = 1;
                        ObjKirigakureGato[playerid] = CreateObject(GatoID, 2876.1316, -2652.3762, 34.5156, 0.0, 0.0, 96.0, 300.0); // OK

                        SetPlayerCheckpoint(playerid, 2876.1316, -2652.3762, 34.5156, 2.0);
                    }
                    case 1:{
                        EmMissaoNormal[playerid] = 4;
                        IdentMissaoNormal[playerid] = 4;

                        KirigakureMissao2NM[playerid] = 2;
                        ObjKirigakureGato[playerid] = CreateObject(GatoID, 2656.1375, -2660.8972, 43.2024, 0.0, 0.0, 96.0, 300.0); // OK

                        SetPlayerCheckpoint(playerid, 2656.1375, -2660.8972, 43.2024, 2.0);
                    }
                    case 2:{
                        EmMissaoNormal[playerid] = 4;
                        IdentMissaoNormal[playerid] = 4;

                        KirigakureMissao2NM[playerid] = 3;
                        ObjKirigakureGato[playerid] = CreateObject(GatoID, 2258.9939, -2726.3262, 28.8453, 0.0, 0.0, 96.0, 300.0); // OK

                        SetPlayerCheckpoint(playerid, 2258.9939, -2726.3262, 28.8453, 2.0);
                    }
                    case 3:{
                        EmMissaoNormal[playerid] = 4;
                        IdentMissaoNormal[playerid] = 4;

                        KirigakureMissao2NM[playerid] = 4;
                        ObjKirigakureGato[playerid] = CreateObject(GatoID, 2660.7400, -2499.0811, 28.5719, 0.0, 0.0, 96.0, 300.0); // OK

                        SetPlayerCheckpoint(playerid, 2660.7400, -2499.0811, 28.5719, 2.0);
                    }
                    case 4:{
                        EmMissaoNormal[playerid] = 4;
                        IdentMissaoNormal[playerid] = 4;

                        KirigakureMissao2NM[playerid] = 5;
                        ObjKirigakureGato[playerid] = CreateObject(GatoID, 2310.7656, -2258.2722, 52.9607, 0.0, 0.0, 96.0, 300.0); // OK

                        SetPlayerCheckpoint(playerid, 2310.7656, -2258.2722, 52.9607, 2.0);
                    }
                    case 5:{
                        EmMissaoNormal[playerid] = 4;
                        IdentMissaoNormal[playerid] = 4;

                        KirigakureMissao2NM[playerid] = 6;
                        ObjKirigakureGato[playerid] = CreateObject(GatoID, 2512.4011, -2119.1233, 81.7266, 0.0, 0.0, 96.0, 300.0); // OK

                        SetPlayerCheckpoint(playerid, 2512.4011, -2119.1233, 81.7266, 2.0);
                    }
                }
                format(stringki, sizeof(stringki), "{AB7C4E}(MISS?O) {FFFFFF}Procure o {AB7C4E}gato{FFFFFF} perdido e {AB7C4E}leve-o ate o sensei{FFFFFF} na academia!");
                SendClientMessage(playerid, COLOR_WHITE, stringki);
                //format(string, sizeof(string), "O a posi??o do gato foi (%d)", GatoPos);
                //SendClientMessage(playerid, COLOR_WHITE, string);

            }
            case 5:{
                EmMissaoNormal[playerid] = 5;
                IdentMissaoNormal[playerid] = 5;
                KirigakureHospitalCP[playerid] = SetPlayerCheckpoint(playerid, 2538.404785, -861.105651, 29.422710, 2.0);
                format(stringki, sizeof(stringki), "{AB7C4E}(MISS?O) {FFFFFF}V? ate a vila de {AB7C4E}Tetsugakure{FFFFFF} buscar uma {AB7C4E}encomenda{FFFFFF} para o hospital.");
                SendClientMessage(playerid, COLOR_WHITE, stringki);
            }
            //Kirigakure Final
            //Iwagakure Inicio
            case 6:{
                EmMissaoNormal[playerid] = 6;
                IdentMissaoNormal[playerid] = 6;
                IwagakureIdentMissao[playerid] = 1;
                IwagakureDelegaciaCP[playerid] = SetPlayerCheckpoint(playerid, -1397.9189, 1549.5508, 7.8914, 2.0);
                format(stringki, sizeof(stringki), "{AB7C4E}(MISS?O) {FFFFFF}Voc? recebeu a tarefa de {AB7C4E}Pegar Documentos{FFFFFF} na delegacia, retorne para receber sua recompensa!");
                SendClientMessage(playerid, COLOR_WHITE, stringki);
            }
            case 7:{
                EmMissaoNormal[playerid] = 7;
                IdentMissaoNormal[playerid] = 7;
                IwagakureIchirakuNUM[playerid] = 1;
                IwagakureIchirakuCP[playerid] = SetPlayerCheckpoint(playerid, 179.9275, 1333.1051, 3.4164, 2.0);
                format(stringki, sizeof(stringki), "{AB7C4E}(MISS?O) {FFFFFF}V? e pegue uma {AB7C4E}Encomenda{FFFFFF} na vila da cachoeira e leve ela ate o Ichiraku");
                SendClientMessage(playerid, COLOR_WHITE, stringki);
            }
            case 9:{
                MissaoTobyIdent[playerid] = 6;
                EmMissaoNormal[playerid] = 9;
                IdentMissaoNormal[playerid] = 9;
                CPDogDP[playerid] = SetPlayerCheckpoint(playerid, -1404.7218, 1541.1235, 7.8914, 2.0);
                format(stringki, sizeof(stringki), "{AB7C4E}(MISS?O) {FFFFFF}V? ate a delegacia e pegue a {AB7C4E}Informa?ao{FFFFFF} sobre o cachorro desaparecido.");
                SendClientMessage(playerid, COLOR_WHITE, stringki);
            }
            //Iwagakure Final
            //Konoha Inicio
            case 8:{
                EmMissaoNormal[playerid] = 8;
                IdentMissaoNormal[playerid] = 8;
                FlorDaLuaMissaoIdent[playerid] = 1; // Identidade da Miss?o da Lua para usar comando
                format(stringki, sizeof(stringki), "{AB7C4E}(MISS?O){FFFFFF} Voc? precisa convidar uma pessoa para essa miss?o. {AB7C4E}Use o comando /convidarmissao{FFFFFF}.");
                SendClientMessage(playerid, COLOR_WHITE, stringki);
            }
            //Konoha Final
        }
        MissoesNormalOpen[playerid] = 0;
        TextDrawHideForPlayer(playerid, MissoesBKG[0]);
        PlayerTextDrawHide(playerid, MissoesNew[playerid][0]);
        PlayerTextDrawHide(playerid, MissoesNew[playerid][1]);
        PlayerTextDrawHide(playerid, MissoesNew[playerid][2]);
        PlayerTextDrawHide(playerid, MissoesNew[playerid][3]);
        PlayerTextDrawHide(playerid, MissoesNew[playerid][4]);
        PlayerTextDrawHide(playerid, MissoesNew[playerid][5]);
        PlayerTextDrawHide(playerid, MissoesNew[playerid][6]);
        PlayerTextDrawHide(playerid, MissoesNew[playerid][7]);
        CancelSelectTextDraw(playerid);
        BarrasNarutoOn(playerid);
        Audio_Play(playerid, 58);
    }
    return 0;
}