// ==========================================================
//  menunpc.pwn  (UI + spawns shinobi_ai + ponte bandidos)
//  Coloque em: Includes/Npcs/menunpc.pwn
// ==========================================================
#if defined _SHRP_MENUNPC_INCLUDED
    #endinput
#endif
#define _SHRP_MENUNPC_INCLUDED

#include <a_samp>

// Usa os dois sistemas
#include "Includes\Npcs\bandidos.pwn"
#include "Includes\Npcs\shinobi_ai.pwn"

// Economia (opcional, mas recomendado)
#if defined _ECO_CORE_INCLUDED
    // já incluído
#else
    // se no seu GM eco_core já vem antes, melhor não incluir aqui.
    // #include "Includes\\Economia\\eco_core.pwn"
#endif

// -------------------- DIALOG IDS (use faixa alta) --------------------
#define DLG_MENUNPC_MAIN          (24500)
#define DLG_MENUNPC_MOB_TPL       (24501)
#define DLG_MENUNPC_GUARD_TPL     (24502)
#define DLG_MENUNPC_LIST          (24503)
#define DLG_MENUNPC_REMOVE_CONFIRM (24504)

// -------------------- CONFIG --------------------
#define MENUNPC_MAX_SPAWNS        (120)

// clones
#define BUNSHIN_MAX_CLONES        (3)
#define BUNSHIN_LIFETIME_MS       (45000)
#define BUNSHIN_COOLDOWN_MS       (20000)
#define BUNSHIN_CHAKRA_COST       (35.0)

// -------------------- SPAWN DATA --------------------
#define SPAWN_NONE     (0)
#define SPAWN_MOB      (1)
#define SPAWN_GUARD    (2)

enum E_MN_SPAWN
{
    bool:mnUsed,
    mnType,
    mnTemplate,
    mnVila,
    mnSkin,
    mnRespawnMs,
    mnCost,                 // usado em guardas do tesouro
    Float:mnX,
    Float:mnY,
    Float:mnZ,
    mnVW,
    mnInt,
    mnActiveSlot,           // slot do shinobi_ai (ou -1)
    mnLastSpawnTick
}
new gMnSpawn[MENUNPC_MAX_SPAWNS][E_MN_SPAWN];

new gMnTimer = -1;

// mapeamento da lista por player (pra remover)
new gMnListMap[MAX_PLAYERS][MENUNPC_MAX_SPAWNS];
new gMnListCount[MAX_PLAYERS];
new gMnPendingRemoveIdx[MAX_PLAYERS];

// -------------------- CLONES --------------------
new gBunshinSlots[MAX_PLAYERS][BUNSHIN_MAX_CLONES];
new gBunshinExpireTick[MAX_PLAYERS];
new gBunshinNextUseTick[MAX_PLAYERS];

// -------------------- ACCESS (AJUSTE AQUI) --------------------
stock bool:MenuNpc_CanUse(playerid)
{
    // Sugestão: restringir pra staff.
    // Ex.: return (Info[playerid][pAdmin] >= 1);
    return true;
}

stock bool:MenuNpc_IsKage(playerid)
{
    #if defined _ECO_CORE_INCLUDED
        return Eco_IsPlayerKage(playerid);
    #else
        return false;
    #endif
}

// -------------------- HELPERS --------------------
stock bool:Mn_IsAliveSlot(slot)
{
    return (slot >= 0 && slot < MAXIMO_NPCS_COMBATE && gNpcUsed[slot] && gNpcId[slot] != INVALID_PLAYER_ID);
}

stock Mn_FindFreeSpawn()
{
    for(new i=0; i<MENUNPC_MAX_SPAWNS; i++)
        if(!gMnSpawn[i][mnUsed]) return i;
    return -1;
}

