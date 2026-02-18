#if defined _SHRP_DAILY_TXD_INCLUDED
#endinput
#endif
#define _SHRP_DAILY_TXD_INCLUDED

// ================================================================
// SHRP - Quadro de Missoes Diarias (Rank + TXD)
// Arquivo: diarias_rank_txd.pwn
//
// Como integrar (patch rapido):
//  1) Coloque diarias_rank_cfg.pwn e diarias_rank_txd.pwn na pasta:
//     Includes/Missoes/
//  2) No seu SHRP.pwn (ou include central), inclua:
//     #include "Includes/Missoes/diarias_rank_txd.pwn"
//  3) Adicione nos callbacks do gamemode:
//
//     public OnGameModeInit()
//     {
//         ...
//         Daily_Init();
//         ...
//     }
//
//     public OnPlayerConnect(playerid)
//     {
//         ...
//         Daily_OnConnect(playerid);
//         ...
//     }
//
//     public OnPlayerDisconnect(playerid, reason)
//     {
//         Daily_OnDisconnect(playerid, reason);
//         ...
//     }
//
//     public OnPlayerDeath(playerid, killerid, reason)
//     {
//         Daily_OnDeath(playerid, killerid, reason);
//         ...
//     }
//
//     public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
//     {
//         Daily_OnKey(playerid, newkeys, oldkeys);
//         ...
//     }
//
//     public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
//     {
//         if(Daily_OnDialogResponse(playerid, dialogid, response, listitem, inputtext)) return 1;
//         ...
//     }
//
//     public OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
//     {
//         if(Daily_OnClickPTD(playerid, playertextid)) return 1;
//         ...
//     }
//
//     public OnPlayerGiveDamageActor(playerid, damaged_actorid, Float:amount, weaponid, bodypart)
//     {
//         Daily_OnGiveDmgAct(playerid, damaged_actorid, amount, weaponid, bodypart);
//         ...
//         return 1;
//     }
//
// Opcional:
//  - No seu /missao (status), chame: Daily_ShowStatus(playerid);
//
// ================================================================

#include <a_samp>
#include <dof2>

#if !defined _streamer_included
#include <streamer>
#endif

#include "diarias_rank_cfg.pwn"

// ------------------------------------------------
// Controle visual dos provedores (fallback)
// Se nao estiver definido no diarias_rank_cfg.pwn, assume DESLIGADO (nao cria pickup/3dtext/obj).
// ------------------------------------------------
#if !defined DAILY_PROVIDER_SPAWN_OBJECT
    #define DAILY_PROVIDER_SPAWN_OBJECT (0)
#endif
#if !defined DAILY_PROVIDER_SPAWN_PICKUP
    #define DAILY_PROVIDER_SPAWN_PICKUP (0)
#endif
#if !defined DAILY_PROVIDER_SPAWN_3DTEXT
    #define DAILY_PROVIDER_SPAWN_3DTEXT (0)
#endif


// ------------------------------------------------
// Rank masks (fallback)
// Some codebases define these globally. If your SHRP does not, we define safe defaults here.
// Bit positions: E=0, D=1, C=2, B=3, A=4, S=5.
#if !defined RANKMASK_E
#define RANKMASK_E   (1<<0)
#endif
#if !defined RANKMASK_D
#define RANKMASK_D   (1<<1)
#endif
#if !defined RANKMASK_C
#define RANKMASK_C   (1<<2)
#endif
#if !defined RANKMASK_B
#define RANKMASK_B   (1<<3)
#endif
#if !defined RANKMASK_A
#define RANKMASK_A   (1<<4)
#endif
#if !defined RANKMASK_S
#define RANKMASK_S   (1<<5)
#endif
// ------------------------------------------------


// ------------------------------
// Fallbacks (cores / helpers)
// ------------------------------
#if !defined COLOR_WHITE
#define COLOR_WHITE 0xFFFFFFFF
#endif
#if !defined COLOR_RED
#define COLOR_RED 0xFF3030FF
#endif
#if !defined COLOR_GREEN
#define COLOR_GREEN 0x33FF33FF
#endif
#if !defined COLOR_YELLOW
#define COLOR_YELLOW 0xFFFF00FF
#endif
#if !defined SendClientMessageEx
    stock SendClientMessageEx(playerid, color, const msg[]) { return SendClientMessage(playerid, color, msg); }
#endif

// ------------------------------
// Integracao segura com funcoes do SHRP
// (evita "function heading differs from prototype")
// ------------------------------
stock Daily_AcaIsDone(playerid)
{
    // Regra principal (como você pediu): só libera o Quadro após concluir a missao 1 da Academia e receber um cla.
    if(Info[playerid][pClan] != 0) return 1;

    // Se existir uma checagem específica da Academia, usamos ela.
#if defined AcaM1_IsDone
        return AcaM1_IsDone(playerid);
#else
        return 0;
#endif
}


stock Daily_GiveCash(playerid, amount)
{
    if(amount <= 0) return 1;
    if(funcidx("GivePlayerCash") != -1) return CallLocalFunction("GivePlayerCash", "ii", playerid, amount);
    return GivePlayerMoney(playerid, amount);
}

stock Daily_GiveXP(playerid, amount)
{
    if(amount <= 0) return 1;
    if(funcidx("GivePlayerExperiencia") != -1) return CallLocalFunction("GivePlayerExperiencia", "ii", playerid, amount);
    return 1;
}

stock Daily_RewardTxd(playerid, xp, ry)
{
    if(funcidx("RyoseXPTxd") != -1) return CallLocalFunction("RyoseXPTxd", "iii", playerid, xp, ry);
    return 1;
}

stock Daily_AddFama(playerid, amount)
{
    if(amount <= 0) return 1;

    // IMPORTANTE:
    //  - No teu sistema (fama.pwn), Fama_AddNinja é stock com 3º parâmetro opcional (motivo).
    //  - CallLocalFunction/funcidx não enxerga stock -> por isso tentamos chamar direto quando existir.
    //  - Garanta que #include "fama.pwn" venha ANTES deste include, ou o bloco abaixo cai no fallback.
#if defined Fama_AddNinja
        return Fama_AddNinja(playerid, amount, "");
#else
        // fallback (caso exista uma versão public em outro módulo)
        if(funcidx("Fama_AddNinja") != -1) return CallLocalFunction("Fama_AddNinja", "iis", playerid, amount, "");
        return 1;
#endif
}

stock Daily_AddOpiniao(playerid, amount)
{
    if(amount <= 0) return 1;
    if(funcidx("Fama_AddOpiniao") != -1) return CallLocalFunction("Fama_AddOpiniao", "ii", playerid, amount);
    return 1;
}

stock Daily_FamaSave(playerid)
{
    // Salva a fama/opinião depois de recompensar a diaria.
    // No teu projeto isso vem do include fama.pwn (Fama_Save).
#if defined Fama_Save
        return Fama_Save(playerid);
#else
        // Se der undefined aqui, inclua fama.pwn ANTES deste include.
        return 1;
#endif
}




// HUD ON (seguro): chama BarrasNarutoOn se existir no gamemode.
stock Daily_HudOn(playerid)
{
    if(funcidx("BarrasNarutoOn") != -1) return CallLocalFunction("BarrasNarutoOn", "i", playerid);
    return 1;
}

#define PTD_INVALID (PlayerText:0xFFFF)

// ------------------------------
// Internos
// ------------------------------
#define DAILY_FILE_PREFIX "daily_"
#define DAILY_LOG_FILE    "daily_missoes.log"

#define DAILY_TICK_MS     (1000)

#define DAILY_CP_RADIUS   (3.0)
#define DAILY_NEAR_PROV   (2.6)

// Escolta
#define DAILY_ESCORT_OK_DIST_E   (18.0)
#define DAILY_ESCORT_OK_DIST_D   (16.0)
#define DAILY_ESCORT_OK_DIST_C   (14.0)
#define DAILY_ESCORT_OK_DIST_B   (12.0)
#define DAILY_ESCORT_OK_DIST_A   (11.0)
#define DAILY_ESCORT_OK_DIST_S   (9.5)

#define DAILY_ESCORT_GRACE_SEC   (8) // tempo tolerado afastado

// NPC
#define DAILY_NPC_MAX (24)
#define DAILY_ACT_MAX (1000)

// Suspeita
#define DSUS_TELEPORT (1)
#define DSUS_FASTDONE (2)

// UI
#define DAILY_PTD_MAX (32)
#define DUI_NONE (0)
#define DUI_LIST (1)
#define DUI_OFFER (2)

// UI indices
#define PTD_TITLE   (0)
#define PTD_SUB     (1)
#define PTD_BTN_BG  (2) // close/back bg
#define PTD_BTN_TX  (3) // close/back text

#define PTD_O_TITLE (4)
#define PTD_O_DESC  (5)
#define PTD_O_REW   (6)
#define PTD_O_ACC_BG (7)
#define PTD_O_ACC_TX (8)
#define PTD_O_DEC_BG (9)
#define PTD_O_DEC_TX (10)

// rank rows: 6 ranks, each uses 3 PTDs: bg, label, info
#define PTD_R_BASE  (11)
#define PTD_R_BG(%0)   (PTD_R_BASE + ((%0) * 3) + 0)
#define PTD_R_TX(%0)   (PTD_R_BASE + ((%0) * 3) + 1)
#define PTD_R_INF(%0)  (PTD_R_BASE + ((%0) * 3) + 2)


// OFFER UI (layout igual à missao da Academia / MSS:Int1)
#define DAILY_OFFER_PTD_MAX (8)
#define DOF_TITLE   (0)
#define DOF_DESC    (1)
#define DOF_RYOS    (2)
#define DOF_XP      (3)
#define DOF_FAMA    (4)
#define DOF_OP      (5)
#define DOF_RECUSAR (6)
#define DOF_ACEITAR (7)

// ------------------------------
// Estado por player
// ------------------------------
enum eDailyP
{
    dLoaded,
    dDayKey,
    dUI,
    dProvIdx,
    dOfferRank,
    dOfferMid,

    dActive,
    dRank,
    dMid,
    dStep,

    dStartTime,
    dHold,
    dHoldNeed,
    Float:dOrgX,
    Float:dOrgY,
    Float:dOrgZ,
    Float:dScale,

    Float:dTgtX,
    Float:dTgtY,
    Float:dTgtZ,

    Float:dLastX,
    Float:dLastY,
    Float:dLastZ,
    Float:dTravel,

    dNeed,
    dCount,
    dSusFlags,
    dEscortAway,

    dDoneE, dDoneD, dDoneC, dDoneB, dDoneA, dDoneS,
    dCdE, dCdD, dCdC, dCdB, dCdA, dCdS,

    dForceUnlock // debug: libera ranks ate este (0..5), -1 desliga
};
new DailyP[MAX_PLAYERS][eDailyP];

// ==========================================================
// RANK DIALOG (Quadro de Missoes) — abre primeiro (sem TXD)
// Depois que o player escolhe o Rank, aí sim abre o TXD com a missao.
// Ajuste o ID se você ja usa um dialogid nessa faixa.
#if !defined DIALOG_DAILY_RANK
#define DIALOG_DAILY_RANK (28901)
#endif

new DailyDlgRankMap[MAX_PLAYERS][DR_MAX];
new DailyDlgRankCount[MAX_PLAYERS];



// Missao runtime (recursos)
new DailyNpcCnt[MAX_PLAYERS];
new DailyNpcId[MAX_PLAYERS][DAILY_NPC_MAX];
new DailyEscortObj[MAX_PLAYERS];
new DailyHostageAct[MAX_PLAYERS];

// Mapeamento por ActorID
new DailyActOwner[DAILY_ACT_MAX];
new DailyActMid[DAILY_ACT_MAX];
new DailyActAlive[DAILY_ACT_MAX];
// ------------------------------------------------
// PVE via NPCs de combate (FCNPC/Shinobi AI)
// - Para DMT_PVE funcionar com Taijutsu (melee), usamos NPCs do shinobi_ai (combat NPC),
//   porque Actors (CreateActor) nao recebem hits do seu sistema de combate.
// - Marcamos os NPCs de combate por "AI slot" e contamos kills via callback vindo do shinobi_ai.
// ------------------------------------------------
#if !defined MAXIMO_NPCS_COMBATE
    #define MAXIMO_NPCS_COMBATE (80) // fallback (shinobi_ai usa 80 por padrao)
#endif

#if !defined NPCT_HOSTILE
    #define NPCT_HOSTILE (1)
#endif

#define DAILY_NPC_TAG_AISLOT (10000) // encode: DAILY_NPC_TAG_AISLOT + aislot

new DailyAiOwner[MAXIMO_NPCS_COMBATE];
new DailyAiMid[MAXIMO_NPCS_COMBATE];
new bool:DailyAiAlive[MAXIMO_NPCS_COMBATE];
new DailyPveFixTmr[MAX_PLAYERS] = { -1, ... };
new Float:DailyAiMinZ[MAXIMO_NPCS_COMBATE];
new DailyAiFixUntilTick[MAXIMO_NPCS_COMBATE];


// ------------------------------------------------
// FIX: Missão Rank E - "Treino: Derrubar Bonecos"
// Spawn FIXO por vila (Iwagakure/Kirigakure) para não cair na água
// e garantir que os NPCs nasçam no "dojo" certo.
// ------------------------------------------------
static const Float:gDailyBonecos_IWA[3][4] = {
    { -1421.3204, 1700.1259, 25.1198, 198.1017 },
    { -1434.0272, 1655.9135, 25.1198, 359.7896 },
    { -1454.7251, 1673.1787, 25.1198, 272.7861 }
};

static const Float:gDailyBonecos_KIRI[3][4] = {
    { 2445.1335, -2072.9719, 29.7656, 145.8801 },
    { 2367.2542, -2087.3428, 29.7656, 266.2049 },
    { 2356.1934, -2170.3472, 29.2836, 294.1546 }
};

stock bool:Daily_IsBonecosMission(mid)
{
    if(mid < 0 || mid >= sizeof(gDailyMissions)) return false;
    if(gDailyMissions[mid][dmType] != DMT_PVE) return false;
    return (!strcmp(gDailyMissions[mid][dmName], "Treino: Derrubar Bonecos", true));
}


// UI PTDs
new Text:gDailyBkg = Text:INVALID_TEXT_DRAW;
new PlayerText:gDailyPTD[MAX_PLAYERS][DAILY_PTD_MAX];
new PlayerText:gDailyOfferPTD[MAX_PLAYERS][DAILY_OFFER_PTD_MAX];

// Providers (obj/pickup/3dtext)
new DailyProvObj[sizeof(gDailyProvPos)];
new DailyProvPickup[sizeof(gDailyProvPos)];
new Text3D:DailyProvLabel[sizeof(gDailyProvPos)];

// Timer
new DailyTickTimer = -1;

// ------------------------------
// Util
// ------------------------------
stock Daily_GetDayKey()
{
    // Day key (timezone) = inteiro que muda a cada 24h no fuso desejado
    return ((gettime() + DAILY_TZ_OFFSET_SEC) / 86400);
}

stock Daily_RankName(rank, out[], outLen)
{
    switch(rank)
    {
        case DR_E: format(out, outLen, "E");
        case DR_D: format(out, outLen, "D");
        case DR_C: format(out, outLen, "C");
        case DR_B: format(out, outLen, "B");
        case DR_A: format(out, outLen, "A");
        case DR_S: format(out, outLen, "S");
        default: format(out, outLen, "?");
    }
    return 1;
}

stock Daily_ProvMaskByType(pType)
{
    switch(pType)
    {
        case DP_BOARD:  return DAILY_PROVIDER_MASK_BOARD;
        case DP_SENSEI: return DAILY_PROVIDER_MASK_SENSEI;
        case DP_KAGE:   return DAILY_PROVIDER_MASK_KAGE;
    }
    return 0;
}

