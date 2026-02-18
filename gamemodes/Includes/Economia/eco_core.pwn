#if defined _ECO_CORE_INCLUDED
    #endinput
#endif
#define _ECO_CORE_INCLUDED

// ============================================
// SHRP - Economia Core (Impostos/Embargo/Alianca/Paz)
// Arquivo: Includes/Economia/eco_core.pwn (ANSI)
// ============================================
#include <a_samp>

#define ECO_FILE                "shrp_eco.cfg"
#define ECO_MAX_VILAS           (6) // 0..5

#define ECO_VILA_NONE           (0)
#define ECO_VILA_KONOHA         (1)
#define ECO_VILA_SUNA           (2)
#define ECO_VILA_KIRI           (3)
#define ECO_VILA_IWA            (4)
#define ECO_VILA_KUMO           (5)

#define ECO_TAX_PEACE_BASECAP   (10) // fallback (nao usado quando cap por vila)
#define ECO_TAX_WAR_BASECAP     (40) // fallback (nao usado quando cap por vila)
#define ECO_TAX_CAP_MAX         (60) // hard cap
#define ECO_POWER_DIV           (10) // +1% cap por 10 de poder

#define ECO_CHARGE_BOUGHT       (1)  // usa Bought() (gametext/som)
#define ECO_CHARGE_CASH         (2)  // usa GivePlayerCash() (silencioso)

new gEcoTaxPeace[ECO_MAX_VILAS];
new gEcoTaxWar[ECO_MAX_VILAS];
new gEcoPower[ECO_MAX_VILAS];
new gEcoTreasury[ECO_MAX_VILAS];

new bool:gEcoEmbargo[ECO_MAX_VILAS][ECO_MAX_VILAS];
new bool:gEcoAlliance[ECO_MAX_VILAS][ECO_MAX_VILAS];

// pedidos (por vila-alvo)
new gEcoReqAllyFrom[ECO_MAX_VILAS];
new gEcoReqPeaceFrom[ECO_MAX_VILAS];

// ======= Caps por vila (vira cap por categoria quando categoria = vila dona)
// Ajuste aqui os caps base:
// - Comida = Kiri: paz menor, guerra baixa
// - Armas = Iwa: paz maior, guerra maior
new const gEcoPeaceBaseCapByVila[ECO_MAX_VILAS] =
{
    0,  // NONE
    10, // KONOHA
    10, // SUNA
    10, // KIRI  (COMIDA)
    20, // IWA   (ARMAS)
    15  // KUMO  (MEIO TERMO / util)
};

new const gEcoWarBaseCapByVila[ECO_MAX_VILAS] =
{
    0,  // NONE
    40, // KONOHA
    40, // SUNA
    15, // KIRI  (COMIDA)
    30, // IWA   (ARMAS)
    25  // KUMO  (MEIO TERMO / util)
};

// ======= Dependencias do seu GM (ja existem no SHRP)
forward IsVillagesAtWar(v1, v2);

// Se voce ja tem esses colors no GM, otimo. Se nao tiver, comente.
#if !defined COLOR_GRAD2
    #define COLOR_GRAD2 0xB4B5B7FF
#endif
#if !defined COLOR_LIGHTBLUE
    #define COLOR_LIGHTBLUE 0x33CCFFFF
#endif
#if !defined COLOR_GREEN
    #define COLOR_GREEN 0x33AA33FF
#endif
#if !defined COLOR_RED
    #define COLOR_RED 0xAA3333FF
#endif

// ============================================
// Helpers
// ============================================
stock Eco_IsValidVila(v)
{
    return (v > 0 && v < ECO_MAX_VILAS);
}



// ============================================================
// Tesouro da vila (Economia)
// - Profissoes e outros sistemas podem depositar aqui.
// - Valores sao salvos/carregados junto do eco_core.
// ============================================================
stock Eco_AddTreasury(vila, amount)
{
    if(amount <= 0) return 0;
    if(!Eco_IsValidVila(vila)) return 0;
    gEcoTreasury[vila] += amount;
    return 1;
}

