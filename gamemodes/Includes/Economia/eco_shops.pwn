#if defined _ECO_SHOPS_INCLUDED
    #endinput
#endif
#define _ECO_SHOPS_INCLUDED

// ============================================
// SHRP - Economia Shops (aplica imposto nos dialogs)
// Arquivo: Includes/Economia/eco_shops.pwn (ANSI)
// ============================================

// Donos (edite como quiser)
#define ECO_OWNER_GAS    (ECO_VILA_KONOHA)
#define ECO_OWNER_ELEC   (ECO_VILA_KUMO)

stock Eco_AddLinePrice(playerid, ownerVila, const itemName[], basePrice, dest[], destSize)
{
    new tax, pct, total;
    Eco_PreviewTotal(playerid, ownerVila, basePrice, tax, pct, total);

    new totalStr[24];
    if(total < 0) format(totalStr, sizeof totalStr, "{FF3333}BLOQUEADO");
    else format(totalStr, sizeof totalStr, "%d", total);

    new line[128];
    format(line, sizeof line, "%s\t%d\t%s\n", itemName, basePrice, totalStr);
    strcat(dest, line, destSize);
    return 1;
}


stock EcoIchiraku_Show(playerid, ownerVila, dialogid, const title[])
{
    new list[512];
    list[0] = '\0';

    // Mostra BASE e TOTAL (BASE + IMPOSTO) antes de comprar
    strcat(list, "{E9FE23}Comida\t{E9FE23}Base\t{E9FE23}Total\n", sizeof list);

    Eco_AddLinePrice(playerid, ownerVila, "Nigiri Sushi", 30, list, sizeof list);
    Eco_AddLinePrice(playerid, ownerVila, "Ramen",        40, list, sizeof list);
    Eco_AddLinePrice(playerid, ownerVila, "Onigiri",      40, list, sizeof list);

    ShowPlayerDialog(playerid, dialogid, DIALOG_STYLE_TABLIST_HEADERS, title, list, "Comprar", "Sair");
    return 1;
}




// Se voce quiser depois: AMMU = IWA, ICHIRAKU = KIRI, etc.


stock bool:EcoShops_OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(!response) return false;

    // ===== TIENDA_GAS (570)
    #if defined TIENDA_GAS
    if(dialogid == TIENDA_GAS)
    {
        // Repare: no GM original ele usa GivePlayerCash(-preco). 
        new basePrice = 0;

        switch(listitem)
        {
            case 0: basePrice = 70;   // agua
            case 1: basePrice = 150;  // gasolina
            case 2: basePrice = 20;   // celular
            case 3: basePrice = 40;   // cigarro
            case 4: basePrice = 20;   // mechero
            default: return true;
        }

        new tax, pct, totalPaid;
        if(!Eco_TakeMoneyWithTax(playerid, ECO_OWNER_GAS, basePrice, ECO_CHARGE_CASH, tax, pct, totalPaid)) return true;

        // mantem o efeito original (so o que e seguro aqui)
        if(listitem == 0) { PlayerPlaySound(playerid, 1052, 0.0, 0.0, 0.0); SetPlayerHealth(playerid, 100.0); }
        if(listitem == 1) { PlayerPlaySound(playerid, 1052, 0.0, 0.0, 0.0); SetPlayerSpecialAction(playerid, SPECIAL_ACTION_CARRY); SetPVarInt(playerid, "gas", 2); }
        if(listitem == 2) { PlayerPlaySound(playerid, 1052, 0.0, 0.0, 0.0); /* No seu GM ele da Mobil[] = 1, mas essa var nao ta aqui. */ }
        if(listitem == 3) { PlayerPlaySound(playerid, 1052, 0.0, 0.0, 0.0); SetPlayerSpecialAction(playerid, SPECIAL_ACTION_SMOKE_CIGGY); }
        if(listitem == 4) { PlayerPlaySound(playerid, 1052, 0.0, 0.0, 0.0); /* IsPlayerSmoking[playerid] = 0; (se existir no seu GM) */ }

        Eco_PrintTax(playerid, ECO_OWNER_GAS, basePrice, tax, pct, totalPaid);
        return true;
    }
    #endif

    // ===== TIENDA_ELEC (551)
    #if defined TIENDA_ELEC
    if(dialogid == TIENDA_ELEC)
    {
        // Aqui seguimos os precos que o GM realmente cobra via Bought(). 
        new basePrice = 0;

        // Acesso ao seu enum Info[]:

        switch(listitem)
        {
            case 1: // agenda (libreta) 200
            {
                if(Info[playerid][pLibreta] == 1) return SendClientMessageEx(playerid, COLOR_GRAD2, "(Erro) Ja tens uma agenda.");
                basePrice = 200;

                new tax, pct, totalPaid;
                if(!Eco_TakeMoneyWithTax(playerid, ECO_OWNER_ELEC, basePrice, ECO_CHARGE_BOUGHT, tax, pct, totalPaid)) return true;

                Info[playerid][pLibreta] = 1;
                Info[playerid][pNumeroLibreta1] = 1;
                Info[playerid][pNumeroLibreta2] = 2;
                Info[playerid][pNumeroLibreta3] = 3;
                Info[playerid][pNumeroLibreta4] = 4;
                Info[playerid][pNumeroLibreta5] = 5;

                Eco_PrintTax(playerid, ECO_OWNER_ELEC, basePrice, tax, pct, totalPaid);
                return true;
            }
            case 2: // phonebook 150
            {
                if(Info[playerid][pPhoneBook] == 1) return SendClientMessageEx(playerid, COLOR_GRAD2, "(Erro) Ja tens um Phonebook.");
                basePrice = 150;

                new tax, pct, totalPaid;
                if(!Eco_TakeMoneyWithTax(playerid, ECO_OWNER_ELEC, basePrice, ECO_CHARGE_BOUGHT, tax, pct, totalPaid)) return true;

                Info[playerid][pPhoneBook] = 1;
                Eco_PrintTax(playerid, ECO_OWNER_ELEC, basePrice, tax, pct, totalPaid);
                return true;
            }
            case 3: // camera 120
            {
                basePrice = 120;

                new tax, pct, totalPaid;
                if(!Eco_TakeMoneyWithTax(playerid, ECO_OWNER_ELEC, basePrice, ECO_CHARGE_BOUGHT, tax, pct, totalPaid)) return true;

                // No GM ele seta pPhoneBook de novo (bug antigo). Mantive o efeito so como placeholder.
                // Se voce tiver variavel real de camera, troca aqui.
                Eco_PrintTax(playerid, ECO_OWNER_ELEC, basePrice, tax, pct, totalPaid);
                return true;
            }
            case 4: // radio 800
            {
                if(Info[playerid][pRadio] == 1) return SendClientMessageEx(playerid, COLOR_GRAD2, "(Erro) Ja tens uma Radio.");
                basePrice = 800;

                new tax, pct, totalPaid;
                if(!Eco_TakeMoneyWithTax(playerid, ECO_OWNER_ELEC, basePrice, ECO_CHARGE_BOUGHT, tax, pct, totalPaid)) return true;

                Info[playerid][pRadio] = 1;
                Info[playerid][pRadioFreq] = 0;

                Eco_PrintTax(playerid, ECO_OWNER_ELEC, basePrice, tax, pct, totalPaid);
                return true;
            }
        }
        return true;
    }
    #endif

	// ===== ICHIRAKU (comida) =====
