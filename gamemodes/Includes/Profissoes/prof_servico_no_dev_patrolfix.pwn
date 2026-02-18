#if defined _PROF_SERVICO_INCLUDED
    #endinput
#endif
#define _PROF_SERVICO_INCLUDED

// ============================================================
// SHRP - Profissoes Ativas (Hospital / Policia) - ProfServ
// Arquivo: Includes/Profissoes/prof_servico.pwn (ANSI friendly)
// SA-MP 0.3.DL friendly
//
// OBJETIVO:
// - Remover farm AFK de ponto (salario por minuto so com atividade).
// - Ganho por acoes reais: chamados, reanimar, prender, patrulhar.
// - Chamados por vila (Iwa=1 / Kiri=3) e somente on-duty.
//
// INTEGRACAO (ver patch no SHRP.pwn):
// - Chamar ProfServ_OnDutyToggle ao bater/sair do ponto (HP/DP)
// - Chamar ProfServ_OnMedicReanimar dentro de ReanimarAnimm
// - Chamar ProfServ_OnPolicePrender dentro do /prender (momento que prende)
// - Chamar ProfServ_OnPlayerDisconnect em OnPlayerDisconnect
// - SetTimer("ProfServ_Tick", 5000, true) em OnGameModeInit
// - No PagamentoHP/DP, pagar somente se ProfServ_IsSalaryActive() retornar true
// - Em OnDialogResponse: if(ProfServ_OnDialog(...)) return 1;
//
// ------------------------------------------------------------
// OBS:
// - Este include usa MapIcon (nao usa checkpoint) para evitar conflitos.
// - Coordenadas de patrulha / NPC chamados estao abaixo (AJUSTE se quiser).
// ============================================================

#include <a_samp>
#include <sscanf2>

// ====== Constantes gerais
#define PROF_NONE               (0)
#define PROF_HP                 (1)
#define PROF_DP                 (2)
#define PROF_MAX                (3)  // 0..2

#define PROF_ALLOWED_VILA_IWA   (1)
#define PROF_ALLOWED_VILA_KIRI  (3)

#define PROF_ACTIVITY_WINDOW    (600)   // 10 minutos (em segundos)
#define PROF_CALL_EXPIRE        (900)   // 15 minutos
#define PROF_CALL_COOLDOWN      (300)   // 5 minutos
#define PROF_SAME_TARGET_WINDOW (180)   // 180s
#define PROF_NPC_RESOLVE_DIST   (6.0)

// MapIcon indexes (0..99) por player
#define PROF_ICON_CALL          (90)
#define PROF_ICON_PATROL        (91)

// MapIcon types (GTA blips). Ajuste se quiser.
#define PROF_BLIP_HOSPITAL      (22) // skull (placeholder). Troque se quiser.
#define PROF_BLIP_POLICE        (30) // police station (placeholder).
#define PROF_BLIP_PATROL        (56) // flag (placeholder).

// Dialog IDs (escolha faixa alta para nao conflitar)
#define DIALOG_PROFSERV_MAIN    (19120)
#define DIALOG_PROFSERV_CALLS   (19121)
#define DIALOG_PROFSERV_INFO    (19122)

// Max chamados simultaneos (otimizacao / limite)
#define PROF_MAX_CALLS          (64)

// ====== Prototipos para evitar warning 208
forward ProfServ_Tick();
stock ProfServ_InitAll();
stock ProfServ_OnDutyToggle(playerid, prof, bool:onDuty);
stock ProfServ_OnMedicReanimar(medicid, patientid);
stock ProfServ_OnPolicePrender(policeid, suspectid, jailMinutes);
stock ProfServ_OnPlayerDisconnect(playerid);
stock bool:ProfServ_IsSalaryActive(playerid, prof);

stock bool:ProfServ_OnDialog(playerid, dialogid, response, listitem, inputtext[]);

// ====== Coordenadas (AJUSTE AQUI SE QUISER)
// Centro de referencia (ponto de delegacia / hospital) ja existe no seu GM:
// - Iwa Hospital:   -1646.4414, 1896.8406, 6.3456
// - Iwa Delegacia:  -1406.4342, 1564.0348, 7.8914
// - Kiri Hospital:  2829.3145, -2607.7334, 39.8807
// - Kiri Delegacia: 2303.8323, -2262.5166, 30.6717
//
// A patrulha gera 5 pontos a partir destes arrays.
// Se algum ponto cair em lugar ruim no seu mapa, edite as coords.

#define PROF_PTS_IWA    (8)
#define PROF_PTS_KIRI   (8)

#define PROFSERV_PATROL_STEPS   (5)
// PROFSERV_PTS_MAX precisa ser expressao CONSTANTE para usar em tamanho de array.
// O Pawn (0.3.DL) nem sempre aceita operador ternario (?:) como constante em tamanho de array.
// Por isso calculamos com #if/#else.
#if PROF_PTS_IWA > PROF_PTS_KIRI
    #define PROFSERV_PTS_MAX   (PROF_PTS_IWA)
#else
    #define PROFSERV_PTS_MAX   (PROF_PTS_KIRI)
#endif

new const Float:gProfPatrolPts_Iwa[PROF_PTS_IWA][3] =
{
    {-1406.43, 1564.03,  7.89},  // delegacia
    {-1384.53, 1543.31, 24.99},  // prisao (entrada)
    {-1646.44, 1896.84,  6.34},  // hospital
    {-1588.00, 1820.00,  6.50},  // area proxima
    {-1510.00, 1700.00,  7.50},
    {-1450.00, 1650.00,  7.50},
    {-1550.00, 1600.00,  7.50},
    {-1600.00, 1750.00,  7.50}
};

new const Float:gProfPatrolPts_Kiri[PROF_PTS_KIRI][3] =
{
    {2303.83, -2262.51, 30.67},  // delegacia
    {2333.76, -2265.74, 47.77},  // prisao (entrada)
    {2829.31, -2607.73, 39.88},  // hospital
    {2750.00, -2550.00, 39.80},
    {2650.00, -2500.00, 39.60},
    {2550.00, -2400.00, 35.00},
    {2400.00, -2320.00, 31.00},
    {2460.00, -2380.00, 31.00}
};

// Pontos de spawn para chamados NPC (actors) - reutiliza alguns pontos de patrulha
new const Float:gProfNpcPts_Iwa[4][3] =
{
    {-1588.00, 1820.00, 6.50},
    {-1510.00, 1700.00, 7.50},
    {-1450.00, 1650.00, 7.50},
    {-1600.00, 1750.00, 7.50}
};

new const Float:gProfNpcPts_Kiri[4][3] =
{
    {2750.00, -2550.00, 39.80},
    {2650.00, -2500.00, 39.60},
    {2550.00, -2400.00, 35.00},
    {2460.00, -2380.00, 31.00}
};

// ====== Estruturas / estados
enum eProfCall
{
    bool:pcActive,
    pcProf,                 // PROF_HP / PROF_DP
    pcVila,                 // 1 ou 3 (por enquanto)
    bool:pcIsNPC,            // true = actor / false = player
    pcCreatedAt,
    pcExpiresAt,
    pcRequester,            // playerid que abriu (ou INVALID_PLAYER_ID para NPC gerado)
    pcTarget,               // player alvo (para PLAYER calls) ou INVALID_PLAYER_ID
    pcAcceptedBy,           // playerid que aceitou (ou INVALID_PLAYER_ID)
    pcActorId,              // actor id (para NPC) ou -1
    Float:pcX,
    Float:pcY,
    Float:pcZ,
    pcReason[64]
};
new gProfCalls[PROF_MAX_CALLS][eProfCall];