stock Daily_IsAdmin(playerid)
{
    // Compativel com seu padrao (/menuhpadm): RCON ou adminZC
    if(IsPlayerAdmin(playerid)) return 1;
#if defined pAdminZC
        if(Info[playerid][pAdminZC] > 0) return 1;
#endif
    return 0;
}

stock Daily_GetDone(playerid, rank)
{
    switch(rank)
    {
        case DR_E: return DailyP[playerid][dDoneE];
        case DR_D: return DailyP[playerid][dDoneD];
        case DR_C: return DailyP[playerid][dDoneC];
        case DR_B: return DailyP[playerid][dDoneB];
        case DR_A: return DailyP[playerid][dDoneA];
        case DR_S: return DailyP[playerid][dDoneS];
    }
    return 0;
}

stock Daily_SetDone(playerid, rank, val)
{
    switch(rank)
    {
        case DR_E: DailyP[playerid][dDoneE] = val;
        case DR_D: DailyP[playerid][dDoneD] = val;
        case DR_C: DailyP[playerid][dDoneC] = val;
        case DR_B: DailyP[playerid][dDoneB] = val;
        case DR_A: DailyP[playerid][dDoneA] = val;
        case DR_S: DailyP[playerid][dDoneS] = val;
    }
    return 1;
}

stock Daily_GetCd(playerid, rank)
{
    switch(rank)
    {
        case DR_E: return DailyP[playerid][dCdE];
        case DR_D: return DailyP[playerid][dCdD];
        case DR_C: return DailyP[playerid][dCdC];
        case DR_B: return DailyP[playerid][dCdB];
        case DR_A: return DailyP[playerid][dCdA];
        case DR_S: return DailyP[playerid][dCdS];
    }
    return 0;
}

stock Daily_SetCd(playerid, rank, val)
{
    switch(rank)
    {
        case DR_E: DailyP[playerid][dCdE] = val;
        case DR_D: DailyP[playerid][dCdD] = val;
        case DR_C: DailyP[playerid][dCdC] = val;
        case DR_B: DailyP[playerid][dCdB] = val;
        case DR_A: DailyP[playerid][dCdA] = val;
        case DR_S: DailyP[playerid][dCdS] = val;
    }
    return 1;
}

stock Float:Daily_EscortMaxDist(rank)
{
    switch(rank)
    {
        case DR_E: return DAILY_ESCORT_OK_DIST_E;
        case DR_D: return DAILY_ESCORT_OK_DIST_D;
        case DR_C: return DAILY_ESCORT_OK_DIST_C;
        case DR_B: return DAILY_ESCORT_OK_DIST_B;
        case DR_A: return DAILY_ESCORT_OK_DIST_A;
        case DR_S: return DAILY_ESCORT_OK_DIST_S;
    }
    return 14.0;
}

stock Daily_FilePath(playerid, out[], outLen)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    // remove spaces
    for(new i=0; name[i]; i++) if(name[i] == ' ') name[i] = '_';
    format(out, outLen, "%s%s.ini", DAILY_FILE_PREFIX, name);
    return 1;
}

stock Daily_Log(const line[])
{
    new File:f = fopen(DAILY_LOG_FILE, io_append);
    if(!f) return 0;
    fwrite(f, line);
    fwrite(f, "\r\n");
    fclose(f);
    return 1;
}


// ------------------------------
// Persistencia (DOF2)
// ------------------------------
stock Daily_Save(playerid)
{
    if(!DailyP[playerid][dLoaded]) return 0;

    new file[64];
    Daily_FilePath(playerid, file, sizeof(file));

    DOF2_SetInt(file, "DayKey", DailyP[playerid][dDayKey]);

    DOF2_SetInt(file, "DoneE", DailyP[playerid][dDoneE]);
    DOF2_SetInt(file, "DoneD", DailyP[playerid][dDoneD]);
    DOF2_SetInt(file, "DoneC", DailyP[playerid][dDoneC]);
    DOF2_SetInt(file, "DoneB", DailyP[playerid][dDoneB]);
    DOF2_SetInt(file, "DoneA", DailyP[playerid][dDoneA]);
    DOF2_SetInt(file, "DoneS", DailyP[playerid][dDoneS]);

    DOF2_SetInt(file, "CdE", DailyP[playerid][dCdE]);
    DOF2_SetInt(file, "CdD", DailyP[playerid][dCdD]);
    DOF2_SetInt(file, "CdC", DailyP[playerid][dCdC]);
    DOF2_SetInt(file, "CdB", DailyP[playerid][dCdB]);
    DOF2_SetInt(file, "CdA", DailyP[playerid][dCdA]);
    DOF2_SetInt(file, "CdS", DailyP[playerid][dCdS]);

    DOF2_SaveFile();
    return 1;
}

stock Daily_ResetCounters(playerid)
{
    DailyP[playerid][dDoneE] = 0;
    DailyP[playerid][dDoneD] = 0;
    DailyP[playerid][dDoneC] = 0;
    DailyP[playerid][dDoneB] = 0;
    DailyP[playerid][dDoneA] = 0;
    DailyP[playerid][dDoneS] = 0;

    DailyP[playerid][dCdE] = 0;
    DailyP[playerid][dCdD] = 0;
    DailyP[playerid][dCdC] = 0;
    DailyP[playerid][dCdB] = 0;
    DailyP[playerid][dCdA] = 0;
    DailyP[playerid][dCdS] = 0;
    return 1;
}

stock Daily_Load(playerid)
{
    new file[64];
    Daily_FilePath(playerid, file, sizeof(file));

    DailyP[playerid][dLoaded] = 1;

    if(DOF2_FileExists(file))
    {
        DailyP[playerid][dDayKey] = DOF2_GetInt(file, "DayKey");

        DailyP[playerid][dDoneE] = DOF2_GetInt(file, "DoneE");
        DailyP[playerid][dDoneD] = DOF2_GetInt(file, "DoneD");
        DailyP[playerid][dDoneC] = DOF2_GetInt(file, "DoneC");
        DailyP[playerid][dDoneB] = DOF2_GetInt(file, "DoneB");
        DailyP[playerid][dDoneA] = DOF2_GetInt(file, "DoneA");
        DailyP[playerid][dDoneS] = DOF2_GetInt(file, "DoneS");

        DailyP[playerid][dCdE] = DOF2_GetInt(file, "CdE");
        DailyP[playerid][dCdD] = DOF2_GetInt(file, "CdD");
        DailyP[playerid][dCdC] = DOF2_GetInt(file, "CdC");
        DailyP[playerid][dCdB] = DOF2_GetInt(file, "CdB");
        DailyP[playerid][dCdA] = DOF2_GetInt(file, "CdA");
        DailyP[playerid][dCdS] = DOF2_GetInt(file, "CdS");
    }
    else
    {
        DailyP[playerid][dDayKey] = Daily_GetDayKey();
        Daily_ResetCounters(playerid);
        Daily_Save(playerid);
    }

    // reset diario lazy
    new nowKey = Daily_GetDayKey();
    if(DailyP[playerid][dDayKey] != nowKey)
    {
        DailyP[playerid][dDayKey] = nowKey;
        Daily_ResetCounters(playerid);
        Daily_Save(playerid);
        SendClientMessageEx(playerid, COLOR_YELLOW, "[Missoes] Seu limite diario de missoes foi resetado (00:00).");
    }
    return 1;
}

// ------------------------------
// Providers (Quadro/Sensei/Kage)
// ------------------------------
stock Daily_CreateProviders()
{
    for(new i=0; i<gDailyProvCount; i++)
    {
        new Float:x = gDailyProvPos[i][dpX];
        new Float:y = gDailyProvPos[i][dpY];
        new Float:z = gDailyProvPos[i][dpZ];
        new Float:a = gDailyProvPos[i][dpA];

        // Por padrao, este sistema pode criar OBJ/PICKUP/3DTEXT no local do provedor.
        // Como voce ja tem NPC no ponto do "Aperte R", voce pode desligar tudo no cfg:
        //  DAILY_PROVIDER_SPAWN_OBJECT / PICKUP / 3DTEXT
        DailyProvObj[i] = -1;
        DailyProvPickup[i] = -1;
        DailyProvLabel[i] = Text3D:-1;

        // objeto (visual)
        if(DAILY_PROVIDER_SPAWN_OBJECT)
        {
#if defined _streamer_included
            DailyProvObj[i] = CreateDynamicObject(DAILY_BOARD_OBJ_MODEL, x, y, z-0.8, 0.0, 0.0, a);
#else
            DailyProvObj[i] = CreateObject(DAILY_BOARD_OBJ_MODEL, x, y, z-0.8, 0.0, 0.0, a);
#endif
        }

        // pickup (icone girando) - DESLIGUE se ja existe NPC no local
        if(DAILY_PROVIDER_SPAWN_PICKUP)
        {
#if defined _streamer_included
            DailyProvPickup[i] = CreateDynamicPickup(DAILY_BOARD_PICKUP, 23, x, y, z+0.2, 0, 0, -1, 30.0);
#else
            DailyProvPickup[i] = CreatePickup(DAILY_BOARD_PICKUP, 23, x, y, z+0.2, 0);
#endif
        }

        // 3DText (ex: "Aperte ...") - DESLIGUE se ja existe texto/actor no local
        if(DAILY_PROVIDER_SPAWN_3DTEXT)
        {
            new label[96];
            switch(gDailyProvPos[i][dpType])
            {
                case DP_BOARD:  format(label, sizeof(label), "{FFFFFF}Quadro de Missoes Diarias\n{AAAAAA}Aperte {FFFFFF}R {AAAAAA}perto");
                case DP_SENSEI: format(label, sizeof(label), "{FFFFFF}Sensei: Missoes Diarias\n{AAAAAA}Aperte {FFFFFF}R {AAAAAA}perto");
                case DP_KAGE:   format(label, sizeof(label), "{FFFFFF}Kage: Missoes Diarias\n{AAAAAA}Aperte {FFFFFF}R {AAAAAA}perto");
                default: format(label, sizeof(label), "{FFFFFF}Missoes Diarias\n{AAAAAA}Aperte {FFFFFF}R {AAAAAA}perto");
            }
#if defined _streamer_included
            DailyProvLabel[i] = CreateDynamic3DTextLabel(label, 0xFFFFFFFF, x, y, z+1.1, 18.0, INVALID_PLAYER_ID, INVALID_VEHICLE_ID, 0, 0, 0, -1, 30.0);
#else
            DailyProvLabel[i] = Create3DTextLabel(label, 0xFFFFFFFF, x, y, z+1.1, 18.0, 0, 0);
#endif
        }
    }
    return 1;
}


stock Daily_FindNearProvider(playerid)
{
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

    new best = -1;
    new Float:bestD = 99999.0;

    for(new i=0; i<gDailyProvCount; i++)
    {
        new Float:x = gDailyProvPos[i][dpX];
        new Float:y = gDailyProvPos[i][dpY];
        new Float:z = gDailyProvPos[i][dpZ];

        new Float:d = floatsqroot((px-x)*(px-x) + (py-y)*(py-y) + (pz-z)*(pz-z));
        if(d < DAILY_NEAR_PROV && d < bestD)
        {
            bestD = d;
            best = i;
        }
    }
    return best;
}

// ------------------------------
// UI
// ------------------------------
stock Daily_UIHideAll(playerid)
{
    if(gDailyBkg != Text:INVALID_TEXT_DRAW) TextDrawHideForPlayer(playerid, gDailyBkg);

    for(new i=0; i<DAILY_PTD_MAX; i++)
    {
        if(gDailyPTD[playerid][i] != PTD_INVALID)
            PlayerTextDrawHide(playerid, gDailyPTD[playerid][i]);
    }

    // oferta (layout MSS)
    for(new i=0; i<DAILY_OFFER_PTD_MAX; i++)
    {
        if(gDailyOfferPTD[playerid][i] != PTD_INVALID)
            PlayerTextDrawHide(playerid, gDailyOfferPTD[playerid][i]);
    }

    DailyP[playerid][dUI] = DUI_NONE;
    return 1;
}

stock Daily_UIExit(playerid, bool:backToRankDialog)
{
    // Fecha qualquer UI do sistema de diarias e volta o HUD do SHRP.
    Daily_UIHideAll(playerid);
    CancelSelectTextDraw(playerid);

    // Se o player estiver inconsciente, não “força” o HUD a voltar.
    if(GetPVarInt(playerid, "Inconsciente") < 1)
    {
        Daily_HudOn(playerid);
    }

    if(backToRankDialog)
    {
        // Reabre o Quadro de Missoes (Rank) sem TXD.
        Daily_OpenRankDialog(playerid);
    }
    return 1;
}

stock Daily_OpenRankDialog(playerid)
{
    // Precisa ter um provedor selecionado (setado no Daily_OnKey)
    new prov = DailyP[playerid][dProvIdx];
    if(prov == -1) return 0;

    // Bloqueia antes da academia/cla (como você pediu)
    if(!Daily_AcaIsDone(playerid))
    {
        SendClientMessage(playerid, 0xFFFFFFFF, "[Missoes] Conclua a missao da Academia e escolha seu cla para liberar o Quadro de Missoes.");
        return 0;
    }

    new type = gDailyProvPos[prov][dpType];
    new mask = (type == DP_BOARD) ? (RANKMASK_E | RANKMASK_D) :
               (type == DP_SENSEI) ? (RANKMASK_C | RANKMASK_B) :
               (type == DP_KAGE)   ? (RANKMASK_A | RANKMASK_S) : (RANKMASK_E | RANKMASK_D);

    new list[512];
    list[0] = '\0';
    DailyDlgRankCount[playerid] = 0;

    for(new r = 0; r < DR_MAX; r++)
    {
        if(!(mask & (1 << r))) continue;

        new why[64];
        new ok = Daily_CanTakeRank(playerid, r, why, sizeof(why));
        new rn[2];
        Daily_RankName(r, rn, sizeof(rn));

        new line[128];
        if(ok) format(line, sizeof(line), "Rank %s", rn);
        else   format(line, sizeof(line), "Rank %s (Bloqueado)", rn);

        strcat(list, line);
        strcat(list, "\n");

        DailyDlgRankMap[playerid][DailyDlgRankCount[playerid]++] = r;
    }

    ShowPlayerDialog(playerid, DIALOG_DAILY_RANK, DIALOG_STYLE_LIST, "Quadro de Missoes", list, "Escolher", "Fechar");
    return 1;
}



// ------------------------------
// Helpers (format/wrap para o TXD)
// ------------------------------
stock Daily_FormatDots(value, out[], outLen)
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

stock Daily_WrapText(const src[], dst[], dstLen, maxLine)
{
    new di = 0;
    new lineLen = 0;

    for(new i=0; src[i] != '\0' && di < dstLen-1; )
    {
        // mantém quebras manuais (~n~)
        if(src[i] == '~' && src[i+1] == 'n' && src[i+2] == '~')
        {
            if(di + 3 >= dstLen) break;
            dst[di++] = '~'; dst[di++] = 'n'; dst[di++] = '~';
            i += 3;
            lineLen = 0;
            continue;
        }

        if(src[i] == ' ')
        {
            // mede a próxima palavra para quebrar antes de estourar
            new j = i + 1;
            while(src[j] == ' ') j++;

            new w = 0;
            while(src[j+w] != '\0' && src[j+w] != ' ' && !(src[j+w] == '~' && src[j+w+1] == 'n' && src[j+w+2] == '~')) w++;

            if(lineLen > 0 && (lineLen + 1 + w) > maxLine)
            {
                if(di + 3 >= dstLen) break;
                dst[di++] = '~'; dst[di++] = 'n'; dst[di++] = '~';
                lineLen = 0;
                i++; // pula o espaço atual
                continue;
            }
        }

        dst[di++] = src[i++];
        lineLen++;
    }

    dst[di] = '\0';
    return 1;
}

