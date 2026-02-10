//INCLUDES
#include <a_samp>
#include <zcmd>
#include <DOF2>

new Text:InventBackground[9];
new PlayerText:PlayerSlotsInvent[MAX_PLAYERS][33];
new PlayerText:PlayerUsarItem[MAX_PLAYERS][1];
new PlayerText:PlayerSepararItem[MAX_PLAYERS][1];
new PlayerText:PlayerMoverItem[MAX_PLAYERS][1];
new PlayerText:PlayerApagarItem[MAX_PLAYERS][1];


public OnGameModeExit()
{
    DOF2_Exit();
        InventBackground[0] = TextDrawCreate(-40.475830, 0.416684, "Invent:Inventario");
        TextDrawTextSize(InventBackground[0], 647.000000, 414.000000);
        TextDrawAlignment(InventBackground[0], 1);
        TextDrawColor(InventBackground[0], -1);
        TextDrawSetShadow(InventBackground[0], 0);
        TextDrawBackgroundColor(InventBackground[0], 255);
        TextDrawFont(InventBackground[0], 4);
        TextDrawSetProportional(InventBackground[0], 0);

        InventBackground[1] = TextDrawCreate(14.341159, -55.583332, "Invent:Inventarioo");
        TextDrawTextSize(InventBackground[1], 607.000000, 482.000000);
        TextDrawAlignment(InventBackground[1], 1);
        TextDrawColor(InventBackground[1], -1);
        TextDrawSetShadow(InventBackground[1], 0);
        TextDrawBackgroundColor(InventBackground[1], 255);
        TextDrawFont(InventBackground[1], 4);
        TextDrawSetProportional(InventBackground[1], 0);

        InventBackground[2] = TextDrawCreate(11.530033, -73.083343, "Invent:InventarioD");
        TextDrawTextSize(InventBackground[2], 572.000000, 494.000000);
        TextDrawAlignment(InventBackground[2], 1);
        TextDrawColor(InventBackground[2], -1);
        TextDrawSetShadow(InventBackground[2], 0);
        TextDrawBackgroundColor(InventBackground[2], 255);
        TextDrawFont(InventBackground[2], 4);
        TextDrawSetProportional(InventBackground[2], 0);

        InventBackground[3] = TextDrawCreate(333.872772, 386.649993, "Invent:Botao");
        TextDrawTextSize(InventBackground[3], 40.000000, 43.000000);
        TextDrawAlignment(InventBackground[3], 1);
        TextDrawColor(InventBackground[3], -1);
        TextDrawSetShadow(InventBackground[3], 0);
        TextDrawBackgroundColor(InventBackground[3], 255);
        TextDrawFont(InventBackground[3], 4);
        TextDrawSetProportional(InventBackground[3], 0);

        InventBackground[4] = TextDrawCreate(378.382415, 386.066680, "Invent:Botao");
        TextDrawTextSize(InventBackground[4], 40.000000, 43.000000);
        TextDrawAlignment(InventBackground[4], 1);
        TextDrawColor(InventBackground[4], -1);
        TextDrawSetShadow(InventBackground[4], 0);
        TextDrawBackgroundColor(InventBackground[4], 255);
        TextDrawFont(InventBackground[4], 4);
        TextDrawSetProportional(InventBackground[4], 0);

        InventBackground[5] = TextDrawCreate(423.101409, 386.066680, "Invent:Botao");
        TextDrawTextSize(InventBackground[5], 40.000000, 43.000000);
        TextDrawAlignment(InventBackground[5], 1);
        TextDrawColor(InventBackground[5], -1);
        TextDrawSetShadow(InventBackground[5], 0);
        TextDrawBackgroundColor(InventBackground[5], 255);
        TextDrawFont(InventBackground[5], 4);
        TextDrawSetProportional(InventBackground[5], 0);

        InventBackground[6] = TextDrawCreate(467.142517, 385.483306, "Invent:Botao");
        TextDrawTextSize(InventBackground[6], 40.000000, 43.000000);
        TextDrawAlignment(InventBackground[6], 1);
        TextDrawColor(InventBackground[6], -1);
        TextDrawSetShadow(InventBackground[6], 0);
        TextDrawBackgroundColor(InventBackground[6], 255);
        TextDrawFont(InventBackground[6], 4);
        TextDrawSetProportional(InventBackground[6], 0);

        InventBackground[7] = TextDrawCreate(387.284088, 308.999908, "Invent:Botao");
        TextDrawTextSize(InventBackground[7], 42.259956, 40.969837);
        TextDrawAlignment(InventBackground[7], 1);
        TextDrawColor(InventBackground[7], -1);
        TextDrawSetShadow(InventBackground[7], 0);
        TextDrawBackgroundColor(InventBackground[7], 255);
        TextDrawFont(InventBackground[7], 4);
        TextDrawSetProportional(InventBackground[7], 0);

}
public OnPlayerSpawn(playerid)
{
    
    PlayerUsarItem[playerid][0] = CreatePlayerTextDraw(playerid, 353.250427, 402.916778, "Usar");
    PlayerTextDrawLetterSize(playerid, PlayerUsarItem[playerid][0], 0.294114, 1.022499);
    PlayerTextDrawAlignment(playerid, PlayerUsarItem[playerid][0], 2);
    PlayerTextDrawColor(playerid, PlayerUsarItem[playerid][0], -1);
    PlayerTextDrawSetShadow(playerid, PlayerUsarItem[playerid][0], 0);
    PlayerTextDrawBackgroundColor(playerid, PlayerUsarItem[playerid][0], 255);
    PlayerTextDrawFont(playerid, PlayerUsarItem[playerid][0], 1);
    PlayerTextDrawSetProportional(playerid, PlayerUsarItem[playerid][0], 1);
    PlayerTextDrawSetSelectable(playerid, PlayerUsarItem[playerid][0], true);

    PlayerSepararItem[playerid][0] = CreatePlayerTextDraw(playerid, 398.260101, 402.333435, "Separar");
    PlayerTextDrawLetterSize(playerid, PlayerSepararItem[playerid][0], 0.230863, 0.946666);
    PlayerTextDrawAlignment(playerid, PlayerSepararItem[playerid][0], 2);
    PlayerTextDrawColor(playerid, PlayerSepararItem[playerid][0], -1);
    PlayerTextDrawSetShadow(playerid, PlayerSepararItem[playerid][0], 0);
    PlayerTextDrawBackgroundColor(playerid, PlayerSepararItem[playerid][0], 255);
    PlayerTextDrawFont(playerid, PlayerSepararItem[playerid][0], 1);
    PlayerTextDrawSetProportional(playerid, PlayerSepararItem[playerid][0], 1);
    PlayerTextDrawSetSelectable(playerid, PlayerSepararItem[playerid][0], true);

    PlayerMoverItem[playerid][0] = CreatePlayerTextDraw(playerid, 442.769714, 402.333435, "Mover");
    PlayerTextDrawLetterSize(playerid, PlayerMoverItem[playerid][0], 0.230863, 0.946666);
    PlayerTextDrawAlignment(playerid, PlayerMoverItem[playerid][0], 2);
    PlayerTextDrawColor(playerid, PlayerMoverItem[playerid][0], -1);
    PlayerTextDrawSetShadow(playerid, PlayerMoverItem[playerid][0], 0);
    PlayerTextDrawBackgroundColor(playerid, PlayerMoverItem[playerid][0], 255);
    PlayerTextDrawFont(playerid, PlayerMoverItem[playerid][0], 1);
    PlayerTextDrawSetProportional(playerid, PlayerMoverItem[playerid][0], 1);
    PlayerTextDrawSetSelectable(playerid, PlayerMoverItem[playerid][0], true);

    PlayerApagarItem[playerid][0] = CreatePlayerTextDraw(playerid, 487.042358, 401.933410, "Apagar");
    PlayerTextDrawLetterSize(playerid, PlayerApagarItem[playerid][0], 0.230863, 0.946666);
    PlayerTextDrawAlignment(playerid, PlayerApagarItem[playerid][0], 2);
    PlayerTextDrawColor(playerid, PlayerApagarItem[playerid][0], -1);
    PlayerTextDrawSetShadow(playerid, PlayerApagarItem[playerid][0], 0);
    PlayerTextDrawBackgroundColor(playerid, PlayerApagarItem[playerid][0], 255);
    PlayerTextDrawFont(playerid, PlayerApagarItem[playerid][0], 1);
    PlayerTextDrawSetProportional(playerid, PlayerApagarItem[playerid][0], 1);
    PlayerTextDrawSetSelectable(playerid, PlayerApagarItem[playerid][0], true);


        PlayerSlotsInvent[playerid][0] = CreatePlayerTextDraw(playerid, 281.866760, 131.083358, "Invent:Quadrado");
        PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][0], 49.000000, 46.000000);
        PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][0], 1);
        PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][0], -1);
        PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][0], 0);
        PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][0], 255);
        PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][0], 4);
        PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][0], 0);
        PlayerTextDrawSetSelectable(playerid, PlayerSlotsInvent[playerid][0], true);

        PlayerSlotsInvent[playerid][1] = CreatePlayerTextDraw(playerid, 281.835296, 178.933441, "Invent:Quadrado");
        PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][1], 49.000000, 46.000000);
        PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][1], 1);
        PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][1], -1);
        PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][1], 0);
        PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][1], 255);
        PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][1], 4);
        PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][1], 0);
        PlayerTextDrawSetSelectable(playerid, PlayerSlotsInvent[playerid][1], true);

        PlayerSlotsInvent[playerid][2] = CreatePlayerTextDraw(playerid, 281.835266, 226.766769, "Invent:Quadrado");
        PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][2], 49.000000, 46.000000);
        PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][2], 1);
        PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][2], -1);
        PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][2], 0);
        PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][2], 255);
        PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][2], 4);
        PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][2], 0);
        PlayerTextDrawSetSelectable(playerid, PlayerSlotsInvent[playerid][2], true);

        PlayerSlotsInvent[playerid][3] = CreatePlayerTextDraw(playerid, 281.835266, 274.599945, "Invent:Quadrado");
        PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][3], 49.000000, 46.000000);
        PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][3], 1);
        PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][3], -1);
        PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][3], 0);
        PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][3], 255);
        PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][3], 4);
        PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][3], 0);
        PlayerTextDrawSetSelectable(playerid, PlayerSlotsInvent[playerid][3], true);

        PlayerSlotsInvent[playerid][4] = CreatePlayerTextDraw(playerid, 333.372406, 131.099868, "Invent:Quadrado");
        PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][4], 49.000000, 46.000000);
        PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][4], 1);
        PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][4], -1);
        PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][4], 0);
        PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][4], 255);
        PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][4], 4);
        PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][4], 0);
        PlayerTextDrawSetSelectable(playerid, PlayerSlotsInvent[playerid][4], true);

        PlayerSlotsInvent[playerid][5] = CreatePlayerTextDraw(playerid, 333.372558, 178.933197, "Invent:Quadrado");
        PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][5], 49.000000, 46.000000);
        PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][5], 1);
        PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][5], -1);
        PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][5], 0);
        PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][5], 255);
        PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][5], 4);
        PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][5], 0);
        PlayerTextDrawSetSelectable(playerid, PlayerSlotsInvent[playerid][5], true);

        PlayerSlotsInvent[playerid][6] = CreatePlayerTextDraw(playerid, 333.372741, 226.766494, "Invent:Quadrado");
        PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][6], 49.000000, 46.000000);
        PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][6], 1);
        PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][6], -1);
        PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][6], 0);
        PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][6], 255);
        PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][6], 4);
        PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][6], 0);
        PlayerTextDrawSetSelectable(playerid, PlayerSlotsInvent[playerid][6], true);

        PlayerSlotsInvent[playerid][7] = CreatePlayerTextDraw(playerid, 333.372344, 274.599731, "Invent:Quadrado");
        PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][7], 49.000000, 46.000000);
        PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][7], 1);
        PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][7], -1);
        PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][7], 0);
        PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][7], 255);
        PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][7], 4);
        PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][7], 0);
        PlayerTextDrawSetSelectable(playerid, PlayerSlotsInvent[playerid][7], true);

        PlayerSlotsInvent[playerid][8] = CreatePlayerTextDraw(playerid, 384.909759, 131.099792, "Invent:Quadrado");
        PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][8], 49.000000, 46.000000);
        PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][8], 1);
        PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][8], -1);
        PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][8], 0);
        PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][8], 255);
        PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][8], 4);
        PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][8], 0);
        PlayerTextDrawSetSelectable(playerid, PlayerSlotsInvent[playerid][8], true);

        PlayerSlotsInvent[playerid][9] = CreatePlayerTextDraw(playerid, 384.909759, 178.933090, "Invent:Quadrado");
        PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][9], 49.000000, 46.000000);
        PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][9], 1);
        PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][9], -1);
        PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][9], 0);
        PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][9], 255);
        PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][9], 4);
        PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][9], 0);
        PlayerTextDrawSetSelectable(playerid, PlayerSlotsInvent[playerid][9], true);

        PlayerSlotsInvent[playerid][10] = CreatePlayerTextDraw(playerid, 384.909667, 226.766464, "Invent:Quadrado");
        PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][10], 49.000000, 46.000000);
        PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][10], 1);
        PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][10], -1);
        PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][10], 0);
        PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][10], 255);
        PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][10], 4);
        PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][10], 0);
        PlayerTextDrawSetSelectable(playerid, PlayerSlotsInvent[playerid][10], true);

        PlayerSlotsInvent[playerid][11] = CreatePlayerTextDraw(playerid, 384.909362, 274.599792, "Invent:Quadrado");
        PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][11], 49.000000, 46.000000);
        PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][11], 1);
        PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][11], -1);
        PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][11], 0);
        PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][11], 255);
        PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][11], 4);
        PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][11], 0);
        PlayerTextDrawSetSelectable(playerid, PlayerSlotsInvent[playerid][11], true);

        PlayerSlotsInvent[playerid][12] = CreatePlayerTextDraw(playerid, 436.446441, 131.099761, "Invent:Quadrado");
        PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][12], 49.000000, 46.000000);
        PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][12], 1);
        PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][12], -1);
        PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][12], 0);
        PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][12], 255);
        PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][12], 4);
        PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][12], 0);
        PlayerTextDrawSetSelectable(playerid, PlayerSlotsInvent[playerid][12], true);

        PlayerSlotsInvent[playerid][13] = CreatePlayerTextDraw(playerid, 436.446533, 178.933135, "Invent:Quadrado");
        PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][13], 49.000000, 46.000000);
        PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][13], 1);
        PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][13], -1);
        PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][13], 0);
        PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][13], 255);
        PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][13], 4);
        PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][13], 0);
        PlayerTextDrawSetSelectable(playerid, PlayerSlotsInvent[playerid][13], true);

        PlayerSlotsInvent[playerid][14] = CreatePlayerTextDraw(playerid, 436.446563, 226.183166, "Invent:Quadrado");
        PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][14], 49.000000, 46.000000);
        PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][14], 1);
        PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][14], -1);
        PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][14], 0);
        PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][14], 255);
        PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][14], 4);
        PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][14], 0);
        PlayerTextDrawSetSelectable(playerid, PlayerSlotsInvent[playerid][14], true);

        PlayerSlotsInvent[playerid][15] = CreatePlayerTextDraw(playerid, 436.446411, 274.016510, "Invent:Quadrado");
        PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][15], 49.000000, 46.000000);
        PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][15], 1);
        PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][15], -1);
        PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][15], 0);
        PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][15], 255);
        PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][15], 4);
        PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][15], 0);
        PlayerTextDrawSetSelectable(playerid, PlayerSlotsInvent[playerid][15], true);

        PlayerSlotsInvent[playerid][16] = CreatePlayerTextDraw(playerid, 488.452239, 131.099838, "Invent:Quadrado");
        PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][16], 49.000000, 46.000000);
        PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][16], 1);
        PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][16], -1);
        PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][16], 0);
        PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][16], 255);
        PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][16], 4);
        PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][16], 0);
        PlayerTextDrawSetSelectable(playerid, PlayerSlotsInvent[playerid][16], true);

        PlayerSlotsInvent[playerid][17] = CreatePlayerTextDraw(playerid, 488.452178, 178.933227, "Invent:Quadrado");
        PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][17], 49.000000, 46.000000);
        PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][17], 1);
        PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][17], -1);
        PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][17], 0);
        PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][17], 255);
        PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][17], 4);
        PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][17], 0);
        PlayerTextDrawSetSelectable(playerid, PlayerSlotsInvent[playerid][17], true);

    PlayerSlotsInvent[playerid][18] = CreatePlayerTextDraw(playerid, 488.451934, 226.766586, "Invent:Quadrado");
    PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][18], 49.000000, 46.000000);
    PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][18], 1);
    PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][18], -1);
    PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][18], 0);
    PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][18], 255);
    PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][18], 4);
    PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][18], 0);
    PlayerTextDrawSetSelectable(playerid, PlayerSlotsInvent[playerid][18], true);

    PlayerSlotsInvent[playerid][19] = CreatePlayerTextDraw(playerid, 488.452026, 274.016418, "Invent:Quadrado");
    PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][19], 49.000000, 46.000000);
    PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][19], 1);
    PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][19], -1);
    PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][19], 0);
    PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][19], 255);
    PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][19], 4);
    PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][19], 0);
    PlayerTextDrawSetSelectable(playerid, PlayerSlotsInvent[playerid][19], true);

    PlayerSlotsInvent[playerid][20] = CreatePlayerTextDraw(playerid, 189.768081, 108.600036, "Invent:Quadrado");
    PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][20], 44.000000, 49.000000);
    PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][20], 1);
    PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][20], -1);
    PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][20], 0);
    PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][20], 255);
    PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][20], 4);
    PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][20], 0);

    PlayerSlotsInvent[playerid][21] = CreatePlayerTextDraw(playerid, 189.736572, 186.366622, "Invent:Quadrado");
    PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][21], 44.000000, 49.000000);
    PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][21], 1);
    PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][21], -1);
    PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][21], 0);
    PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][21], 255);
    PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][21], 4);
    PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][21], 0);

    PlayerSlotsInvent[playerid][22] = CreatePlayerTextDraw(playerid, 189.736572, 263.071289, "Invent:Quadrado");
    PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][22], 44.000000, 49.000000);
    PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][22], 1);
    PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][22], -1);
    PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][22], 0);
    PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][22], 255);
    PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][22], 4);
    PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][22], 0);

    PlayerSlotsInvent[playerid][23] = CreatePlayerTextDraw(playerid, 75.133613, 263.071289, "Invent:Quadrado");
    PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][23], 44.000000, 49.000000);
    PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][23], 1);
    PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][23], -1);
    PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][23], 0);
    PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][23], 255);
    PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][23], 4);
    PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][23], 0);

    PlayerSlotsInvent[playerid][24] = CreatePlayerTextDraw(playerid, 75.133613, 186.266601, "Invent:Quadrado");
    PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][24], 44.000000, 49.000000);
    PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][24], 1);
    PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][24], -1);
    PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][24], 0);
    PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][24], 255);
    PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][24], 4);
    PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][24], 0);

    PlayerSlotsInvent[playerid][25] = CreatePlayerTextDraw(playerid, 75.133613, 108.763343, "Invent:Quadrado");
    PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][25], 44.000000, 49.000000);
    PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][25], 1);
    PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][25], -1);
    PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][25], 0);
    PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][25], 255);
    PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][25], 4);
    PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][25], 0);

    PlayerSlotsInvent[playerid][26] = CreatePlayerTextDraw(playerid, 294.048370, 363.249969, "Invent:Quadrado");
    PlayerTextDrawTextSize(playerid, PlayerSlotsInvent[playerid][26], 35.000000, 38.000000);
    PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][26], 1);
    PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][26], -1);
    PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][26], 0);
    PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][26], 255);
    PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][26], 4);
    PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][26], 0);

    PlayerSlotsInvent[playerid][27] = CreatePlayerTextDraw(playerid, 321.731933, 343.433105, "Nome_Item_(qnt)");
    PlayerTextDrawLetterSize(playerid, PlayerSlotsInvent[playerid][27], 0.191976, 1.156666);
    PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][27], 2);
    PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][27], -1);
    PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][27], 0);
    PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][27], 255);
    PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][27], 1);
    PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][27], 1);

    PlayerSlotsInvent[playerid][28] = CreatePlayerTextDraw(playerid, 398.228332, 363.249969, "Descricao_do_item");
    PlayerTextDrawLetterSize(playerid, PlayerSlotsInvent[playerid][28], 0.221493, 1.214999);
    PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][28], 2);
    PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][28], 255);
    PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][28], 0);
    PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][28], 255);
    PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][28], 1);
    PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][28], 1);

    PlayerSlotsInvent[playerid][29] = CreatePlayerTextDraw(playerid, 342.472656, 387.783691, "Tipo:");
    PlayerTextDrawLetterSize(playerid, PlayerSlotsInvent[playerid][29], 0.221493, 1.214999);
    PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][29], 2);
    PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][29], 255);
    PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][29], 0);
    PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][29], 255);
    PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][29], 1);
    PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][29], 1);

    PlayerSlotsInvent[playerid][30] = CreatePlayerTextDraw(playerid, 377.074768, 387.783691, "item_tipo");
    PlayerTextDrawLetterSize(playerid, PlayerSlotsInvent[playerid][30], 0.221493, 1.214999);
    PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][30], 2);
    PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][30], -1523963137);
    PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][30], 0);
    PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][30], 255);
    PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][30], 1);
    PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][30], 1);

    PlayerSlotsInvent[playerid][31] = CreatePlayerTextDraw(playerid, 415.777130, 387.783691, "Atributo:");
    PlayerTextDrawLetterSize(playerid, PlayerSlotsInvent[playerid][31], 0.221493, 1.214999);
    PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][31], 2);
    PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][31], 255);
    PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][31], 0);
    PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][31], 255);
    PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][31], 1);
    PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][31], 1);

    PlayerSlotsInvent[playerid][32] = CreatePlayerTextDraw(playerid, 451.579315, 387.783691, "Item_Atr");
    PlayerTextDrawLetterSize(playerid, PlayerSlotsInvent[playerid][32], 0.221493, 1.214999);
    PlayerTextDrawAlignment(playerid, PlayerSlotsInvent[playerid][32], 2);
    PlayerTextDrawColor(playerid, PlayerSlotsInvent[playerid][32], -1523963137);
    PlayerTextDrawSetShadow(playerid, PlayerSlotsInvent[playerid][32], 0);
    PlayerTextDrawBackgroundColor(playerid, PlayerSlotsInvent[playerid][32], 255);
    PlayerTextDrawFont(playerid, PlayerSlotsInvent[playerid][32], 1);
    PlayerTextDrawSetProportional(playerid, PlayerSlotsInvent[playerid][32], 1);
    return 1;
}

