Golpear(playerid, hit)
{
    new Float:vP[3], Float:distance = 1.9, bool:success, lActor = GetPlayerCameraTargetDynActor(playerid), lPlayer = GetPlayerCameraTargetPlayer(playerid);
    TaijutsuHit(playerid, hit);
    GetPlayerPos(playerid, vP[0], vP[1], vP[2]);
    if(lPlayer != 65535)
    {
        if(IsPlayerInRangeOfPoint(lPlayer, distance, vP[0], vP[1], vP[2]) && IsPlayerHittable(lPlayer))
        {
            new bool:Protegido = GetPVarInt(lPlayer, "Defensa");
            GetPlayerPos(lPlayer, vP[0], vP[1], vP[2]);
            HitPlayer(playerid, lPlayer, hit, Protegido);
            success = true;
        }
    }
    if(lActor != INVALID_PLAYER_ID)
    {
        for(new v; v<MAX_PLAYERS; v++)
        {
            if(v<sizeof(BONECOS))
            {
                if(IsPlayerInRangeOfPoint(playerid, distance, Bonecos[v][posBoneco][0], Bonecos[v][posBoneco][1], Bonecos[v][posBoneco][2]) && IsActorHitted(v))
                {
                    HitActor(playerid, v, hit);
                    success = true;
                    break;
                }
            }
        }
    }
    if(!success)
    {
        switch(hit)
        {
            case 1: { AudioInPlayer(playerid, 20.0, 77); }
            case 2: { AudioInPlayer(playerid, 20.0, 78); }
            case 3: { AudioInPlayer(playerid, 20.0, 77); }
            case 4: { AudioInPlayer(playerid, 20.0, 78); }
        }
    }
    if(success) 
    {
        CreateEffect(hit % 2 == 0 ? 18726 : 18707, vP[0], vP[1], vP[2]-0.9, 0.0, 0.0, 0.0, 300.0);
    }
    return 0;
}
HitPlayer(playerid, victimid, hit, bool:protected)
{   
    if(protected) return ProtectedSound(victimid, hit);
    _CCHit(victimid);
    ClearSelo(victimid);
    DeletePVar(victimid, "Defensa");
    SetPlayerToFacePlayer(playerid, victimid);
    TaijutsuVar[victimid][taiHits] = 0;
    SetDamageToPlayer(playerid, victimid, GetDamageToPlayer(playerid, MELEE, 0, 1.0));
    if(JuuhoON[playerid] == 1)
    {
        if(JuuhoHit[playerid] >= 4)
        {
            SetDamageToPlayer(playerid, victimid, GetDamageToPlayer(playerid, MELEE, 13, 5.0));
            ApplyAnimation(victimid, "Shinobi_Anim", "Caindo", 4.1, 0, 1, 1, 1, 0, 1);
            ChutaoForteSpeed(victimid, -1.3);
            AudioInPlayer(victimid, 30.0, 67);
            AudioInPlayer(playerid, 100.0, 64);
            SetPlayerState[victimid] = 1;
            SetTimerEx("GetPlayerCollision", 450, false, "d", victimid);
            JuuhoHit[playerid] = 0;
        }
        JuuhoHit[playerid] ++;
        SetDamageToPlayer(playerid, victimid, GetDamageToPlayer(playerid, MELEE, 12, 2.5));
    }
    if(IsPlayerInAir[playerid] == 1)
    {
        SetAlvoNoPlayer(playerid, victimid);
        SetPlayerVelocity(victimid, 0.0, 0.0, 0.03);
    }
    switch(hit)
    {
        case 1: { ApplyAnimation(victimid, "Combo_1", "Recebido_1x", 3.0, 0, 1, 1, 0, 0, 1); AudioInPlayer(victimid, 20.0, 73); }
        case 2: { ApplyAnimation(victimid, "Combo_1", "Recebido_2x", 3.0, 0, 1, 1, 0, 0, 1); AudioInPlayer(victimid, 20.0, 74); }
        case 3: { ApplyAnimation(victimid, "Combo_1", "Recebido_3x", 3.0, 0, 1, 1, 0, 0, 1); AudioInPlayer(victimid, 20.0, 75); }
        case 4: { ApplyAnimation(victimid, "Combo_1", "Recebido_4x", 3.0, 0, 1, 1, 0, 0, 1); AudioInPlayer(victimid, 20.0, 76); }
    }
    return 1;
}
AtacarEx(playerid)
{
    SetPlayerFacingCamera(playerid);
    if(AnimChidoriJutsu[playerid] == 1) return SetTimerEx("ChidoriAnim", 50, 0, "d", playerid);
    if(TaijutsuVar[playerid][taiHit] || GetPVarInt(playerid, "Defensa") || AirCombo[playerid][airIn] == 2 || Invunerable[playerid]) return 0;
    TaijutsuVar[playerid][taiHits] = TaijutsuVar[playerid][taiHits] >= 4 ? 1 : ++TaijutsuVar[playerid][taiHits];
    Golpear(playerid, TaijutsuVar[playerid][taiHits]);
    return 1;
}
TaijutsuHit(playerid, hit)
{
    SetPlayerFacingCamera(playerid);
    if(IsPlayerInAir[playerid] == 1 && CharakNoSaberuUse[playerid] == 1 && Info[playerid][pClan] == 4){TaijutsuAirSaberu(playerid, hit); SetXYPlayerVelocity(playerid, 0.03);}
    else if(IsPlayerInAir[playerid] == 1 && CharakNoSaberuUse[playerid] == 1){TaijutsuAirSaberu(playerid, hit); SetXYPlayerVelocity(playerid, 0.03);}
    else if(IsPlayerInAir[playerid] == 1 && Info[playerid][pClan] == 4){TaijutsuAirHyuuga(playerid, hit); SetXYPlayerVelocity(playerid, 0.03);}
    else if(CharakNoSaberuUse[playerid] == 1){TaijutsuSaberu(playerid, hit);}
    else if(IsPlayerInAir[playerid] == 1){TaijutsuAir(playerid, hit); SetXYPlayerVelocity(playerid, 0.03);}
    else if(Info[playerid][pClan] == 4){TaijutsuMeleeHyuuga(playerid, hit);} 
    else {TaijutsuMelee(playerid, hit);}
    return 1;
}
_CanHitAgain(playerid, time)
{
    TaijutsuVar[playerid][taiHit] = SetTimerEx("CanHit", time, 0, "d", playerid);
}
function CanHit(playerid) 
{
    TaijutsuVar[playerid][taiHit] = 0;
}
_CCHit(playerid)
{
    TaijutsuVar[playerid][taiHitted] = SetTimerEx("HitOff", 520, 0, "d", playerid);
    return 1;
}
function HitOff(playerid)
{
    TaijutsuVar[playerid][taiHitted] = 0;
}