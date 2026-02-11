// ==========================================================
// SHRP - Shinobi NPC System (Areas + Patrol Contracts)
// Arquivo sugerido: Includes/Npcs/shinobi_system.pwn
// - Mantem separado do bandidos.pwn (NPCGPT/fala) para nao quebrar o que ja esta ok.
// - Foco: menus para ADMIN/KAGE + areas de mobs (upar XP) + patrulheiros pagos pelo tesouro.
// - Sem veiculos (somente a pe).
//
// Integracao no seu GM:
// 1) #include "Includes/Npcs/shinobi_system.pwn" (depois do enum Info/pMember/pKage e DataBancoKage)
// 2) Em OnGameModeInit():     ShinobiSys_OnGameModeInit();
// 3) Em OnGameModeExit():     ShinobiSys_OnGameModeExit();
// 4) Em OnDialogResponse():   if(ShinobiSys_OnDialog(playerid, dialogid, response, listitem, inputtext)) return 1;
// 5) Em OnPlayerDeath():      ShinobiSys_OnPlayerDeath(playerid, killerid, reason);
//
// Observacao:
// - Para integrar 100% com seus jutsus/efeitos/combate, voce pode criar as funcoes opcionais:
//     NPC_Combat_Melee(npcid, targetid, style)  // usa seu sistema real (espada/adaga/taijutsu)
//     NPC_Combat_Jutsu(npcid, targetid, elem)   // usa seu sistema real de jutsu (katon/suiton/...)
//   Se nao existir, este include aplica dano "generico" via GetDamageToPlayer/SetDamageToPlayer.
//
// ==========================================================

#if defined _SHRP_SHINOBI_SYSTEM_INCLUDED
    #endinput
#endif
#define _SHRP_SHINOBI_SYSTEM_INCLUDED

#include <a_samp>

// FCNPC.inc exige simbolo HTTP em alguns setups.
#if !defined HTTP
    native HTTP(index, type, const url[], const data[], const callback[]);
#endif
#if !defined HTTP_GET
    #define HTTP_GET     (1)
    #define HTTP_POST    (2)
#endif

#include <FCNPC>
// Defaults caso seu GM nao tenha os defines disponiveis antes deste include
#if !defined MELEE
    #define MELEE (4)
#endif
#if !defined KENJUTSU
    #define KENJUTSU (5)
#endif
#if !defined KATON
    #define KATON (0)
#endif
#if !defined FUTON
    #define FUTON (1)
#endif
#if !defined RAITON
    #define RAITON (2)
#endif
#if !defined DOTON
    #define DOTON (3)
#endif
#if !defined Suiton
    #define Suiton (4)
#endif


// ----------------------------------------------------------
// CONFIG
// ----------------------------------------------------------
#define SHINOBI_MAX_AREAS            (40)
#define SHINOBI_MAX_NPCS             (180)
#define SHINOBI_MAX_CONTRACTS        (30)
#define SHINOBI_MAX_SKINS_PER_VILA   (16)

#define SHINOBI_SPAWN_TICK_MS        (1000)
#define SHINOBI_AI_TICK_MS           (250)

#define SHINOBI_ACQUIRE_DIST         (18.0)
#define SHINOBI_LEASH_DIST           (26.0)
#define SHINOBI_MELEE_DIST           (1.75)

#define SHINOBI_ATK_COOLDOWN_MS      (1700)
#define SHINOBI_MOVE_COOLDOWN_MS     (1800)

#define SHINOBI_PATROL_COST_PER_MIN  (25)   // custo por NPC por minuto
#define SHINOBI_PATROL_QTY_MAX       (12)
#define SHINOBI_PATROL_MIN_MINUTES   (5)
#define SHINOBI_PATROL_MAX_MINUTES   (120)

// Arquivos de config (simples)
#define SHINOBI_FILE_AREAS           "shrp_npcs_areas.cfg"
#define SHINOBI_FILE_SKINS           "shrp_npcs_skins.cfg"
#define SHINOBI_FILE_WAR             "shrp_npcs_war.cfg"

// ----------------------------------------------------------
// Tipos / enums
// ----------------------------------------------------------
#define AREA_TYPE_MOB                (1)
#define AREA_TYPE_PATROL             (2)

#define NPC_KIND_MOB                 (1)
#define NPC_KIND_PATROL              (2)

#define NPC_STATE_IDLE               (0)
#define NPC_STATE_WANDER             (1)
#define NPC_STATE_CHASE              (2)
#define NPC_STATE_RETURN             (3)

// ----------------------------------------------------------
// Dialog IDs (usar range alto para nao colidir)
// ----------------------------------------------------------
#define SHINOBI_DLG_BASE             (29500)

#define DLG_NPC_MAIN                 (SHINOBI_DLG_BASE + 1)
#define DLG_NPC_ADMIN_MAIN           (SHINOBI_DLG_BASE + 2)
#define DLG_NPC_KAGE_MAIN            (SHINOBI_DLG_BASE + 3)

// Admin: Areas
#define DLG_AREA_LIST                (SHINOBI_DLG_BASE + 10)
#define DLG_AREA_ACTION              (SHINOBI_DLG_BASE + 11)
#define DLG_AREA_CREATE_TYPE         (SHINOBI_DLG_BASE + 12)

// Wizard MOB
#define DLG_WIZ_NAME                 (SHINOBI_DLG_BASE + 20)
#define DLG_WIZ_RADIUS               (SHINOBI_DLG_BASE + 21)
#define DLG_WIZ_MAX                  (SHINOBI_DLG_BASE + 22)
#define DLG_WIZ_RESPAWN              (SHINOBI_DLG_BASE + 23)
#define DLG_WIZ_SKIN                 (SHINOBI_DLG_BASE + 24)
#define DLG_WIZ_HP                   (SHINOBI_DLG_BASE + 25)
#define DLG_WIZ_XP                   (SHINOBI_DLG_BASE + 26)
#define DLG_WIZ_ELEM                 (SHINOBI_DLG_BASE + 27)
#define DLG_WIZ_MELEE                (SHINOBI_DLG_BASE + 28)
#define DLG_WIZ_CONFIRM              (SHINOBI_DLG_BASE + 29)

// Wizard PATROL
#define DLG_WIZP_NAME                (SHINOBI_DLG_BASE + 40)
#define DLG_WIZP_RADIUS              (SHINOBI_DLG_BASE + 41)
#define DLG_WIZP_CONFIRM             (SHINOBI_DLG_BASE + 42)

// Admin: Skins
#define DLG_SKIN_VILA                (SHINOBI_DLG_BASE + 60)
#define DLG_SKIN_SET                 (SHINOBI_DLG_BASE + 61)

// Admin: Guerra
#define DLG_WAR_PICK_A               (SHINOBI_DLG_BASE + 70)
#define DLG_WAR_PICK_B               (SHINOBI_DLG_BASE + 71)
#define DLG_WAR_SET                  (SHINOBI_DLG_BASE + 72)

// Kage: Contrato patrulha
#define DLG_KAGE_PICK_AREA           (SHINOBI_DLG_BASE + 80)
#define DLG_KAGE_QTY                 (SHINOBI_DLG_BASE + 81)
#define DLG_KAGE_MINUTES             (SHINOBI_DLG_BASE + 82)
#define DLG_KAGE_CONFIRM             (SHINOBI_DLG_BASE + 83)
#define DLG_KAGE_ACTIVE              (SHINOBI_DLG_BASE + 84)

// ----------------------------------------------------------
// STORAGE - Areas
// ----------------------------------------------------------
new bool:gAreaUsed[SHINOBI_MAX_AREAS];
new gAreaType[SHINOBI_MAX_AREAS];
new gAreaName[SHINOBI_MAX_AREAS][32];
new Float:gAreaPos[SHINOBI_MAX_AREAS][3];
new Float:gAreaRadius[SHINOBI_MAX_AREAS];
new gAreaVW[SHINOBI_MAX_AREAS];
new gAreaInt[SHINOBI_MAX_AREAS];

new gAreaMaxAlive[SHINOBI_MAX_AREAS];
new gAreaRespawnMs[SHINOBI_MAX_AREAS];

// MOB config
new gAreaMobSkin[SHINOBI_MAX_AREAS];
new Float:gAreaMobHP[SHINOBI_MAX_AREAS];
new gAreaMobXP[SHINOBI_MAX_AREAS];
new gAreaMobElem[SHINOBI_MAX_AREAS];      // KATON/FUTON/RAITON/DOTON/Suiton (conforme seu GM)
new gAreaMobMeleeType[SHINOBI_MAX_AREAS]; // MELEE/KENJUTSU (conforme seu GM)
new bool:gAreaMobAggroAll[SHINOBI_MAX_AREAS];

// ----------------------------------------------------------
// STORAGE - NPC instances
// ----------------------------------------------------------
new bool:gNpcUsed[SHINOBI_MAX_NPCS];
new gNpcId[SHINOBI_MAX_NPCS];           // playerid do FCNPC
new gNpcKind[SHINOBI_MAX_NPCS];         // MOB/PATROL
new gNpcArea[SHINOBI_MAX_NPCS];         // area id
new gNpcOwnerVila[SHINOBI_MAX_NPCS];    // para patrulha (pMember)

new gNpcState[SHINOBI_MAX_NPCS];
new gNpcTarget[SHINOBI_MAX_NPCS];
new gNpcNextAtkTick[SHINOBI_MAX_NPCS];
new gNpcNextMoveTick[SHINOBI_MAX_NPCS];
new gNpcDeadUntil[SHINOBI_MAX_NPCS];    // respawn (mobs)
new bool:gNpcDead[SHINOBI_MAX_NPCS];

// ----------------------------------------------------------
// STORAGE - Skins permitidas por vila (admin define)
// pMember do seu server (SistemaBandanaIDStatus):
// 1 Iwa | 2 Suna | 3 Kiri | 4 Konoha | 5 Kumo | ...
// ----------------------------------------------------------
new gVilaSkinCount[12];
new gVilaSkins[12][SHINOBI_MAX_SKINS_PER_VILA];

