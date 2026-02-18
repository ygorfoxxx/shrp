#if defined _NNRP_DASH_
    #endinput
#endif
#define _NNRP_DASH_

#if !defined QUEBRACOMBO_COOLDOWN
    #define QUEBRACOMBO_COOLDOWN 40
#endif

// ==========================================================
//  NNRP - Sistema de Dash (extra?do do gamemode)
//  Arquivo: dash.pwn (ANSI)
// ==========================================================

// ==========================================================
// [NEW] AJUSTE FINO - "AR FINAL LAUNCH" (empurrao extra NO ULTIMO HIT do combo no ar)
// - AIR_FINAL_USE_HIT_LIMIT: 1 = usa o limite real de hits (GetAirComboHitLimit/TaijutsuAirHit) | 0 = usa AIR_FINAL_TICK (legado)
// - AIR_FINAL_TICK: qual "tick" do KnockUP conta como "final" (somente se AIR_FINAL_USE_HIT_LIMIT=0)
// - AIR_FINAL_LAUNCH_IMPULSE: for?a extra em XY (0.30 ~ 0.55 recomendado)
// - AIR_FINAL_LAUNCH_USE_CAMERA: 1 = alinha a dire??o ao ?ngulo da c?mera (mais intuitivo)
// ==========================================================
#if !defined true
    #define true (1)
#endif
#if !defined false
    #define false (0)
#endif

#if !defined AIR_FINAL_USE_HIT_LIMIT
    #define AIR_FINAL_USE_HIT_LIMIT      (1)
#endif

#if !defined AIR_FINAL_TICK
    #define AIR_FINAL_TICK               (18)
#endif

#if !defined AIR_FINAL_LAUNCH_IMPULSE
    #define AIR_FINAL_LAUNCH_IMPULSE     (0.45)
#endif

#if !defined AIR_FINAL_LAUNCH_USE_CAMERA
    #define AIR_FINAL_LAUNCH_USE_CAMERA  (1)
#endif

// [NEW] Flag pra garantir que o empurr?o final acontece s? 1x por combo (por atacante)
new AirComboFinalLaunchDone[MAX_PLAYERS];
// [NEW] Cache do limite real de hits no ar (definido no start do air combo)
new AirComboHitLimitCache[MAX_PLAYERS];

// [FIX] Cache das teclas anteriores para detectar \"apertou F agora\" com segurança
new DashLastKeysCache[MAX_PLAYERS];


// [NEW] Aplica um impulso extra na v?tima, na dire??o do atacante (control?vel pelo atacante)
// - Preserva Z atual da v?tima (n?o muda altura)
// - Soma o impulso no XY atual (n?o sobrescreve totalmente o movimento)
stock AirCombo_ApplyFinalLaunch(playerid, targetid)
{
    if(targetid == INVALID_PLAYER_ID) return 0;
    if(!IsPlayerConnected(playerid) || !IsPlayerConnected(targetid)) return 0;

    // Dire??o control?vel:
    // se AIR_FINAL_LAUNCH_USE_CAMERA=1, alinhar o ?ngulo do player ? c?mera
    #if AIR_FINAL_LAUNCH_USE_CAMERA
        SetPlayerFacingAngleToCamera(playerid);
    #endif

    new Float:a;
    GetPlayerFacingAngle(playerid, a);

    // Vetor "pra frente" do atacante
    new Float:dx = floatsin(-a, degrees);
    new Float:dy = floatcos(-a, degrees);

    // Pega a velocidade atual da v?tima e soma o impulso no XY
    new Float:cvx, Float:cvy, Float:cvz;
    GetPlayerVelocity(targetid, cvx, cvy, cvz);

    new Float:nvx = cvx + (dx * AIR_FINAL_LAUNCH_IMPULSE);
    new Float:nvy = cvy + (dy * AIR_FINAL_LAUNCH_IMPULSE);

    // (Opcional) clamp simples pra n?o virar "chute forte"
    // Mant?m o empurr?o pequeno e previs?vel
    new Float:s = floatsqroot(nvx*nvx + nvy*nvy);
    if(s > 2.0)
    {
        nvx = (nvx / s) * 2.0;
        nvy = (nvy / s) * 2.0;
    }

    SetPlayerVelocity(targetid, nvx, nvy, cvz);
    return 1;
}


// ==========================================================
// [NEW] RAPIDDASH - CORRECAO DISTANCIA CURTA (nao atravessar)
// - RAPIDDASH_CLOSE_STOP_DIST: dentro dessa distancia, forca encaixe/hit sem depender do ray GetShootedJutsu
// ==========================================================
#if !defined RAPIDDASH_CLOSE_STOP_DIST
    #define RAPIDDASH_CLOSE_STOP_DIST (2.40)
#endif

// ==========================================================
// [FIX] RAPIDDASH SNAP (nao terminar atras do alvo)
// - RAPIDDASH_SNAP_DIST: distancia (metros) para "encaixar" antes do alvo (0.9 ~ 1.4 recomendado)
// - RAPIDDASH_SNAP_Z: ajuste leve no Z para evitar prender no chao (0.0 ~ 0.3)
// ==========================================================
#if !defined RAPIDDASH_SNAP_DIST
    #define RAPIDDASH_SNAP_DIST   (1.05)
#endif
#if !defined RAPIDDASH_SNAP_Z
    #define RAPIDDASH_SNAP_Z      (0.12)
#endif

