#include <amxmodx>
#include <amxmisc>

#define PLUGIN_NAME     "PlayTime Logger"
#define PLUGIN_VERSION  "1.0"
#define PLUGIN_AUTHOR   "sakulmore"

#define ADMIN_FLAG      ADMIN_RCON

new g_szDataFile[128]
new Trie:g_tPlayerData
new Array:g_aPlayerKeys
new g_iJoinTime[33]
new g_iLastTeam[33]
new g_pCvarAllowSpec

enum _:PlayerData {
    pd_szFirstDate[16],
    pd_szName[32],
    pd_iTotalSeconds
}

public plugin_init() {
    register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
    
    g_pCvarAllowSpec = register_cvar("playtime_allowspectator", "1")
    
    register_clcmd("say /rpt", "Cmd_ResetFile")
    register_clcmd("say_team /rpt", "Cmd_ResetFile")
    register_concmd("playtime_resetfile", "Cmd_ResetFile")
    register_srvcmd("playtime_resetfile", "Cmd_ResetFile_Server")
    
    register_event("TeamInfo", "Event_TeamInfo", "a")
    
    g_tPlayerData = TrieCreate()
    g_aPlayerKeys = ArrayCreate(32)
    
    new szDataDir[128]
    get_localinfo("amxx_datadir", szDataDir, charsmax(szDataDir))
    formatex(g_szDataFile, charsmax(g_szDataFile), "%s/playtime_logger.txt", szDataDir)
    
    LoadData()
}

public plugin_end() {
    TrieDestroy(g_tPlayerData)
    ArrayDestroy(g_aPlayerKeys)
}

LoadData() {
    if (!file_exists(g_szDataFile)) {
        new file = fopen(g_szDataFile, "wt")
        if (file) fclose(file)
        return
    }
    
    new file = fopen(g_szDataFile, "rt")
    if (!file) return
    
    new szLine[256], szParts[4][64], szTimeParts[3][32]
    new data[PlayerData]
    
    while (!feof(file)) {
        fgets(file, szLine, charsmax(szLine))
        trim(szLine)
        
        if (!szLine[0]) continue
        
        explode_string(szLine, "|", szParts, 4, 63)
        trim(szParts[0])
        trim(szParts[1])
        trim(szParts[2])
        trim(szParts[3])
        
        copy(data[pd_szFirstDate], 15, szParts[0])
        copy(data[pd_szName], 31, szParts[2])
        
        explode_string(szParts[3], ";", szTimeParts, 3, 31)
        new iDays = str_to_num(szTimeParts[0])
        new iHours = str_to_num(szTimeParts[1])
        new iMins = str_to_num(szTimeParts[2])
        
        data[pd_iTotalSeconds] = (iDays * 86400) + (iHours * 3600) + (iMins * 60)
        
        if (!TrieKeyExists(g_tPlayerData, szParts[1])) {
            ArrayPushString(g_aPlayerKeys, szParts[1])
        }
        TrieSetArray(g_tPlayerData, szParts[1], data, PlayerData)
    }
    fclose(file)
}

SaveData() {
    new file = fopen(g_szDataFile, "wt")
    if (!file) return
    
    new iSize = ArraySize(g_aPlayerKeys)
    new szAuth[32], data[PlayerData]
    new iDays, iHours, iMins, iLeft
    
    for (new i = 0; i < iSize; i++) {
        ArrayGetString(g_aPlayerKeys, i, szAuth, charsmax(szAuth))
        
        if (TrieGetArray(g_tPlayerData, szAuth, data, PlayerData)) {
            iDays = data[pd_iTotalSeconds] / 86400
            iLeft = data[pd_iTotalSeconds] % 86400
            iHours = iLeft / 3600
            iLeft = iLeft % 3600
            iMins = iLeft / 60
            
            fprintf(file, "%s | %s | %s | %d Days; %d Hours; %d Minutes;%c", data[pd_szFirstDate], szAuth, data[pd_szName], iDays, iHours, iMins, 10)
        }
    }
    
    fclose(file)
}

public Event_TeamInfo() {
    new id = read_data(1)
    if (!is_user_connected(id) || is_user_bot(id) || is_user_hltv(id)) return
    
    new szTeam[16]
    read_data(2, szTeam, charsmax(szTeam))
    
    new iNewTeam = 0
    if (szTeam[0] == 'T') iNewTeam = 1
    else if (szTeam[0] == 'C') iNewTeam = 2
    else if (szTeam[0] == 'S') iNewTeam = 3
    
    if (g_iLastTeam[id] != iNewTeam) {
        UpdatePlayerTime(id)
        g_iLastTeam[id] = iNewTeam
    }
}

