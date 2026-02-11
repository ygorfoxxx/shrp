// ============================================
// SHRP - NPCs Shinobi (movimento/seguir/combate/XP/patrulha)
// Arquivo sugerido: Includes/Npcs/shinobi_ai.pwn
// Baseado no seu bandidos_novo_v10 (mantm separado pra no quebrar o talk/IA)
// ============================================

#if defined _SHRP_SHINOBI_AI_INCLUDED
    #endinput
#endif
#define _SHRP_SHINOBI_AI_INCLUDED

#include <a_samp>

// FCNPC.inc exige o smbolo HTTP em alguns setups.
// (Voc j resolveu isso no bandidos, mas aqui fica redundante e seguro.)
#if !defined HTTP
native HTTP(index, type, const url[], const data[], const callback[]);
#endif

#include <FCNPC>

// Se voc tiver esses defines no seu GM, beleza. Se no, o include continua compilando.
#if !defined EOS
    #define EOS (0)
#endif

// -----------------------------
// Config
// -----------------------------
#define MAXIMO_NPCS_COMBATE      (80)

// Tipos
#define NPCT_HOSTILE             (1) // mob que caa jogadores
#define NPCT_GUARD               (2) // guarda/clone de um dono
#define NPCT_PATROL              (3) // patrulha (vai e volta na rea)

// Estados
#define NPCS_IDLE                (0)
#define NPCS_PATROL              (1)
#define NPCS_FOLLOW              (2)
#define NPCS_CHASE               (3)
#define NPCS_DEAD                (4)

// -----------------------------
// Data
// -----------------------------
new gNpcId[MAXIMO_NPCS_COMBATE];
new bool:gNpcUsed[MAXIMO_NPCS_COMBATE];
new gNpcType[MAXIMO_NPCS_COMBATE];
new gNpcState[MAXIMO_NPCS_COMBATE];

new gNpcOwner[MAXIMO_NPCS_COMBATE];         // dono (para guard/clone). INVALID_PLAYER_ID se nenhum
new gNpcTarget[MAXIMO_NPCS_COMBATE];        // alvo atual. INVALID_PLAYER_ID se nenhum
new gNpcVila[MAXIMO_NPCS_COMBATE];          // vila/faccao do NPC (use seu id de vila)

new Float:gNpcHome[MAXIMO_NPCS_COMBATE][3]; // ponto-base (spawn)
new gNpcVW[MAXIMO_NPCS_COMBATE];
new gNpcInt[MAXIMO_NPCS_COMBATE];

new Float:gNpcHP[MAXIMO_NPCS_COMBATE];
new Float:gNpcHPMax[MAXIMO_NPCS_COMBATE];

new gNpcXPReward[MAXIMO_NPCS_COMBATE];
new gNpcMoneyReward[MAXIMO_NPCS_COMBATE];

new Float:gNpcAggroRange[MAXIMO_NPCS_COMBATE];
new Float:gNpcAttackRange[MAXIMO_NPCS_COMBATE];
new Float:gNpcFollowDist[MAXIMO_NPCS_COMBATE];
new Float:gNpcPatrolRadius[MAXIMO_NPCS_COMBATE];

new gNpcNextThinkTick[MAXIMO_NPCS_COMBATE];
new gNpcLastAttackTick[MAXIMO_NPCS_COMBATE];

// Controle de stun / ritmo de combate
new gNpcStunUntilTick[MAXIMO_NPCS_COMBATE];
new gNpcStunImmuneUntilTick[MAXIMO_NPCS_COMBATE];
new gNpcStunMs[MAXIMO_NPCS_COMBATE];
new gNpcStunImmuneMs[MAXIMO_NPCS_COMBATE];
new gNpcAttackCooldownMs[MAXIMO_NPCS_COMBATE];
new gNpcLastDamager[MAXIMO_NPCS_COMBATE];

new gNpcHitSeq[MAXIMO_NPCS_COMBATE]; // 1..4 sequncia de golpes (taijutsu)

new gNpcTimer = -1;

// Mapeamento rpido: playerid -> slot do NPC (somente para NPCs desse include)
new gNpcSlotByPlayer[MAX_PLAYERS];

// Jutsu opcional (chama comando ZCMD: "cmd_<nome>")
new gNpcJutsuCmd[MAXIMO_NPCS_COMBATE][24]; // ex: "katon", "suiton"
new bool:gNpcJutsuNeedsTarget[MAXIMO_NPCS_COMBATE];
new gNpcJutsuCooldownMs[MAXIMO_NPCS_COMBATE];
new gNpcLastJutsuTick[MAXIMO_NPCS_COMBATE];

