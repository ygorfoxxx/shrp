#if defined _WALLRUN_INC
    #endinput
#endif
#define _WALLRUN_INC

#include <a_samp>
#include <colandreas>

// ===================== CONFIG RAPIDA =====================
#define WR_ANIM_LIB              "PAREDETESTE" // nome da LIB no client (não é obrigatoriamente o nome do .ifp)
#define WR_TICK_MS               (45)
#define WR_RAY_DIST              (1.25)
#define WR_MAX_WALL_NZ           (0.35)
#define WR_STICK_FORCE           (0.20)
#define WR_OFFSET_FORCE_K        (0.90)
#define WR_TARGET_OFFSET         (0.35)

// Velocidades
#define WR_CLIMB_WALK_Z          (0.55)
#define WR_CLIMB_SPRINT_Z        (0.90)
#define WR_SLIDE_IDLE_Z          (-0.10)
#define WR_DESCEND_Z             (-0.70)

#define WR_SIDE_WALK             (0.35)
#define WR_SIDE_SPRINT           (0.55)

// Pulo pra sair
#define WR_JUMP_BACK_PUSH        (0.80)
#define WR_JUMP_UP               (0.45)

// Teclas
#define WR_KEY_DEFEND            (KEY_SECONDARY_ATTACK)

// ===================== STATE =====================
enum eWRDir
{
    WR_DIR_NONE = 0,
    WR_DIR_W,
    WR_DIR_S,
    WR_DIR_A,
    WR_DIR_D,
    WR_DIR_WA,
    WR_DIR_WD,
    WR_DIR_SA,
    WR_DIR_SD
};

new bool:gWR_Active[MAX_PLAYERS];
new gWR_NextTick[MAX_PLAYERS];

new Float:gWR_NX[MAX_PLAYERS], Float:gWR_NY[MAX_PLAYERS], Float:gWR_NZ[MAX_PLAYERS];
new Float:gWR_HX[MAX_PLAYERS], Float:gWR_HY[MAX_PLAYERS], Float:gWR_HZ[MAX_PLAYERS];

new gWR_LastKeys[MAX_PLAYERS];
new gWR_LastDir[MAX_PLAYERS];
new gWR_LastMode[MAX_PLAYERS]; // 0 idle, 1 walk, 2 sprint, 3 defend
new gWR_LastAnim[MAX_PLAYERS][32];

// ===================== HELPERS =====================
stock Float:WR_Clamp(Float:v, Float:mn, Float:mx)
{
    if (v < mn) return mn;
    if (v > mx) return mx;
    return v;
}

stock eWRDir:WR_DirFromUDLR(ud, lr)
{
    new bool:up = (ud == KEY_UP);
    new bool:dn = (ud == KEY_DOWN);
    new bool:lf = (lr == KEY_LEFT);
    new bool:rt = (lr == KEY_RIGHT);

    if (up && lf) return WR_DIR_WA;
    if (up && rt) return WR_DIR_WD;
    if (dn && lf) return WR_DIR_SA;
    if (dn && rt) return WR_DIR_SD;
    if (up) return WR_DIR_W;
    if (dn) return WR_DIR_S;
    if (lf) return WR_DIR_A;
    if (rt) return WR_DIR_D;
    return WR_DIR_NONE;
}

stock WR_BuildAnimName(wrMode, eWRDir:dir, dest[], destLen)
{
    new prefix[16];
    new suffix[4];

    switch (wrMode)
    {
        case 0: format(prefix, sizeof(prefix), "IdleWall");
        case 1: format(prefix, sizeof(prefix), "WalkWall");
        case 2: format(prefix, sizeof(prefix), "SpriWall");
        case 3: format(prefix, sizeof(prefix), "DefWall");
        default: format(prefix, sizeof(prefix), "WalkWall");
    }

    switch (dir)
    {
        case WR_DIR_W:  format(suffix, sizeof(suffix), "_W");
        case WR_DIR_S:  format(suffix, sizeof(suffix), "_S");
        case WR_DIR_A:  format(suffix, sizeof(suffix), "_A");
        case WR_DIR_D:  format(suffix, sizeof(suffix), "_D");
        case WR_DIR_WA: format(suffix, sizeof(suffix), "_WA");
        case WR_DIR_WD: format(suffix, sizeof(suffix), "_WD");
        case WR_DIR_SA: format(suffix, sizeof(suffix), "_SA");
        case WR_DIR_SD: format(suffix, sizeof(suffix), "_SD");
        default:        format(suffix, sizeof(suffix), "_W");
    }

    format(dest, destLen, "%s%s", prefix, suffix);
}