stock Daily_UIShowList(playerid)
{
    Daily_UIEnsure(playerid);
    if(gDailyBkg != Text:INVALID_TEXT_DRAW) TextDrawShowForPlayer(playerid, gDailyBkg);

    // garante que a oferta (layout MSS) esteja escondida
    for(new i=0; i<DAILY_OFFER_PTD_MAX; i++)
    {
        if(gDailyOfferPTD[playerid][i] != PTD_INVALID)
            PlayerTextDrawHide(playerid, gDailyOfferPTD[playerid][i]);
    }

    // hide offer elements
    PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_O_TITLE]);
    PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_O_DESC]);
    PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_O_REW]);
    PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_O_ACC_BG]);
    PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_O_ACC_TX]);
    PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_O_DEC_BG]);
    PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_O_DEC_TX]);

    // show base
    PlayerTextDrawSetString(playerid, gDailyPTD[playerid][PTD_TITLE], "QUADRO DE MISSOES DIARIAS");
    PlayerTextDrawSetString(playerid, gDailyPTD[playerid][PTD_SUB], "Selecione um rank para receber uma missao. Limites resetam 00:00.");

    PlayerTextDrawShow(playerid, gDailyPTD[playerid][PTD_TITLE]);
    PlayerTextDrawShow(playerid, gDailyPTD[playerid][PTD_SUB]);

    // button = FECHAR
    PlayerTextDrawSetString(playerid, gDailyPTD[playerid][PTD_BTN_TX], "FECHAR");
    PlayerTextDrawShow(playerid, gDailyPTD[playerid][PTD_BTN_BG]);
    PlayerTextDrawShow(playerid, gDailyPTD[playerid][PTD_BTN_TX]);

    // rank rows
    new provIdx = DailyP[playerid][dProvIdx];
    new pType = gDailyProvPos[provIdx][dpType];
    new mask = Daily_ProvMaskByType(pType);

    for(new r=0; r<DR_MAX; r++)
    {
        // show only if provider offers it
        if(!(mask & (1<<r)))
        {
            PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_R_BG(r)]);
            PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_R_TX(r)]);
            PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_R_INF(r)]);
            continue;
        }

        new done = Daily_GetDone(playerid, r);
        new limit = gDailyLimit[r];

        new line[96], inf[96];

        // build "RANK X" label
        new rname[4];
        Daily_RankName(r, rname, sizeof(rname));
        format(line, sizeof(line), "RANK %s", rname);

        // info string: progress and locked reason if any
        if(DailyP[playerid][dForceUnlock] >= 0 && r <= DailyP[playerid][dForceUnlock])
        {
            format(inf, sizeof(inf), "debug: liberado | %d/%d", done, limit);
        }
        else
        {
            new why[64];
            if(!Daily_CanTakeRank(playerid, r, why, sizeof(why)))
                format(inf, sizeof(inf), "%s | %d/%d", why, done, limit);
            else
                format(inf, sizeof(inf), "%d/%d concluidas hoje", done, limit);
        }

        PlayerTextDrawSetString(playerid, gDailyPTD[playerid][PTD_R_TX(r)], line);
        PlayerTextDrawSetString(playerid, gDailyPTD[playerid][PTD_R_INF(r)], inf);

        PlayerTextDrawShow(playerid, gDailyPTD[playerid][PTD_R_BG(r)]);
        PlayerTextDrawShow(playerid, gDailyPTD[playerid][PTD_R_TX(r)]);
        PlayerTextDrawShow(playerid, gDailyPTD[playerid][PTD_R_INF(r)]);
    }

    DailyP[playerid][dUI] = DUI_LIST;
    SelectTextDraw(playerid, 0xFFFFFFFF);
    return 1;
}

stock Daily_UIShowOffer(playerid, rank, mid)
{
    if(gDailyBkg != Text:INVALID_TEXT_DRAW) TextDrawShowForPlayer(playerid, gDailyBkg);

    // Esconde UI de lista (caso ainda exista)
    PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_TITLE]);
    PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_SUB]);
    PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_BTN_BG]);
    PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_BTN_TX]);

    for(new r=0; r<DR_MAX; r++)
    {
        PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_R_BG(r)]);
        PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_R_TX(r)]);
        PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_R_INF(r)]);
    }

    // Esconde a oferta antiga (layout antigo)
    PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_O_TITLE]);
    PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_O_DESC]);
    PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_O_REW]);
    PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_O_ACC_BG]);
    PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_O_ACC_TX]);
    PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_O_DEC_BG]);
    PlayerTextDrawHide(playerid, gDailyPTD[playerid][PTD_O_DEC_TX]);

    // Monta conteúdo (igual a missao da Academia, só que dinâmico)
    new rn[2];
    Daily_RankName(rank, rn, sizeof(rn));

    new title[96];
    format(title, sizeof(title), "RANK %s - %s", rn, gDailyMissions[mid][dmName]);

    new descRaw[256];
    format(descRaw, sizeof(descRaw), "%s", gDailyMissions[mid][dmDesc]);

    new desc[260];
    Daily_WrapText(descRaw, desc, sizeof(desc), 46);

    new ry = gDailyMissions[mid][dmRyos];
    new xp = gDailyMissions[mid][dmXP];
    new fm = gDailyMissions[mid][dmFama];
    new op = gDailyMissions[mid][dmOp];

    // Fallback do rank (caso venha 0 no cfg)
    // Fallback do rank (caso venha 0 no cfg)
    if(ry <= 0) ry = gDailyBaseRyos[rank];
    if(xp <= 0) xp = gDailyBaseXP[rank];
    if(fm <= 0) fm = gDailyBaseFama[rank];
    if(op <= 0) op = gDailyBaseOp[rank];

    new num[16];
    new sRyos[32], sXP[32], sFama[24], sOp[24];

    Daily_FormatDots(ry, num, sizeof(num)); format(sRyos, sizeof(sRyos), "%s", num);
    Daily_FormatDots(xp, num, sizeof(num)); format(sXP, sizeof(sXP), "%s", num);
    format(sFama, sizeof(sFama), " ");
    format(sOp, sizeof(sOp), " ");

    PlayerTextDrawSetString(playerid, gDailyOfferPTD[playerid][DOF_TITLE], title);
    PlayerTextDrawSetString(playerid, gDailyOfferPTD[playerid][DOF_DESC], desc);
    PlayerTextDrawSetString(playerid, gDailyOfferPTD[playerid][DOF_RYOS], sRyos);
    PlayerTextDrawSetString(playerid, gDailyOfferPTD[playerid][DOF_XP], sXP);
    PlayerTextDrawSetString(playerid, gDailyOfferPTD[playerid][DOF_FAMA], sFama);
    PlayerTextDrawSetString(playerid, gDailyOfferPTD[playerid][DOF_OP], sOp);

    // Mostra a oferta (layout MSS)
    for(new i=0; i<DAILY_OFFER_PTD_MAX; i++)
    {
        // Usamos o layout igual ao da Missão da Academia.
        // Essas 2 linhas extras (Fama/Op) ficam escondidas para não “bagunçar” as recompensas.
        if(i == DOF_FAMA || i == DOF_OP) continue;

        if(gDailyOfferPTD[playerid][i] != PTD_INVALID)
            PlayerTextDrawShow(playerid, gDailyOfferPTD[playerid][i]);
    }

    DailyP[playerid][dUI] = DUI_OFFER;
    DailyP[playerid][dOfferRank] = rank;
    DailyP[playerid][dOfferMid] = mid;

    SelectTextDraw(playerid, 0xFFFFFFFF);
    return 1;
}