// -----------------------------
// Helpers
// -----------------------------
stock Float:SHRP_FRandom(Float:minv, Float:maxv)
{
    new r = random(10000); // 0..9999
    return minv + (float(r) / 9999.0) * (maxv - minv);
}

stock Float:SHRP_Dist3D(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2)
{
    new Float:dx = x1 - x2;
    new Float:dy = y1 - y2;
    new Float:dz = z1 - z2;
    return floatsqroot(dx*dx + dy*dy + dz*dz);
}

stock Float:SHRP_Dist2D(Float:x1, Float:y1, Float:x2, Float:y2)
{
    new Float:dx = x1 - x2;
    new Float:dy = y1 - y2;
    return floatsqroot(dx*dx + dy*dy);
}

stock SHRP_IsValidPlayer(playerid)
{
    return (playerid >= 0 && playerid < MAX_PLAYERS && IsPlayerConnected(playerid));
}

stock SHRP_IsRealPlayer(playerid)
{
    return (SHRP_IsValidPlayer(playerid) && !IsPlayerNPC(playerid));
}

stock SHRP_NpcSlotFromId(npcid)
{
    if (npcid < 0 || npcid >= MAX_PLAYERS) return -1;
    return gNpcSlotByPlayer[npcid];
}

stock bool:SHRP_NpcIsOurs(playerid)
{
    new slot = SHRP_NpcSlotFromId(playerid);
    return (slot != -1 && gNpcUsed[slot] && gNpcId[slot] == playerid);
}

// Retorna o playerid (npcid) de um slot do AI
stock SHRP_NpcGetId(slot)
{
    if (slot < 0 || slot >= MAXIMO_NPCS_COMBATE) return INVALID_PLAYER_ID;
    if (!gNpcUsed[slot]) return INVALID_PLAYER_ID;
    return gNpcId[slot];
}
// -------------------------------------------------
// API runtime para outros includes (evita depender de ordem de #include)
// -------------------------------------------------

// Registra um NPC j criado via FCNPC_Create/Spawn como NPC de combate deste AI.
// Retorna o slot do AI ou -1 se falhar.
forward SHRP_NpcAI_RegisterExisting(npcid, npctype, vila, Float:x, Float:y, Float:z, vw, interior);
public SHRP_NpcAI_RegisterExisting(npcid, npctype, vila, Float:x, Float:y, Float:z, vw, interior)
{
    if(npcid == INVALID_PLAYER_ID) return -1;
    if(!IsPlayerConnected(npcid) || !IsPlayerNPC(npcid)) return -1;

    // j est registrado?
    new cur = SHRP_NpcSlotFromId(npcid);
    if(cur != -1) return cur;

    new slot = SHRP_NpcAllocSlot();
    if(slot == -1) return -1;

    // base
    gNpcUsed[slot] = true;
    gNpcId[slot] = npcid;
    gNpcType[slot] = npctype;
    gNpcState[slot] = NPCS_IDLE;
    gNpcOwner[slot] = INVALID_PLAYER_ID;
    gNpcTarget[slot] = INVALID_PLAYER_ID;
    gNpcVila[slot] = vila;
    gNpcHome[slot][0] = x;
    gNpcHome[slot][1] = y;
    gNpcHome[slot][2] = z;
    gNpcVW[slot] = vw;
    gNpcInt[slot] = interior;

    gNpcHPMax[slot] = 100.0;
    gNpcHP[slot] = 100.0;
    gNpcXPReward[slot] = 0;
    gNpcMoneyReward[slot] = 0;

    gNpcAggroRange[slot] = 20.0;
    gNpcAttackRange[slot] = 2.3;
    gNpcFollowDist[slot] = 2.2;
    gNpcPatrolRadius[slot] = 18.0;

    gNpcStunUntilTick[slot] = 0;
    gNpcStunImmuneUntilTick[slot] = 0;
    gNpcStunMs[slot] = 320;
    gNpcStunImmuneMs[slot] = 520;
    gNpcAttackCooldownMs[slot] = 900;
    gNpcLastAttackTick[slot] = 0;
    gNpcLastDamager[slot] = INVALID_PLAYER_ID;
    gNpcHitSeq[slot] = 0;

    // map reverse
    gNpcSlotByPlayer[npcid] = slot;

    // Garantir VW/Int do NPC
    SetPlayerVirtualWorld(npcid, vw);
    SetPlayerInterior(npcid, interior);

    return slot;
}

