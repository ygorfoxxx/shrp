#if defined ACA_M1_TXD_INC
#endinput
#endif
#define ACA_M1_TXD_INC

#include <a_samp>
#include <zcmd>


// --- Aliases para evitar truncamento de 31 chars ---
#if !defined AcaM1_OnPlayerClickPlayerTextDraw
#define AcaM1_OnPlayerClickPlayerTextDraw AcaM1_ClickPTD
#endif
#if !defined AcaM1_OnDialogResponse
#define AcaM1_OnDialogResponse AcaM1_DialogResp
#endif
#if !defined AcaM1_OnPlayerSpawn
#define AcaM1_OnPlayerSpawn AcaM1_Spawn
#endif
#if !defined AcaM1_OnPlayerClickTextDraw
#define AcaM1_OnPlayerClickTextDraw AcaM1_ClickTD
#endif

/*
    ==========================================================
      SHRP - Academia (Missao 1) - Estilo TXD (Painel de Missoes)
    ==========================================================
*/

// ===============================
// Configs / Coordenadas
// ===============================
#define ACA_M1_ENTRADA_RADIUS      (12.0)
#define ACA_M1_INSTRUTOR_RADIUS    (3.5)

// Recompensas
#define ACA_M1_REWARD_RYOUS        (250)
#define ACA_M1_REWARD_XP           (1000)
#define ACA_M1_UI_TAG              (999)

// Entradas
#if !defined ACA_M1_ENT_KIRI_X
#define ACA_M1_ENT_KIRI_X (2811.5266)
#endif
#if !defined ACA_M1_ENT_KIRI_Y
#define ACA_M1_ENT_KIRI_Y (-2432.2561)
#endif
#if !defined ACA_M1_ENT_KIRI_Z
#define ACA_M1_ENT_KIRI_Z (29.6232)
#endif

#if !defined ACA_M1_ENT_IWA_X
#define ACA_M1_ENT_IWA_X (-1819.0652)
#endif
#if !defined ACA_M1_ENT_IWA_Y
#define ACA_M1_ENT_IWA_Y (1863.1150)
#endif
#if !defined ACA_M1_ENT_IWA_Z
#define ACA_M1_ENT_IWA_Z (2.0700)
#endif

// Posicao do Instrutor
#if !defined ACA_M1_INS_KIRI_X
#define ACA_M1_INS_KIRI_X (2830.6045)
#endif
#if !defined ACA_M1_INS_KIRI_Y
#define ACA_M1_INS_KIRI_Y (-2433.5054)
#endif
#if !defined ACA_M1_INS_KIRI_Z
#define ACA_M1_INS_KIRI_Z (29.6660)
#endif

#if !defined ACA_M1_INS_IWA_X
#define ACA_M1_INS_IWA_X (-1824.5286)
#endif
#if !defined ACA_M1_INS_IWA_Y
#define ACA_M1_INS_IWA_Y (1882.3031)
#endif
#if !defined ACA_M1_INS_IWA_Z
#define ACA_M1_INS_IWA_Z (2.0111)
#endif

// Vila
#define ACA_M1_VILA_KIRI  (1)
#define ACA_M1_VILA_IWA   (2)

// ===============================
// Dialog IDs
// ===============================
#define DIALOG_ACA_M1_START    (19701)
#define DIALOG_ACA_M1_Q1       (19702)
#define DIALOG_ACA_M1_Q2       (19703)
#define DIALOG_ACA_M1_Q3       (19704)
#define DIALOG_ACA_M1_Q4       (19705)
#define DIALOG_ACA_M1_Q5       (19706)

// ===============================
// PVars
// ===============================
#define P_ACA_M1_STAGE      "ACA_M1_STAGE"
#define P_ACA_M1_DONE       "ACA_M1_DONE"
#define P_ACA_M1_VILA       "ACA_M1_VILA"
#define P_ACA_M1_TMR        "ACA_M1_TMR"
#define P_ACA_M1_TXDOPEN    "ACA_M1_TXDOPEN"
#define P_ACA_M1_DBGSEL     "ACA_M1_DBGSEL"
#define P_ACA_M1_PREVOPEN   "ACA_M1_PREVOPEN"
#define P_ACA_M1_TUTSTEP    "ACA_M1_TUTSTEP"
#define P_ACA_M1_TUTTMR     "ACA_M1_TUTTMR"
#define P_ACA_M1_SELTMR     "ACA_M1_SELTMR"