stock RapidDash_SnapToTarget(playerid, targetid)
{
    if(targetid == INVALID_PLAYER_ID) return 0;
    if(!IsPlayerConnected(playerid) || !IsPlayerConnected(targetid)) return 0;

    new Float:ax, Float:ay, Float:az;
    new Float:tx, Float:ty, Float:tz;
    GetPlayerPos(playerid, ax, ay, az);
    GetPlayerPos(targetid, tx, ty, tz);

    new Float:dx = tx - ax;
    new Float:dy = ty - ay;
    new Float:len = floatsqroot(dx*dx + dy*dy);

    if(len < 0.001)
    {
        // fallback: usa o angulo do alvo
        new Float:a;
        GetPlayerFacingAngle(targetid, a);
        dx = floatsin(-a, degrees);
        dy = floatcos(-a, degrees);
        len = 1.0;
    }
    else
    {
        dx /= len;
        dy /= len;
    }

    // posiciona o atacante ENTRE ele e o alvo (sem atravessar)
    new Float:nx = tx - (dx * RAPIDDASH_SNAP_DIST);
    new Float:ny = ty - (dy * RAPIDDASH_SNAP_DIST);
    new Float:nz = tz + RAPIDDASH_SNAP_Z;

    // trava o movimento do dash e encaixa
    SetPlayerVelocity(playerid, 0.0, 0.0, 0.0);
    SetPlayerPos(playerid, nx, ny, nz);

    // faz o atacante olhar pro alvo (angulo calculado pelo vetor)
    SetPlayerFacingAngle(playerid, atan2(ty - ny, tx - nx) - 90.0);

    return 1;
}


// Tick de cooldown do dash (substitui o bloco do TimerDashC no OnPlayerUpdate)
Dash_OnPlayerUpdate(playerid)
{
    if(TimerDashC[playerid] && gettime() >= TimerDashC[playerid]){ // RapidDash
        TimerDashC[playerid] = 0;
        SendClientMessage(playerid, -1, "{5FDE35}(JUTSU){FFFFFF} Seu dash pra frente j? pode ser usada novamente.");
    }
    return 1;
}

// --- Timers auxiliares do RapidDash ---
function DashFrenteUse(playerid)
{
    KillTimer(TimingDashFrente[playerid]);
    //SendClientMessage(playerid, -1, "{5FDE35}(JUTSU){FFFFFF} Seu dash pra frente j? pode ser usada novamente.");
    DashFrenteNoUse[playerid] = 0;
    return 1;
}
function ResetDashF(playerid)
{
    DashFrente[playerid] = 0;
    DashUsado[playerid] = 0;
    SeguindoPlayer[playerid] = 0;
    TargetSeguindoDash[playerid] = 0;
    TargetSeguir[playerid] = -5;
    ApplyAnimation(playerid, "ped", "Jump_Front_L", 4.0, 0, 1, 1, 0, 1, 1);
    return 1;
}

// --- Helper de velocidade do dash frontal (mantido como estava) ---
stock DashFSpeed(playerid, Float:speed)
{
    static Float:a, Float:x, Float:y;
    a = x = y = 0.0;

    GetPlayerFacingAngle(playerid, a);
    x += (speed * floatsin(-a, degrees));
    y += (speed * floatcos(-a, degrees));
    return SetPlayerVelocity(playerid, x, y, 1.1);
}

// --- Dash principal (bloco original do gamemode) ---
//Dash's
PlayerDash(playerid, newkeys)
{
    new keys, ud, lr;
    GetPlayerKeys(playerid, keys, ud, lr);

    // Bloqueios básicos
    if(Info[playerid][pEnergiaEmUso] <= 4.0) return 0;
    if(ChuteForteAtivou[playerid] == 1) return 0;
    if(PlayerRaijinVoador[playerid][raijinUsado] == 1 || PlayerRaijinVoador[playerid][raijinAtingido] == 1) return 0;
    if(Info[playerid][pNinjaQuebrado] == 1 || Info[playerid][pNinjaQuebrado] == 3 || UsandoKit[playerid] == 1) return 0;
    if(IryouUse[playerid] == 1){ApplyAnimation(playerid, "Shinobi_Anim", "Cura_1", 4.0, 0, 0, 0, 1, 5000, 1); return 1;}
    if(DashUsado[playerid] == 1 || DashFHitted[playerid] || TaijutsuVar[playerid][taiHitted] || RasenganAt[playerid]) return 0;
    if(DashCount[playerid] >= 2) return 0;

    // Lógica Anti-Fly: Verificar se está no ar ou em cooldown de animação
    new animlib[32], animname[32];
    GetAnimationName(GetPlayerAnimationIndex(playerid), animlib, 32, animname, 32);
    
    // Se estiver em uma animação de queda ou pulo (ar), bloqueia o dash de chão (casos 4, 5, 6)
    // Nota: IsPlayerInAir costuma ser setado no seu sistema de pulo ninja
    if(IsPlayerInAir[playerid] == 1 || !strcmp(animname, "fall_fall", true) || !strcmp(animname, "Jump_Launch_R", true)) return 0;

    if(!VariaveisDash(playerid)) return 0;

    if((keys & KEY_SECONDARY_ATTACK) && (keys & KEY_SPRINT) && ud == KEY_UP) { RapidDash(playerid); return 1; }
    if(HitPlayerCount[playerid] >= 3 && (keys & KEY_SECONDARY_ATTACK) && ud == KEY_UP) { AirComboDash(playerid); return 1; }

    if((keys & KEY_SECONDARY_ATTACK) && (keys & KEY_SPRINT))
    {
        if(lr == KEY_LEFT) // F + SHIFT + A
        {
            PlayerDashEx(playerid, 4);
            DashUsado[playerid] = 1;
            Invunerable[playerid] = 1;
            DashCount[playerid]++;
            SetXPlayerVelocity(playerid, -0.5);
            EstaminaDash(playerid);
            TimerDash[playerid] = SetTimerEx("ResetTimingDash", 250, false, "d", playerid); // Tempo aumentado para evitar flood
            LimiteDash[playerid] = 1;
            return 1;
        }
        else if(lr == KEY_RIGHT) // F + SHIFT + D
        {
            PlayerDashEx(playerid, 5);
            DashUsado[playerid] = 1;
            Invunerable[playerid] = 1;
            DashCount[playerid]++;
            SetXPlayerVelocity(playerid, 0.5);
            EstaminaDash(playerid);
            TimerDash[playerid] = SetTimerEx("ResetTimingDash", 250, false, "d", playerid);
            LimiteDash[playerid] = 1;
            return 1;
        }
        else if(ud == KEY_DOWN) // F + SHIFT + S
        {
            PlayerDashEx(playerid, 6);
            DashUsado[playerid] = 1;
            Invunerable[playerid] = 1;
            DashCount[playerid]++;
            SetXYPlayerVelocity2(playerid, -0.5);
            EstaminaDash(playerid);
            TimerDash[playerid] = SetTimerEx("ResetTimingDash", 250, false, "d", playerid);
            LimiteDash[playerid] = 1;
            return 1;
        }
    }
    else if(keys & KEY_SECONDARY_ATTACK)
    {
        if(lr == KEY_LEFT) // F + A
        {
            SetPlayerFacingAngleToCamera(playerid);
            PlayerDashEx(playerid, 1);
            DashUsado[playerid] = 1;
            Invunerable[playerid] = 1;
            DashChao[playerid] = 1;
            EstaminaDash(playerid);
            TimerDash[playerid] = SetTimerEx("ResetTimingDash", 100, false, "d", playerid);
            return 1;
        }
        else if(lr == KEY_RIGHT) // F + D
        {
            SetPlayerFacingAngleToCamera(playerid);
            PlayerDashEx(playerid, 2);
            DashUsado[playerid] = 1;
            Invunerable[playerid] = 1;
            DashChao[playerid] = 2;
            EstaminaDash(playerid);
            TimerDash[playerid] = SetTimerEx("ResetTimingDash", 100, false, "d", playerid);
            return 1;
        }
        else if(ud == KEY_DOWN) // F + S
        {
            SetPlayerFacingAngleToCamera(playerid);
            PlayerDashEx(playerid, 3);
            DashUsado[playerid] = 1;
            Invunerable[playerid] = 1;
            DashChao[playerid] = 3;
            EstaminaDash(playerid);
            TimerDash[playerid] = SetTimerEx("ResetTimingDash", 100, false, "d", playerid);
            return 1;
        }
    }
    return 1;
}