// Aplica um preset seguro de balance (usado pelo bandidos via CallLocalFunction).
forward SHRP_NpcAI_ConfigureDefaults(slot);
public SHRP_NpcAI_ConfigureDefaults(slot)
{
    if(slot < 0 || slot >= MAXIMO_NPCS_COMBATE) return 0;
    if(!gNpcUsed[slot]) return 0;

    // defaults (pode ajustar depois via menu)
    gNpcHPMax[slot] = 110.0;
    gNpcHP[slot] = 110.0;
    gNpcXPReward[slot] = 60;
    gNpcMoneyReward[slot] = 40;
    gNpcAggroRange[slot] = 22.0;
    gNpcAttackRange[slot] = 2.4;

    // cooldown por tipo (combate mais justo)
    if(gNpcType[slot] == NPCT_HOSTILE) gNpcAttackCooldownMs[slot] = 850;
    else if(gNpcType[slot] == NPCT_GUARD) gNpcAttackCooldownMs[slot] = 950;
    else gNpcAttackCooldownMs[slot] = 1000;

    // Stun balance: evita stunlock infinito mas permite reao do NPC.
    // Regra: 1 hit = aplica stun; hits durante stun NO estendem.
    // Depois do stun, o NPC fica imune a stun por um curto perodo.
    // Ajuste por HP: bosses (HP alto) tomam menos stun.
    if(gNpcHPMax[slot] >= 400.0)
    {
        gNpcStunMs[slot] = 180;
        gNpcStunImmuneMs[slot] = 700;
    }
    else if(gNpcHPMax[slot] >= 220.0)
    {
        gNpcStunMs[slot] = 240;
        gNpcStunImmuneMs[slot] = 600;
    }
    else
    {
        gNpcStunMs[slot] = 300;
        gNpcStunImmuneMs[slot] = 520;
    }

    return 1;

}
// Retorna 1 se 'npcid' for um NPC do shinobi_ai e o dono (owner) for 'ownerid'
public SHRP_NpcAI_IsOwnedBy(npcid, ownerid)
{
    new slot = SHRP_NpcSlotFromId(npcid);
    if(slot == -1 || !gNpcUsed[slot] || gNpcId[slot] != npcid) return 0;
    return (gNpcOwner[slot] == ownerid);
}

// Retorna 1 se o id for um NPC gerenciado pelo shinobi_ai (mob/guard/patrol)
public SHRP_NpcAI_IsCombatNPC_Public(playerid)
{
    new slot = SHRP_NpcSlotFromId(playerid);
    if(slot == -1 || !gNpcUsed[slot] || gNpcId[slot] != playerid) return 0;
    return 1;
}



stock bool:SHRP_IsCombatEntity(playerid)
{
    return (SHRP_IsRealPlayer(playerid) || (IsPlayerNPC(playerid) && SHRP_NpcAI_IsCombatNPC(playerid)));
}

stock bool:SHRP_IsSameContext(slot, targetid)
{
    if (GetPlayerVirtualWorld(targetid) != gNpcVW[slot]) return false;
    if (GetPlayerInterior(targetid) != gNpcInt[slot]) return false;
    return true;
}

// Aplica stun de forma balanceada (sem stunlock infinito)
stock SHRP_NpcAI_TryApplyStun(slot)
{
    new now = GetTickCount();

    // Se j est stunado, NO estende (isso evita perma-stun)
    if(now < gNpcStunUntilTick[slot]) return 0;

    // Janela de imunidade a stun, para o NPC conseguir reagir/contra-atacar
    if(now < gNpcStunImmuneUntilTick[slot]) return 0;

    gNpcStunUntilTick[slot] = now + gNpcStunMs[slot];
    gNpcStunImmuneUntilTick[slot] = now + gNpcStunImmuneMs[slot];
    return 1;
}

stock SHRP_GetEntityVila(entityid)
{
    if (SHRP_IsRealPlayer(entityid)) return Info[entityid][pMember];
    if (IsPlayerNPC(entityid) && SHRP_NpcAI_IsCombatNPC(entityid))
    {
        new s = SHRP_NpcSlotFromId(entityid);
        if (s != -1 && gNpcUsed[s]) return gNpcVila[s];
    }
    return 0;
}

// Notifica guards/clones quando o dono toma dano (chame do OnPlayerTakeDamage)
stock SHRP_NpcAI_OnPlayerDamaged(victimid, attackerid, Float:amount)
{
    if (!SHRP_IsRealPlayer(victimid)) return 0;
    if (!SHRP_IsCombatEntity(attackerid)) return 0;
    for (new s=0; s<MAXIMO_NPCS_COMBATE; s++)
    {
        if (!gNpcUsed[s]) continue;
        if (gNpcState[s] == NPCS_DEAD) continue;
        if (gNpcOwner[s] != victimid) continue;
        if (gNpcType[s] != NPCT_GUARD) continue;
        if (!SHRP_IsSameContext(s, attackerid)) continue;
        gNpcTarget[s] = attackerid;
        gNpcState[s] = NPCS_CHASE;
    }
    return 1;
}