// ===============================
// Forwards / Publics
// ===============================
forward AcaM1_TickProximidade(playerid);
forward AcaM1_TickTutorial(playerid);
forward AcaM1_KeepSelectTick(playerid);
forward AcaM1_ForceSelectTD(playerid);
forward AcaM1_OpenTXD_Delayed(playerid);
forward AcaM1_ReshowAndReselect(playerid);

// ===============================
// Helpers
// ===============================
stock AcaM1_IsDone(playerid)
{
    if(Info[playerid][pClan] != 0) return 1;
    return (GetPVarInt(playerid, P_ACA_M1_DONE) == 1);
}

stock AcaM1_GetVila(playerid)
{
    new v = GetPVarInt(playerid, P_ACA_M1_VILA);
    if(v != ACA_M1_VILA_KIRI && v != ACA_M1_VILA_IWA) v = 0;
    return v;
}

stock AcaM1_SetVilaByNearestEntrance(playerid)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    new Float:dx1 = (px - ACA_M1_ENT_KIRI_X);
    new Float:dy1 = (py - ACA_M1_ENT_KIRI_Y);
    new Float:dz1 = (pz - ACA_M1_ENT_KIRI_Z);
    new Float:dKiri = (dx1*dx1 + dy1*dy1 + dz1*dz1);

    new Float:dx2 = (px - ACA_M1_ENT_IWA_X);
    new Float:dy2 = (py - ACA_M1_ENT_IWA_Y);
    new Float:dz2 = (pz - ACA_M1_ENT_IWA_Z);
    new Float:dIwa = (dx2*dx2 + dy2*dy2 + dz2*dz2);

    if(dKiri <= dIwa) SetPVarInt(playerid, P_ACA_M1_VILA, ACA_M1_VILA_KIRI);
    else SetPVarInt(playerid, P_ACA_M1_VILA, ACA_M1_VILA_IWA);
}

stock AcaM1_KillTimerSafe(playerid, pvarTimerName[])
{
    new t = GetPVarInt(playerid, pvarTimerName);
    if(t > 0)
    {
        KillTimer(t);
        SetPVarInt(playerid, pvarTimerName, 0);
    }
}

stock AcaM1_FormatDots(value, out[], outLen)
{
    new tmp[16];
    format(tmp, sizeof(tmp), "%d", value);

    new len = strlen(tmp);
    new o = 0;
    for(new i=0; i<len && o < outLen-1; i++)
    {
        if(i > 0 && ((len - i) % 3 == 0) && o < outLen-1)
            out[o++] = '.';

        if(o < outLen-1) out[o++] = tmp[i];
    }
    out[o] = '\0';
    return 1;
}

public AcaM1_ForceSelectTD(playerid)
{
    if(!IsPlayerConnected(playerid) || IsPlayerNPC(playerid)) return 1;
    if(GetPVarInt(playerid, P_ACA_M1_TXDOPEN) == 1) SelectTextDraw(playerid, 0xFF4040AA);
    return 1;
}

public AcaM1_KeepSelectTick(playerid)
{
    if(GetPVarInt(playerid, P_ACA_M1_DBGSEL) == 0){ SetPVarInt(playerid, P_ACA_M1_DBGSEL, 1); }
    if(!IsPlayerConnected(playerid) || IsPlayerNPC(playerid)) return 0;
    if(GetPVarInt(playerid, P_ACA_M1_TXDOPEN) != 1)
    {
        AcaM1_KillTimerSafe(playerid, P_ACA_M1_SELTMR);
        return 0;
    }

    // Reforca Selectable
    if(MissoesNew[playerid][6] != PlayerText:INVALID_TEXT_DRAW)
        PlayerTextDrawSetSelectable(playerid, MissoesNew[playerid][6], 1);
    if(MissoesNew[playerid][7] != PlayerText:INVALID_TEXT_DRAW)
        PlayerTextDrawSetSelectable(playerid, MissoesNew[playerid][7], 1);

    SelectTextDraw(playerid, 0xFF4040AA);
    return 1;
}