stock Daily_UICreate(playerid)
{
    // bg global
    if(gDailyBkg == Text:INVALID_TEXT_DRAW)
    {
        // layout IGUAL ao painel de missao da Academia (MSS:Int1)
        gDailyBkg = TextDrawCreate(80.0, -20.0, "MSS:Int1");
        TextDrawFont(gDailyBkg, 4);
        TextDrawLetterSize(gDailyBkg, 0.6, 2.0);
        TextDrawTextSize(gDailyBkg, 500.0, 500.0);
        TextDrawSetOutline(gDailyBkg, 1);
        TextDrawSetShadow(gDailyBkg, 0);
        TextDrawAlignment(gDailyBkg, 1);
        TextDrawUseBox(gDailyBkg, 1);
        TextDrawBoxColor(gDailyBkg, 50);
        TextDrawBackgroundColor(gDailyBkg, 255);
        TextDrawColor(gDailyBkg, -1);
        TextDrawSetProportional(gDailyBkg, 1);
        TextDrawSetSelectable(gDailyBkg, 0);
    }

    for(new i=0; i<DAILY_PTD_MAX; i++) gDailyPTD[playerid][i] = PTD_INVALID;
    for(new i=0; i<DAILY_OFFER_PTD_MAX; i++) gDailyOfferPTD[playerid][i] = PTD_INVALID;

    // Title
    gDailyPTD[playerid][PTD_TITLE] = CreatePlayerTextDraw(playerid, 80.0, 165.0, "QUADRO DE MISSOES DIARIAS");
    PlayerTextDrawFont(playerid, gDailyPTD[playerid][PTD_TITLE], 2);
    PlayerTextDrawLetterSize(playerid, gDailyPTD[playerid][PTD_TITLE], 0.28, 1.30);
    PlayerTextDrawColor(playerid, gDailyPTD[playerid][PTD_TITLE], -1);
    PlayerTextDrawSetOutline(playerid, gDailyPTD[playerid][PTD_TITLE], 1);
    PlayerTextDrawSetSelectable(playerid, gDailyPTD[playerid][PTD_TITLE], 0);

    // Sub
    gDailyPTD[playerid][PTD_SUB] = CreatePlayerTextDraw(playerid, 80.0, 186.0, " ");
    PlayerTextDrawFont(playerid, gDailyPTD[playerid][PTD_SUB], 1);
    PlayerTextDrawLetterSize(playerid, gDailyPTD[playerid][PTD_SUB], 0.22, 1.05);
    PlayerTextDrawColor(playerid, gDailyPTD[playerid][PTD_SUB], 0xDADADAFF);
    PlayerTextDrawSetOutline(playerid, gDailyPTD[playerid][PTD_SUB], 1);
    PlayerTextDrawSetSelectable(playerid, gDailyPTD[playerid][PTD_SUB], 0);

    // Close/Back button bg (use MSS:Int2)
    gDailyPTD[playerid][PTD_BTN_BG] = CreatePlayerTextDraw(playerid, 520.0, 320.0, "MSS:Int2");
    PlayerTextDrawFont(playerid, gDailyPTD[playerid][PTD_BTN_BG], 4);
    PlayerTextDrawTextSize(playerid, gDailyPTD[playerid][PTD_BTN_BG], 80.0, 25.0);
    PlayerTextDrawColor(playerid, gDailyPTD[playerid][PTD_BTN_BG], -1);
    PlayerTextDrawSetSelectable(playerid, gDailyPTD[playerid][PTD_BTN_BG], 1);

    gDailyPTD[playerid][PTD_BTN_TX] = CreatePlayerTextDraw(playerid, 560.0, 325.0, "FECHAR");
    PlayerTextDrawFont(playerid, gDailyPTD[playerid][PTD_BTN_TX], 2);
    PlayerTextDrawLetterSize(playerid, gDailyPTD[playerid][PTD_BTN_TX], 0.22, 1.10);
    PlayerTextDrawAlignment(playerid, gDailyPTD[playerid][PTD_BTN_TX], 2);
    PlayerTextDrawColor(playerid, gDailyPTD[playerid][PTD_BTN_TX], -1);
    PlayerTextDrawSetOutline(playerid, gDailyPTD[playerid][PTD_BTN_TX], 1);
    PlayerTextDrawSetSelectable(playerid, gDailyPTD[playerid][PTD_BTN_TX], 1);

    // Offer title
    gDailyPTD[playerid][PTD_O_TITLE] = CreatePlayerTextDraw(playerid, 80.0, 214.0, " ");
    PlayerTextDrawFont(playerid, gDailyPTD[playerid][PTD_O_TITLE], 2);
    PlayerTextDrawLetterSize(playerid, gDailyPTD[playerid][PTD_O_TITLE], 0.25, 1.20);
    PlayerTextDrawColor(playerid, gDailyPTD[playerid][PTD_O_TITLE], -1);
    PlayerTextDrawSetOutline(playerid, gDailyPTD[playerid][PTD_O_TITLE], 1);

    // Offer desc
    gDailyPTD[playerid][PTD_O_DESC] = CreatePlayerTextDraw(playerid, 80.0, 236.0, " ");
    PlayerTextDrawFont(playerid, gDailyPTD[playerid][PTD_O_DESC], 1);
    PlayerTextDrawLetterSize(playerid, gDailyPTD[playerid][PTD_O_DESC], 0.22, 1.08);
    PlayerTextDrawColor(playerid, gDailyPTD[playerid][PTD_O_DESC], 0xFFFFFFFF);
    PlayerTextDrawSetOutline(playerid, gDailyPTD[playerid][PTD_O_DESC], 1);
    PlayerTextDrawTextSize(playerid, gDailyPTD[playerid][PTD_O_DESC], 560.0, 0.0);

    // Offer rew
    gDailyPTD[playerid][PTD_O_REW] = CreatePlayerTextDraw(playerid, 80.0, 306.0, " ");
    PlayerTextDrawFont(playerid, gDailyPTD[playerid][PTD_O_REW], 1);
    PlayerTextDrawLetterSize(playerid, gDailyPTD[playerid][PTD_O_REW], 0.22, 1.05);
    PlayerTextDrawColor(playerid, gDailyPTD[playerid][PTD_O_REW], 0xFFFFAAFF);
    PlayerTextDrawSetOutline(playerid, gDailyPTD[playerid][PTD_O_REW], 1);

    // Offer accept bg (use MSS:Int3)
    gDailyPTD[playerid][PTD_O_ACC_BG] = CreatePlayerTextDraw(playerid, 415.0, 320.0, "MSS:Int3");
    PlayerTextDrawFont(playerid, gDailyPTD[playerid][PTD_O_ACC_BG], 4);
    PlayerTextDrawTextSize(playerid, gDailyPTD[playerid][PTD_O_ACC_BG], 95.0, 25.0);
    PlayerTextDrawColor(playerid, gDailyPTD[playerid][PTD_O_ACC_BG], -1);
    PlayerTextDrawSetSelectable(playerid, gDailyPTD[playerid][PTD_O_ACC_BG], 1);

    gDailyPTD[playerid][PTD_O_ACC_TX] = CreatePlayerTextDraw(playerid, 462.0, 325.0, "ACEITAR");
    PlayerTextDrawFont(playerid, gDailyPTD[playerid][PTD_O_ACC_TX], 2);
    PlayerTextDrawLetterSize(playerid, gDailyPTD[playerid][PTD_O_ACC_TX], 0.22, 1.10);
    PlayerTextDrawAlignment(playerid, gDailyPTD[playerid][PTD_O_ACC_TX], 2);
    PlayerTextDrawColor(playerid, gDailyPTD[playerid][PTD_O_ACC_TX], -1);
    PlayerTextDrawSetOutline(playerid, gDailyPTD[playerid][PTD_O_ACC_TX], 1);
    PlayerTextDrawSetSelectable(playerid, gDailyPTD[playerid][PTD_O_ACC_TX], 1);

    // Offer decline bg (use MSS:Int2)
    gDailyPTD[playerid][PTD_O_DEC_BG] = CreatePlayerTextDraw(playerid, 520.0, 320.0, "MSS:Int2");
    PlayerTextDrawFont(playerid, gDailyPTD[playerid][PTD_O_DEC_BG], 4);
    PlayerTextDrawTextSize(playerid, gDailyPTD[playerid][PTD_O_DEC_BG], 80.0, 25.0);
    PlayerTextDrawColor(playerid, gDailyPTD[playerid][PTD_O_DEC_BG], -1);
    PlayerTextDrawSetSelectable(playerid, gDailyPTD[playerid][PTD_O_DEC_BG], 1);

    gDailyPTD[playerid][PTD_O_DEC_TX] = CreatePlayerTextDraw(playerid, 560.0, 325.0, "RECUSAR");
    PlayerTextDrawFont(playerid, gDailyPTD[playerid][PTD_O_DEC_TX], 2);
    PlayerTextDrawLetterSize(playerid, gDailyPTD[playerid][PTD_O_DEC_TX], 0.22, 1.10);
    PlayerTextDrawAlignment(playerid, gDailyPTD[playerid][PTD_O_DEC_TX], 2);
    PlayerTextDrawColor(playerid, gDailyPTD[playerid][PTD_O_DEC_TX], -1);
    PlayerTextDrawSetOutline(playerid, gDailyPTD[playerid][PTD_O_DEC_TX], 1);
    PlayerTextDrawSetSelectable(playerid, gDailyPTD[playerid][PTD_O_DEC_TX], 1);

    // Rank rows
    new Float:baseY = 214.0;
    for(new r=0; r<DR_MAX; r++)
    {
        new Float:y = baseY + (r * 20.5);

        gDailyPTD[playerid][PTD_R_BG(r)] = CreatePlayerTextDraw(playerid, 78.0, y, "MSS:Int2");
        PlayerTextDrawFont(playerid, gDailyPTD[playerid][PTD_R_BG(r)], 4);
        PlayerTextDrawTextSize(playerid, gDailyPTD[playerid][PTD_R_BG(r)], 420.0, 18.0);
        PlayerTextDrawColor(playerid, gDailyPTD[playerid][PTD_R_BG(r)], -1);
        PlayerTextDrawSetSelectable(playerid, gDailyPTD[playerid][PTD_R_BG(r)], 1);

        gDailyPTD[playerid][PTD_R_TX(r)] = CreatePlayerTextDraw(playerid, 88.0, y+1.2, "RANK ?");
        PlayerTextDrawFont(playerid, gDailyPTD[playerid][PTD_R_TX(r)], 2);
        PlayerTextDrawLetterSize(playerid, gDailyPTD[playerid][PTD_R_TX(r)], 0.22, 1.05);
        PlayerTextDrawColor(playerid, gDailyPTD[playerid][PTD_R_TX(r)], -1);
        PlayerTextDrawSetOutline(playerid, gDailyPTD[playerid][PTD_R_TX(r)], 1);
        PlayerTextDrawSetSelectable(playerid, gDailyPTD[playerid][PTD_R_TX(r)], 1);

        gDailyPTD[playerid][PTD_R_INF(r)] = CreatePlayerTextDraw(playerid, 250.0, y+1.2, " ");
        PlayerTextDrawFont(playerid, gDailyPTD[playerid][PTD_R_INF(r)], 1);
        PlayerTextDrawLetterSize(playerid, gDailyPTD[playerid][PTD_R_INF(r)], 0.21, 1.05);
        PlayerTextDrawColor(playerid, gDailyPTD[playerid][PTD_R_INF(r)], 0xDDDDDDFF);
        PlayerTextDrawSetOutline(playerid, gDailyPTD[playerid][PTD_R_INF(r)], 1);



        PlayerTextDrawSetSelectable(playerid, gDailyPTD[playerid][PTD_R_INF(r)], 1);
    }


    // Offer (layout MSS / igual à missao da Academia)
    gDailyOfferPTD[playerid][DOF_TITLE] = CreatePlayerTextDraw(playerid, 323.0, 148.0, " ");
    PlayerTextDrawFont(playerid, gDailyOfferPTD[playerid][DOF_TITLE], 1);
    PlayerTextDrawLetterSize(playerid, gDailyOfferPTD[playerid][DOF_TITLE], 0.366666, 1.4);
    PlayerTextDrawTextSize(playerid, gDailyOfferPTD[playerid][DOF_TITLE], 629.5, 298.0);
    PlayerTextDrawAlignment(playerid, gDailyOfferPTD[playerid][DOF_TITLE], 2);
    PlayerTextDrawColor(playerid, gDailyOfferPTD[playerid][DOF_TITLE], 255);
    PlayerTextDrawSetShadow(playerid, gDailyOfferPTD[playerid][DOF_TITLE], 0);
    PlayerTextDrawSetOutline(playerid, gDailyOfferPTD[playerid][DOF_TITLE], 1);
    PlayerTextDrawBackgroundColor(playerid, gDailyOfferPTD[playerid][DOF_TITLE], 0);
    PlayerTextDrawSetProportional(playerid, gDailyOfferPTD[playerid][DOF_TITLE], 1);
    PlayerTextDrawUseBox(playerid, gDailyOfferPTD[playerid][DOF_TITLE], 1);
    PlayerTextDrawBoxColor(playerid, gDailyOfferPTD[playerid][DOF_TITLE], 0);
    PlayerTextDrawSetSelectable(playerid, gDailyOfferPTD[playerid][DOF_TITLE], 0);

    gDailyOfferPTD[playerid][DOF_DESC] = CreatePlayerTextDraw(playerid, 323.0, 169.0, " ");
    PlayerTextDrawFont(playerid, gDailyOfferPTD[playerid][DOF_DESC], 1);
    PlayerTextDrawLetterSize(playerid, gDailyOfferPTD[playerid][DOF_DESC], 0.245833, 1.4);
    PlayerTextDrawTextSize(playerid, gDailyOfferPTD[playerid][DOF_DESC], 629.5, 298.0);
    PlayerTextDrawAlignment(playerid, gDailyOfferPTD[playerid][DOF_DESC], 2);
    PlayerTextDrawColor(playerid, gDailyOfferPTD[playerid][DOF_DESC], 255);
    PlayerTextDrawSetShadow(playerid, gDailyOfferPTD[playerid][DOF_DESC], 0);
    PlayerTextDrawSetOutline(playerid, gDailyOfferPTD[playerid][DOF_DESC], 1);
    PlayerTextDrawBackgroundColor(playerid, gDailyOfferPTD[playerid][DOF_DESC], 0);
    PlayerTextDrawSetProportional(playerid, gDailyOfferPTD[playerid][DOF_DESC], 1);
    PlayerTextDrawUseBox(playerid, gDailyOfferPTD[playerid][DOF_DESC], 1);
    PlayerTextDrawBoxColor(playerid, gDailyOfferPTD[playerid][DOF_DESC], 0);
    PlayerTextDrawSetSelectable(playerid, gDailyOfferPTD[playerid][DOF_DESC], 0);

    gDailyOfferPTD[playerid][DOF_RYOS] = CreatePlayerTextDraw(playerid, 283.0, 294.0, "0 Ryos");
    PlayerTextDrawFont(playerid, gDailyOfferPTD[playerid][DOF_RYOS], 1);
    PlayerTextDrawLetterSize(playerid, gDailyOfferPTD[playerid][DOF_RYOS], 0.2, 1.6);
    PlayerTextDrawTextSize(playerid, gDailyOfferPTD[playerid][DOF_RYOS], 629.5, 298.0);
    PlayerTextDrawAlignment(playerid, gDailyOfferPTD[playerid][DOF_RYOS], 2);
    PlayerTextDrawColor(playerid, gDailyOfferPTD[playerid][DOF_RYOS], -1);
    PlayerTextDrawSetShadow(playerid, gDailyOfferPTD[playerid][DOF_RYOS], 0);
    PlayerTextDrawSetOutline(playerid, gDailyOfferPTD[playerid][DOF_RYOS], 1);
    PlayerTextDrawBackgroundColor(playerid, gDailyOfferPTD[playerid][DOF_RYOS], 0);
    PlayerTextDrawSetProportional(playerid, gDailyOfferPTD[playerid][DOF_RYOS], 1);
    PlayerTextDrawUseBox(playerid, gDailyOfferPTD[playerid][DOF_RYOS], 1);
    PlayerTextDrawBoxColor(playerid, gDailyOfferPTD[playerid][DOF_RYOS], 0);
    PlayerTextDrawSetSelectable(playerid, gDailyOfferPTD[playerid][DOF_RYOS], 0);

    gDailyOfferPTD[playerid][DOF_XP] = CreatePlayerTextDraw(playerid, 330.0, 294.0, "0 XP");
    PlayerTextDrawFont(playerid, gDailyOfferPTD[playerid][DOF_XP], 1);
    PlayerTextDrawLetterSize(playerid, gDailyOfferPTD[playerid][DOF_XP], 0.2, 1.6);
    PlayerTextDrawTextSize(playerid, gDailyOfferPTD[playerid][DOF_XP], 629.5, 298.0);
    PlayerTextDrawAlignment(playerid, gDailyOfferPTD[playerid][DOF_XP], 2);
    PlayerTextDrawColor(playerid, gDailyOfferPTD[playerid][DOF_XP], -1);
    PlayerTextDrawSetShadow(playerid, gDailyOfferPTD[playerid][DOF_XP], 0);
    PlayerTextDrawSetOutline(playerid, gDailyOfferPTD[playerid][DOF_XP], 1);
    PlayerTextDrawBackgroundColor(playerid, gDailyOfferPTD[playerid][DOF_XP], 0);
    PlayerTextDrawSetProportional(playerid, gDailyOfferPTD[playerid][DOF_XP], 1);
    PlayerTextDrawUseBox(playerid, gDailyOfferPTD[playerid][DOF_XP], 1);
    PlayerTextDrawBoxColor(playerid, gDailyOfferPTD[playerid][DOF_XP], 0);
    PlayerTextDrawSetSelectable(playerid, gDailyOfferPTD[playerid][DOF_XP], 0);

    gDailyOfferPTD[playerid][DOF_FAMA] = CreatePlayerTextDraw(playerid, 384.0, 295.0, "0 Fama");
    PlayerTextDrawFont(playerid, gDailyOfferPTD[playerid][DOF_FAMA], 1);
    PlayerTextDrawLetterSize(playerid, gDailyOfferPTD[playerid][DOF_FAMA], 0.154166, 1.6);
    PlayerTextDrawTextSize(playerid, gDailyOfferPTD[playerid][DOF_FAMA], 629.5, 298.0);
    PlayerTextDrawAlignment(playerid, gDailyOfferPTD[playerid][DOF_FAMA], 2);
    PlayerTextDrawColor(playerid, gDailyOfferPTD[playerid][DOF_FAMA], -1);
    PlayerTextDrawSetShadow(playerid, gDailyOfferPTD[playerid][DOF_FAMA], 0);
    PlayerTextDrawSetOutline(playerid, gDailyOfferPTD[playerid][DOF_FAMA], 1);
    PlayerTextDrawBackgroundColor(playerid, gDailyOfferPTD[playerid][DOF_FAMA], 0);
    PlayerTextDrawSetProportional(playerid, gDailyOfferPTD[playerid][DOF_FAMA], 1);
    PlayerTextDrawUseBox(playerid, gDailyOfferPTD[playerid][DOF_FAMA], 1);
    PlayerTextDrawBoxColor(playerid, gDailyOfferPTD[playerid][DOF_FAMA], 0);
    PlayerTextDrawSetSelectable(playerid, gDailyOfferPTD[playerid][DOF_FAMA], 0);

    gDailyOfferPTD[playerid][DOF_OP] = CreatePlayerTextDraw(playerid, 416.0, 295.0, "0 Op");
    PlayerTextDrawFont(playerid, gDailyOfferPTD[playerid][DOF_OP], 1);
    PlayerTextDrawLetterSize(playerid, gDailyOfferPTD[playerid][DOF_OP], 0.154166, 1.6);
    PlayerTextDrawTextSize(playerid, gDailyOfferPTD[playerid][DOF_OP], 629.5, 298.0);
    PlayerTextDrawAlignment(playerid, gDailyOfferPTD[playerid][DOF_OP], 2);
    PlayerTextDrawColor(playerid, gDailyOfferPTD[playerid][DOF_OP], -1);
    PlayerTextDrawSetShadow(playerid, gDailyOfferPTD[playerid][DOF_OP], 0);
    PlayerTextDrawSetOutline(playerid, gDailyOfferPTD[playerid][DOF_OP], 1);
    PlayerTextDrawBackgroundColor(playerid, gDailyOfferPTD[playerid][DOF_OP], 0);
    PlayerTextDrawSetProportional(playerid, gDailyOfferPTD[playerid][DOF_OP], 1);
    PlayerTextDrawUseBox(playerid, gDailyOfferPTD[playerid][DOF_OP], 1);
    PlayerTextDrawBoxColor(playerid, gDailyOfferPTD[playerid][DOF_OP], 0);
    PlayerTextDrawSetSelectable(playerid, gDailyOfferPTD[playerid][DOF_OP], 0);

    // Botões (áreas clicáveis) - Recusar / Aceitar
    gDailyOfferPTD[playerid][DOF_RECUSAR] = CreatePlayerTextDraw(playerid, 260.0, 329.0, "_");
    PlayerTextDrawFont(playerid, gDailyOfferPTD[playerid][DOF_RECUSAR], 2);
    PlayerTextDrawLetterSize(playerid, gDailyOfferPTD[playerid][DOF_RECUSAR], 0.258332, 1.75);
    PlayerTextDrawTextSize(playerid, gDailyOfferPTD[playerid][DOF_RECUSAR], 11.0, 64.0);
    PlayerTextDrawAlignment(playerid, gDailyOfferPTD[playerid][DOF_RECUSAR], 2);
    PlayerTextDrawColor(playerid, gDailyOfferPTD[playerid][DOF_RECUSAR], -1);
    PlayerTextDrawUseBox(playerid, gDailyOfferPTD[playerid][DOF_RECUSAR], 1);
    PlayerTextDrawBoxColor(playerid, gDailyOfferPTD[playerid][DOF_RECUSAR], 0);
    PlayerTextDrawSetShadow(playerid, gDailyOfferPTD[playerid][DOF_RECUSAR], 0);
    PlayerTextDrawSetOutline(playerid, gDailyOfferPTD[playerid][DOF_RECUSAR], 1);
    PlayerTextDrawBackgroundColor(playerid, gDailyOfferPTD[playerid][DOF_RECUSAR], 255);
    PlayerTextDrawSetProportional(playerid, gDailyOfferPTD[playerid][DOF_RECUSAR], 1);
    PlayerTextDrawSetSelectable(playerid, gDailyOfferPTD[playerid][DOF_RECUSAR], 1);

    gDailyOfferPTD[playerid][DOF_ACEITAR] = CreatePlayerTextDraw(playerid, 394.0, 329.0, "_");
    PlayerTextDrawFont(playerid, gDailyOfferPTD[playerid][DOF_ACEITAR], 2);
    PlayerTextDrawLetterSize(playerid, gDailyOfferPTD[playerid][DOF_ACEITAR], 0.258332, 1.75);
    PlayerTextDrawTextSize(playerid, gDailyOfferPTD[playerid][DOF_ACEITAR], 11.0, 64.0);
    PlayerTextDrawAlignment(playerid, gDailyOfferPTD[playerid][DOF_ACEITAR], 2);
    PlayerTextDrawColor(playerid, gDailyOfferPTD[playerid][DOF_ACEITAR], -1);
    PlayerTextDrawUseBox(playerid, gDailyOfferPTD[playerid][DOF_ACEITAR], 1);
    PlayerTextDrawBoxColor(playerid, gDailyOfferPTD[playerid][DOF_ACEITAR], 0);
    PlayerTextDrawSetShadow(playerid, gDailyOfferPTD[playerid][DOF_ACEITAR], 0);
    PlayerTextDrawSetOutline(playerid, gDailyOfferPTD[playerid][DOF_ACEITAR], 1);
    PlayerTextDrawBackgroundColor(playerid, gDailyOfferPTD[playerid][DOF_ACEITAR], 255);
    PlayerTextDrawSetProportional(playerid, gDailyOfferPTD[playerid][DOF_ACEITAR], 1);
    PlayerTextDrawSetSelectable(playerid, gDailyOfferPTD[playerid][DOF_ACEITAR], 1);


    // defaults hidden
    Daily_UIHideAll(playerid);
    return 1;
}

