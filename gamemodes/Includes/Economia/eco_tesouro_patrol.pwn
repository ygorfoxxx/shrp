#if defined _ECO_TESOURO_PATROL_
    #endinput
#endif
#define _ECO_TESOURO_PATROL_

// ==========================================================
//  SHRP - Economia (Tesouro do Kage + Ninja Patrulha) [V2]
//  Arquivo: Includes/Economia/eco_tesouro_patrol.pwn
//
//  V2 (correção crítica):
//   - NÃO reserva slots fixos por vila (evita "comer" MAXIMO_BANDIDOS).
//   - Funciona para TODAS as vilas do eco_core (ECO_VILA_KONOHA..ECO_VILA_KUMO).
//   - Mantém max 3 ninjas por vila.
//   - Persiste usando BandidoFixed + BandidoPersona = "ECO_PATROL:vila=X;slot=Y".
//
//  Requisitos:
//   - eco_core.pwn incluído antes (ECO_MAX_VILAS, gEcoTreasury, Eco_IsPlayerKage etc.)
//   - bandidos.pwn incluído antes (Bandido_CreateAt, Bandido_SaveFixed, arrays globais)
//   - No GM:
//       * chame EcoPatrol_Init() APÓS Bandido_LoadFixed()
//       * em OnDialogResponse: if(EcoPatrol_OnDialog(...)) return 1;
//       * em OnPlayerDisconnect: EcoPatrol_OnPlayerDisconnect(playerid);
// ==========================================================

// ------------------------------
// CONFIG
// ------------------------------
#define ECO_PATROL_SLOTS_PER_VILA      (3)
#define ECO_PATROL_HIRE_COST           (2000)     // custo por contratação (1ª vez)
#define ECO_PATROL_PATROL_RADIUS       (18.0)     // raio de patrulha
#define ECO_PATROL_SKIN_DEFAULT        (287)      // skin GTA (ajuste se quiser)
#define ECO_PATROL_PENDING_MS          (120000)   // 2 min para posicionar

#define DLG_ECO_PATROL_MENU            (21950)

// ------------------------------
// STATE
// ------------------------------
new EcoPatrol_PendingVila[MAX_PLAYERS];
new EcoPatrol_PendingSlot[MAX_PLAYERS];
new EcoPatrol_PendingUntil[MAX_PLAYERS];

// Mapa vila->slot(1..3)->bandidoSlot real (0..MAXIMO_BANDIDOS-1) ou -1
new EcoPatrol_Map[ECO_MAX_VILAS][ECO_PATROL_SLOTS_PER_VILA];

// ------------------------------
// PERMISSÃO (você pediu "Kage e outros cargos (vago)")
// ------------------------------
stock bool:EcoPatrol_HasAccess(playerid)
{
    // Hoje: somente Kage. Depois você pode expandir aqui (conselheiro, ANBU, etc.)
    return Eco_IsPlayerKage(playerid);
}

// ------------------------------
// HELPERS
// ------------------------------
stock EcoPatrol_ClearPending(playerid)
{
    EcoPatrol_PendingVila[playerid]  = ECO_VILA_NONE;
    EcoPatrol_PendingSlot[playerid]  = 0;
    EcoPatrol_PendingUntil[playerid] = 0;
    return 1;
}

stock bool:EcoPatrol_HasPending(playerid)
{
    if(EcoPatrol_PendingVila[playerid] == ECO_VILA_NONE) return false;
    if(EcoPatrol_PendingSlot[playerid] < 1 || EcoPatrol_PendingSlot[playerid] > ECO_PATROL_SLOTS_PER_VILA) return false;

    if(EcoPatrol_PendingUntil[playerid] != 0 && GetTickCount() > EcoPatrol_PendingUntil[playerid])
    {
        EcoPatrol_ClearPending(playerid);
        return false;
    }
    return true;
}

stock EcoPatrol_SetPending(playerid, vila, patrolSlot)
{
    EcoPatrol_PendingVila[playerid]  = vila;
    EcoPatrol_PendingSlot[playerid]  = patrolSlot;
    EcoPatrol_PendingUntil[playerid] = GetTickCount() + ECO_PATROL_PENDING_MS;
    return 1;
}