// per player
new bool:gProfOnDuty[MAX_PLAYERS][PROF_MAX];
new gProfLastAction[MAX_PLAYERS][PROF_MAX];
new bool:gProfSalaryActive[MAX_PLAYERS][PROF_MAX];

new gProfAcceptedCall[MAX_PLAYERS][PROF_MAX];      // idx ou -1
new gProfLastCreateCall[MAX_PLAYERS][PROF_MAX];    // cooldown /socorro /denunciar

new gProfLastTargetId[MAX_PLAYERS][PROF_MAX];
new gProfLastTargetTime[MAX_PLAYERS][PROF_MAX];

// dialog mapping (lista de chamados)
#define PROF_DLG_MAXLIST (20)
new gProfDlgCallMap[MAX_PLAYERS][PROF_DLG_MAXLIST]; // listitem -> call idx
new gProfDlgCallCount[MAX_PLAYERS];

// patrulha
new bool:gProfPatrolActive[MAX_PLAYERS][PROF_MAX];
new gProfPatrolVila[MAX_PLAYERS][PROF_MAX];
new gProfPatrolStep[MAX_PLAYERS][PROF_MAX]; // 0..4
new gProfPatrolPointIdx[MAX_PLAYERS][PROF_MAX][5]; // idx dentro do array de pontos

// ECO_MAX_VILAS vem do eco_core.pwn. Se nao estiver definido (por algum motivo), cria fallback.
#if !defined ECO_MAX_VILAS
    #define ECO_MAX_VILAS (6)
#endif

// cooldown de geracao de NPC por vila/prof
// [prof][vila] - usamos index direto do ID da vila (1..ECO_MAX_VILAS)
new gProfLastNpcSpawn[PROF_MAX][ECO_MAX_VILAS + 1];

// ============================================================
// Helpers basicos
// ============================================================

static stock bool:ProfServ_IsAllowedVila(vila)
{
    return (vila == PROF_ALLOWED_VILA_IWA || vila == PROF_ALLOWED_VILA_KIRI);
}

static stock ProfServ_NormRankHP(patente)
{
    if(patente <= 0) return 0;
    // HP tem blocos de 5 por vila (1..5, 6..10, 11..15 ...)
    return ((patente - 1) % 5) + 1; // 1..5
}

static stock ProfServ_NormRankDP(patente)
{
    if(patente <= 0) return 0;
    // DP tem blocos de 6 por vila (1..6, 7..12, 13..18 ...)
    return ((patente - 1) % 6) + 1; // 1..6
}

static stock ProfServ_GetRank(playerid, prof)
{
    // usa Info[playerid][pHPPatente] / pDPPatente
    // (Info[] existe no seu GM)
    if(prof == PROF_HP) return ProfServ_NormRankHP(Info[playerid][pHPPatente]);
    if(prof == PROF_DP) return ProfServ_NormRankDP(Info[playerid][pDPPatente]);
    return 0;
}

static stock ProfServ_GetBlipForProf(prof)
{
    if(prof == PROF_HP) return PROF_BLIP_HOSPITAL;
    if(prof == PROF_DP) return PROF_BLIP_POLICE;
    return PROF_BLIP_PATROL;
}

static stock ProfServ_ClearMapIcons(playerid)
{
    RemovePlayerMapIcon(playerid, PROF_ICON_CALL);
    RemovePlayerMapIcon(playerid, PROF_ICON_PATROL);
}

static stock ProfServ_SetCallIcon(playerid, Float:x, Float:y, Float:z, prof)
{
    // Index fixo por player (nao conflita com outros sistemas)
    SetPlayerMapIcon(playerid, PROF_ICON_CALL, x, y, z, ProfServ_GetBlipForProf(prof), 0, 0);
}

static stock ProfServ_SetPatrolIcon(playerid, Float:x, Float:y, Float:z)
{
    SetPlayerMapIcon(playerid, PROF_ICON_PATROL, x, y, z, PROF_BLIP_PATROL, 0, 0);
}

static stock ProfServ_TouchActivity(playerid, prof)
{
    if(prof <= PROF_NONE || prof >= PROF_MAX) return 0;
    if(!gProfOnDuty[playerid][prof]) return 0;

    new now = gettime();
    gProfLastAction[playerid][prof] = now;

    if(!gProfSalaryActive[playerid][prof])
    {
        gProfSalaryActive[playerid][prof] = true;
        SendClientMessage(playerid, 0xA2DC35FF, "[SERVICO] Atividade registrada. Seu salario por minuto foi reativado.");
    }
    return 1;
}

static stock bool:ProfServ_IsActiveWindow(playerid, prof)
{
    if(!gProfOnDuty[playerid][prof]) return false;
    new now = gettime();
    if(now - gProfLastAction[playerid][prof] <= PROF_ACTIVITY_WINDOW) return true;
    return false;
}

stock bool:ProfServ_IsSalaryActive(playerid, prof)
{
    if(prof <= PROF_NONE || prof >= PROF_MAX) return false;
    // derived: on-duty + dentro da janela
    return ProfServ_IsActiveWindow(playerid, prof);
}

static stock ProfServ_ResetPlayerState(playerid, prof)
{
    gProfOnDuty[playerid][prof] = false;
    gProfLastAction[playerid][prof] = 0;
    gProfSalaryActive[playerid][prof] = false;

    gProfAcceptedCall[playerid][prof] = -1;
    gProfPatrolActive[playerid][prof] = false;
    gProfPatrolVila[playerid][prof] = 0;
    gProfPatrolStep[playerid][prof] = 0;

    ProfServ_ClearMapIcons(playerid);
    return 1;
}


// Inicializa estruturas globais (chame em OnGameModeInit)
stock ProfServ_InitAll()
{
    // zera chamados
    for(new i=0; i<PROF_MAX_CALLS; i++)
    {
        gProfCalls[i][pcActive] = false;
        gProfCalls[i][pcAcceptedBy] = INVALID_PLAYER_ID;
        gProfCalls[i][pcRequester] = INVALID_PLAYER_ID;
        gProfCalls[i][pcTarget] = INVALID_PLAYER_ID;
        gProfCalls[i][pcActorId] = -1;
        gProfCalls[i][pcReason][0] = '\0';
    }

    // zera cooldown de NPC
    for(new p=0; p<PROF_MAX; p++)
    {
        for(new v=0; v<=ECO_MAX_VILAS; v++)
        {
            gProfLastNpcSpawn[p][v] = 0;
        }
    }

    // prepara estado dos players (mesmo offline)
    for(new pid=0; pid<MAX_PLAYERS; pid++)
    {
        ProfServ_InitPlayer(pid);
        // IMPORTANT: indice de chamado aceito precisa iniciar em -1
        gProfAcceptedCall[pid][PROF_HP] = -1;
        gProfAcceptedCall[pid][PROF_DP] = -1;
    }
    return 1;
}