stock SHRP_NpcResetSlot(slot)
{
    gNpcId[slot] = INVALID_PLAYER_ID;
    gNpcUsed[slot] = false;
    gNpcType[slot] = 0;
    gNpcState[slot] = NPCS_IDLE;

    gNpcOwner[slot] = INVALID_PLAYER_ID;
    gNpcTarget[slot] = INVALID_PLAYER_ID;
    gNpcVila[slot] = 0;

    gNpcHome[slot][0] = 0.0;
    gNpcHome[slot][1] = 0.0;
    gNpcHome[slot][2] = 0.0;

    gNpcVW[slot] = 0;
    gNpcInt[slot] = 0;

    gNpcHP[slot] = 100.0;
    gNpcHPMax[slot] = 100.0;

    gNpcXPReward[slot] = 0;
    gNpcMoneyReward[slot] = 0;

    gNpcAggroRange[slot] = 25.0;
    gNpcAttackRange[slot] = 2.5;
    gNpcFollowDist[slot] = 2.5;
    gNpcPatrolRadius[slot] = 20.0;

    gNpcNextThinkTick[slot] = 0;
    gNpcLastAttackTick[slot] = 0;

    gNpcHitSeq[slot] = 0;

    gNpcStunUntilTick[slot] = 0;
    gNpcStunImmuneUntilTick[slot] = 0;
    gNpcStunMs[slot] = 320;
    gNpcStunImmuneMs[slot] = 520;
    gNpcAttackCooldownMs[slot] = 850; // default (ajustado no create por tipo)
    gNpcLastDamager[slot] = INVALID_PLAYER_ID;

    gNpcJutsuCmd[slot][0] = EOS;
    gNpcJutsuNeedsTarget[slot] = false;
    gNpcJutsuCooldownMs[slot] = 5000;
    gNpcLastJutsuTick[slot] = 0;
}

stock SHRP_NpcAllocSlot()
{
    for (new i = 0; i < MAXIMO_NPCS_COMBATE; i++)
    {
        if (!gNpcUsed[i]) return i;
    }
    return -1;
}

// -----------------------------
// API: init/shutdown
// -----------------------------
forward SHRP_NpcAI_Tick();
public SHRP_NpcAI_Tick();

stock SHRP_NpcAI_Init()
{
    // init map
    for (new p = 0; p < MAX_PLAYERS; p++) gNpcSlotByPlayer[p] = -1;

    // init slots
    for (new i = 0; i < MAXIMO_NPCS_COMBATE; i++) SHRP_NpcResetSlot(i);

    if (gNpcTimer != -1) KillTimer(gNpcTimer);
    gNpcTimer = SetTimer("SHRP_NpcAI_Tick", 250, true);
    return 1;
}

stock SHRP_NpcAI_Shutdown()
{
    if (gNpcTimer != -1)
    {
        KillTimer(gNpcTimer);
        gNpcTimer = -1;
    }

    for (new i = 0; i < MAXIMO_NPCS_COMBATE; i++)
    {
        if (gNpcUsed[i] && gNpcId[i] != INVALID_PLAYER_ID)
        {
            FCNPC_Destroy(gNpcId[i]);
        }
        SHRP_NpcResetSlot(i);
    }

    for (new p = 0; p < MAX_PLAYERS; p++) gNpcSlotByPlayer[p] = -1;
    return 1;
}

// -----------------------------
// API: criao
// -----------------------------
stock SHRP_NpcCreate(const name[], skin, type, vila, Float:x, Float:y, Float:z, vw = 0, interior = 0)
{
    new slot = SHRP_NpcAllocSlot();
    if (slot == -1) return -1;

    new npcid = FCNPC_Create(name);
    if (npcid == INVALID_PLAYER_ID) return -1;

    FCNPC_Spawn(npcid, skin, x, y, z);
    SetPlayerSkin(npcid, skin); // garante a skin
    SetPlayerVirtualWorld(npcid, vw);
    SetPlayerInterior(npcid, interior);

    gNpcUsed[slot] = true;
    gNpcId[slot] = npcid;
    gNpcSlotByPlayer[npcid] = slot;

    // stats base (pra dano de taijutsu funcionar mesmo sem template)
    Info[npcid][pTaijutsu] = 50;

    gNpcType[slot] = type;

    // cooldown de ataque por tipo (ajuste fino aqui se quiser)
    if (type == NPCT_HOSTILE) gNpcAttackCooldownMs[slot] = 850;
    else if (type == NPCT_GUARD) gNpcAttackCooldownMs[slot] = 950;
    else if (type == NPCT_PATROL) gNpcAttackCooldownMs[slot] = 1000;
    else gNpcAttackCooldownMs[slot] = 900;
    gNpcState[slot] = (type == NPCT_PATROL) ? NPCS_PATROL : NPCS_IDLE;
    gNpcVila[slot] = vila;

    gNpcHome[slot][0] = x;
    gNpcHome[slot][1] = y;
    gNpcHome[slot][2] = z;
    gNpcVW[slot] = vw;
    gNpcInt[slot] = interior;

    // HP default
    gNpcHPMax[slot] = 120.0;
    gNpcHP[slot] = gNpcHPMax[slot];

    // recompensas default
    gNpcXPReward[slot] = 0;
    gNpcMoneyReward[slot] = 0;

    // ranges
    gNpcAggroRange[slot] = 25.0;
    gNpcAttackRange[slot] = 2.5;
    gNpcFollowDist[slot] = 2.5;
    gNpcPatrolRadius[slot] = 20.0;

    // para guard/clone (voc seta depois)
    gNpcOwner[slot] = INVALID_PLAYER_ID;
    gNpcTarget[slot] = INVALID_PLAYER_ID;

    return slot;
}