stock Eco_GetTreasury(vila)
{
    if(!Eco_IsValidVila(vila)) return 0;
    return gEcoTreasury[vila];
}
stock Eco_GetVilaName(vila, name[], size)
{
    switch(vila)
    {
        case ECO_VILA_KONOHA: format(name, size, "KONOHA");
        case ECO_VILA_SUNA:   format(name, size, "SUNA");
        case ECO_VILA_KIRI:   format(name, size, "KIRIGAKURE");
        case ECO_VILA_IWA:    format(name, size, "IWAGAKURE");
        case ECO_VILA_KUMO:   format(name, size, "KUMOGAKURE");
        default:              format(name, size, "SEM");
    }
    return 1;
}

// No seu registro, pMember e a vila (ex.: 1 e 3).
stock Eco_GetPlayerVila(playerid)
{
    new v = Info[playerid][pMember];
    if(!Eco_IsValidVila(v)) return ECO_VILA_NONE;
    return v;
}

// No seu sistema de guerra, pKage define vila do kage (1->IWA 2->KIRI 3->KUMO).
stock Eco_GetKageVilaFromPlayer(playerid)
{
    switch(Info[playerid][pKage])
    {
        case 1: return ECO_VILA_IWA;
        case 2: return ECO_VILA_KIRI;
        case 3: return ECO_VILA_KUMO;
    }
    return ECO_VILA_NONE;
}

stock bool:Eco_IsPlayerKage(playerid)
{
    return (Eco_GetKageVilaFromPlayer(playerid) != ECO_VILA_NONE);
}

// ======= CAP POR VILA (paz/guerra) + bonus por poder =======
stock Eco_GetTaxCap(vila, bool:war)
{
    if(!Eco_IsValidVila(vila)) return 0;

    new cap = war ? gEcoWarBaseCapByVila[vila] : gEcoPeaceBaseCapByVila[vila];

    // bonus por poder (mantem sua regra)
    cap += (gEcoPower[vila] / ECO_POWER_DIV);

    if(cap > ECO_TAX_CAP_MAX) cap = ECO_TAX_CAP_MAX;
    if(cap < 0) cap = 0;
    return cap;
}

stock bool:Eco_IsEmbargoed(ownerVila, buyerVila)
{
    if(!Eco_IsValidVila(ownerVila) || !Eco_IsValidVila(buyerVila)) return false;
    return gEcoEmbargo[ownerVila][buyerVila];
}

stock bool:Eco_IsAllied(a, b)
{
    if(!Eco_IsValidVila(a) || !Eco_IsValidVila(b) || a == b) return false;
    return gEcoAlliance[a][b];
}

// ============================================
// Persistencia simples
// ============================================
stock EcoCore_SetDefaults()
{
    for(new v=0; v<ECO_MAX_VILAS; v++)
    {
        gEcoTaxPeace[v] = 5;
        gEcoTaxWar[v]   = 12;
        gEcoPower[v]    = 0;
        gEcoTreasury[v] = 0;

        gEcoReqAllyFrom[v] = 0;
        gEcoReqPeaceFrom[v] = 0;

        for(new u=0; u<ECO_MAX_VILAS; u++)
        {
            gEcoEmbargo[v][u] = false;
            gEcoAlliance[v][u] = false;
        }
    }
    return 1;
}

