/////// INCLUDE ///////
#include <a_samp>
#include <a_actor>
#include <streamer>
/////// FIM ///////
#if defined FILTERSCRIPT

public OnFilterScriptInit()
{
	print("\n--------------------------------------");
	print(" Actors Carregados -- By: Ali");
	print("--------------------------------------\n");
	return 1;
}


public OnFilterScriptExit()
{
	return 1;
}

#else
#define 			function%0(%1) 							forward %0(%1); public %0(%1)
main()
{

}

#endif
public OnGameModeInit()
{
		// Inicio NPC'S Iwagakure
		CreateDynamicActor(286, -1672.5050, 1919.8663, 2.0255, 137.3480, 1, 100.0, 0, 0, -1, 50);  // NPC HOSPITAL IWAGAKURE
		CreateDynamicActor(296, -1551.0905, 1626.4233, 2.1377, 296.0060, 1, 100.0, 0, 0, -1, 50); // NPC ICHIRAKU IWAGAKURE
		CreateDynamicActor(184, -1466.5721, 1495.2083, 2.0650, 231.2090, 1, 100.0, 0, 0, -1, 50); // NPC TSUNADE IWAGAKURE
		CreateDynamicActor(294, -1442.5591, 1755.6208, 23.5495,198.2989, 1, 100.0, 0, 0, -1, 50); // NPC ROUPAS IWAGAKURE
		CreateDynamicActor(151, -1839.9407, 1869.9462, 2.0111, 233.0611, 1, 100.0, 0, 0, -1, 50); // NPC EXAME CHUNIN IWAGAKURE
		CreateDynamicActor(155, -1824.5286, 1882.3031, 2.0111, 149.2620, 1, 100.0, 0, 0, -1, 50); // NPC MISSÃO IWAGAKURE
		CreateDynamicActor(154, -1650.1456, 1928.2588, 2.0320, 225.8826, 1, 100.0, 0, 0, -1, 50); // NPC MISSÃO IWAGAKURE KAGE
		CreateDynamicActor(289, -1652.3944, 1794.5969, 2.0000, 318.5518, 1, 100.0, 0, 0, -1, 50); // KID BENGMA
		// Final NPC'S Iwagakure 
		CreateDynamicActor(262, -1567.4543,201.0385,2.1534,31.8045); // NPC MERCADO NEGRO
		//Actors[8] = CreateDynamicActor(123, 85.0622,-423.6740,2030.4444,90.4255); // MOMOSHIKI
		//SetActorInvulnerable(Actors[8], true);
		//ApplyActorAnimation(Actors[8],"ped", "SEAT_up", 4.1, 0, 0, 1, 1, 1);
		// Inicio NPC'S Kirigakure
		CreateDynamicActor(147, 2823.5862, -2415.2993, 29.7635, 134.2744, 1, 100.0, 0, 0, -1, 50); // NPC EXAME CHUNIN KIRI
		CreateDynamicActor(287, 2830.6719, -2573.0283, 35.5607, 87.9345, 1, 100.0, 0, 0, -1, 50); // NPC HOSPITAL KIRI
		CreateDynamicActor(148, 2539.5417, -2395.6648, 46.4627, 227.6625, 1, 100.0, 0, 0, -1, 50); // SENSEI MOSHI KIRI;
		CreateDynamicActor(295, 2658.7527, -2696.1118, 35.5319, 261.8274, 1, 100.0, 0, 0, -1, 50); // Mulher Ramen de KIRI;
		CreateDynamicActor(184, 2280.7358, -2298.4858, 29.9685, 175.2901, 1, 100.0, 0, 0, -1, 50); // TSUNADE KIRI
		CreateDynamicActor(293, 2611.9480, -2292.0364, 29.8595, 211.8728, 1, 100.0, 0, 0, -1, 50); // NPC VELHO MISSAO KIRI
		CreateDynamicActor(294, 2529.2751, -2124.6221, 46.4609, 99.6577, 1, 100.0, 0, 0, -1, 50); // NPC ROUPAS KIRI
		CreateDynamicActor(148, 2830.6045, -2433.5054, 29.6660, 47.0864, 1, 100.0, 0, 0, -1, 50); // NPC MISSÃO KIRI
		CreateDynamicActor(289, 2658.5730, -2716.0957, 35.5156, 263.9007, 1, 100.0, 0, 0, -1, 50); // KID BENGMA
		// Final NPC'S Kirigakure
		// Inicio NPC'S Nevada
		CreateDynamicActor(291, 2303.2410, -739.5428, 27.2907, 89.4852, 1, 100.0, 0, 0, -1, 50);
		// Final NPC'S Nevada
		// Inicio NPC'S Missoes
		CreateDynamicActor(226, 1404.9886, -1512.7532, 7.9219, 10.8088, 1, 100.0, 0, 0, -1, 50); // NPC MISSAO INGREDIENTES
		CreateDynamicActor(144, 370.7455, -706.9885, 33.6913, 330.5818, 1, 100.0, 0, 0, -1, 50); // NPC SHIZUNE MISSAO KONOHA KAGE
		CreateDynamicActor(291, 79.5390, 1327.8228, 24.1027, 66.7804, 1, 100.0, 0, 0, -1, 50); // NPC MISSAO INGREDIENTES
		CreateDynamicActor(140, 2582.9031, -2301.9678, 64.5547, 296.6137, 1, 100.0, 0, 0, -1, 50); // NPC SHIZUNE MISSAO KIRI KAGE
		// Final NPC'S Missoes
		// Inicio NPC'S Cemiterio
		CreateDynamicActor(129, 695.4669, -1213.5353, 7.7632, 113.5924, 1, 100.0, 0, 0, -1, 50);
		// Final NPC'S Cemiterio
	return 1;
}