// ------------------------------
// Requisitos (mensagens)
// ------------------------------
stock Daily_CanTakeRank(playerid, rank, outWhy[], outLen)
{
    // debug override
    if(DailyP[playerid][dForceUnlock] >= 0 && rank <= DailyP[playerid][dForceUnlock])
    {
        format(outWhy, outLen, "Liberado (debug)");
        return 1;
    }

    // daily limit
    new done = Daily_GetDone(playerid, rank);
    if(done >= gDailyLimit[rank])
    {
        format(outWhy, outLen, "Limite diario atingido");
        return 0;
    }

    // cooldown rank
    new cd = Daily_GetCd(playerid, rank);
    if(cd > gettime())
    {
        new left = cd - gettime();
        new mins = (left / 60);
        format(outWhy, outLen, "Cooldown (%d min)", mins);
        return 0;
    }

    // board needs academy done
    new provIdx = DailyP[playerid][dProvIdx];
    new pType = gDailyProvPos[provIdx][dpType];
    if(pType == DP_BOARD)
    {
        if(!DAILY_CAN_USE_BOARD(playerid))
        {
            format(outWhy, outLen, "Conclua a academia primeiro");
            return 0;
        }
    }

    // graduation checks
    new prank = Info[playerid][pRank];

    if(rank == DR_D && prank < DAILY_REQ_D_PRANK)
    {
        format(outWhy, outLen, "Requer Genin");
        return 0;
    }
    if(rank == DR_C && prank < DAILY_REQ_C_PRANK)
    {
        format(outWhy, outLen, "Requer Chunin");
        return 0;
    }
    if(rank == DR_B && prank < DAILY_REQ_B_PRANK)
    {
        format(outWhy, outLen, "Requer Chunin");
        return 0;
    }
    if(rank == DR_A && !DAILY_HAS_SPECIAL_A(playerid))
    {
        format(outWhy, outLen, "Requer Jounin+");
        return 0;
    }

    if(rank == DR_S)
    {
        if(DAILY_HAS_SPECIAL_S(playerid))
        {
            format(outWhy, outLen, "Liberado");
            return 1;
        }
#if DAILY_ALLOW_S_BY_FAMA
            // usa NinjaFamaRank se existir
#if defined NinjaFamaRank
                if(NinjaFamaRank[playerid] >= DAILY_REQ_S_FAMA_RANK)
                {
                    format(outWhy, outLen, "Liberado por reputacao");
                    return 1;
                }
#endif
#endif
        format(outWhy, outLen, "Requer ANBU/Kage ou alta reputacao");
        return 0;
    }

    format(outWhy, outLen, "Liberado");
    return 1;
}

// ------------------------------
// Sorteio de missao por rank
// ------------------------------
stock Daily_PickMission(rank)
{
    new ids[64];
    new count = 0;

    for(new i=0; i<sizeof(gDailyMissions); i++)
    {
        if(gDailyMissions[i][dmRank] == rank)
        {
            ids[count++] = i;
            if(count >= 64) break;
        }
    }

    if(count <= 0) return -1;
    return ids[random(count)];
}

// ------------------------------
// Coordenadas por offset
// ------------------------------
stock Daily_OffsetPos(playerid, Float:ox, Float:oy, Float:oz, Float:dx, Float:dy, Float:dz, &Float:rx, &Float:ry, &Float:rz)
{
    new Float:sc = DailyP[playerid][dScale];
    rx = ox + (dx * sc);
    ry = oy + (dy * sc);
    rz = oz + (dz * sc);
    return 1;
}

// ------------------------------
// Missao runtime: cleanup
// ------------------------------
stock Daily_ClearActors(playerid)
{
    for(new i=0; i<DailyNpcCnt[playerid]; i++)
    {
        new id = DailyNpcId[playerid][i];

        // 1) Actor (CreateActor)
        if(id >= 0 && id < DAILY_ACT_MAX)
        {
            DestroyActor(id);
            DailyActOwner[id] = -1;
            DailyActMid[id] = -1;
            DailyActAlive[id] = 0;
        }
        // 2) Combat NPC (shinobi_ai) -> id armazenado como TAG + aislot
        else if(id >= DAILY_NPC_TAG_AISLOT)
        {
            new aislot = id - DAILY_NPC_TAG_AISLOT;
            if(aislot >= 0 && aislot < MAXIMO_NPCS_COMBATE)
            {
                // tenta destruir via API do shinobi_ai (runtime-safe)
                if(funcidx("SHRP_NpcDestroy") != -1) CallLocalFunction("SHRP_NpcDestroy", "i", aislot);

                DailyAiOwner[aislot] = -1;
                DailyAiMid[aislot] = -1;
                DailyAiAlive[aislot] = false;
            }
        }

        DailyNpcId[playerid][i] = -1;
    }
    DailyNpcCnt[playerid] = 0;

    if(DailyHostageAct[playerid] != -1)
    {
        DestroyActor(DailyHostageAct[playerid]);
        DailyHostageAct[playerid] = -1;
    }
    return 1;
}

stock Daily_ClearEscort(playerid)
{
    if(DailyEscortObj[playerid] != -1)
    {
#if defined _streamer_included
            DestroyDynamicObject(DailyEscortObj[playerid]);
#else
            DestroyObject(DailyEscortObj[playerid]);
#endif
        DailyEscortObj[playerid] = -1;
    }
    return 1;
}

stock Daily_StopMission(playerid)
{
    DisablePlayerCheckpoint(playerid);
    Daily_ClearEscort(playerid);
    Daily_ClearActors(playerid);

    DailyP[playerid][dActive] = 0;
    DailyP[playerid][dMid] = -1;
    DailyP[playerid][dRank] = -1;
    DailyP[playerid][dStep] = 0;
    DailyP[playerid][dHold] = 0;
    DailyP[playerid][dHoldNeed] = 0;
    DailyP[playerid][dNeed] = 0;
    DailyP[playerid][dCount] = 0;
    DailyP[playerid][dSusFlags] = 0;
    DailyP[playerid][dEscortAway] = 0;
    DailyP[playerid][dTravel] = 0.0;
    return 1;
}

// ------------------------------
// Penalidade
// ------------------------------
stock Daily_ApplyPenalty(playerid, rank)
{
    if(rank < 0 || rank >= DR_MAX) return 0;

#if DAILY_PEN_MODE == 1
        // consome tentativa do rank (incrementa done)
        new done = Daily_GetDone(playerid, rank);
        Daily_SetDone(playerid, rank, done+1);
#else
        // cooldown
        Daily_SetCd(playerid, rank, gettime() + (DAILY_PEN_COOLDOWN_MIN * 60));
#endif
    Daily_Save(playerid);
    return 1;
}

// ------------------------------
// Missao: fail/complete
// ------------------------------
stock Daily_Fail(playerid, const reason[])
{
    if(!DailyP[playerid][dActive]) return 0;

    new rank = DailyP[playerid][dRank];
    new mid  = DailyP[playerid][dMid];

    Daily_ApplyPenalty(playerid, rank);

    new rname[4];
    Daily_RankName(rank, rname, sizeof(rname));

    new msg[144];
    format(msg, sizeof(msg), "[Missoes] Rank %s falhou: %s", rname, reason);
    SendClientMessageEx(playerid, COLOR_RED, msg);

    new __lg[256];
    format(__lg, sizeof(__lg), "[FAIL] %d %s rank=%s mid=%d reason=%s", playerid, "player", rname, mid, reason);
    Daily_Log(__lg);
    Daily_StopMission(playerid);
    return 1;
}

stock Daily_Complete(playerid)
{
    if(!DailyP[playerid][dActive]) return 0;

    new rank = DailyP[playerid][dRank];
    new mid  = DailyP[playerid][dMid];

    // anti-burla: minimo de tempo e distancia
    new dur = gettime() - DailyP[playerid][dStartTime];
    new minT = gDailyMissions[mid][dmMinTime];
    if(minT <= 0) minT = gDailyMinTime[rank];

    new Float:minD = gDailyMissions[mid][dmMinDist];
    if(minD <= 0.0) minD = gDailyMinDist[rank];

    if(dur < minT)
    {
        DailyP[playerid][dSusFlags] |= DSUS_FASTDONE;
        // falha "leve": nao recompensar e aplicar penalidade
        Daily_Fail(playerid, "tempo minimo nao atingido");
        return 1;
    }
    if(DailyP[playerid][dTravel] < minD)
    {
        Daily_Fail(playerid, "distancia minima nao atingida");
        return 1;
    }

#if DAILY_BLOCK_ON_SUSPECT
        if(DailyP[playerid][dSusFlags] != 0)
        {
            Daily_Fail(playerid, "atividade suspeita detectada");
            return 1;
        }
#endif

    // recompensas
    new ry = gDailyMissions[mid][dmRyos]; if(ry <= 0) ry = gDailyBaseRyos[rank];
    new xp = gDailyMissions[mid][dmXP];   if(xp <= 0) xp = gDailyBaseXP[rank];
    new fm = gDailyMissions[mid][dmFama]; if(fm <= 0) fm = gDailyBaseFama[rank];
    new op = gDailyMissions[mid][dmOp];   if(op <= 0) op = gDailyBaseOp[rank];

    Daily_GiveCash(playerid, ry);
    Daily_GiveXP(playerid, xp);
    Daily_RewardTxd(playerid, xp, ry);

    Daily_AddFama(playerid, fm);
    Daily_AddOpiniao(playerid, op);
    Daily_FamaSave(playerid);

    // contabiliza
    new done = Daily_GetDone(playerid, rank);
    Daily_SetDone(playerid, rank, done+1);

    Daily_Save(playerid);

    new rname[4];
    Daily_RankName(rank, rname, sizeof(rname));

    new msg[170];
    format(msg, sizeof(msg), "[Missoes] Rank %s concluida. +%d Ryos | +%d XP | +%d Fama | +%d Opiniao.", rname, ry, xp, fm, op);
    SendClientMessageEx(playerid, COLOR_GREEN, msg);

    new __lg[256];
    format(__lg, sizeof(__lg), "[OK] pid=%d rank=%s mid=%d dur=%ds dist=%.1f sus=%d ry=%d xp=%d fm=%d op=%d", playerid, rname, mid, dur, DailyP[playerid][dTravel], DailyP[playerid][dSusFlags], ry, xp, fm, op);
    Daily_Log(__lg);
    Daily_StopMission(playerid);
    return 1;
}

// ------------------------------
// Missao: avancar steps
// ------------------------------
stock Daily_SetTarget(playerid, Float:x, Float:y, Float:z)
{
    DailyP[playerid][dTgtX] = x;
    DailyP[playerid][dTgtY] = y;
    DailyP[playerid][dTgtZ] = z;
    SetPlayerCheckpoint(playerid, x, y, z, DAILY_CP_RADIUS);
    DailyP[playerid][dHold] = 0;

    new h = gDailyMissions[DailyP[playerid][dMid]][dmHold];
    if(h <= 0) h = (DAILY_HOLD_MIN + random((DAILY_HOLD_MAX - DAILY_HOLD_MIN) + 1));
    DailyP[playerid][dHoldNeed] = h;
    return 1;
}

stock Daily_StartDelivery(playerid)
{
    new mid = DailyP[playerid][dMid];

    new Float:ox = DailyP[playerid][dOrgX];
    new Float:oy = DailyP[playerid][dOrgY];
    new Float:oz = DailyP[playerid][dOrgZ];

    new Float:x, Float:y, Float:z;

    if(DailyP[playerid][dStep] == 0)
    {
        Daily_OffsetPos(playerid, ox, oy, oz, gDailyMissions[mid][dmP1x], gDailyMissions[mid][dmP1y], gDailyMissions[mid][dmP1z], x, y, z);
        Daily_SetTarget(playerid, x, y, z);
        SendClientMessageEx(playerid, COLOR_WHITE, "[Missoes] Va ate o ponto e aguarde alguns segundos para pegar o item.");
    }
    else if(DailyP[playerid][dStep] == 1)
    {
        Daily_OffsetPos(playerid, ox, oy, oz, gDailyMissions[mid][dmP2x], gDailyMissions[mid][dmP2y], gDailyMissions[mid][dmP2z], x, y, z);
        Daily_SetTarget(playerid, x, y, z);
        SendClientMessageEx(playerid, COLOR_WHITE, "[Missoes] Agora entregue no destino e aguarde a confirmacao.");
    }
    else
    {
        Daily_Complete(playerid);
    }
    return 1;
}

stock Daily_StartInvest(playerid)
{
    new mid = DailyP[playerid][dMid];
    new Float:ox = DailyP[playerid][dOrgX];
    new Float:oy = DailyP[playerid][dOrgY];
    new Float:oz = DailyP[playerid][dOrgZ];

    new Float:x, Float:y, Float:z;

    if(DailyP[playerid][dStep] == 0)
        Daily_OffsetPos(playerid, ox, oy, oz, gDailyMissions[mid][dmP1x], gDailyMissions[mid][dmP1y], gDailyMissions[mid][dmP1z], x, y, z);
    else if(DailyP[playerid][dStep] == 1)
        Daily_OffsetPos(playerid, ox, oy, oz, gDailyMissions[mid][dmP2x], gDailyMissions[mid][dmP2y], gDailyMissions[mid][dmP2z], x, y, z);
    else if(DailyP[playerid][dStep] == 2)
        Daily_OffsetPos(playerid, ox, oy, oz, gDailyMissions[mid][dmP3x], gDailyMissions[mid][dmP3y], gDailyMissions[mid][dmP3z], x, y, z);
    else
    {
        Daily_Complete(playerid);
        return 1;
    }

    Daily_SetTarget(playerid, x, y, z);
    SendClientMessageEx(playerid, COLOR_WHITE, "[Missoes] Investigue o local e permaneça ate confirmar.");
    return 1;
}

stock Daily_StartPatrol(playerid)
{
    new mid = DailyP[playerid][dMid];
    new need = gDailyMissions[mid][dmNeed];
    if(need <= 0) need = 4;

    if(DailyP[playerid][dStep] >= need)
    {
        Daily_Complete(playerid);
        return 1;
    }

    new Float:ox = DailyP[playerid][dOrgX];
    new Float:oy = DailyP[playerid][dOrgY];
    new Float:oz = DailyP[playerid][dOrgZ];

    new Float:x, Float:y, Float:z;

    switch(DailyP[playerid][dStep])
    {
        case 0: Daily_OffsetPos(playerid, ox, oy, oz, gDailyMissions[mid][dmP1x], gDailyMissions[mid][dmP1y], gDailyMissions[mid][dmP1z], x, y, z);
        case 1: Daily_OffsetPos(playerid, ox, oy, oz, gDailyMissions[mid][dmP2x], gDailyMissions[mid][dmP2y], gDailyMissions[mid][dmP2z], x, y, z);
        case 2: Daily_OffsetPos(playerid, ox, oy, oz, gDailyMissions[mid][dmP3x], gDailyMissions[mid][dmP3y], gDailyMissions[mid][dmP3z], x, y, z);
        case 3: Daily_OffsetPos(playerid, ox, oy, oz, gDailyMissions[mid][dmP4x], gDailyMissions[mid][dmP4y], gDailyMissions[mid][dmP4z], x, y, z);
    }

    Daily_SetTarget(playerid, x, y, z);
    SendClientMessageEx(playerid, COLOR_WHITE, "[Missoes] Patrulha: chegue e permaneça ate validar o ponto.");
    return 1;
}