stock AcaM1_IsNearInstructor(playerid)
{
    if(IsPlayerInRangeOfPoint(playerid, ACA_M1_INSTRUTOR_RADIUS, ACA_M1_INS_IWA_X, ACA_M1_INS_IWA_Y, ACA_M1_INS_IWA_Z))
    {
        SetPVarInt(playerid, P_ACA_M1_VILA, ACA_M1_VILA_IWA);
        return 1;
    }
    if(IsPlayerInRangeOfPoint(playerid, ACA_M1_INSTRUTOR_RADIUS, ACA_M1_INS_KIRI_X, ACA_M1_INS_KIRI_Y, ACA_M1_INS_KIRI_Z))
    {
        SetPVarInt(playerid, P_ACA_M1_VILA, ACA_M1_VILA_KIRI);
        return 1;
    }
    return 0;
}

stock AcaM1_TryOpenFromKey(playerid)
{
    if(AcaM1_IsDone(playerid)) return 0;
    if(!AcaM1_IsNearInstructor(playerid)) return 0;

    if(GetPVarInt(playerid, P_ACA_M1_STAGE) < 2)
        SetPVarInt(playerid, P_ACA_M1_STAGE, 2);

    if(GetPVarInt(playerid, P_ACA_M1_TXDOPEN) == 1) return 1;

    if(GetPVarInt(playerid, "ACA_M1_OPENPENDING") == 1) return 1;
    SetPVarInt(playerid, "ACA_M1_OPENPENDING", 1);
    SetTimerEx("AcaM1_OpenTXD_Delayed", 1, false, "i", playerid);
    return 1;
}

public AcaM1_OpenTXD_Delayed(playerid)
{
    DeletePVar(playerid, "ACA_M1_OPENPENDING");
    return AcaM1_OpenTXD(playerid);
}

public AcaM1_ReshowAndReselect(playerid)
{
    if(GetPVarInt(playerid, P_ACA_M1_TXDOPEN) != 1) return 1;
    TextDrawShowForPlayer(playerid, MissoesBKG[0]);
    for(new i = 0; i < 8; i++)
    {
        if(MissoesNew[playerid][i] != PlayerText:INVALID_TEXT_DRAW)
            PlayerTextDrawShow(playerid, MissoesNew[playerid][i]);
    }
    SelectTextDraw(playerid, 0xFF4040AA);
    return 1;
}