// ----------------------------------------------------------
// STORAGE - Guerra (matriz simples vila x vila)
// ----------------------------------------------------------
new bool:gWar[12][12];
new gWarPickA[MAX_PLAYERS];

// ----------------------------------------------------------
// STORAGE - Contratos de patrulha
// ----------------------------------------------------------
new bool:gContractUsed[SHINOBI_MAX_CONTRACTS];
new gContractVila[SHINOBI_MAX_CONTRACTS];
new gContractArea[SHINOBI_MAX_CONTRACTS];
new gContractEndTick[SHINOBI_MAX_CONTRACTS];
new gContractQty[SHINOBI_MAX_CONTRACTS];
new gContractCost[SHINOBI_MAX_CONTRACTS];

// temp por player (menu kage)
new gKagePickArea[MAX_PLAYERS];
new gKagePickQty[MAX_PLAYERS];
new gKagePickMinutes[MAX_PLAYERS];

// ----------------------------------------------------------
// Timers
// ----------------------------------------------------------
new gShinobiTimerSpawn;
new gShinobiTimerAI;

// ==========================================================
// Helpers
// ==========================================================
stock bool:ShinobiSys_IsAdmin(playerid)
{
    // seu GM usa pAdminZC
    return (Info[playerid][pAdminZC] > 0);
}
stock bool:ShinobiSys_IsKage(playerid)
{
    return (Info[playerid][pKage] >= 1);
}
stock Float:Shinobi_Dist3D(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2)
{
    new Float:dx = x1-x2;
    new Float:dy = y1-y2;
    new Float:dz = z1-z2;
    return floatsqroot(dx*dx + dy*dy + dz*dz);
}
stock Shinobi_VilaName(member, out[], outLen)
{
    // baseado no seu SistemaBandanaIDStatus (SHRP)
    switch(member)
    {
        case 1: format(out, outLen, "Iwagakure");
        case 2: format(out, outLen, "Sunagakure");
        case 3: format(out, outLen, "Kirigakure");
        case 4: format(out, outLen, "Konohagakure");
        case 5: format(out, outLen, "Kumogakure");
        case 6: format(out, outLen, "Renegado");
        case 7: format(out, outLen, "Renegado");
        case 8: format(out, outLen, "Myoboku");
        default: format(out, outLen, "Sem vila");
    }
    return 1;
}
stock bool:Shinobi_WarBetween(v1, v2)
{
    if(v1 < 0 || v1 > 11) return false;
    if(v2 < 0 || v2 > 11) return false;
    return gWar[v1][v2];
}

// ==========================================================
// Economia: Tesouro da vila
// - Prioridade: se existir Eco_TrySpendTreasury(vila, amount), usa.
// - Senao: usa DataBancoKage[0][banco*] (Iwa/Kiri/Kumo)
// ==========================================================
stock bool:Shinobi_TrySpendTreasury(vila, amount)
{
    if(amount <= 0) return true;

    if(funcidx("Eco_TrySpendTreasury") != -1)
    {
        return (CallLocalFunction("Eco_TrySpendTreasury", "ii", vila, amount) != 0);
    }

    // Fallback pelo seu banco de kage (DataBancoKage)
    // (MAX_BANCOKAGES = 1 no seu GM)
    switch(vila)
    {
        case 1: // Iwa
        {
            if(DataBancoKage[0][bancoIwagakure] < amount) return false;
            DataBancoKage[0][bancoIwagakure] -= amount;
        }
        case 3: // Kiri
        {
            if(DataBancoKage[0][bancoKirigakure] < amount) return false;
            DataBancoKage[0][bancoKirigakure] -= amount;
        }
        case 5: // Kumo
        {
            if(DataBancoKage[0][bancoKumogakure] < amount) return false;
            DataBancoKage[0][bancoKumogakure] -= amount;
        }
        default:
        {
            return false;
        }
    }

    // salva banco (se existir)
    if(funcidx("SalvarBanco") != -1) CallLocalFunction("SalvarBanco", "i", 0);
    return true;
}

stock Shinobi_GetTreasury(vila)
{
    if(funcidx("Eco_GetTreasury") != -1) return CallLocalFunction("Eco_GetTreasury", "i", vila);

    switch(vila)
    {
        case 1: return DataBancoKage[0][bancoIwagakure];
        case 3: return DataBancoKage[0][bancoKirigakure];
        case 5: return DataBancoKage[0][bancoKumogakure];
    }
    return 0;
}

// ==========================================================
// Optional combat hooks
// ==========================================================
stock Float:Shinobi_GetDamage(attacker, dmgType, weapon, Float:base)
{
    if(funcidx("GetDamageToPlayer") != -1)
    {
        return Float:CallLocalFunction("GetDamageToPlayer", "iiif", attacker, dmgType, weapon, base);
    }
    return base;
}
stock Shinobi_ApplyDamage(attacker, victim, Float:dmg)
{
    if(funcidx("SetDamageToPlayer") != -1)
    {
        CallLocalFunction("SetDamageToPlayer", "iif", attacker, victim, dmg);
        return 1;
    }
    // fallback: reduz HP direto
    new Float:hp;
    GetPlayerHealth(victim, hp);
    hp -= dmg;
    if(hp < 0.0) hp = 0.0;
    SetPlayerHealth(victim, hp);
    return 1;
}

stock Shinobi_DoMelee(npcid, targetid, dmgType)
{
    // Se o GM tiver combat real:
    if(funcidx("NPC_Combat_Melee") != -1)
    {
        CallLocalFunction("NPC_Combat_Melee", "iii", npcid, targetid, dmgType);
        return 1;
    }

    // Dano generico (MELEE/KENJUTSU)
    new Float:dmg = Shinobi_GetDamage(npcid, dmgType, 0, 18.0);
    Shinobi_ApplyDamage(npcid, targetid, dmg);
    return 1;
}

stock Shinobi_DoJutsu(npcid, targetid, elem)
{
    if(funcidx("NPC_Combat_Jutsu") != -1)
    {
        CallLocalFunction("NPC_Combat_Jutsu", "iii", npcid, targetid, elem);
        return 1;
    }

    // fallback: dano tipo elemento (KATON/FUTON/RAITON/DOTON/Suiton)
    new Float:dmg = Shinobi_GetDamage(npcid, elem, 0, 26.0);
    Shinobi_ApplyDamage(npcid, targetid, dmg);

    if(funcidx("AparecerMapaJutsu") != -1) CallLocalFunction("AparecerMapaJutsu", "if", targetid, 80.0);
    return 1;
}

// ==========================================================
// Area / NPC helpers
// ==========================================================
stock Shinobi_FindFreeArea()
{
    for(new i=0;i<SHINOBI_MAX_AREAS;i++) if(!gAreaUsed[i]) return i;
    return -1;
}
stock Shinobi_FindFreeNpcSlot()
{
    for(new i=0;i<SHINOBI_MAX_NPCS;i++) if(!gNpcUsed[i]) return i;
    return -1;
}
stock Shinobi_FindAreaById(id) { return (id>=0 && id<SHINOBI_MAX_AREAS && gAreaUsed[id]) ? id : -1; }

stock Shinobi_CountAliveNpcsInArea(areaid)
{
    new c=0;
    for(new i=0;i<SHINOBI_MAX_NPCS;i++)
    {
        if(!gNpcUsed[i]) continue;
        if(gNpcDead[i]) continue;
        if(gNpcArea[i] == areaid) c++;
    }
    return c;
}

stock Shinobi_RandPointInArea(areaid, &Float:ox, &Float:oy, &Float:oz)
{
    new Float:cx = gAreaPos[areaid][0];
    new Float:cy = gAreaPos[areaid][1];
    new Float:cz = gAreaPos[areaid][2];

    new Float:r = gAreaRadius[areaid];
    if(r < 2.0) r = 2.0;

    // random inside circle (approx)
    new Float:rx = float(random(2000))/1000.0; // 0..1.999
    rx -= 1.0; // -1..0.999
    new Float:ry = float(random(2000))/1000.0;
    ry -= 1.0;

    ox = cx + (rx * r);
    oy = cy + (ry * r);
    oz = cz;

    return 1;
}

stock Shinobi_ApplyBandanaAndName(npcid, vila, const name[])
{
    Info[npcid][pMember] = vila;
    PlayerIsLogado[npcid] = 1;

    if(name[0] != '\0')
    {
        format(Info[npcid][pNome], 24, "%s", name);
        // SetPlayerName(npcid, name); // opcional (pode conflitar em alguns gamemodes)
    }

    if(funcidx("SistemaBandanaIDStatus") != -1)
    {
        CallLocalFunction("SistemaBandanaIDStatus", "i", npcid);
    }
    return 1;
}

stock Shinobi_PickSkinForVila(vila)
{
    if(vila < 0 || vila > 11) return 0;
    new c = gVilaSkinCount[vila];
    if(c <= 0) return 0;
    return gVilaSkins[vila][ random(c) ];
}

