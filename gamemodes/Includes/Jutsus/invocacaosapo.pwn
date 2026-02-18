#if defined _SHRP_SAPO_INVOCACAO_INCLUDED
    #endinput
#endif
#define _SHRP_SAPO_INVOCACAO_INCLUDED

#include <a_samp>
#include <streamer>

// ==========================================================
// SHRP - Jutsu: Invocação (Prisão do Sapo Guardião) - Dynamic
// Pawno 0.3.DL friendly (SEM &objid, SEM static stock em função)
//
// Integração:
//  - Chamar: SapoInvocacaoJutsu(playerid);
//  - OnPlayerTakeDamage: SapoInvocacao_OnPlayerTakeDamage(playerid, issuerid, amount, weaponid);
//  - OnPlayerDisconnect: SapoInvocacao_OnPlayerDisconnect(playerid);
//  - OnPlayerDeath: SapoInvocacao_OnPlayerDeath(playerid);
//  - No Dash/Kawarimi: if(SapoInvocacao_IsPrisoned(playerid)) bloquear.
//
// ==========================================================

// ===== CONFIG =====
#define SAPO_COOLDOWN_SEC        (0)         // você quer 0 pra testar
#define SAPO_TIMING_MS           (5000)    // seu timing
#define SAPO_CAST_MS             (0)      // cast 1s

#define SAPO_COST_CHAKRA         (5000.0)

#define SAPO_TARGET_RANGE        (18.0)      // alcance do cone
#define SAPO_CONE_ANGLE_DEG      (35.0)      // cone frontal

#define SAPO_WALL_OFFSET         (5.0)       // paredes em +/-5.0
#define SAPO_HALF_INNER          (4.4)       // anti-escape antes da parede

#define SAPO_SLOW_MAX_HVEL       (0.16)      // clamp velocidade horizontal
#define SAPO_HP_BASE             (200.0)     // HP da prisão
#define SAPO_DMG_SCALE           (1.00)      // dano no preso -> dano na prisão

#define SAPO_TAI_DIV             (5000.0)    // taijutsu/div = % redução
#define SAPO_TAI_CAP             (0.40)      // cap 40%
#define SAPO_MIN_DUR_MS          (2500)

// ===== DATA =====
enum dataSapoInvocacao
{
    sapoAtivo,
    sapoCasting,
    sapoCooldownUntil,     // gettime()

    sapoVictim,            // playerid preso (pode ser NPC FCNPC)
    sapoTimerEnd,          // timer fim
    sapoTimerCtrl,         // timer controle (slow/anti-escape)

    Float:sapoCX,
    Float:sapoCY,
    Float:sapoCZ,
    Float:sapoHP,

    sapoObj,               // sapo topo
    sapoObjs[9]            // paredes/tetos/chao
}
new SapoInvocacao[MAX_PLAYERS][dataSapoInvocacao];

// ===== FORWARDS =====
forward SapoInvocacao_CastFinish(playerid);
forward SapoInvocacao_ControlTick(playerid);
forward SapoInvocacao_TimerEnd(playerid);
forward SapoInvocacao_DestroyFx(objid);

// ==========================================================
// FLAG "SapoPrisao" (pra você bloquear dash/kawarimi)
// ==========================================================
stock SapoInvocacao_IsPrisoned(playerid)
{
    return (GetPVarInt(playerid, "SapoPrisao") == 1);
}
stock SapoInvocacao_SetFlag(playerid, enable)
{
    if(enable) SetPVarInt(playerid, "SapoPrisao", 1);
    else DeletePVar(playerid, "SapoPrisao");
    return 1;
}

// ==========================================================
// Utils
// ==========================================================
stock Float:SapoAbs(Float:v)
{
    return (v < 0.0) ? -v : v;
}

// destrói e retorna 0 pra você zerar a variável
stock SapoDestroyDyn(objid)
{
    if(objid != 0) DestroyDynamicObject(objid);
    return 0;
}

// alvo por mira ou cone frontal
stock Sapo_GetTarget(playerid)
{
    // 1) mira/arma
    new t = GetPlayerTargetPlayer(playerid);
    if(t != INVALID_PLAYER_ID && IsPlayerConnected(t))
        return t;

    // 2) cone frontal
    new Float:cx, Float:cy, Float:cz, Float:fa;
    GetPlayerPos(playerid, cx, cy, cz);
    GetPlayerFacingAngle(playerid, fa);

    new best = INVALID_PLAYER_ID;
    new Float:bestDist2 = 999999.0;

    for(new i=0; i<MAX_PLAYERS; i++)
    {
        if(!IsPlayerConnected(i) || i == playerid) continue;

        new Float:x, Float:y, Float:z;
        GetPlayerPos(i, x, y, z);

        new Float:dx = x - cx;
        new Float:dy = y - cy;
        new Float:dist2 = dx*dx + dy*dy;

        if(dist2 > (SAPO_TARGET_RANGE * SAPO_TARGET_RANGE)) continue;

        new Float:ang = atan2(dy, dx) * 57.2957795; // deg
        new Float:diff = SapoAbs(ang - fa);
        if(diff > 180.0) diff = 360.0 - diff;

        if(diff <= SAPO_CONE_ANGLE_DEG)
        {
            if(dist2 < bestDist2)
            {
                bestDist2 = dist2;
                best = i;
            }
        }
    }
    return best;
}