#if defined animName
    #undef animName
#endif
#if defined anim
    #undef anim
#endif


stock WR_PlayAnimIfChanged(playerid, const wrAnimName[])
{
    if (!strcmp(gWR_LastAnim[playerid], wrAnimName, true)) return 1;

    ApplyAnimation(playerid, WR_ANIM_LIB, wrAnimName, 4.1, 1, 0, 0, 0, 0, 1);

    format(gWR_LastAnim[playerid], sizeof(gWR_LastAnim[]), "%s", wrAnimName);
    return 1;
}



stock bool:WR_RaycastFront(playerid, Float:dist, &Float:hx, &Float:hy, &Float:hz, &Float:nx, &Float:ny, &Float:nz)
{
    new Float:px, Float:py, Float:pz, Float:ang;
    GetPlayerPos(playerid, px, py, pz);
    GetPlayerFacingAngle(playerid, ang);

    new Float:dx = floatsin(-ang, degrees);
    new Float:dy = floatcos(-ang, degrees);

    new Float:sx = px;
    new Float:sy = py;
    new Float:sz = pz + 1.0;

    new Float:ex = px + dx * dist;
    new Float:ey = py + dy * dist;
    new Float:ez = sz;

    // ✅ FIX: cast no Z (arg 3 e 6) pra bater com includes colandreas "mal taggeadas"
    new modelid = CA_RayCastReflectionVector(sx, sy, _:sz, ex, ey, _:ez, hx, hy, hz, nx, ny, nz);
    if (modelid == 0 || modelid == 20000) return false;
    return true;
}

stock WR_FixNormalTowardsPlayer(Float:px, Float:py, Float:pz, Float:hx, Float:hy, Float:hz, &Float:nx, &Float:ny, &Float:nz)
{
    new Float:vx = px - hx;
    new Float:vy = py - hy;
    new Float:vz = pz - hz;

    new Float:dot = (vx * nx) + (vy * ny) + (vz * nz);
    if (dot < 0.0)
    {
        nx = -nx; ny = -ny; nz = -nz;
    }
}

// ===================== API =====================
stock WallRun_ResetPlayer(playerid)
{
    gWR_Active[playerid] = false;
    gWR_NextTick[playerid] = 0;
    gWR_LastKeys[playerid] = 0;
    gWR_LastDir[playerid] = _:WR_DIR_NONE;
    gWR_LastMode[playerid] = -1;
    gWR_LastAnim[playerid][0] = '\0';
}

stock bool:WallRun_TryEnter(playerid)
{
    if (gWR_Active[playerid]) return false;
    if (GetPlayerState(playerid) != PLAYER_STATE_ONFOOT) return false;

    new keys, ud, lr;
    GetPlayerKeys(playerid, keys, ud, lr);

    // entra só se estiver segurando W e apertar JUMP (a chamada vem do keychange)
    if (ud != KEY_UP) return false;

    new Float:hx, Float:hy, Float:hz, Float:nx, Float:ny, Float:nz;
    if (!WR_RaycastFront(playerid, WR_RAY_DIST, hx, hy, hz, nx, ny, nz)) return false;

    // parede = normal com nz pequeno
    if (floatabs(nz) > WR_MAX_WALL_NZ) return false;

    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    WR_FixNormalTowardsPlayer(px, py, pz, hx, hy, hz, nx, ny, nz);

    gWR_Active[playerid] = true;
    gWR_HX[playerid] = hx; gWR_HY[playerid] = hy; gWR_HZ[playerid] = hz;
    gWR_NX[playerid] = nx; gWR_NY[playerid] = ny; gWR_NZ[playerid] = nz;

    gWR_LastMode[playerid] = -1;
    gWR_LastDir[playerid] = _:WR_DIR_NONE;
    gWR_LastAnim[playerid][0] = '\0';
    return true;
}

stock WallRun_Exit(playerid)
{
    if (!gWR_Active[playerid]) return;
    gWR_Active[playerid] = false;
    gWR_LastMode[playerid] = -1;
    gWR_LastDir[playerid] = _:WR_DIR_NONE;
    gWR_LastAnim[playerid][0] = '\0';
    ClearAnimations(playerid);
}

