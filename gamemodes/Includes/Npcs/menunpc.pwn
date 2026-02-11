// ==========================================================
//  menunpc.pwn  (UI + spawns shinobi_ai + ponte bandidos)
//  Coloque em: Includes/Npcs/menunpc.pwn
// ==========================================================
#if defined _SHRP_MENUNPC_INCLUDED
    #endinput
#endif
#define _SHRP_MENUNPC_INCLUDED

#include <a_samp>

// Economia (tesouro) - include seguro (eco_core tem include-guard)
#include "Includes/Economia/eco_core.pwn"

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
#define DLG_MENUNPC_SET_SKIN      (24505)
#define DLG_MENUNPC_SET_HP        (24506)
#define DLG_MENUNPC_XP_LIST       (24507)
#define DLG_MENUNPC_XP_SET        (24508)

#define DLG_MENUNPC_BUN_LIST     (6612)
#define DLG_MENUNPC_BUN_SET      (6613)
// -------------------- CONFIG --------------------
#define MENUNPC_MAX_SPAWNS        (120)

// clones
#define BUNSHIN_MAX_CLONES        (6)
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
    bool:mnPendingSkin, // aguardando o jogador definir a skin
    bool:mnPendingHP,   // aguardando o jogador definir a vida

    mnType,
    mnTemplate,
    mnVila,
    mnEcoVila,
    mnSkin,
    Float:mnHPMax,
    mnRespawnMs,
    mnCost,                 // usado em guardas do tesouro
    mnXPOverride,            // -1 = usa template; >=0 = override de XP do spawn
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

// XP panel (admin)
new gMnXpListMap[MAX_PLAYERS][MENUNPC_MAX_SPAWNS];
new gMnXpListCount[MAX_PLAYERS];
new gMnXpEditIdx[MAX_PLAYERS];

// pendência de criação (skin)
new gMnPendingSkinIdx[MAX_PLAYERS];
new bool:gMnPendingSkinIsGuard[MAX_PLAYERS];

// -------------------- CLONES --------------------
new gBunshinSlots[MAX_PLAYERS][BUNSHIN_MAX_CLONES];
// posições de spawn do bunshin (para alinhar FX e spawn)
new Float:gBunshinSpawnX[MAX_PLAYERS][BUNSHIN_MAX_CLONES];
new Float:gBunshinSpawnY[MAX_PLAYERS][BUNSHIN_MAX_CLONES];
new Float:gBunshinSpawnZ[MAX_PLAYERS][BUNSHIN_MAX_CLONES];
new gBunshinSpawnVW[MAX_PLAYERS];
new gBunshinSpawnInterior[MAX_PLAYERS];
new gBunshinSpawnSkin[MAX_PLAYERS];

new gBunshinExpireTick[MAX_PLAYERS];
new gBunshinNextUseTick[MAX_PLAYERS];

// permissão/limite do Bunshin (controlado por ADMIN)
new gBunshinGranted[MAX_PLAYERS];          // 0 = não tem, 1 = liberado
new gBunshinGrantedMax[MAX_PLAYERS];       // limite liberado (admin)
new gBunshinToSpawn[MAX_PLAYERS];          // quantidade que vai spawnar no cast atual

// Painel Bunshin (Admin)
new gMnBunListCount[MAX_PLAYERS];
new gMnBunListMap[MAX_PLAYERS][MAX_PLAYERS]; // listitem -> targetid
new gMnBunTarget[MAX_PLAYERS];


// -------------------- ACCESS (AJUSTE AQUI) --------------------
stock bool:MenuNpc_CanUse(playerid)
{
    // Sugestão: restringir pra staff.
    // Ex.: return (Info[playerid][pAdmin] >= 1);
    return true;
}

stock bool:MenuNpc_IsAdmin(playerid)
{
    // Ajuste se seu GM usar outro nível.
    // pAdminZC existe no SHRP.
    if(IsPlayerAdmin(playerid)) return true; // RCON
    return (Info[playerid][pAdminZC] >= 1);
}

stock bool:MenuNpc_IsKage(playerid)
{
    #if defined _ECO_CORE_INCLUDED
        return Eco_IsPlayerKage(playerid);
    #else
        // fallback: usa flag do seu GM (compat com /darkage)
        #if defined pKage
            return (Info[playerid][pKage] >= 1);
        #else
            return false;
        #endif
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
    gMnSpawn[i][mnPendingSkin] = false;
    gMnSpawn[i][mnPendingHP] = false;
    gMnSpawn[i][mnType] = SPAWN_NONE;
    gMnSpawn[i][mnTemplate] = 0;
    gMnSpawn[i][mnVila] = 0;
    gMnSpawn[i][mnEcoVila] = 0;
    gMnSpawn[i][mnSkin] = 0;
    gMnSpawn[i][mnHPMax] = 0.0;
    gMnSpawn[i][mnRespawnMs] = 0;
    gMnSpawn[i][mnCost] = 0;
    gMnSpawn[i][mnXPOverride] = -1;
    gMnSpawn[i][mnX] = 0.0;
    gMnSpawn[i][mnY] = 0.0;
    gMnSpawn[i][mnZ] = 0.0;
    gMnSpawn[i][mnVW] = 0;
    gMnSpawn[i][mnInt] = 0;
    gMnSpawn[i][mnActiveSlot] = -1;
    gMnSpawn[i][mnLastSpawnTick] = 0;
    return 1;
}


