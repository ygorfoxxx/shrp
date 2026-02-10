
#define FILTERSCRIPT

/////////////////////////////////////////////////////////////////////////////////////////////////
// GM: Filterscript con lo necesario para hacer funcionar el servidor.///////////////////////////
// Mapeos - Labels - Actores - Todo script que precise streamer estará en este FS ///////////////
/////////////////////////////////////////////////////////////////////////////////////////////////

// Native: CreateDynamicObject(ID, X, Y, Z, Xr, Yr, Zr,Int,Vw);
// Native CreateDynamicMapIcon(Float:x, Float:y, Float:z, type, color, worldid = -1, interiorid = -1, playerid = -1, Float:streamdistance = 100.0);
// Native Text3D:CreateDynamic3DTextLabel(const text[], color, X, Y, Z, Float:drawdistance, attachedplayer = INVALID_PLAYER_ID, attachedvehicle = INVALID_VEHICLE_ID, testlos = 0, worldid = -1, interiorid = -1, playerid = -1, Float:streamdistance = 100.0);

#include <a_samp>
#include <sscanf2>
#include <streamer>

public OnFilterScriptInit()
{
	//Ferreiro Nevada
	CreateDynamicPickup(15300, 0, 2267.4187, -746.0071, 29.0391, -1, -1);//Balão ferreiro nevada
	// Kumo
	CreateDynamicMapIcon(1721.4590, 1401.7721, 38.9922, 52, 0, 0, 0, -1, 500.0); //Tsunade Kumo
	CreateDynamicMapIcon(1753.9548, 1375.4895, 38.9922, 21, 0, 0, 0, -1, 500.0); //KidBengma Kumo
	CreateDynamicPickup(15300, 0, 1897.3053, 1688.0160, 48.4758, -1, -1);//B Entrada Sala Raikage
	CreateDynamicPickup(15300, 0, 1898.6461, 1687.5613, 116.5287, -1, -1);//B Dentro da Sala Raikage
	CreateDynamicPickup(15300, 0, 1906.3649, 1663.2028, 216.6992, -1, -1);//B Terraço Raikage
	return 1; 
}