// ==========================================================
// FUNCAO PRINCIPAL DE ABERTURA (CORRIGIDA)
// ==========================================================
stock AcaM1_OpenTXD(playerid)
{
    if(AcaM1_IsDone(playerid)) return 0;
    if(GetPVarInt(playerid, P_ACA_M1_TXDOPEN) == 1) return 1;
    if(GetPVarInt(playerid, P_ACA_M1_STAGE) < 2) return 0;

    // --- CORRECAO PRINCIPAL ---
    // Em vez de usar MissoesNew_UIEnsure (que pode falhar se os IDs estiverem sujos),
    // nos forçamos a destruicao e recriacao limpa dos TextDraws.
    // Isso garante que os botoes e a descricao existam de verdade.
    
    // 1. Destroi qualquer residuo anterior
    MissoesNew_UIDestroy(playerid);
    
    // 2. Cria TextDraws novinhos em folha
    Missoes_CreatePlayerTextDraws_New(playerid);

    // UI Setup
    CancelSelectTextDraw(playerid);
    BarrasNarutoOff(playerid);

    SetPVarInt(playerid, P_ACA_M1_TXDOPEN, 1);
    SetPVarInt(playerid, P_ACA_M1_PREVOPEN, MissoesNormalOpen[playerid]);
    MissoesNormalOpen[playerid] = 1;

    // Abre background global
    TextDrawShowForPlayer(playerid, MissoesBKG[0]);

    // Conteudo
    PlayerTextDrawSetString(playerid, MissoesNew[playerid][0], "Boas vindas a academia (RANK E)");

    new __desc[512];
    format(__desc, sizeof(__desc), "Seja bem-vindo(a), jovem shinobi!~n~~n~Aqui voce vai aprender o basico do nosso servidor.~n~Voce pode: (1) iniciar o tutorial guiado, ou (2) pular e ir direto para a prova.~n~~n~Se for sua primeira vez, recomendo o tutorial.");
    PlayerTextDrawSetString(playerid, MissoesNew[playerid][1], __desc);

    PlayerTextDrawSetString(playerid, MissoesNew[playerid][2], "Ryous: ~g~+250");
    PlayerTextDrawSetString(playerid, MissoesNew[playerid][3], "XP: ~b~+1.000");
    PlayerTextDrawSetString(playerid, MissoesNew[playerid][4], "Fama: ~y~+0");
    PlayerTextDrawSetString(playerid, MissoesNew[playerid][5], "Op. Publica: ~p~+0");

    PlayerTextDrawSetString(playerid, MissoesNew[playerid][6], "Recusar");
    PlayerTextDrawSetString(playerid, MissoesNew[playerid][7], "Aceitar");

    // REFORÇA que sao clicaveis (as vezes perde na recriacao)
    if(MissoesNew[playerid][6] != PlayerText:INVALID_TEXT_DRAW) PlayerTextDrawSetSelectable(playerid, MissoesNew[playerid][6], 1);
    if(MissoesNew[playerid][7] != PlayerText:INVALID_TEXT_DRAW) PlayerTextDrawSetSelectable(playerid, MissoesNew[playerid][7], 1);

    // Mostra tudo
    for(new i2 = 0; i2 < 8; i2++)
    {
        if(MissoesNew[playerid][i2] != PlayerText:INVALID_TEXT_DRAW)
            PlayerTextDrawShow(playerid, MissoesNew[playerid][i2]);
    }

    SelectTextDraw(playerid, 0xFF4040AA);
    SetTimerEx("AcaM1_ForceSelectTD", 150, false, "i", playerid);

    AcaM1_KillTimerSafe(playerid, P_ACA_M1_SELTMR);
    SetPVarInt(playerid, P_ACA_M1_SELTMR, SetTimerEx("AcaM1_KeepSelectTick", 500, true, "i", playerid));

    return 1;
}

stock AcaM1_CloseTXD(playerid)
{
    if(GetPVarInt(playerid, P_ACA_M1_TXDOPEN) != 1) return 0;

    SetPVarInt(playerid, P_ACA_M1_TXDOPEN, 0);
    DeletePVar(playerid, P_ACA_M1_DBGSEL);
    AcaM1_KillTimerSafe(playerid, P_ACA_M1_SELTMR);

    if(GetPVarType(playerid, P_ACA_M1_PREVOPEN) != 0)
    {
        MissoesNormalOpen[playerid] = GetPVarInt(playerid, P_ACA_M1_PREVOPEN);
        DeletePVar(playerid, P_ACA_M1_PREVOPEN);
    }
    else
    {
        MissoesNormalOpen[playerid] = 1;
    }

    TextDrawHideForPlayer(playerid, MissoesBKG[0]);
    
    // Limpa os textdraws da tela E da memoria, para nao deixar residuos para outros sistemas
    MissoesNew_UIDestroy(playerid);
    
    CancelSelectTextDraw(playerid);
    BarrasNarutoOn(playerid);

#if defined Audio_Play
    Audio_Play(playerid, 58);
#endif
    return 1;
}

stock AcaM1_Spawn(playerid)
{
    if(AcaM1_IsDone(playerid)) return 0;

    new stage = GetPVarInt(playerid, P_ACA_M1_STAGE);
    if(stage == 0)
    {
        AcaM1_SetVilaByNearestEntrance(playerid);
        SetPVarInt(playerid, P_ACA_M1_STAGE, 1);
        SetTimerEx("AcaM1_SendIntro", 1200, false, "i", playerid);
        AcaM1_KillTimerSafe(playerid, P_ACA_M1_TMR);
        new t = SetTimerEx("AcaM1_TickProximidade", 750, true, "i", playerid);
        SetPVarInt(playerid, P_ACA_M1_TMR, t);
    }
    return 1;
}