stock bool:EcoPatrol_ParsePersona(const persona[], &vila, &slot1to3)
{
    vila = ECO_VILA_NONE;
    slot1to3 = 0;

    // deve conter assinatura
    if(strfind(persona, "ECO_PATROL:", true) != 0) return false;

    new p = strfind(persona, "vila=", true);
    if(p == -1) return false;
    vila = strval(persona[p + 5]);

    p = strfind(persona, "slot=", true);
    if(p == -1) return false;
    slot1to3 = strval(persona[p + 5]);

    if(vila <= ECO_VILA_NONE || vila >= ECO_MAX_VILAS) return false;
    if(slot1to3 < 1 || slot1to3 > ECO_PATROL_SLOTS_PER_VILA) return false;

    return true;
}

stock bool:EcoPatrol_IsGuardSlot(bSlot, vila, slot1to3)
{
    if(!Bandido_IsValidSlot(bSlot)) return false;
    if(gBandidoNpc[bSlot] == INVALID_PLAYER_ID) return false;

    if(!BandidoFixed[bSlot]) return false;
    if(BandidoMember[bSlot] != vila) return false;
    if(BandidoBehavior[bSlot] != BAND_BEHAV_PATROL) return false;
    if(!BandidoWarOnly[bSlot]) return false;
    if(BandidoUseGPT[bSlot]) return false;

    // Confere persona (evita confundir com outro NPC fixo patrulha)
    new pv, ps;
    if(!EcoPatrol_ParsePersona(BandidoPersona[bSlot], pv, ps)) return false;
    if(pv != vila || ps != slot1to3) return false;

    return true;
}

stock EcoPatrol_FindFreeBandidoSlot()
{
    // Pega o primeiro slot realmente vazio
    for(new i=0; i<MAXIMO_BANDIDOS; i++)
    {
        if(gBandidoNpc[i] == INVALID_PLAYER_ID) return i;
    }
    return -1;
}

stock EcoPatrol_UnlinkIfInvalid(vila, slot1to3)
{
    new idx = slot1to3 - 1;
    if(idx < 0 || idx >= ECO_PATROL_SLOTS_PER_VILA) return 0;

    new bSlot = EcoPatrol_Map[vila][idx];
    if(bSlot == -1) return 1;

    if(!EcoPatrol_IsGuardSlot(bSlot, vila, slot1to3))
        EcoPatrol_Map[vila][idx] = -1;

    return 1;
}

// ------------------------------
// INIT / REBIND
// ------------------------------
stock EcoPatrol_Init()
{
    // zera mapas e pendências
    for(new v=0; v<ECO_MAX_VILAS; v++)
        for(new s=0; s<ECO_PATROL_SLOTS_PER_VILA; s++)
            EcoPatrol_Map[v][s] = -1;

    for(new p=0; p<MAX_PLAYERS; p++)
        EcoPatrol_ClearPending(p);

    // Rebind: varre NPCs fixos e encontra os que são patrulha eco
    for(new bSlot=0; bSlot<MAXIMO_BANDIDOS; bSlot++)
    {
        if(gBandidoNpc[bSlot] == INVALID_PLAYER_ID) continue;
        if(!BandidoFixed[bSlot]) continue;

        new vila, ps;
        if(!EcoPatrol_ParsePersona(BandidoPersona[bSlot], vila, ps)) continue;

        // Só linka se realmente bater assinatura (flags etc.)
        if(EcoPatrol_IsGuardSlot(bSlot, vila, ps))
        {
            EcoPatrol_Map[vila][ps - 1] = bSlot;
        }
    }
    return 1;
}