stock EcoCore_Load()
{
    EcoCore_SetDefaults();

    new File:f = fopen(ECO_FILE, io_read);
    if(!f) return 0;

    new line[128];
    while(fread(f, line))
    {
        if(line[0] == ';' || line[0] == '/' || line[0] == '\0') continue;

        new cmd[16], a, b, c;
        cmd[0] = '\0';

        if(sscanf(line, "s[16]ddd", cmd, a, b, c)) continue;

        if(!strcmp(cmd, "TAXP", true) && Eco_IsValidVila(a)) gEcoTaxPeace[a] = b;
        else if(!strcmp(cmd, "TAXW", true) && Eco_IsValidVila(a)) gEcoTaxWar[a] = b;
        else if(!strcmp(cmd, "POWER", true) && Eco_IsValidVila(a)) gEcoPower[a] = b;
        else if(!strcmp(cmd, "TREAS", true) && Eco_IsValidVila(a)) gEcoTreasury[a] = b;
        else if(!strcmp(cmd, "EMB", true) && Eco_IsValidVila(a) && Eco_IsValidVila(b)) gEcoEmbargo[a][b] = (c != 0);
        else if(!strcmp(cmd, "ALLY", true) && Eco_IsValidVila(a) && Eco_IsValidVila(b)) gEcoAlliance[a][b] = (c != 0);
    }

    fclose(f);
    return 1;
}

stock EcoCore_Save()
{
    new File:f = fopen(ECO_FILE, io_write);
    if(!f) return 0;

    fwrite(f, "; SHRP eco - formato:\n");
    fwrite(f, "; TAXP vila pct\n");
    fwrite(f, "; TAXW vila pct\n");
    fwrite(f, "; POWER vila value\n");
    fwrite(f, "; TREAS vila value\n");
    fwrite(f, "; EMB owner buyer on(0/1)\n");
    fwrite(f, "; ALLY a b on(0/1)\n");

    new out[128];

    for(new v=1; v<ECO_MAX_VILAS; v++)
    {
        format(out, sizeof(out), "TAXP %d %d 0\n", v, gEcoTaxPeace[v]); fwrite(f, out);
        format(out, sizeof(out), "TAXW %d %d 0\n", v, gEcoTaxWar[v]);   fwrite(f, out);
        format(out, sizeof(out), "POWER %d %d 0\n", v, gEcoPower[v]);   fwrite(f, out);
        format(out, sizeof(out), "TREAS %d %d 0\n", v, gEcoTreasury[v]); fwrite(f, out);
    }

    for(new a=1; a<ECO_MAX_VILAS; a++)
    {
        for(new b=1; b<ECO_MAX_VILAS; b++)
        {
            if(a == b) continue;

            if(gEcoEmbargo[a][b])
            {
                format(out, sizeof(out), "EMB %d %d 1\n", a, b); fwrite(f, out);
            }
            if(gEcoAlliance[a][b])
            {
                format(out, sizeof(out), "ALLY %d %d 1\n", a, b); fwrite(f, out);
            }
        }
    }

    fclose(f);
    return 1;
}

stock EcoCore_OnGameModeInit() { return EcoCore_Load(); }
stock EcoCore_OnGameModeExit() { return EcoCore_Save(); }

// ============================================
// Cobranca com imposto (core)
// ============================================
stock Eco_PreviewTotal(playerid, ownerVila, basePrice, &outTax, &outPct, &outTotal)
{
    outTax = 0;
    outPct = 0;
    outTotal = basePrice;

    if(basePrice <= 0) return 1;

    if(!Eco_IsValidVila(ownerVila)) ownerVila = ECO_VILA_NONE;

    new buyerVila = Eco_GetPlayerVila(playerid);

    // Sem vila / mesma vila / dono "SEM": sem imposto
    if(!Eco_IsValidVila(buyerVila) || ownerVila == ECO_VILA_NONE || buyerVila == ownerVila)
        return 1;

    // Embargo: bloqueia compra (no menu deve aparecer "BLOQUEADO")
    if(gEcoEmbargo[ownerVila][buyerVila])
    {
        outTotal = -1;
        return 1;
    }

    // Paz x Guerra + cap (mesma regra da compra real)
    new bool:war = (IsVillagesAtWar(ownerVila, buyerVila) != 0);
    outPct = war ? gEcoTaxWar[ownerVila] : gEcoTaxPeace[ownerVila];

    new cap = Eco_GetTaxCap(ownerVila, war);
    if(outPct > cap) outPct = cap;
    if(outPct < 0) outPct = 0;

    // Aliados: -5%
    if(Eco_IsAllied(ownerVila, buyerVila))
    {
        outPct -= 5;
        if(outPct < 0) outPct = 0;
    }

    outTax = (basePrice * outPct) / 100;
    outTotal = basePrice + outTax;
    return 1;
}