// ==========================================================
// Spawn / Destroy NPC
// ==========================================================
stock Shinobi_SpawnNpcInArea(npcSlot, areaid, kind, vila)
{
    if(npcSlot < 0 || npcSlot >= SHINOBI_MAX_NPCS) return 0;
    if(!gAreaUsed[areaid]) return 0;

    new Float:x, Float:y, Float:z;
    Shinobi_RandPointInArea(areaid, x, y, z);

    new name[32];
    if(kind == NPC_KIND_PATROL)
        format(name, sizeof name, "Patrulha_%d_%d", areaid, npcSlot);
    else
        format(name, sizeof name, "Mob_%d_%d", areaid, npcSlot);

    new npcid = FCNPC_Create(name);
    if(npcid == INVALID_PLAYER_ID) return 0;

    new skin = 0;
    if(kind == NPC_KIND_PATROL)
    {
        skin = Shinobi_PickSkinForVila(vila);
        if(skin <= 0) skin = 0;
    }
    else
    {
        skin = gAreaMobSkin[areaid];
        if(skin < 0) skin = 0;
    }

    FCNPC_Spawn(npcid, skin, x, y, z);

    SetPlayerVirtualWorld(npcid, gAreaVW[areaid]);
    SetPlayerInterior(npcid, gAreaInt[areaid]);

    // Vida
    new Float:hp = 900.0;
    if(kind == NPC_KIND_MOB) hp = gAreaMobHP[areaid];
    if(hp < 50.0) hp = 50.0;
    SetPlayerHealth(npcid, hp);

    // Bandana / nome
    if(kind == NPC_KIND_PATROL)
        Shinobi_ApplyBandanaAndName(npcid, vila, "Patrulheiro");
    else
        Shinobi_ApplyBandanaAndName(npcid, 6, "Nukenin"); // default renegado

    // Registra slot
    gNpcUsed[npcSlot] = true;
    gNpcId[npcSlot] = npcid;
    gNpcKind[npcSlot] = kind;
    gNpcArea[npcSlot] = areaid;
    gNpcOwnerVila[npcSlot] = vila;

    gNpcState[npcSlot] = NPC_STATE_WANDER;
    gNpcTarget[npcSlot] = INVALID_PLAYER_ID;
    gNpcNextAtkTick[npcSlot] = GetTickCount() + 800;
    gNpcNextMoveTick[npcSlot] = GetTickCount() + 500;

    gNpcDead[npcSlot] = false;
    gNpcDeadUntil[npcSlot] = 0;

    // move speed
    return 1;
}

stock Shinobi_DestroyNpcSlot(npcSlot)
{
    if(npcSlot < 0 || npcSlot >= SHINOBI_MAX_NPCS) return 0;
    if(!gNpcUsed[npcSlot]) return 0;

    new npcid = gNpcId[npcSlot];
    if(npcid != INVALID_PLAYER_ID && IsPlayerConnected(npcid) && IsPlayerNPC(npcid))
    {
        FCNPC_Destroy(npcid);
    }

    gNpcUsed[npcSlot] = false;
    gNpcId[npcSlot] = INVALID_PLAYER_ID;
    gNpcTarget[npcSlot] = INVALID_PLAYER_ID;
    gNpcDead[npcSlot] = false;
    gNpcDeadUntil[npcSlot] = 0;
    return 1;
}

stock Shinobi_FindNpcSlotByPlayerId(playerid)
{
    for(new i=0;i<SHINOBI_MAX_NPCS;i++)
    {
        if(gNpcUsed[i] && gNpcId[i] == playerid) return i;
    }
    return -1;
}

// ==========================================================
// Save/Load (areas, skins, war)
// ==========================================================
stock Shinobi_SaveSkins()
{
    new File:f = fopen(SHINOBI_FILE_SKINS, io_write);
    if(!f) return 0;

    new line[256];
    for(new vila=0; vila<12; vila++)
    {
        if(gVilaSkinCount[vila] <= 0) continue;

        format(line, sizeof line, "SKINS|%d|", vila);
        fwrite(f, line);

        for(new i=0;i<gVilaSkinCount[vila];i++)
        {
            format(line, sizeof line, "%d", gVilaSkins[vila][i]);
            fwrite(f, line);
            if(i < gVilaSkinCount[vila]-1) fwrite(f, ",");
        }
        fwrite(f, "\r\n");
    }
    fclose(f);
    return 1;
}

stock Shinobi_LoadSkins()
{
    for(new v=0; v<12; v++) gVilaSkinCount[v] = 0;

    new File:f = fopen(SHINOBI_FILE_SKINS, io_read);
    if(!f) return 0;

    new line[256];
    while(fread(f, line))
    {
        if(line[0] == '\0') continue;
        if(strfind(line, "SKINS|", true) != 0) continue;

        // formato: SKINS|vila|300,301,302
        new p1 = strfind(line, "|", true);
        if(p1 == -1) continue;
        new p2 = strfind(line, "|", true, p1+1);
        if(p2 == -1) continue;

        new vilaStr[8];
        strmid(vilaStr, line, p1+1, p2, sizeof vilaStr);
        new vila = strval(vilaStr);
        if(vila < 0 || vila > 11) continue;

        new skinsStr[200];
        strmid(skinsStr, line, p2+1, strlen(line), sizeof skinsStr);

        // remove \r\n
        for(new k=strlen(skinsStr)-1; k>=0; k--)
        {
            if(skinsStr[k] == '\r' || skinsStr[k] == '\n') skinsStr[k] = '\0';
            else break;
        }

        // parse CSV
        new num[16];
        new ni=0;
        new c=0;
        for(new i=0; skinsStr[i] != '\0'; i++)
        {
            if(skinsStr[i] == ',' || skinsStr[i] == ' ' || skinsStr[i] == '\t')
            {
                if(ni > 0)
                {
                    num[ni] = '\0';
                    if(c < SHINOBI_MAX_SKINS_PER_VILA)
                    {
                        gVilaSkins[vila][c++] = strval(num);
                    }
                    ni = 0;
                }
                continue;
            }
            if(ni < sizeof(num)-1) num[ni++] = skinsStr[i];
        }
        if(ni > 0 && c < SHINOBI_MAX_SKINS_PER_VILA)
        {
            num[ni] = '\0';
            gVilaSkins[vila][c++] = strval(num);
        }
        gVilaSkinCount[vila] = c;
    }
    fclose(f);
    return 1;
}

stock Shinobi_SaveWar()
{
    new File:f = fopen(SHINOBI_FILE_WAR, io_write);
    if(!f) return 0;
    new line[64];
    for(new a=0;a<12;a++)
    {
        for(new b=0;b<12;b++)
        {
            if(!gWar[a][b]) continue;
            format(line, sizeof line, "WAR|%d|%d\r\n", a, b);
            fwrite(f, line);
        }
    }
    fclose(f);
    return 1;
}
stock Shinobi_LoadWar()
{
    for(new a=0;a<12;a++) for(new b=0;b<12;b++) gWar[a][b] = false;

    new File:f = fopen(SHINOBI_FILE_WAR, io_read);
    if(!f) return 0;

    new line[64];
    while(fread(f, line))
    {
        if(strfind(line, "WAR|", true) != 0) continue;

        // formato: WAR|A|B
        new p1 = strfind(line, "|", true);          // apos "WAR"
        new p2 = strfind(line, "|", true, p1+1);    // apos A
        if(p1 == -1 || p2 == -1) continue;

        new aStr[8], bStr[8];
        strmid(aStr, line, p1+1, p2, sizeof aStr);
        strmid(bStr, line, p2+1, strlen(line), sizeof bStr);

        // remove \r/\n do fim (Windows/CRLF)
        for(new k = strlen(bStr)-1; k >= 0; k--)
        {
            if(bStr[k] == '\n' || bStr[k] == '\r') bStr[k] = '\0';
            else break;
        }
        for(new k = strlen(aStr)-1; k >= 0; k--)
        {
            if(aStr[k] == '\n' || aStr[k] == '\r') aStr[k] = '\0';
            else break;
        }

        new a = strval(aStr), b = strval(bStr);
        if(a < 0 || a > 11) continue;
        if(b < 0 || b > 11) continue;
        gWar[a][b] = true;
        gWar[b][a] = true;
    }

    fclose(f);
    return 1;
}


stock Shinobi_SaveAreas()
{
    new File:f = fopen(SHINOBI_FILE_AREAS, io_write);
    if(!f) return 0;

    new line[256];
    for(new i=0;i<SHINOBI_MAX_AREAS;i++)
    {
        if(!gAreaUsed[i]) continue;

        // AREA|id|type|name|x|y|z|r|vw|int|max|respawn|skin|hp|xp|elem|melee|aggro
        format(line, sizeof line,
            "AREA|%d|%d|%s|%.3f|%.3f|%.3f|%.2f|%d|%d|%d|%d|%d|%.1f|%d|%d|%d|%d\r\n",
            i,
            gAreaType[i],
            gAreaName[i],
            gAreaPos[i][0], gAreaPos[i][1], gAreaPos[i][2],
            gAreaRadius[i],
            gAreaVW[i],
            gAreaInt[i],
            gAreaMaxAlive[i],
            gAreaRespawnMs[i],
            gAreaMobSkin[i],
            gAreaMobHP[i],
            gAreaMobXP[i],
            gAreaMobElem[i],
            gAreaMobMeleeType[i],
            gAreaMobAggroAll[i] ? 1 : 0
        );
        fwrite(f, line);
    }

    fclose(f);
    return 1;
}

stock Shinobi_LoadAreas()
{
    for(new i=0;i<SHINOBI_MAX_AREAS;i++) gAreaUsed[i] = false;

    new File:f = fopen(SHINOBI_FILE_AREAS, io_read);
    if(!f) return 0;

    new line[256];
    while(fread(f, line))
    {
        if(strfind(line, "AREA|", true) != 0) continue;

        // split por '|'
        new parts[18][64];
        new part = 0, pi = 0;
        for(new c=0; line[c] != '\0' && part < 18; c++)
        {
            if(line[c] == '|' || line[c] == '\r' || line[c] == '\n')
            {
                parts[part][pi] = '\0';
                part++;
                pi = 0;
                continue;
            }
            if(pi < 63) parts[part][pi++] = line[c];
        }
        if(part < 12) continue; // minimo

        // parts:
        // 0=AREA,1=id,2=type,3=name,4=x,5=y,6=z,7=r,8=vw,9=int,10=max,11=respawn,12=skin,13=hp,14=xp,15=elem,16=melee,17=aggro
        new id = strval(parts[1]);
        if(id < 0 || id >= SHINOBI_MAX_AREAS) continue;

        gAreaUsed[id] = true;
        gAreaType[id] = strval(parts[2]);
        format(gAreaName[id], 32, "%s", parts[3]);

        gAreaPos[id][0] = floatstr(parts[4]);
        gAreaPos[id][1] = floatstr(parts[5]);
        gAreaPos[id][2] = floatstr(parts[6]);
        gAreaRadius[id] = floatstr(parts[7]);

        gAreaVW[id] = strval(parts[8]);
        gAreaInt[id] = strval(parts[9]);

        gAreaMaxAlive[id] = strval(parts[10]);
        gAreaRespawnMs[id] = strval(parts[11]);

        // defaults
        gAreaMobSkin[id] = 0;
        gAreaMobHP[id] = 900.0;
        gAreaMobXP[id] = 20;
        gAreaMobElem[id] = 0;
        gAreaMobMeleeType[id] = 0;
        gAreaMobAggroAll[id] = true;

        if(part > 12) gAreaMobSkin[id] = strval(parts[12]);
        if(part > 13) gAreaMobHP[id] = floatstr(parts[13]);
        if(part > 14) gAreaMobXP[id] = strval(parts[14]);
        if(part > 15) gAreaMobElem[id] = strval(parts[15]);
        if(part > 16) gAreaMobMeleeType[id] = strval(parts[16]);
        if(part > 17) gAreaMobAggroAll[id] = (strval(parts[17]) != 0);
    }

    fclose(f);
    return 1;
}