stock bool:Mn_IsValidSkin(skin)
{
    if(skin >= 0 && skin <= 311) return true;
    // SA-MP 0.3.DL custom skins via artconfig (ex: AddCharModel)
    if(skin >= 20001 && skin <= 20226) return true;
    return false;
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
            SHRP_NpcSetTaijutsu(slot, 30);
            SHRP_NpcSetRewards(slot, 35, 80);
            gNpcAggroRange[slot] = 20.0;
            gNpcAttackRange[slot] = 2.5;
        }
        case MOB_TPL_MEDIO:
        {
            SHRP_NpcSetHP(slot, 180.0);
            SHRP_NpcSetTaijutsu(slot, 60);
            SHRP_NpcSetRewards(slot, 65, 150);
            gNpcAggroRange[slot] = 25.0;
            gNpcAttackRange[slot] = 2.6;
        }
        case MOB_TPL_BOSS:
        {
            SHRP_NpcSetHP(slot, 520.0);
            SHRP_NpcSetTaijutsu(slot, 120);
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
            SHRP_NpcSetTaijutsu(slot, 90);
            gNpcAggroRange[slot] = 40.0;
            gNpcAttackRange[slot] = 2.6;
            SHRP_NpcSetPatrolRadius(slot, 3.0); // fica "no portão"
        }
        case GUARD_TPL_PATROL:
        {
            SHRP_NpcSetHP(slot, 220.0);
            SHRP_NpcSetTaijutsu(slot, 80);
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
    if(gMnSpawn[i][mnType] == SPAWN_MOB) format(name, sizeof name, "Mob%d", i);
    else                                  format(name, sizeof name, "Guarda%d", i);

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

    // Override de VIDA definido no menu
    if(gMnSpawn[i][mnHPMax] > 0.0) SHRP_NpcSetHP(slot, gMnSpawn[i][mnHPMax]);

    // Override de XP (somente staff deve setar via /npcxp)
    if(gMnSpawn[i][mnXPOverride] >= 0)
    {
        gNpcXPReward[slot] = gMnSpawn[i][mnXPOverride];
    }

    return 1;
}

