/*
 *  Server Side Registries
 *
 *  These are the registries that are stored on the server and are used for
 *  game state management.
 */

// Actor Registry
[["_SP_PLAYER_",[["rank","CAPTAIN"],["name","Jacob Schmidt"],["holster",true],["state","HEALTHY"],["organization","0160566824"],["loadout",[[],[],[],["U_BG_Guerrilla_RF",[]],[],[],"lxWS_H_CapB_rvs_blk_ION","G_Glasses_black_RF",[],["ItemMap","ItemGPS","ItemRadio","ItemCompass","ItemWatch",""]]],["stance","CROUCH"],["uid","_SP_PLAYER_"],["phone_number","0160566824"],["direction",0],["position",[0,0.0498047,5.00144]],["email","0160566824@spearnet.mil"]]]];

// Bank Registry
[["_SP_PLAYER_",[["pin",1234],["name","Jacob Schmidt"],["earnings",0],["bank",2000],["transactions",[]],["cash",0],["uid","_SP_PLAYER_"]]]];
// Bank Index Registry
[["_SP_PLAYER_",[["name","Jacob Schmidt"],["uid","_SP_PLAYER_"]]]];

// Garage Registry
[["_SP_PLAYER_",[["efccebda-5f16-48f6-b4a5-da8dbfb19d02",[["plate","efccebda-5f16-48f6-b4a5-da8dbfb19d02"],["hit_points",[["names",["hitlfwheel","hitlf2wheel","hitrfwheel","hitrf2wheel","hitfuel","hithull","hitengine","hitbody","hitglass1","hitrglass","hitlglass","hitglass2","hitglass3","hitglass4","hitglass5","hitglass6","hitlbwheel","hitlmwheel","hitrbwheel","hitrmwheel","#light_1_hitpoint","#light_2_hitpoint"]],["selections",["wheel_1_1_steering","wheel_1_2_steering","wheel_2_1_steering","wheel_2_2_steering","fuel_hitpoint","fuel_hitpoint","engine_hitpoint","body_hitpoint","","","","","","","","","","","","","light_1_hitpoint","light_2_hitpoint"]],["values",[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]]],["damage",0],["classname","B_LSV_01_unarmed_F"],["fuel",1]]]]]];

// Locker Registry
[["_SP_PLAYER_",[["30Rnd_65x39_caseless_mag",[["amount",4],["classname","30Rnd_65x39_caseless_mag"],["category","magazine"]]],["arifle_MX_F",[["amount",1],["classname","arifle_MX_F"],["category","weapon"]]],["NVGoggles",[["amount",1],["classname","NVGoggles"],["category","hmd"]]]]]];

// Org Registry
[["default",[["name","Forge Dynamics"],["id","default"],["funds",200000],["reputation",0],["owner","server"]]],["0160566824",[["name","Black Rifle Company"],["id","0160566824"],["funds",0],["reputation",0],["owner","_SP_PLAYER_"],["members",[["_SP_PLAYER_",[["name","Jacob Schmidt"],["uid","_SP_PLAYER_"]]]]]]]];
// Org Index Registry
[["_SP_PLAYER_",[["orgID","0160566824"]]]];

// Player Session Registry
[["_SP_PLAYER_",[["sessionToken","855837"]]]];

// Virtual Arsenal Registry
[["_SP_PLAYER_",[["items",["saber_light_ir_sand_lxWS","optic_Hamr_sand_lxWS","acc_pointer_IR_pistol_RF","U_BG_Guerrilla_RF","V_PlateCarrier1_rgr_noflag_F","lxWS_H_CapB_rvs_blk_ION","G_Glasses_black_RF","ItemMap","ItemCompass","ItemGPS","ItemRadio","ItemWatch"]],["backpacks",["B_AssaultPack_rgr"]],["weapons",["arifle_XMS_Sand_lxWS","hgun_Glock19_Tan_RF","Binocular"]],["magazines",["30Rnd_556x45_AP_Stanag_red_RF","17Rnd_9x19_red_Mag_RF"]]]]];

// Virtual Garage Registry
[["_SP_PLAYER_",[["armor",[]],["helis",[]],["cars",["B_Quadbike_01_F","B_ION_Pickup_rf"]],["other",[]],["planes",[]],["naval",[]]]]];

/*
 *  Client Side Classes
 *
 *  These are the classes that are stored on the client and are used for
 *  optimistic UI updates. (Read-Only)
 */

// Actor Class
[["rank","CAPTAIN"],["name","Jacob Schmidt"],["holster",true],["state","HEALTHY"],["organization","0160566824"],["loadout",[[],[],[],["U_BG_Guerrilla_RF",[]],[],[],"lxWS_H_CapB_rvs_blk_ION","G_Glasses_black_RF",[],["ItemMap","ItemGPS","ItemRadio","ItemCompass","ItemWatch",""]]],["stance","CROUCH"],["uid","_SP_PLAYER_"],["phone_number","0160566824"],["direction",0],["position",[0,0.0498047,5.00144]],["email","0160566824@spearnet.mil"]];

// Bank Class
[["pin",1234],["name","Jacob Schmidt"],["earnings",0],["bank",2000],["transactions",[]],["cash",0],["uid","_SP_PLAYER_"]];

// Garage Class
[["efccebda-5f16-48f6-b4a5-da8dbfb19d02",[["plate","efccebda-5f16-48f6-b4a5-da8dbfb19d02"],["hit_points",[["names",["hitlfwheel","hitlf2wheel","hitrfwheel","hitrf2wheel","hitfuel","hithull","hitengine","hitbody","hitglass1","hitrglass","hitlglass","hitglass2","hitglass3","hitglass4","hitglass5","hitglass6","hitlbwheel","hitlmwheel","hitrbwheel","hitrmwheel","#light_1_hitpoint","#light_2_hitpoint"]],["selections",["wheel_1_1_steering","wheel_1_2_steering","wheel_2_1_steering","wheel_2_2_steering","fuel_hitpoint","fuel_hitpoint","engine_hitpoint","body_hitpoint","","","","","","","","","","","","","light_1_hitpoint","light_2_hitpoint"]],["values",[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]]]],["damage",0],["classname","B_LSV_01_unarmed_F"],["fuel",1]]]];

// Locker Class
[["30Rnd_65x39_caseless_mag",[["amount",4],["classname","30Rnd_65x39_caseless_mag"],["category","magazine"]]],["arifle_MX_F",[["amount",1],["classname","arifle_MX_F"],["category","weapon"]]],["NVGoggles",[["amount",1],["classname","NVGoggles"],["category","hmd"]]]];

// Organization Class
[["assets",[]],["name","Black Rifle Company"],["id","0160566824"],["funds",0],["reputation",0],["owner","_SP_PLAYER_"],["members",[["_SP_PLAYER_",[["name","Jacob Schmidt"],["uid","_SP_PLAYER_"]]]]]];

// Virtual Arsenal Class
[["items",["saber_light_ir_sand_lxWS","optic_Hamr_sand_lxWS","acc_pointer_IR_pistol_RF","U_BG_Guerrilla_RF","V_PlateCarrier1_rgr_noflag_F","lxWS_H_CapB_rvs_blk_ION","G_Glasses_black_RF","ItemMap","ItemCompass","ItemGPS","ItemRadio","ItemWatch"]],["backpacks",["B_AssaultPack_rgr"]],["weapons",["arifle_XMS_Sand_lxWS","hgun_Glock19_Tan_RF","Binocular"]],["magazines",["30Rnd_556x45_AP_Stanag_red_RF","17Rnd_9x19_red_Mag_RF"]]];

// Virtual Garage Class
[["armor",[]],["helis",[]],["cars",["B_Quadbike_01_F","B_ION_Pickup_rf"]],["other",[]],["planes",[]],["naval",[]]];
