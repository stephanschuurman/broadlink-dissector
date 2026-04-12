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

local broadlink = Proto("broadlink", "Broadlink Smart Home Protocol")

local auth_key = ByteArray.new("097628343fe99e23765c1513accf8b02")  -- 16 bytes, default Broadlink AES key
local auth_iv  = ByteArray.new("562e17996d093d28ddb3ba695a2e6f58")  -- 16 bytes, default Broadlink AES IV
broadlink.prefs.aes_key = Pref.string("Session key", auth_key:tohex(), "AES-128 session key (hex) — auto-populated from Auth Response, or enter manually")

-- Session key cache: device IP string → ByteArray(16)
-- Populated automatically when a 0x03e9 Auth Response is decrypted.
local session_keys = {}

-- ── Field definitions ──────────────────────────────────────────────────────

-- Shared
local pf_magic          = ProtoField.bytes ("broadlink.magic",            "Magic Bytes")

local pf_gmt_offset     = ProtoField.int32 ("broadlink.gmt_offset",       "GMT Offset (h)",     base.DEC)
local pf_year           = ProtoField.uint16("broadlink.year",             "Year",               base.DEC)
local pf_seconds        = ProtoField.uint8 ("broadlink.seconds",          "Seconds",            base.DEC)
local pf_minutes        = ProtoField.uint8 ("broadlink.minutes",          "Minutes",            base.DEC)
local pf_hours          = ProtoField.uint8 ("broadlink.hours",            "Hours",              base.DEC)
local pf_day_of_week    = ProtoField.uint8 ("broadlink.day_of_week",      "Day of Week",        base.DEC)
local pf_day_of_month   = ProtoField.uint8 ("broadlink.day_of_month",     "Day of Month",       base.DEC)
local pf_month          = ProtoField.uint8 ("broadlink.month",            "Month",              base.DEC)

local pf_src_ip         = ProtoField.ipv4  ("broadlink.src_ip",           "Source IP")
local pf_src_port       = ProtoField.uint16("broadlink.src_port",         "Source Port",        base.DEC)

local pf_checksum       = ProtoField.uint16("broadlink.checksum",         "Checksum",           base.HEX)
local pf_error_code     = ProtoField.uint16("broadlink.error_code",       "Error Code",         base.HEX)
local pf_dev_type       = ProtoField.uint16("broadlink.device_type",      "Device Type",        base.HEX)
local pf_payload_type   = ProtoField.uint16("broadlink.payload_type",     "Payload Type",       base.HEX)

local pf_packet_count   = ProtoField.uint16("broadlink.packet_count",     "Packet Count",       base.DEC)
local pf_mac            = ProtoField.ether ("broadlink.mac",              "MAC Address")

-- General assigned device ID; store for future packets
local pf_device_id      = ProtoField.uint32("broadlink.device_id",        "Device ID",          base.HEX)
local pf_device_name    = ProtoField.stringz("broadlink.device_name",     "Device Name")

-- Hello Response (0x0007)
local pf_device_type    = ProtoField.uint16("broadlink.device_type",      "Device Type",        base.HEX)
local pf_device_ip      = ProtoField.ipv4  ("broadlink.device_ip",        "Device IP")
local pf_device_mac     = ProtoField.ether ("broadlink.device_mac",       "Device MAC")

local pf_locked_status  = ProtoField.uint8 ("broadlink.locked_status",    "Locked Status",      base.DEC)

-- Authorization Request (0x0065)
local pf_device_iden    = ProtoField.bytes("broadlink.device_iden",      "Device Identifier (IMEI)")
local pf_flag           = ProtoField.uint8 ("broadlink.flag",             "Flag",                       base.HEX)

-- Authorization Response (0x03e9)
local pf_auth_key       = ProtoField.bytes("broadlink.auth_key",           "Auth Key")   


local pf_signal_type    = ProtoField.uint8 ("broadlink.signal_type",        "Signal Type",       base.HEX)
local pf_command        = ProtoField.uint16("broadlink.command",          "Command Code",       base.HEX)
local pf_payload_chksum = ProtoField.uint16("broadlink.payload_checksum", "Payload Checksum",   base.HEX)
local pf_payload        = ProtoField.bytes ("broadlink.payload",          "Encrypted Payload")

-- AP mode setup (new device provisioning)
local pf_ap_ssid        = ProtoField.string("broadlink.ap_ssid",          "SSID")
local pf_ap_password    = ProtoField.string("broadlink.ap_password",       "Password")
local pf_ap_ssid_len    = ProtoField.uint8 ("broadlink.ap_ssid_len",       "SSID Length",        base.DEC)
local pf_ap_pwd_len     = ProtoField.uint8 ("broadlink.ap_pwd_len",        "Password Length",    base.DEC)
local pf_ap_security    = ProtoField.uint8 ("broadlink.ap_security",       "Security Mode",      base.DEC)