stock SHRP_NpcDestroy(slot)
{
    if (slot < 0 || slot >= MAXIMO_NPCS_COMBATE) return 0;
    if (!gNpcUsed[slot]) return 0;

    new npcid = gNpcId[slot];
    if (npcid != INVALID_PLAYER_ID)
    {
        if (npcid >= 0 && npcid < MAX_PLAYERS) gNpcSlotByPlayer[npcid] = -1;
        FCNPC_Destroy(npcid);
    }
    SHRP_NpcResetSlot(slot);
    return 1;
}

stock SHRP_NpcSetRewards(slot, xp, money)
{
    if (slot < 0 || slot >= MAXIMO_NPCS_COMBATE) return 0;
    if (!gNpcUsed[slot]) return 0;
    gNpcXPReward[slot] = xp;
    gNpcMoneyReward[slot] = money;
    return 1;
}

stock SHRP_NpcSetHP(slot, Float:hpmax)
{
    if (slot < 0 || slot >= MAXIMO_NPCS_COMBATE) return 0;
    if (!gNpcUsed[slot]) return 0;
    if (hpmax < 1.0) hpmax = 1.0;
    gNpcHPMax[slot] = hpmax;
    gNpcHP[slot] = hpmax;
    return 1;
}

stock SHRP_NpcSetPatrolRadius(slot, Float:radius)
{
    if (slot < 0 || slot >= MAXIMO_NPCS_COMBATE) return 0;
    if (!gNpcUsed[slot]) return 0;
    if (radius < 2.0) radius = 2.0;
    gNpcPatrolRadius[slot] = radius;
    gNpcState[slot] = NPCS_PATROL;
    return 1;
}

stock SHRP_NpcSetOwner(slot, ownerid, Float:followDist = 2.5)
{
    if (slot < 0 || slot >= MAXIMO_NPCS_COMBATE) return 0;
    if (!gNpcUsed[slot]) return 0;
    gNpcOwner[slot] = ownerid;
    gNpcFollowDist[slot] = followDist;
    gNpcState[slot] = NPCS_FOLLOW;
    return 1;
}

stock SHRP_NpcSetJutsu(slot, const cmdName[], bool:needsTarget = false, cooldownMs = 5000)
{
    if (slot < 0 || slot >= MAXIMO_NPCS_COMBATE) return 0;
    if (!gNpcUsed[slot]) return 0;

    format(gNpcJutsuCmd[slot], sizeof(gNpcJutsuCmd[]), "%s", cmdName);
    gNpcJutsuNeedsTarget[slot] = needsTarget;
    gNpcJutsuCooldownMs[slot] = (cooldownMs < 1000) ? 1000 : cooldownMs;
    gNpcLastJutsuTick[slot] = 0;
    return 1;
}

stock SHRP_NpcSetTaijutsu(slot, taijutsu)
{
    if (slot < 0 || slot >= MAXIMO_NPCS_COMBATE) return 0;
    if (!gNpcUsed[slot]) return 0;

    new npcid = gNpcId[slot];
    if (npcid == INVALID_PLAYER_ID) return 0;

    // usa o stat do seu GM pra calcular dano no HitPlayer()/GetDamageToPlayer()
    Info[npcid][pTaijutsu] = taijutsu;
    return 1;
}

// -----------------------------
// Integrao com o GM:
// 1) Permitir bater em NPCs (Taijutsu/Kenjutsu/etc):
//    No seu SHRP.pwn, altere o IsPlayerHittable() pra:
//      return IsPlayerHittableEx(playerid, SHRP_NpcAI_IsCombatNPC(playerid));
//
// 2) Dano em NPC vindo do seu SetDamageToPlayer():
//    Seu GM j tem hook via _NNRP_BANDIDOS_PWN_ + Bandido_ApplyDamageFromPlayer.
//    Aqui a gente define esse hook pra desviar dano pro HP do NPC.
// -----------------------------

