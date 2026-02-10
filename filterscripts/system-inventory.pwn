// includes

#include    <a_samp>
#include    <a_mysql>

// others-includes

#include    <ZCMD>

// defines

#define     function%0(%1)                      forward %0(%1); public %0(%1)

enum E_PLAYER
{
    ORM:pORM,

    pID,
    pName[MAX_PLAYER_NAME]
}

new PlayerInfo[MAX_PLAYERS][E_PLAYER];

new MySQL:sqlConn;

// modules

#include "..\modules\database.pwn"
#include "..\modules\login.pwn"
#include "..\modules\inventory.pwn"
#include "..\modules\inventory-textdraws.pwn"
#include "..\modules\inventory-commands.pwn"

main()
{}