-- Discovery response
local pf_device_ip      = ProtoField.ipv4  ("broadlink.device_ip",        "Device IP")
local pf_device_mac     = ProtoField.ether ("broadlink.device_mac",       "Device MAC")


broadlink.fields = {
    pf_magic, pf_checksum, pf_dev_type, pf_command, pf_packet_count,
    pf_mac, pf_auth_key, pf_device_iden, pf_flag, pf_signal_type,
    pf_device_id, pf_device_type, 
    pf_payload_type, pf_payload_chksum, pf_error_code, pf_payload,
    pf_gmt_offset, pf_year, pf_seconds, pf_minutes, pf_hours,
    pf_day_of_week, pf_day_of_month, pf_month, pf_src_ip, pf_src_port,
    pf_device_ip, pf_device_mac, pf_device_name, pf_locked_status,
    pf_ap_ssid, pf_ap_password, pf_ap_ssid_len, pf_ap_pwd_len, pf_ap_security,
}

-- ── Lookup tables ──────────────────────────────────────────────────────────

local payload_names = {
    [0x0006] = "Hello Request",
    [0x0007] = "Hello Response",
    [0x001a] = "Discovery Request",
    [0x001b] = "Discovery Response",
    [0x0014] = "Join Request",
    [0x0015] = "Join Response",
    [0x0065] = "Authorization Request",
    [0x03e9] = "Authorization Response",
    [0x006a] = "Command Request",
    [0x03ee] = "Command Response",
    [0x0398] = "Join Response Error?"
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
    [0] = "Unknown",
    [1] = "Locked",
    [2] = "Unlocked",
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
        [0x01] = "get/update status / sensor read",
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
        [0x68] = "???",
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
        [0x01] = "sensor response: temp@0x04-05, humidity@0x06-07, light@0x08, air_quality@0x0a, noise@0x0c",
    },
    a2 = {
        [0x01] = "sensor response (framed): values at fixed offsets",
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

local function toSigned16(value)
  if value >= 0x8000 then
    return value - 0x10000
  end
  return value
end

local function decodeBroadlinkError(value)
  local signed = toSigned16(value)
  return {
    hex = string.format("0x%04X", value),
    signed = signed,
    message = BroadlinkErrors[signed] or "Unknown error"
  }
end

local function decrypt_payload(enc_tvb)
    if GcryptCipher == nil then return nil end
    local cipher = GcryptCipher.open(GCRY_CIPHER_AES, GCRY_CIPHER_MODE_CBC, 0)
    if not pcall(function() cipher:setkey(auth_key) end) then return nil end
    cipher:setiv(auth_iv)
    -- AES-CBC requires input to be a multiple of 16 bytes; truncate any trailing padding
    local len = enc_tvb:len()
    local aligned = len - (len % 16)
    if aligned == 0 then return nil end
    return cipher:decrypt(NULL, enc_tvb(0, aligned):bytes())  -- returns ByteArray
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
    local join_tree = tree:add(broadlink, tvb(), "AP Mode Setup")
    add_validated_checksum(join_tree, tvb)

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

    pktinfo.cols.info:set("AP Setup")
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
    local err_item = tree:add_le(pf_error_code, tvb(0x22, 2))
    if tvb(0x22, 2):le_uint() ~= 0 then
        local err = decodeBroadlinkError(tvb(0x22, 2):le_uint())
        err_item:append_text(" (" .. err.message .. ") ←←← Warning: Response Error")
    end

    local dev_type = tvb(0x24, 2):le_uint()
    local dev_name = get_device_name(dev_type) or "Unknown"
    tree:add_le(pf_dev_type, tvb(0x24, 2)):append_text(" (" .. dev_name .. ")")

    local cmd = tvb(0x26, 2):le_uint()
    local cmd_name = payload_names[cmd] or "Unknown"
    tree:add_le(pf_command,  tvb(0x26, 2)):append_text(" (" .. cmd_name .. ")")
    pktinfo.cols.info:set("" .. cmd_name)

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
    if tvb:len() < 0x80 then return end

    local hello_response_tree = tree:add(broadlink, tvb(0x30, 0x50), "Hello Response Payload")
    hello_response_tree:add_le(pf_device_id,      tvb(0x30, 4))
    local dt = tvb(0x34, 2):le_uint()
    hello_response_tree:add_le(pf_device_type, tvb(0x34, 2)):append_text(" (" .. (get_device_name(dt) or "Unknown") .. ")")
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
    hello_response_tree:add_le(pf_locked_status,  tvb(0x7e, 1)):append_text(" (" .. (locked_status[tvb(0x7e, 1):le_uint()] or "Unknown") .. ")")
    -- Padding bytes 0x4f-0x4f are all zero in observed packets; skipping
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

    -- tree:add(pf_payload,       tvb(0x38))

    local pcommand = tvb(0x26,2):le_uint()

    if tvb:len()-0x38 <= 0 then
        tree:add("Encrypted data length: " .. tvb:len()-0x38)
    else
        tree:add("Encrypted data: " .. tvb(0x38))
        if GcryptCipher == nil then
            tree:add("[Decryption unavailable: Wireshark build does not expose GcryptCipher to Lua]")
        else
            local ok, err = pcall(function()
                local cipher = GcryptCipher.open(GCRY_CIPHER_AES, GCRY_CIPHER_MODE_CBC, 0)

                if not pcall(function()
                        -- Auth Request (0x65), Auth Response (0x3e9) and Join Response (0x0015) use the default AES128 key
                        if pcommand == 0x65 or pcommand == 0x3e9 or pcommand == 0x0015 then
                            cipher:setkey(auth_key)
                        else
                            -- Prefer auto-cached session key for this device; fall back to preference
                            local device_ip = tostring(pktinfo.dst)
                            local cached = session_keys[device_ip]
                                        or session_keys[tostring(pktinfo.src)]
                            if cached then
                                cipher:setkey(cached)
                            else
                                cipher:setkey(ByteArray.new(broadlink.prefs.aes_key))
                            end
                        end
                        cipher:setiv(auth_iv)
                    end) then
                    tree:add("[Invalid decryption key set in protocol preferences]")
                    error("key setup failed")
                end

                local decrypted = cipher:decrypt(NULL, tvb(0x38):bytes())
                local pt_tvb = ByteArray.tvb(decrypted, "Decrypted Payload")
                tree:add(pt_tvb(), "Decrypted: " .. decrypted:tohex())

                -- Auth request payload structure (0x0065):
                if pcommand == 0x0065 then

                    tree:add(pt_tvb(0x04, 0x10), "Device Identifier (IMEI): " .. decrypted(0x04, 0x0F):tohex())
                    local flag = decrypted(0x1c, 1):uint()
                    tree:add(pt_tvb(0x1c, 0x01), "Flag: " .. string.format("0x%02x", flag))
                    -- Client name: 0x30–0x4f, 32 bytes, NULL-terminated ASCII (zero-padded)
                    local raw_name = decrypted(0x30, 0x20)
                    local name_str = raw_name:raw():match("^([^\0]*)")
                    tree:add(pt_tvb(0x30, 0x20), "Client Name: " .. (name_str ~= "" and name_str or "(empty)"))
                    -- Reserved: 0x50–0x53, 4 bytes
                    tree:add(pt_tvb(0x50, 0x04), "Reserved: " .. decrypted(0x50, 0x04):tohex())
                    -- Auth Blob: 0x54–0x63, 16 bytes
                    tree:add(pt_tvb(0x54, 0x10), "Auth Blob: " .. decrypted(0x54, 0x10):tohex())
                    -- Metadata JSON: 0x64 onwards, variable length
                    if decrypted:len() > 0x64 then
                        local json_len = decrypted:len() - 0x64
                        local json_str = decrypted(0x64, json_len):raw():match("^([^\0]*)")
                        tree:add(pt_tvb(0x64, json_len), "Metadata JSON: " .. (json_str ~= "" and json_str or "(empty)"))
                    end

                -- Join Response decrypted payload structure (0x0015): JSON status blob
                elseif pcommand == 0x0015 then

                    local json_str = decrypted:raw():match("^([^\0]*)")
                    tree:add(pt_tvb(), "JSON: " .. (json_str ~= "" and json_str or "(empty)"))
                    -- Extract notable fields
                    local function jstr(key) return json_str:match('"' .. key .. '"%s*:%s*"([^"]*)"') end
                    local function jnum(key) return json_str:match('"' .. key .. '"%s*:%s*(%-?%d+)') end
                    local hw      = jstr("hw")      if hw      then tree:add(pt_tvb(), "Hardware Platform: " .. hw)      end
                    local ver     = jnum("ver")     if ver     then tree:add(pt_tvb(), "Firmware Version: "  .. ver)     end
                    local svn     = jnum("svn")     if svn     then tree:add(pt_tvb(), "SVN Revision: "      .. svn)     end
                    local ssid    = jstr("ssid")    if ssid    then tree:add(pt_tvb(), "SSID: "              .. (ssid ~= "" and ssid or "(not connected)")) end
                    local bssid   = jstr("bssid")   if bssid   then tree:add(pt_tvb(), "BSSID: "             .. bssid)   end
                    local rssi    = jnum("rssi")    if rssi    then tree:add(pt_tvb(), "RSSI: "              .. rssi)    end
                    local uptime  = jnum("uptime")  if uptime  then tree:add(pt_tvb(), "Uptime (s): "        .. uptime)  end
                    local devkey  = jstr("devkey")  if devkey  then tree:add(pt_tvb(), "Device Key: "        .. devkey)  end
                    local did     = jstr("did")     if did     then tree:add(pt_tvb(), "Device ID: "         .. did)     end

                -- Auth response decrypted payload structure (0x3e9):
                elseif pcommand == 0x3e9 then

                    local resp_device_id = decrypted(0x00, 4):le_uint()
                    tree:add(pt_tvb(0x00, 0x04), "Device ID: " .. string.format("0x%08x", resp_device_id))
                    local session_key_hex = decrypted(0x04, 0x10):tohex()
                    local session_key_ba  = decrypted(0x04, 0x10)
                    tree:add(pt_tvb(0x04, 0x10), "Auth Key: " .. session_key_hex)
                    -- Cache the session key for subsequent command packets from this device
                    local device_ip = tostring(pktinfo.src)
                    if not session_keys[device_ip] then
                        session_keys[device_ip] = session_key_ba
                    end
                
                -- Command request decrypted payload structure (0x006a):
                elseif pcommand == 0x006a or pcommand == 0x3ee then

                    local decrypted_len = decrypted:len()
                    -- Classic Broadlink devices (RM2/RM3/SP1/SP2) respond to auth with a 20-byte payload containing:
                    --   0x00–0x03  Device ID assigned by the device (uint32 LE)
                    --   0x04–0x13  AES-128 key for all subsequent command packets
                    local b0 = decrypted(0, 2):le_uint()
                    -- tree:add(pt_tvb(0,1), "Sub-command: " .. string.format("0x%02x", b0))

                    local dev_type = tvb(0x24, 2):le_uint()
                    -- RM4 / Red Bean devices prefix commands with  04 00 <cmd>.
                    -- Use the device type for reliable detection; fall back to
                    -- byte heuristic for unknown/unregistered devices.
                    local style = get_device_payload_style(dev_type)
                    local is_new
                    if style == "new" then
                        is_new = true
                    elseif style == "classic" then
                        is_new = false
                    else
                        -- Unknown device: guess from payload bytes
                        is_new = decrypted_len >= 3
                                 and b0 == 0x0004
                                 and decrypted(1,1):le_uint() == 0x00
                    end
                    local subcmd, subcmd_off
                    if is_new then
                        
                        subcmd     = decrypted(0x02, 1):le_uint()
                        subcmd_off = 0x02
                    else
                        subcmd     = b0
                        subcmd_off = 0x00
                    end
                    
    -- if outer_cmd == 0x006a or outer_cmd == 0x03ee:
    -- read first u32 little-endian as inner_opcode

    -- if inner_opcode == 0x00000002:
    --     decode as send_data:
    --         u8 signal_type
    --         u8 repeat
    --         u16 data_len
    --         bytes raw_data
    -- elif inner_opcode == 0x00000068:
    --     decode as rm5_status_action:
    --         u32 opcode
    --         remaining bytes as status words / reserved
    -- else:
    --     show as generic opaque inner payload

                    tree:add(pt_tvb(0x00), "Protocol: " .. (is_new and "New" or "Classic") .. ", Length: " ..  decrypted_len )

                    local subcmd_name = get_subcmd_name(dev_type, subcmd)
                    local subcmd_item = tree:add(pt_tvb(subcmd_off, 1), "Sub-command: " .. subcmd_name .. string.format(" → (0x%02x)", subcmd))
                    tree:add(pt_tvb(2, 4), "Subcommand: " .. string.format("0x%06x", decrypted(2, 4):le_uint())) 

                    -- Sensor reading (subcmd 0x24) ─────────────────────────────────────
                     -- and subcmd == 0x24

                    if is_new then
                        
                        -- Naming package? (observed in RM5 auth response)
                        if decrypted_len == 80 and decrypted(0, 4):le_uint() == 0x00 then
                            local name_str = decrypted(4, 0x30):raw():match("^([^\0]*)")
                            tree:add(pt_tvb(4, 0x30), "Name: " .. (name_str ~= "" and name_str or "(empty)"))
                        -- JSON package with 0x5a5aa5a5 marker (observed with RM5)
                        elseif decrypted_len >= 16  and decrypted(2, 4):le_uint() == 0x5a5aa5a5 then
                            tree:add(pt_tvb(2, 4), "Magic Marker (0x5a5aa5a5)")
                            tree:add(pt_tvb(6, 4), "Unknown Data: 0x" .. decrypted(6, 4):tohex())
                            tree:add(pt_tvb(10, 4), "JSON Length: " .. decrypted(10, 4):le_uint())
                            local length = decrypted(0, 2):le_uint() - 12
                            local json_str = decrypted(14, length):raw():match("^([^\0]*)")
                            tree:add(pt_tvb(14, length), "JSON: \"" .. (json_str ~= "" and json_str or "(empty)") .. "\"")
                        end



                        -- tree:add(pt_tvb(4, 0x30), "Data: " .. decrypted(4, 0x30):tohex())
                            -- subcmd_item:add_text(" (truncated payload, cannot parse)")



                        -- local msg_len = decrypted(0, 2):le_uint()
                        -- tree:add(pt_tvb(0,2), "Length: " .. string.format("%d", msg_len) ..  " (" .. string.format("0x%04x", msg_len) .. ") => " ..  decrypted_len )
                        -- tree:add(pt_tvb(2,4), "Command: " .. string.format("0x%06x", decrypted(2, 4):le_uint()))
                        -- tree:add(pt_tvb(6, msg_len - 4), "Data: 0x" .. decrypted(6, msg_len - 4):tohex())
                        --local sensor_id = decrypted(subcmd_off + 1, 1):uint()
                        --local sensor_name = get_sensor_name(dev_type, sensor_id)
                        -- tree:add(pt_tvb(subcmd_off + 1, 1), "Sensor ID: " .. sensor_name .. string.format(" (0x%02x)", sensor_id))
                    
                    
                    end



                    -- ── Send IR / RF  (subcmd 0x02) ────────────────────────────────
                    if subcmd == 0x02 and decrypted_len >= subcmd_off + 6 then
                        tree:add(pt_tvb(0, 2), "Length: " .. decrypted(0, 2):le_uint() .. " (" .. string.format("0x%04x", decrypted(0, 2):le_uint()) .. ")") 
                        tree:add(pt_tvb(2, 4), "Subcommand: " .. string.format("0x%06x", decrypted(2, 4):le_uint())) 
                        
                        if pcommand == 0x006a then
                            local sig = decrypted(6, 1):le_uint()
                            local sig_name = signal_type_names[sig] or string.format("Unknown (0x%02x)", sig)
                            tree:add(pt_tvb(6, 1), "Signal Type: " .. sig_name)
                            tree:add(pt_tvb(7, 1), "Repeat Count: " .. decrypted(7, 1):le_uint()) 
                            local data_len = decrypted(8, 2):le_uint()
                            tree:add(pt_tvb(8, 2), "Length: " .. data_len .. " (" .. string.format("0x%04x",data_len) .. ")")
                            tree:add(pt_tvb(10, data_len), "Data: " .. decrypted(10, data_len):tohex()) 
                        
                        elseif pcommand == 0x3ee then


                        end

    


                        -- local data_off = subcmd_off + 1          -- byte after subcmd
                        -- repeat count: 1 byte
                        -- local repeat_cnt = decrypted(data_off  +4 , 1):uint()
                        -- tree:add(pt_tvb(data_off, 1), "Repeat Count: " .. repeat_cnt)
                        -- signal type: 1 byte
                        -- if decrypted:len() >= data_off + 2 then
                        --     local sig = decrypted(data_off + 1, 1):uint()
                        --     local sig_name = signal_type_names[sig] or string.format("Unknown (0x%02x)", sig)
                        --     tree:add(pt_tvb(data_off + 1, 1), "Signal Type: " .. sig_name)
                        -- end
                        -- data length: uint16 LE  (bytes data_off+2 .. data_off+3)
                        -- if decrypted:len() >= data_off + 4 then
                        --     local dlen = decrypted(data_off + 2, 2):le_uint()
                        --     tree:add(pt_tvb(data_off + 2, 2), "Data Length: " .. dlen)
                        --     -- raw IR/RF pulse data starts at data_off+4
                        --     local pulse_off = data_off + 4
                        --     if decrypted:len() > pulse_off then
                        --         local pulse_len = decrypted:len() - pulse_off
                        --         tree:add(pt_tvb(pulse_off, pulse_len),
                        --             "IR/RF Data (" .. pulse_len .. " bytes): "
                        --             .. decrypted(pulse_off, pulse_len):tohex())
                        --     end
                        -- end

                    -- ── SP2 / SP Mini set power  (subcmd 0x01 from outer device type) ──
                    elseif pcommand == 0x3ee and subcmd == 0x66 and decrypted:len() >= subcmd_off + 2 then
                        local state = decrypted(subcmd_off + 1, 1):uint()
                        tree:add(pt_tvb(subcmd_off + 1, 1),
                            "Power State: " .. (state == 1 and "On" or state == 0 and "Off" or string.format("0x%02x", state)))
                    end

                -- elseif pcommand == 0x3ee then
                --     -- Command response decrypted payload:
                --     local subcmd = decrypted(0,1):uint()
                --     tree:add(pt_tvb(0,1), "Sub-command: " .. string.format("0x%02x", subcmd))
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



    -- if tvb:len()-0x38 <= 0 then
    --         subtree:add("Encrypted data length: " .. tvb:len()-0x38)
    --     else
    --         subtree:add("Encrypted data: " .. tvb(0x38))

    --         -- Decrypt content.
    --         local cipher = gcrypt.Cipher(gcrypt.CIPHER_AES128, gcrypt.CIPHER_MODE_CBC)
    --         if not pcall(function()
    --             -- auth request (0x65) and response (0x3e9) uses the default AES128 key 
    --             if pcommand == 0x65 or pcommand == 0x3e9 then
    --                 cipher:setkey(fromhex(default_settings.aes_defkey))
    --             else
    --                 cipher:setkey(fromhex(broadlink.prefs.aes_key))
    --             end
    --             cipher:setiv(fromhex("562e17996d093d28ddb3ba695a2e6f58"))
    --         end) then
    --             subtree:add("Invalid decryption key set in protocol preferences.")
    --         end

    --         if not pcall(function()
    --             decrypted = cipher:decrypt(fromhex(tostring(buffer(0x38):bytes())))
    --             local buff = ByteArray.new(Struct.tohex(decrypted))
    --             local bufFrame = ByteArray.tvb(buff, "Decrypted buffer")
    --             decrtree = subtree:add(bufFrame(),"Decrypted payload")
    --             decrtree:add(f_message_payloaddec_b, bufFrame() )
    --             if pcommand == 0x3e9 then
    --                 decrtree:add_le(f_decr_authstatus, bufFrame(0x00,4))
    --                 decrtree:add(f_decr_aeskey,bufFrame(0x04,16))
    --             elseif pcommand == 0x65 then
    --                 decrtree:add(f_decr_authstr1, bufFrame(0x04,40))
    --                 decrtree:add(f_decr_authstr2, bufFrame(0x30,32))
    --                 decrtree:add(f_decr_authstr3, bufFrame(0x64))
    --                 decrtree:add(f_decr_aesalt, bufFrame(0x54,16))
    --             else
    --                 decrtree:add_le(f_decr_length, bufFrame(0x00,2))
    --                 decrtree:add(buffer(0,8),"Connection ID: 0x" .. tostring(bufFrame(0x02,4)))
    --                 decrtree:add_le(f_message_chksump,bufFrame(0x06,2))
    --                 decrtree:add(f_decr_cmdtype, bufFrame(0x08,1))
    --                 decrtree:add_le(f_decr_clength, bufFrame(0x0a,2))
    --                 decrtree:add(f_decr_command, bufFrame(0x0e))
    --             end
    --         end) then
    --             subtree:add("Unable to decrypt")
    --         end            

    --     end
    -- end

end

local function dissect_join_response(tvb, pktinfo, tree)
    pktinfo.cols.info:set("Join Response")
    if tvb:len() < 0x38 then return end
    local t = tree:add(broadlink, tvb(0x30), "Join Response Payload")
    if tvb:len() <= 0x38 then return end
    t:add("Encrypted data: " .. tvb(0x30))
    if GcryptCipher == nil then
        t:add("[Decryption unavailable: Wireshark build does not expose GcryptCipher to Lua]")
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
    local hw     = jstr("hw")     if hw     then t:add(pt_tvb(), "Hardware Platform: "              .. hw)                               end
    local ver    = jnum("ver")    if ver    then t:add(pt_tvb(), "Firmware Version: "               .. ver)                              end
    local svn    = jnum("svn")    if svn    then t:add(pt_tvb(), "SVN Revision: "                   .. svn)                              end
    local ssid   = jstr("ssid")   if ssid   then t:add(pt_tvb(), "SSID: "                           .. (ssid ~= "" and ssid or "(not connected)"))   end
    local bssid  = jstr("bssid")  if bssid  then t:add(pt_tvb(), "BSSID: "                          .. bssid)                           end
    local rssi   = jnum("rssi")   if rssi   then t:add(pt_tvb(), "RSSI: "                           .. rssi)                            end
    local uptime = jnum("uptime") if uptime then t:add(pt_tvb(), "Uptime (s): "                     .. uptime)                          end
    local devkey = jstr("devkey") if devkey then t:add(pt_tvb(), "Device Key: "                     .. devkey)                          end
    local did    = jstr("did")    if did    then t:add(pt_tvb(), "Device ID (did, MAC): "           .. did)                             end
end

-- Authorization Request (0x0065)
local function dissect_auth_request_packet(tvb, pktinfo, tree)
    if tvb:len() < 0x0108 then return end

    local auth_request_tree = tree:add(broadlink,       tvb(0x30, 0x0108), "Auth Request Payload")
    encrypted(tvb, pktinfo, auth_request_tree)



    -- auth_request_tree:add_le(pf_device_iden,            tvb(0x34, 0x12)) 
    -- auth_request_tree:add_le(pf_flag,               tvb(0x34, 15))  
    -- pf_flag, pf_device_name,

end

-- Authorization Response (0x03e9)
local function dissect_auth_response_packet(tvb, pktinfo, tree)
    if tvb:len() ~= 0x58 then return end

    local auth_response_tree = tree:add(broadlink,      tvb(0x30, 0x28), "Auth Response Payload")
    encrypted(tvb, pktinfo, auth_response_tree)
    -- auth_response_tree:add_le(pf_device_id,             tvb(0x30, 0x04))
    -- auth_response_tree:add_le(pf_auth_key,              tvb(0x34, 0x24))

end

-- Command Request (0x006a)
local function dissect_command_request_packet(tvb, pktinfo, tree)
    if tvb:len() < 0x30 then return end

    local command_request_tree = tree:add(broadlink, tvb(0x30), "Command Request Payload")
    encrypted(tvb, pktinfo, command_request_tree)
    -- command_request_tree:add_le(pf_device_id,        tvb(0x30, 0x04))
    -- local signal_type = tvb(0x34, 1):le_uint()
    -- command_request_tree:add_le(pf_signal_type, tvb(0x34, 1)):append_text(" (" .. (signal_type_names[signal_type] or "Unknown") .. ")")
    -- command_request_tree:add(pf_payload,       tvb(0x38))


    -- if tvb:len() > 0x38 then
    --     local pl_item = tree:add(pf_payload, tvb(0x38))
    --     -- Annotate known 0x006a sub-commands from the first plaintext byte.
    --     -- The payload is AES-CBC encrypted on the wire; the annotation is a hint only.
    --     if tvb:len() >= 0x28 then
    --         local cmd = tvb(0x26, 2):le_uint()
    --         if cmd == 0x006a and tvb:len() > 0x39 then
    --             local b0 = tvb(0x38, 1):uint()
    --             local b1 = tvb(0x39, 1):uint()
    --             local b2 = tvb:len() > 0x3a and tvb(0x3a, 1):uint() or nil
    --             local hint = nil
    --             -- RM4 / Red Bean prefix 04 00 xx
    --             if b0 == 0x04 and b1 == 0x00 and b2 ~= nil then
    --                 if     b2 == 0x03 then hint = "Enter IR learning (RM4/Red Bean)"
    --                 elseif b2 == 0x04 then hint = "Check captured IR / RF data (RM4)"
    --                 elseif b2 == 0x19 then hint = "Enter RF sweep (RM4 Pro)"
    --                 elseif b2 == 0x1a then hint = "Check RF frequency (RM4 Pro)"
    --                 elseif b2 == 0x1b then hint = "Read captured RF data (RM4 Pro)"
    --                 elseif b2 == 0x1e then hint = "Cancel RF sweep (RM4 Pro)"
    --                 end
    --             -- RM3 Red Bean send: d0 00 02
    --             elseif b0 == 0xd0 and b1 == 0x00 and b2 == 0x02 then
    --                 hint = "Send IR/RF data (RM3 Red Bean / RM4 Mini)"
    --             -- RM4 Pro send: da 00 02
    --             elseif b0 == 0xda and b1 == 0x00 and b2 == 0x02 then
    --                 hint = "Send IR/RF data (RM4 Pro)"
    --             -- Temp/humidity: byte[2] = 0x24 (first 2 bytes may be 0,0)
    --             elseif b0 == 0x00 and b1 == 0x00 and b2 == 0x24 then
    --                 hint = "Check temperature / humidity (RM4 Pro)"
    --             -- Send data (RM2/RM3 standard): payload[0]=0x02, payload[4]=signal type
    --             elseif b0 == 0x02 then
    --                 local signal = ""
    --                 if tvb:len() > 0x3c then
    --                     local sig_byte = tvb(0x3c, 1):uint()
    --                     if     sig_byte == 0x26 then signal = " — IR"
    --                     elseif sig_byte == 0xb2 then signal = " — RF 433 MHz"
    --                     elseif sig_byte == 0xd7 then signal = " — RF 315 MHz"
    --                     end
    --                 end
    --                 hint = "Send IR/RF data (RM2/RM3 standard)" .. signal
    --             else
    --                 hint = subcmd_request_006a[b0]
    --             end
    --             if hint then
    --                 pl_item:append_text(" — " .. hint)
    --             end
    --         end
    --     end
    -- end
end

-- Command Response (0x03ee)
local function dissect_command_response_packet(tvb, pktinfo, tree)
    if tvb:len() < 0x30 then return end

    local command_response_tree = tree:add(broadlink, tvb(0x30), "Command Response Payload")
    encrypted(tvb, pktinfo, command_response_tree)
    -- command_response_tree:add_le(pf_device_id,         tvb(0x30, 0x04))

end

-- Check for Broadlink magic bytes at the start of the packet. Valid packets have either:
--   5a a5 aa 55 5a a5 aa 55
--   00 00 00 00 00 00 00 00 (used by some clients)
local function has_magic(tvb)
    if tvb:len() >= 8 and tvb(0, 8):raw() == "\x5a\xa5\xaa\x55\x5a\xa5\xaa\x55" then
        return true
    elseif tvb:len() >= 8 and tvb(0, 8):raw() == "\x00\x00\x00\x00\x00\x00\x00\x00" then
        return true
    end
    return false
end

-- ── Main dissector ─────────────────────────────────────────────────────────

function broadlink.dissector(tvb, pktinfo, root)
    local len = tvb:len()


    if len < 0x30 or not has_magic(tvb) then return 0 end

    pktinfo.cols.protocol:set("Broadlink")

    local tree = root:add(broadlink, tvb(), "Broadlink Smart Home Protocol")

    if len >= 0x30 then
        local payload_type = tvb(0x26, 2):le_uint()
        local payload_name = payload_names[payload_type] or string.format("Cmd 0x%04x", payload_type)
        tree:append_text(" (" .. payload_name .. ")")
        dissect_base_packet(tvb, pktinfo, tree)
    
        if payload_type == 0x0014 and len == 0x88 then
            -- Join Request (0x0014)
            pktinfo.cols.info:set("Join Request")
            tree:append_text(" (AP Mode Setup)")
            dissect_ap_setup(tvb, pktinfo, tree)
        elseif payload_type == 0x0015 then
            -- Join Response (0x0015), found when sending 0x0014 Join Request to an unjoined device
            pktinfo.cols.info:set("Broadlink Join Response")
            tree:append_text(" (AP Mode Setup)")
            dissect_join_response(tvb, pktinfo, tree)
        elseif payload_type == 0x0398 then
            -- Join Response Error (0x0398), found when sending 0x0014 Join Request to an already-joined device
            pktinfo.cols.info:set("Broadlink Response Error")
        elseif payload_type == 0x0006 and len == 0x30 then
            -- Hello Request (0x0006) has no payload
            pktinfo.cols.info:set("Hello Request")
        elseif payload_type == 0x0007 and len == 0x80 then
            -- Hello Response (0x0007)
            dissect_hello_response_packet(tvb, pktinfo, tree)
        elseif payload_type == 0x0065 then
            -- Authorization Request (0x0065)
            dissect_auth_request_packet(tvb, pktinfo, tree)
        elseif payload_type == 0x03e9 then
            -- Authorization Response (0x03e9)
            dissect_auth_response_packet(tvb, pktinfo, tree)
        elseif payload_type == 0x006a then
            -- Command Request (0x006a)
            dissect_command_request_packet(tvb, pktinfo, tree)
        elseif payload_type == 0x03ee then
            -- Command Response (0x03ee)
            dissect_command_response_packet(tvb, pktinfo, tree)
        else
            tree:append_text(" (Unknown)")
            pktinfo.cols.info:set("Broadlink Unknown Packet")
        end
    end

    -- if len == 136 and tvb(0x26, 1):uint() == 0x14 then
    --     tree:append_text(" (AP Mode Setup)")
    --     dissect_ap_setup(tvb, pktinfo, tree)
    -- elseif len == 48 then
    --     tree:append_text(" (Discovery Request)")
    --     pktinfo.cols.info:set("Broadlink Discovery Request")
    --     dissect_discovery_request(tvb, tree)
    -- else
    --     tree:append_text(" (Unknown)")
    --     pktinfo.cols.info:set("Broadlink Unknown Packet")
    -- end

    return len
end

-- ── Register on UDP ports ──────────────────────────────────────────────────
-- Discovery uses UDP port 80 (broadcast); commands use 80 and higher ports.
-- Add more ports here if needed.

local udp_table = DissectorTable.get("udp.port")
udp_table:add(80,    broadlink)
udp_table:add(16680, broadlink)
udp_table:add(8899,  broadlink)  -- common Broadlink command port