// ==========================================================
// Public API - Callbacks do GM
// ==========================================================
forward ShinobiSys_OnGameModeInit();
public ShinobiSys_OnGameModeInit()
{
    // init arrays
    for(new i=0;i<SHINOBI_MAX_NPCS;i++)
    {
        gNpcUsed[i] = false;
        gNpcId[i] = INVALID_PLAYER_ID;
        gNpcTarget[i] = INVALID_PLAYER_ID;
        gNpcDead[i] = false;
        gNpcDeadUntil[i] = 0;
    }
    for(new c=0;c<SHINOBI_MAX_CONTRACTS;c++) gContractUsed[c] = false;

    Shinobi_LoadSkins();
    Shinobi_LoadWar();
    Shinobi_LoadAreas();

    if(gShinobiTimerSpawn) KillTimer(gShinobiTimerSpawn);
    if(gShinobiTimerAI) KillTimer(gShinobiTimerAI);

    gShinobiTimerSpawn = SetTimer("ShinobiSys_SpawnTick", SHINOBI_SPAWN_TICK_MS, true);
    gShinobiTimerAI = SetTimer("ShinobiSys_AITick", SHINOBI_AI_TICK_MS, true);

    print("[SHINOBI] Sistema de NPCs iniciado (areas/patrulha).");
    return 1;
}

forward ShinobiSys_OnGameModeExit();
public ShinobiSys_OnGameModeExit()
{
    Shinobi_SaveSkins();
    Shinobi_SaveWar();
    Shinobi_SaveAreas();

    for(new i=0;i<SHINOBI_MAX_NPCS;i++) if(gNpcUsed[i]) Shinobi_DestroyNpcSlot(i);
    if(gShinobiTimerSpawn) KillTimer(gShinobiTimerSpawn);
    if(gShinobiTimerAI) KillTimer(gShinobiTimerAI);

    return 1;
}

forward ShinobiSys_OnPlayerDeath(playerid, killerid, reason);
public ShinobiSys_OnPlayerDeath(playerid, killerid, reason)
{
    // Se morreu NPC nosso, paga XP se for mob
    new slot = Shinobi_FindNpcSlotByPlayerId(playerid);
    if(slot == -1) return 1;

    // marca dead
    gNpcDead[slot] = true;
    gNpcTarget[slot] = INVALID_PLAYER_ID;

    new areaid = gNpcArea[slot];
    new kind = gNpcKind[slot];

    if(kind == NPC_KIND_MOB)
    {
        // XP
        if(killerid != INVALID_PLAYER_ID && IsPlayerConnected(killerid) && !IsPlayerNPC(killerid))
        {
            new xp = gAreaMobXP[areaid];
            if(xp > 0)
            {
                if(funcidx("GivePlayerExperiencia") != -1) CallLocalFunction("GivePlayerExperiencia", "ii", killerid, xp);
                if(funcidx("SubirDLevel") != -1) CallLocalFunction("SubirDLevel", "i", killerid);
            }
        }

        // respawn
        new now = GetTickCount();
        new delay = gAreaRespawnMs[areaid];
        if(delay < 1000) delay = 1000;
        gNpcDeadUntil[slot] = now + delay;
    }
    else
    {
        // patrulha: some e nao respawna (contrato pode respawnar no futuro)
        Shinobi_DestroyNpcSlot(slot);
    }

    return 1;
}

// ==========================================================
// Tick: Spawn de mobs + expiracao de contratos
// ==========================================================
forward ShinobiSys_SpawnTick();
public ShinobiSys_SpawnTick()
{
    new now = GetTickCount();

    // 1) Contratos: expirar
    for(new c=0;c<SHINOBI_MAX_CONTRACTS;c++)
    {
        if(!gContractUsed[c]) continue;
        if(now < gContractEndTick[c]) continue;

        // expira: destroi patrulheiros daquela area/vila
        for(new i=0;i<SHINOBI_MAX_NPCS;i++)
        {
            if(!gNpcUsed[i]) continue;
            if(gNpcKind[i] != NPC_KIND_PATROL) continue;
            if(gNpcArea[i] != gContractArea[c]) continue;
            if(gNpcOwnerVila[i] != gContractVila[c]) continue;
            Shinobi_DestroyNpcSlot(i);
        }

        gContractUsed[c] = false;
    }

    // 2) Areas: garantir mobs
    for(new a=0;a<SHINOBI_MAX_AREAS;a++)
    {
        if(!gAreaUsed[a]) continue;
        if(gAreaType[a] != AREA_TYPE_MOB) continue;

        // respawn dead slots
        for(new i=0;i<SHINOBI_MAX_NPCS;i++)
        {
            if(!gNpcUsed[i]) continue;
            if(gNpcArea[i] != a) continue;
            if(gNpcKind[i] != NPC_KIND_MOB) continue;
            if(!gNpcDead[i]) continue;
            if(now < gNpcDeadUntil[i]) continue;

            // respawn no mesmo ID (mais seguro recriar)
            Shinobi_DestroyNpcSlot(i);

            // reaproveita slot (mesmo indice)
            Shinobi_SpawnNpcInArea(i, a, NPC_KIND_MOB, 0);
        }

        new alive = Shinobi_CountAliveNpcsInArea(a);
        new maxAlive = gAreaMaxAlive[a];
        if(maxAlive <= 0) maxAlive = 1;

        while(alive < maxAlive)
        {
            new ns = Shinobi_FindFreeNpcSlot();
            if(ns == -1) break;
            Shinobi_SpawnNpcInArea(ns, a, NPC_KIND_MOB, 0);
            alive++;
        }
    }

    return 1;
}

// ==========================================================
// Tick: AI movimento/ataque
// ==========================================================
forward ShinobiSys_AITick();
public ShinobiSys_AITick()
{
    new now = GetTickCount();

    for(new s=0;s<SHINOBI_MAX_NPCS;s++)
    {
        if(!gNpcUsed[s]) continue;
        if(gNpcDead[s]) continue;

        new npcid = gNpcId[s];
        if(npcid == INVALID_PLAYER_ID) continue;
        if(!IsPlayerConnected(npcid) || !IsPlayerNPC(npcid)) continue;

        new areaid = gNpcArea[s];
        if(areaid < 0 || areaid >= SHINOBI_MAX_AREAS || !gAreaUsed[areaid]) continue;

        // target valida?
        new t = gNpcTarget[s];
        if(t != INVALID_PLAYER_ID)
        {
            if(!IsPlayerConnected(t) || IsPlayerNPC(t) || GetPlayerVirtualWorld(t) != gAreaVW[areaid] || GetPlayerInterior(t) != gAreaInt[areaid])
            {
                gNpcTarget[s] = INVALID_PLAYER_ID;
                t = INVALID_PLAYER_ID;
            }
        }

        // pos npc
        new Float:nx, Float:ny, Float:nz;
        FCNPC_GetPosition(npcid, nx, ny, nz);

        // acquire target
        if(t == INVALID_PLAYER_ID)
        {
            new best = INVALID_PLAYER_ID;
            new Float:bestD = SHINOBI_ACQUIRE_DIST;

            for(new p=0;p<MAX_PLAYERS;p++)
            {
                if(!IsPlayerConnected(p) || IsPlayerNPC(p)) continue;
                if(GetPlayerVirtualWorld(p) != gAreaVW[areaid]) continue;
                if(GetPlayerInterior(p) != gAreaInt[areaid]) continue;

                // regra de guerra p/ patrulha
                if(gNpcKind[s] == NPC_KIND_PATROL)
                {
                    new pvila = Info[p][pMember];
                    if(!Shinobi_WarBetween(gNpcOwnerVila[s], pvila)) continue;
                }

                // MOB: se nao for aggroall, so ataca inimigo de vila diferente
                if(gNpcKind[s] == NPC_KIND_MOB && !gAreaMobAggroAll[areaid])
                {
                    // mob renegado: ignora mesma vila (se tiver)
                    if(Info[p][pMember] == Info[npcid][pMember]) continue;
                }

                new Float:px, Float:py, Float:pz;
                GetPlayerPos(p, px, py, pz);
                new Float:d = Shinobi_Dist3D(nx, ny, nz, px, py, pz);
                if(d <= bestD)
                {
                    bestD = d;
                    best = p;
                }
            }

            if(best != INVALID_PLAYER_ID)
            {
                gNpcTarget[s] = best;
                gNpcState[s] = NPC_STATE_CHASE;
                t = best;
            }
        }

        // chase / attack
        if(t != INVALID_PLAYER_ID)
        {
            new Float:px, Float:py, Float:pz;
            GetPlayerPos(t, px, py, pz);
            new Float:d = Shinobi_Dist3D(nx, ny, nz, px, py, pz);

            // leash
            if(d > SHINOBI_LEASH_DIST)
            {
                gNpcTarget[s] = INVALID_PLAYER_ID;
                gNpcState[s] = NPC_STATE_RETURN;
                continue;
            }

            // move to target (cooldown)
            if(now >= gNpcNextMoveTick[s])
            {
                FCNPC_GoTo(npcid, px, py, pz);
                gNpcNextMoveTick[s] = now + SHINOBI_MOVE_COOLDOWN_MS;
            }

            // attack
            if(d <= SHINOBI_MELEE_DIST && now >= gNpcNextAtkTick[s])
            {
                if(gNpcKind[s] == NPC_KIND_MOB)
                {
                    Shinobi_DoMelee(npcid, t, gAreaMobMeleeType[areaid]);
                    // chance pequena de jutsu se tiver elem
                    if(gAreaMobElem[areaid] >= 0 && random(100) < 18)
                        Shinobi_DoJutsu(npcid, t, gAreaMobElem[areaid]);
                }
                else
                {
                    // patrulha: kenjutsu por padrao (se existir)
                    Shinobi_DoMelee(npcid, t, KENJUTSU);
                }

                gNpcNextAtkTick[s] = now + SHINOBI_ATK_COOLDOWN_MS;
            }

            continue;
        }

        // idle / wander / return
        if(now >= gNpcNextMoveTick[s])
        {
            new Float:tx, Float:ty, Float:tz;
            Shinobi_RandPointInArea(areaid, tx, ty, tz);
            FCNPC_GoTo(npcid, tx, ty, tz);
            gNpcNextMoveTick[s] = now + SHINOBI_MOVE_COOLDOWN_MS;
            gNpcState[s] = NPC_STATE_WANDER;
        }
    }

    return 1;
}

