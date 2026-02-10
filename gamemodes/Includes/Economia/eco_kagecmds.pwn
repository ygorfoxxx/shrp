#if defined _ECO_KAGECMDS_INCLUDED
    #endinput
#endif
#define _ECO_KAGECMDS_INCLUDED


// ============================================
// SHRP - Economia (Comandos Kage - aliases)
// Arquivo: Includes/Economia/eco_kagecmds.pwn (ANSI)
// ============================================
//
// IMPORTANTE:
// - Este arquivo original estava apontando para símbolos que NÃO existem no eco_core (EcoVilaName, EcoTaxPeace[][], Eco_Save(), etc).
// - Aqui eu transformei os comandos "/kage*" em *aliases* do modelo real do eco_core_fixed:
//      * imposto de paz é por VILA (gEcoTaxPeace[vila])
//      * imposto de guerra é por VILA (gEcoTaxWar[vila])
//      * embargo e alianca são matrizes 2D (gEcoEmbargo / gEcoAlliance)
//
// Se você quiser no futuro imposto "por-alvo" (my->target), aí sim teria que mudar o core para 2D.

#include "Includes/Economia/eco_core.pwn"


// ------------------------------------------------------------
// Helpers internos
// ------------------------------------------------------------

static stock EcoKage_GetMyVila(playerid)
{
    return Eco_GetKageVilaFromPlayer(playerid);
}

static stock EcoKage_SendUsage(playerid)
{
    SendClientMessageEx(playerid, COLOR_GRAD2, "Economia Kage: /ecostatus /kagetax /kagewarbonus /kageembargo /kagealianca");
    SendClientMessageEx(playerid, COLOR_GRAD2, "Dica: /kagetax e /kagewarbonus aceitam: /kagetax <pct>  OU  /kagetax <vilaId> <pct> (vilaId é ignorado).");
    return 1;
}

#if defined CMD

// /ecostatus  (status da sua vila)
CMD:ecostatus(playerid, params[])
{
    #pragma unused params

    new myV = EcoKage_GetMyVila(playerid);
    if(myV == ECO_VILA_NONE) return SendClientMessage(playerid, COLOR_GRAD2, "(Economia) Somente Kage.");

    new n[16]; Eco_GetVilaName(myV, n, sizeof n);

    new msg[160];

    format(msg, sizeof msg, "=== ECONOMIA %s ===", n);
    SendClientMessage(playerid, COLOR_GREEN, msg);

    format(msg, sizeof msg,
        "Imposto Paz: %d%% (cap %d%%) | Imposto Guerra: %d%% (cap %d%%)",
        gEcoTaxPeace[myV], Eco_GetTaxCap(myV, false),
        gEcoTaxWar[myV],   Eco_GetTaxCap(myV, true)
    );
    SendClientMessage(playerid, COLOR_GREEN, msg);

    format(msg, sizeof msg, "Poder: %d | Tesouro: %d", gEcoPower[myV], gEcoTreasury[myV]);
    SendClientMessage(playerid, COLOR_GREEN, msg);

    EcoKage_SendUsage(playerid);
    return 1;
}

// /kagetax <pct>   OU   /kagetax <vilaId> <pct>
CMD:kagetax(playerid, params[])
{
    new myV = EcoKage_GetMyVila(playerid);
    if(myV == ECO_VILA_NONE) return SendClientMessage(playerid, COLOR_GRAD2, "(Economia) Somente Kage.");

    new pct, dummy;

    // Compat: aceita dois params (vilaId pct), mas aqui o imposto é DA SUA VILA, então vilaId é ignorado.
    if(sscanf(params, "dd", dummy, pct))
    {
        if(sscanf(params, "d", pct))
            return SendClientMessage(playerid, COLOR_GRAD2, "Uso: /kagetax <pct>  OU  /kagetax <vilaId> <pct>");
    }

    new cap = Eco_GetTaxCap(myV, false);
    if(pct < 0) pct = 0;
    if(pct > cap) pct = cap;

    gEcoTaxPeace[myV] = pct;
    EcoCore_Save();

    new msg[160];
    format(msg, sizeof msg, "(Economia) Imposto de PAZ ajustado para %d%% (cap %d%%).", pct, cap);
    SendClientMessage(playerid, COLOR_GREEN, msg);
    return 1;
}