function EstaminaDash(playerid)
{
    Info[playerid][pEnergiaEmUso] -= 3.0;
    return 1;
}

function VariaveisDash(playerid)
{
    if(LimiteDash[playerid] == 1) return 0;
    if(ByakuganON[playerid] == 1 || DaikodanHitAlvo[playerid] == 1) return 0;
    if(Info[playerid][pDentroDeCasa] == 1 || HittedKageshibari[playerid] == 1) return 0;
    if(HittedDoroji[playerid] == 1 || HakkeshouON[playerid] == 1 || Meditando[playerid] == 1) return 0;
    if(lastHitted[playerid][hitReason] > 1 || lastJutsu[playerid][jutsuLast] >= 1) return 0;
    if(StackChakra[playerid] == 1 || GetPVarInt(playerid, "Inconsciente") >= 1) return 0;
    if(KagutsuchiON[playerid] == 1 || IkazuchiHitAlvo[playerid] == 1 || SeladoS[playerid] == 1) return 0;
    if(ChidoriON[playerid] == 1 || SuirouON[playerid] == 1 || PlayerParalisado[playerid] == 1) return 0;
    if(SetPlayerState[playerid] == 1 || ChuteCimaHitted[playerid] == 1 || SuirouHIT[playerid] == 1) return 0;
    if(TsutenHittedAlvo[playerid] == 1 || KatonHIT[playerid] == 1 || Pescando[playerid] == 1) return 0;
    return 1;
}

PlayerDashEx(playerid, dash)
{
    switch(dash)
    {
        case 1: {ApplyAnimation(playerid, "Shinobi_Anim", "JumpL", 5.5, 0, 1, 1, 0, 0, 1); AudioInPlayer(playerid, 20.0, 1);}
        case 2: {ApplyAnimation(playerid, "Shinobi_Anim", "JumpR", 5.5, 0, 1, 1, 0, 0, 1); AudioInPlayer(playerid, 20.0, 1);}
        case 3: {ApplyAnimation(playerid, "Shinobi_Anim", "JumpB", 5.5, 0, 1, 1, 0, 0, 1); AudioInPlayer(playerid, 20.0, 1);}
        case 4: {ApplyAnimation(playerid, "ped", "Jump_Left", 5.5, 0, 1, 1, 0, 0, 1); AudioInPlayer(playerid, 20.0, 1);}
        case 5: {ApplyAnimation(playerid, "ped", "Jump_Right", 5.5, 0, 1, 1, 0, 0, 1); AudioInPlayer(playerid, 20.0, 1);}
        case 6: {ApplyAnimation(playerid, "ped", "Jump_Back", 5.5, 0, 1, 1, 0, 0, 1); AudioInPlayer(playerid, 20.0, 1);}
    }
    DashAtivado[playerid] = 0; 
    return 1;
}

function ResetTimingDash(playerid)
{
    if(DashUsado[playerid] == 0 && LimiteDash[playerid] == 0) return 0;
    KillTimer(TimerDash[playerid]);
    Invunerable[playerid] = 0;
    DashUsado[playerid] = 0;
    DashChao[playerid] = 0;
    LimiteDash[playerid] = 0; // CORREÇÃO: Resetando o limite para poder usar de novo sem precisar pular
    DashCount[playerid] = 0;  // Resetando o contador de dashes seguidos
    return 1;
}