// ==========================================================
// Menus
// ==========================================================
stock Shinobi_ShowMainMenu(playerid)
{
    ShowPlayerDialog(playerid, DLG_NPC_MAIN, DIALOG_STYLE_LIST,
        "NPCs",
        "Menu ADMIN (areas/skins/guerra)\nMenu KAGE (contrato patrulha)\nFechar",
        "Ok", "Sair");
    return 1;
}

stock Shinobi_ShowAdminMenu(playerid)
{
    ShowPlayerDialog(playerid, DLG_NPC_ADMIN_MAIN, DIALOG_STYLE_LIST,
        "NPCs - Admin",
        "Areas (mobs/patrulha)\nSkins por vila\nGuerra (definir rivalidade)\nSalvar configs\nVoltar",
        "Ok", "Voltar");
    return 1;
}

stock Shinobi_ShowKageMenu(playerid)
{
    ShowPlayerDialog(playerid, DLG_NPC_KAGE_MAIN, DIALOG_STYLE_LIST,
        "NPCs - Kage",
        "Contratar patrulha\nVer patrulhas ativas\nVoltar",
        "Ok", "Voltar");
    return 1;
}

stock Shinobi_ShowAreaList(playerid)
{
    new list[1024];
    list[0] = '\0';

    for(new i=0;i<SHINOBI_MAX_AREAS;i++)
    {
        if(!gAreaUsed[i]) continue;

        new t[12];
        if(gAreaType[i] == AREA_TYPE_MOB) format(t, sizeof t, "MOB");
        else format(t, sizeof t, "PATRULHA");

        new line[96];
        format(line, sizeof line, "%d) [%s] %s\n", i, t, gAreaName[i]);
        strcat(list, line, sizeof list);
    }

    if(!list[0]) strcat(list, "(nenhuma area criada)\n", sizeof list);
    strcat(list, "Criar area MOB (aqui)\nCriar area PATRULHA (aqui)\nDeletar area (id)\nVoltar\n", sizeof list);

    ShowPlayerDialog(playerid, DLG_AREA_LIST, DIALOG_STYLE_LIST, "Areas", list, "Ok", "Voltar");
    return 1;
}

stock Shinobi_ShowSkinVila(playerid)
{
    ShowPlayerDialog(playerid, DLG_SKIN_VILA, DIALOG_STYLE_LIST,
        "Skins permitidas - Escolha vila",
        "1 Iwagakure\n3 Kirigakure\n5 Kumogakure\n4 Konohagakure\n2 Sunagakure\nVoltar",
        "Ok", "Voltar");
    return 1;
}

stock Shinobi_ShowWarPickA(playerid)
{
    ShowPlayerDialog(playerid, DLG_WAR_PICK_A, DIALOG_STYLE_LIST,
        "Guerra - Vila A",
        "1 Iwagakure\n3 Kirigakure\n5 Kumogakure\n4 Konohagakure\n2 Sunagakure\nVoltar",
        "Ok", "Voltar");
    return 1;
}
stock Shinobi_ShowWarPickB(playerid)
{
    ShowPlayerDialog(playerid, DLG_WAR_PICK_B, DIALOG_STYLE_LIST,
        "Guerra - Vila B",
        "1 Iwagakure\n3 Kirigakure\n5 Kumogakure\n4 Konohagakure\n2 Sunagakure\nVoltar",
        "Ok", "Voltar");
    return 1;
}

stock Shinobi_ShowKagePickArea(playerid)
{
    new list[1024];
    list[0] = '\0';

    for(new i=0;i<SHINOBI_MAX_AREAS;i++)
    {
        if(!gAreaUsed[i]) continue;
        if(gAreaType[i] != AREA_TYPE_PATROL) continue;

        new line[96];
        format(line, sizeof line, "%d) %s\n", i, gAreaName[i]);
        strcat(list, line, sizeof list);
    }

    if(!list[0]) strcat(list, "(nenhuma area de patrulha criada)\n", sizeof list);
    strcat(list, "Voltar\n", sizeof list);

    ShowPlayerDialog(playerid, DLG_KAGE_PICK_AREA, DIALOG_STYLE_LIST, "Contratar patrulha - Area", list, "Ok", "Voltar");
    return 1;
}

stock Shinobi_ShowKageActiveContracts(playerid)
{
    new list[1024];
    list[0] = '\0';

    new now = GetTickCount();

    for(new c=0;c<SHINOBI_MAX_CONTRACTS;c++)
    {
        if(!gContractUsed[c]) continue;

        new vilaName[24];
        Shinobi_VilaName(gContractVila[c], vilaName, sizeof vilaName);

        new left = (gContractEndTick[c] - now) / 1000;
        if(left < 0) left = 0;

        new line[128];
        format(line, sizeof line, "%d) %s - Area %d (%d NPC) - %ds\n", c, vilaName, gContractArea[c], gContractQty[c], left);
        strcat(list, line, sizeof list);
    }

    if(!list[0]) strcat(list, "(nenhuma patrulha ativa)\n", sizeof list);
    strcat(list, "Voltar\n", sizeof list);

    ShowPlayerDialog(playerid, DLG_KAGE_ACTIVE, DIALOG_STYLE_LIST, "Patrulhas ativas", list, "Ok", "Voltar");
    return 1;
}

// ==========================================================
// Wizard: Create Areas
// ==========================================================
new bool:gWizMob[MAX_PLAYERS];
new gWizAreaId[MAX_PLAYERS];
new gWizType[MAX_PLAYERS];

new Float:gWizRadius[MAX_PLAYERS];
new gWizMax[MAX_PLAYERS];
new gWizRespawn[MAX_PLAYERS];
new gWizSkin[MAX_PLAYERS];
new Float:gWizHP[MAX_PLAYERS];
new gWizXP[MAX_PLAYERS];
new gWizElem[MAX_PLAYERS];
new gWizMelee[MAX_PLAYERS];

stock Shinobi_StartWizard(playerid, type)
{
    gWizType[playerid] = type;
    gWizAreaId[playerid] = -1;
    gWizMob[playerid] = (type == AREA_TYPE_MOB);

    // defaults
    gWizRadius[playerid] = 25.0;
    gWizMax[playerid] = 6;
    gWizRespawn[playerid] = 8000;
    gWizSkin[playerid] = 117;
    gWizHP[playerid] = 900.0;
    gWizXP[playerid] = 25;
    gWizElem[playerid] = KATON;
    gWizMelee[playerid] = MELEE;

    ShowPlayerDialog(playerid, gWizMob[playerid] ? DLG_WIZ_NAME : DLG_WIZP_NAME,
        DIALOG_STYLE_INPUT,
        gWizMob[playerid] ? "Criar area MOB - Nome" : "Criar area PATRULHA - Nome",
        "Digite um nome curto (sem acentos).",
        "Ok", "Cancelar");
    return 1;
}

stock Shinobi_FinalizeWizard(playerid)
{
    new id = Shinobi_FindFreeArea();
    if(id == -1) return SendClientMessage(playerid, -1, "[NPC] Limite de areas atingido."), 1;

    gAreaUsed[id] = true;
    gAreaType[id] = gWizType[playerid];

    format(gAreaName[id], 32, "%s", gAreaName[id]); // placeholder (vai ser setado no dialog)

    GetPlayerPos(playerid, gAreaPos[id][0], gAreaPos[id][1], gAreaPos[id][2]);
    gAreaRadius[id] = gWizRadius[playerid];
    gAreaVW[id] = GetPlayerVirtualWorld(playerid);
    gAreaInt[id] = GetPlayerInterior(playerid);

    gAreaMaxAlive[id] = gWizMax[playerid];
    gAreaRespawnMs[id] = gWizRespawn[playerid];

    gAreaMobSkin[id] = gWizSkin[playerid];
    gAreaMobHP[id] = gWizHP[playerid];
    gAreaMobXP[id] = gWizXP[playerid];
    gAreaMobElem[id] = gWizElem[playerid];
    gAreaMobMeleeType[id] = gWizMelee[playerid];
    gAreaMobAggroAll[id] = true;

    gWizAreaId[playerid] = id;
    return 1;
}