CMD:invent(playerid)
{
    
    PlayerTextDrawShow(playerid, PlayerUsarItem[playerid][0]);
    PlayerTextDrawShow(playerid, PlayerSepararItem[playerid][0]);
    PlayerTextDrawShow(playerid, PlayerMoverItem[playerid][0]);
    PlayerTextDrawShow(playerid, PlayerApagarItem[playerid][0]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][0]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][1]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][2]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][3]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][4]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][5]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][6]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][7]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][8]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][9]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][10]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][11]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][12]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][13]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][14]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][15]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][16]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][17]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][18]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][19]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][20]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][21]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][22]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][23]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][24]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][25]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][26]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][27]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][28]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][29]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][30]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][31]);
    PlayerTextDrawShow(playerid, PlayerSlotsInvent[playerid][32]);
    TextDrawShowForPlayer(playerid, InventBackground[0]);
    TextDrawShowForPlayer(playerid, InventBackground[1]);
    TextDrawShowForPlayer(playerid, InventBackground[2]);
    TextDrawShowForPlayer(playerid, InventBackground[3]);
    TextDrawShowForPlayer(playerid, InventBackground[4]);
    TextDrawShowForPlayer(playerid, InventBackground[5]);
    TextDrawShowForPlayer(playerid, InventBackground[6]);
    TextDrawShowForPlayer(playerid, InventBackground[7]);
    SelectTextDraw(playerid, 0xFF0000FF);
    return 1;
}