stock WallRun_DoWallJump(playerid)
{
    if (!gWR_Active[playerid]) return;

    new Float:nx = gWR_NX[playerid];
    new Float:ny = gWR_NY[playerid];

    SetPlayerVelocity(playerid, nx * WR_JUMP_BACK_PUSH, ny * WR_JUMP_BACK_PUSH, WR_JUMP_UP);
    WallRun_Exit(playerid);
}

stock WallRun_OnKeyStateChange(playerid, newkeys, oldkeys)
{
    if ((newkeys & KEY_JUMP) && !(oldkeys & KEY_JUMP))
    {
        if (gWR_Active[playerid]) WallRun_DoWallJump(playerid);
        else WallRun_TryEnter(playerid);
    }
    gWR_LastKeys[playerid] = newkeys;
    return 1;
}

stock WallRun_OnUpdate(playerid)
{
    if (!gWR_Active[playerid]) return 1;

    new now = GetTickCount();
    if (now < gWR_NextTick[playerid]) return 1;
    gWR_NextTick[playerid] = now + WR_TICK_MS;

    if (GetPlayerState(playerid) != PLAYER_STATE_ONFOOT)
    {
        WallRun_Exit(playerid);
        return 1;
    }

    new keys, ud, lr;
    GetPlayerKeys(playerid, keys, ud, lr);

    new Float:hx, Float:hy, Float:hz, Float:nx, Float:ny, Float:nz;
    if (!WR_RaycastFront(playerid, WR_RAY_DIST, hx, hy, hz, nx, ny, nz))
    {
        WallRun_Exit(playerid);
        return 1;
    }
    if (floatabs(nz) > WR_MAX_WALL_NZ)
    {
        WallRun_Exit(playerid);
        return 1;
    }

    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);
    WR_FixNormalTowardsPlayer(px, py, pz, hx, hy, hz, nx, ny, nz);

    gWR_HX[playerid] = hx; gWR_HY[playerid] = hy; gWR_HZ[playerid] = hz;
    gWR_NX[playerid] = nx; gWR_NY[playerid] = ny; gWR_NZ[playerid] = nz;

    new bool:def = ((keys & WR_KEY_DEFEND) != 0);
    new bool:sprint = ((keys & KEY_SPRINT) != 0);

    new eWRDir:dir = WR_DirFromUDLR(ud, lr);

    new wrMode;
    if (def) wrMode = 3;
    else if (dir == WR_DIR_NONE) wrMode = 0;
    else if (sprint) wrMode = 2;
    else wrMode = 1;

    if (wrMode != gWR_LastMode[playerid] || (_:dir) != gWR_LastDir[playerid])
    {
new wrAnimName[32]; // SEM [32 char]
WR_BuildAnimName(wrMode, dir, wrAnimName, sizeof(wrAnimName));
WR_PlayAnimIfChanged(playerid, wrAnimName);

        gWR_LastMode[playerid] = wrMode;
        gWR_LastDir[playerid] = _:dir;
    }

    // Tangente na parede (direita): up x normal = (-ny, nx, 0)
    new Float:tx = -ny, Float:ty = nx;
    new Float:tlen = floatsqroot(tx*tx + ty*ty);
    if (tlen > 0.0001) { tx /= tlen; ty /= tlen; }

    new Float:sideSign = 0.0;
    if (lr == KEY_LEFT) sideSign = -1.0;
    else if (lr == KEY_RIGHT) sideSign = 1.0;

    new Float:zspeed = WR_SLIDE_IDLE_Z;
    if (ud == KEY_UP)
    {
        zspeed = sprint ? WR_CLIMB_SPRINT_Z : WR_CLIMB_WALK_Z;
        if (def) zspeed *= 0.6;
    }
    else if (ud == KEY_DOWN)
    {
        zspeed = WR_DESCEND_Z;
        if (def) zspeed *= 0.6;
    }

    new Float:sidespeed = sprint ? WR_SIDE_SPRINT : WR_SIDE_WALK;
    if (def) sidespeed *= 0.65;

    new Float:distN = (px - hx) * nx + (py - hy) * ny + (pz - hz) * nz;
    new Float:offsetErr = WR_TARGET_OFFSET - distN;
    offsetErr = WR_Clamp(offsetErr, -0.30, 0.30);

    new Float:stick = WR_STICK_FORCE + (offsetErr * WR_OFFSET_FORCE_K);

    new Float:vx = (tx * sideSign * sidespeed) + (-nx * stick);
    new Float:vy = (ty * sideSign * sidespeed) + (-ny * stick);
    new Float:vz = zspeed;

    SetPlayerVelocity(playerid, vx, vy, vz);
    return 1;
}