// ==========================================================
// FUNÇÃO PRINCIPAL (você vai chamar pela hotbar/selos depois)
// ==========================================================
stock SapoInvocacaoJutsu(playerid)
{
    // se já estiver ativo -> desativa
    if(SapoInvocacao[playerid][sapoAtivo])
    {
        SapoInvocacao_Disable(playerid);
        return 1;
    }

	//Do jeito que está, se o player tiver pProgressoHP >= 10000, o jutsu não roda
    //if(Info[playerid][pProgressoHP] >= 10000) return 0;

    // chakra
    if(Info[playerid][pChakraEnUso] < SAPO_COST_CHAKRA)
        return SemChakra(playerid);

    // cooldown
    if(SapoInvocacao[playerid][sapoCooldownUntil] > gettime())
        return JutsuNotReady2(playerid, COLOR_WHITE,
            "Jutsu de Invocação: Prisão Do Sapo Guardião!",
            SapoInvocacao[playerid][sapoCooldownUntil]);

    // no chão (tolerância)
    new Float:vx, Float:vy, Float:vz;
    GetPlayerVelocity(playerid, vx, vy, vz);
    if(SapoAbs(vz) > 0.02)
        return SendClientMessageEx(playerid, COLOR_WHITE,
            "{EF0D02}(JUTSU) Você precisa estar no chão para usar este jutsu.");

    // gasta chakra
    Info[playerid][pChakraEnUso] -= SAPO_COST_CHAKRA;

    // limpa selos + anim
    ClearSelo(playerid);
    ApplyAnimation(playerid, "selos", "Doton1_1", 2.0, 0, 0, 0, 0, 0, 1);

    // fala + som (usa as tuas funções existentes)
    //SapoInvocacaoSay(playerid);

    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    for(new i=0; i<MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && IsPlayerInRangeOfPoint(i, 50.0, px, py, pz))
            AudioInPlayer(i, 200.0, 72);
    }

    // registra cooldown
    SapoInvocacao[playerid][sapoCooldownUntil] = gettime() + SAPO_COOLDOWN_SEC;

    // SEM CAST: cria na hora
    SapoInvocacao_CastFinish(playerid);
    return 1;

}

