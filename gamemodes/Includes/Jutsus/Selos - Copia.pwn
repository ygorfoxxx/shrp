// ==========================================================
//  Selos.pwn  (PONTE -> hotbarpreparacao)
//  - Mantm VerificarSelos()
//  - Centraliza tudo no Jutsu_CastBySelos()
// ==========================================================

#if defined _SHRP_SELOS_INCLUDED
    // j includo
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

    // EXEMPLO de sequncia cannica: "Tigre, Cobra, Tigre, "
    // (HBCH_SelosCanonicalize padroniza)
    new canon[128];
    if (HBCH_SelosCanonicalize(selos, canon, sizeof canon))
    {
        if (!strcmp(canon, "Tigre, Cobra, Tigre, ", true))
            return Jutsu_KageBunshin(playerid);
    
// ==========================================================
// NPCs (FCNPC) no usam hotbar do player. Aqui fazemos um mapeamento
// FIXO de selos -> jutsu, apenas quando for NPC.
// Para passar o alvo (target), o sistema de IA deve setar:
//   SetPVarInt(npcid, "NPCSelosTarget", targetid + 1);
// ==========================================================
if (IsPlayerNPC(playerid))
{
    new targetid = GetPVarInt(playerid, "NPCSelosTarget") - 1;
    if (targetid < 0 || !IsPlayerConnected(targetid)) targetid = INVALID_PLAYER_ID;

    // Katon (1..3)
    if (!strcmp(canon, "Tigre, ", true))                 return Jutsu_CastByID(playerid, JID_GOUKAKYUU, targetid);
    if (!strcmp(canon, "Tigre, Cobra, ", true))          return Jutsu_CastByID(playerid, JID_HOUSENKA, targetid);
    if (!strcmp(canon, "Tigre, Cobra, Dragao, ", true))  return Jutsu_CastByID(playerid, JID_KARYUUENDAN, targetid);

    // Suiton (1..3)
    if (!strcmp(canon, "Cobra, ", true))                 return Jutsu_CastByID(playerid, JID_MIZURAPPA, targetid);
    if (!strcmp(canon, "Cobra, Coelho, ", true))         return Jutsu_CastByID(playerid, JID_SUIKODAN, targetid);
    if (!strcmp(canon, "Cobra, Coelho, Dragao, ", true)) return Jutsu_CastByID(playerid, JID_SUIROU, targetid);

    // Futon (1..3)
    if (!strcmp(canon, "Coelho, ", true))                return Jutsu_CastByID(playerid, JID_HANACHI, targetid);
    if (!strcmp(canon, "Coelho, Tigre, ", true))         return Jutsu_CastByID(playerid, JID_SHINKUHA, targetid);
    if (!strcmp(canon, "Coelho, Tigre, Dragao, ", true)) return Jutsu_CastByID(playerid, JID_ATSUGAI, targetid);

    // Doton (1..3)
    if (!strcmp(canon, "Dragao, ", true))                return Jutsu_CastByID(playerid, JID_IWAKAI, targetid);
    if (!strcmp(canon, "Dragao, Rato, ", true))          return Jutsu_CastByID(playerid, JID_DORYUUHEKI, targetid);
    if (!strcmp(canon, "Dragao, Rato, Tigre, ", true))   return Jutsu_CastByID(playerid, JID_DOROJIGOKU, targetid);

    // Raiton (1..3)
    if (!strcmp(canon, "Rato, ", true))                  return Jutsu_CastByID(playerid, JID_ARASHI_I, targetid);
    if (!strcmp(canon, "Rato, Coelho, ", true))          return Jutsu_CastByID(playerid, JID_RAIKYUU, targetid);
    if (!strcmp(canon, "Rato, Coelho, Dragao, ", true))  return Jutsu_CastByID(playerid, JID_NAGASHI, targetid);

    return 1;
}
}

    return Jutsu_CastBySelos(playerid, selos);
}



#endif // _SHRP_SELOS_INCLUDED