forward Mn_Tick();
public Mn_Tick()
{
    new now = GetTickCount();

    for(new i=0; i<MENUNPC_MAX_SPAWNS; i++)
    {
        if(!gMnSpawn[i][mnUsed]) continue;
        if(gMnSpawn[i][mnPendingSkin] || gMnSpawn[i][mnPendingHP]) continue;

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
            for(new c=0; c<gBunshinToSpawn[p]; c++)
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
        gMnXpEditIdx[p] = -1;
        gMnXpListCount[p] = 0;
        gMnPendingSkinIdx[p] = -1;
        gMnPendingSkinIsGuard[p] = false;

        for(new c=0; c<BUNSHIN_MAX_CLONES; c++) gBunshinSlots[p][c] = -1;
        gBunshinExpireTick[p] = 0;
        gBunshinNextUseTick[p] = 0;
        gBunshinGranted[p] = 0;
        gBunshinGrantedMax[p] = 0;
        gBunshinToSpawn[p] = 0;
        gMnBunListCount[p] = 0;
        gMnBunTarget[p] = INVALID_PLAYER_ID;
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
    strcat(list, "Painel XP (ADMIN)\n");
    strcat(list, "Painel Bunshin (ADMIN)\n");
    strcat(list, "Criar NPC FALANTE (wizard bandidos)\n");

#if defined _ECO_CORE_INCLUDED
    {
        new vila = Eco_GetKageVilaFromPlayer(playerid);
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

stock MenuNpc_ShowSetSkin(playerid, defaultSkin, bool:isGuard)
{
    new txt[256];
    format(txt, sizeof txt, "Digite o ID da skin (0-311).\nPode usar skin custom do artconfig (ex: 305).\n\nPadrão: %d", defaultSkin);

    new title[32];
    if(isGuard) format(title, sizeof title, "Skin do Guarda");
    else format(title, sizeof title, "Skin do MOB");

    ShowPlayerDialog(playerid, DLG_MENUNPC_SET_SKIN, DIALOG_STYLE_INPUT,
        title, txt, "Criar", "Voltar");
    return 1;
}


stock MenuNpc_ShowSetHP(playerid, Float:defaultHP, bool:isGuard)
{
    new txt[256];
    format(txt, sizeof txt, "Digite a VIDA do NPC (ex: 120, 250, 450).\n\nPadrão: %.0f", defaultHP);

    new title[32];
    if(isGuard) format(title, sizeof title, "Vida do Guarda");
    else format(title, sizeof title, "Vida do MOB");

    ShowPlayerDialog(playerid, DLG_MENUNPC_SET_HP, DIALOG_STYLE_INPUT,
        title, txt, "Criar", "Voltar");
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
        strcat(out, "\t(sem spawns)\t\n", outSize);

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

// -------------------- XP PANEL (ADMIN) --------------------
stock Mn_GetDefaultXpBySpawn(spawnid)
{
    if(spawnid < 0 || spawnid >= MENUNPC_MAX_SPAWNS || !gMnSpawn[spawnid][mnUsed]) return 0;

    if(gMnSpawn[spawnid][mnType] == SPAWN_MOB)
    {
        switch(gMnSpawn[spawnid][mnTemplate])
        {
            case MOB_TPL_FRACO: return 35;
            case MOB_TPL_MEDIO: return 65;
            case MOB_TPL_BOSS:  return 260;
        }
        return 35;
    }
    // Guard/Patrulha por padrão não dá XP
    return 0;
}

stock MenuNpc_BuildXpList(playerid, out[], outSize)
{
    out[0] = '\0';
    strcat(out, "ID\tTipo\tXP Atual\n", outSize);

    gMnXpListCount[playerid] = 0;

    for(new i=0; i<MENUNPC_MAX_SPAWNS; i++)
    {
        if(!gMnSpawn[i][mnUsed]) continue;

        new typeName[12];
        if(gMnSpawn[i][mnType] == SPAWN_MOB) format(typeName, sizeof typeName, "MOB");
        else format(typeName, sizeof typeName, "GUARDA");

        new defxp = Mn_GetDefaultXpBySpawn(i);
        new curxp = (gMnSpawn[i][mnXPOverride] >= 0) ? gMnSpawn[i][mnXPOverride] : defxp;

        new line[128];
        if(gMnSpawn[i][mnXPOverride] >= 0)
            format(line, sizeof line, "%d\t%s\t%d (override)\n", i, typeName, curxp);
        else
            format(line, sizeof line, "%d\t%s\t%d (padrao)\n", i, typeName, curxp);

        strcat(out, line, outSize);

        gMnXpListMap[playerid][gMnXpListCount[playerid]++] = i;
        if(gMnXpListCount[playerid] >= MENUNPC_MAX_SPAWNS) break;
    }

    if(gMnXpListCount[playerid] == 0)
        strcat(out, "\t(sem spawns)\t\n", outSize);

    return 1;
}

stock MenuNpc_ShowXpPanel(playerid)
{
    if(!MenuNpc_IsAdmin(playerid))
        return SendClientMessage(playerid, -1, "Somente administrador pode editar XP de MOB/NPC."), 1;

    new list[2048];
    MenuNpc_BuildXpList(playerid, list, sizeof list);

    ShowPlayerDialog(playerid, DLG_MENUNPC_XP_LIST, DIALOG_STYLE_TABLIST_HEADERS,
        "Painel XP (Admin)", list, "Editar", "Voltar");
    return 1;
}

stock MenuNpc_ShowBunPanel(playerid)
{
    if(!MenuNpc_IsAdmin(playerid)) return MenuNpc_ShowMain(playerid);

    new list[4096];
    format(list, sizeof list, "Player\tClones\n");

    gMnBunListCount[playerid] = 0;

    foreach(Player, i)
    {
        if(!IsPlayerConnected(i) || IsPlayerNPC(i)) continue;
        if(gMnBunListCount[playerid] >= MAX_PLAYERS) break;

        new nome[MAX_PLAYER_NAME];
        GetPlayerName(i, nome, sizeof nome);

        new cur = (gBunshinGranted[i]) ? gBunshinGrantedMax[i] : 0;

        new linha[128];
        format(linha, sizeof linha, "%s (%d)\t%d\n", nome, i, cur);
        strcat(list, linha);

        gMnBunListMap[playerid][gMnBunListCount[playerid]++] = i;
    }

    ShowPlayerDialog(playerid, DLG_MENUNPC_BUN_LIST, DIALOG_STYLE_TABLIST_HEADERS,
        "Painel Bunshin (Admin)", list, "Editar", "Voltar");
    return 1;
}


stock MenuNpc_ShowSetXP(playerid, spawnid)
{
    new defxp = Mn_GetDefaultXpBySpawn(spawnid);
    new curxp = (gMnSpawn[spawnid][mnXPOverride] >= 0) ? gMnSpawn[spawnid][mnXPOverride] : defxp;

    new txt[256];
    format(txt, sizeof txt,
        "Spawn %d\n\nXP atual: %d\nXP padrão do template: %d\n\nDigite o XP.\nUse -1 para voltar ao padrão.",
        spawnid, curxp, defxp);

    ShowPlayerDialog(playerid, DLG_MENUNPC_XP_SET, DIALOG_STYLE_INPUT,
        "Definir XP", txt, "Salvar", "Voltar");
    return 1;
}

// -------------------- COMMAND --------------------
CMD:menunpc(playerid, params[])
{
    if(!MenuNpc_CanUse(playerid)) return SendClientMessage(playerid, -1, "Sem permissao."), 1;
    return MenuNpc_ShowMain(playerid);
}


CMD:npcxp(playerid, params[])
{
    if(!MenuNpc_IsAdmin(playerid))
        return SendClientMessage(playerid, -1, "Somente administrador pode definir XP de MOB/NPC."), 1;

    new idx = 0;
    new tok[32];

    if(!Mn_NextTok(params, idx, tok, sizeof tok))
        return SendClientMessage(playerid, -1, "Uso: /npcxp <spawnId|npcid> <xp>"), 1;

    new id = strval(tok);

    if(!Mn_NextTok(params, idx, tok, sizeof tok))
        return SendClientMessage(playerid, -1, "Uso: /npcxp <spawnId|npcid> <xp>"), 1;

    new xp = strval(tok);
    // Use -1 para voltar ao XP padrão do template (somente spawns do /menunpc)
    if(xp < 0) xp = -1;
    if(xp > 5000) xp = 5000;

    // 1) Se for um SPAWN do /menunpc
    if(id >= 0 && id < MENUNPC_MAX_SPAWNS && gMnSpawn[id][mnUsed])
    {
        gMnSpawn[id][mnXPOverride] = xp;

        new slot = gMnSpawn[id][mnActiveSlot];
        if(Mn_IsAliveSlot(slot))
        {
            new defxp = Mn_GetDefaultXpBySpawn(id);
            new finalxp = (xp >= 0) ? xp : defxp;
            gNpcXPReward[slot] = finalxp;
        }

        new msg[96];
        format(msg, sizeof msg, "XP do spawn %d setado para %d.", id, xp);
        SendClientMessage(playerid, -1, msg);
        return 1;
    }

    // 2) Fallback: setar no NPC vivo (não persiste)
    #if defined SHRP_NpcSlotFromId
        new slot2 = SHRP_NpcSlotFromId(id);
        if(slot2 != -1 && Mn_IsAliveSlot(slot2))
        {
            gNpcXPReward[slot2] = (xp >= 0) ? xp : 0;
            new msg2[128];
            format(msg2, sizeof msg2, "XP aplicado no NPC %d (slot %d) para %d (nao persiste em respawn).", id, slot2, xp);
            SendClientMessage(playerid, -1, msg2);
            return 1;
        }
    #endif

    return SendClientMessage(playerid, -1, "ID invalido. Use um spawnId do /menunpc (lista) ou um npcid vivo."), 1;
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
                case 3: return MenuNpc_ShowXpPanel(playerid);
                case 4: return MenuNpc_ShowBunPanel(playerid);
                case 5: return BandidoMenu_Start(playerid);
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
            gMnSpawn[idx][mnPendingSkin] = true;
            gMnSpawn[idx][mnPendingHP] = false;
            gMnSpawn[idx][mnType] = SPAWN_MOB;
            gMnSpawn[idx][mnTemplate] = tpl;
            gMnSpawn[idx][mnVila] = 0; // mob ataca todos
            gMnSpawn[idx][mnEcoVila] = 0;
            gMnSpawn[idx][mnSkin] = 105; // skin padrão (pode trocar no próximo dialog)
            gMnSpawn[idx][mnHPMax] = (tpl == MOB_TPL_FRACO) ? 120.0 : (tpl == MOB_TPL_MEDIO) ? 220.0 : 450.0;
            gMnSpawn[idx][mnRespawnMs] = respawn;
            gMnSpawn[idx][mnCost] = 0;
            gMnSpawn[idx][mnXPOverride] = -1;

            gMnSpawn[idx][mnX] = x; gMnSpawn[idx][mnY] = y; gMnSpawn[idx][mnZ] = z;
            gMnSpawn[idx][mnVW] = GetPlayerVirtualWorld(playerid);
            gMnSpawn[idx][mnInt] = GetPlayerInterior(playerid);
            gMnSpawn[idx][mnActiveSlot] = -1;
            gMnSpawn[idx][mnLastSpawnTick] = GetTickCount();

            gMnPendingSkinIdx[playerid] = idx;
            gMnPendingSkinIsGuard[playerid] = false;

            return MenuNpc_ShowSetSkin(playerid, 105, false);
        }

        case DLG_MENUNPC_GUARD_TPL:
        {
            if(!response) return MenuNpc_ShowMain(playerid);

            if(!MenuNpc_IsKage(playerid))
                return SendClientMessage(playerid, -1, "Somente o Kage pode contratar guardas pelo tesouro."), 1;

            #if defined _ECO_CORE_INCLUDED
            new ecoVila = Eco_GetKageVilaFromPlayer(playerid);
            if(ecoVila <= 0) return SendClientMessage(playerid, -1, "Você não tem vila válida."), 1;

            // Bandana / vila do Kage (usa o mesmo ID do SistemaBandanaIDStatus)
            new bandanaVila = Info[playerid][pMember];
            if(bandanaVila < 1 || bandanaVila > 5) return SendClientMessage(playerid, -1, "Sua bandana/vila está inválida para contratar guardas."), 1;

            new tpl = (listitem == 0) ? GUARD_TPL_GATE : GUARD_TPL_PATROL;
            new cost = (tpl == GUARD_TPL_GATE) ? 2000 : 3000;

            if(gEcoTreasury[ecoVila] < cost)
                return SendClientMessage(playerid, -1, "Tesouro insuficiente."), 1;

            new idx = Mn_FindFreeSpawn();
            if(idx == -1) return SendClientMessage(playerid, -1, "Sem espaco de spawn."), 1;

            new Float:x, Float:y, Float:z;
            GetPlayerPos(playerid, x, y, z);

            // reserva o spawn e cobra do tesouro (se cancelar, devolve)
            gEcoTreasury[ecoVila] -= cost;

            gMnSpawn[idx][mnUsed] = true;
            gMnSpawn[idx][mnPendingSkin] = true;
            gMnSpawn[idx][mnPendingHP] = false;
            gMnSpawn[idx][mnType] = SPAWN_GUARD;
            gMnSpawn[idx][mnTemplate] = tpl;
            gMnSpawn[idx][mnVila] = bandanaVila;     // guarda ignora mesma vila (bandana) e ataca invasores
            gMnSpawn[idx][mnEcoVila] = ecoVila;      // tesouro/eco (índice da eco_core)
            gMnSpawn[idx][mnSkin] = 287;      // skin padrão
            gMnSpawn[idx][mnHPMax] = (tpl == GUARD_TPL_GATE) ? 320.0 : 280.0;
            gMnSpawn[idx][mnRespawnMs] = 60000;
            gMnSpawn[idx][mnCost] = cost;
             gMnSpawn[idx][mnXPOverride] = -1;

            gMnSpawn[idx][mnX] = x; gMnSpawn[idx][mnY] = y; gMnSpawn[idx][mnZ] = z;
            gMnSpawn[idx][mnVW] = GetPlayerVirtualWorld(playerid);
            gMnSpawn[idx][mnInt] = GetPlayerInterior(playerid);
            gMnSpawn[idx][mnActiveSlot] = -1;
            gMnSpawn[idx][mnLastSpawnTick] = GetTickCount();

            gMnPendingSkinIdx[playerid] = idx;
            gMnPendingSkinIsGuard[playerid] = true;

            return MenuNpc_ShowSetSkin(playerid, 287, true);
            #else
            return SendClientMessage(playerid, -1, "eco_core não está incluído."), 1;
            #endif
        }

        case DLG_MENUNPC_SET_SKIN:
        {
            new idx = gMnPendingSkinIdx[playerid];
            if(idx < 0 || idx >= MENUNPC_MAX_SPAWNS || !gMnSpawn[idx][mnUsed] || !gMnSpawn[idx][mnPendingSkin])
                return MenuNpc_ShowMain(playerid);

            if(!response)
            {
                // cancelou: devolve custo (se for guarda) e apaga
                #if defined _ECO_CORE_INCLUDED
                if(gMnPendingSkinIsGuard[playerid] && gMnSpawn[idx][mnCost] > 0 && gMnSpawn[idx][mnEcoVila] > 0)
                    gEcoTreasury[gMnSpawn[idx][mnEcoVila]] += gMnSpawn[idx][mnCost];
                #endif

                Mn_ResetSpawn(idx);

                gMnPendingSkinIdx[playerid] = -1;
                gMnPendingSkinIsGuard[playerid] = false;

                return MenuNpc_ShowMain(playerid);
            }

            new skin = strval(inputtext);
            if(!Mn_IsValidSkin(skin))
            {
                SendClientMessage(playerid, -1, "Skin inválida. Use 0-311 ou 20001-20226 (skins custom 0.3.DL).");
                return MenuNpc_ShowSetSkin(playerid, gMnSpawn[idx][mnSkin], gMnPendingSkinIsGuard[playerid]);
            }

            gMnSpawn[idx][mnSkin] = skin;
            gMnSpawn[idx][mnPendingSkin] = false;
            gMnSpawn[idx][mnPendingHP] = true;

            // Próximo passo: definir VIDA (para evitar mob fácil/difícil demais)
            return MenuNpc_ShowSetHP(playerid, gMnSpawn[idx][mnHPMax], gMnPendingSkinIsGuard[playerid]);
        }


        case DLG_MENUNPC_SET_HP:
        {
            new idx = gMnPendingSkinIdx[playerid];
            if(idx < 0 || idx >= MENUNPC_MAX_SPAWNS || !gMnSpawn[idx][mnUsed] || !gMnSpawn[idx][mnPendingHP])
                return MenuNpc_ShowMain(playerid);

            if(!response)
            {
                // Voltar para escolher a skin novamente (mantém custo reservado se guarda)
                gMnSpawn[idx][mnPendingHP] = false;
                gMnSpawn[idx][mnPendingSkin] = true;
                return MenuNpc_ShowSetSkin(playerid, gMnSpawn[idx][mnSkin], gMnPendingSkinIsGuard[playerid]);
            }

            if(!strlen(inputtext))
            {
                SendClientMessage(playerid, -1, "Vida inválida. Digite apenas números (ex: 250).");
                return MenuNpc_ShowSetHP(playerid, gMnSpawn[idx][mnHPMax], gMnPendingSkinIsGuard[playerid]);
            }

            new hp_i = strval(inputtext);
            new Float:hp = float(hp_i);
            if(hp < 10.0 || hp > 5000.0)
            {
                SendClientMessage(playerid, -1, "Vida inválida. Use um valor entre 10 e 5000.");
                return MenuNpc_ShowSetHP(playerid, gMnSpawn[idx][mnHPMax], gMnPendingSkinIsGuard[playerid]);
            }

            gMnSpawn[idx][mnHPMax] = hp;
            gMnSpawn[idx][mnPendingHP] = false;

            Mn_SpawnNow(idx);

            gMnPendingSkinIdx[playerid] = -1;
            gMnPendingSkinIsGuard[playerid] = false;

            SendClientMessage(playerid, -1, "NPC criado!");
            return 1;
        }



        case DLG_MENUNPC_XP_LIST:
        {
            if(!MenuNpc_IsAdmin(playerid)) return MenuNpc_ShowMain(playerid);

            if(!response) return MenuNpc_ShowMain(playerid);
            if(gMnXpListCount[playerid] <= 0) return MenuNpc_ShowMain(playerid);

            new idxList = gMnXpListMap[playerid][listitem];
            if(idxList < 0 || idxList >= MENUNPC_MAX_SPAWNS || !gMnSpawn[idxList][mnUsed])
                return MenuNpc_ShowXpPanel(playerid);

            gMnXpEditIdx[playerid] = idxList;
            return MenuNpc_ShowSetXP(playerid, idxList);
        }

        case DLG_MENUNPC_XP_SET:
        {
            if(!MenuNpc_IsAdmin(playerid)) return MenuNpc_ShowMain(playerid);

            new idxList = gMnXpEditIdx[playerid];
            if(idxList < 0 || idxList >= MENUNPC_MAX_SPAWNS || !gMnSpawn[idxList][mnUsed])
                return MenuNpc_ShowXpPanel(playerid);

            if(!response) return MenuNpc_ShowXpPanel(playerid);

            if(!strlen(inputtext))
                return MenuNpc_ShowSetXP(playerid, idxList);

            new xp = strval(inputtext);
            if(xp < 0)
            {
                // volta ao padrão
                gMnSpawn[idxList][mnXPOverride] = -1;
            }
            else
            {
                if(xp > 5000) xp = 5000;
                gMnSpawn[idxList][mnXPOverride] = xp;
            }

            // aplica imediatamente no NPC vivo (se existir)
            new slot = gMnSpawn[idxList][mnActiveSlot];
            if(Mn_IsAliveSlot(slot))
            {
                new defxp = Mn_GetDefaultXpBySpawn(idxList);
                new finalxp = (gMnSpawn[idxList][mnXPOverride] >= 0) ? gMnSpawn[idxList][mnXPOverride] : defxp;
                gNpcXPReward[slot] = finalxp;
            }

            SendClientMessage(playerid, -1, "XP atualizado.");
            return MenuNpc_ShowXpPanel(playerid);
        }

        case DLG_MENUNPC_BUN_LIST:
        {
            if(!MenuNpc_IsAdmin(playerid)) return MenuNpc_ShowMain(playerid);
            if(!response) return MenuNpc_ShowMain(playerid);

            if(gMnBunListCount[playerid] <= 0) return MenuNpc_ShowMain(playerid);
            if(listitem < 0 || listitem >= gMnBunListCount[playerid]) return MenuNpc_ShowBunPanel(playerid);

            new targetid = gMnBunListMap[playerid][listitem];
            if(!IsPlayerConnected(targetid) || IsPlayerNPC(targetid)) return MenuNpc_ShowBunPanel(playerid);

            gMnBunTarget[playerid] = targetid;

            new nome[MAX_PLAYER_NAME];
            GetPlayerName(targetid, nome, sizeof nome);

            new msg[256];
            format(msg, sizeof msg,
                "Defina quantos clones esse player pode usar.\n\n- 0 = revogar\n- 1 = 1 clone\n- 2 = 2 clones (somente Jounin)\n- 3+ = acima de 2 (somente se ADMIN liberar)\n\nPlayer: %s (%d)",
                nome, targetid);

            ShowPlayerDialog(playerid, DLG_MENUNPC_BUN_SET, DIALOG_STYLE_INPUT,
                "Bunshin - Quantidade", msg, "Salvar", "Voltar");
            return 1;
        }

        case DLG_MENUNPC_BUN_SET:
        {
            if(!MenuNpc_IsAdmin(playerid)) return MenuNpc_ShowMain(playerid);

            if(!response) return MenuNpc_ShowBunPanel(playerid);

            new targetid = gMnBunTarget[playerid];
            if(targetid == INVALID_PLAYER_ID || !IsPlayerConnected(targetid) || IsPlayerNPC(targetid))
                return MenuNpc_ShowBunPanel(playerid);

            new amount = strval(inputtext);
            if(amount < 0) amount = 0;
            if(amount > BUNSHIN_MAX_CLONES) amount = BUNSHIN_MAX_CLONES;

            if(amount == 0)
            {
                gBunshinGranted[targetid] = 0;
                gBunshinGrantedMax[targetid] = 0;

                SendClientMessage(playerid, -1, "Bunshin revogado para o player.");
                SendClientMessage(targetid, -1, "(JUTSU) Sua permissão de Kage Bunshin foi revogada.");
                return MenuNpc_ShowBunPanel(playerid);
            }

            gBunshinGranted[targetid] = 1;
            gBunshinGrantedMax[targetid] = amount;

            new msg[96];
            format(msg, sizeof msg, "Bunshin liberado: %d clone(s).", amount);
            SendClientMessage(playerid, -1, msg);
            SendClientMessage(targetid, -1, "(JUTSU) Você recebeu permissão para usar Kage Bunshin.");

            return MenuNpc_ShowBunPanel(playerid);
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
    gBunshinToSpawn[playerid] = 0;
    return 1;
}

stock Bunshin_Effect_Destroy(objid)
{
    DestroyDynamicObject(objid);
    return 1;
}

// ===============================
// BUNSHIN - CONFIG RÁPIDA
// ===============================
// 1 = mostra nametag acima da cabeça (SistemaBandanaIDStatus)
// 0 = não mostra nametag (fica "limpo")
#if !defined BUNSHIN_NAMETAG
    #define BUNSHIN_NAMETAG (0)
#endif

// 1 = herda também clã e rank do dono (fica igualzinho no topo)
#if !defined BUNSHIN_INHERIT_CLAN_RANK
    #define BUNSHIN_INHERIT_CLAN_RANK (1)
#endif

forward Bunshin_DoSpawn(playerid);
public Bunshin_DoSpawn(playerid)
{
    if(!IsPlayerConnected(playerid) || IsPlayerNPC(playerid)) return 1;

    new vw = gBunshinSpawnVW[playerid];
    new interior = gBunshinSpawnInterior[playerid];
    new skin = gBunshinSpawnSkin[playerid];

    // Bunshin herda a vila/bandana do dono (mesmo ID do SistemaBandanaIDStatus)
    new vila = Info[playerid][pMember];

    // Nome EXATO que aparece na sua nametag (usa Info[pNome]; se vazio, cai no nick do SA-MP)
    new donoNome[MAX_PLAYER_NAME];
    format(donoNome, sizeof donoNome, "%s", Info[playerid][pNome]);
    if(donoNome[0] == '\0') GetPlayerName(playerid, donoNome, sizeof donoNome);

    new spawnCount = gBunshinToSpawn[playerid];
    if(spawnCount <= 0) return 1;
    if(spawnCount > BUNSHIN_MAX_CLONES) spawnCount = BUNSHIN_MAX_CLONES;

    for(new c=0; c<spawnCount; c++)
    {
        new Float:ox = gBunshinSpawnX[playerid][c];
        new Float:oy = gBunshinSpawnY[playerid][c];
        new Float:oz = gBunshinSpawnZ[playerid][c];

        // se por algum motivo não foi setado (segurança)
        if(ox == 0.0 && oy == 0.0 && oz == 0.0)
        {
            new Float:px, Float:py, Float:pz;
            GetPlayerPos(playerid, px, py, pz);
            ox = px; oy = py; oz = pz;
        }

        // Nome interno PRECISA ser único (não use nome do player aqui)
        new cname[32];
        format(cname, sizeof cname, "Bunshin_%d_%d", playerid, c);

        new slot = SHRP_NpcCreate(cname, skin, NPCT_GUARD, vila, ox, oy, oz, vw, interior);
        if(slot != -1)
        {
            new npcid = SHRP_NpcGetId(slot);

            SHRP_NpcSetRewards(slot, 0, 0);
            SHRP_NpcSetHP(slot, 80.0);
            SHRP_NpcSetTaijutsu(slot, floatround(Info[playerid][pTaijutsu] * 0.70));

            // segue o dono e ataca inimigos perto dele
            SHRP_NpcSetOwner(slot, playerid, 2.0);

            // ====== NOME + VILA iguais ao dono (pro seu SistemaBandanaIDStatus) ======
            if(npcid != INVALID_PLAYER_ID)
            {
                format(Info[npcid][pNome], MAX_PLAYER_NAME, "%s", donoNome);
                Info[npcid][pMember] = vila;

                #if BUNSHIN_INHERIT_CLAN_RANK
                    Info[npcid][pClan] = Info[playerid][pClan];
                    NinjaFamaRank[npcid] = NinjaFamaRank[playerid];
                #endif

                // Toggle fácil da nametag do bunshin
                #if defined SHRP_NpcSetTagEnabled
                    SHRP_NpcSetTagEnabled(slot, (BUNSHIN_NAMETAG != 0));
                #endif

                #if BUNSHIN_NAMETAG
                    // força atualizar o label depois de copiar nome/vila
                    if(funcidx("SistemaBandanaIDStatus") != -1)
                        CallLocalFunction("SistemaBandanaIDStatus", "i", npcid);
                #endif
            }

            gBunshinSlots[playerid][c] = slot;
        }
        else gBunshinSlots[playerid][c] = -1;
    }

    return 1;
}


stock Jutsu_KageBunshin(playerid)
{
    new now = GetTickCount();
    if(now < gBunshinNextUseTick[playerid])
        return SendClientMessage(playerid, -1, "(JUTSU) Aguarde o cooldown do Bunshin."), 1;

    // Permissão do Bunshin: só usa se um ADMIN liberou (Painel Bunshin / /darclone)
    if(!gBunshinGranted[playerid] || gBunshinGrantedMax[playerid] <= 0)
        return SendClientMessage(playerid, -1, "(JUTSU) Você não possui permissão para usar Kage Bunshin."), 1;

    // Regra de quantidade:
    // - Genin/Chunin/etc: máximo 1 se a liberação do admin for 1 ou 2
    // - Jounin: máximo 2 se a liberação do admin for 2
    // - Acima de 2: somente admin pode liberar, então respeita o valor liberado
    new allowed = gBunshinGrantedMax[playerid];
    new spawnCount;

    if(allowed <= 2)
    {
        if(Info[playerid][pRank] == 3) // Jounin
            spawnCount = (allowed >= 2) ? 2 : 1;
        else
            spawnCount = 1;
    }
    else
    {
        spawnCount = allowed;
        if(spawnCount > BUNSHIN_MAX_CLONES) spawnCount = BUNSHIN_MAX_CLONES;
    }
    // chakra (usa seu core do GM)
    if(Info[playerid][pChakraEnUso] < BUNSHIN_CHAKRA_COST) return SemChakra(playerid);
    BaixarChakra(playerid, BUNSHIN_CHAKRA_COST);

    Bunshin_Clear(playerid);


    gBunshinToSpawn[playerid] = spawnCount;
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    new vw = GetPlayerVirtualWorld(playerid);
    new interior = GetPlayerInterior(playerid);
    new skin = GetPlayerSkin(playerid);

    
// som do jutsu
AudioInPlayer(playerid, 25.0, 144);

// guarda dados do spawn (para alinhar FX + clones)
gBunshinSpawnVW[playerid] = vw;
gBunshinSpawnInterior[playerid] = interior;
gBunshinSpawnSkin[playerid] = skin;

// calcula os pontos onde cada clone vai nascer e cria o FX primeiro nesses pontos
for(new c=0; c<gBunshinToSpawn[playerid]; c++)
{
    // offsets fixos (mesmos usados no spawn)
    new Float:ox = x + (c == 0 ? 1.2 : c == 1 ? -1.2 : 0.0);
    new Float:oy = y + (c == 2 ? 1.2 : 0.0);

    gBunshinSpawnX[playerid][c] = ox;
    gBunshinSpawnY[playerid][c] = oy;
    gBunshinSpawnZ[playerid][c] = z;

    new obj = CreateDynamicObject(18737, ox, oy, z, 0.0, 0.0, 0.0, vw, interior, -1, 60.0, 60.0);
    SetTimerEx("Bunshin_Effect_Destroy", 700, false, "i", obj);
}

// spawn ligeiramente depois do efeito (em cima dos pontos salvos)
SetTimerEx("Bunshin_DoSpawn", 450, false, "i", playerid);

gBunshinExpireTick[playerid] = now + BUNSHIN_LIFETIME_MS;
    gBunshinNextUseTick[playerid] = now + BUNSHIN_COOLDOWN_MS;

    SendClientMessage(playerid, -1, "(JUTSU) Kage Bunshin criado!");
    return 1;
}



// -------------------- ORDENS / CONFIG (STAFF / TESTE) --------------------
// /npcordem <npcid> <seguir|ficar|atacar|voltar> [alvo]
// /npcjutsu <npcid> <cmd> <cooldownMs> <needTarget 0/1>
stock Mn_NextTok(const str[], &idx, out[], outlen)
{
    // pula espacos
    while(str[idx] == ' ') idx++;
    if(str[idx] == '\0') { out[0] = '\0'; return 0; }

    new j = 0;
    while(str[idx] != '\0' && str[idx] != ' ' && j < outlen-1)
    {
        out[j++] = str[idx++];
    }
    out[j] = '\0';
    return 1;
}

CMD:npcordem(playerid, params[])
{
    if(!MenuNpc_CanUse(playerid)) return 1;

    new idx = 0;
    new tok[32];

    if(!Mn_NextTok(params, idx, tok, sizeof tok)) return SendClientMessage(playerid, -1, "Uso: /npcordem <npcid> <seguir|ficar|atacar|voltar> [alvo]"), 1;
    new npcid = strval(tok);

    if(!Mn_NextTok(params, idx, tok, sizeof tok)) return SendClientMessage(playerid, -1, "Uso: /npcordem <npcid> <seguir|ficar|atacar|voltar> [alvo]"), 1;

    #if !defined SHRP_NpcSlotFromId
        return SendClientMessage(playerid, -1, "ERRO: shinobi_ai nao esta incluso."), 1;
    #else
        new slot = SHRP_NpcSlotFromId(npcid);
        if(slot == -1 || !Mn_IsAliveSlot(slot)) return SendClientMessage(playerid, -1, "NPC invalido."), 1;

        // so o dono controla guard/clone
        if(gNpcOwner[slot] != INVALID_PLAYER_ID && gNpcOwner[slot] != playerid)
            return SendClientMessage(playerid, -1, "Voce nao e o dono desse NPC."), 1;

        if(!strcmp(tok, "seguir", true))
        {
            SHRP_NpcSetOwner(slot, playerid, 2.0);
            SendClientMessage(playerid, -1, "NPC agora esta seguindo voce.");
            return 1;
        }
        if(!strcmp(tok, "ficar", true))
        {
            gNpcOwner[slot] = playerid;
            gNpcTarget[slot] = INVALID_PLAYER_ID;
            gNpcState[slot] = NPCS_IDLE;
            FCNPC_Stop(npcid);
            SendClientMessage(playerid, -1, "NPC agora esta parado.");
            return 1;
        }
        if(!strcmp(tok, "voltar", true))
        {
            gNpcTarget[slot] = INVALID_PLAYER_ID;
            gNpcOwner[slot] = INVALID_PLAYER_ID;
            gNpcState[slot] = NPCS_PATROL;
            SendClientMessage(playerid, -1, "NPC voltou para patrulha/area.");
            return 1;
        }
        if(!strcmp(tok, "atacar", true))
        {
            if(!Mn_NextTok(params, idx, tok, sizeof tok)) return SendClientMessage(playerid, -1, "Uso: /npcordem <npcid> atacar <alvoid>"), 1;
            new targetid = strval(tok);
            if(!IsPlayerConnected(targetid)) return SendClientMessage(playerid, -1, "Alvo invalido."), 1;
            gNpcTarget[slot] = targetid;
            gNpcState[slot] = NPCS_CHASE;
            SendClientMessage(playerid, -1, "NPC indo atacar o alvo.");
            return 1;
        }

        SendClientMessage(playerid, -1, "Comando invalido. Use: seguir, ficar, atacar, voltar.");
        return 1;
    #endif
}

CMD:npcjutsu(playerid, params[])
{
    if(!MenuNpc_CanUse(playerid)) return 1;

    new idx = 0;
    new tok[64];

    if(!Mn_NextTok(params, idx, tok, sizeof tok)) return SendClientMessage(playerid, -1, "Uso: /npcjutsu <npcid> <cmd> <cooldownMs> <needTarget 0/1>"), 1;
    new npcid = strval(tok);

    new cmdname[32];
    if(!Mn_NextTok(params, idx, cmdname, sizeof cmdname)) return SendClientMessage(playerid, -1, "Uso: /npcjutsu <npcid> <cmd> <cooldownMs> <needTarget 0/1>"), 1;

    if(!Mn_NextTok(params, idx, tok, sizeof tok)) return SendClientMessage(playerid, -1, "Uso: /npcjutsu <npcid> <cmd> <cooldownMs> <needTarget 0/1>"), 1;
    new cd = strval(tok);

    if(!Mn_NextTok(params, idx, tok, sizeof tok)) return SendClientMessage(playerid, -1, "Uso: /npcjutsu <npcid> <cmd> <cooldownMs> <needTarget 0/1>"), 1;
    new need = strval(tok);

    #if !defined SHRP_NpcSlotFromId
        return SendClientMessage(playerid, -1, "ERRO: shinobi_ai nao esta incluso."), 1;
    #else
        new slot = SHRP_NpcSlotFromId(npcid);
        if(slot == -1 || !Mn_IsAliveSlot(slot)) return SendClientMessage(playerid, -1, "NPC invalido."), 1;

        if(gNpcOwner[slot] != INVALID_PLAYER_ID && gNpcOwner[slot] != playerid)
            return SendClientMessage(playerid, -1, "Voce nao e o dono desse NPC."), 1;

        SHRP_NpcSetJutsu(slot, cmdname, (need != 0), cd);
        SendClientMessage(playerid, -1, "Jutsu configurado no NPC.");
        return 1;
    #endif
}

stock MenuNpc_OnPlayerDisconnect(playerid)
{
    // se estava no meio de criar um NPC (skin pendente), cancela e devolve o custo
    if(gMnPendingSkinIdx[playerid] != -1)
    {
        new idx = gMnPendingSkinIdx[playerid];
        if(idx >= 0 && idx < MENUNPC_MAX_SPAWNS && gMnSpawn[idx][mnUsed] && gMnSpawn[idx][mnPendingSkin])
        {
            #if defined _ECO_CORE_INCLUDED
            if(gMnPendingSkinIsGuard[playerid] && gMnSpawn[idx][mnCost] > 0 && gMnSpawn[idx][mnEcoVila] > 0)
                gEcoTreasury[gMnSpawn[idx][mnEcoVila]] += gMnSpawn[idx][mnCost];
            #endif

            Mn_ResetSpawn(idx);
        }
        gMnPendingSkinIdx[playerid] = -1;
        gMnPendingSkinIsGuard[playerid] = false;
    }

    Bunshin_Clear(playerid);
    return 1;
}