stock bool:Eco_TakeMoneyWithTax(playerid, ownerVila, basePrice, chargeMode, &outTax, &outPct, &outTotal)
{
    outTax = 0;
    outPct = 0;
    outTotal = basePrice;

    if(basePrice <= 0) return false;
    if(!Eco_IsValidVila(ownerVila)) ownerVila = ECO_VILA_NONE;

    new buyerVila = Eco_GetPlayerVila(playerid);
    if(!Eco_IsValidVila(buyerVila) || ownerVila == ECO_VILA_NONE || buyerVila == ownerVila)
    {
        if(!CheckMoney(playerid, basePrice)) return false;
        if(chargeMode == ECO_CHARGE_BOUGHT) Bought(playerid, basePrice);
        else GivePlayerCash(playerid, -basePrice);
        return true;
    }

    if(Eco_IsEmbargoed(ownerVila, buyerVila))
    {
        new oName[16]; Eco_GetVilaName(ownerVila, oName, sizeof oName);
        new msg[144];
        format(msg, sizeof msg, "(Economia) Compra negada: %s esta com embargo contra sua vila.", oName);
        SendClientMessage(playerid, COLOR_RED, msg);
        return false;
    }

    new bool:war = (IsVillagesAtWar(ownerVila, buyerVila) != 0);
    outPct = war ? gEcoTaxWar[ownerVila] : gEcoTaxPeace[ownerVila];

    new cap = Eco_GetTaxCap(ownerVila, war);
    if(outPct > cap) outPct = cap;
    if(outPct < 0) outPct = 0;

    if(Eco_IsAllied(ownerVila, buyerVila))
    {
        outPct -= 5;
        if(outPct < 0) outPct = 0;
    }

    outTax = (basePrice * outPct) / 100;
    outTotal = basePrice + outTax;

    if(!CheckMoney(playerid, outTotal)) return false;

    if(chargeMode == ECO_CHARGE_BOUGHT) Bought(playerid, outTotal);
    else GivePlayerCash(playerid, -outTotal);

    gEcoTreasury[ownerVila] += outTax;
    return true;
}

stock Eco_PrintTax(playerid, ownerVila, basePrice, taxPaid, pct, totalPaid)
{
    if(!Eco_IsValidVila(ownerVila)) return 0;

    new vName[16];
    Eco_GetVilaName(ownerVila, vName, sizeof vName);

    // Chat "de player": mostra quanto saiu de imposto e a %.
    // Importante: NO mostra o quanto a vila tem no tesouro (isso fica s nos comandos do Kage).
    new msg[160];
    format(msg, sizeof msg,
        "{B9FFB9}[ECONOMIA]{FFFFFF} Loja de {A2D7FF}%s{FFFFFF} | Base: {FFFF99}%d{FFFFFF} | Imposto: {FFCC66}%d{FFFFFF} ({FFCC66}%d%%{FFFFFF}) | Total: {FFFF99}%d",
        vName,
        basePrice,
        taxPaid,
        pct,
        totalPaid
    );
    SendClientMessage(playerid, -1, msg);
    return 1;
}


// ============================================
// Comandos (Kage)
// ============================================
CMD:eco(playerid, params[])
{
    new v = Eco_GetKageVilaFromPlayer(playerid);
    if(v == ECO_VILA_NONE) return SendClientMessage(playerid, COLOR_GRAD2, "(Economia) Somente Kage.");

    new n[16]; Eco_GetVilaName(v, n, sizeof n);

    new msg[144];
    format(msg, sizeof msg, "=== ECONOMIA %s ===", n);
    SendClientMessage(playerid, COLOR_GREEN, msg);

    format(msg, sizeof msg, "Imposto Paz: %d%% | Imposto Guerra: %d%% | Poder: %d | Caixa: %d",
        gEcoTaxPeace[v], gEcoTaxWar[v], gEcoPower[v], gEcoTreasury[v]
    );
    SendClientMessage(playerid, COLOR_GREEN, msg);
    return 1;
}