// ------------------------------
// MENU
// ------------------------------
stock EcoPatrol_ShowMenu(playerid, vila)
{
    new vName[16];
    Eco_GetVilaName(vila, vName, sizeof vName);

    new header[96];
    format(header, sizeof header, "PATRULHA %s", vName);

    new list[512];
    list[0] = '\0';
    strcat(list, "Slot\tStatus\tCusto\n", sizeof list);

    for(new s=1; s<=ECO_PATROL_SLOTS_PER_VILA; s++)
    {
        EcoPatrol_UnlinkIfInvalid(vila, s);

        new status[24];
        new bSlot = EcoPatrol_Map[vila][s-1];

        if(bSlot != -1 && EcoPatrol_IsGuardSlot(bSlot, vila, s))
            format(status, sizeof status, "{B9FFB9}Ativo");
        else
            format(status, sizeof status, "{FFB9B9}Vazio");

        new line[96];
        if(bSlot == -1) format(line, sizeof line, "%d\t%s\t%d\n", s, status, ECO_PATROL_HIRE_COST);
        else            format(line, sizeof line, "%d\t%s\t0\n",  s, status, 0);

        strcat(list, line, sizeof list);
    }

    new msg[96];
    format(msg, sizeof msg, "(Economia) Tesouro atual: %d Ryo.", gEcoTreasury[vila]);
    SendClientMessage(playerid, -1, msg);

    ShowPlayerDialog(playerid, DLG_ECO_PATROL_MENU, DIALOG_STYLE_TABLIST_HEADERS, header, list, "Selecionar", "Fechar");
    return 1;
}

// ------------------------------
// CREATE / MOVE
// ------------------------------
stock EcoPatrol_CreateOrMoveGuard(playerid, vila, slot1to3)
{
    if(vila <= ECO_VILA_NONE || vila >= ECO_MAX_VILAS) return 0;
    if(slot1to3 < 1 || slot1to3 > ECO_PATROL_SLOTS_PER_VILA) return 0;

    EcoPatrol_UnlinkIfInvalid(vila, slot1to3);

    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    new vw = GetPlayerVirtualWorld(playerid);
    new interior = GetPlayerInterior(playerid);

    new bSlot = EcoPatrol_Map[vila][slot1to3 - 1];
    if(bSlot == -1)
    {
        bSlot = EcoPatrol_FindFreeBandidoSlot();
        if(bSlot == -1)
        {
            SendClientMessage(playerid, -1, "(Patrulha) Sem slots de NPC livres (MAXIMO_BANDIDOS cheio).");
            return 0;
        }
    }

    new vName[16];
    Eco_GetVilaName(vila, vName, sizeof vName);

    new name[32];
    format(name, sizeof name, "Guarda %s", vName);

    // Cria (ou recria) via sistema de bandidos
    if(!Bandido_CreateAt(bSlot, BANDIDO_TIPO_BANDIDO, ECO_PATROL_SKIN_DEFAULT, name, x, y, z, vw, interior))
    {
        SendClientMessage(playerid, -1, "(Patrulha) Bandido_CreateAt falhou (FCNPC_Create falhou ou limite de NPCs).");
        return 0;
    }

    // Marca como patrulha oficial
    BandidoMember[bSlot] = vila;
    BandidoBehavior[bSlot] = BAND_BEHAV_PATROL;
    BandidoWarOnly[bSlot] = true;
    BandidoUseGPT[bSlot] = false;
    BandidoGiveXP[bSlot] = false;
    BandidoPatrolRadius[bSlot] = ECO_PATROL_PATROL_RADIUS;
    BandidoFixed[bSlot] = true;
    BandidoRespawn[bSlot] = true;

    format(BandidoPersona[bSlot], sizeof BandidoPersona[], "ECO_PATROL:vila=%d;slot=%d", vila, slot1to3);

    Bandido_ApplyBandana(bSlot);
    Bandido_UpdateLabel(bSlot);

    Bandido_SaveFixed();

    EcoPatrol_Map[vila][slot1to3 - 1] = bSlot;

    new msg[144];
    format(msg, sizeof msg, "(Patrulha) Ninja #%d posicionado em %s (raio %.1f).", slot1to3, vName, ECO_PATROL_PATROL_RADIUS);
    SendClientMessage(playerid, -1, msg);

    return 1;
}