// ===============================================
// RapidDash AIR FIX
// - Aumenta toler?ncia Z do GetLookingTarget quando estiver no ar
// - No ar: aplica impulso XY preservando o Z atual (n?o muda altura)
// ===============================================

#if !defined DASH_LOOK_Z_GROUND
    #define DASH_LOOK_Z_GROUND   (6.0)
#endif

#if !defined DASH_LOOK_Z_AIR
    #define DASH_LOOK_Z_AIR      (10.0) // s? no ar; evita falhar por diferen?a de altura
#endif

new DashTargetID[MAX_PLAYERS];
new DashLastAirTick[MAX_PLAYERS];

stock IsPlayerAirborne_RapidDash(playerid)
{
    // Heurística simples e estável:
    // - Se vz != 0 recentemente, consideramos no ar
    new Float:vx, Float:vy, Float:vz;
    GetPlayerVelocity(playerid, vx, vy, vz);

    new now = GetTickCount();
    if (floatabs(vz) > 0.02)
    {
        DashLastAirTick[playerid] = now;
        return 1;
    }

    // cobre o "ápice do pulo" (vz ~ 0 por um instante)
    return ((now - DashLastAirTick[playerid]) < 250);
}


stock DashImpulseXY_ToTarget(playerid, targetid, Float:speed)
{
    new Float:px, Float:py, Float:pz;
    new Float:tx, Float:ty, Float:tz;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerPos(targetid, tx, ty, tz);

    new Float:dx = tx - px;
    new Float:dy = ty - py;
    new Float:dist = floatsqroot(dx*dx + dy*dy);
    if (dist < 0.001) return 0;

    dx /= dist;
    dy /= dist;

    // Preserva o Z atual (n?o altera "altura")
    new Float:cvx, Float:cvy, Float:cvz;
    GetPlayerVelocity(playerid, cvx, cvy, cvz);

    SetPlayerVelocity(playerid, dx * speed, dy * speed, cvz);
    return 1;
}

// (Opcional mas recomendado) inicialize no OnPlayerConnect:
stock RapidDash_InitPlayer(playerid)
{
    DashTargetID[playerid] = INVALID_PLAYER_ID;
    DashLastAirTick[playerid] = 0;
    return 1;
}

RapidDash(playerid)
{
    if(DaikodanHitAlvo[playerid] == 1 || Info[playerid][pDentroDeCasa] == 1 || HittedDoroji[playerid] == 1 || HittedKageshibari[playerid] == 1 || lastHitted[playerid][hitReason] > 1 || ByakuganON[playerid] == 1 || TsutenHittedAlvo[playerid] == 1 || Pescando[playerid] == 1) return 0;
    if(GetPVarInt(playerid, "Inconsciente") >= 1 || KagutsuchiON[playerid] == 1 || IkazuchiHitAlvo[playerid] == 1 || SeladoS[playerid] == 1 || ChidoriON[playerid] == 2 || SuirouON[playerid] == 1 || PlayerParalisado[playerid] == 1 || SetPlayerState[playerid] == 1 || ChuteCimaHitted[playerid] == 1 || SuirouHIT[playerid] == 1 || KatonHIT[playerid] == 1) return 0;
    if(TimerDashC[playerid] > gettime()) return 0;

    if(DashFrenteNoUse[playerid] == 0)
    {
        new vw = GetPlayerVirtualWorld(playerid);

        // ? FIX: toler?ncia Z maior quando estiver no ar
        new bool:inAir = IsPlayerAirborne_RapidDash(playerid);
        new Float:zRange = (inAir ? DASH_LOOK_Z_AIR : DASH_LOOK_Z_GROUND);

        for(new i; i<MAX_PLAYERS; i++)
        {
            switch(GetLookingTarget(80.0, zRange, Invunerable[i] == 1, false, vw, playerid, i))
            {
                case NONE:
                {
                    if(i != MAX_PLAYERS-1) continue;
                    break;
                }
                case PLAYER:
                {
                    if(Spectating[i] == 1) return 0;

                    new Float:PlayerPos[3];
                    DashUsado[playerid] = 1;

                    ApplyAnimation(playerid, "ped", "Jump_Front_L", 4.0, 0, 1, 1, 0, 1, 1);
                    SetTimerEx("AnimDash", 100, false, "d", playerid);

                    AudioInPlayer(playerid, 20.0, 48);
                    TimerDashC[playerid] = gettime() + DASH_COOLDOWN;

                    DashFrente[playerid] = 1;
                    DashFrenteON[playerid] = 1;

                    // ? FIX: guarda alvo do dash
                    DashTargetID[playerid] = i;

                    // ? FIX: no ar, n?o depender do FollowPlayer (que ?s vezes s? funciona no ch?o)
                    
                    // [NEW] DISTANCIA CURTA: se o alvo j? estiver perto, n?o aplica impulso/FollowPlayer
                    // (evita atravessar ou ir pro lado). For?a encaixe/hit como se tivesse colidido.
                    new Float:_px, Float:_py, Float:_pz;
                    new Float:_tx, Float:_ty, Float:_tz;
                    GetPlayerPos(playerid, _px, _py, _pz);
                    GetPlayerPos(i, _tx, _ty, _tz);
                    new Float:_dx = _tx - _px;
                    new Float:_dy = _ty - _py;
                    new Float:_dist2d = floatsqroot(_dx*_dx + _dy*_dy);

                    if(_dist2d <= RAPIDDASH_CLOSE_STOP_DIST)
                    {
                        DashCol_OnPlayerHit(playerid, i);
                    }
                    else
                    {
if(inAir)
                    {
                        DashImpulseXY_ToTarget(playerid, i, 0.9);
                    }
                    else
                    {
                        FollowPlayer(playerid, i, 0.9);
                    }
                    }


                    DashCol(playerid);
                    EstaminaDash(playerid);

                    GetPlayerPos(playerid, PlayerPos[0], PlayerPos[1], PlayerPos[2]);
                    DashOBJ[playerid] = CreateObject(18670, PlayerPos[0], PlayerPos[1], PlayerPos[2]-0.9, 0.0, 0.0, 0.0, 300.0);

                    SetTimerEx("ResetDashF", 850+(Info[playerid][pTaijutsu]/10), false, "i", playerid);
                    SetTimerEx("DashColReset", 850+(Info[playerid][pTaijutsu]/10), false, "i", playerid);
                    SetTimerEx("DashEffectDel", 3500, false, "i", playerid);
                    TimingDashFrente[playerid] = SetTimerEx("DashFrenteUse", 10000, false, "i", playerid);

                    return 1;
                }
            }
        }
    }
    return 1;
}

