//INCLUDES
#include <a_samp>
#include <zcmd>
#include <dof2>
//INCLUDES END//
//DEFINES//
#define                 PASTA_INVENTARIO			"INVENTARIO/%s.ini"
#define 				MAX_INVENTORY_SLOTS			20
//DEFINES END//
//ENUM//
enum enum_Itens
{
    item_id,
    item_tipo,
    item_modelo,
    item_nome[24],
    item_limite,
    bool:item_canbedropped,
    Float:item_previewrot[4],
    item_description[200]
}

enum
{
    ITEM_TYPE_WEAPON,
    ITEM_TYPE_HELMET,
    ITEM_TYPE_NORMAL,
    ITEM_TYPE_BODY,
    ITEM_TYPE_AMMO,
    ITEM_TYPE_BACKPACK,
    ITEM_TYPE_MELEEWEAPON
}

enum enum_pInventory
{
    invSlot[MAX_INVENTORY_SLOTS],
    invSelectedSlot,
    invSlotAmount[MAX_INVENTORY_SLOTS],
    Float:invArmourStatus[MAX_INVENTORY_SLOTS]
}
 
enum enum_pCharacter
{
    charSlot[7],
    charSelectedSlot,
    Float:charArmourStatus
}

new Itens[][enum_Itens] =
{
    {0,     ITEM_TYPE_NORMAL,       19382,      "Nada",                 0,          false,      {0.0,0.0,0.0,0.0},                              "N/A"},
};
//ENUM END//
//VARIAVEIS//
new InventarioAberto[MAX_PLAYERS];
//VARIAVEIS END//

public OnGameModeExit()
{
	DOF2_Exit();
	return 1;
}

public OnPlayerConnect(playerid)
{
	InventarioAberto[playerid] = 0;
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	return 1;
}

public OnPlayerSpawn(playerid)
{
	return 1;
}