// /kagewarbonus <pct>  OU  /kagewarbonus <vilaId> <pct>
// (No core não existe "bonus" separado; aqui isso ajusta o imposto base de GUERRA da sua vila)
CMD:kagewarbonus(playerid, params[])
{
    new myV = EcoKage_GetMyVila(playerid);
    if(myV == ECO_VILA_NONE) return SendClientMessage(playerid, COLOR_GRAD2, "(Economia) Somente Kage.");

    new pct, dummy;
    if(sscanf(params, "dd", dummy, pct))
    {
        if(sscanf(params, "d", pct))
            return SendClientMessage(playerid, COLOR_GRAD2, "Uso: /kagewarbonus <pct>  OU  /kagewarbonus <vilaId> <pct>");
    }

    new cap = Eco_GetTaxCap(myV, true);
    if(pct < 0) pct = 0;
    if(pct > cap) pct = cap;

    gEcoTaxWar[myV] = pct;
    EcoCore_Save();

    new msg[160];
    format(msg, sizeof msg, "(Economia) Imposto de GUERRA ajustado para %d%% (cap %d%%).", pct, cap);
    SendClientMessage(playerid, COLOR_GREEN, msg);
    return 1;
}

// /kageembargo <vilaId>  (toggle embargo contra outra vila)
CMD:kageembargo(playerid, params[])
{
    new myV = EcoKage_GetMyVila(playerid);
    if(myV == ECO_VILA_NONE) return SendClientMessage(playerid, COLOR_GRAD2, "(Economia) Somente Kage.");

    new targetV;
    if(sscanf(params, "d", targetV)) return SendClientMessage(playerid, COLOR_GRAD2, "Uso: /kageembargo <vilaId 1..5>");
    if(!Eco_IsValidVila(targetV) || targetV == myV) return SendClientMessage(playerid, COLOR_GRAD2, "(Economia) Vila inválida.");

    gEcoEmbargo[myV][targetV] = !gEcoEmbargo[myV][targetV];
    EcoCore_Save();

    new tName[16]; Eco_GetVilaName(targetV, tName, sizeof tName);

    new msg[160];
    format(msg, sizeof msg, "(Economia) Embargo contra %s: %s",
        tName,
        gEcoEmbargo[myV][targetV] ? ("ATIVO") : ("DESATIVADO")
    );
    SendClientMessage(playerid, COLOR_GREEN, msg);
    return 1;
}

// /kagealianca <vilaId>  (toggle aliança)
CMD:kagealianca(playerid, params[])
{
    new myV = EcoKage_GetMyVila(playerid);
    if(myV == ECO_VILA_NONE) return SendClientMessage(playerid, COLOR_GRAD2, "(Economia) Somente Kage.");

    new targetV;
    if(sscanf(params, "d", targetV)) return SendClientMessage(playerid, COLOR_GRAD2, "Uso: /kagealianca <vilaId 1..5>");
    if(!Eco_IsValidVila(targetV) || targetV == myV) return SendClientMessage(playerid, COLOR_GRAD2, "(Economia) Vila inválida.");

    new bool:on = !gEcoAlliance[myV][targetV];

    // aliança é sempre dupla
    gEcoAlliance[myV][targetV] = on;
    gEcoAlliance[targetV][myV] = on;

    EcoCore_Save();

    new tName[16]; Eco_GetVilaName(targetV, tName, sizeof tName);
    new myName[16]; Eco_GetVilaName(myV, myName, sizeof myName);

    new msg[160];
    format(msg, sizeof msg, "(Economia) Aliança %s <-> %s: %s",
        myName, tName, on ? ("ATIVA") : ("DESATIVADA")
    );
    SendClientMessage(playerid, COLOR_GREEN, msg);

    SendClientMessage(playerid, COLOR_GREEN, "Obs: aliado reduz 5% do imposto automaticamente (ver Eco_TakeMoneyWithTax).");
    return 1;
}

#endif // CMD