function AnimDash(playerid)
{
    ApplyAnimation(playerid, "ped", "Jump_Front_L", 4.0, 1, 1, 1, 0, 850+(Info[playerid][pTaijutsu]/10), 1);

    // ? FIX extra: reaplica o "pux?o" no ar (garante que a investida continue)
    if(DashFrenteON[playerid] == 1)
    {
        new t = DashTargetID[playerid];
        if(t != INVALID_PLAYER_ID && IsPlayerConnected(t))
        {
            // [NEW] se j? estiver MUITO perto, trata como colis?o (encaixa na frente e para)
            new Float:_px, Float:_py, Float:_pz;
            new Float:_tx, Float:_ty, Float:_tz;
            GetPlayerPos(playerid, _px, _py, _pz);
            GetPlayerPos(t, _tx, _ty, _tz);
            new Float:_dx = _tx - _px;
            new Float:_dy = _ty - _py;
            new Float:_dist2d = floatsqroot(_dx*_dx + _dy*_dy);
            if(_dist2d <= RAPIDDASH_CLOSE_STOP_DIST)
            {
                DashCol_OnPlayerHit(playerid, t);
                return 1;
            }

            if(IsPlayerAirborne_RapidDash(playerid))
            {
                DashImpulseXY_ToTarget(playerid, t, 0.8);
            }
            else
            {
                FollowPlayer(playerid, t, 0.9);
            }
        }
    }
    return 1;
}

AirComboDash(playerid)
{
    if(DaikodanHitAlvo[playerid] == 1 || Info[playerid][pDentroDeCasa] == 1 || HittedDoroji[playerid] == 1 || HittedKageshibari[playerid] == 1 || lastHitted[playerid][hitReason] > 1 || ByakuganON[playerid] == 1 || TsutenHittedAlvo[playerid] == 1 || Pescando[playerid] == 1) return 0;
    if(GetPVarInt(playerid, "Inconsciente") >= 1 || KagutsuchiON[playerid] == 1 || IkazuchiHitAlvo[playerid] == 1 || SeladoS[playerid] == 1 || ChidoriON[playerid] == 2 || SuirouON[playerid] == 1 || PlayerParalisado[playerid] == 1 || SetPlayerState[playerid] == 1 || ChuteCimaHitted[playerid] == 1 || SuirouHIT[playerid] == 1 || KatonHIT[playerid] == 1) return 0;
    if(AirComboTimer[playerid] > gettime()) return 0;
    new Float:PlayerPos[3];
    if(IsSomeoneInFrontOfPlayer(playerid, 5.0))
    {
        ApplyAnimation(playerid, "Shinobi_Anim", "JumpF", 4.1, 0, 1, 1, 0, 0, 1);
        AudioInPlayer(playerid, 20.0, 48);
        AirComboTimer[playerid] = gettime() + AIRCOMBO_COOLDOWN;
        AirComboIniciou[playerid] = 1;
        DashCurto(playerid);
        EstaminaDash(playerid);
        GetPlayerPos(playerid, PlayerPos[0], PlayerPos[1], PlayerPos[2]);
        AirDashObj[playerid] = CreateObject(18670, PlayerPos[0], PlayerPos[1], PlayerPos[2]-0.9, 0.0, 0.0, 0.0, 300.0);
        SetTimerEx("AirComboDel", 3500, false, "i", playerid);
        SetTimerEx("ResetAirCombo", 680, false, "i", playerid);
    }
    return 1;
}
function ResetAirCombo(playerid)
{
    AirComboIniciou[playerid] = 3;
    return 1;
}
function DashEffectDel(playerid)
{
    DestroyObject(DashOBJ[playerid]);
    return 1;
}
function AirComboDel(playerid)
{
    DestroyObject(AirDashObj[playerid]);
    return 1;
}