stock Mn_ResetSpawn(i)
{
    gMnSpawn[i][mnUsed] = false;
    gMnSpawn[i][mnType] = SPAWN_NONE;
    gMnSpawn[i][mnTemplate] = 0;
    gMnSpawn[i][mnVila] = 0;
    gMnSpawn[i][mnSkin] = 0;
    gMnSpawn[i][mnRespawnMs] = 0;
    gMnSpawn[i][mnCost] = 0;
    gMnSpawn[i][mnX] = 0.0;
    gMnSpawn[i][mnY] = 0.0;
    gMnSpawn[i][mnZ] = 0.0;
    gMnSpawn[i][mnVW] = 0;
    gMnSpawn[i][mnInt] = 0;
    gMnSpawn[i][mnActiveSlot] = -1;
    gMnSpawn[i][mnLastSpawnTick] = 0;
    return 1;
}

// -------------------- TEMPLATES --------------------
#define MOB_TPL_FRACO    (1)
#define MOB_TPL_MEDIO    (2)
#define MOB_TPL_BOSS     (3)

#define GUARD_TPL_GATE   (1)
#define GUARD_TPL_PATROL (2)

stock Mn_ApplyMobTemplate(slot, tpl)
{
    switch(tpl)
    {
        case MOB_TPL_FRACO:
        {
            SHRP_NpcSetHP(slot, 120.0);
            SHRP_NpcSetRewards(slot, 35, 80);
            gNpcAggroRange[slot] = 20.0;
            gNpcAttackRange[slot] = 2.5;
        }
        case MOB_TPL_MEDIO:
        {
            SHRP_NpcSetHP(slot, 180.0);
            SHRP_NpcSetRewards(slot, 65, 150);
            gNpcAggroRange[slot] = 25.0;
            gNpcAttackRange[slot] = 2.6;
        }
        case MOB_TPL_BOSS:
        {
            SHRP_NpcSetHP(slot, 520.0);
            SHRP_NpcSetRewards(slot, 260, 700);
            gNpcAggroRange[slot] = 32.0;
            gNpcAttackRange[slot] = 2.8;
        }
    }
    return 1;
}

stock Mn_ApplyGuardTemplate(slot, tpl)
{
    // Guardas não dão recompensa
    SHRP_NpcSetRewards(slot, 0, 0);

    switch(tpl)
    {
        case GUARD_TPL_GATE:
        {
            SHRP_NpcSetHP(slot, 260.0);
            gNpcAggroRange[slot] = 40.0;
            gNpcAttackRange[slot] = 2.6;
            SHRP_NpcSetPatrolRadius(slot, 3.0); // fica "no portão"
        }
        case GUARD_TPL_PATROL:
        {
            SHRP_NpcSetHP(slot, 220.0);
            gNpcAggroRange[slot] = 35.0;
            gNpcAttackRange[slot] = 2.6;
            SHRP_NpcSetPatrolRadius(slot, 18.0); // ronda
        }
    }
    return 1;
}

// -------------------- SPAWN/RESPAWN --------------------
stock Mn_SpawnNow(i)
{
    if(!gMnSpawn[i][mnUsed]) return 0;

    // se ainda tá vivo, não mexe
    if(Mn_IsAliveSlot(gMnSpawn[i][mnActiveSlot])) return 1;

    new name[32];
    if(gMnSpawn[i][mnType] == SPAWN_MOB) format(name, sizeof name, "Mob_%d", i);
    else                                  format(name, sizeof name, "Guarda_%d", i);

    new type = (gMnSpawn[i][mnType] == SPAWN_GUARD) ? NPCT_PATROL : NPCT_HOSTILE;
    new vila = gMnSpawn[i][mnVila];

    new slot = SHRP_NpcCreate(
        name,
        gMnSpawn[i][mnSkin],
        type,
        vila,
        gMnSpawn[i][mnX], gMnSpawn[i][mnY], gMnSpawn[i][mnZ],
        gMnSpawn[i][mnVW],
        gMnSpawn[i][mnInt]
    );

    if(slot == -1) return 0;

    gMnSpawn[i][mnActiveSlot] = slot;
    gMnSpawn[i][mnLastSpawnTick] = GetTickCount();

    if(gMnSpawn[i][mnType] == SPAWN_MOB)   Mn_ApplyMobTemplate(slot, gMnSpawn[i][mnTemplate]);
    else                                   Mn_ApplyGuardTemplate(slot, gMnSpawn[i][mnTemplate]);

    return 1;
}