static stock ProfServ_InitPlayer(playerid)
{
    for(new p=0; p<PROF_MAX; p++)
    {
        gProfOnDuty[playerid][p] = false;
        gProfLastAction[playerid][p] = 0;
        gProfSalaryActive[playerid][p] = false;
        gProfAcceptedCall[playerid][p] = -1;
        gProfLastCreateCall[playerid][p] = 0;
        gProfLastTargetId[playerid][p] = INVALID_PLAYER_ID;
        gProfLastTargetTime[playerid][p] = 0;

        gProfPatrolActive[playerid][p] = false;
        gProfPatrolVila[playerid][p] = 0;
        gProfPatrolStep[playerid][p] = 0;
        for(new k=0; k<5; k++) gProfPatrolPointIdx[playerid][p][k] = -1;
    }
    ProfServ_ClearMapIcons(playerid);
    return 1;
}

static stock ProfServ_ValidCallIndex(idx)
{
    return (idx >= 0 && idx < PROF_MAX_CALLS);
}

static stock ProfServ_FindFreeCallSlot()
{
    for(new i=0; i<PROF_MAX_CALLS; i++)
    {
        if(!gProfCalls[i][pcActive]) return i;
    }
    return -1;
}

static stock bool:ProfServ_CallMatchesPro(playerid, callIdx)
{
    new prof = gProfCalls[callIdx][pcProf];
    new vila = gProfCalls[callIdx][pcVila];

    if(!gProfOnDuty[playerid][prof]) return false;
    if(Info[playerid][pMember] != vila) return false;
    return true;
}

static stock ProfServ_DestroyCallNPC(callIdx)
{
    if(!gProfCalls[callIdx][pcIsNPC]) return 1;

    new actorid = gProfCalls[callIdx][pcActorId];
    if(actorid != -1)
    {
        // nao existe IsValidActor na 0.3.7, entao tentamos destruir.
        DestroyActor(actorid);
    }
    gProfCalls[callIdx][pcActorId] = -1;
    return 1;
}

static stock ProfServ_ExpireCall(callIdx, reasonMsg[])
{
    if(!ProfServ_ValidCallIndex(callIdx)) return 0;
    if(!gProfCalls[callIdx][pcActive]) return 0;

    // avisar quem aceitou
    new accepter = gProfCalls[callIdx][pcAcceptedBy];
    if(accepter != INVALID_PLAYER_ID && IsPlayerConnected(accepter))
    {
        SendClientMessage(accepter, 0xFFB74DFF, reasonMsg);
        if(gProfAcceptedCall[accepter][ gProfCalls[callIdx][pcProf] ] == callIdx)
        {
            gProfAcceptedCall[accepter][ gProfCalls[callIdx][pcProf] ] = -1;
            ProfServ_ClearMapIcons(accepter);
        }
    }

    ProfServ_DestroyCallNPC(callIdx);

    gProfCalls[callIdx][pcActive] = false;
    gProfCalls[callIdx][pcAcceptedBy] = INVALID_PLAYER_ID;
    gProfCalls[callIdx][pcRequester] = INVALID_PLAYER_ID;
    gProfCalls[callIdx][pcTarget] = INVALID_PLAYER_ID;
    gProfCalls[callIdx][pcReason][0] = '\0';
    return 1;
}

static stock ProfServ_ReleaseAcceptedCall(playerid, prof)
{
    new old = gProfAcceptedCall[playerid][prof];
    if(old != -1 && ProfServ_ValidCallIndex(old) && gProfCalls[old][pcActive])
    {
        gProfCalls[old][pcAcceptedBy] = INVALID_PLAYER_ID;
        SendClientMessage(playerid, 0xFFB74DFF, "[SERVICO] Voce devolveu o chamado anterior para a fila.");
    }
    gProfAcceptedCall[playerid][prof] = -1;
    ProfServ_ClearMapIcons(playerid);
    return 1;
}

static stock ProfServ_IsDuplicateCall(prof, vila, targetid)
{
    // impede duplicado para o mesmo alvo
    for(new i=0; i<PROF_MAX_CALLS; i++)
    {
        if(!gProfCalls[i][pcActive]) continue;
        if(gProfCalls[i][pcProf] != prof) continue;
        if(gProfCalls[i][pcVila] != vila) continue;
        if(gProfCalls[i][pcIsNPC]) continue;
        if(gProfCalls[i][pcTarget] == targetid) return 1;
    }
    return 0;
}

static stock ProfServ_CountOpenCalls(prof, vila)
{
    new c=0;
    for(new i=0; i<PROF_MAX_CALLS; i++)
    {
        if(!gProfCalls[i][pcActive]) continue;
        if(gProfCalls[i][pcProf] != prof) continue;
        if(gProfCalls[i][pcVila] != vila) continue;
        c++;
    }
    return c;
}

static stock ProfServ_CountOnDuty(prof, vila)
{
    new c=0;
    for(new i=0; i<MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i)) continue;
        if(!gProfOnDuty[i][prof]) continue;
        if(Info[i][pMember] != vila) continue;
        c++;
    }
    return c;
}

static stock ProfServ_GetDist3D(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2)
{
    new Float:dx = x1 - x2;
    new Float:dy = y1 - y2;
    new Float:dz = z1 - z2;
    return floatround(floatsqroot(dx*dx + dy*dy + dz*dz));
}

static stock Float:ProfServ_GetDist3DF(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2)
{
    return floatsqroot((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2) + (z1-z2)*(z1-z2));
}

// ============================================================
// Criacao de chamados
// ============================================================

static stock ProfServ_CreatePlayerCall(requester, prof, vila, targetid, reason[])
{
    if(!IsPlayerConnected(requester)) return -1;
    if(!ProfServ_IsAllowedVila(vila))
    {
        SendClientMessage(requester, 0xFF6B6BFF, "[SERVICO] Este sistema so esta ativo em Iwagakure (1) e Kirigakure (3) por enquanto.");
        return -1;
    }

    new now = gettime();
    if(now - gProfLastCreateCall[requester][prof] < PROF_CALL_COOLDOWN)
    {
        SendClientMessage(requester, 0xFF6B6BFF, "[SERVICO] Aguarde 5 minutos para abrir outro chamado.");
        return -1;
    }

    if(targetid != INVALID_PLAYER_ID && ProfServ_IsDuplicateCall(prof, vila, targetid))
    {
        SendClientMessage(requester, 0xFF6B6BFF, "[SERVICO] Ja existe um chamado aberto para este alvo.");
        return -1;
    }

    new slot = ProfServ_FindFreeCallSlot();
    if(slot == -1)
    {
        SendClientMessage(requester, 0xFF6B6BFF, "[SERVICO] Limite de chamados atingido. Tente novamente.");
        return -1;
    }

    gProfLastCreateCall[requester][prof] = now;

    gProfCalls[slot][pcActive] = true;
    gProfCalls[slot][pcProf] = prof;
    gProfCalls[slot][pcVila] = vila;
    gProfCalls[slot][pcIsNPC] = false;
    gProfCalls[slot][pcCreatedAt] = now;
    gProfCalls[slot][pcExpiresAt] = now + PROF_CALL_EXPIRE;
    gProfCalls[slot][pcRequester] = requester;
    gProfCalls[slot][pcTarget] = targetid;
    gProfCalls[slot][pcAcceptedBy] = INVALID_PLAYER_ID;
    gProfCalls[slot][pcActorId] = -1;
    gProfCalls[slot][pcX] = 0.0;
    gProfCalls[slot][pcY] = 0.0;
    gProfCalls[slot][pcZ] = 0.0;
    format(gProfCalls[slot][pcReason], 64, "%s", reason);

    SendClientMessage(requester, 0xA2DC35FF, "[SERVICO] Chamado aberto com sucesso. Profissionais da sua vila poderao aceitar.");
    return slot;
}