#if defined DIALOG_ICHIRAKUI
if(dialogid == DIALOG_ICHIRAKUI) // Ichiraku de Iwagakure
{
    new basePrice = 0;
    switch(listitem)
    {
        case 0: basePrice = 30;
        case 1: basePrice = 40;
        case 2: basePrice = 40;
        default: return true;
    }

    new tax, pct, totalPaid;
    if(!Eco_TakeMoneyWithTax(playerid, ECO_OWNER_COMIDA, basePrice, ECO_CHARGE_BOUGHT, tax, pct, totalPaid)) return true;

    // entrega dos itens (igual seu GM fazia)
    if(listitem == 0) GivePlayerItemEx(playerid, 5, 1);
    if(listitem == 1) GivePlayerItemEx(playerid, 6, 1);
    if(listitem == 2) GivePlayerItemEx(playerid, 54, 1);

    PlayerPlaySound(playerid, 1052, 0.0, 0.0, 0.0);
    Eco_PrintTax(playerid, ECO_OWNER_COMIDA, basePrice, tax, pct, totalPaid);
    return true;
}

#if defined DIALOG_ICHIRAKUK
if(dialogid == DIALOG_ICHIRAKUK) // Ichiraku de Kirigakure
{
    new basePrice = 0;
    switch(listitem)
    {
        case 0: basePrice = 30;
        case 1: basePrice = 40;
        case 2: basePrice = 40;
        default: return true;
    }

    new tax, pct, totalPaid;
    if(!Eco_TakeMoneyWithTax(playerid, ECO_OWNER_COMIDA, basePrice, ECO_CHARGE_BOUGHT, tax, pct, totalPaid)) return true;

    if(listitem == 0) GivePlayerItemEx(playerid, 5, 1);
    if(listitem == 1) GivePlayerItemEx(playerid, 6, 1);
    if(listitem == 2) GivePlayerItemEx(playerid, 54, 1);

    PlayerPlaySound(playerid, 1052, 0.0, 0.0, 0.0);
    Eco_PrintTax(playerid, ECO_OWNER_COMIDA, basePrice, tax, pct, totalPaid);
    return true;
}
#endif


    return false;
}