stock DashCol_OnPlayerHit(playerid, targetid)
{
    if(targetid == INVALID_PLAYER_ID) return 0;
    if(!IsPlayerConnected(targetid)) return 0;

    if(Invunerable[targetid] == 1) return 0;

    if(Izanagi[targetid][IzanagiAtivado])
    {
        SetTimerEx("IzanagiVoltar", 100, false, "d", targetid);
        return 0;
    }

    if(GetPVarInt(targetid, "Defensa"))
    {
        // DEFENSA no timing: cancela o HIT do Rapid Dash
        // - sem chute automᴩco
        // - sem quebrar defesa do defensor
        // - sem stun no defensor (ele pode contra-atacar manualmente)
        AudioInPlayer(targetid, 30.0, 108);

        DashFrenteON[playerid] = 3;
        DashUsado[playerid] = 0;
        DashUsado[targetid] = 0;

        RapidDash_SnapToTarget(playerid, targetid);
        SetPlayerToFacePlayer(playerid, targetid);
        if(EntrouArenaPvP[targetid] == 1){LastHitArenaPvP(playerid, targetid);}

        // Quebra-combo (empurr㯠PEQUENO) s󠳥 o cooldown estiver livre (40s)
        new qc = GetPVarInt(targetid, "QC_CD");
        if(qc <= 0 || qc <= gettime())
        {
            // empurra s󠵭 pouco o agressor para dar espa篠ao defensor
            new Float:ax, Float:ay, Float:az;
            new Float:dx, Float:dy, Float:dz;
            GetPlayerPos(playerid, ax, ay, az);
            GetPlayerPos(targetid, dx, dy, dz);

            new Float:vx = (ax - dx);
            new Float:vy = (ay - dy);
            new Float:len = floatsqroot(vx*vx + vy*vy);
            if(len < 0.001) len = 0.001;
            vx = (vx / len) * 0.20;
            vy = (vy / len) * 0.20;
            SetPlayerVelocity(playerid, vx, vy, 0.05);

            SetPVarInt(targetid, "QC_CD", gettime() + QUEBRACOMBO_COOLDOWN);
        }
        return 1;
    }
    else
    {
        ClearSelo(targetid);
        DashFrenteON[playerid] = 3;
        RapidDash_SnapToTarget(playerid, targetid);
        ClearAnimations(targetid);
        AudioInPlayer(targetid, 50.0, 68);
        SetPlayerToFacePlayer(playerid, targetid);
        DashUsado[playerid] = 0;
        HitCountCombos(playerid);
        DashFHitted[targetid] = 1;
        PCarregandoChakra(targetid);
        if(EntrouArenaPvP[targetid] == 1){LastHitArenaPvP(playerid, targetid);}
        ApplyAnimation(targetid, "Shinobi_Anim","Cansado", 4.0, 1, 0, 0, 1, 500, 1);
        DashFHittedTimer[targetid] = SetTimerEx("LimparDashHit", 500, false, "i", targetid);
        return 1;
    }
}