forward Mn_Tick();
public Mn_Tick()
{
    new now = GetTickCount();

    for(new i=0; i<MENUNPC_MAX_SPAWNS; i++)
    {
        if(!gMnSpawn[i][mnUsed]) continue;

        if(!Mn_IsAliveSlot(gMnSpawn[i][mnActiveSlot]))
        {
            // respawn
            if(now - gMnSpawn[i][mnLastSpawnTick] >= gMnSpawn[i][mnRespawnMs])
            {
                Mn_SpawnNow(i);
            }
        }
    }

    // expirar clones
    for(new p=0; p<MAX_PLAYERS; p++)
    {
        if(!IsPlayerConnected(p) || IsPlayerNPC(p)) continue;

        if(gBunshinExpireTick[p] != 0 && now > gBunshinExpireTick[p])
        {
            for(new c=0; c<BUNSHIN_MAX_CLONES; c++)
            {
                new slot = gBunshinSlots[p][c];
                if(Mn_IsAliveSlot(slot)) SHRP_NpcDestroy(slot);
                gBunshinSlots[p][c] = -1;
            }
            gBunshinExpireTick[p] = 0;
        }
    }

    return 1;
}

stock MenuNpc_Init()
{
    for(new i=0; i<MENUNPC_MAX_SPAWNS; i++) Mn_ResetSpawn(i);

    for(new p=0; p<MAX_PLAYERS; p++)
    {
        gMnPendingRemoveIdx[p] = -1;
        gMnListCount[p] = 0;

        for(new c=0; c<BUNSHIN_MAX_CLONES; c++) gBunshinSlots[p][c] = -1;
        gBunshinExpireTick[p] = 0;
        gBunshinNextUseTick[p] = 0;
    }

    if(gMnTimer != -1) KillTimer(gMnTimer);
    gMnTimer = SetTimer("Mn_Tick", 1000, true);
    return 1;
}

stock MenuNpc_Shutdown()
{
    if(gMnTimer != -1) { KillTimer(gMnTimer); gMnTimer = -1; }

    // destrói spawns ativos
    for(new i=0; i<MENUNPC_MAX_SPAWNS; i++)
    {
        if(!gMnSpawn[i][mnUsed]) continue;
        if(Mn_IsAliveSlot(gMnSpawn[i][mnActiveSlot])) SHRP_NpcDestroy(gMnSpawn[i][mnActiveSlot]);
        Mn_ResetSpawn(i);
    }
    return 1;
}

// -------------------- MENU UI --------------------
stock MenuNpc_ShowMain(playerid)
{
    new list[512];
    list[0] = '\0';

    strcat(list, "Criar MOB aqui (pra upar)\n");
    strcat(list, "Criar GUARDA de portão (Kage / Tesouro)\n");
    strcat(list, "Gerenciar spawns (remover)\n");
    strcat(list, "Criar NPC FALANTE (wizard bandidos)\n");

    #if defined _ECO_CORE_INCLUDED
    {
        new vila = Info[playerid][pMember];
        if(vila > 0)
        {
            new msg[96];
            format(msg, sizeof msg, "(Tesouro) Sua vila: %d | Tesouro: %d", vila, gEcoTreasury[vila]);
            SendClientMessage(playerid, -1, msg);
        }
    }
    #endif

    ShowPlayerDialog(playerid, DLG_MENUNPC_MAIN, DIALOG_STYLE_LIST,
        "MENU NPC", list, "OK", "Fechar");
    return 1;
}