forward AcaM1_SendIntro(playerid);
public AcaM1_SendIntro(playerid)
{
    if(!IsPlayerConnected(playerid) || IsPlayerNPC(playerid)) return 1;
    if(AcaM1_IsDone(playerid)) return 1;
    if(GetPVarInt(playerid, P_ACA_M1_STAGE) < 1) return 1;

    SendClientMessage(playerid, -1, "{AB7C4E}(ACADEMIA) {FFFFFF}Sua primeira missao e concluir a {AB7C4E}Academia Ninja{FFFFFF} da sua vila.");
    SendClientMessage(playerid, -1, "{AB7C4E}(ACADEMIA) {FFFFFF}Va ate a academia, aproxime-se do {AB7C4E}instrutor{FFFFFF} e pressione {AB7C4E}R{FFFFFF} (ou use /instrutor)." );
    return 1;
}

public AcaM1_TickProximidade(playerid)
{
    if(!IsPlayerConnected(playerid)) return 0;
    if(AcaM1_IsDone(playerid)) { AcaM1_KillTimerSafe(playerid, P_ACA_M1_TMR); return 0; }

    new stage = GetPVarInt(playerid, P_ACA_M1_STAGE);
    if(stage != 1) { AcaM1_KillTimerSafe(playerid, P_ACA_M1_TMR); return 0; }

    new vila = AcaM1_GetVila(playerid);
    if(vila == ACA_M1_VILA_KIRI)
    {
        if(IsPlayerInRangeOfPoint(playerid, ACA_M1_ENTRADA_RADIUS, ACA_M1_ENT_KIRI_X, ACA_M1_ENT_KIRI_Y, ACA_M1_ENT_KIRI_Z))
        {
            SetPVarInt(playerid, P_ACA_M1_STAGE, 2);
            SendClientMessage(playerid, -1, "{AB7C4E}(ACADEMIA) {FFFFFF}Seja bem-vindo a {AB7C4E}Academia Ninja{FFFFFF}! Fale com o {AB7C4E}Shinobi Instrutor{FFFFFF}.");
            SendClientMessage(playerid, -1, "{AB7C4E}(ACADEMIA) {FFFFFF}Aproxime-se do instrutor e use {AB7C4E}R{FFFFFF}.");
            AcaM1_KillTimerSafe(playerid, P_ACA_M1_TMR);
        }
    }
    else
    {
        if(IsPlayerInRangeOfPoint(playerid, ACA_M1_ENTRADA_RADIUS, ACA_M1_ENT_IWA_X, ACA_M1_ENT_IWA_Y, ACA_M1_ENT_IWA_Z))
        {
            SetPVarInt(playerid, P_ACA_M1_STAGE, 2);
            SendClientMessage(playerid, -1, "{AB7C4E}(ACADEMIA) {FFFFFF}Seja bem-vindo a {AB7C4E}Academia Ninja{FFFFFF}! Fale com o {AB7C4E}Shinobi Instrutor{FFFFFF}.");
            SendClientMessage(playerid, -1, "{AB7C4E}(ACADEMIA) {FFFFFF}Aproxime-se do instrutor e use {AB7C4E}R{FFFFFF}.");
            AcaM1_KillTimerSafe(playerid, P_ACA_M1_TMR);
        }
    }
    return 1;
}

#if defined _zcmd_included
CMD:instrutor(playerid)
{
    if(AcaM1_IsDone(playerid)) return SendClientMessage(playerid, -1, "{AB7C4E}(ACADEMIA) {FFFFFF}Voce ja concluiu a academia.");

    if(GetPVarInt(playerid, P_ACA_M1_STAGE) < 2)
    {
        if(AcaM1_IsNearInstructor(playerid))
            SetPVarInt(playerid, P_ACA_M1_STAGE, 2);
        else
            return SendClientMessage(playerid, -1, "{AB7C4E}(ACADEMIA) {FFFFFF}Va ate a {AB7C4E}academia ninja{FFFFFF} primeiro.");
    }

    if(!AcaM1_IsNearInstructor(playerid))
        return SendClientMessage(playerid, -1, "{AB7C4E}(ACADEMIA) {FFFFFF}Chegue mais perto do {AB7C4E}instrutor{FFFFFF}.");

    if(GetPVarInt(playerid, P_ACA_M1_TXDOPEN) == 1)
    {
        AcaM1_CloseTXD(playerid);
        return 1;
    }

    AcaM1_TryOpenFromKey(playerid);
    return 1;
}
#endif