CMD:imposto(playerid, params[])
{
    new v = Eco_GetKageVilaFromPlayer(playerid);
    if(v == ECO_VILA_NONE) return SendClientMessage(playerid, COLOR_GRAD2, "(Economia) Somente Kage.");

    new pct;
    if(sscanf(params, "d", pct)) return SendClientMessage(playerid, COLOR_GRAD2, "Uso: /imposto [0..cap]");

    new cap = Eco_GetTaxCap(v, false);
    if(pct < 0) pct = 0;
    if(pct > cap) pct = cap;

    gEcoTaxPeace[v] = pct;
    EcoCore_Save();

    new msg[144];
    format(msg, sizeof msg, "(Economia) Imposto de PAZ ajustado para %d%% (cap atual %d%%).", pct, cap);
    SendClientMessage(playerid, COLOR_GREEN, msg);
    return 1;
}

CMD:impostoguerra(playerid, params[])
{
    new v = Eco_GetKageVilaFromPlayer(playerid);
    if(v == ECO_VILA_NONE) return SendClientMessage(playerid, COLOR_GRAD2, "(Economia) Somente Kage.");

    new pct;
    if(sscanf(params, "d", pct)) return SendClientMessage(playerid, COLOR_GRAD2, "Uso: /impostoguerra [0..cap]");

    new cap = Eco_GetTaxCap(v, true);
    if(pct < 0) pct = 0;
    if(pct > cap) pct = cap;

    gEcoTaxWar[v] = pct;
    EcoCore_Save();

    new msg[144];
    format(msg, sizeof msg, "(Economia) Imposto de GUERRA ajustado para %d%% (cap atual %d%%).", pct, cap);
    SendClientMessage(playerid, COLOR_GREEN, msg);
    return 1;
}

CMD:embargo(playerid, params[])
{
    new myV = Eco_GetKageVilaFromPlayer(playerid);
    if(myV == ECO_VILA_NONE) return SendClientMessage(playerid, COLOR_GRAD2, "(Economia) Somente Kage.");

    new targetV;
    if(sscanf(params, "d", targetV)) return SendClientMessage(playerid, COLOR_GRAD2, "Uso: /embargo [vilaId 1..5]");

    if(!Eco_IsValidVila(targetV) || targetV == myV) return SendClientMessage(playerid, COLOR_GRAD2, "(Economia) Vila invalida.");

    gEcoEmbargo[myV][targetV] = !gEcoEmbargo[myV][targetV];
    EcoCore_Save();

    new tName[16]; Eco_GetVilaName(targetV, tName, sizeof tName);

    new msg[144];
    format(msg, sizeof msg, "(Economia) Embargo contra %s: %s", tName, gEcoEmbargo[myV][targetV] ? ("ATIVO") : ("DESATIVADO"));
    SendClientMessage(playerid, COLOR_GREEN, msg);
    return 1;
}

CMD:ecopoder(playerid, params[])
{
    new myV = Eco_GetKageVilaFromPlayer(playerid);
    if(myV == ECO_VILA_NONE) return SendClientMessage(playerid, COLOR_GRAD2, "(Economia) Somente Kage.");

    new val;
    if(sscanf(params, "d", val)) return SendClientMessage(playerid, COLOR_GRAD2, "Uso: /ecopoder [0..100]");

    if(val < 0) val = 0;
    if(val > 100) val = 100;

    gEcoPower[myV] = val;
    EcoCore_Save();

    new msg[160];
    format(msg, sizeof msg,
        "(Economia) Poder economico ajustado para %d. (cap paz %d%% | cap guerra %d%%)",
        val, Eco_GetTaxCap(myV, false), Eco_GetTaxCap(myV, true)
    );
    SendClientMessage(playerid, COLOR_GREEN, msg);
    return 1;
}