stock MenuNpc_ShowMobTpl(playerid)
{
    ShowPlayerDialog(playerid, DLG_MENUNPC_MOB_TPL, DIALOG_STYLE_LIST,
        "Criar MOB - Template",
        "Fraco (respawn 45s)\nMedio (respawn 60s)\nBoss (respawn 180s)",
        "Criar", "Voltar");
    return 1;
}

stock MenuNpc_ShowGuardTpl(playerid)
{
    ShowPlayerDialog(playerid, DLG_MENUNPC_GUARD_TPL, DIALOG_STYLE_LIST,
        "Criar GUARDA (Kage)",
        "Guarda de Portao (custo 2000)\nPatrulha (custo 3000)",
        "Criar", "Voltar");
    return 1;
}

stock MenuNpc_BuildSpawnList(playerid, out[], outSize)
{
    out[0] = '\0';
    strcat(out, "ID\tTipo\tStatus\n", outSize);

    gMnListCount[playerid] = 0;

    for(new i=0; i<MENUNPC_MAX_SPAWNS; i++)
    {
        if(!gMnSpawn[i][mnUsed]) continue;

        new status[16];
        if(Mn_IsAliveSlot(gMnSpawn[i][mnActiveSlot])) format(status, sizeof status, "{B9FFB9}Ativo");
        else                                         format(status, sizeof status, "{FFB9B9}Morto");

        new tipo[16];
		if (gMnSpawn[i][mnType] == SPAWN_MOB) strcpy(tipo, "MOB");
else strcpy(tipo, "GUARDA");



        new line[96];
        format(line, sizeof line, "%d\t%s\t%s\n", i, tipo, status);
        strcat(out, line, outSize);

        gMnListMap[playerid][gMnListCount[playerid]++] = i;
        if(gMnListCount[playerid] >= MENUNPC_MAX_SPAWNS) break;
    }

    if(gMnListCount[playerid] == 0)
        strcat(out, "—\t(sem spawns)\t—\n", outSize);

    return 1;
}

stock MenuNpc_ShowSpawnList(playerid)
{
    new list[2048];
    MenuNpc_BuildSpawnList(playerid, list, sizeof list);

    ShowPlayerDialog(playerid, DLG_MENUNPC_LIST, DIALOG_STYLE_TABLIST_HEADERS,
        "Spawns", list, "Selecionar", "Voltar");
    return 1;
}

// -------------------- COMMAND --------------------
CMD:menunpc(playerid, params[])
{
    if(!MenuNpc_CanUse(playerid)) return SendClientMessage(playerid, -1, "Sem permissao."), 1;
    return MenuNpc_ShowMain(playerid);
}