stock Daily_AddActorForPlayer(playerid, actorid)
{
    if(DailyNpcCnt[playerid] >= DAILY_NPC_MAX) return 0;
    DailyNpcId[playerid][DailyNpcCnt[playerid]++] = actorid;
    return 1;
}

stock Daily_SpawnPveActors(playerid)
{
    new mid = DailyP[playerid][dMid];
    new kills = gDailyMissions[mid][dmNeed];
    if(kills <= 0) kills = 3;

    // limite por player
    if(kills > DAILY_NPC_MAX) kills = DAILY_NPC_MAX;

    new skin = gDailyMissions[mid][dmNpcSkin];
    if(skin <= 0) skin = 162;

    // vila do provedor (IWA/KIRI etc) - usado só pra escolher spawn FIXO
    new prov = DailyP[playerid][dProvIdx];
    new vila = 0;
    if(prov >= 0 && prov < gDailyProvCount) vila = gDailyProvPos[prov][dpVila];

    // centro/checkpoint padrão (área configurada no cfg)
    new Float:ox = DailyP[playerid][dOrgX];
    new Float:oy = DailyP[playerid][dOrgY];
    new Float:oz = DailyP[playerid][dOrgZ];

    new Float:cx, Float:cy, Float:cz;
    Daily_OffsetPos(playerid, ox, oy, oz, gDailyMissions[mid][dmAreaX], gDailyMissions[mid][dmAreaY], gDailyMissions[mid][dmAreaZ], cx, cy, cz);

    new Float:rad = gDailyMissions[mid][dmRadius];
    if(rad <= 0.0) rad = 25.0;

    // --- FIX ESPECÍFICO: Treino: Derrubar Bonecos (spawn fixo por vila) ---
    new bool:isBonecos = Daily_IsBonecosMission(mid);

    if(isBonecos)
    {
        // força 3 bonecos (ou o dmNeed se for menor), e força centro do checkpoint pro "dojo"
        if(kills > 3) kills = 3;

        if(vila == 1) // Iwagakure
        {
            cx = -1436.6909; cy = 1676.4060; cz = 25.1198;
            rad = 35.0;
        }
        else if(vila == 2) // Kirigakure
        {
            cx = 2389.5270; cy = -2110.2206; cz = 29.6049;
            rad = 45.0;
        }
        else
        {
            // vila desconhecida -> mantém area do cfg
            rad = 30.0;
        }
    }

    DailyP[playerid][dNeed] = kills;
    DailyP[playerid][dCount] = 0;

    new vw = GetPlayerVirtualWorld(playerid);
    new interior = GetPlayerInterior(playerid);

    // Se o shinobi_ai estiver carregado, criamos NPCs de combate (FCNPC) -> melee/taijutsu funciona.
    new bool:useCombatNpc = (funcidx("SHRP_NpcCreate") != -1);

    new created = 0;

    for(new i=0; i<kills; i++)
    {
        new Float:nx, Float:ny, Float:nz, Float:ang;

        if(isBonecos)
        {
            if(vila == 1)
            {
                nx = gDailyBonecos_IWA[i][0];
                ny = gDailyBonecos_IWA[i][1];
                nz = gDailyBonecos_IWA[i][2];
                ang = gDailyBonecos_IWA[i][3];
            }
            else if(vila == 2)
            {
                nx = gDailyBonecos_KIRI[i][0];
                ny = gDailyBonecos_KIRI[i][1];
                nz = gDailyBonecos_KIRI[i][2];
                ang = gDailyBonecos_KIRI[i][3];
            }
            else
            {
                // fallback (sem vila) -> random na área
                ang = float(random(360));
                new Float:dist = float(random(floatround(rad)));
                nx = cx + floatsin(ang, degrees) * dist;
                ny = cy + floatcos(ang, degrees) * dist;
                nz = cz;
            }
        }
        else
        {
            // random na área configurada
            ang = float(random(360));
            new Float:dist2 = float(random(floatround(rad)));
            nx = cx + floatsin(ang, degrees) * dist2;
            ny = cy + floatcos(ang, degrees) * dist2;
            nz = cz;
        }

        if(useCombatNpc)
        {
            // nome unico (precisa ser valido como nick)
            new nname[24];
            if(isBonecos) format(nname, sizeof nname, "Boneco_%d_%d", playerid, i);
            else format(nname, sizeof nname, "Bandido_%d_%d", playerid, i);

            // IMPORTANTE:
            // - NUNCA setar vila do NPC aqui, senão ele pode ignorar o player (mesma vila)
            // - Vila 0 = "bandido neutro" (acerta e recebe hit de qualquer um)
            new aislot = CallLocalFunction("SHRP_NpcCreate", "siiifffii",
                nname, skin, NPCT_HOSTILE, 0, nx, ny, nz, vw, interior);

            if(aislot != -1)
            {
                // Ajustes rápidos (sem XP/dinheiro pra treino)
                if(funcidx("SHRP_NpcAI_ConfigureDefaults") != -1) CallLocalFunction("SHRP_NpcAI_ConfigureDefaults", "i", aislot);
                if(funcidx("SHRP_NpcSetHP") != -1) CallLocalFunction("SHRP_NpcSetHP", "if", aislot, 120.0);
                if(funcidx("SHRP_NpcSetRewards") != -1) CallLocalFunction("SHRP_NpcSetRewards", "iii", aislot, 0, 0);

                // marca para contagem/limpeza
                if(DailyNpcCnt[playerid] < DAILY_NPC_MAX)
                {
                    DailyNpcId[playerid][DailyNpcCnt[playerid]++] = DAILY_NPC_TAG_AISLOT + aislot;
                    created++;

                    if(aislot >= 0 && aislot < MAXIMO_NPCS_COMBATE)
                    {
                        DailyAiOwner[aislot] = playerid;
                        DailyAiMid[aislot] = mid;
                        DailyAiAlive[aislot] = true;
                        // Z FIX: store expected min Z and hold for a few seconds after spawn.
                        DailyAiMinZ[aislot] = nz;
                        DailyAiFixUntilTick[aislot] = GetTickCount() + 10000;

                        // light timer only for "Treino: Derrubar Bonecos"
                        if(isBonecos && DailyPveFixTmr[playerid] == -1)
                        {
                            DailyPveFixTmr[playerid] = SetTimerEx("Daily_PveFixNpcZ", 350, true, "i", playerid);
                        }
                    }
                }

                #if defined Daily_OnSpawnPveNpc
                    new npcid = INVALID_PLAYER_ID;
                    if(funcidx("SHRP_NpcGetId") != -1) npcid = CallLocalFunction("SHRP_NpcGetId", "i", aislot);
                    Daily_OnSpawnPveNpc(playerid, npcid, aislot);
                #endif
            }
        }
        else
        {
            // fallback antigo (Actors)
            new actorid = CreateActor(skin, nx, ny, nz, ang);
            if(actorid >= 0 && actorid < DAILY_ACT_MAX)
            {
                SetActorHealth(actorid, 100.0);

                DailyActOwner[actorid] = playerid;
                DailyActMid[actorid] = mid;
                DailyActAlive[actorid] = 1;

                Daily_AddActorForPlayer(playerid, actorid);

                #if defined Daily_OnSpawnNpc
                    Daily_OnSpawnNpc(playerid, actorid);
                #endif
            }
        }
    }

    // checkpoint para area (ou centro fixo do treino)
    Daily_SetTarget(playerid, cx, cy, cz);

    if(useCombatNpc)
    {
        if(created <= 0)
            SendClientMessageEx(playerid, COLOR_WHITE, "[Missoes] PVE: nao foi possivel criar NPCs de combate (sem slots livres).");
        else if(isBonecos)
            SendClientMessageEx(playerid, COLOR_WHITE, "[Missoes] Rank E: Treino: derrube os bonecos no local marcado. Apenas suas eliminacoes contam.");
        else
            SendClientMessageEx(playerid, COLOR_WHITE, "[Missoes] PVE: elimine os bandidos na area marcada. Apenas suas eliminacoes contam.");
    }
    else
    {
        SendClientMessageEx(playerid, COLOR_WHITE, "[Missoes] PVE: elimine os alvos na area marcada. Apenas eliminacoes marcadas pelo sistema contam.");
    }
    return 1;
}



stock Daily_StartRescue(playerid)
{
    new mid = DailyP[playerid][dMid];
    new spots = gDailyMissions[mid][dmNeed];
    if(spots <= 0) spots = 3;
    if(spots > 4) spots = 4;

    new pick = random(spots);

    new Float:ox = DailyP[playerid][dOrgX];
    new Float:oy = DailyP[playerid][dOrgY];
    new Float:oz = DailyP[playerid][dOrgZ];

    new Float:x, Float:y, Float:z;

    if(pick == 0) Daily_OffsetPos(playerid, ox, oy, oz, gDailyMissions[mid][dmP1x], gDailyMissions[mid][dmP1y], gDailyMissions[mid][dmP1z], x, y, z);
    else if(pick == 1) Daily_OffsetPos(playerid, ox, oy, oz, gDailyMissions[mid][dmP2x], gDailyMissions[mid][dmP2y], gDailyMissions[mid][dmP2z], x, y, z);
    else if(pick == 2) Daily_OffsetPos(playerid, ox, oy, oz, gDailyMissions[mid][dmP3x], gDailyMissions[mid][dmP3y], gDailyMissions[mid][dmP3z], x, y, z);
    else Daily_OffsetPos(playerid, ox, oy, oz, gDailyMissions[mid][dmP4x], gDailyMissions[mid][dmP4y], gDailyMissions[mid][dmP4z], x, y, z);

    new skin = gDailyMissions[mid][dmNpcSkin];
    if(skin <= 0) skin = 120;

    // cria refem (ator)
    DailyHostageAct[playerid] = CreateActor(skin, x, y, z, 0.0);
    if(DailyHostageAct[playerid] != -1)
    {
        SetActorHealth(DailyHostageAct[playerid], 100.0);
    }

    DailyP[playerid][dStep] = 0;
    Daily_SetTarget(playerid, x, y, z);
    SendClientMessageEx(playerid, COLOR_WHITE, "[Missoes] Encontre o refem e aguarde alguns segundos para retira-lo.");
    return 1;
}

stock Daily_StartEscort(playerid)
{
    new mid = DailyP[playerid][dMid];
    new model = gDailyMissions[mid][dmObjModel];
    if(model <= 0) model = 1271;

    new Float:ox = DailyP[playerid][dOrgX];
    new Float:oy = DailyP[playerid][dOrgY];
    new Float:oz = DailyP[playerid][dOrgZ];

    new Float:sx, Float:sy, Float:sz;
    Daily_OffsetPos(playerid, ox, oy, oz, gDailyMissions[mid][dmP1x], gDailyMissions[mid][dmP1y], gDailyMissions[mid][dmP1z], sx, sy, sz);

#if defined _streamer_included
        DailyEscortObj[playerid] = CreateDynamicObject(model, sx, sy, sz-0.9, 0.0, 0.0, 0.0);
#else
        DailyEscortObj[playerid] = CreateObject(model, sx, sy, sz-0.9, 0.0, 0.0, 0.0);
#endif

    DailyP[playerid][dStep] = 1; // step representa waypoint atual (P2=1, P3=2, P4=3)
    DailyP[playerid][dEscortAway] = 0;

    // checkpoint inicial (siga o alvo)
    Daily_SetTarget(playerid, sx, sy, sz);

    SendClientMessageEx(playerid, COLOR_WHITE, "[Missoes] Escolta iniciada. Fique perto do alvo ate completar a rota.");
    return 1;
}

stock Daily_StartBoss(playerid)
{
    // Boss: 3 selos (P1..P3), depois spawn boss em P4 e matar 1
    new mid = DailyP[playerid][dMid];
    DailyP[playerid][dNeed] = 1;
    DailyP[playerid][dCount] = 0;

    DailyP[playerid][dStep] = 0;
    Daily_StartInvest(playerid); // usa P1..P3 como selos
    SendClientMessageEx(playerid, COLOR_WHITE, "[Missoes] Ative o selo 1. Depois, siga para os proximos selos.");
    return 1;
}

stock Daily_StartMission(playerid, rank, mid)
{
    if(DailyP[playerid][dActive]) return 0;

    // set origin = provider position
    new provIdx = DailyP[playerid][dProvIdx];
    DailyP[playerid][dOrgX] = gDailyProvPos[provIdx][dpX];
    DailyP[playerid][dOrgY] = gDailyProvPos[provIdx][dpY];
    DailyP[playerid][dOrgZ] = gDailyProvPos[provIdx][dpZ];
    DailyP[playerid][dScale] = gDailyProvPos[provIdx][dpScale];

    DailyP[playerid][dActive] = 1;
    DailyP[playerid][dRank] = rank;
    DailyP[playerid][dMid] = mid;
    DailyP[playerid][dStep] = 0;
    DailyP[playerid][dStartTime] = gettime();
    DailyP[playerid][dHold] = 0;
    DailyP[playerid][dHoldNeed] = 0;
    DailyP[playerid][dNeed] = 0;
    DailyP[playerid][dCount] = 0;
    DailyP[playerid][dSusFlags] = 0;
    DailyP[playerid][dEscortAway] = 0;

    // travel baseline
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    DailyP[playerid][dLastX] = px;
    DailyP[playerid][dLastY] = py;
    DailyP[playerid][dLastZ] = pz;
    DailyP[playerid][dTravel] = 0.0;

    // clear resources
    DailyNpcCnt[playerid] = 0;
    for(new i=0; i<DAILY_NPC_MAX; i++) DailyNpcId[playerid][i] = -1;
    DailyEscortObj[playerid] = -1;
    DailyHostageAct[playerid] = -1;

    new t = gDailyMissions[mid][dmType];

    switch(t)
    {
        case DMT_DELIVERY:
        {
            DailyP[playerid][dStep] = 0;
            Daily_StartDelivery(playerid);
        }
        case DMT_INVEST:
        {
            DailyP[playerid][dStep] = 0;
            Daily_StartInvest(playerid);
        }
        case DMT_PATROL:
        {
            DailyP[playerid][dStep] = 0;
            Daily_StartPatrol(playerid);
        }
        case DMT_PVE:
        {
            Daily_SpawnPveActors(playerid);
        }
        case DMT_ESCORT:
        {
            Daily_StartEscort(playerid);
        }
        case DMT_RESCUE:
        {
            Daily_StartRescue(playerid);
        }
        case DMT_BOSS:
        {
            Daily_StartBoss(playerid);
        }
        default:
        {
            Daily_Fail(playerid, "tipo de missao invalido");
        }
    }

    // Mensagem inicial (contexto)
    new rname[4];
    Daily_RankName(rank, rname, sizeof(rname));
    new msg[160];
    format(msg, sizeof(msg), "[Missoes] Missao Rank %s iniciada: %s", rname, gDailyMissions[mid][dmName]);
    SendClientMessageEx(playerid, COLOR_YELLOW, msg);

    return 1;
}