static stock ProfServ_CreateNpcCall(prof, vila, reason[])
{
    if(!ProfServ_IsAllowedVila(vila)) return -1;

    new slot = ProfServ_FindFreeCallSlot();
    if(slot == -1) return -1;

    new Float:x, Float:y, Float:z;
    if(vila == PROF_ALLOWED_VILA_IWA)
    {
        new r = random(4);
        x = gProfNpcPts_Iwa[r][0]; y = gProfNpcPts_Iwa[r][1]; z = gProfNpcPts_Iwa[r][2];
    }
    else
    {
        new r = random(4);
        x = gProfNpcPts_Kiri[r][0]; y = gProfNpcPts_Kiri[r][1]; z = gProfNpcPts_Kiri[r][2];
    }

    // skin simples (ajuste se quiser)
    new skins[3] = { 211, 280, 206 };
    new skin = skins[random(3)];

    new actorid = CreateActor(skin, x, y, z, 0.0);

    new now = gettime();

    gProfCalls[slot][pcActive] = true;
    gProfCalls[slot][pcProf] = prof;
    gProfCalls[slot][pcVila] = vila;
    gProfCalls[slot][pcIsNPC] = true;
    gProfCalls[slot][pcCreatedAt] = now;
    gProfCalls[slot][pcExpiresAt] = now + PROF_CALL_EXPIRE;
    gProfCalls[slot][pcRequester] = INVALID_PLAYER_ID;
    gProfCalls[slot][pcTarget] = INVALID_PLAYER_ID;
    gProfCalls[slot][pcAcceptedBy] = INVALID_PLAYER_ID;
    gProfCalls[slot][pcActorId] = actorid;
    gProfCalls[slot][pcX] = x;
    gProfCalls[slot][pcY] = y;
    gProfCalls[slot][pcZ] = z;
    format(gProfCalls[slot][pcReason], 64, "%s", reason);

    return slot;
}

// ============================================================
// Conclusao de chamados / recompensas
// ============================================================

static stock ProfServ_ApplyRewards(proid, prof, targetid, bool:isNPC, reason[])
{
    // recompensa escala por patente normalizada
    new rank = ProfServ_GetRank(proid, prof);
    if(rank <= 0) rank = 1;

    new xp, money, prog, fame;
    if(prof == PROF_HP)
    {
        if(isNPC)
        {
            xp   = 35 + (rank * 6);
            money= 45 + (rank * 10);
            prog = 8  + (rank * 2);
            fame = 1  + (rank / 3);
        }
        else
        {
            xp   = 60 + (rank * 10);
            money= 80 + (rank * 20);
            prog = 15 + (rank * 5);
            fame = 2  + (rank / 2);
        }
    }
    else // PROF_DP
    {
        if(isNPC)
        {
            xp   = 40 + (rank * 7);
            money= 55 + (rank * 12);
            prog = 10 + (rank * 3);
            fame = 1  + (rank / 3);
        }
        else
        {
            xp   = 70 + (rank * 12);
            money= 90 + (rank * 22);
            prog = 18 + (rank * 6);
            fame = 3  + (rank / 2);
        }
    }

    // Anti-farm: mesmo alvo em <180s -> 25% reward e progresso minimo 1
    if(!isNPC && targetid != INVALID_PLAYER_ID)
    {
        if(gProfLastTargetId[proid][prof] == targetid && (gettime() - gProfLastTargetTime[proid][prof]) < PROF_SAME_TARGET_WINDOW)
        {
            xp = (xp * 25) / 100;
            money = (money * 25) / 100;
            fame = (fame * 25) / 100;
            prog = 1;
        }
        gProfLastTargetId[proid][prof] = targetid;
        gProfLastTargetTime[proid][prof] = gettime();
    }

    // 25% do bonus de dinheiro vai para o tesouro (player recebe 75%)
    new vila = Info[proid][pMember];
    new treasuryPart = money / 4;
    new playerMoney = money - treasuryPart;

    if(playerMoney < 0) playerMoney = 0;
    if(treasuryPart < 0) treasuryPart = 0;

    GivePlayerExperiencia(proid, xp);
    GivePlayerCash(proid, playerMoney);
    Fama_AddNinja(proid, fame);
    Fama_AddOpiniao(proid, fame);

    if(prof == PROF_HP) Info[proid][pProgressoHP] += prog;
    else Info[proid][pProgressoDP] += prog;

    // Tesouro (economia)
    #if defined Eco_AddTreasury
        Eco_AddTreasury(vila, treasuryPart);
    #endif

    new msg[180];
    format(msg, sizeof(msg), "[SERVICO] Concluido: +%d XP, +%d Ryous, +%d Progresso, +%d Fama. (Tesouro +%d) | %s", xp, playerMoney, prog, fame, treasuryPart, reason);
    SendClientMessage(proid, 0xA2DC35FF, msg);

    return 1;
}

static stock ProfServ_ConcludeCall(callIdx, proid, targetid, bool:isNPC)
{
    if(!ProfServ_ValidCallIndex(callIdx)) return 0;
    if(!gProfCalls[callIdx][pcActive]) return 0;

    new prof = gProfCalls[callIdx][pcProf];
    new vila = gProfCalls[callIdx][pcVila];

    // only if pro is on duty + same vila
    if(!gProfOnDuty[proid][prof]) return 0;
    if(Info[proid][pMember] != vila) return 0;

    ProfServ_TouchActivity(proid, prof);

    // remove accepted reference
    if(gProfAcceptedCall[proid][prof] == callIdx) gProfAcceptedCall[proid][prof] = -1;

    ProfServ_ClearMapIcons(proid);

    // recompensa
    ProfServ_ApplyRewards(proid, prof, targetid, isNPC, gProfCalls[callIdx][pcReason]);

    // finalizar
    ProfServ_DestroyCallNPC(callIdx);
    gProfCalls[callIdx][pcActive] = false;
    gProfCalls[callIdx][pcAcceptedBy] = INVALID_PLAYER_ID;

    return 1;
}

// ============================================================
// Patrulha
// ============================================================