stock bool:SHRP_NpcAI_IsCombatNPC(playerid)
{
    new slot = SHRP_NpcSlotFromId(playerid);
    if(slot == -1 || !gNpcUsed[slot] || gNpcId[slot] != playerid) return false;
    return (gNpcType[slot] == NPCT_HOSTILE || gNpcType[slot] == NPCT_GUARD || gNpcType[slot] == NPCT_PATROL);
}


// IMPORTANTE:
// - Se o NPC no  "nosso", a gente retorna true tambm (pra impedir BajarVida em NPC desconhecido).
// - Se voc tiver outros sistemas de FCNPC (ex: animais) que dependem de SetDamageToPlayer,
//   a voc ajusta aqui pra "return false" pra esses casos.
#if !defined _NNRP_BANDIDOS_PWN_
    #define _NNRP_BANDIDOS_PWN_
#endif

stock bool:Bandido_ApplyDamageFromPlayer(damagerid, damagedid, Float:damage)
{
    if (!IsPlayerNPC(damagedid)) return false;

    new slot = SHRP_NpcSlotFromId(damagedid);
    if (slot == -1 || !gNpcUsed[slot] || gNpcId[slot] != damagedid)
    {
        // NPC que no  desse include: bloqueia dano aqui (evita BajarVida em NPC e possveis bugs)
        return true;
    }

    if (gNpcState[slot] == NPCS_DEAD) return true;

    // stun + retalia
    new now = GetTickCount();
    SHRP_NpcAI_TryApplyStun(slot);
    gNpcLastDamager[slot] = damagerid;
    if (SHRP_IsCombatEntity(damagerid) && SHRP_IsSameContext(slot, damagerid))
    {
        gNpcTarget[slot] = damagerid;
        if (gNpcState[slot] != NPCS_DEAD) gNpcState[slot] = NPCS_CHASE;
    }

    gNpcHP[slot] -= damage;
    if (gNpcHP[slot] <= 0.0)
    {
        gNpcHP[slot] = 0.0;
        gNpcState[slot] = NPCS_DEAD;

        FCNPC_Stop(damagedid);
        ApplyAnimation(damagedid, "PED", "KO_shot_stom", 4.0, 0, 0, 0, 0, 0);

        // recompensa
        if (SHRP_IsRealPlayer(damagerid))
        {
            if (gNpcXPReward[slot] > 0)
            {
                // Funes existem no seu GM (vi no SHRP.pwn): GivePlayerExperiencia + SubirDLevel
                GivePlayerExperiencia(damagerid, gNpcXPReward[slot]);
                SubirDLevel(damagerid);
            }
            if (gNpcMoneyReward[slot] > 0)
            {
                GivePlayerCash(damagerid, gNpcMoneyReward[slot]);
            }
        }

        // despawn simples
        SetTimerEx("SHRP_Npc_DespawnLater", 2500, false, "i", slot);
    }

    return true;
}

forward SHRP_Npc_DespawnLater(slot);
public SHRP_Npc_DespawnLater(slot)
{
    if (slot < 0 || slot >= MAXIMO_NPCS_COMBATE) return 0;
    if (!gNpcUsed[slot]) return 0;
    if (gNpcState[slot] != NPCS_DEAD) return 0;

    SHRP_NpcDestroy(slot);
    return 1;
}

// -----------------------------
// AI Tick
// -----------------------------
stock SHRP_NpcPickTarget(slot)
{
    new npcid = gNpcId[slot];
    if (npcid == INVALID_PLAYER_ID) return INVALID_PLAYER_ID;

    new Float:nx, Float:ny, Float:nz;
    FCNPC_GetPosition(npcid, nx, ny, nz);

    new best = INVALID_PLAYER_ID;
    new Float:bestd = 999999.0;

    for (new p = 0; p < MAX_PLAYERS; p++)
    {
        if (!SHRP_IsCombatEntity(p)) continue;
        if (p == npcid) continue;
        // clones/guards: nunca atacar o dono
        if (gNpcOwner[slot] != INVALID_PLAYER_ID && p == gNpcOwner[slot]) continue;
        if (GetPlayerVirtualWorld(p) != gNpcVW[slot]) continue;
        if (GetPlayerInterior(p) != gNpcInt[slot]) continue;

        // inimigo simples: se NPC tem vila, ignora jogadores da mesma vila
        if (gNpcVila[slot] > 0)
        {
            // Info[playerid][pMember] existe no seu GM e indica vila/membro
            if (SHRP_GetEntityVila(p) == gNpcVila[slot]) continue;
        }

        new Float:px, Float:py, Float:pz;
        GetPlayerPos(p, px, py, pz);
        new Float:d = SHRP_Dist3D(nx, ny, nz, px, py, pz);

        if (d <= gNpcAggroRange[slot] && d < bestd)
        {
            bestd = d;
            best = p;
        }
    }
    return best;
}