UpdatePlayerTime(id) {
    if (g_iJoinTime[id] == 0) return
    
    new iSysTime = get_systime()
    new iPlayedTime = iSysTime - g_iJoinTime[id]
    
    if (iPlayedTime > 0) {
        new bShouldCount = true
        
        if (g_iLastTeam[id] == 3 && get_pcvar_num(g_pCvarAllowSpec) == 0) {
            bShouldCount = false
        }
        
        if (bShouldCount) {
            new szAuth[32], data[PlayerData]
            get_user_authid(id, szAuth, charsmax(szAuth))
            
            if (TrieGetArray(g_tPlayerData, szAuth, data, PlayerData)) {
                data[pd_iTotalSeconds] += iPlayedTime
                TrieSetArray(g_tPlayerData, szAuth, data, PlayerData)
            }
        }
    }
    
    g_iJoinTime[id] = iSysTime
}

public client_putinserver(id) {
    if (is_user_bot(id) || is_user_hltv(id)) return
    
    new szAuth[32], szName[32]
    get_user_authid(id, szAuth, charsmax(szAuth))
    get_user_name(id, szName, charsmax(szName))
    
    replace_all(szName, charsmax(szName), "|", "")
    
    g_iJoinTime[id] = get_systime()
    g_iLastTeam[id] = 0
    
    new data[PlayerData]
    if (TrieGetArray(g_tPlayerData, szAuth, data, PlayerData)) {
        copy(data[pd_szName], 31, szName)
    } else {
        get_time("%d.%m.%Y", data[pd_szFirstDate], 15)
        copy(data[pd_szName], 31, szName)
        data[pd_iTotalSeconds] = 0
        
        ArrayPushString(g_aPlayerKeys, szAuth)
    }
    
    TrieSetArray(g_tPlayerData, szAuth, data, PlayerData)
}

public client_disconnected(id) {
    if (is_user_bot(id) || is_user_hltv(id)) return
    
    UpdatePlayerTime(id)
    g_iJoinTime[id] = 0
    g_iLastTeam[id] = 0
    
    SaveData()
}

public Cmd_ResetFile(id) {
    if (!(get_user_flags(id) & ADMIN_FLAG)) return PLUGIN_HANDLED
    
    ClearData(id)
    return PLUGIN_HANDLED
}

public Cmd_ResetFile_Server() {
    ClearData(0)
    return PLUGIN_HANDLED
}

ClearData(id) {
    TrieClear(g_tPlayerData)
    ArrayClear(g_aPlayerKeys)
    
    new file = fopen(g_szDataFile, "wt")
    if (file) fclose(file)
    
    if (id == 0) {
        server_print("[PlayTime Logger] The file %cplaytime_logger.txt%c has been successfully cleared.%c", 34, 34, 10)
    } else {
        client_print(id, print_chat, "[PlayTime Logger] The file %cplaytime_logger.txt%c has been successfully cleared.", 34, 34)
    }
    
    new iPlayers[32], iNum, player
    get_players(iPlayers, iNum, "ch")
    for (new i = 0; i < iNum; i++) {
        player = iPlayers[i]
        g_iJoinTime[player] = get_systime()
        
        new szTeam[16]
        get_user_team(player, szTeam, charsmax(szTeam))
        if (szTeam[0] == 'T') g_iLastTeam[player] = 1
        else if (szTeam[0] == 'C') g_iLastTeam[player] = 2
        else if (szTeam[0] == 'S') g_iLastTeam[player] = 3
        else g_iLastTeam[player] = 0
        
        new szAuth[32], szName[32], data[PlayerData]
        get_user_authid(player, szAuth, charsmax(szAuth))
        get_user_name(player, szName, charsmax(szName))
        replace_all(szName, charsmax(szName), "|", "")
        
        get_time("%d.%m.%Y", data[pd_szFirstDate], 15)
        copy(data[pd_szName], 31, szName)
        data[pd_iTotalSeconds] = 0
        
        ArrayPushString(g_aPlayerKeys, szAuth)
        TrieSetArray(g_tPlayerData, szAuth, data, PlayerData)
    }
}