static stock ProfServ_GeneratePatrolRoute(playerid, prof, vila)
{
    // Gera uma rota de 5 pontos (PROFSERV_PATROL_STEPS).
    // IMPORTANTE (anti-freeze):
    //  - A versao anterior usava do/while procurando "ponto nao usado".
    //  - Se o total de pontos configurados for < 5, aquilo virava loop infinito e travava o servidor.
    //  - Aqui usamos "embaralhar (shuffle) + pegar os 5 primeiros". Se tiver <5, repete alguns (sem travar).

    new ptTotal = (vila == PROF_ALLOWED_VILA_IWA) ? PROF_PTS_IWA : PROF_PTS_KIRI;
    if(ptTotal <= 0)
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "[SERVICO] Patrulha indisponivel: pontos de patrulha nao configurados.");
        return 0;
    }

    // pool de indices 0..total-1 (embaralha)
    new pool[PROFSERV_PTS_MAX];
    for(new i=0; i<ptTotal; i++) pool[i] = i;

    // Fisher-Yates shuffle (seguro e rapido)
    for(new i=0; i<ptTotal; i++)
    {
        new j = i + random(ptTotal - i);
        new tmp = pool[i];
        pool[i] = pool[j];
        pool[j] = tmp;
    }

    // Define 5 passos. Se total < 5, repete alguns indices (ainda assim nao trava).
    for(new k=0; k<PROFSERV_PATROL_STEPS; k++)
    {
        new pick;
        if(k < ptTotal) pick = pool[k];
        else pick = pool[random(ptTotal)];
        gProfPatrolPointIdx[playerid][prof][k] = pick;
    }

    gProfPatrolStep[playerid][prof] = 0;
    gProfPatrolActive[playerid][prof] = true;
    gProfPatrolVila[playerid][prof] = vila;

    // set icon para o primeiro
    new idx = gProfPatrolPointIdx[playerid][prof][0];
    new Float:x, Float:y, Float:z;

    if(vila == PROF_ALLOWED_VILA_IWA)
    { x = gProfPatrolPts_Iwa[idx][0]; y = gProfPatrolPts_Iwa[idx][1]; z = gProfPatrolPts_Iwa[idx][2]; }
    else
    { x = gProfPatrolPts_Kiri[idx][0]; y = gProfPatrolPts_Kiri[idx][1]; z = gProfPatrolPts_Kiri[idx][2]; }

    ProfServ_SetPatrolIcon(playerid, x, y, z);
    SendClientMessage(playerid, 0xA2DC35FF, "[SERVICO] Patrulha iniciada. Siga o marcador no mapa (5 pontos).");
    ProfServ_TouchActivity(playerid, prof);

    // Dica de configuracao (nao bloqueia, so alerta)
    if(ptTotal < PROFSERV_PATROL_STEPS)
    {
        SendClientMessage(playerid, 0xFFB74DFF, "[SERVICO] Aviso: sua vila tem menos de 5 pontos de patrulha configurados. Alguns pontos podem se repetir.");
    }

    return 1;
}

static stock ProfServ_StopPatrol(playerid, prof, bool:reward)
{
    if(!gProfPatrolActive[playerid][prof]) return 0;

    gProfPatrolActive[playerid][prof] = false;
    gProfPatrolStep[playerid][prof] = 0;
    gProfPatrolVila[playerid][prof] = 0;
    for(new k=0; k<5; k++) gProfPatrolPointIdx[playerid][prof][k] = -1;

    RemovePlayerMapIcon(playerid, PROF_ICON_PATROL);

    if(reward)
    {
        // bonus leve
        ProfServ_ApplyRewards(playerid, prof, INVALID_PLAYER_ID, true, "Bonus de patrulha");
    }
    return 1;
}

static stock ProfServ_CheckPatrolProgress(playerid, prof)
{
    if(!gProfPatrolActive[playerid][prof]) return 0;

    new vila = gProfPatrolVila[playerid][prof];
    if(Info[playerid][pMember] != vila)
    {
        SendClientMessage(playerid, 0xFFB74DFF, "[SERVICO] Patrulha cancelada: voce saiu da vila.");
        ProfServ_StopPatrol(playerid, prof, false);
        return 1;
    }

    new step = gProfPatrolStep[playerid][prof];
    if(step < 0 || step > 4) step = 0;

    new idx = gProfPatrolPointIdx[playerid][prof][step];
    if(idx < 0) return 0;

    new Float:px, Float:py, Float:pz;
    if(vila == PROF_ALLOWED_VILA_IWA)
    { px = gProfPatrolPts_Iwa[idx][0]; py = gProfPatrolPts_Iwa[idx][1]; pz = gProfPatrolPts_Iwa[idx][2]; }
    else
    { px = gProfPatrolPts_Kiri[idx][0]; py = gProfPatrolPts_Kiri[idx][1]; pz = gProfPatrolPts_Kiri[idx][2]; }

    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    if(ProfServ_GetDist3DF(x, y, z, px, py, pz) <= 6.0)
    {
        ProfServ_TouchActivity(playerid, prof);

        step++;
        if(step >= 5)
        {
            SendClientMessage(playerid, 0xA2DC35FF, "[SERVICO] Patrulha concluida. Bonus aplicado.");
            ProfServ_StopPatrol(playerid, prof, true);
            return 1;
        }

        gProfPatrolStep[playerid][prof] = step;
        idx = gProfPatrolPointIdx[playerid][prof][step];

        if(vila == PROF_ALLOWED_VILA_IWA)
        { px = gProfPatrolPts_Iwa[idx][0]; py = gProfPatrolPts_Iwa[idx][1]; pz = gProfPatrolPts_Iwa[idx][2]; }
        else
        { px = gProfPatrolPts_Kiri[idx][0]; py = gProfPatrolPts_Kiri[idx][1]; pz = gProfPatrolPts_Kiri[idx][2]; }

        ProfServ_SetPatrolIcon(playerid, px, py, pz);

        SendClientMessage(playerid, 0xA2DC35FF, "[SERVICO] Ponto de patrulha concluido. Proximo ponto marcado.");
    }
    return 1;
}

// ============================================================
// Duty toggle (chamado do ponto)
// ============================================================

stock ProfServ_OnDutyToggle(playerid, prof, bool:onDuty)
{
    if(prof <= PROF_NONE || prof >= PROF_MAX) return 0;

    if(onDuty)
    {
        // valida vila e patente
        if(!ProfServ_IsAllowedVila(Info[playerid][pMember]))
        {
            SendClientMessage(playerid, 0xFF6B6BFF, "[SERVICO] Profissoes ativas so estao habilitadas em Iwa (1) e Kiri (3) por enquanto.");
            ProfServ_ResetPlayerState(playerid, prof);
            return 0;
        }

        gProfOnDuty[playerid][prof] = true;
        gProfLastAction[playerid][prof] = gettime();
        gProfSalaryActive[playerid][prof] = true;
        gProfAcceptedCall[playerid][prof] = -1;

        SendClientMessage(playerid, 0xA2DC35FF, "[SERVICO] Voce entrou em servico. Salario por minuto ativo (faça acoes para manter).");

        // menu rapido (opcional)
        return 1;
    }
    else
    {
        // liberar chamado aceito
        ProfServ_ReleaseAcceptedCall(playerid, prof);
        ProfServ_StopPatrol(playerid, prof, false);

        gProfOnDuty[playerid][prof] = false;
        gProfSalaryActive[playerid][prof] = false;

        SendClientMessage(playerid, 0xFFB74DFF, "[SERVICO] Voce saiu de servico.");
        return 1;
    }
}

// ============================================================
// Integracoes em eventos existentes (GM)
// ============================================================

