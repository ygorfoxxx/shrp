#include <a_samp>
#include <zcmd>
#include <streamer>
#include <sscanf2>
#include <fly>
new IsFly[MAX_PLAYERS];
CMD:flymode(playerid, params[])
{
    if(IsFly[playerid] == 0){ IsFly[playerid] = 1;
        StartFly(playerid);
    }else if(IsFly[playerid] == 1){ IsFly[playerid] = 0;
        StopFly(playerid);
    }
    return 1;
}