// ------------------------------
// Tick runtime (CP hold, escort, reset diario, travel, etc)
// ------------------------------

forward Daily_PveFixNpcZ(playerid);
forward Daily_Tick();
public Daily_Tick()
{
    new nowKey = Daily_GetDayKey();

    for(new p=0; p<MAX_PLAYERS; p++)
    {
        if(!IsPlayerConnected(p) || IsPlayerNPC(p)) continue;

        // reset diario se mudou
        if(DailyP[p][dLoaded] && DailyP[p][dDayKey] != nowKey)
        {
            DailyP[p][dDayKey] = nowKey;
            Daily_ResetCounters(p);
            Daily_Save(p);
            SendClientMessageEx(p, COLOR_YELLOW, "[Missoes] Reset diario aplicado (00:00).");
        }

        if(!DailyP[p][dActive]) continue;

        // travel + suspeita de teleport
        new Float:px, Float:py, Float:pz;
        GetPlayerPos(p, px, py, pz);

        new Float:dx = px - DailyP[p][dLastX];
        new Float:dy = py - DailyP[p][dLastY];
        new Float:dz = pz - DailyP[p][dLastZ];

        new Float:step = floatsqroot(dx*dx + dy*dy + dz*dz);
        if(step > DAILY_MAX_STEP_DIST)
            DailyP[p][dSusFlags] |= DSUS_TELEPORT;

        DailyP[p][dTravel] += step;

        DailyP[p][dLastX] = px;
        DailyP[p][dLastY] = py;
        DailyP[p][dLastZ] = pz;

        new mid = DailyP[p][dMid];
        new t = gDailyMissions[mid][dmType];

        // ESCORT: mover objeto e validar distancia
        if(t == DMT_ESCORT)
        {
            if(DailyEscortObj[p] != -1)
            {
                new Float:ox = DailyP[p][dOrgX];
                new Float:oy = DailyP[p][dOrgY];
                new Float:oz = DailyP[p][dOrgZ];

                // waypoint atual
                new wp = DailyP[p][dStep];

                new Float:tx, Float:ty, Float:tz;
                if(wp == 1) Daily_OffsetPos(p, ox, oy, oz, gDailyMissions[mid][dmP2x], gDailyMissions[mid][dmP2y], gDailyMissions[mid][dmP2z], tx, ty, tz);
                else if(wp == 2) Daily_OffsetPos(p, ox, oy, oz, gDailyMissions[mid][dmP3x], gDailyMissions[mid][dmP3y], gDailyMissions[mid][dmP3z], tx, ty, tz);
                else if(wp == 3) Daily_OffsetPos(p, ox, oy, oz, gDailyMissions[mid][dmP4x], gDailyMissions[mid][dmP4y], gDailyMissions[mid][dmP4z], tx, ty, tz);
                else
                {
                    Daily_Complete(p);
                    continue;
                }

                // pos atual do objeto
                new Float:cx, Float:cy, Float:cz;
#if defined _streamer_included
                    GetDynamicObjectPos(DailyEscortObj[p], cx, cy, cz);
#else
                    GetObjectPos(DailyEscortObj[p], cx, cy, cz);
#endif

                new Float:odx = tx - cx;
                new Float:ody = ty - cy;
                new Float:odist = floatsqroot(odx*odx + ody*ody);

                // move pequeno passo por tick
                if(odist > 1.5)
                {
                    new Float:stepObj = 4.0;
                    new Float:nx = cx + (odx / odist) * stepObj;
                    new Float:ny = cy + (ody / odist) * stepObj;
                    new Float:nz = cz;

#if defined _streamer_included
                        SetDynamicObjectPos(DailyEscortObj[p], nx, ny, nz);
#else
                        SetObjectPos(DailyEscortObj[p], nx, ny, nz);
#endif

                    Daily_SetTarget(p, nx, ny, nz); // checkpoint segue o alvo
                }
                else
                {
                    // chegou no waypoint, avancar
                    DailyP[p][dStep] += 1;
                }

                // valida distancia do player ao objeto
                new Float:distP = floatsqroot((px-cx)*(px-cx) + (py-cy)*(py-cy) + (pz-cz)*(pz-cz));
                new Float:maxDist = Daily_EscortMaxDist(DailyP[p][dRank]);

                if(distP > maxDist)
                {
                    DailyP[p][dEscortAway] += 1;
                    if(DailyP[p][dEscortAway] >= DAILY_ESCORT_GRACE_SEC)
                    {
                        Daily_Fail(p, "voce se afastou demais da escolta");
                        continue;
                    }
                }
                else
                {
                    DailyP[p][dEscortAway] = 0;
                }
            }
            continue;
        }

        // PVE/BOSS: progress via OnPlayerGiveDamageActor; aqui so mantem CP visivel
        if(t == DMT_PVE)
        {
            continue;
        }

        // RESCUE: step0 encontra refem; step1 entrega no safe
        if(t == DMT_RESCUE)
        {
            // step 0 ou 1 usam checkpoint normal
            // hold process abaixo
        }

        // BOSS: step0..2 selos via CP; step3 spawn boss e matar via damage actor
        if(t == DMT_BOSS)
        {
            // se step >=3, espera kill do boss
            if(DailyP[p][dStep] >= 3)
                continue;
        }

        // Hold checkpoint
        new Float:tx = DailyP[p][dTgtX];
        new Float:ty = DailyP[p][dTgtY];
        new Float:tz = DailyP[p][dTgtZ];

        new Float:dist = floatsqroot((px-tx)*(px-tx) + (py-ty)*(py-ty) + (pz-tz)*(pz-tz));
        if(dist <= DAILY_CP_RADIUS)
        {
            DailyP[p][dHold] += 1;
            if(DailyP[p][dHold] >= DailyP[p][dHoldNeed])
            {
                // avancar conforme tipo
                if(t == DMT_DELIVERY)
                {
                    DailyP[p][dStep] += 1;
                    Daily_StartDelivery(p);
                }
                else if(t == DMT_INVEST)
                {
                    DailyP[p][dStep] += 1;
                    Daily_StartInvest(p);
                }
                else if(t == DMT_PATROL)
                {
                    DailyP[p][dStep] += 1;
                    Daily_StartPatrol(p);
                }
                else if(t == DMT_RESCUE)
                {
                    new mid2 = DailyP[p][dMid];
                    new Float:ox2 = DailyP[p][dOrgX];
                    new Float:oy2 = DailyP[p][dOrgY];
                    new Float:oz2 = DailyP[p][dOrgZ];

                    if(DailyP[p][dStep] == 0)
                    {
                        // retirou refem
                        if(DailyHostageAct[p] != -1)
                        {
                            DestroyActor(DailyHostageAct[p]);
                            DailyHostageAct[p] = -1;
                        }
                        DailyP[p][dStep] = 1;

                        // safe point
                        new Float:sx, Float:sy, Float:sz;
                        Daily_OffsetPos(p, ox2, oy2, oz2, gDailyMissions[mid2][dmAreaX], gDailyMissions[mid2][dmAreaY], gDailyMissions[mid2][dmAreaZ], sx, sy, sz);
                        Daily_SetTarget(p, sx, sy, sz);
                        SendClientMessageEx(p, COLOR_WHITE, "[Missoes] Refem seguro. Agora leve ao ponto seguro e aguarde confirmacao.");
                    }
                    else
                    {
                        Daily_Complete(p);
                    }
                }
                else if(t == DMT_BOSS)
                {
                    // selo concluido
                    DailyP[p][dStep] += 1;
                    if(DailyP[p][dStep] <= 2)
                    {
                        Daily_StartInvest(p); // proximo selo
                        new stepn = DailyP[p][dStep] + 1;
                        new msg2[80];
                        format(msg2, sizeof(msg2), "[Missoes] Ative o selo %d.", stepn);
                        SendClientMessageEx(p, COLOR_WHITE, msg2);
                    }
                    else
                    {
                        // spawn boss em P4
                        new Float:ox3 = DailyP[p][dOrgX];
                        new Float:oy3 = DailyP[p][dOrgY];
                        new Float:oz3 = DailyP[p][dOrgZ];

                        new Float:bx, Float:by, Float:bz;
                        Daily_OffsetPos(p, ox3, oy3, oz3, gDailyMissions[mid][dmP4x], gDailyMissions[mid][dmP4y], gDailyMissions[mid][dmP4z], bx, by, bz);

                        new skin = gDailyMissions[mid][dmNpcSkin];
                        if(skin <= 0) skin = 287;

                        new actorid = CreateActor(skin, bx, by, bz, 0.0);
                        if(actorid >= 0 && actorid < DAILY_ACT_MAX)
                        {
                            SetActorHealth(actorid, 300.0);
                            DailyActOwner[actorid] = p;
                            DailyActMid[actorid] = mid;
                            DailyActAlive[actorid] = 1;
                            Daily_AddActorForPlayer(p, actorid);

                            DailyP[p][dStep] = 3; // combate
                            Daily_SetTarget(p, bx, by, bz);

                            SendClientMessageEx(p, COLOR_YELLOW, "[Missoes] Alvo principal localizado. Elimine-o.");
                        }
                        else
                        {
                            Daily_Fail(p, "nao foi possivel criar o boss");
                        }
                    }
                }
            }
        }
        else
        {
            DailyP[p][dHold] = 0;
        }
    }
    return 1;
}

// ------------------------------
// Callbacks de integracao
// ------------------------------
stock Daily_Init()
{
    // init mapping
    for(new i=0; i<DAILY_ACT_MAX; i++)
    {
        DailyActOwner[i] = -1;
        DailyActMid[i] = -1;
        DailyActAlive[i] = 0;
    }

    // init mapping (AI combat NPC slots)
    for(new i=0; i<MAXIMO_NPCS_COMBATE; i++)
    {
        DailyAiOwner[i] = -1;
        DailyAiMid[i] = -1;
        DailyAiAlive[i] = false;
    }

    DailyCfg_InitProviders();
    Daily_CreateProviders();

    if(DailyTickTimer == -1)
        DailyTickTimer = SetTimer("Daily_Tick", DAILY_TICK_MS, true);

    Daily_Log("[SYSTEM] Daily mission system initialized.");
    return 1;
}



// ==========================================================
// Daily UI - PlayerTextDraws sob demanda
// Motivo: economizar PTD para nao quebrar HUD/Skillbar.
// ==========================================================
stock Daily_UIReset(playerid)
{
    for(new i = 0; i < DAILY_PTD_MAX; i++) gDailyPTD[playerid][i] = PTD_INVALID;
    for(new i = 0; i < DAILY_RANK_MAX; i++)
    {
        gDailyRankPTD[playerid][i][0] = PTD_INVALID;
        gDailyRankPTD[playerid][i][1] = PTD_INVALID;
    }
    return 1;
}

stock Daily_UIEnsure(playerid)
{
    if(gDailyPTD[playerid][PTD_TITLE] == PTD_INVALID)
    {
        Daily_UICreate(playerid);
    }
    return 1;
}
stock Daily_OnConnect(playerid)
{
    // init state
    for(new i=0; i<eDailyP; i++) DailyP[playerid][i] = 0;
    DailyP[playerid][dUI] = DUI_NONE;
    DailyP[playerid][dProvIdx] = -1;
    DailyP[playerid][dOfferRank] = -1;
    DailyP[playerid][dOfferMid] = -1;

    DailyP[playerid][dActive] = 0;
    DailyP[playerid][dRank] = -1;
    DailyP[playerid][dMid] = -1;

    DailyNpcCnt[playerid] = 0;
    for(new i2=0; i2<DAILY_NPC_MAX; i2++) DailyNpcId[playerid][i2] = -1;
    DailyEscortObj[playerid] = -1;
    DailyHostageAct[playerid] = -1;

    DailyP[playerid][dForceUnlock] = -1;

    Daily_Load(playerid);
    Daily_UICreate(playerid);
    return 1;
}

stock Daily_OnDisconnect(playerid, reason)
{
    if(DailyP[playerid][dActive] && DAILY_FAIL_ON_QUIT)
        Daily_Fail(playerid, "desconectou durante a missao");

    Daily_UIHideAll(playerid);
    CancelSelectTextDraw(playerid);

    Daily_StopMission(playerid);
    Daily_Save(playerid);
    return 1;
}

stock Daily_OnDeath(playerid, killerid, reason)
{
    if(DailyP[playerid][dActive] && DAILY_FAIL_ON_DEATH)
        Daily_Fail(playerid, "morreu durante a missao");
    return 1;
}

stock Daily_OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    #pragma unused inputtext
    if(dialogid != DIALOG_DAILY_RANK) return 0;

    if(!response) return 1;
    if(listitem < 0 || listitem >= DailyDlgRankCount[playerid]) return 1;

    new rank = DailyDlgRankMap[playerid][listitem];

    new why[64];
    if(!Daily_CanTakeRank(playerid, rank, why, sizeof(why)))
    {
        SendClientMessage(playerid, 0xFFFFFFFF, "[Missoes] Voce ainda não pode pegar esse Rank.");
        Daily_OpenRankDialog(playerid);
        return 1;
    }

    // Gera uma missao do rank escolhido e abre o TXD (oferta) com a descrição.
    new mid = Daily_PickMission(rank);
    if(mid == -1)
    {
        SendClientMessage(playerid, 0xFFFFFFFF, "[Missoes] Nao há missões disponíveis nesse Rank no momento.");
        Daily_OpenRankDialog(playerid);
        return 1;
    }

    Daily_UIShowOffer(playerid, rank, mid);
    return 1;
}

stock Daily_OnKey(playerid, newkeys, oldkeys)
{
    // Abrir Quadro de Missoes com a tecla “R” (no SHRP, normalmente KEY_CTRL_BACK).
    if(!PRESSED(newkeys, KEY_CTRL_BACK)) return 0;

    new prov = Daily_FindNearProvider(playerid);
    if(prov == -1) return 0;

    // Antes de concluir a Academia / escolher Clã, NÃO consome a tecla
    // (assim o sistema da missao da academia continua funcionando no mesmo NPC).
    if(!Daily_AcaIsDone(playerid)) return 0;

    // Se ja estiver em missao diaria ativa, consome a tecla e avisa.
    if(DailyP[playerid][dActive])
    {
        SendClientMessage(playerid, 0xFFFFFFFF, "[Missoes] Voce ja está em uma missao diaria. Finalize ou cancele antes de pegar outra.");
        return 1;
    }

    DailyP[playerid][dProvIdx] = prov;

    // 1) Abre o Quadro (Rank) SEM TXD
    // 2) Após escolher o Rank, abre o TXD com a missao escrita (oferta).
    Daily_OpenRankDialog(playerid);
    return 1;
}

// ==========================================================
// Compat: chamadas do sistema antigo (shrp_missoes_normal.pwn)
// ==========================================================
// Tenta abrir o Quadro de Missoes Diarias se o player estiver perto de um provedor.
// Retorna 1 se consumiu (abriu/avisou); 0 se nao e ponto de diaria (deixa outro sistema lidar).
stock Daily_TryOpenBoard(playerid)
{
    new prov = Daily_FindNearProvider(playerid);
    if(prov == -1) return 0;

    // Antes de concluir a Academia / escolher Cla, nao consome.
    if(!Daily_AcaIsDone(playerid)) return 0;

    // Se ja estiver em missao diaria ativa, consome e avisa.
    if(DailyP[playerid][dActive])
    {
        SendClientMessage(playerid, 0xFFFFFFFF, "[Missoes] Voce ja esta em uma missao diaria. Finalize ou cancele antes de pegar outra.");
        return 1;
    }

    DailyP[playerid][dProvIdx] = prov;
    Daily_OpenRankDialog(playerid);
    return 1;
}