// ==========================================================
// FIM DO CAST -> cria prisão no alvo ou na frente
// ==========================================================
public SapoInvocacao_CastFinish(playerid)
{
    if(!IsPlayerConnected(playerid)) return 0;

    // SEM CAST: não usa sapoCasting
    SapoInvocacao[playerid][sapoCasting] = 0;


    new target = Sapo_GetTarget(playerid);

    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerFacingAngle(playerid, a);
    GetPlayerPos(playerid, x, y, z);

    if(target != INVALID_PLAYER_ID)
    {
        GetPlayerPos(target, x, y, z);
        SapoInvocacao[playerid][sapoVictim] = target;
    }
    else
    {
        GetXYInFrontOfPlayer(playerid, x, y, 9.0);
        SapoInvocacao[playerid][sapoVictim] = INVALID_PLAYER_ID;
    }

    // centro
    SapoInvocacao[playerid][sapoCX] = x;
    SapoInvocacao[playerid][sapoCY] = y;
    SapoInvocacao[playerid][sapoCZ] = z;

    // HP da prisão
    SapoInvocacao[playerid][sapoHP] = SAPO_HP_BASE;

    // ========= OBJETOS / ALTURAS =========
    // paredes:   z
    // teto:      z+3.0
    // sapo topo: z+3.0
    // chão:      z-3.0
    // =====================================

    // sapo topo
    SapoInvocacao[playerid][sapoObj] = CreateDynamicObject(18637, x, y, z+3.0, 0.0, 0.0, a);

    // paredes
    SapoInvocacao[playerid][sapoObjs][0] = CreateDynamicObject(12044, x+SAPO_WALL_OFFSET, y, z, 0.0, 0.0,  90.0);
    SapoInvocacao[playerid][sapoObjs][1] = CreateDynamicObject(12044, x-SAPO_WALL_OFFSET, y, z, 0.0, 0.0, 270.0);
    SapoInvocacao[playerid][sapoObjs][2] = CreateDynamicObject(12044, x, y+SAPO_WALL_OFFSET, z, 0.0, 0.0,   0.0);
    SapoInvocacao[playerid][sapoObjs][3] = CreateDynamicObject(12044, x, y-SAPO_WALL_OFFSET, z, 0.0, 0.0, 180.0);

    // teto/peças
    SapoInvocacao[playerid][sapoObjs][4] = CreateDynamicObject(12044, x, y, z+3.0, 90.0, 0.0, 0.0);
    SapoInvocacao[playerid][sapoObjs][5] = CreateDynamicObject(12044, x, y+3.0, z+3.0, 90.0, 0.0, 0.0);
    SapoInvocacao[playerid][sapoObjs][6] = CreateDynamicObject(12044, x, y-3.0, z+3.0, 90.0, 0.0, 0.0);

    // chão (nota: índice 7 não usado, igual no teu original)
    SapoInvocacao[playerid][sapoObjs][8] = CreateDynamicObject(12044, x, y, z-3.0, 90.0, 0.0, 0.0);

    // fumaça
    new fx = CreateDynamicObject(18682, x, y, z-5.5, 0.0, 0.0, 0.0);
    SetTimerEx("SapoInvocacao_DestroyFx", 5000, false, "i", fx);

    // ativo
    SapoInvocacao[playerid][sapoAtivo] = 1;

    // duração reduzida por taijutsu do alvo
    new dur = SAPO_TIMING_MS;
    if(SapoInvocacao[playerid][sapoVictim] != INVALID_PLAYER_ID)
    {
        new v = SapoInvocacao[playerid][sapoVictim];

        new Float:reduce = float(Info[v][pTaijutsu]) / SAPO_TAI_DIV;
        if(reduce > SAPO_TAI_CAP) reduce = SAPO_TAI_CAP;

        dur = floatround(float(SAPO_TIMING_MS) * (1.0 - reduce));
        if(dur < SAPO_MIN_DUR_MS) dur = SAPO_MIN_DUR_MS;

        // aplica flag no preso
        SapoInvocacao_SetFlag(v, 1);

        // timer controle (slow + anti-escape)
        SapoInvocacao[playerid][sapoTimerCtrl] = SetTimerEx("SapoInvocacao_ControlTick", 200, true, "i", playerid);
    }

    // timer fim
    SapoInvocacao[playerid][sapoTimerEnd] = SetTimerEx("SapoInvocacao_TimerEnd", dur, false, "i", playerid);
    return 1;
}

public SapoInvocacao_DestroyFx(objid)
{
    if(objid != 0) DestroyDynamicObject(objid);
    return 1;
}

// ==========================================================
// CONTROLE: slow + anti-escape
// ==========================================================
public SapoInvocacao_ControlTick(playerid)
{
    if(!IsPlayerConnected(playerid)) return 0;
    if(!SapoInvocacao[playerid][sapoAtivo]) return 0;

    new v = SapoInvocacao[playerid][sapoVictim];
    if(v == INVALID_PLAYER_ID || !IsPlayerConnected(v)) return 0;

    new Float:cx = SapoInvocacao[playerid][sapoCX];
    new Float:cy = SapoInvocacao[playerid][sapoCY];
    new Float:cz = SapoInvocacao[playerid][sapoCZ];

    new Float:x, Float:y, Float:z;
    GetPlayerPos(v, x, y, z);

    // anti-escape: se sair do quadrado interno, puxa pro centro
    if(SapoAbs(x - cx) > SAPO_HALF_INNER || SapoAbs(y - cy) > SAPO_HALF_INNER)
        SetPlayerPos(v, cx, cy, cz + 0.8);

    // slow: clamp da velocidade horizontal
    new Float:vx, Float:vy, Float:vz;
    GetPlayerVelocity(v, vx, vy, vz);

    new Float:hv = floatsqroot(vx*vx + vy*vy);
    if(hv > SAPO_SLOW_MAX_HVEL)
    {
        new Float:scale = SAPO_SLOW_MAX_HVEL / hv;
        SetPlayerVelocity(v, vx*scale, vy*scale, vz);
    }
    return 1;
}

// ==========================================================
// FIM (timer) / desativar
// ==========================================================
public SapoInvocacao_TimerEnd(playerid)
{
    SapoInvocacao_Disable(playerid);
    return 1;
}