// -------------------- DIALOG HANDLER --------------------
// No GM: if(MenuNpc_OnDialog(...)) return 1;
stock MenuNpc_OnDialog(playerid, dialogid, response, listitem, inputtext[])
{
    switch(dialogid)
    {
        case DLG_MENUNPC_MAIN:
        {
            if(!response) return 1;

            switch(listitem)
            {
                case 0: return MenuNpc_ShowMobTpl(playerid);
                case 1: return MenuNpc_ShowGuardTpl(playerid);
                case 2: return MenuNpc_ShowSpawnList(playerid);
                case 3: return BandidoMenu_Start(playerid);
            }
            return 1;
        }

        case DLG_MENUNPC_MOB_TPL:
        {
            if(!response) return MenuNpc_ShowMain(playerid);

            new tpl = (listitem == 0) ? MOB_TPL_FRACO : (listitem == 1) ? MOB_TPL_MEDIO : MOB_TPL_BOSS;
            new respawn = (tpl == MOB_TPL_FRACO) ? 45000 : (tpl == MOB_TPL_MEDIO) ? 60000 : 180000;

            new idx = Mn_FindFreeSpawn();
            if(idx == -1) return SendClientMessage(playerid, -1, "Sem espaco de spawn (MENUNPC_MAX_SPAWNS)."), 1;

            new Float:x, Float:y, Float:z;
            GetPlayerPos(playerid, x, y, z);

            gMnSpawn[idx][mnUsed] = true;
            gMnSpawn[idx][mnType] = SPAWN_MOB;
            gMnSpawn[idx][mnTemplate] = tpl;
            gMnSpawn[idx][mnVila] = 0; // mob ataca todos
            gMnSpawn[idx][mnSkin] = 105; // ajuste a skin padrão
            gMnSpawn[idx][mnRespawnMs] = respawn;
            gMnSpawn[idx][mnCost] = 0;

            gMnSpawn[idx][mnX] = x; gMnSpawn[idx][mnY] = y; gMnSpawn[idx][mnZ] = z;
            gMnSpawn[idx][mnVW] = GetPlayerVirtualWorld(playerid);
            gMnSpawn[idx][mnInt] = GetPlayerInterior(playerid);
            gMnSpawn[idx][mnActiveSlot] = -1;
            gMnSpawn[idx][mnLastSpawnTick] = 0;

            Mn_SpawnNow(idx);

            SendClientMessage(playerid, -1, "MOB criado e configurado com respawn.");
            return 1;
        }

        case DLG_MENUNPC_GUARD_TPL:
        {
            if(!response) return MenuNpc_ShowMain(playerid);

            if(!MenuNpc_IsKage(playerid))
                return SendClientMessage(playerid, -1, "Somente o Kage pode contratar guardas pelo tesouro."), 1;

            #if defined _ECO_CORE_INCLUDED
            new vila = Info[playerid][pMember];
            if(vila <= 0) return SendClientMessage(playerid, -1, "Você não tem vila válida."), 1;

            new tpl = (listitem == 0) ? GUARD_TPL_GATE : GUARD_TPL_PATROL;
            new cost = (tpl == GUARD_TPL_GATE) ? 2000 : 3000;

            if(gEcoTreasury[vila] < cost)
                return SendClientMessage(playerid, -1, "Tesouro insuficiente."), 1;

            new idx = Mn_FindFreeSpawn();
            if(idx == -1) return SendClientMessage(playerid, -1, "Sem espaco de spawn."), 1;

            new Float:x, Float:y, Float:z;
            GetPlayerPos(playerid, x, y, z);

            gEcoTreasury[vila] -= cost;

            gMnSpawn[idx][mnUsed] = true;
            gMnSpawn[idx][mnType] = SPAWN_GUARD;
            gMnSpawn[idx][mnTemplate] = tpl;
            gMnSpawn[idx][mnVila] = vila;     // guarda ignora mesma vila e ataca invasores
            gMnSpawn[idx][mnSkin] = 287;      // ajuste
            gMnSpawn[idx][mnRespawnMs] = 60000;
            gMnSpawn[idx][mnCost] = cost;

            gMnSpawn[idx][mnX] = x; gMnSpawn[idx][mnY] = y; gMnSpawn[idx][mnZ] = z;
            gMnSpawn[idx][mnVW] = GetPlayerVirtualWorld(playerid);
            gMnSpawn[idx][mnInt] = GetPlayerInterior(playerid);
            gMnSpawn[idx][mnActiveSlot] = -1;
            gMnSpawn[idx][mnLastSpawnTick] = 0;

            Mn_SpawnNow(idx);

            SendClientMessage(playerid, -1, "Guarda contratado e posicionado (pago do tesouro).");
            return 1;
            #else
            return SendClientMessage(playerid, -1, "eco_core não está incluído."), 1;
            #endif
        }

        case DLG_MENUNPC_LIST:
        {
            if(!response) return MenuNpc_ShowMain(playerid);
            if(gMnListCount[playerid] <= 0) return MenuNpc_ShowMain(playerid);

            new idx = gMnListMap[playerid][listitem];
            if(idx < 0 || idx >= MENUNPC_MAX_SPAWNS || !gMnSpawn[idx][mnUsed])
                return MenuNpc_ShowSpawnList(playerid);

            gMnPendingRemoveIdx[playerid] = idx;

            ShowPlayerDialog(playerid, DLG_MENUNPC_REMOVE_CONFIRM, DIALOG_STYLE_MSGBOX,
                "Remover", "Remover este spawn? (o NPC some e não respawna mais)", "Remover", "Cancelar");
            return 1;
        }

        case DLG_MENUNPC_REMOVE_CONFIRM:
        {
            if(!response) return MenuNpc_ShowSpawnList(playerid);

            new idx = gMnPendingRemoveIdx[playerid];
            gMnPendingRemoveIdx[playerid] = -1;

            if(idx < 0 || idx >= MENUNPC_MAX_SPAWNS || !gMnSpawn[idx][mnUsed])
                return MenuNpc_ShowSpawnList(playerid);

            if(Mn_IsAliveSlot(gMnSpawn[idx][mnActiveSlot]))
                SHRP_NpcDestroy(gMnSpawn[idx][mnActiveSlot]);

            Mn_ResetSpawn(idx);

            SendClientMessage(playerid, -1, "Spawn removido.");
            return MenuNpc_ShowSpawnList(playerid);
        }
    }
    return 0;
}