// ==========================================================
// Dialog router
// ==========================================================
forward bool:ShinobiSys_OnDialog(playerid, dialogid, response, listitem, inputtext[]);
public bool:ShinobiSys_OnDialog(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == DLG_NPC_MAIN)
    {
        if(!response) return true;

        if(listitem == 0)
        {
            if(!ShinobiSys_IsAdmin(playerid)) return SendClientMessage(playerid, -1, "[NPC] Voce nao e admin."), true;
            return Shinobi_ShowAdminMenu(playerid), true;
        }
        if(listitem == 1)
        {
            if(!ShinobiSys_IsKage(playerid)) return SendClientMessage(playerid, -1, "[NPC] Voce nao e Kage."), true;
            return Shinobi_ShowKageMenu(playerid), true;
        }
        return true;
    }

    if(dialogid == DLG_NPC_ADMIN_MAIN)
    {
        if(!response) return Shinobi_ShowMainMenu(playerid), true;

        switch(listitem)
        {
            case 0: return Shinobi_ShowAreaList(playerid), true;
            case 1: return Shinobi_ShowSkinVila(playerid), true;
            case 2: return Shinobi_ShowWarPickA(playerid), true;
            case 3:
            {
                Shinobi_SaveSkins();
                Shinobi_SaveWar();
                Shinobi_SaveAreas();
                SendClientMessage(playerid, -1, "[NPC] Configs salvas.");
                return Shinobi_ShowAdminMenu(playerid), true;
            }
            default: return Shinobi_ShowMainMenu(playerid), true;
        }
    }

    if(dialogid == DLG_NPC_KAGE_MAIN)
    {
        if(!response) return Shinobi_ShowMainMenu(playerid), true;

        switch(listitem)
        {
            case 0: return Shinobi_ShowKagePickArea(playerid), true;
            case 1: return Shinobi_ShowKageActiveContracts(playerid), true;
            default: return Shinobi_ShowMainMenu(playerid), true;
        }
    }

    // Areas list
    if(dialogid == DLG_AREA_LIST)
    {
        if(!response) return Shinobi_ShowAdminMenu(playerid), true;

        // list includes: existing areas + 4 actions at bottom
        // We need map listitem to either an area or an action.
        // We'll rebuild mapping here quickly.
        new map[SHINOBI_MAX_AREAS + 8];
        new mapCount=0;

        for(new i=0;i<SHINOBI_MAX_AREAS;i++)
        {
            if(!gAreaUsed[i]) continue;
            map[mapCount++] = i;
        }
        // actions as negatives:
        map[mapCount++] = -1; // create mob
        map[mapCount++] = -2; // create patrol
        map[mapCount++] = -3; // delete by id
        map[mapCount++] = -4; // back

        new sel = map[listitem];

        if(sel >= 0)
        {
            // Area actions
            new title[64];
            format(title, sizeof title, "Area %d - %s", sel, gAreaName[sel]);

            ShowPlayerDialog(playerid, DLG_AREA_ACTION, DIALOG_STYLE_LIST, title,
                "Teleport para area\nDeletar esta area\nVoltar",
                "Ok", "Voltar");
            SetPVarInt(playerid, "shrp_area_sel", sel);
            return true;
        }

        if(sel == -1) return Shinobi_StartWizard(playerid, AREA_TYPE_MOB), true;
        if(sel == -2) return Shinobi_StartWizard(playerid, AREA_TYPE_PATROL), true;

        if(sel == -3)
        {
            ShowPlayerDialog(playerid, DLG_AREA_CREATE_TYPE, DIALOG_STYLE_INPUT,
                "Deletar area",
                "Digite o ID da area para deletar:",
                "Ok", "Cancelar");
            return true;
        }

        return Shinobi_ShowAdminMenu(playerid), true;
    }

    if(dialogid == DLG_AREA_CREATE_TYPE)
    {
        if(!response) return Shinobi_ShowAreaList(playerid), true;
        new id = strval(inputtext);
        if(id < 0 || id >= SHINOBI_MAX_AREAS || !gAreaUsed[id]) return SendClientMessage(playerid, -1, "[NPC] Area invalida."), Shinobi_ShowAreaList(playerid), true;

        // destroy all npcs from area
        for(new i=0;i<SHINOBI_MAX_NPCS;i++)
        {
            if(!gNpcUsed[i]) continue;
            if(gNpcArea[i] == id) Shinobi_DestroyNpcSlot(i);
        }

        gAreaUsed[id] = false;
        SendClientMessage(playerid, -1, "[NPC] Area deletada.");
        return Shinobi_ShowAreaList(playerid), true;
    }

    if(dialogid == DLG_AREA_ACTION)
    {
        new sel = GetPVarInt(playerid, "shrp_area_sel");
        if(!response) return Shinobi_ShowAreaList(playerid), true;
        if(sel < 0 || sel >= SHINOBI_MAX_AREAS || !gAreaUsed[sel]) return Shinobi_ShowAreaList(playerid), true;

        if(listitem == 0)
        {
            SetPlayerPos(playerid, gAreaPos[sel][0], gAreaPos[sel][1], gAreaPos[sel][2]);
            SetPlayerVirtualWorld(playerid, gAreaVW[sel]);
            SetPlayerInterior(playerid, gAreaInt[sel]);
            SendClientMessage(playerid, -1, "[NPC] Teleportado.");
            return Shinobi_ShowAreaList(playerid), true;
        }
        if(listitem == 1)
        {
            // same as delete
            for(new i=0;i<SHINOBI_MAX_NPCS;i++)
            {
                if(!gNpcUsed[i]) continue;
                if(gNpcArea[i] == sel) Shinobi_DestroyNpcSlot(i);
            }
            gAreaUsed[sel] = false;
            SendClientMessage(playerid, -1, "[NPC] Area deletada.");
            return Shinobi_ShowAreaList(playerid), true;
        }
        return Shinobi_ShowAreaList(playerid), true;
    }

    // Wizard MOB
    if(dialogid == DLG_WIZ_NAME)
    {
        if(!response) return Shinobi_ShowAreaList(playerid), true;
        new name[32];
        format(name, sizeof name, "%s", inputtext);
        if(!name[0]) return SendClientMessage(playerid, -1, "[NPC] Nome vazio."), Shinobi_StartWizard(playerid, AREA_TYPE_MOB), true;

        // cria area agora e salva nome
        new id = Shinobi_FindFreeArea();
        if(id == -1) return SendClientMessage(playerid, -1, "[NPC] Limite de areas atingido."), true;

        gAreaUsed[id] = true;
        gAreaType[id] = AREA_TYPE_MOB;
        format(gAreaName[id], 32, "%s", name);

        GetPlayerPos(playerid, gAreaPos[id][0], gAreaPos[id][1], gAreaPos[id][2]);
        gAreaVW[id] = GetPlayerVirtualWorld(playerid);
        gAreaInt[id] = GetPlayerInterior(playerid);

        // temp store areaid
        gWizAreaId[playerid] = id;
        gWizType[playerid] = AREA_TYPE_MOB;

        ShowPlayerDialog(playerid, DLG_WIZ_RADIUS, DIALOG_STYLE_INPUT, "Criar area MOB - Raio", "Raio em metros (ex: 25):", "Ok", "Cancelar");
        return true;
    }

    if(dialogid == DLG_WIZ_RADIUS)
    {
        if(!response)
        {
            // cancela wizard e remove area criada
            new id = gWizAreaId[playerid];
            if(id >= 0 && id < SHINOBI_MAX_AREAS) gAreaUsed[id] = false;
            return Shinobi_ShowAreaList(playerid), true;
        }

        new id2 = gWizAreaId[playerid];
        if(id2 < 0 || id2 >= SHINOBI_MAX_AREAS || !gAreaUsed[id2]) return Shinobi_ShowAreaList(playerid), true;

        new Float:r = floatstr(inputtext);
        if(r < 5.0) r = 5.0;
        if(r > 200.0) r = 200.0;
        gAreaRadius[id2] = r;

        ShowPlayerDialog(playerid, DLG_WIZ_MAX, DIALOG_STYLE_INPUT, "Criar area MOB - Max NPC", "Quantos NPCs vivos ao mesmo tempo (ex: 6):", "Ok", "Cancelar");
        return true;
    }

    if(dialogid == DLG_WIZ_MAX)
    {
        if(!response)
        {
            new id = gWizAreaId[playerid];
            if(id >= 0 && id < SHINOBI_MAX_AREAS) gAreaUsed[id] = false;
            return Shinobi_ShowAreaList(playerid), true;
        }
        new id2 = gWizAreaId[playerid];
        if(id2 < 0 || id2 >= SHINOBI_MAX_AREAS || !gAreaUsed[id2]) return Shinobi_ShowAreaList(playerid), true;

        new m = strval(inputtext);
        if(m < 1) m = 1;
        if(m > 30) m = 30;
        gAreaMaxAlive[id2] = m;

        ShowPlayerDialog(playerid, DLG_WIZ_RESPAWN, DIALOG_STYLE_INPUT, "Criar area MOB - Respawn(ms)", "Tempo de respawn (ms), ex: 8000:", "Ok", "Cancelar");
        return true;
    }

    if(dialogid == DLG_WIZ_RESPAWN)
    {
        if(!response)
        {
            new id = gWizAreaId[playerid];
            if(id >= 0 && id < SHINOBI_MAX_AREAS) gAreaUsed[id] = false;
            return Shinobi_ShowAreaList(playerid), true;
        }
        new id2 = gWizAreaId[playerid];
        if(id2 < 0 || id2 >= SHINOBI_MAX_AREAS || !gAreaUsed[id2]) return Shinobi_ShowAreaList(playerid), true;

        new ms = strval(inputtext);
        if(ms < 1000) ms = 1000;
        if(ms > 60000) ms = 60000;
        gAreaRespawnMs[id2] = ms;

        ShowPlayerDialog(playerid, DLG_WIZ_SKIN, DIALOG_STYLE_INPUT, "Criar area MOB - Skin", "Skin ID do NPC (ex: 117):", "Ok", "Cancelar");
        return true;
    }

    if(dialogid == DLG_WIZ_SKIN)
    {
        if(!response)
        {
            new id = gWizAreaId[playerid];
            if(id >= 0 && id < SHINOBI_MAX_AREAS) gAreaUsed[id] = false;
            return Shinobi_ShowAreaList(playerid), true;
        }
        new id2 = gWizAreaId[playerid];
        if(id2 < 0 || id2 >= SHINOBI_MAX_AREAS || !gAreaUsed[id2]) return Shinobi_ShowAreaList(playerid), true;

        gAreaMobSkin[id2] = strval(inputtext);

        ShowPlayerDialog(playerid, DLG_WIZ_HP, DIALOG_STYLE_INPUT, "Criar area MOB - HP", "HP do NPC (ex: 900):", "Ok", "Cancelar");
        return true;
    }

    if(dialogid == DLG_WIZ_HP)
    {
        if(!response)
        {
            new id = gWizAreaId[playerid];
            if(id >= 0 && id < SHINOBI_MAX_AREAS) gAreaUsed[id] = false;
            return Shinobi_ShowAreaList(playerid), true;
        }
        new id2 = gWizAreaId[playerid];
        if(id2 < 0 || id2 >= SHINOBI_MAX_AREAS || !gAreaUsed[id2]) return Shinobi_ShowAreaList(playerid), true;

        new Float:hp = floatstr(inputtext);
        if(hp < 50.0) hp = 50.0;
        if(hp > 5000.0) hp = 5000.0;
        gAreaMobHP[id2] = hp;

        ShowPlayerDialog(playerid, DLG_WIZ_XP, DIALOG_STYLE_INPUT, "Criar area MOB - XP", "XP por kill (ex: 25):", "Ok", "Cancelar");
        return true;
    }

    if(dialogid == DLG_WIZ_XP)
    {
        if(!response)
        {
            new id = gWizAreaId[playerid];
            if(id >= 0 && id < SHINOBI_MAX_AREAS) gAreaUsed[id] = false;
            return Shinobi_ShowAreaList(playerid), true;
        }
        new id2 = gWizAreaId[playerid];
        if(id2 < 0 || id2 >= SHINOBI_MAX_AREAS || !gAreaUsed[id2]) return Shinobi_ShowAreaList(playerid), true;

        new xp = strval(inputtext);
        if(xp < 0) xp = 0;
        if(xp > 500) xp = 500;
        gAreaMobXP[id2] = xp;

        ShowPlayerDialog(playerid, DLG_WIZ_ELEM, DIALOG_STYLE_LIST, "Criar area MOB - Elemento",
            "Katon (0)\nFuuton (1)\nRaiton (2)\nDoton (3)\nSuiton (4)\nNenhum (-1)",
            "Ok", "Cancelar");
        return true;
    }

    if(dialogid == DLG_WIZ_ELEM)
    {
        if(!response)
        {
            new id = gWizAreaId[playerid];
            if(id >= 0 && id < SHINOBI_MAX_AREAS) gAreaUsed[id] = false;
            return Shinobi_ShowAreaList(playerid), true;
        }
        new id2 = gWizAreaId[playerid];
        if(id2 < 0 || id2 >= SHINOBI_MAX_AREAS || !gAreaUsed[id2]) return Shinobi_ShowAreaList(playerid), true;

        switch(listitem)
        {
            case 0: gAreaMobElem[id2] = KATON;
            case 1: gAreaMobElem[id2] = FUTON;
            case 2: gAreaMobElem[id2] = RAITON;
            case 3: gAreaMobElem[id2] = DOTON;
            case 4: gAreaMobElem[id2] = Suiton;
            default: gAreaMobElem[id2] = -1;
        }

        ShowPlayerDialog(playerid, DLG_WIZ_MELEE, DIALOG_STYLE_LIST, "Criar area MOB - Ataque",
            "Taijutsu (MELEE)\nKenjutsu (KENJUTSU)",
            "Ok", "Cancelar");
        return true;
    }

    if(dialogid == DLG_WIZ_MELEE)
    {
        if(!response)
        {
            new id = gWizAreaId[playerid];
            if(id >= 0 && id < SHINOBI_MAX_AREAS) gAreaUsed[id] = false;
            return Shinobi_ShowAreaList(playerid), true;
        }
        new id2 = gWizAreaId[playerid];
        if(id2 < 0 || id2 >= SHINOBI_MAX_AREAS || !gAreaUsed[id2]) return Shinobi_ShowAreaList(playerid), true;

        if(listitem == 0) gAreaMobMeleeType[id2] = MELEE;
        else gAreaMobMeleeType[id2] = KENJUTSU;

        // confirm
        new msg[256];
        format(msg, sizeof msg, "Nome: %s\nRaio: %.1f\nMax: %d\nRespawn: %dms\nSkin: %d\nHP: %.1f\nXP: %d\n\nCriar area?",
            gAreaName[id2], gAreaRadius[id2], gAreaMaxAlive[id2], gAreaRespawnMs[id2], gAreaMobSkin[id2], gAreaMobHP[id2], gAreaMobXP[id2]);

        ShowPlayerDialog(playerid, DLG_WIZ_CONFIRM, DIALOG_STYLE_MSGBOX, "Confirmar", msg, "Criar", "Cancelar");
        return true;
    }

    if(dialogid == DLG_WIZ_CONFIRM)
    {
        if(!response)
        {
            new id = gWizAreaId[playerid];
            if(id >= 0 && id < SHINOBI_MAX_AREAS) gAreaUsed[id] = false;
            return Shinobi_ShowAreaList(playerid), true;
        }

        SendClientMessage(playerid, -1, "[NPC] Area MOB criada.");
        Shinobi_SaveAreas();
        return Shinobi_ShowAreaList(playerid), true;
    }

    // Wizard PATROL
    if(dialogid == DLG_WIZP_NAME)
    {
        if(!response) return Shinobi_ShowAreaList(playerid), true;

        new name[32];
        format(name, sizeof name, "%s", inputtext);
        if(!name[0]) return SendClientMessage(playerid, -1, "[NPC] Nome vazio."), Shinobi_StartWizard(playerid, AREA_TYPE_PATROL), true;

        new id = Shinobi_FindFreeArea();
        if(id == -1) return SendClientMessage(playerid, -1, "[NPC] Limite de areas atingido."), true;

        gAreaUsed[id] = true;
        gAreaType[id] = AREA_TYPE_PATROL;
        format(gAreaName[id], 32, "%s", name);

        GetPlayerPos(playerid, gAreaPos[id][0], gAreaPos[id][1], gAreaPos[id][2]);
        gAreaVW[id] = GetPlayerVirtualWorld(playerid);
        gAreaInt[id] = GetPlayerInterior(playerid);

        gWizAreaId[playerid] = id;
        gWizType[playerid] = AREA_TYPE_PATROL;

        ShowPlayerDialog(playerid, DLG_WIZP_RADIUS, DIALOG_STYLE_INPUT, "Criar area PATRULHA - Raio", "Raio em metros (ex: 35):", "Ok", "Cancelar");
        return true;
    }

    if(dialogid == DLG_WIZP_RADIUS)
    {
        if(!response)
        {
            new id = gWizAreaId[playerid];
            if(id >= 0 && id < SHINOBI_MAX_AREAS) gAreaUsed[id] = false;
            return Shinobi_ShowAreaList(playerid), true;
        }

        new id2 = gWizAreaId[playerid];
        if(id2 < 0 || id2 >= SHINOBI_MAX_AREAS || !gAreaUsed[id2]) return Shinobi_ShowAreaList(playerid), true;

        new Float:r = floatstr(inputtext);
        if(r < 5.0) r = 5.0;
        if(r > 200.0) r = 200.0;
        gAreaRadius[id2] = r;

        ShowPlayerDialog(playerid, DLG_WIZP_CONFIRM, DIALOG_STYLE_MSGBOX, "Confirmar", "Criar area de patrulha aqui?", "Criar", "Cancelar");
        return true;
    }

    if(dialogid == DLG_WIZP_CONFIRM)
    {
        if(!response)
        {
            new id = gWizAreaId[playerid];
            if(id >= 0 && id < SHINOBI_MAX_AREAS) gAreaUsed[id] = false;
            return Shinobi_ShowAreaList(playerid), true;
        }

        SendClientMessage(playerid, -1, "[NPC] Area PATRULHA criada.");
        Shinobi_SaveAreas();
        return Shinobi_ShowAreaList(playerid), true;
    }

    // Skins - pick vila
    if(dialogid == DLG_SKIN_VILA)
    {
        if(!response) return Shinobi_ShowAdminMenu(playerid), true;

        new vila = 0;
        switch(listitem)
        {
            case 0: vila = 1;
            case 1: vila = 3;
            case 2: vila = 5;
            case 3: vila = 4;
            case 4: vila = 2;
            default: return Shinobi_ShowAdminMenu(playerid), true;
        }

        SetPVarInt(playerid, "shrp_skin_vila", vila);

        new current[256];
        current[0] = '\0';
        for(new i=0;i<gVilaSkinCount[vila];i++)
        {
            new t[16];
            format(t, sizeof t, "%d", gVilaSkins[vila][i]);
            strcat(current, t, sizeof current);
            if(i < gVilaSkinCount[vila]-1) strcat(current, ",", sizeof current);
        }
        if(!current[0]) strcat(current, "(nenhuma)", sizeof current);

        new vilaName[24];
        Shinobi_VilaName(vila, vilaName, sizeof vilaName);

        new msg[320];
        format(msg, sizeof msg, "Vila: %s\nAtual: %s\n\nDigite lista CSV (ex: 300,301,302)\nMax %d skins.", vilaName, current, SHINOBI_MAX_SKINS_PER_VILA);

        ShowPlayerDialog(playerid, DLG_SKIN_SET, DIALOG_STYLE_INPUT, "Setar skins", msg, "Salvar", "Cancelar");
        return true;
    }

    if(dialogid == DLG_SKIN_SET)
    {
        if(!response) return Shinobi_ShowAdminMenu(playerid), true;

        new vila = GetPVarInt(playerid, "shrp_skin_vila");
        if(vila < 0 || vila > 11) return Shinobi_ShowAdminMenu(playerid), true;

        // parse csv
        gVilaSkinCount[vila] = 0;

        new num[16]; new ni=0; new c=0;
        for(new i=0; inputtext[i] != '\0'; i++)
        {
            if(inputtext[i] == ',' || inputtext[i] == ' ' || inputtext[i] == '\t')
            {
                if(ni > 0)
                {
                    num[ni] = '\0';
                    if(c < SHINOBI_MAX_SKINS_PER_VILA) gVilaSkins[vila][c++] = strval(num);
                    ni = 0;
                }
                continue;
            }
            if(ni < sizeof(num)-1) num[ni++] = inputtext[i];
        }
        if(ni > 0 && c < SHINOBI_MAX_SKINS_PER_VILA)
        {
            num[ni] = '\0';
            gVilaSkins[vila][c++] = strval(num);
        }
        gVilaSkinCount[vila] = c;

        Shinobi_SaveSkins();
        SendClientMessage(playerid, -1, "[NPC] Skins salvas.");
        return Shinobi_ShowAdminMenu(playerid), true;
    }

    // Guerra
    if(dialogid == DLG_WAR_PICK_A)
    {
        if(!response) return Shinobi_ShowAdminMenu(playerid), true;

        new vila=0;
        switch(listitem)
        {
            case 0: vila = 1;
            case 1: vila = 3;
            case 2: vila = 5;
            case 3: vila = 4;
            case 4: vila = 2;
            default: return Shinobi_ShowAdminMenu(playerid), true;
        }
        gWarPickA[playerid] = vila;
        return Shinobi_ShowWarPickB(playerid), true;
    }

    if(dialogid == DLG_WAR_PICK_B)
    {
        if(!response) return Shinobi_ShowAdminMenu(playerid), true;

        new vilaB=0;
        switch(listitem)
        {
            case 0: vilaB = 1;
            case 1: vilaB = 3;
            case 2: vilaB = 5;
            case 3: vilaB = 4;
            case 4: vilaB = 2;
            default: return Shinobi_ShowAdminMenu(playerid), true;
        }

        new vilaA = gWarPickA[playerid];
        if(vilaA == 0 || vilaB == 0 || vilaA == vilaB) return SendClientMessage(playerid, -1, "[NPC] Selecao invalida."), Shinobi_ShowAdminMenu(playerid), true;

        // msgbox toggle
        new aName[24], bName[24];
        Shinobi_VilaName(vilaA, aName, sizeof aName);
        Shinobi_VilaName(vilaB, bName, sizeof bName);

        new on = gWar[vilaA][vilaB] ? 1 : 0;

        new msg[220];
        format(msg, sizeof msg, "Ativar/desativar guerra entre:\n%s x %s\n\nEstado atual: %s", aName, bName, on ? "ATIVA" : "DESATIVADA");

        SetPVarInt(playerid, "shrp_war_a", vilaA);
        SetPVarInt(playerid, "shrp_war_b", vilaB);

        ShowPlayerDialog(playerid, DLG_WAR_SET, DIALOG_STYLE_MSGBOX, "Guerra", msg, on ? "Desativar" : "Ativar", "Voltar");
        return true;
    }

    if(dialogid == DLG_WAR_SET)
    {
        if(!response) return Shinobi_ShowAdminMenu(playerid), true;

        new a = GetPVarInt(playerid, "shrp_war_a");
        new b = GetPVarInt(playerid, "shrp_war_b");
        if(a < 0 || a > 11 || b < 0 || b > 11) return Shinobi_ShowAdminMenu(playerid), true;

        // toggle
        new nowOn = gWar[a][b] ? 0 : 1;
        gWar[a][b] = (nowOn != 0);
        gWar[b][a] = (nowOn != 0);

        Shinobi_SaveWar();

        SendClientMessage(playerid, -1, nowOn ? "[NPC] Guerra ATIVADA." : "[NPC] Guerra DESATIVADA.");
        return Shinobi_ShowAdminMenu(playerid), true;
    }

    // Kage: pick area
    if(dialogid == DLG_KAGE_PICK_AREA)
    {
        if(!response) return Shinobi_ShowKageMenu(playerid), true;

        // build mapping for patrol areas
        new map[SHINOBI_MAX_AREAS+1];
        new cnt=0;
        for(new i=0;i<SHINOBI_MAX_AREAS;i++)
        {
            if(!gAreaUsed[i]) continue;
            if(gAreaType[i] != AREA_TYPE_PATROL) continue;
            map[cnt++] = i;
        }
        map[cnt++] = -1; // voltar
        new sel = map[listitem];
        if(sel < 0) return Shinobi_ShowKageMenu(playerid), true;

        gKagePickArea[playerid] = sel;
        ShowPlayerDialog(playerid, DLG_KAGE_QTY, DIALOG_STYLE_INPUT, "Contratar patrulha - Quantidade", "Quantos patrulheiros? (1..12)", "Ok", "Cancelar");
        return true;
    }

    if(dialogid == DLG_KAGE_QTY)
    {
        if(!response) return Shinobi_ShowKageMenu(playerid), true;

        new q = strval(inputtext);
        if(q < 1) q = 1;
        if(q > SHINOBI_PATROL_QTY_MAX) q = SHINOBI_PATROL_QTY_MAX;
        gKagePickQty[playerid] = q;

        ShowPlayerDialog(playerid, DLG_KAGE_MINUTES, DIALOG_STYLE_INPUT, "Contratar patrulha - Duracao", "Duracao em minutos (5..120)", "Ok", "Cancelar");
        return true;
    }

    if(dialogid == DLG_KAGE_MINUTES)
    {
        if(!response) return Shinobi_ShowKageMenu(playerid), true;

        new m = strval(inputtext);
        if(m < SHINOBI_PATROL_MIN_MINUTES) m = SHINOBI_PATROL_MIN_MINUTES;
        if(m > SHINOBI_PATROL_MAX_MINUTES) m = SHINOBI_PATROL_MAX_MINUTES;
        gKagePickMinutes[playerid] = m;

        new area = gKagePickArea[playerid];
        if(area < 0 || area >= SHINOBI_MAX_AREAS || !gAreaUsed[area] || gAreaType[area] != AREA_TYPE_PATROL) return Shinobi_ShowKageMenu(playerid), true;

        // calcula custo
        new cost = gKagePickQty[playerid] * gKagePickMinutes[playerid] * SHINOBI_PATROL_COST_PER_MIN;
        new vila = Info[playerid][pMember];

        new vilaName[24];
        Shinobi_VilaName(vila, vilaName, sizeof vilaName);

        new treasury = Shinobi_GetTreasury(vila);

        new msg[256];
        format(msg, sizeof msg,
            "Vila: %s\nArea: %s\nQtd: %d\nTempo: %d min\nCusto: %d\nTesouro atual: %d\n\nConfirmar contrato?",
            vilaName, gAreaName[area], gKagePickQty[playerid], gKagePickMinutes[playerid], cost, treasury);

        SetPVarInt(playerid, "shrp_patrol_cost", cost);

        ShowPlayerDialog(playerid, DLG_KAGE_CONFIRM, DIALOG_STYLE_MSGBOX, "Confirmar", msg, "Contratar", "Cancelar");
        return true;
    }

    if(dialogid == DLG_KAGE_CONFIRM)
    {
        if(!response) return Shinobi_ShowKageMenu(playerid), true;

        new area = gKagePickArea[playerid];
        if(area < 0 || area >= SHINOBI_MAX_AREAS || !gAreaUsed[area] || gAreaType[area] != AREA_TYPE_PATROL) return Shinobi_ShowKageMenu(playerid), true;

        new vila = Info[playerid][pMember];
        new cost = GetPVarInt(playerid, "shrp_patrol_cost");

        // exige guerra ativa com alguem? (regra simples: precisa ter pelo menos 1 rival setado)
        new hasWar = false;
        for(new v=0; v<12; v++)
        {
            if(v == vila) continue;
            if(gWar[vila][v]) { hasWar = true; break; }
        }
        if(!hasWar) return SendClientMessage(playerid, -1, "[NPC] Sua vila nao esta em guerra (admin precisa ativar em /npc)."), Shinobi_ShowKageMenu(playerid), true;

        // skins definidas?
        if(gVilaSkinCount[vila] <= 0) return SendClientMessage(playerid, -1, "[NPC] Admin ainda nao definiu skins da sua vila."), Shinobi_ShowKageMenu(playerid), true;

        if(!Shinobi_TrySpendTreasury(vila, cost))
            return SendClientMessage(playerid, -1, "[NPC] Tesouro insuficiente."), Shinobi_ShowKageMenu(playerid), true;

        // cria contrato
        new cid=-1;
        for(new c=0;c<SHINOBI_MAX_CONTRACTS;c++) if(!gContractUsed[c]) { cid=c; break; }
        if(cid == -1) return SendClientMessage(playerid, -1, "[NPC] Limite de contratos atingido."), Shinobi_ShowKageMenu(playerid), true;

        gContractUsed[cid] = true;
        gContractVila[cid] = vila;
        gContractArea[cid] = area;
        gContractQty[cid] = gKagePickQty[playerid];
        gContractCost[cid] = cost;
        gContractEndTick[cid] = GetTickCount() + (gKagePickMinutes[playerid] * 60 * 1000);

        // spawn patrulheiros (nao respawnam; contrato fica ativo)
        new spawned=0;
        for(new i=0;i<gContractQty[cid];i++)
        {
            new ns = Shinobi_FindFreeNpcSlot();
            if(ns == -1) break;
            if(Shinobi_SpawnNpcInArea(ns, area, NPC_KIND_PATROL, vila)) spawned++;
        }

        new msg[128];
        format(msg, sizeof msg, "[NPC] Contrato ativo: %d patrulheiros por %d min. (custo %d)", spawned, gKagePickMinutes[playerid], cost);
        SendClientMessage(playerid, -1, msg);

        return Shinobi_ShowKageMenu(playerid), true;
    }

    if(dialogid == DLG_KAGE_ACTIVE)
    {
        // Somente listar (sem actions por enquanto)
        return true;
    }

    return false;
}

// ==========================================================
// Commands
// ==========================================================
#if defined CMD

CMD:npc(playerid, params[])
{
    if(!ShinobiSys_IsAdmin(playerid) && !ShinobiSys_IsKage(playerid))
        return SendClientMessage(playerid, -1, "[NPC] Apenas admin/kage."), 1;

    Shinobi_ShowMainMenu(playerid);
    return 1;
}

#endif