// Chamado por reanimacao (hospital)
stock ProfServ_OnMedicReanimar(medicid, patientid)
{
    if(!IsPlayerConnected(medicid) || !IsPlayerConnected(patientid)) return 0;
    if(!gProfOnDuty[medicid][PROF_HP]) return 0;
    if(Info[medicid][pMember] != Info[patientid][pMember]) return 0;

    ProfServ_TouchActivity(medicid, PROF_HP);

    // Procura chamado HP do paciente na mesma vila
    for(new i=0; i<PROF_MAX_CALLS; i++)
    {
        if(!gProfCalls[i][pcActive]) continue;
        if(gProfCalls[i][pcProf] != PROF_HP) continue;
        if(gProfCalls[i][pcVila] != Info[medicid][pMember]) continue;
        if(gProfCalls[i][pcIsNPC]) continue;

        if(gProfCalls[i][pcTarget] == patientid)
        {
            // se nao estava aceito, atribui para quem reanimou (para nao deixar chamado preso)
            if(gProfCalls[i][pcAcceptedBy] == INVALID_PLAYER_ID) gProfCalls[i][pcAcceptedBy] = medicid;

            if(gProfCalls[i][pcAcceptedBy] == medicid)
            {
                return ProfServ_ConcludeCall(i, medicid, patientid, false);
            }
        }
    }
    return 0;
}

// Chamado por prisao (policia)
stock ProfServ_OnPolicePrender(policeid, suspectid, jailMinutes)
{
    if(!IsPlayerConnected(policeid) || !IsPlayerConnected(suspectid)) return 0;
    if(!gProfOnDuty[policeid][PROF_DP]) return 0;

    ProfServ_TouchActivity(policeid, PROF_DP);

    for(new i=0; i<PROF_MAX_CALLS; i++)
    {
        if(!gProfCalls[i][pcActive]) continue;
        if(gProfCalls[i][pcProf] != PROF_DP) continue;
        if(gProfCalls[i][pcVila] != Info[policeid][pMember]) continue;
        if(gProfCalls[i][pcIsNPC]) continue;

        // alvo especifico (se denuncia foi com ID)
        if(gProfCalls[i][pcTarget] == suspectid)
        {
            if(gProfCalls[i][pcAcceptedBy] == INVALID_PLAYER_ID) gProfCalls[i][pcAcceptedBy] = policeid;

            if(gProfCalls[i][pcAcceptedBy] == policeid)
            {
                return ProfServ_ConcludeCall(i, policeid, suspectid, false);
            }
        }
    }
    return 0;
}

stock ProfServ_OnPlayerDisconnect(playerid)
{
    // limpa estados do player
    ProfServ_ResetPlayerState(playerid, PROF_HP);
    ProfServ_ResetPlayerState(playerid, PROF_DP);

    // se player era requester/target/accepter em algum chamado, ajusta
    for(new i=0; i<PROF_MAX_CALLS; i++)
    {
        if(!gProfCalls[i][pcActive]) continue;

        if(gProfCalls[i][pcAcceptedBy] == playerid)
        {
            gProfCalls[i][pcAcceptedBy] = INVALID_PLAYER_ID;
        }

        if(!gProfCalls[i][pcIsNPC])
        {
            if(gProfCalls[i][pcRequester] == playerid || gProfCalls[i][pcTarget] == playerid)
            {
                ProfServ_ExpireCall(i, "[SERVICO] Chamado cancelado: player desconectou.");
            }
        }
    }
    return 1;
}

// ============================================================
// UI (Dialogs) - Menu e Chamados
// ============================================================

static stock ProfServ_OpenMainMenu(playerid, prof)
{
    new title[64];
    if(prof == PROF_HP) format(title, sizeof(title), "Hospital - Servico Ativo");
    else format(title, sizeof(title), "Policia - Servico Ativo");
    ShowPlayerDialog(playerid, DIALOG_PROFSERV_MAIN, DIALOG_STYLE_LIST, title,
        "Chamados\nAceitar\nResolver NPC\nPatrulhar\nCancelar chamado\nFechar", "OK", "Sair");
    SetPVarInt(playerid, "ProfServ_MenuProf", prof);
    return 1;
}

static stock ProfServ_OpenCallsDialog(playerid, prof)
{
    gProfDlgCallCount[playerid] = 0;

    new vila = Info[playerid][pMember];
    if(!ProfServ_IsAllowedVila(vila))
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "[SERVICO] Sua vila ainda nao possui chamados ativos (apenas Iwa e Kiri).");
        return 1;
    }

    new list[2048];
    list[0] = '\0';

    new now = gettime();

    for(new i=0; i<PROF_MAX_CALLS; i++)
    {
        if(!gProfCalls[i][pcActive]) continue;
        if(gProfCalls[i][pcProf] != prof) continue;
        if(gProfCalls[i][pcVila] != vila) continue;

        if(gProfDlgCallCount[playerid] >= PROF_DLG_MAXLIST) break;

        // somente nao aceito ou aceito por mim
        if(gProfCalls[i][pcAcceptedBy] != INVALID_PLAYER_ID && gProfCalls[i][pcAcceptedBy] != playerid) continue;

        new line[160];
        new left = gProfCalls[i][pcExpiresAt] - now;
        if(left < 0) left = 0;

        if(gProfCalls[i][pcIsNPC])
        {
            format(line, sizeof(line), "#%d  [NPC]  %s  (expira %ds)\n", i, gProfCalls[i][pcReason], left);
        }
        else
        {
            new tgt = gProfCalls[i][pcTarget];
            new name[MAX_PLAYER_NAME]; name[0]='\0';
            if(tgt != INVALID_PLAYER_ID && IsPlayerConnected(tgt)) GetPlayerName(tgt, name, sizeof(name));
            else format(name, sizeof(name), "ID:%d", tgt);

            format(line, sizeof(line), "#%d  [PLAYER] %s | alvo %s  (expira %ds)\n", i, gProfCalls[i][pcReason], name, left);
        }

        strcat(list, line);

        gProfDlgCallMap[playerid][ gProfDlgCallCount[playerid] ] = i;
        gProfDlgCallCount[playerid]++;
    }

    if(gProfDlgCallCount[playerid] == 0)
    {
        format(list, sizeof(list), "Nenhum chamado disponivel agora.\n");
    }

    ShowPlayerDialog(playerid, DIALOG_PROFSERV_CALLS, DIALOG_STYLE_LIST, "Chamados Disponiveis", list, "Aceitar", "Voltar");
    SetPVarInt(playerid, "ProfServ_CallsProf", prof);
    return 1;
}

