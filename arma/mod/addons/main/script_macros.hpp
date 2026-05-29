#define QUOTE(var1) #var1
#define DOUBLES(var1,var2) var1##_##var2
#define TRIPLES(var1,var2,var3) DOUBLES(DOUBLES(var1,var2),var3)

#define ADDON DOUBLES(PREFIX,COMPONENT)
#define VERSION_CONFIG version = VERSION; versionStr = QUOTE(VERSION_STR); versionAr[] = {VERSION_AR}

#define SERVER_TASK_FUNC(var1) QUOTE(TRIPLES(DOUBLES(forge_server,task),fnc,var1))