stock Daily_OnClickPTD(playerid, PlayerText:ptd)
{
    if(DailyP[playerid][dUI] == DUI_NONE) return 0;

    // close/back
    if(ptd == gDailyPTD[playerid][PTD_BTN_BG] || ptd == gDailyPTD[playerid][PTD_BTN_TX])
    {
        if(DailyP[playerid][dUI] == DUI_OFFER)
        {
            Daily_UIExit(playerid, true);
        }
        else
        {
            Daily_UIExit(playerid, false);
        }
        return 1;
    }

    // offer accept/decline
    if(DailyP[playerid][dUI] == DUI_OFFER)
    {
        if(ptd == gDailyOfferPTD[playerid][DOF_ACEITAR])
        {
            Daily_UIExit(playerid, false);

            new rank = DailyP[playerid][dOfferRank];
            new mid  = DailyP[playerid][dOfferMid];

            // valida de novo
            new why[64];
            if(!Daily_CanTakeRank(playerid, rank, why, sizeof(why)))
            {
                new msg[96];
                format(msg, sizeof(msg), "[Missoes] Nao foi possivel iniciar: %s", why);
                SendClientMessageEx(playerid, COLOR_RED, msg);
                return 1;
            }

            Daily_StartMission(playerid, rank, mid);
            return 1;
        }
        if(ptd == gDailyOfferPTD[playerid][DOF_RECUSAR])
        {
            Daily_UIExit(playerid, true);
            return 1;
        }
        return 1;
    }

    // rank select
    if(DailyP[playerid][dUI] == DUI_LIST)
    {
        for(new r=0; r<DR_MAX; r++)
        {
            if(ptd == gDailyPTD[playerid][PTD_R_BG(r)] || ptd == gDailyPTD[playerid][PTD_R_TX(r)] || ptd == gDailyPTD[playerid][PTD_R_INF(r)])
            {
                new why[64];
                if(!Daily_CanTakeRank(playerid, r, why, sizeof(why)))
                {
                    new msg[110];
                    format(msg, sizeof(msg), "[Missoes] Rank bloqueado: %s", why);
                    SendClientMessageEx(playerid, COLOR_RED, msg);
                    return 1;
                }

                new mid = Daily_PickMission(r);
                if(mid == -1)
                {
                    SendClientMessageEx(playerid, COLOR_RED, "[Missoes] Nao ha missoes configuradas para este rank.");
                    return 1;
                }

                Daily_UIShowOffer(playerid, r, mid);
                return 1;
            }
        }
    }
    return 1;
}


// ------------------------------------------------
// Callback (runtime) vindo do shinobi_ai quando um NPC de combate morre.
// O shinobi_ai chama via CallLocalFunction se esta func existir.
// ------------------------------------------------
forward Daily_OnCombatNpcDead(killerid, npcid, aislot);
public Daily_OnCombatNpcDead(killerid, npcid, aislot)
{
    if(killerid < 0 || killerid >= MAX_PLAYERS) return 1;

    // precisa estar em missao ativa
    if(!DailyP[killerid][dActive]) return 1;

    new mid = DailyP[killerid][dMid];
    new t = gDailyMissions[mid][dmType];

    // por enquanto: conta apenas PVE (DMT_PVE)
    if(t != DMT_PVE) return 1;

    if(aislot < 0 || aislot >= MAXIMO_NPCS_COMBATE) return 1;
    if(!DailyAiAlive[aislot]) return 1;

    // valida dono + missao
    if(DailyAiOwner[aislot] != killerid) return 1;
    if(DailyAiMid[aislot] != mid) return 1;

    DailyAiAlive[aislot] = false;

    DailyP[killerid][dCount] += 1;

    if(DailyP[killerid][dCount] >= DailyP[killerid][dNeed])
    {
        Daily_Complete(killerid);
    }
    return 1;
}

stock Daily_OnGiveDmgAct(playerid, actorid, Float:amount, weaponid, bodypart)
{
    if(actorid < 0 || actorid >= DAILY_ACT_MAX) return 1;
    if(!DailyActAlive[actorid]) return 1;

    // valida dono
    if(DailyActOwner[actorid] != playerid) return 1;

    // precisa estar em missao e ser a missao certa
    if(!DailyP[playerid][dActive]) return 1;
    if(DailyActMid[actorid] != DailyP[playerid][dMid]) return 1;

    new Float:hp;
    GetActorHealth(actorid, hp);
    if(hp <= 0.0)
    {
        DailyActAlive[actorid] = 0;

        // incrementa contagem
        DailyP[playerid][dCount] += 1;

        new mid = DailyP[playerid][dMid];
        new t = gDailyMissions[mid][dmType];

        // PVE: completa quando matar todos
        if(t == DMT_PVE)
        {
            if(DailyP[playerid][dCount] >= DailyP[playerid][dNeed])
            {
                Daily_Complete(playerid);
            }
        }
        // BOSS: precisa matar 1
        else if(t == DMT_BOSS)
        {
            if(DailyP[playerid][dStep] >= 3 && DailyP[playerid][dCount] >= 1)
            {
                Daily_Complete(playerid);
            }
        }
    }
    return 1;
}

// ------------------------------
// Status helper
// ------------------------------
stock Daily_ShowStatus(playerid)
{
    new out[210];
    format(out, sizeof(out),
        "[Missoes] Diarias: E %d/%d | D %d/%d | C %d/%d | B %d/%d | A %d/%d | S %d/%d",
        DailyP[playerid][dDoneE], gDailyLimit[DR_E],
        DailyP[playerid][dDoneD], gDailyLimit[DR_D],
        DailyP[playerid][dDoneC], gDailyLimit[DR_C],
        DailyP[playerid][dDoneB], gDailyLimit[DR_B],
        DailyP[playerid][dDoneA], gDailyLimit[DR_A],
        DailyP[playerid][dDoneS], gDailyLimit[DR_S]
    );
    SendClientMessageEx(playerid, COLOR_YELLOW, out);
    return 1;
}

#if defined _ZCMD_INCLUDED
// ------------------------------
// Admin / debug commands
// ------------------------------
CMD:dailydebug(playerid, params[])
{
    if(!Daily_IsAdmin(playerid)) return SendClientMessageEx(playerid, COLOR_RED, "Voce nao tem permissao.");

    new msg[220];
    format(msg, sizeof(msg), "[DailyDebug] Active=%d Rank=%d Mid=%d Step=%d Hold=%d/%d Need=%d Cnt=%d Sus=%d Dist=%.1f",
        DailyP[playerid][dActive], DailyP[playerid][dRank], DailyP[playerid][dMid], DailyP[playerid][dStep],
        DailyP[playerid][dHold], DailyP[playerid][dHoldNeed], DailyP[playerid][dNeed], DailyP[playerid][dCount],
        DailyP[playerid][dSusFlags], DailyP[playerid][dTravel]
    );
    SendClientMessageEx(playerid, COLOR_WHITE, msg);
    Daily_ShowStatus(playerid);
    return 1;
}

CMD:dailyreset(playerid, params[])
{
    if(!Daily_IsAdmin(playerid)) return SendClientMessageEx(playerid, COLOR_RED, "Voce nao tem permissao.");

#if !defined sscanf
        SendClientMessageEx(playerid, COLOR_RED, "sscanf nao esta incluso. Use /dailyreset sem parametros (reset em voce) ou instale sscanf2.");
        Daily_ResetCounters(playerid);
        DailyP[playerid][dDayKey] = Daily_GetDayKey();
        Daily_Save(playerid);
        return 1;
#else
        new target = playerid;
        if(params[0] != '\0')
        {
            if(sscanf(params, "u", target)) return SendClientMessageEx(playerid, COLOR_WHITE, "Uso: /dailyreset [playerid]");
        }

        Daily_ResetCounters(target);
        DailyP[target][dDayKey] = Daily_GetDayKey();
        Daily_Save(target);

        SendClientMessageEx(playerid, COLOR_GREEN, "[Daily] Reset aplicado.");
        if(target != playerid) SendClientMessageEx(target, COLOR_YELLOW, "[Missoes] Seu diario foi resetado por um admin.");
        return 1;
#endif
}

CMD:dailysetrank(playerid, params[])
{
    if(!Daily_IsAdmin(playerid)) return SendClientMessageEx(playerid, COLOR_RED, "Voce nao tem permissao.");

#if !defined sscanf
        return SendClientMessageEx(playerid, COLOR_RED, "sscanf nao esta incluso. Instale sscanf2 para usar /dailysetrank.");
#else
        new target;
        new rchar[8];
        if(sscanf(params, "us[8]", target, rchar))
            return SendClientMessageEx(playerid, COLOR_WHITE, "Uso: /dailysetrank [playerid] [E/D/C/B/A/S/off]");

        if(!IsPlayerConnected(target)) return SendClientMessageEx(playerid, COLOR_RED, "Player offline.");

        if(!strcmp(rchar, "off", true))
        {
            DailyP[target][dForceUnlock] = -1;
            SendClientMessageEx(playerid, COLOR_GREEN, "[Daily] Debug unlock desligado.");
            return 1;
        }

        new rank = -1;
        if(!strcmp(rchar, "E", true)) rank = DR_E;
        else if(!strcmp(rchar, "D", true)) rank = DR_D;
        else if(!strcmp(rchar, "C", true)) rank = DR_C;
        else if(!strcmp(rchar, "B", true)) rank = DR_B;
        else if(!strcmp(rchar, "A", true)) rank = DR_A;
        else if(!strcmp(rchar, "S", true)) rank = DR_S;

        if(rank == -1) return SendClientMessageEx(playerid, COLOR_RED, "Rank invalido. Use E/D/C/B/A/S/off.");

        DailyP[target][dForceUnlock] = rank;
        SendClientMessageEx(playerid, COLOR_GREEN, "[Daily] Debug unlock aplicado.");
        return 1;
#endif
}

// ==========================================================
// ESC / CancelSelectTextDraw handler
// ==========================================================
stock Daily_OnCancelTextDraw(playerid)
{
    if(DailyP[playerid][dUI] == DUI_NONE) return 0;
    Daily_UIExit(playerid, false);
    return 1;
}

#if defined _y_hooks_included
hook OnPlayerCancelTextDraw(playerid)
{
    return Daily_OnCancelTextDraw(playerid);
}
#endif



public Daily_PveFixNpcZ(playerid)
{
    if(playerid < 0 || playerid >= MAX_PLAYERS) return 0;
    if(!IsPlayerConnected(playerid))
    {
        if(DailyPveFixTmr[playerid] != -1) { KillTimer(DailyPveFixTmr[playerid]); DailyPveFixTmr[playerid] = -1; }
        return 0;
    }

    new mid = DailyP[playerid][dMid];
    // only for mission "Treino: Derrubar Bonecos" (avoids extra weight)
    if(mid < 0 || !Daily_IsBonecosMission(mid))
    {
        if(DailyPveFixTmr[playerid] != -1) { KillTimer(DailyPveFixTmr[playerid]); DailyPveFixTmr[playerid] = -1; }
        return 0;
    }

    // if player is not in an active mission, stop
    if(DailyP[playerid][dActive] == 0)
    {
        if(DailyPveFixTmr[playerid] != -1) { KillTimer(DailyPveFixTmr[playerid]); DailyPveFixTmr[playerid] = -1; }
        return 0;
    }

    // Some custom maps/streamed objects may NOT collide/stream for NPCs, making them fall below the floor.
    // For a few seconds after spawn, hold the NPC minimum Z so it does not sink underground.
    // X/Y remain free (NPC can move), we only prevent Z from dropping too low.
    new now = GetTickCount();
    new bool:any = false;

    for(new i=0; i<DailyNpcCnt[playerid]; i++)
    {
        new tag = DailyNpcId[playerid][i];
        if(tag < DAILY_NPC_TAG_AISLOT) continue;

        new aislot = tag - DAILY_NPC_TAG_AISLOT;
        if(aislot < 0 || aislot >= MAXIMO_NPCS_COMBATE) continue;
        if(!DailyAiAlive[aislot]) continue;

        if(DailyAiFixUntilTick[aislot] == 0 || now > DailyAiFixUntilTick[aislot]) continue;
        any = true;

        new npcid = INVALID_PLAYER_ID;
        if(funcidx("SHRP_NpcGetId") != -1) npcid = CallLocalFunction("SHRP_NpcGetId", "i", aislot);
        if(npcid == INVALID_PLAYER_ID || !IsPlayerConnected(npcid)) continue;

        new Float:px, Float:py, Float:pz;
        GetPlayerPos(npcid, px, py, pz);

        if(pz < (DailyAiMinZ[aislot] - 0.35))
        {
            SetPlayerPos(npcid, px, py, DailyAiMinZ[aislot]);
        }

        // keep same VW/Interior as the mission owner (avoid "vanishing")
        SetPlayerVirtualWorld(npcid, GetPlayerVirtualWorld(playerid));
        SetPlayerInterior(npcid, GetPlayerInterior(playerid));
    }

    if(!any)
    {
        if(DailyPveFixTmr[playerid] != -1) { KillTimer(DailyPveFixTmr[playerid]); DailyPveFixTmr[playerid] = -1; }
    }
    return 1;
}
// =====================================================
// DEBUG POS / NPC POS (Daily PVE)
// Cole dentro do diarias_rank_txd.pwn
// Requer: CMD: (zcmd/ysf cmd), sscanf, a_samp
// Permissão: troque IsPlayerAdmin por sua checagem se quiser
// =====================================================

CMD:pos(playerid, params[])
{
    #pragma unused params
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, -1, "Sem permissao.");

    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    new msg[160];
    format(msg, sizeof msg, "[POS] %.4f, %.4f, %.4f | ang %.2f | vw %d | int %d",
        x, y, z, a, GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid));
    SendClientMessage(playerid, -1, msg);
    return 1;
}

CMD:npcloc(playerid, params[])
{
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, -1, "Sem permissao.");

    new nid;
    if(sscanf(params, "i", nid)) return SendClientMessage(playerid, -1, "Use: /npcloc <npcid>");

    if(!IsPlayerConnected(nid) || !IsPlayerNPC(nid))
        return SendClientMessage(playerid, -1, "Esse ID nao e um NPC conectado.");

    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(nid, x, y, z);
    GetPlayerFacingAngle(nid, a);

    new msg[180];
    format(msg, sizeof msg, "[NPC %d] %.4f, %.4f, %.4f | ang %.2f | vw %d | int %d",
        nid, x, y, z, a, GetPlayerVirtualWorld(nid), GetPlayerInterior(nid));
    SendClientMessage(playerid, -1, msg);
    return 1;
}

CMD:dailynpcs(playerid, params[])
{
    #pragma unused params
    if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, -1, "Sem permissao.");

    new msg[200];
    format(msg, sizeof msg, "[DailyNPCs] cnt=%d (vw=%d int=%d)",
        DailyNpcCnt[playerid], GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid));
    SendClientMessage(playerid, -1, msg);

    for(new i=0; i<DailyNpcCnt[playerid]; i++)
    {
        new nid = DailyNpcId[playerid][i];
        if(nid == INVALID_PLAYER_ID || !IsPlayerConnected(nid)) continue;

        new Float:x, Float:y, Float:z, Float:a;
        GetPlayerPos(nid, x, y, z);
        GetPlayerFacingAngle(nid, a);

        format(msg, sizeof msg,
            " - idx=%d id=%d npc=%d pos=%.4f %.4f %.4f ang=%.1f vw=%d int=%d",
            i, nid, IsPlayerNPC(nid),
            x, y, z, a,
            GetPlayerVirtualWorld(nid), GetPlayerInterior(nid)
        );
        SendClientMessage(playerid, -1, msg);
    }
    return 1;
}