stock SapoInvocacao_Disable(playerid)
{
    if(!SapoInvocacao[playerid][sapoAtivo]) return 0;

    // mata timers
    if(SapoInvocacao[playerid][sapoTimerEnd])  { KillTimer(SapoInvocacao[playerid][sapoTimerEnd]);  SapoInvocacao[playerid][sapoTimerEnd]  = 0; }
    if(SapoInvocacao[playerid][sapoTimerCtrl]) { KillTimer(SapoInvocacao[playerid][sapoTimerCtrl]); SapoInvocacao[playerid][sapoTimerCtrl] = 0; }

    // solta vítima
    new v = SapoInvocacao[playerid][sapoVictim];
    if(v != INVALID_PLAYER_ID && IsPlayerConnected(v))
        SapoInvocacao_SetFlag(v, 0);
    SapoInvocacao[playerid][sapoVictim] = INVALID_PLAYER_ID;

    // destrói objs (zerando handles)
    SapoInvocacao[playerid][sapoObj] = SapoDestroyDyn(SapoInvocacao[playerid][sapoObj]);

    for(new i=0; i<9; i++)
        SapoInvocacao[playerid][sapoObjs][i] = SapoDestroyDyn(SapoInvocacao[playerid][sapoObjs][i]);

    SapoInvocacao[playerid][sapoAtivo] = 0;

    // fumaça ao sumir
    new Float:x = SapoInvocacao[playerid][sapoCX];
    new Float:y = SapoInvocacao[playerid][sapoCY];
    new Float:z = SapoInvocacao[playerid][sapoCZ];

    new fx = CreateDynamicObject(18682, x, y, z-5.5, 0.0, 0.0, 0.0);
    SetTimerEx("SapoInvocacao_DestroyFx", 5000, false, "i", fx);

    return 1;
}

// ==========================================================
// HOOKS (você chama do SHRP)
// ==========================================================

// cast cancelável + HP da prisão
stock SapoInvocacao_OnPlayerTakeDamage(playerid, issuerid, Float:amount, weaponid)
{
    // A) cancelou cast do próprio caster
    if(SapoInvocacao[playerid][sapoCasting])
    {
        SapoInvocacao[playerid][sapoCasting] = 0;
        SendClientMessageEx(playerid, COLOR_WHITE, "{EF0D02}(JUTSU) Você foi interrompido e cancelou a invocação!");
        return 1;
    }

    // B) se o player está preso, dano nele reduz HP da prisão
    if(SapoInvocacao_IsPrisoned(playerid))
    {
        for(new c=0; c<MAX_PLAYERS; c++)
        {
            if(!IsPlayerConnected(c)) continue;
            if(!SapoInvocacao[c][sapoAtivo]) continue;
            if(SapoInvocacao[c][sapoVictim] != playerid) continue;

            SapoInvocacao[c][sapoHP] -= (amount * SAPO_DMG_SCALE);

            if(SapoInvocacao[c][sapoHP] <= 0.0)
                SapoInvocacao_Disable(c);

            break;
        }
    }
    return 1;
}

stock SapoInvocacao_OnPlayerDisconnect(playerid)
{
    // se ele é caster
    if(SapoInvocacao[playerid][sapoAtivo])
        SapoInvocacao_Disable(playerid);

    // se ele era vítima
    for(new c=0; c<MAX_PLAYERS; c++)
    {
        if(!IsPlayerConnected(c)) continue;
        if(!SapoInvocacao[c][sapoAtivo]) continue;
        if(SapoInvocacao[c][sapoVictim] == playerid)
        {
            SapoInvocacao_Disable(c);
            break;
        }
    }
    return 1;
}

stock SapoInvocacao_OnPlayerDeath(playerid)
{
    return SapoInvocacao_OnPlayerDisconnect(playerid);
}

CMD:sapo(playerid, params[])
{
    return SapoInvocacaoJutsu(playerid);
}

// CMD genérico: /animtest <LIB> <ANIM>
// Ex: /animtest BASE01 Mokuton01
// Ex: /animtest PED WALK_PLAYER

CMD:animtest(playerid, params[])
{
    new lib[32], anim[32];

    if(sscanf(params, "s[32]s[32]", lib, anim))
    {
        SendClientMessage(playerid, -1, "{FF4444}Uso: {FFFFFF}/animtest <LIB> <ANIM>");
        SendClientMessage(playerid, -1, "{AAAAAA}Ex: /animtest BASE01 Mokuton01");
        return 1;
    }

    // Aplica a animação (mesmos parâmetros do seu exemplo)
    ApplyAnimation(playerid, lib, anim, 2.0, 0, 0, 0, 0, 0, 1);

    new msg[128];
    format(msg, sizeof msg, "{5FDE35}[ANIM-TEST]{FFFFFF} ApplyAnimation: %s / %s", lib, anim);
    SendClientMessage(playerid, -1, msg);

    return 1;
}
