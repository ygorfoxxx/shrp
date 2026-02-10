// ==========================================================
//  Selos.pwn  (PONTE -> hotbarpreparacao)
//  - Mantém VerificarSelos()
//  - Centraliza tudo no Jutsu_CastBySelos()
// ==========================================================

#if defined _SHRP_SELOS_INCLUDED
    // já incluído
#else
#define _SHRP_SELOS_INCLUDED

#include <a_samp>

// IMPORTA o core (onde existe Jutsu_CastBySelos)
#include "Includes\\Jutsus\\hotbarpreparacao.pwn"

forward VerificarSelos(playerid, const selos[]);
public VerificarSelos(playerid, const selos[])
{
    if (!IsPlayerConnected(playerid)) return 0;
    if (!strlen(selos)) return 0;

    // (Opcional) debug:
    // printf("[SELOS] player %d: %s", playerid, selos);

    return Jutsu_CastBySelos(playerid, selos);
}

#endif // _SHRP_SELOS_INCLUDED