stock SHRP_NpcTryCastJutsu(slot, targetid)
{
    if (gNpcJutsuCmd[slot][0] == EOS) return 0;

    new now = GetTickCount();
    if (now - gNpcLastJutsuTick[slot] < gNpcJutsuCooldownMs[slot]) return 0;

    new fname[40];
    format(fname, sizeof fname, "cmd_%s", gNpcJutsuCmd[slot]);

    if (funcidx(fname) == -1) return 0;

    new params[16];
    params[0] = EOS;
    if (gNpcJutsuNeedsTarget[slot])
    {
        format(params, sizeof params, "%d", targetid);
    }

    CallLocalFunction(fname, "is", gNpcId[slot], params);
    gNpcLastJutsuTick[slot] = now;
    return 1;
}

stock SHRP_NpcDoMelee(slot, targetid)
{
    new npcid = gNpcId[slot];
    if (npcid == INVALID_PLAYER_ID) return 0;
    if (!SHRP_IsCombatEntity(targetid)) return 0;
    // clones/guards: nunca bater no dono
    if (gNpcOwner[slot] != INVALID_PLAYER_ID && targetid == gNpcOwner[slot]) return 0;

    new now = GetTickCount();
    if (now - gNpcLastAttackTick[slot] < gNpcAttackCooldownMs[slot]) return 0; // cooldown
    gNpcLastAttackTick[slot] = now;

    // sequncia 1..4 (pra usar o mesmo hit do sistema de taijutsu)
    gNpcHitSeq[slot] = (gNpcHitSeq[slot] >= 4) ? 1 : (gNpcHitSeq[slot] + 1);
    new hit = gNpcHitSeq[slot];

    // vira pro alvo antes de bater
    SetPlayerToFacePlayer(npcid, targetid);

    // anima o golpe (usa seu sistema do SHRP)
    #if defined TaijutsuMelee
        TaijutsuMelee(npcid, hit);
    #else
        ApplyAnimation(npcid, "FIGHT_B", "FightB_1", 4.1, 0, 0, 0, 0, 0);
    #endif

    // aplica o HIT + dano pelo sistema de taijutsu do SHRP (HitPlayer)
    if (!IsPlayerHittable(targetid)) return 0;
    if (!SHRP_IsRealPlayer(targetid) && !SHRP_NpcAI_IsCombatNPC(targetid)) return 0;
    if (SHRP_IsRealPlayer(targetid) && InvunerableSuirou[targetid]) return 0;

    new bool:protected = (GetPVarInt(targetid, "Defensa") != 0);

    if (GetPVarInt(targetid, "Inconsciente") >= 1)
        HitPlayerInconsciente(npcid, targetid, hit, protected);
    else
        HitPlayer(npcid, targetid, hit, protected);

    return 1;
}