// -------------------- CLONES (KAGE BUNSHIN) --------------------
stock Bunshin_Clear(playerid)
{
    for(new c=0; c<BUNSHIN_MAX_CLONES; c++)
    {
        new slot = gBunshinSlots[playerid][c];
        if(Mn_IsAliveSlot(slot)) SHRP_NpcDestroy(slot);
        gBunshinSlots[playerid][c] = -1;
    }
    gBunshinExpireTick[playerid] = 0;
    return 1;
}

stock Jutsu_KageBunshin(playerid)
{
    new now = GetTickCount();
    if(now < gBunshinNextUseTick[playerid])
        return SendClientMessage(playerid, -1, "(JUTSU) Aguarde o cooldown do Bunshin."), 1;

    // chakra (usa seu core do GM)
    if(Info[playerid][pChakraEnUso] < BUNSHIN_CHAKRA_COST) return SemChakra(playerid);
    BaixarChakra(playerid, BUNSHIN_CHAKRA_COST);

    Bunshin_Clear(playerid);

    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    new vw = GetPlayerVirtualWorld(playerid);
    new interior = GetPlayerInterior(playerid);
    new vila = Info[playerid][pMember];
    new skin = GetPlayerSkin(playerid);

    new pname[MAX_PLAYER_NAME];
    GetPlayerName(playerid, pname, sizeof pname);

    for(new c=0; c<BUNSHIN_MAX_CLONES; c++)
    {
        new Float:ox = x + (c == 0 ? 1.2 : c == 1 ? -1.2 : 0.0);
        new Float:oy = y + (c == 2 ? 1.2 : 0.0);

        new cname[32];
        format(cname, sizeof cname, "Bunshin_%d_%d", playerid, c);

        new slot = SHRP_NpcCreate(cname, skin, NPCT_GUARD, vila, ox, oy, z, vw, interior);
        if(slot != -1)
        {
            SHRP_NpcSetRewards(slot, 0, 0);
            SHRP_NpcSetHP(slot, 80.0);
            gNpcAggroRange[slot] = 22.0;
            gNpcAttackRange[slot] = 2.5;

            SHRP_NpcSetOwner(slot, playerid, 2.0); // segue e ataca inimigos perto do dono
            gBunshinSlots[playerid][c] = slot;
        }
        else gBunshinSlots[playerid][c] = -1;
    }

    gBunshinExpireTick[playerid] = now + BUNSHIN_LIFETIME_MS;
    gBunshinNextUseTick[playerid] = now + BUNSHIN_COOLDOWN_MS;

    SendClientMessage(playerid, -1, "(JUTSU) Kage Bunshin criado!");
    return 1;
}

stock MenuNpc_OnPlayerDisconnect(playerid)
{
    Bunshin_Clear(playerid);
    return 1;
}
