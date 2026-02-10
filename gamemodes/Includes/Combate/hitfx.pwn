#if defined _SHRP_HITFX_
    #endinput
#endif
#define _SHRP_HITFX_

#include <streamer>

#define HITFX_MODEL        (18707)
#define HITFX_LIFETIME_MS  (350)
#define HITFX_Z_OFFSET     (0.60)

// anti-spam simples (evita estourar objeto se algum hit rodar 2x no mesmo tick)
static gLastHitFxTick[MAX_PLAYERS];

forward HitFX_DestroyDyn(objid);
public HitFX_DestroyDyn(objid)
{
    DestroyDynamicObject(objid);
    return 1;
}

stock Taijutsu_SpawnHitFX(attackerid, victimid)
{
    if(!IsPlayerConnected(attackerid) || !IsPlayerConnected(victimid)) return 0;

    new now = GetTickCount();
    if(now - gLastHitFxTick[victimid] < 60) return 1; // 60ms de throttle
    gLastHitFxTick[victimid] = now;

    new vw = GetPlayerVirtualWorld(victimid);
    new interior = GetPlayerInterior(victimid);

    new Float:ax, Float:ay, Float:az;
    new Float:vx, Float:vy, Float:vz;
    GetPlayerPos(attackerid, ax, ay, az);
    GetPlayerPos(victimid,  vx, vy, vz);

    new Float:x = (ax + vx) * 0.5;
    new Float:y = (ay + vy) * 0.5;
    new Float:z = (az + vz) * 0.5 + HITFX_Z_OFFSET;

    new Float:ang;
    GetPlayerFacingAngle(attackerid, ang);

    new obj = CreateDynamicObject(HITFX_MODEL, x, y, z, 0.0, 0.0, ang, vw, interior, -1, 60.0, 60.0);
    SetTimerEx("HitFX_DestroyDyn", HITFX_LIFETIME_MS, false, "i", obj);
    return 1;
}