forward AcaM1_ClickHandler(playerid, PlayerText:playertextid);
public AcaM1_ClickHandler(playerid, PlayerText:playertextid)
{
    return AcaM1_OnPlayerClickPlayerTextDraw(playerid, playertextid);
}

forward AcaM1_ClickTextHandler(playerid, Text:clickedid);
public AcaM1_ClickTextHandler(playerid, Text:clickedid)
{
    return AcaM1_OnPlayerClickTextDraw(playerid, clickedid);
}

stock AcaM1_ClickPTD(playerid, PlayerText:playertextid)
{
    if(GetPVarInt(playerid, P_ACA_M1_TXDOPEN) != 1) return 0;

    if(playertextid == MissoesNew[playerid][6]) // Recusar
    {
        AcaM1_CloseTXD(playerid);
        SendClientMessage(playerid, -1, "{FF4040}(ACADEMIA) {FFFFFF}Voce recusou. Para liberar o quadro de missoes, conclua a primeira missao na academia.");
        return 1;
    }
    if(playertextid == MissoesNew[playerid][7]) // Aceitar
    {
        AcaM1_CloseTXD(playerid);
        SendClientMessage(playerid, -1, "{AB7C4E}(ACADEMIA) {FFFFFF}Missao aceita. Preste atencao no instrutor.");
        AcaM1_StartTutorial(playerid);
        return 1;
    }
    return 0;
}

stock AcaM1_ClickTD(playerid, Text:clickedid)
{
    if(GetPVarInt(playerid, P_ACA_M1_TXDOPEN) != 1) return 0;
    if(clickedid == Text:INVALID_TEXT_DRAW)
    {
        AcaM1_CloseTXD(playerid);
        return 1;
    }
    return 0;
}

static const AcaM1_TutorialText[][] =
{
    "Ah... bem, vejo que voce e novo aqui. Vou comecar pelo basico.",
    "Shinobi sao ninjas e a potencia militar de suas vilas. Ninja feminina: kunoichi.",
    "Um shinobi manipula CHAKRA para criar tecnicas. Desertores sao Nukenin e sao caados.",
    "Chakra e a uniao de energia fisica + energia mental. Ele flui pelo sistema de chakra e tenketsus.",
    "Jutsus sao artes misticas usadas em batalha. Para usar, voce gasta chakra e pode formar selos.",
    "Tres tecnicas basicas: NINJUTSU (tecnicas ninjas), GENJUTSU (ilusoes), TAIJUTSU (corpo a corpo).",
    "Alm de jutsus, usamos ferramentas ninjas: armas de arremesso, itens e equipamentos.",
    "No SHRP, sua vila define misses, economia e hierarquia. Respeite sua vila e seu RP.",
    "Pronto. Agora vamos para a prova. Responda com atencao."
};

stock AcaM1_StartTutorial(playerid)
{
    SetPVarInt(playerid, P_ACA_M1_STAGE, 3);
    SetPVarInt(playerid, P_ACA_M1_TUTSTEP, 0);
    TogglePlayerControllable(playerid, 0);

    AcaM1_KillTimerSafe(playerid, P_ACA_M1_TUTTMR);
    new t = SetTimerEx("AcaM1_TickTutorial", 4200, true, "i", playerid);
    SetPVarInt(playerid, P_ACA_M1_TUTTMR, t);

    SendClientMessage(playerid, -1, "{AB7C4E}(INSTRUTOR) {FFFFFF}Ah... bem, vejo que voce e novo aqui. Vou comecar pelo basico.");
    SetPVarInt(playerid, P_ACA_M1_TUTSTEP, 1);
    return 1;
}