stock bool:ProfServ_OnDialog(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == DIALOG_PROFSERV_MAIN)
    {
        if(!response) return 1;

        new prof = GetPVarInt(playerid, "ProfServ_MenuProf");
        if(prof != PROF_HP && prof != PROF_DP) prof = PROF_HP;

        switch(listitem)
        {
            case 0: // Chamados
            {
                ProfServ_OpenCallsDialog(playerid, prof);
            }
            case 1: // Aceitar (pede ID no chat)
            {
                SendClientMessage(playerid, 0xFFFFFFFF, "[SERVICO] Use /aceitar [ID] para aceitar um chamado.");
            }
            case 2: // Resolver NPC
            {
                SendClientMessage(playerid, 0xFFFFFFFF, "[SERVICO] Use /resolverchamado para concluir seu chamado NPC perto do local.");
            }
            case 3: // Patrulhar
            {
                SendClientMessage(playerid, 0xFFFFFFFF, "[SERVICO] Use /patrulhar para iniciar a rota de 5 pontos.");
            }
            case 4: // Cancelar
            {
                ProfServ_ReleaseAcceptedCall(playerid, prof);
            }
            default: {}
        }
        return 1;
    }
    else if(dialogid == DIALOG_PROFSERV_CALLS)
    {
        if(!response)
        {
            // voltar para menu principal
            new prof = GetPVarInt(playerid, "ProfServ_CallsProf");
            ProfServ_OpenMainMenu(playerid, prof);
            return 1;
        }

        new prof = GetPVarInt(playerid, "ProfServ_CallsProf");
        if(listitem < 0 || listitem >= gProfDlgCallCount[playerid]) return 1;

        new callIdx = gProfDlgCallMap[playerid][listitem];
        if(!ProfServ_ValidCallIndex(callIdx) || !gProfCalls[callIdx][pcActive]) return 1;

        // aceitar
        // aceitar direto
        if(!ProfServ_AcceptCall(playerid, prof, callIdx))
            SendClientMessage(playerid, 0xFF6B6BFF, "[SERVICO] Nao foi possivel aceitar este chamado.");
        return 1;
    }
    return 0;
}

// ============================================================
// Aceitar / Resolver / Listar (logica)
// ============================================================

static stock ProfServ_AcceptCall(playerid, prof, callIdx)
{
    if(!ProfServ_ValidCallIndex(callIdx)) return 0;
    if(!gProfCalls[callIdx][pcActive]) return 0;

    if(gProfCalls[callIdx][pcProf] != prof) return 0;
    if(Info[playerid][pMember] != gProfCalls[callIdx][pcVila]) return 0;

    if(!gProfOnDuty[playerid][prof])
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "[SERVICO] Voce precisa estar em servico para aceitar chamados.");
        return 0;
    }

    // se ja aceito por outro
    if(gProfCalls[callIdx][pcAcceptedBy] != INVALID_PLAYER_ID && gProfCalls[callIdx][pcAcceptedBy] != playerid)
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "[SERVICO] Este chamado ja foi aceito por outro profissional.");
        return 0;
    }

    // so 1 aceito por prof -> devolve o anterior
    ProfServ_ReleaseAcceptedCall(playerid, prof);

    gProfCalls[callIdx][pcAcceptedBy] = playerid;
    gProfAcceptedCall[playerid][prof] = callIdx;

    // marcar icone
    if(gProfCalls[callIdx][pcIsNPC])
    {
        ProfServ_SetCallIcon(playerid, gProfCalls[callIdx][pcX], gProfCalls[callIdx][pcY], gProfCalls[callIdx][pcZ], prof);
    }
    else
    {
        new tgt = gProfCalls[callIdx][pcTarget];
        if(tgt != INVALID_PLAYER_ID && IsPlayerConnected(tgt))
        {
            new Float:x, Float:y, Float:z;
            GetPlayerPos(tgt, x, y, z);
            ProfServ_SetCallIcon(playerid, x, y, z, prof);
        }
    }

    ProfServ_TouchActivity(playerid, prof);

    SendClientMessage(playerid, 0xA2DC35FF, "[SERVICO] Chamado aceito. Marcador no mapa criado.");
    return 1;
}

static stock ProfServ_ResolveNpcAccepted(playerid, prof)
{
    new callIdx = gProfAcceptedCall[playerid][prof];
    if(callIdx == -1 || !ProfServ_ValidCallIndex(callIdx) || !gProfCalls[callIdx][pcActive])
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "[SERVICO] Voce nao tem um chamado aceito.");
        return 0;
    }
    if(!gProfCalls[callIdx][pcIsNPC])
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "[SERVICO] Seu chamado aceito nao e de NPC.");
        return 0;
    }

    // distancia <= 6m do local
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    if(ProfServ_GetDist3DF(x, y, z, gProfCalls[callIdx][pcX], gProfCalls[callIdx][pcY], gProfCalls[callIdx][pcZ]) > PROF_NPC_RESOLVE_DIST)
    {
        SendClientMessage(playerid, 0xFF6B6BFF, "[SERVICO] Aproxime-se do local do chamado (<= 6m) para resolver.");
        return 0;
    }

    return ProfServ_ConcludeCall(callIdx, playerid, INVALID_PLAYER_ID, true);
}

// ============================================================
// Timer principal (5s)
// ============================================================

public ProfServ_Tick()
{
    new now = gettime();

    // 1) Expirar chamados
    for(new i=0; i<PROF_MAX_CALLS; i++)
    {
        if(!gProfCalls[i][pcActive]) continue;
        if(now >= gProfCalls[i][pcExpiresAt])
        {
            ProfServ_ExpireCall(i, "[SERVICO] Chamado expirou (15 min).");
        }
    }

    // 2) Atualizar icones de chamados aceitos (alvo se move)
    for(new p=0; p<MAX_PLAYERS; p++)
    {
        if(!IsPlayerConnected(p)) continue;

        // HP
        if(gProfAcceptedCall[p][PROF_HP] != -1)
        {
            new idx = gProfAcceptedCall[p][PROF_HP];
            if(ProfServ_ValidCallIndex(idx) && gProfCalls[idx][pcActive] && gProfCalls[idx][pcAcceptedBy] == p)
            {
                if(!gProfCalls[idx][pcIsNPC])
                {
                    new tgt = gProfCalls[idx][pcTarget];
                    if(tgt != INVALID_PLAYER_ID && IsPlayerConnected(tgt))
                    {
                        new Float:x, Float:y, Float:z;
                        GetPlayerPos(tgt, x, y, z);
                        ProfServ_SetCallIcon(p, x, y, z, PROF_HP);
                    }
                }
            }
            else
            {
                gProfAcceptedCall[p][PROF_HP] = -1;
                RemovePlayerMapIcon(p, PROF_ICON_CALL);
            }
        }

        // DP
        if(gProfAcceptedCall[p][PROF_DP] != -1)
        {
            new idx2 = gProfAcceptedCall[p][PROF_DP];
            if(ProfServ_ValidCallIndex(idx2) && gProfCalls[idx2][pcActive] && gProfCalls[idx2][pcAcceptedBy] == p)
            {
                if(!gProfCalls[idx2][pcIsNPC])
                {
                    new tgt2 = gProfCalls[idx2][pcTarget];
                    if(tgt2 != INVALID_PLAYER_ID && IsPlayerConnected(tgt2))
                    {
                        new Float:x2, Float:y2, Float:z2;
                        GetPlayerPos(tgt2, x2, y2, z2);
                        ProfServ_SetCallIcon(p, x2, y2, z2, PROF_DP);
                    }
                }
            }
            else
            {
                gProfAcceptedCall[p][PROF_DP] = -1;
                RemovePlayerMapIcon(p, PROF_ICON_CALL);
            }
        }

        // 3) Checar patrulha
        if(gProfPatrolActive[p][PROF_HP]) ProfServ_CheckPatrolProgress(p, PROF_HP);
        if(gProfPatrolActive[p][PROF_DP]) ProfServ_CheckPatrolProgress(p, PROF_DP);

        // 4) Suspender salario se passou 10min sem acao (mensagem 1x)
        for(new prof=PROF_HP; prof<=PROF_DP; prof++)
        {
            if(!gProfOnDuty[p][prof]) continue;

            if(!ProfServ_IsActiveWindow(p, prof))
            {
                if(gProfSalaryActive[p][prof])
                {
                    gProfSalaryActive[p][prof] = false;
                    SendClientMessage(p, 0xFFB74DFF, "[SERVICO] Voce ficou 10 minutos sem atividade. Salario por minuto suspenso.");
                }
            }
        }
    }

    // 5) Gerar chamados NPC se: ha profissionais on-duty e nao ha chamados
    // Cooldown por vila/prof para nao spammar.
    for(new vila=1; vila<=5; vila++)
    {
        if(!ProfServ_IsAllowedVila(vila)) continue;

        // Hospital
        if(ProfServ_CountOnDuty(PROF_HP, vila) > 0 && ProfServ_CountOpenCalls(PROF_HP, vila) == 0)
        {
            if(now - gProfLastNpcSpawn[PROF_HP][vila] >= 180) // 3 min
            {
                if(ProfServ_CreateNpcCall(PROF_HP, vila, "Ferido NPC precisando de atendimento") != -1)
                {
                    gProfLastNpcSpawn[PROF_HP][vila] = now;
                }
            }
        }

        // Policia
        if(ProfServ_CountOnDuty(PROF_DP, vila) > 0 && ProfServ_CountOpenCalls(PROF_DP, vila) == 0)
        {
            if(now - gProfLastNpcSpawn[PROF_DP][vila] >= 180) // 3 min
            {
                if(ProfServ_CreateNpcCall(PROF_DP, vila, "Ocorrencia NPC na area") != -1)
                {
                    gProfLastNpcSpawn[PROF_DP][vila] = now;
                }
            }
        }
    }

    return 1;
}