public SHRP_NpcAI_Tick()
{
    new now = GetTickCount();

    for (new slot = 0; slot < MAXIMO_NPCS_COMBATE; slot++)
    {
        if (!gNpcUsed[slot]) continue;

        new npcid = gNpcId[slot];
        if (npcid == INVALID_PLAYER_ID) continue;

        // segurana: se por algum motivo no  NPC, remove
        if (!IsPlayerNPC(npcid))
        {
            SHRP_NpcDestroy(slot);
            continue;
        }

        if (gNpcState[slot] == NPCS_DEAD) continue;
        if (now < gNpcNextThinkTick[slot]) continue;
        gNpcNextThinkTick[slot] = now + 250;

        // Hit-stun: se acabou de tomar dano, nao age neste tick
        if (now < gNpcStunUntilTick[slot])
        {
            FCNPC_Stop(npcid);
            continue;
        }

        // Mantm VW/int (evita desync em algumas setups)
        SetPlayerVirtualWorld(npcid, gNpcVW[slot]);
        SetPlayerInterior(npcid, gNpcInt[slot]);

        // Owner follow
        if (gNpcState[slot] == NPCS_FOLLOW && SHRP_IsRealPlayer(gNpcOwner[slot]))
        {
            new owner = gNpcOwner[slot];

            // se tiver alvo e ele for vlido, vai pra chase
            if (SHRP_IsCombatEntity(gNpcTarget[slot]))
            {
                gNpcState[slot] = NPCS_CHASE;
            }
            else
            {
                // segue dono
                new Float:ox, Float:oy, Float:oz;
                GetPlayerPos(owner, ox, oy, oz);

                new Float:nx, Float:ny, Float:nz;
                FCNPC_GetPosition(npcid, nx, ny, nz);

                new Float:d = SHRP_Dist3D(nx, ny, nz, ox, oy, oz);
                if (d > gNpcFollowDist[slot] + 0.8)
                {
                    FCNPC_GoToPlayer(npcid, owner);
                }
                else
                {
                    FCNPC_Stop(npcid);
                }

                // procura inimigos perto do dono
                new t = SHRP_NpcPickTarget(slot);
                if (t != INVALID_PLAYER_ID) gNpcTarget[slot] = t;
            }
        }

        // Hostile / Patrol: buscar alvo
        if (gNpcType[slot] == NPCT_HOSTILE || gNpcType[slot] == NPCT_PATROL)
        {
            if (!SHRP_IsCombatEntity(gNpcTarget[slot]))
            {
                new t = SHRP_NpcPickTarget(slot);
                gNpcTarget[slot] = t;
                if (t != INVALID_PLAYER_ID) gNpcState[slot] = NPCS_CHASE;
            }
        }

        // Chase / combate
        if (gNpcState[slot] == NPCS_CHASE)
        {
            if (!SHRP_IsCombatEntity(gNpcTarget[slot]))
            {
                gNpcTarget[slot] = INVALID_PLAYER_ID;
                gNpcState[slot] = (gNpcType[slot] == NPCT_PATROL) ? NPCS_PATROL : NPCS_IDLE;
                continue;
            }

            new target = gNpcTarget[slot];

            new Float:nx, Float:ny, Float:nz;
            FCNPC_GetPosition(npcid, nx, ny, nz);

            new Float:tx, Float:ty, Float:tz;
            GetPlayerPos(target, tx, ty, tz);

            new Float:d2 = SHRP_Dist2D(nx, ny, tx, ty);
            new Float:dz = floatabs(nz - tz);

            // perdeu?
            if (d2 > gNpcAggroRange[slot] + 10.0 || dz > 12.0)
            {
                gNpcTarget[slot] = INVALID_PLAYER_ID;
                gNpcState[slot] = (gNpcType[slot] == NPCT_PATROL) ? NPCS_PATROL : NPCS_IDLE;
                FCNPC_Stop(npcid);
                continue;
            }

            // tenta jutsu em distncia mdia (opcional)
            if (d2 > gNpcAttackRange[slot] + 1.0 && d2 < 22.0)
            {
                SHRP_NpcTryCastJutsu(slot, target);
            }

            if (d2 > gNpcAttackRange[slot] || dz > 1.8)
            {
                FCNPC_GoToPlayer(npcid, target);
            }
            else
            {
                FCNPC_Stop(npcid);
                SHRP_NpcDoMelee(slot, target);
            }
        }

        // Patrol roam
        if (gNpcState[slot] == NPCS_PATROL)
        {
            if (SHRP_IsCombatEntity(gNpcTarget[slot]))
            {
                gNpcState[slot] = NPCS_CHASE;
                continue;
            }

            // se no t andando, escolhe um ponto aleatrio perto do home
            if (!FCNPC_IsMoving(npcid))
            {
                new Float:rx = gNpcHome[slot][0] + SHRP_FRandom(-gNpcPatrolRadius[slot], gNpcPatrolRadius[slot]);
                new Float:ry = gNpcHome[slot][1] + SHRP_FRandom(-gNpcPatrolRadius[slot], gNpcPatrolRadius[slot]);
                new Float:rz = gNpcHome[slot][2];

                FCNPC_GoTo(npcid, rx, ry, rz);
            }

            // aggro
            new t = SHRP_NpcPickTarget(slot);
            if (t != INVALID_PLAYER_ID)
            {
                gNpcTarget[slot] = t;
                gNpcState[slot] = NPCS_CHASE;
            }
        }
    }
    return 1;
}

// -----------------------------
// Economia (opcional): patrulha paga pelo Tesouro da Vila
// (Seu eco_core define gEcoTreasury[] e _ECO_CORE_INCLUDED)
// -----------------------------
#if defined _ECO_CORE_INCLUDED
stock bool:SHRP_NpcHirePatrolFromTreasury(playerid, const name[], skin, cost, Float:radius = 25.0)
{
    // valida vila
    new vila = Info[playerid][pMember];
    if (vila <= 0) return false;

    if (gEcoTreasury[vila] < cost) return false;
    gEcoTreasury[vila] -= cost;

    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    new slot = SHRP_NpcCreate(name, skin, NPCT_PATROL, vila, x, y, z, GetPlayerVirtualWorld(playerid), GetPlayerInterior(playerid));
    if (slot == -1) return false;

    SHRP_NpcSetPatrolRadius(slot, radius);
    return true;
}

#endif