public AcaM1_TickTutorial(playerid)
{
    if(!IsPlayerConnected(playerid)) return 0;

    new step = GetPVarInt(playerid, P_ACA_M1_TUTSTEP);
    if(step < 0) step = 0;

    if(step >= sizeof(AcaM1_TutorialText))
    {
        AcaM1_KillTimerSafe(playerid, P_ACA_M1_TUTTMR);
        TogglePlayerControllable(playerid, 1);
        AcaM1_StartQuiz(playerid);
        return 1;
    }

    new msg[196];
    format(msg, sizeof(msg), "{AB7C4E}(INSTRUTOR) {FFFFFF}%s", AcaM1_TutorialText[step]);
    SendClientMessage(playerid, -1, msg);

    SetPVarInt(playerid, P_ACA_M1_TUTSTEP, step + 1);
    return 1;
}

stock AcaM1_SayQ(playerid, qnum, qtext[])
{
    new msg[220];
    format(msg, sizeof(msg), "{AB7C4E}(PROVA %d/5) {FFFFFF}%s", qnum, qtext);
    SendClientMessage(playerid, -1, msg);
    return 1;
}

stock AcaM1_ShowQ1(playerid)
{
    AcaM1_SayQ(playerid, 1, "O que e um Shinobi e Kunoichi?");
    ShowPlayerDialog(playerid, DIALOG_ACA_M1_Q1, DIALOG_STYLE_LIST,
        "{FFFFFF}Prova da Academia",
        "Um estilo de tecnica utilizado para artes marciais.\nSao ninjas; shinobi e masculino e kunoichi e feminino.\nUma profissao que serve para organizar ninjas.\nAmbos sao ferramentas ninjas.",
        "Responder", "Fechar"
    );
    return 1;
}

stock AcaM1_ShowQ2(playerid)
{
    AcaM1_SayQ(playerid, 2, "Como funciona a estrutura shinobi?");
    ShowPlayerDialog(playerid, DIALOG_ACA_M1_Q2, DIALOG_STYLE_LIST,
        "{FFFFFF}Prova da Academia",
        "Ronin, Nukenin, Sennin, Kage.\nGenin, Chunin, Jounin, Kage.\nPenin, Chunin, Jounin, Sennin.\nGenin, Chunin, Warnin, Nukenin.",
        "Responder", "Fechar"
    );
    return 1;
}

stock AcaM1_ShowQ3(playerid)
{
    AcaM1_SayQ(playerid, 3, "O que e um Jutsu?");
    ShowPlayerDialog(playerid, DIALOG_ACA_M1_Q3, DIALOG_STYLE_LIST,
        "{FFFFFF}Prova da Academia",
        "Ferramentas ninjas.\nEsquadrao Especial de Assassinato e Tatica.\nArtes misticas que um ninja utiliza na batalha.\nTerritorios do mundo shinobi.",
        "Responder", "Fechar"
    );
    return 1;
}

stock AcaM1_ShowQ4(playerid)
{
    AcaM1_SayQ(playerid, 4, "Quais sao as duas grandes vilas do Shinobi Roleplai?");
    ShowPlayerDialog(playerid, DIALOG_ACA_M1_Q4, DIALOG_STYLE_LIST,
        "{FFFFFF}Prova da Academia",
        "Vila da Nevoa e Vila da Pedra.\nVila da Folha e Vila da Grama.\nVila do Fogo e Vila da Areia.\nVila do Som e Vila da Folha.",
        "Responder", "Fechar"
    );
    return 1;
}

stock AcaM1_ShowQ5(playerid)
{
    AcaM1_SayQ(playerid, 5, "Cite as tres tecnicas basicas utilizadas nos jutsus.");
    ShowPlayerDialog(playerid, DIALOG_ACA_M1_Q5, DIALOG_STYLE_LIST,
        "{FFFFFF}Prova da Academia",
        "Taijutsu, Tenjutsu e Gonkjutsu.\nTaijutsu, Ninjutsu e Futonjutsu.\nSaijutsu, Ninjutsu e Genjutsu.\nTaijutsu, Genjutsu e Ninjutsu.",
        "Responder", "Fechar"
    );
    return 1;
}

