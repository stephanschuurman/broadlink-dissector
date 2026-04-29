-- broadlink_dissector.lua
-- Wireshark Lua dissector for the Broadlink Smart Home Protocol
-- Based on: https://github.com/mjg59/python-broadlink/blob/master/protocol.md
-- https://docs.ibroadlink.com/public/appsdk_en/appsdk_05/
-- https://github.com/csabavirag/broadlink-dissector/blob/master/broadlink.lua
-- https://github.com/mjg59/python-broadlink/blob/730853e5faf2cf979596662faf9def2b1f8fee6d/protocol.md
--
-- Installation:
--   macOS:   ~/.config/wireshark/plugins/broadlink_dissector.lua
--   Windows: %APPDATA%\Wireshark\plugins\broadlink_dissector.lua
--   Linux:   ~/.config/wireshark/plugins/broadlink_dissector.lua
--
-- Then: Wireshark > Analyze > Reload Lua Plugins  (Ctrl+Shift+L)

-- Optional: luagcrypt library (https://github.com/Lekensteyn/luagcrypt)
-- Used as a decryption fallback when Wireshark's built-in GcryptCipher is unavailable.
-- Install: brew install libgcrypt  &&  luarocks install luagcrypt
local gcrypt
do local ok, mod = pcall(require, "luagcrypt"); if ok then gcrypt = mod end end

-- Debug level infrastructure
local debug_level = { DISABLED = 0, LEVEL_1 = 1, LEVEL_2 = 2 }
local DEBUG = debug_level.LEVEL_1

local default_settings = {
    debug_level = DEBUG,
    port        = 80,
}

local dprint  = function() end
local dprint2 = function() end
local function reset_debug_level()
    if default_settings.debug_level > debug_level.DISABLED then
        dprint = function(...) print(table.concat({"Lua:", ...}, " ")) end
        if default_settings.debug_level > debug_level.LEVEL_1 then
            dprint2 = dprint
        end
    end
end
reset_debug_level()

local broadlink = Proto("broadlink", "Broadlink Smart Home Protocol")

local auth_key = ByteArray.new("097628343fe99e23765c1513accf8b02")  -- 16 bytes, default Broadlink AES key
local auth_iv  = ByteArray.new("562e17996d093d28ddb3ba695a2e6f58")  -- 16 bytes, default Broadlink AES IV

-- ── Preferences ──────────────────────────────────────────────────────────
local debug_pref_enum = {
    { 1, "Disabled", debug_level.DISABLED },
    { 2, "Level 1",  debug_level.LEVEL_1  },
    { 3, "Level 2",  debug_level.LEVEL_2  },
}
broadlink.prefs.debug   = Pref.enum("Debug", default_settings.debug_level,
                              "The debug printing level", debug_pref_enum)
broadlink.prefs.port    = Pref.uint("Port number", default_settings.port,
                              "The UDP port number for Broadlink protocol")
broadlink.prefs.aes_key = Pref.string("Session key", auth_key:tohex(), "AES-128 session key (hex) — auto-populated from Auth Response, or enter manually")

function broadlink.prefs_changed()
    dprint2("prefs_changed called")
    default_settings.debug_level = broadlink.prefs.debug
    reset_debug_level()
    if default_settings.port ~= broadlink.prefs.port then
        if default_settings.port ~= 0 then
            dprint2("removing Broadlink from port", default_settings.port)
            DissectorTable.get("udp.port"):remove(default_settings.port, broadlink)
        end
        default_settings.port = broadlink.prefs.port
        if default_settings.port ~= 0 then
            dprint2("adding Broadlink to port", default_settings.port)
            DissectorTable.get("udp.port"):add(default_settings.port, broadlink)
        end
    end
end

-- Convert a hexadecimal string to a raw binary string (used by the luagcrypt backend)
local function fromhex(hex)
    if string.match(hex, "[^0-9a-fA-F]") then error("Invalid chars in hex") end
    if string.len(hex) % 2 == 1 then error("Hex string must be a multiple of two") end
    return string.gsub(hex, "..", function(v) return string.char(tonumber(v, 16)) end)
end

-- Session key cache: device IP string → ByteArray(16)
-- Populated automatically when a 0x03e9 Auth Response is decrypted.
local session_keys = {}

-- ── Field definitions ──────────────────────────────────────────────────────
local pf_magic          = ProtoField.bytes  ("broadlink.magic",            "Magic Bytes")
local pf_gmt_offset     = ProtoField.int32  ("broadlink.gmt_offset",       "GMT Offset (h)",   base.DEC)
local pf_year           = ProtoField.uint16 ("broadlink.year",             "Year",             base.DEC)
local pf_seconds        = ProtoField.uint8  ("broadlink.seconds",          "Seconds",          base.DEC)
local pf_minutes        = ProtoField.uint8  ("broadlink.minutes",          "Minutes",          base.DEC)
local pf_hours          = ProtoField.uint8  ("broadlink.hours",            "Hours",            base.DEC)
local pf_day_of_week    = ProtoField.uint8  ("broadlink.day_of_week",      "Day of Week",      base.DEC)
local pf_day_of_month   = ProtoField.uint8  ("broadlink.day_of_month",     "Day of Month",     base.DEC)
local pf_month          = ProtoField.uint8  ("broadlink.month",            "Month",            base.DEC)
local pf_src_ip         = ProtoField.ipv4   ("broadlink.src_ip",           "Source IP")
local pf_src_port       = ProtoField.uint16 ("broadlink.src_port",         "Source Port",      base.DEC)
local pf_checksum       = ProtoField.uint16 ("broadlink.checksum",         "Checksum",         base.HEX)
local pf_error_code     = ProtoField.uint16 ("broadlink.error_code",       "Error Code",       base.HEX)
local pf_dev_type       = ProtoField.uint16 ("broadlink.device_type",      "Device Type",      base.HEX)
local pf_payload_type   = ProtoField.uint16 ("broadlink.payload_type",     "Payload Type",     base.HEX)
local pf_packet_count   = ProtoField.uint16 ("broadlink.packet_count",     "Packet Count",     base.DEC)
local pf_mac            = ProtoField.ether  ("broadlink.mac",              "MAC Address")
local pf_device_id      = ProtoField.uint32 ("broadlink.device_id",        "Device ID",        base.HEX)
local pf_device_name    = ProtoField.stringz("broadlink.device_name",      "Device Name")
local pf_device_ip      = ProtoField.ipv4   ("broadlink.device_ip",        "Device IP")
local pf_device_mac     = ProtoField.ether  ("broadlink.device_mac",       "Device MAC")
local pf_locked_status  = ProtoField.uint8  ("broadlink.locked_status",    "Locked Status",    base.DEC)
local pf_device_iden    = ProtoField.bytes  ("broadlink.device_iden",      "Device Identifier (IMEI)")
local pf_flag           = ProtoField.uint8  ("broadlink.flag",             "Flag",             base.HEX)
local pf_auth_key       = ProtoField.bytes  ("broadlink.auth_key",         "Auth Key")
local pf_signal_type    = ProtoField.uint8  ("broadlink.signal_type",      "Signal Type",      base.HEX)
local pf_command        = ProtoField.uint16 ("broadlink.command",          "Command Code",     base.HEX)
local pf_payload_chksum = ProtoField.uint16 ("broadlink.payload_checksum", "Payload Checksum", base.HEX)
local pf_payload        = ProtoField.bytes  ("broadlink.payload",          "Encrypted Payload")
local pf_ap_ssid        = ProtoField.string ("broadlink.ap_ssid",          "SSID")
local pf_ap_password    = ProtoField.string ("broadlink.ap_password",      "Password")
local pf_ap_ssid_len    = ProtoField.uint8  ("broadlink.ap_ssid_len",      "SSID Length",      base.DEC)
local pf_ap_pwd_len     = ProtoField.uint8  ("broadlink.ap_pwd_len",       "Password Length",  base.DEC)
local pf_ap_security    = ProtoField.uint8  ("broadlink.ap_security",      "Security Mode",    base.DEC)

broadlink.fields = {
    pf_magic, pf_checksum, pf_dev_type, pf_command, pf_packet_count,
    pf_mac, pf_auth_key, pf_device_iden, pf_flag, pf_signal_type,
    pf_device_id, pf_payload_type, pf_payload_chksum, pf_error_code, pf_payload,
    pf_gmt_offset, pf_year, pf_seconds, pf_minutes, pf_hours,
    pf_day_of_week, pf_day_of_month, pf_month, pf_src_ip, pf_src_port,
    pf_device_ip, pf_device_mac, pf_device_name, pf_locked_status,
    pf_ap_ssid, pf_ap_password, pf_ap_ssid_len, pf_ap_pwd_len, pf_ap_security,
}

-- ── Lookup tables ──────────────────────────────────────────────────────────

-- Packet type codes (command field at offset 0x26)
local CMD = {
    PING               = 0x0001,
    HELLO_REQUEST      = 0x0006,
    HELLO_RESPONSE     = 0x0007,
    JOIN_REQUEST       = 0x0014,
    JOIN_RESPONSE      = 0x0015,
    DISCOVERY_REQUEST  = 0x001a,
    DISCOVERY_RESPONSE = 0x001b,
    AUTH_REQUEST       = 0x0065,
    COMMAND_REQUEST    = 0x006a,
    JOIN_ERROR         = 0x0398,
    AUTH_RESPONSE      = 0x03e9,
    COMMAND_RESPONSE   = 0x03ee,
}

local payload_names = {
    [CMD.PING]               = "Ping",
    [CMD.HELLO_REQUEST]      = "Hello Request",
    [CMD.HELLO_RESPONSE]     = "Hello Response",
    [CMD.DISCOVERY_REQUEST]  = "Discovery Request",
    [CMD.DISCOVERY_RESPONSE] = "Discovery Response",
    [CMD.JOIN_REQUEST]       = "Join Request",
    [CMD.JOIN_RESPONSE]      = "Join Response",
    [CMD.AUTH_REQUEST]       = "Authorization Request",
    [CMD.AUTH_RESPONSE]      = "Authorization Response",
    [CMD.COMMAND_REQUEST]    = "Command Request",
    [CMD.COMMAND_RESPONSE]   = "Command Response",
    [CMD.JOIN_ERROR]         = "Join Response Error?",
}

local day_names = {
    [1] = "Monday",
    [2] = "Tuesday",
    [3] = "Wednesday",
    [4] = "Thursday",
    [5] = "Friday",
    [6] = "Saturday",
    [7] = "Sunday",
}

local locked_status = {
    [0] = "Unlocked",
    [1] = "Locked",
}

local signal_type_names = {
    [0x26] = "IR",
    [0xb2] = "RF 433 MHz",
    [0xd7] = "RF 315 MHz",
}

local get_device_info  -- forward declaration; defined after device_info table below

-- Sub-command tables per device class (device_info.type).
-- Applies to the *decrypted* command payload; encrypted on the wire.
local subcmd_by_class = {
    -- RM legacy firmware (rmmini, rmpro)
    rmmini = {
        [0x01] = "get/update status",
        [0x02] = "send_data (IR/RF)",
        [0x03] = "enter IR learning mode",
        [0x04] = "check_data: learned IR code at payload+0x04",
    },
    rmpro = {
        [0x01] = "check_sensors: get/update status / sensor read",
        [0x02] = "send_data (IR/RF)",
        [0x03] = "enter IR learning mode",
        [0x04] = "check_data: learned IR/RF data at payload+0x04",
        [0x19] = "RF sweep start",
        [0x1a] = "check_frequency: RF frequency-lock status",
        [0x1b] = "find_rf_packet: enter RF code learning",
        [0x1e] = "cancel RF sweep",
    },
    -- RM new firmware / Red Bean (rmminib, rm4mini, rm4pro)
    -- These use the 04 00 <cmd> prefix in the command payload.
    rmminib = {
        [0x01] = "get/update status",
        [0x02] = "send_data (IR/RF)",
        [0x03] = "enter IR learning mode",
        [0x04] = "check_data: learned IR/RF data at payload+0x08",
    },
    rm4mini = {
        [0x01] = "get/update status",
        [0x02] = "send_data (IR/RF)",
        [0x03] = "enter IR learning mode",
        [0x04] = "check_data: learned IR/RF data at payload+0x08",
        [0x24] = "check_sensors: temperature/humidity at fixed offsets",
        [0x68] = "Delete?",
    },
    rm4pro = {
        [0x01] = "get/update status",
        [0x02] = "send_data (IR/RF)",
        [0x03] = "enter IR learning mode",
        [0x04] = "check_data: learned IR/RF data at payload+0x08",
        [0x19] = "RF sweep start",
        [0x1a] = "check_frequency: RF frequency-lock status",
        [0x1b] = "find_rf_packet: enter RF code learning",
        [0x1e] = "cancel RF sweep",
        [0x24] = "check_sensors: temperature/humidity at fixed offsets",
    },
    -- A1 / A2 environment sensors
    a1 = {
        [0x01] = "check_sensors: temp@0x04-05, humidity@0x06-07, light@0x08, air_quality@0x0a, noise@0x0c",
    },
    a2 = {
        [0x01] = "check_sensors: temperature, humidity, light, pm10, pm2.5 and pm1 at fixed offsets in payload",
    },
    -- SP1 legacy plug
    sp1 = {
        [0x66] = "set power state (0=off, 1=on)",
    },
    -- SP2/SP3 classic smart plugs
    sp2 = {
        [0x01] = "power/status response",
        [0x02] = "set-power ack",
        [0x04] = "energy response (SP2S models)",
    },
    sp2s = {
        [0x01] = "power/status response",
        [0x02] = "set-power ack",
        [0x04] = "energy response: parsed from fixed offsets",
    },
    sp3 = {
        [0x01] = "power/status response",
        [0x02] = "set-power ack",
    },
    -- SP3S: energy request uses a fixed 10-byte payload; no single-byte subcmd
    sp3s = {},
    -- MP1 power strip
    mp1 = {
        [0x0a] = "port-state response: bitmask/nibble-style port states",
        [0x0d] = "set-port-power ack",
    },
    mp1s = {
        [0x0a] = "port-state response",
        [0x0d] = "set-port-power ack",
    },
    -- Dooya curtain motors
    dooya = {
        [0x09] = "curtain command family; action in packet[3]: 0x01=open, 0x02=close, 0x03=stop",
    },
    dooya2 = {
        [0x01] = "read percentage/position response",
        [0x02] = "write-action ack (open/close/stop/set percentage)",
    },
    -- Wistar blind motor (framed)
    wser = {
        [0x01] = "read position/state response",
        [0x02] = "write-action ack",
    },
    -- SP4 / BG1: JSON-framed payload, no single-byte subcmd
    sp4  = {},
    sp4b = {},
    bg1  = {},
    ehc31 = {},
}

-- Returns the sub-command name for a given device type code + sub-command byte.
local function get_subcmd_name(dev_type, subcmd)
    local info = get_device_info(dev_type)
    local tbl  = info and subcmd_by_class[info.type]
    if tbl and tbl[subcmd] then
        return tbl[subcmd]
    end
    return string.format("Unknown (0x%02x)", subcmd)
end

-- Device info table: maps device type code → { type = class, name = model }
-- 'type' follows python-broadlink class names; useful for protocol branching
-- (e.g. rm4mini/rm4pro use the 04 00 sub-command prefix; rmpro/rmmini do not).
-- Ref: https://raw.githubusercontent.com/mjg59/python-broadlink/refs/heads/master/broadlink/__init__.py
local device_info = {
    -- SP1
    [0x0000] = { type = "sp1",    name = "SP1 or Unknown" },
    -- SP2 family
    [0x2717] = { type = "sp2",    name = "NEO (Ankuoo)" },
    [0x2719] = { type = "sp2",    name = "SP2 (Honeywell)" },
    [0x271a] = { type = "sp2",    name = "SP2 (Honeywell)" },
    [0x7919] = { type = "sp2",    name = "SP2 (Honeywell)" },
    [0x791a] = { type = "sp2",    name = "SP2 (Honeywell)" },
    [0x2720] = { type = "sp2",    name = "SP Mini" },
    [0x2728] = { type = "sp2",    name = "SP Mini2" },
    [0x273e] = { type = "sp2",    name = "SP Mini" },
    [0x753e] = { type = "sp2",    name = "SP Mini 3" },
    [0x7d0d] = { type = "sp2",    name = "SP Mini 3 (OEM)" },
    -- 0x7530-0x7918: SP2 OEM range (checked dynamically in get_device_info)
    -- SP2 with energy monitoring
    [0x2711] = { type = "sp2s",   name = "SP2" },
    [0x2716] = { type = "sp2s",   name = "NEO PRO (Ankuoo)" },
    [0x271d] = { type = "sp2s",   name = "Ego (Efergy)" },
    [0x2736] = { type = "sp2s",   name = "SP Mini+" },
    -- SP3
    [0x2733] = { type = "sp3",    name = "SP3" },
    [0x7d00] = { type = "sp3",    name = "SP3-EU (OEM)" },
    -- SP3 with energy monitoring
    [0x9479] = { type = "sp3s",   name = "SP3S-EU" },
    [0x947a] = { type = "sp3s",   name = "SP3S-US" },
    -- SP4 family
    [0x7568] = { type = "sp4",    name = "SP4L-CN" },
    [0x756b] = { type = "sp4",    name = "SP4M-JP" },
    [0x756c] = { type = "sp4",    name = "SP4M" },
    [0x756f] = { type = "sp4",    name = "MCB1" },
    [0x7579] = { type = "sp4",    name = "SP4L-EU" },
    [0x757b] = { type = "sp4",    name = "SP4L-AU" },
    [0x7583] = { type = "sp4",    name = "SP Mini 3" },
    [0x7587] = { type = "sp4",    name = "SP4L-UK" },
    [0x7d11] = { type = "sp4",    name = "SP Mini 3" },
    -- RM Mini / RM3 (legacy, IR only)
    [0x2737] = { type = "rmmini", name = "RM Mini 3 (Blackbean)" },
    [0x278f] = { type = "rmmini", name = "RM Mini" },
    [0x27b7] = { type = "rmmini", name = "RM Mini 3" },
    [0x27c2] = { type = "rmmini", name = "RM Mini 3" },
    [0x27c7] = { type = "rmmini", name = "RM Mini 3" },
    -- RM Pro / RM2 (legacy, IR + RF)
    [0x2712] = { type = "rmpro",  name = "RM2 / RM Pro" },
    [0x272a] = { type = "rmpro",  name = "RM2 Pro Plus" },
    [0x273d] = { type = "rmpro",  name = "RM Pro (Phicomm)" },
    [0x277c] = { type = "rmpro",  name = "RM2 Home Plus GDT" },
    [0x2783] = { type = "rmpro",  name = "RM2 Home Plus" },
    [0x2787] = { type = "rmpro",  name = "RM2 Pro Plus2" },
    [0x278b] = { type = "rmpro",  name = "RM2 Pro Plus BL" },
    [0x2797] = { type = "rmpro",  name = "RM Pro+ HYC" },
    [0x279d] = { type = "rmpro",  name = "RM Pro+" },
    [0x27a1] = { type = "rmpro",  name = "RM2 Pro Plus R1" },
    [0x27a6] = { type = "rmpro",  name = "RM2 Pro PP" },
    [0x27a9] = { type = "rmpro",  name = "RM2 Pro Plus 300" },
    [0x27c3] = { type = "rmpro",  name = "RM Pro+" },
    -- RM Mini 3 new firmware (rmminib — IR only, newer protocol)
    [0x5f36] = { type = "rmminib", name = "RM Mini 3 (Red Bean)" },
    [0x6507] = { type = "rmminib", name = "RM Mini 3" },
    [0x6508] = { type = "rmminib", name = "RM Mini 3" },
    -- RM4 Mini (new protocol, uses 04 00 prefix in command payloads)
    [0x51da] = { type = "rm4mini", name = "RM4 Mini" },
    [0x5209] = { type = "rm4mini", name = "RM4 TV Mate" },
    [0x520c] = { type = "rm4mini", name = "RM4 Mini" },
    [0x520d] = { type = "rm4mini", name = "RM4C Mini" },
    [0x5211] = { type = "rm4mini", name = "RM4C Mate" },
    [0x5212] = { type = "rm4mini", name = "RM4 TV Mate" },
    [0x5216] = { type = "rm4mini", name = "RM4 Mini" },
    [0x521c] = { type = "rm4mini", name = "RM4 Mini" },
    [0x5224] = { type = "rm4mini", name = "RM5 Plus" },
    [0x6070] = { type = "rm4mini", name = "RM4C Mini" },
    [0x610e] = { type = "rm4mini", name = "RM4 Mini" },
    [0x610f] = { type = "rm4mini", name = "RM4C Mini" },
    [0x62bc] = { type = "rm4mini", name = "RM4 Mini" },
    [0x62be] = { type = "rm4mini", name = "RM4C Mini" },
    [0x6364] = { type = "rm4mini", name = "RM4S" },
    [0x648d] = { type = "rm4mini", name = "RM4 Mini" },
    [0x6539] = { type = "rm4mini", name = "RM4C Mini" },
    [0x653a] = { type = "rm4mini", name = "RM4 Mini" },
    -- RM4 Pro (new protocol, uses 04 00 prefix in command payloads)
    [0x520b] = { type = "rm4pro",  name = "RM4 Pro" },
    [0x5213] = { type = "rm4pro",  name = "RM4 Pro" },
    [0x5218] = { type = "rm4pro",  name = "RM4C Pro" },
    [0x6026] = { type = "rm4pro",  name = "RM4 Pro" },
    [0x6184] = { type = "rm4pro",  name = "RM4C Pro" },
    [0x61a2] = { type = "rm4pro",  name = "RM4 Pro" },
    [0x649b] = { type = "rm4pro",  name = "RM4 Pro" },
    [0x653c] = { type = "rm4pro",  name = "RM4 Pro" },
    -- A1 environment sensor
    [0x2714] = { type = "a1",     name = "A1" },
    -- MP1 power strip
    [0x4eb5] = { type = "mp1",    name = "MP1-1K4S" },
    [0x4f65] = { type = "mp1",    name = "MP1-1K3S2U" },
    [0x4ef7] = { type = "mp1s",   name = "MP1-1K4S (OEM)" },
    -- Hysen thermostat
    [0x4ead] = { type = "hysen",  name = "Hysen HY02/HY03" },
    -- Dooya curtain motor
    [0x4e4d] = { type = "dooya",  name = "Dooya DT360E" },
    -- S1C alarm kit
    [0x2722] = { type = "s1c",    name = "S1C (SmartOne Alarm Kit)" },
    -- BG Electrical
    [0x51e3] = { type = "bg1",    name = "BG800/BG900 (BG Electrical)" },
    [0x6480] = { type = "ehc31",  name = "EHC31 (BG Electrical)" },
}

-- Returns the full info record { type=..., name=... } for a device type code, or nil.
get_device_info = function(dev_type)
    if dev_type >= 0x7530 and dev_type <= 0x7918 then
        return { type = "sp2", name = "SP2 (OEM)" }
    end
    return device_info[dev_type]
end

-- Returns a display string "Model Name [class]", e.g. "RM4 Mini [rm4mini]".
local function get_device_name(dev_type)
    local info = get_device_info(dev_type)
    if info then
        return info.name .. " [" .. info.type .. "]"
    end
end

-- Returns "new" for devices that prefix command payloads with 04 00 <cmd>,
-- "classic" for devices that use a bare sub-command byte, or nil for unknown.
-- New-style classes: rmminib (Red Bean), rm4mini, rm4pro.
local function get_device_payload_style(dev_type)
    local info = get_device_info(dev_type)
    if not info then return nil end
    local t = info.type
    if t == "rmminib" or t == "rm4mini" or t == "rm4pro" then
        return "new"
    end
    return "classic"
end

local BroadlinkErrors = {
  [0]  = "Success",
  [-1] = "Authentication failed",
  [-2] = "Logged in from another device / session invalid",
  [-3] = "Device offline",
  [-4] = "Command not supported",
  [-5] = "Device storage full / module timeout",
  [-6] = "Structure abnormal",
  [-7] = "Control key expired",
}

local function decrypt_payload(enc_tvb)
    local len     = enc_tvb:len()
    local aligned = len - (len % 16)
    if aligned == 0 then return nil end
    if GcryptCipher ~= nil then
        local cipher = GcryptCipher.open(GCRY_CIPHER_AES, GCRY_CIPHER_MODE_CBC, 0)
        if not pcall(function() cipher:setkey(auth_key) end) then return nil end
        cipher:setiv(auth_iv)
        return cipher:decrypt(NULL, enc_tvb(0, aligned):bytes())  -- returns ByteArray
    elseif gcrypt ~= nil then
        local cipher = gcrypt.Cipher(gcrypt.CIPHER_AES128, gcrypt.CIPHER_MODE_CBC)
        if not pcall(function()
            cipher:setkey(fromhex(auth_key:tohex()))
            cipher:setiv(fromhex(auth_iv:tohex()))
        end) then return nil end
        local dec_str = cipher:decrypt(fromhex(enc_tvb(0, aligned):bytes():tohex()))
        return ByteArray.new(Struct.tohex(dec_str))
    end
    return nil
end

-- ── Checksum validation ────────────────────────────────────────────────────
-- BroadLink packets carry a 16-bit little-endian checksum at bytes 0x20–0x21.
-- Algorithm: start with 0xBEAF, add every byte in the packet (treating the
-- two checksum bytes as zero), then keep the lower 16 bits.
local function compute_checksum(tvb)
    local sum = 0xBEAF
    local raw = tvb():bytes()
    for i = 0, raw:len() - 1 do
        if i ~= 0x20 and i ~= 0x21 then
            sum = (sum + raw:get_index(i)) % 0x10000
        end
    end
    return sum
end

-- Adds the checksum ProtoField to `tree` and appends a [correct] / [INCORRECT]
-- annotation.  Returns the new tree item.
local function add_validated_checksum(tree, tvb)
    local stored   = tvb(0x20, 2):le_uint()
    local computed = compute_checksum(tvb)
    local item = tree:add_le(pf_checksum, tvb(0x20, 2))
    if stored == computed then
        item:append_text(" [correct]")
    else
        item:append_text(string.format(" [INCORRECT, expected 0x%04x]", computed))
        item:add_expert_info(PI_CHECKSUM, PI_WARN, "Bad checksum")
    end
    return item
end

-- Security mode names for AP provisioning
local ap_security_names = { [0]="None", [1]="WEP", [2]="WPA1", [3]="WPA2", [4]="WPA1/2" }

-- AP mode setup packet (136 bytes, sent to new device in AP mode, port 80 broadcast)
-- Offset 0x26 = 0x14 identifies this packet type.
-- Ref: protocol/index.md "New device setup"
local function dissect_ap_setup(tvb, pktinfo, tree)
    local join_tree = tree:add(broadlink, tvb(), "Join Request Payload")

    local ssid_len = tvb(0x84, 1):uint()
    local pwd_len  = tvb(0x85, 1):uint()
    local sec      = tvb(0x86, 1):uint()

    if ssid_len > 0 and ssid_len <= 32 then
        join_tree:add(pf_ap_ssid,     tvb(0x44, ssid_len))
    end
    if pwd_len > 0 and pwd_len <= 32 then
        join_tree:add(pf_ap_password, tvb(0x64, pwd_len))
    end
    join_tree:add(pf_ap_ssid_len,  tvb(0x84, 1))
    join_tree:add(pf_ap_pwd_len,   tvb(0x85, 1))
    local sec_name = ap_security_names[sec] or "Unknown"
    join_tree:add(pf_ap_security,  tvb(0x86, 1)):append_text(" (" .. sec_name .. ")")

    pktinfo.cols.info:set("Join Request: AP Setup")
end

local function dissect_discovery_request(tvb, tree)
    -- IP is stored in reversed byte order — read raw and flip
    local ip_raw = tvb(0x18, 4)
    local ip_str = string.format("%d.%d.%d.%d",
        ip_raw(3,1):uint(), ip_raw(2,1):uint(),
        ip_raw(1,1):uint(), ip_raw(0,1):uint())
    tree:add(pf_src_ip, ip_raw):set_text("Source IP: " .. ip_str)
    tree:add_le(pf_src_port,  tvb(0x1c, 2))
    add_validated_checksum(tree, tvb)
end

local function dissect_discovery_response(tvb, pktinfo, tree)
    tree:add(pf_magic,         tvb(0x00, 8))
    add_validated_checksum(tree, tvb)
    tree:add_le(pf_command,    tvb(0x26, 2)):append_text(" (Discovery Response)")
    tree:add_le(pf_packet_count, tvb(0x28, 2))

    if tvb:len() >= 0x36 then
        local dev_type = tvb(0x34, 2):le_uint()
        local dev_name = get_device_name(dev_type) or "Unknown Broadlink device"
        tree:add_le(pf_dev_type, tvb(0x34, 2)):append_text(" (" .. dev_name .. ")")
    end

    if tvb:len() >= 0x3a then
        local ip_raw = tvb(0x36, 4)
        local ip_str = string.format("%d.%d.%d.%d",
            ip_raw(3,1):uint(), ip_raw(2,1):uint(),
            ip_raw(1,1):uint(), ip_raw(0,1):uint())
        tree:add(pf_device_ip, ip_raw):set_text("Device IP: " .. ip_str)
    end

    if tvb:len() >= 0x40 then
        tree:add(pf_device_mac, tvb(0x3a, 6))
    end

    if tvb:len() >= 0x34 then
        tree:add_le(pf_device_id, tvb(0x30, 4))
    end

    if tvb:len() > 0x40 then
        -- ENC_UTF_8 = 0x00000002: device name is null-terminated UTF-8
        tree:add_packet_field(pf_device_name, tvb(0x40, math.min(64, tvb:len() - 0x40)), 0x00000002)
    end
end

local function dissect_base_packet(tvb, pktinfo, tree)
    tree:add(pf_magic,        tvb(0x00, 8))

    -- Date/Time
    local date_time_tree = tree:add(broadlink, tvb(0x30), "Date/Time")
    date_time_tree:add_le(pf_gmt_offset,   tvb(0x08, 4))
    date_time_tree:add_le(pf_year,         tvb(0x0c, 2))
    date_time_tree:add_le(pf_seconds,      tvb(0x0e, 1))
    date_time_tree:add_le(pf_minutes,      tvb(0x0f, 1))
    date_time_tree:add_le(pf_hours,        tvb(0x10, 1))

    local dow = tvb(0x11, 1):uint()
    local dow_name = (dow >= 1 and dow <= 7) and day_names[dow] or "Unknown"
    date_time_tree:add_le(pf_day_of_week,  tvb(0x11, 1)):append_text(" (" .. dow_name .. ")")
    date_time_tree:add_le(pf_day_of_month, tvb(0x12, 1))
    date_time_tree:add_le(pf_month,        tvb(0x13, 1))

    -- Padding bytes 0x14-0x17 are all zero in observed packets; skipping

    tree:add_le(pf_src_ip,    tvb(0x18, 4))
    tree:add_le(pf_src_port,  tvb(0x1c, 2))

    -- Padding bytes 0x1e-0x1f are all zero in observed packets; skipping

    add_validated_checksum(tree, tvb)
    local err_code = tvb(0x22, 2):le_uint()
    local err_item = tree:add_le(pf_error_code, tvb(0x22, 2))
    if err_code ~= 0 then
        local signed = err_code >= 0x8000 and err_code - 0x10000 or err_code
        err_item:append_text(" (" .. (BroadlinkErrors[signed] or "Unknown error") .. ") ←←← Warning: Response Error")
    end

    local dev_type = tvb(0x24, 2):le_uint()
    local dev_name = get_device_name(dev_type) or "Unknown"
    tree:add_le(pf_dev_type, tvb(0x24, 2)):append_text(" (" .. dev_name .. ")")

    local cmd = tvb(0x26, 2):le_uint()
    local cmd_name = payload_names[cmd] or "Unknown"
    tree:add_le(pf_command,  tvb(0x26, 2)):append_text(" (" .. cmd_name .. ")")
    pktinfo.cols.info:set(cmd_name)

    tree:add_le(pf_packet_count, tvb(0x28, 2))

    -- MAC is stored reversed (mac[5]..mac[0]) in controller→device packets
    do
        local m = tvb(0x2a, 6)
        local s = string.format("%02x:%02x:%02x:%02x:%02x:%02x",
            m(5,1):uint(), m(4,1):uint(), m(3,1):uint(),
            m(2,1):uint(), m(1,1):uint(), m(0,1):uint())
        tree:add(pf_mac, m):set_text("Destination MAC Address: " .. s)
    end

end

-- Hello Response (0x0007)
local function dissect_hello_response_packet(tvb, pktinfo, tree)
    local hello_response_tree = tree:add(broadlink, tvb(0x30, 0x50), "Hello Response Payload")
    hello_response_tree:add_le(pf_device_id,      tvb(0x30, 4))
    local dt = tvb(0x34, 2):le_uint()
    hello_response_tree:add_le(pf_dev_type, tvb(0x34, 2)):append_text(" (" .. (get_device_name(dt) or "Unknown") .. ")")
    hello_response_tree:add_le(pf_device_ip,      tvb(0x36, 4))
    do
        local m = tvb(0x3a, 6)
        local s = string.format("%02x:%02x:%02x:%02x:%02x:%02x",
            m(5,1):uint(), m(4,1):uint(), m(3,1):uint(),
            m(2,1):uint(), m(1,1):uint(), m(0,1):uint())
        hello_response_tree:add(pf_device_mac, m):set_text("MAC Address: " .. s)
    end

    -- ENC_UTF_8 = 0x00000002: device name is null-terminated UTF-8 (may contain Chinese characters)
    hello_response_tree:add_packet_field(pf_device_name, tvb(0x40, 60), 0x00000002)
    hello_response_tree:add(tvb(0x7e, 1), "Unknown byte: " .. string.format("0x%02x", tvb(0x7e, 1):uint()))
    hello_response_tree:add_le(pf_locked_status,  tvb(0x7f, 1)):append_text(" (" .. (locked_status[tvb(0x7f, 1):le_uint()] or "Unknown") .. ")")
end

local function encrypted(tvb, pktinfo, tree)

    if tvb:len() >= 0x34 then
        local dev_id = tvb(0x30, 4):le_uint()
        local id_item = tree:add_le(pf_device_id, tvb(0x30, 0x04))
        if dev_id == 0 then
            id_item:append_text(" (unpaired / pre-auth)")
        end
    end

    if tvb:len() >= 0x36 then
        tree:add_le(pf_payload_chksum, tvb(0x34, 2))
    end

    local pcommand = tvb(0x26, 2):le_uint()

    if tvb:len()-0x38 <= 0 then
        tree:add("Encrypted data length: " .. tvb:len()-0x38)
    else
        tree:add("Encrypted data: " .. tvb(0x38))
        if GcryptCipher == nil and gcrypt == nil then
            tree:add("[Decryption unavailable: install luagcrypt or use a Wireshark build with GcryptCipher Lua support]")
        else
            local ok, err = pcall(function()
                -- ── Select decryption key ──────────────────────────────────────
                local key_ba  -- ByteArray
                if pcommand == CMD.AUTH_REQUEST or pcommand == CMD.AUTH_RESPONSE then
                    key_ba = auth_key
                else
                    local device_ip = tostring(pktinfo.dst)
                    key_ba = session_keys[device_ip] or session_keys[tostring(pktinfo.src)]
                            or ByteArray.new(broadlink.prefs.aes_key)
                end

                -- ── Decrypt with available backend ─────────────────────────────
                local decrypted  -- ByteArray
                if GcryptCipher ~= nil then
                    local cipher = GcryptCipher.open(GCRY_CIPHER_AES, GCRY_CIPHER_MODE_CBC, 0)
                    if not pcall(function()
                        cipher:setkey(key_ba)
                        cipher:setiv(auth_iv)
                    end) then
                        tree:add("[Invalid decryption key set in protocol preferences]")
                        error("key setup failed")
                    end
                    decrypted = cipher:decrypt(NULL, tvb(0x38):bytes())
                else
                    -- luagcrypt fallback
                    local cipher = gcrypt.Cipher(gcrypt.CIPHER_AES128, gcrypt.CIPHER_MODE_CBC)
                    if not pcall(function()
                        cipher:setkey(fromhex(key_ba:tohex()))
                        cipher:setiv(fromhex(auth_iv:tohex()))
                    end) then
                        tree:add("[Invalid decryption key set in protocol preferences]")
                        error("key setup failed")
                    end
                    local dec_str = cipher:decrypt(fromhex(tvb(0x38):bytes():tohex()))
                    decrypted = ByteArray.new(Struct.tohex(dec_str))
                end

                local pt_tvb = ByteArray.tvb(decrypted, "Decrypted Payload")
                tree:add(pt_tvb(), "Decrypted: " .. decrypted:tohex())

                -- Auth request payload structure (0x0065):
                -- Ref: device.py Device.auth() — total encrypted payload is 0x50 bytes
                --   0x04–0x13  16 bytes: device identifier (0x31 * 16)
                --   0x1E       flag 0x01
                --   0x2D       flag 0x01
                --   0x30–0x35  device name ("Test 1")
                if pcommand == CMD.AUTH_REQUEST then

                    if decrypted:len() >= 0x14 then
                        tree:add(pt_tvb(0x04, 0x10), "Device Identifier: " .. decrypted(0x04, 0x10):tohex())
                    end
                    if decrypted:len() >= 0x1f then
                        tree:add(pt_tvb(0x1e, 0x01), "Flag[0x1E]: " .. string.format("0x%02x", decrypted(0x1e, 1):uint()))
                    end
                    if decrypted:len() >= 0x2e then
                        tree:add(pt_tvb(0x2d, 0x01), "Flag[0x2D]: " .. string.format("0x%02x", decrypted(0x2d, 1):uint()))
                    end
                    if decrypted:len() >= 0x36 then
                        local name_str = decrypted(0x30, 6):raw():match("^([^\0]*)")
                        tree:add(pt_tvb(0x30, 6), "Device Name: " .. (name_str ~= "" and name_str or "(empty)"))
                    end

                -- Auth response decrypted payload structure (0x3e9):
                elseif pcommand == CMD.AUTH_RESPONSE then

                    local resp_device_id = decrypted(0x00, 4):le_uint()
                    tree:add(pt_tvb(0x00, 0x04), "Device ID: " .. string.format("0x%08x", resp_device_id))
                    local session_key_ba = decrypted(0x04, 0x10)
                    tree:add(pt_tvb(0x04, 0x10), "Auth Key: " .. session_key_ba:tohex())
                    -- Cache the session key for subsequent command packets from this device
                    local device_ip = tostring(pktinfo.src)
                    if not session_keys[device_ip] then
                        session_keys[device_ip] = session_key_ba
                    end
                
                -- Command payload structure (0x006a / 0x03ee):
                -- New-style (rmminib/rm4*):  [0-1] length, [2] subcmd, data follows
                -- Classic   (rmmini/rmpro):  [0-3] subcmd as uint32 LE, data follows
                elseif pcommand == CMD.COMMAND_REQUEST or pcommand == CMD.COMMAND_RESPONSE then

                    local decrypted_len = decrypted:len()
                    local b0            = decrypted(0, 2):le_uint()
                    local dev_type      = tvb(0x24, 2):le_uint()

                    -- Detect protocol style from device type; fall back to byte heuristic.
                    local style  = get_device_payload_style(dev_type)
                    local is_new = (style == "new")
                    if style == nil then
                        -- Unknown device: guess from payload shape
                        is_new = decrypted_len >= 3
                                 and b0 == 0x0004
                                 and decrypted(1, 1):le_uint() == 0x00
                    end

                    -- New-style byte[2] is the subcmd; if it is 0x00 the payload is
                    -- actually classic-style (e.g. RM4 Pro auth response).
                    local subcmd = decrypted(0x02, 1):le_uint()
                    if subcmd == 0x00 then is_new = false end

                    local subcmd_offset
                    if is_new then
                        subcmd_offset = 0x02
                    else
                        subcmd        = b0
                        subcmd_offset = 0x00
                    end

                    tree:add(pt_tvb(0x00), "Protocol: " .. (is_new and "New" or "Classic"))

                    if is_new then
                        local payload_length = decrypted(0x00, 2):le_uint()
                        local subcmd_description = get_subcmd_name(dev_type, subcmd) or "Unknown"

                        tree:add(pt_tvb(0, 2), "Length: " .. payload_length .. string.format(" → (0x%04x)", payload_length))
                        tree:add(pt_tvb(2, 1), "Sub-command: " .. subcmd_description .. string.format(" → (0x%02x)", subcmd))

                        if subcmd == 0x24 then
                            -- rm4mini/rm4pro check_sensors: response data starts at offset 6
                            -- (after 2-byte length + 1-byte subcmd + 1 padding + 2 unknown)
                            -- temp = signed(byte[6]) + byte[7]/100.0
                            -- humi = byte[8] + byte[9]/100.0
                            if decrypted_len >= 0x0a then
                                local t_int = decrypted(0x06, 1):uint()
                                if t_int >= 0x80 then t_int = t_int - 0x100 end
                                local temperature = t_int + decrypted(0x07, 1):uint() / 100.0
                                local humidity    = decrypted(0x08, 1):uint() + decrypted(0x09, 1):uint() / 100.0
                                tree:add(pt_tvb(0x06, 2), "Temperature: " .. string.format("%.2f", temperature) .. " °C")
                                tree:add(pt_tvb(0x08, 2), "Humidity: "    .. string.format("%.2f", humidity)    .. " %")
                            end
                        end

                        -- JSON package with 0x5a5aa5a5 marker (observed with RM5)
                        if decrypted_len >= 16  and decrypted(2, 4):le_uint() == 0x5a5aa5a5 then
                            tree:add(pt_tvb(2, 4), "Magic Marker (0x5a5aa5a5)")
                            tree:add(pt_tvb(6, 4), "Unknown Data: 0x" .. decrypted(6, 4):tohex())
                            tree:add(pt_tvb(10, 4), "JSON Length: " .. decrypted(10, 4):le_uint())
                            local length = decrypted(0, 2):le_uint() - 12
                            local json_str = decrypted(14, length):raw():match("^([^\0]*)")
                            tree:add(pt_tvb(14, length), "JSON: \"" .. (json_str ~= "" and json_str or "(empty)") .. "\"")
                        end

                    else -- classic style
                        if subcmd == 0x00 and decrypted_len == 80 then 
                            tree:add(pt_tvb(0x00), "Command: Rename and Lock Device Query")
                            local name_str = decrypted(4, 0x30):raw():match("^([^\0]*)")
                            tree:add(pt_tvb(0x04, 0x30), "Name: " .. (name_str ~= "" and name_str or "(empty)"))
                            tree:add(pt_tvb(0x43, 0x01), "Locked: " .. (locked_status[decrypted(0x43, 1):le_uint()] or "Unknown") .. string.format(" (0x%02x)", decrypted(0x43, 1):le_uint()))
                            tree:append_text(" (Rename and Lock Device Query)")
                        elseif subcmd == 0x68 and decrypted_len >= 0x06 then
                            tree:add(pt_tvb(0x00), "Command: Firmware Version Query")
                            if pcommand == CMD.COMMAND_RESPONSE then
                                tree:add(pt_tvb(0x04, 0x02), "Firmware Version: " .. decrypted(0x04, 0x02):le_uint())
                                if decrypted_len >= 0x12 then
                                    tree:add(pt_tvb(0x10, 0x02), "Profile Version: " .. decrypted(0x10, 0x02):le_uint())
                                end
                            end
                        end
                    end

                    -- ── Send IR / RF  (subcmd 0x02) ────────────────────────────────
                    -- New-style (rmminib/rm4*): [0-1]=length, [2-3]=subcmd(0x0002), [4]=signal_type, [5]=repeat, [6-7]=data_len, [8+]=data
                    -- Classic (rmmini/rmpro):   [0-3]=cmd(0x00000002), [4]=signal_type, [5]=repeat, [6-7]=data_len, [8+]=data
                    if subcmd == 0x02 and pcommand == CMD.COMMAND_REQUEST then
                        -- signal_type@4, repeat@5, data_len@6-7, data@8+ (same layout for both styles)
                        if is_new then
                            tree:add(pt_tvb(0, 2), "Length: " .. decrypted(0, 2):le_uint() .. string.format(" (0x%04x)", decrypted(0, 2):le_uint()))
                            tree:add(pt_tvb(2, 2), "Sub-command: 0x0002 (send_data)")
                        else
                            tree:add(pt_tvb(0, 4), "Command: 0x00000002 (send_data)")
                        end
                        if decrypted_len >= 8 then
                            local sig      = decrypted(4, 1):le_uint()
                            local sig_name = signal_type_names[sig] or string.format("Unknown (0x%02x)", sig)
                            local data_len = decrypted(6, 2):le_uint()
                            tree:add(pt_tvb(4, 1), "Signal Type: "  .. sig_name)
                            tree:add(pt_tvb(5, 1), "Repeat Count: " .. decrypted(5, 1):le_uint())
                            tree:add(pt_tvb(6, 2), "Data Length: "  .. data_len .. string.format(" (0x%04x)", data_len))
                            if data_len > 0 and decrypted_len >= 8 + data_len then
                                tree:add(pt_tvb(8, data_len), "IR/RF Data: " .. decrypted(8, data_len):tohex())
                            end
                        end
                    elseif subcmd == 0x02 and pcommand == CMD.COMMAND_RESPONSE then
                        -- TODO: decode send_data response

                    -- ── SP2 / SP Mini set power  (subcmd 0x66) ──
                    elseif pcommand == CMD.COMMAND_RESPONSE and subcmd == 0x66 and decrypted_len >= subcmd_offset + 2 then
                        local state = decrypted(subcmd_offset + 1, 1):uint()
                        tree:add(pt_tvb(subcmd_offset + 1, 1),
                            "Power State: " .. (state == 1 and "On" or state == 0 and "Off" or string.format("0x%02x", state)))
                    end

                elseif decrypted:len() > 0 then
                    tree:add(pt_tvb(), "Decrypted payload (unparsed)")
                else
                    tree:add("Decrypted payload (unparsed)")
                end

            end)
            if not ok then
                tree:add("[Decryption failed: " .. tostring(err) .. "]")
            end
        end
    end
end

local function dissect_join_response(tvb, pktinfo, tree)
    pktinfo.cols.info:set("Join Response")
    if tvb:len() < 0x38 then return end
    local t = tree:add(broadlink, tvb(0x30), "Join Response Payload")
    if tvb:len() <= 0x38 then return end
    t:add("Encrypted data: " .. tvb(0x30))
    if GcryptCipher == nil and gcrypt == nil then
        t:add("[Decryption unavailable: install luagcrypt or use a Wireshark build with GcryptCipher Lua support]")
        return
    end
    local dec = decrypt_payload(tvb(0x30))
    if not dec then t:add("[Decryption failed]") return end
    local pt_tvb = ByteArray.tvb(dec, "Decrypted Payload")
    t:add(pt_tvb(), "Decrypted: " .. dec:tohex())
    local json_str = dec:raw():match("^([^\0]*)")
    if not json_str or json_str == "" then return end
    t:add(pt_tvb(), "JSON: " .. json_str)
    local function jstr(k) return json_str:match('"' .. k .. '"%s*:%s*"([^"]*)"') end
    local function jnum(k) return json_str:match('"' .. k .. '"%s*:%s*(%-?%d+)') end
    local hw     = jstr("hw")     if hw     then t:add(pt_tvb(), "Hardware Platform: " .. hw)                                     end
    local ver    = jnum("ver")    if ver    then t:add(pt_tvb(), "Firmware Version: "  .. ver)                                    end
    local svn    = jnum("svn")    if svn    then t:add(pt_tvb(), "SVN Revision: "      .. svn)                                    end
    local ssid   = jstr("ssid")   if ssid   then t:add(pt_tvb(), "SSID: "              .. (ssid ~= "" and ssid or "(not connected)")) end
    local bssid  = jstr("bssid")  if bssid  then t:add(pt_tvb(), "BSSID: "             .. bssid)                                  end
    local rssi   = jnum("rssi")   if rssi   then t:add(pt_tvb(), "RSSI: "              .. rssi)                                   end
    local uptime = jnum("uptime") if uptime then t:add(pt_tvb(), "Uptime (s): "        .. uptime)                                 end
    local devkey = jstr("devkey") if devkey then t:add(pt_tvb(), "Device Key: "        .. devkey)                                 end
    local did    = jstr("did")    if did    then t:add(pt_tvb(), "Device ID (did): "   .. did)                                    end
end

-- Check for Broadlink magic bytes at the start of the packet. Valid packets start with:
--   5a a5 aa 55 5a a5 xx xx  (first 6 bytes fixed; last 2 vary by firmware/version)
--   00 00 00 00 00 00 00 00  (used by some older clients)
-- Observed last-2-byte variants: aa 55 (classic), 00 00 (RM5+ / newer firmware)
local function has_magic(tvb)
    if tvb:len() < 8 then return false end
    local magic6 = tvb(0, 6):raw()
    local magic8 = tvb(0, 8):raw()
    return magic6 == "\x5a\xa5\xaa\x55\x5a\xa5"
        or magic8 == "\x00\x00\x00\x00\x00\x00\x00\x00"
end

-- ── Main dissector ─────────────────────────────────────────────────────────

function broadlink.dissector(tvb, pktinfo, root)
    local len = tvb:len()
    if len < 0x30 or not has_magic(tvb) then return 0 end

    pktinfo.cols.protocol:set("Broadlink")

    local tree = root:add(broadlink, tvb(), "Broadlink Smart Home Protocol")

    local payload_type = tvb(0x26, 2):le_uint()
    local payload_name = payload_names[payload_type] or string.format("Cmd 0x%04x", payload_type)
    tree:append_text(" (" .. payload_name .. ")")
    dissect_base_packet(tvb, pktinfo, tree)

    if payload_type == CMD.JOIN_REQUEST and len == 0x88 then
        -- Join Request (0x0014)
        pktinfo.cols.info:set("Join Request")
        tree:append_text(" (AP Mode Setup)")
        dissect_ap_setup(tvb, pktinfo, tree)
    elseif payload_type == CMD.JOIN_RESPONSE then
        -- Join Response: sent in reply to a Join Request on an unjoined device
        pktinfo.cols.info:set("Broadlink Join Response")
        tree:append_text(" (AP Mode Setup)")
        dissect_join_response(tvb, pktinfo, tree)
    elseif payload_type == CMD.JOIN_ERROR then
        -- Join Response Error: device is already joined
        pktinfo.cols.info:set("Broadlink Response Error")
    elseif payload_type == CMD.DISCOVERY_REQUEST then
        dissect_discovery_request(tvb, tree)
    elseif payload_type == CMD.DISCOVERY_RESPONSE then
        dissect_discovery_response(tvb, pktinfo, tree)
    elseif payload_type == CMD.PING then
        -- Ping / keepalive — no payload
        pktinfo.cols.info:set("Ping (Keepalive)")
    elseif payload_type == CMD.HELLO_REQUEST and len == 0x30 then
        -- Hello Request has no payload
        pktinfo.cols.info:set("Hello Request")
    elseif payload_type == CMD.HELLO_RESPONSE and len == 0x80 then
        dissect_hello_response_packet(tvb, pktinfo, tree)
    elseif payload_type == CMD.AUTH_REQUEST then
        -- Total packet = 0x38 header + 0x50 encrypted payload = 0x88 bytes
        if len >= 0x88 then
            encrypted(tvb, pktinfo, tree:add(broadlink, tvb(0x38), "Auth Request Payload"))
        end
    elseif payload_type == CMD.AUTH_RESPONSE then
        if len == 0x58 then
            encrypted(tvb, pktinfo, tree:add(broadlink, tvb(0x30, 0x28), "Auth Response Payload"))
        end
    elseif payload_type == CMD.COMMAND_REQUEST then
        if len >= 0x30 then
            encrypted(tvb, pktinfo, tree:add(broadlink, tvb(0x30), "Command Request Payload"))
        end
    elseif payload_type == CMD.COMMAND_RESPONSE then
        if len >= 0x30 then
            encrypted(tvb, pktinfo, tree:add(broadlink, tvb(0x30), "Command Response Payload"))
        end
    else
        tree:append_text(" (Unknown)")
        pktinfo.cols.info:set("Broadlink Unknown Packet (" .. string.format("0x%04x", payload_type) .. ")")
    end

    return len
end

-- ── Register on UDP ports ──────────────────────────────────────────────────
-- Discovery uses UDP port 80 (broadcast); commands use 80 and higher ports.
-- Add more ports here if needed.

local udp_table = DissectorTable.get("udp.port")
udp_table:add(default_settings.port, broadlink)
udp_table:add(16680, broadlink)
udp_table:add(16410, broadlink)  
udp_table:add(8899,  broadlink)  -- common Broadlink command port
udp_table:add(7795,  broadlink)  -- Cloud devices, observed with RM5+ on LAN
udp_table:add(1812,  broadlink)  -- Cloud devices, observed with RM5+ on LAN
dprint2("Broadlink dissector registered on UDP port", default_settings.port)