// ============================================================
// Comandos (ZCMD)
// ============================================================

// Abrir menu rapido (para facilitar, voce pode chamar isso do seu menu existente)
CMD:menuhp(playerid, params[])
{
    if(!gProfOnDuty[playerid][PROF_HP]) return SendClientMessage(playerid, 0xFF6B6BFF, "[SERVICO] Voce nao esta em servico no Hospital.");
    ProfServ_OpenMainMenu(playerid, PROF_HP);
    return 1;
}
CMD:menudp(playerid, params[])
{
    if(!gProfOnDuty[playerid][PROF_DP]) return SendClientMessage(playerid, 0xFF6B6BFF, "[SERVICO] Voce nao esta em servico na Policia.");
    ProfServ_OpenMainMenu(playerid, PROF_DP);
    return 1;
}

// /socorro [motivo] -> cria chamado HP do proprio player
CMD:socorro(playerid, params[])
{
    if(params[0] == ' ') return SendClientMessage(playerid, 0xFFFFFFFF, "Use: /socorro [motivo]");
    new vila = Info[playerid][pMember];
    new reason[64]; format(reason, sizeof(reason), "%s", params);

    ProfServ_CreatePlayerCall(playerid, PROF_HP, vila, playerid, reason);
    return 1;
}

// /denunciar [id opcional] [motivo]
CMD:denunciar(playerid, params[])
{
    if(params[0] == ' ') return SendClientMessage(playerid, 0xFFFFFFFF, "Use: /denunciar [id opcional] [motivo]");

    new vila = Info[playerid][pMember];
    new target = INVALID_PLAYER_ID;
    new reason[64];

    // tenta ler primeiro token como id
    new id;
    if(!sscanf(params, "dS()[64]", id, reason))
    {
        if(IsPlayerConnected(id))
        {
            target = id;
            if(reason[0] == ' ') format(reason, sizeof(reason), "Denuncia sem motivo");
        }
        else
        {
            // id invalido -> trata tudo como motivo
            target = INVALID_PLAYER_ID;
            format(reason, sizeof(reason), "%s", params);
        }
    }
    else
    {
        // sem id -> motivo inteiro
        format(reason, sizeof(reason), "%s", params);
    }

    ProfServ_CreatePlayerCall(playerid, PROF_DP, vila, target, reason);
    return 1;
}

// /chamados -> abre lista conforme profissao on-duty
CMD:chamados(playerid, params[])
{
    if(gProfOnDuty[playerid][PROF_HP]) ProfServ_OpenCallsDialog(playerid, PROF_HP);
    else if(gProfOnDuty[playerid][PROF_DP]) ProfServ_OpenCallsDialog(playerid, PROF_DP);
    else SendClientMessage(playerid, 0xFF6B6BFF, "[SERVICO] Voce precisa estar em servico (Hospital ou Policia).");
    return 1;
}

// /aceitar [id]
CMD:aceitar(playerid, params[])
{
    new id;
    if(sscanf(params, "d", id)) return SendClientMessage(playerid, 0xFFFFFFFF, "Use: /aceitar [ID do chamado]");

    // escolhe prof com base no duty
    new prof = PROF_NONE;
    if(gProfOnDuty[playerid][PROF_HP]) prof = PROF_HP;
    else if(gProfOnDuty[playerid][PROF_DP]) prof = PROF_DP;

    if(prof == PROF_NONE) return SendClientMessage(playerid, 0xFF6B6BFF, "[SERVICO] Voce precisa estar em servico para aceitar.");

    if(!ProfServ_AcceptCall(playerid, prof, id))
        SendClientMessage(playerid, 0xFF6B6BFF, "[SERVICO] Nao foi possivel aceitar este chamado (verifique ID / vila / status).");

    return 1;
}

// /resolverchamado -> somente para chamados NPC aceitos
CMD:resolverchamado(playerid, params[])
{
    new prof = PROF_NONE;
    if(gProfOnDuty[playerid][PROF_HP]) prof = PROF_HP;
    else if(gProfOnDuty[playerid][PROF_DP]) prof = PROF_DP;
    if(prof == PROF_NONE) return SendClientMessage(playerid, 0xFF6B6BFF, "[SERVICO] Voce precisa estar em servico.");

    ProfServ_ResolveNpcAccepted(playerid, prof);
    return 1;
}

// /patrulhar -> inicia rota de 5 pontos
CMD:patrulhar(playerid, params[])
{
    new prof = PROF_NONE;
    if(gProfOnDuty[playerid][PROF_HP]) prof = PROF_HP;
    else if(gProfOnDuty[playerid][PROF_DP]) prof = PROF_DP;
    if(prof == PROF_NONE) return SendClientMessage(playerid, 0xFF6B6BFF, "[SERVICO] Voce precisa estar em servico.");

    if(gProfPatrolActive[playerid][prof]) return SendClientMessage(playerid, 0xFFB74DFF, "[SERVICO] Voce ja esta em patrulha.");

    new vila = Info[playerid][pMember];
    if(!ProfServ_IsAllowedVila(vila)) return SendClientMessage(playerid, 0xFF6B6BFF, "[SERVICO] Patrulha so esta ativa em Iwa e Kiri.");

    ProfServ_GeneratePatrolRoute(playerid, prof, vila);
    return 1;
}

// ============================================================
// Init (opcional): chame isso em OnPlayerConnect se quiser
// (Se nao chamar, ainda funciona, mas e recomendado zerar estados).
// ============================================================
stock ProfServ_OnPlayerConnect(playerid)
{
    ProfServ_InitPlayer(playerid);
    return 1;
}