// ------------------------------
// DIALOG HANDLER
// ------------------------------
stock bool:EcoPatrol_OnDialog(playerid, dialogid, response, listitem, inputtext[])
{
    #pragma unused inputtext
    if(dialogid != DLG_ECO_PATROL_MENU) return false;

    if(!response) return true;

    if(!EcoPatrol_HasAccess(playerid)) return true;

    new vila = Eco_GetKageVilaFromPlayer(playerid);
    if(vila == ECO_VILA_NONE) return true;

    new patrolSlot = listitem + 1;
    if(patrolSlot < 1 || patrolSlot > ECO_PATROL_SLOTS_PER_VILA) return true;

    EcoPatrol_UnlinkIfInvalid(vila, patrolSlot);

    // Se já existe: reposicionar sem custo
    new bSlot = EcoPatrol_Map[vila][patrolSlot - 1];
    if(bSlot != -1 && EcoPatrol_IsGuardSlot(bSlot, vila, patrolSlot))
    {
        EcoPatrol_SetPending(playerid, vila, patrolSlot);
        SendClientMessage(playerid, -1, "(Patrulha) Reposicionar: vá até o local e use /posicionarninja <1-3> (sem custo).");
        return true;
    }

    // Contratar: precisa ter tesouro
    if(gEcoTreasury[vila] < ECO_PATROL_HIRE_COST)
    {
        SendClientMessage(playerid, -1, "(Economia) Tesouro insuficiente para contratar este ninja.");
        return true;
    }

    gEcoTreasury[vila] -= ECO_PATROL_HIRE_COST;
    EcoCore_Save();

    EcoPatrol_SetPending(playerid, vila, patrolSlot);

    new msg[160];
    format(msg, sizeof msg, "(Patrulha) Contratado! -%d Ryo do tesouro. Vá até o local e use /posicionarninja %d.", ECO_PATROL_HIRE_COST, patrolSlot);
    SendClientMessage(playerid, -1, msg);

    return true;
}

// ------------------------------
// COMMANDS
// ------------------------------
#if defined CMD

CMD:tesouro(playerid, params[])
{
    #pragma unused params

    if(!EcoPatrol_HasAccess(playerid))
        return SendClientMessage(playerid, -1, "(Economia) Você não tem permissão.");

    new vila = Eco_GetKageVilaFromPlayer(playerid);
    if(vila == ECO_VILA_NONE)
        return SendClientMessage(playerid, -1, "(Economia) Vila inválida.");

    EcoPatrol_ShowMenu(playerid, vila);
    return 1;
}

CMD:posicionarninja(playerid, params[])
{
    new slot = strval(params);
    if(slot < 1 || slot > ECO_PATROL_SLOTS_PER_VILA)
        return SendClientMessage(playerid, -1, "Uso: /posicionarninja <1-3>");

    if(!EcoPatrol_HasAccess(playerid))
        return SendClientMessage(playerid, -1, "(Patrulha) Você não tem permissão.");

    if(!EcoPatrol_HasPending(playerid))
        return SendClientMessage(playerid, -1, "(Patrulha) Você não tem nenhum ninja pendente. Use /tesouro e selecione um slot.");

    if(EcoPatrol_PendingSlot[playerid] != slot)
        return SendClientMessage(playerid, -1, "(Patrulha) Esse não é o slot pendente. Use o slot que você selecionou no /tesouro.");

    new vila = EcoPatrol_PendingVila[playerid];
    if(vila == ECO_VILA_NONE) return SendClientMessage(playerid, -1, "(Patrulha) Pendente inválido.");

    if(!EcoPatrol_CreateOrMoveGuard(playerid, vila, slot))
        return 1; // EcoPatrol_CreateOrMoveGuard já manda o motivo no chat

    EcoPatrol_ClearPending(playerid);
    return 1;
}

#endif

stock EcoPatrol_OnPlayerDisconnect(playerid)
{
    EcoPatrol_ClearPending(playerid);
    return 1;
}