stock AcaM1_StartQuiz(playerid)
{
    SetPVarInt(playerid, P_ACA_M1_STAGE, 3);
    AcaM1_ShowQ1(playerid);
    return 1;
}

stock AcaM1_Finish(playerid)
{
    SetPVarInt(playerid, P_ACA_M1_DONE, 1);
    SetPVarInt(playerid, P_ACA_M1_STAGE, 10);

    SendClientMessage(playerid, -1, "{AB7C4E}(ACADEMIA) {FFFFFF}Parabens! Voce passou na prova da academia.");
    SendClientMessage(playerid, -1, "{AB7C4E}(ACADEMIA) {FFFFFF}Agora vamos ver de que cl voc .");

#if defined RyoseXPTxd
    RyoseXPTxd(playerid, ACA_M1_REWARD_XP, ACA_M1_REWARD_RYOUS);
#endif
#if defined GivePlayerCash
    GivePlayerCash(playerid, ACA_M1_REWARD_RYOUS);
#endif
#if defined GivePlayerExperiencia
    GivePlayerExperiencia(playerid, ACA_M1_REWARD_XP);
#endif

    // Gancho
    EscolhaCla(playerid);
#if defined Academia_OnGraduated
    Academia_OnGraduated(playerid);
#endif

    return 1;
}

stock AcaM1_DialogResp(playerid, dialogid, response, listitem, inputtext[])
{
    if(AcaM1_IsDone(playerid)) return 0;

    switch(dialogid)
    {
        case DIALOG_ACA_M1_START:
        {
            if(!response) return 1;

            if(listitem == 0) // tutorial
            {
                AcaM1_StartTutorial(playerid);
            }
            else // pular -> prova
            {
                TogglePlayerControllable(playerid, 1);
                AcaM1_StartQuiz(playerid);
            }
            return 1;
        }
        case DIALOG_ACA_M1_Q1:
        {
            if(!response) return 1;
            if(listitem == 1) AcaM1_ShowQ2(playerid);
            else { SendClientMessage(playerid, -1, "{FF4040}(ACADEMIA) Resposta incorreta. Tente novamente."); AcaM1_ShowQ1(playerid); }
            return 1;
        }
        case DIALOG_ACA_M1_Q2:
        {
            if(!response) return 1;
            if(listitem == 1) AcaM1_ShowQ3(playerid);
            else { SendClientMessage(playerid, -1, "{FF4040}(ACADEMIA) Resposta incorreta. Tente novamente."); AcaM1_ShowQ2(playerid); }
            return 1;
        }
        case DIALOG_ACA_M1_Q3:
        {
            if(!response) return 1;
            if(listitem == 2) AcaM1_ShowQ4(playerid);
            else { SendClientMessage(playerid, -1, "{FF4040}(ACADEMIA) Resposta incorreta. Tente novamente."); AcaM1_ShowQ3(playerid); }
            return 1;
        }
        case DIALOG_ACA_M1_Q4:
        {
            if(!response) return 1;
            if(listitem == 0) AcaM1_ShowQ5(playerid);
            else { SendClientMessage(playerid, -1, "{FF4040}(ACADEMIA) Resposta incorreta. Tente novamente."); AcaM1_ShowQ4(playerid); }
            return 1;
        }
        case DIALOG_ACA_M1_Q5:
        {
            if(!response) return 1;
            if(listitem == 3) AcaM1_Finish(playerid);
            else { SendClientMessage(playerid, -1, "{FF4040}(ACADEMIA) Resposta incorreta. Tente novamente."); AcaM1_ShowQ5(playerid); }
            return 1;
        }
    }
    return 0;
}

stock AcaM1_OnPlayerDisconnect(playerid)
{
    AcaM1_KillTimerSafe(playerid, P_ACA_M1_TMR);
    AcaM1_KillTimerSafe(playerid, P_ACA_M1_TUTTMR);
    
    // Nao precisamos limpar MissoesNew aqui pois shrp_missoes_txd.pwn ja deve ter um hook para isso
    // mas se quiser garantir: MissoesNew_UIDestroy(playerid);
    return 1;
}