function DashCol(playerid)
{
    if(DashFrenteON[playerid] != 1) return 0;
    new Float:playerPos[3], vw = GetPlayerVirtualWorld(playerid);
    GetPlayerPos(playerid, playerPos[0], playerPos[1], playerPos[2]);

    // [NEW] DISTANCIA CURTA: se j? estamos perto do alvo travado do RapidDash,
    // forca o "hit" e o encaixe na frente, sem depender do GetShootedJutsu (ray) que pode falhar colado.
    new t = DashTargetID[playerid];
    if(t != INVALID_PLAYER_ID && IsPlayerConnected(t) && t != playerid)
    {
        if(GetPlayerVirtualWorld(t) == vw)
        {
            new Float:tx, Float:ty, Float:tz;
            GetPlayerPos(t, tx, ty, tz);

            new Float:dx = tx - playerPos[0];
            new Float:dy = ty - playerPos[1];
            new Float:dist2d = floatsqroot(dx*dx + dy*dy);

            if(dist2d <= RAPIDDASH_CLOSE_STOP_DIST)
            {
                if(DashCol_OnPlayerHit(playerid, t))
                {
                    // encerra a checagem - j? tratou colis?o/hit
                    SetTimerEx("DashCol", 50, false, "d", playerid);
                    return 0;
                }
            }
        }
    }

    for(new i; i<MAX_PLAYERS; i++)
    {
        switch(GetShootedJutsu(playerPos[0], playerPos[1], playerPos[2], 4.0, false, false, vw, playerid, i))
        {
            case DUMMY:
            {
                DashFrenteON[playerid] = 3;
                AudioInPlayer(playerid, 50.0, 68);
                SetPlayerInFrontOfDummy(playerid, i);
                TaijutsuAirHit[playerid] = 0;
                DashUsado[i] = 0;
                break;
            }
            case PLAYER:
            {
                // Trata colis?o com player usando a mesma l?gica, mas via helper (reutiliz?vel)
                DashCol_OnPlayerHit(playerid, i);
                break;
            }
        }
    }
    SetTimerEx("DashCol", 50, false, "d", playerid);
    return 0;
}
function DashCurto(playerid)
{
    if(AirComboIniciou[playerid] != 1) return 0;
    new Float:playerPos[3], vw = GetPlayerVirtualWorld(playerid);
    GetPlayerPos(playerid, playerPos[0], playerPos[1], playerPos[2]);
    for(new i; i<MAX_PLAYERS; i++)
    {
        switch(GetShootedJutsu(playerPos[0], playerPos[1], playerPos[2], 4.0, false, false, vw, playerid, i))
        {
            case DUMMY:
            {
                AirComboIniciou[playerid] = 3;
                AudioInPlayer(playerid, 50.0, 68);
                SetPlayerInFrontOfDummy(playerid, i);
                TaijutsuAirHit[playerid] = 0;
                DashUsado[i] = 0;
                break;
            }
            case PLAYER:
            {
                if(Invunerable[i] == 1) return 0;
                if(Izanagi[i][IzanagiAtivado]){
                    SetTimerEx("IzanagiVoltar", 100, false, "d", i);
                }else{
                    if(GetPVarInt(i, "Defensa"))
                    {
                        // DEFENSA no timing: cancela o HIT / inicia磯 do combo a鲥o
                        // - sem chute automᴩco
                        // - sem quebrar defesa do defensor
                        // - sem stun no defensor
                        AudioInPlayer(i, 30.0, 108);

                        AirComboIniciou[playerid] = 3;
                        DashUsado[i] = 0;

                        SetPlayerBehindPlayer(playerid, i);
                        SetPlayerToFacePlayer(playerid, i);
                        if(EntrouArenaPvP[i] == 1){LastHitArenaPvP(playerid, i);}

                        // Quebra-combo (empurr㯠PEQUENO) s󠳥 o cooldown estiver livre (40s)
                        new qc = GetPVarInt(i, "QC_CD");
                        if(qc <= 0 || qc <= gettime())
                        {
                            new Float:ax, Float:ay, Float:az;
                            new Float:dx, Float:dy, Float:dz;
                            GetPlayerPos(playerid, ax, ay, az);
                            GetPlayerPos(i, dx, dy, dz);

                            new Float:vx = (ax - dx);
                            new Float:vy = (ay - dy);
                            new Float:len = floatsqroot(vx*vx + vy*vy);
                            if(len < 0.001) len = 0.001;
                            vx = (vx / len) * 0.20;
                            vy = (vy / len) * 0.20;
                            SetPlayerVelocity(playerid, vx, vy, 0.05);

                            SetPVarInt(i, "QC_CD", gettime() + QUEBRACOMBO_COOLDOWN);
                        }
                        break;
                    }else{
                        if(EntrouArenaPvP[i] == 1){LastHitArenaPvP(playerid, i);}
                        ClearSelo(i);
                        HitCountCombos(playerid);
                        AudioInPlayer(i, 50.0, 68);
                        AirComboIniciou[playerid] = 3;
                        TaijutsuAirHit[playerid] = 0;
                        ChuteCimaHitImpossible[playerid] = 1;
                        AirCombo[playerid][airTarget] = i;
                        ChuteCimaHitted[i] = 1;
                        DashUsado[i] = 0;
                        AirCombo[playerid][airHits] = 0;
                        AirComboStart(playerid, i);
                        SetTimerEx("ChuteCimaPlayerTarget", 750, false, "ii", playerid, i);
                        SetTimerEx("PlayerInAirA", 800, false, "ii", playerid, i);
                        SetTimerEx("LimparChuteC", 800, false, "ii", playerid, i);
                        AirCombo[i][airTiming][0] = SetTimerEx("LimparParalisado", 1850, false, "i", i);
                        AirCombo[i][airTiming][1] = SetTimerEx("ClearChuteCima", 1850, false, "i", i);
                        break;
                    }
                    
                }      
            }
        }
    }
    SetTimerEx("DashCurto", 50, false, "d", playerid);
    return 0;
}
function ChuteForteD(playerid, AlvoPlayerChute)
{
    // IMPORTANTE: N?O ALTERADO (mant?m seu sistema de chute forte como est?)
    if(Izanagi[AlvoPlayerChute][IzanagiAtivado]){
        IzanagiVoltar(AlvoPlayerChute);
    }else{
        HitCountCombos(playerid);
        ApplyAnimation(playerid, "Combo_1","Hit_3x", 4.0, 0, 0, 0, 0, 0, 1);
        AudioInPlayer(playerid, 50.0, 67);
        SetDamageToPlayer(playerid, AlvoPlayerChute, GetDamageToPlayer(playerid, MELEE, 0, 10.0));
        SetPlayerToFacePlayer(playerid, AlvoPlayerChute);
        ChutaoUse[playerid] = 1;
        ClearSelo(AlvoPlayerChute);
        SetTimerEx("GetPlayerCollision", 200, false, "d", AlvoPlayerChute);
        TimingChuteForte[playerid] = SetTimerEx("ChutaoForteReset", 5000, false, "i", playerid);
        SetTimerEx("ChutaoForte", 100, false, "i", AlvoPlayerChute);
    }
    DefesaH[playerid][defesaHitDash] = 0;      
    return 1;
}
function LimparDashHit(playerid)
{
    KillTimer(DashFHittedTimer[playerid]);
    DashFHitted[playerid] = 0;
    ApplyAnimation(playerid, "Shinobi_Anim","Cansado", 4.0, 0, 0, 0, 0, 1, 1);
    return 1;
}
function QuebraDefesaAgain(playerid)
{
    KillTimer(TimerQuebraDefesa[playerid]);
    ImpossibleDefesa[playerid] = 0;
    return 1;
}
function DashColReset(playerid)
{
    DashFrenteON[playerid] = 3;
    return 1;
}
function AirComboDasha(playerid)
{
    new Float:playerPos[3], vw = GetPlayerVirtualWorld(playerid);
    GetPlayerPos(playerid, playerPos[0], playerPos[1], playerPos[2]);
    for(new i; i<MAX_PLAYERS; i++)
    {
        switch(GetShootedJutsu(playerPos[0], playerPos[1], playerPos[2], 3.0, false, false, vw, playerid, i))
        {
            case PLAYER:
            {
                if(HitPlayerCount[playerid] >= 3)
                TaijutsuAirHit[playerid] = 0;
                ChuteCimaHitImpossible[playerid] = 1;
                AirCombo[playerid][airTarget] = i;
                ChuteCimaHitted[i] = 1;
                DashUsado[i] = 0;
                ApplyAnimation(playerid, "Shinobi_Anim", "JumpF", 4.1, 0, 1, 1, 0, 0, 1);
                AirCombo[playerid][airHits] = 0;
                AirComboStart(playerid, i);
                SetTimerEx("ChuteCimaPlayerTarget", 750, false, "ii", playerid, i);
                SetTimerEx("PlayerInAirA", 800, false, "ii", playerid, i);
                SetTimerEx("LimparChuteC", 800, false, "ii", playerid, i);
                AirCombo[i][airTiming][0] = SetTimerEx("LimparParalisado", 1850, false, "i", i);
                AirCombo[i][airTiming][1] = SetTimerEx("ClearChuteCima", 1850, false, "i", i);
                return 1;//break;
            }
        }
    }
    return 0;
}
AirComboStart(playerid, targetid)
{
    if(GetPVarInt(targetid, "Inconsciente") >= 1 || SuirouHIT[targetid] == 1) return 0;
    if(Dorojigoku[targetid][doroCaster] != INVALID_PLAYER_ID)
    {
        Dorojigoku[targetid][doroCaster] = INVALID_PLAYER_ID;
        PlayerTextDrawHide(targetid, PressTD[targetid]);
        HittedDoroji[targetid] = 0;
        UnfreezePlayer(targetid);
    }

    // [NEW] reseta a flag do empurr?o final para este combo (por atacante)
    AirComboFinalLaunchDone[playerid] = 0;

    // [NEW] pega o limite real de hits do ar para este atacante (usa limitehits.pwn)
    #if AIR_FINAL_USE_HIT_LIMIT
        AirComboHitLimitCache[playerid] = GetAirComboHitLimit(playerid);
        if(AirComboHitLimitCache[playerid] < 1) AirComboHitLimitCache[playerid] = 3;
    #else
        AirComboHitLimitCache[playerid] = 0; // nao usado no modo legado
    #endif


    TaijutsuVar[playerid][taiHits] = 0;
    ClearSelo(targetid);
    Status[targetid] = 6;
    SistemaBandanaIDStatus(targetid);
    if(GetPVarInt(playerid, "Inconsciente") == 0)
    {
        ApplyAnimation(playerid, "Combo_1", "Hit_3x", 3.0, 0, 1, 1, 0, 0, 1);
        AirCombo[targetid][airIn] = 1;
        AirCombo[playerid][airIn] = 1;
        AirCombo[playerid][airTimes] = 0;
        AirCombo[playerid][airTimer] = SetTimerEx("KnockUP", 100, true, "dd", playerid, targetid);
    }
    return 1;
}
function KnockUP(playerid, targetid)
{
    if(!IsPlayerConnected(targetid))
    {
        KillTimer(AirCombo[playerid][airTimer]);
        AirCombo[playerid][airIn] = 0;

        // [NEW] seguran?a: reseta flag
        AirComboFinalLaunchDone[playerid] = 0;
        AirComboHitLimitCache[playerid] = 0;
        return 1;
    }

    if(++AirCombo[playerid][airTimes] > 18 && (!IsPlayerInAir[playerid] || !IsPlayerInAir[targetid] || GetPVarInt(playerid, "Inconsciente") >= 1 || GetPVarInt(playerid, "Inconsciente") >= 1))
    {
        KillTimer(AirCombo[playerid][airTimer]);
        AirCombo[playerid][airIn] = 0;
        AirCombo[targetid][airIn] = 0;

        // [NEW] seguran?a: reseta flag
        AirComboFinalLaunchDone[playerid] = 0;
        AirComboHitLimitCache[playerid] = 0;
        return 1;
    }
    switch(AirCombo[playerid][airTimes])
    {
        case 1:
        {
            SetPlayerToFacePlayer(playerid, targetid);
            SetPlayerToFacePlayer(targetid, playerid);
        }
        case 8:
        {
            ConfrontPlayer(targetid, playerid);
        }
    }
    if(AirCombo[playerid][airTimes] > 5 && AirCombo[playerid][airTimes] < 10) ConfrontPlayer(targetid, playerid);

    // ==========================================================
    // [NEW] ULTIMO HIT REAL DO COMBO AEREO: empurra a vitima 1~2m a mais
    // - MODO 1 (AIR_FINAL_USE_HIT_LIMIT=1): dispara no EXATO ultimo hit (TaijutsuAirHit >= limite calculado)
    // - MODO 0 (legado): dispara no tick AIR_FINAL_TICK do KnockUP
    // ==========================================================
    #if AIR_FINAL_USE_HIT_LIMIT
        if(AirComboFinalLaunchDone[playerid] == 0
            && IsPlayerInAir[playerid]
            && IsPlayerInAir[targetid])
        {
            if(AirComboHitLimitCache[playerid] < 1) AirComboHitLimitCache[playerid] = 3;

            if(AirCombo[playerid][airHits] >= AirComboHitLimitCache[playerid])
            {
                AirComboFinalLaunchDone[playerid] = 1;
                AirCombo_ApplyFinalLaunch(playerid, targetid);
            }
        }
    #else
        if(AirCombo[playerid][airTimes] == AIR_FINAL_TICK
            && AirComboFinalLaunchDone[playerid] == 0
            && IsPlayerInAir[playerid]
            && IsPlayerInAir[targetid])
        {
            AirComboFinalLaunchDone[playerid] = 1;
            AirCombo_ApplyFinalLaunch(playerid, targetid);
        }
    #endif

    //if(AirCombo[playerid][airTimes] < 3) return 1;
    if(AirCombo[playerid][airTimes] < 8) //aumenta altura do aircombo
    {
        SetPlayerVelocity(playerid, 0.0, 0.0, 10.0); SetPlayerVelocity(targetid, 0.0, 0.0, 10.0);
        ApplyAnimation(playerid, "Combo_1", "Atk_cmb03", 6.1, 1, 1, 1, 0, 200, 1);
        ApplyAnimation(targetid, "Combo_1", "Atk_cmb03", 6.1, 1, 1, 1, 0, 200, 1);
    }
    return 1;
}

// --- Reset usado pelo Dash no ch?o (timer "ResetDashChao") ---
function ResetDashChao(playerid)
{
    KillTimer(DashChaoTimer[playerid]);
    DashUsado[playerid] = 0;
    DashChao[playerid] = 0;
    return 1;
}