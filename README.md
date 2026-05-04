# broadlink-dissector
A Wireshark Lua dissector for the Broadlink Smart Home Protocol. Decodes UDP traffic between clients and Broadlink devices.

Partially based on [csabavirag/broadlink-dissector](https://github.com/csabavirag/broadlink-dissector).

Protocol documentation: [LAN](lan-protocol/protocol.md) and [Cloud](cloud-protocol/protocol.md)

## Pre-requisites
1. [Wireshark](https://www.wireshark.org/download.html) 4.6.0 (or newer), as this natively supports GcryptCipher.

## Installation

Copy the plugin to your Wireshark plugins folder:

**macOS / Linux**
```bash
cp broadlink.lua ~/.config/wireshark/plugins/
```

**Windows**
```
copy broadlink.lua %APPDATA%\Wireshark\plugins\
```

Then reload plugins — no restart needed:

> **Wireshark → Analyze → Reload Lua Plugins** (`Ctrl+Shift+L`)

---

## Syntax Check

Validate the file before loading it:

```bash
luac -p broadlink.lua && echo "OK"
```

---

## Usage

The dissector registers itself on **UDP ports 80 and 8899**.  
Broadlink devices use port 80 for discovery broadcasts and typically port 8899 for commands.

To force decoding on a different port:

> Right-click a packet → **Decode As** → select `broadlink`

### Display filter examples

```wireshark
# All Broadlink traffic
broadlink

# Only auth / pairing packets
broadlink.command == 0x0065

# Only IR/RF command packets
broadlink.command == 0x006a

# Specific device type (RM5 Pro)
broadlink.device_type == 0x5224

# Response packets with errors
broadlink.error_code != 0

# Filter by MAC address
broadlink.mac == aa:a8:1a:89:8e:34
```

---

## Decoded fields

| Field | Filter key | Notes |
|---|---|---|
| Magic bytes | `broadlink.magic` | `5a a5 aa 55 5a a5 aa 55` |
| Checksum | `broadlink.checksum` | Seed `0xbeaf`, over entire packet |
| Error code | `broadlink.error_code` | Non-zero in response errors only |
| Device type | `broadlink.device_type` | See device table below |
| Command code | `broadlink.command` | See command table below |
| Packet counter | `broadlink.packet_count` | Increments per session |
| MAC address | `broadlink.mac` | Reversed in controller→device packets |
| Device ID | `broadlink.device_id` | `0x00000000` = unpaired / pre-auth |
| Payload checksum | `broadlink.payload_checksum` | Seed `0xbeaf`, over unencrypted payload |
| Encrypted payload | `broadlink.payload` | AES-128-CBC |
| Device IP | `broadlink.device_ip` | Discovery response only |
| Device MAC | `broadlink.device_mac` | Discovery response only |
| Device name | `broadlink.device_name` | Discovery response only |

---

## Command codes

| Code | Description |
|---|---|
| `0x0001` | Ping / keepalive |
| `0x0006` | Hello Request (discovery) |
| `0x0007` | Hello Response |
| `0x0014` | Join Request (AP provisioning) |
| `0x0015` | Join Response |
| `0x001a` | Discovery Request |
| `0x001b` | Discovery Response |
| `0x0065` | Auth Request |
| `0x006a` | Command Request (IR/RF, sensors, …) |
| `0x0398` | Join Error |
| `0x03e9` | Auth Response |
| `0x03ee` | Command Response |
| `0x2724` | JSON Envelope (RM5+ cloud push) |

---

## 0x006a sub-commands

The dissector decrypts the payload and reads the sub-command byte to annotate both the packet tree and the Info column.

| Sub-command | Meaning |
|---|---|
| `0x01` | Read device status |
| `0x02` | Send IR/RF data |
| `0x03` | Enter IR learning mode |
| `0x04` | Check captured IR/RF data |
| `0x09` | Dooya: curtain command |
| `0x0a` | MP1: check power state |
| `0x0d` | MP1: set port power state |
| `0x19` | Enter RF sweep |
| `0x1a` | Check RF frequency |
| `0x1b` | Read captured RF data |
| `0x1e` | Cancel RF sweep |
| `0x24` | Check temperature / humidity (RM4) |

RM4-series devices (`rm4mini`, `rm4pro`, `rmminib`) prefix the payload with `04 00` before the sub-command byte.

---

## Capturing traffic

Broadcasts (Hello packets) are easy to capture on any interface. For unicast device traffic you need to be in the traffic path. Options:

**Option 1 — Router with tcpdump** (e.g. DD-WRT):
```bash
ssh root@192.168.1.1 'tcpdump -i any -s0 -w - host 192.168.1.X' \
  | /Applications/Wireshark.app/Contents/MacOS/Wireshark -k -i -
```

**Option 2 — Rooted Android device**:
```bash
adb shell su -c 'tcpdump -i any -s0 -w - host 192.168.1.X' \
  | /Applications/Wireshark.app/Contents/MacOS/Wireshark -k -i -
```

**Option 3 — BroadLink iOS app on macOS** (Apple Silicon / Rosetta):  
Run the [BroadLink iPad app](https://apps.apple.com/nl/app/broadlink/id1450257910) natively on macOS and capture on the loopback or Wi-Fi interface.

**Option 4 — iOS device via Remote Virtual Interface**:
```bash
xcrun rvictl -s <UDID>   # creates rvi0
wireshark -i rvi0
```

---

## Session key

The first Auth Request/Response exchange uses the built-in default key. The dissector automatically extracts the session key from the Auth Response and uses it for all subsequent packets.

Filter for the auth exchange:
```
broadlink.command == 0x0065 || broadlink.command == 0x03e9
```

If the key was captured mid-session, enter it manually under **Edit → Preferences → Protocols → Broadlink → Session key**.

> **After the key is set or auto-populated, press `Ctrl+Shift+L`** (**Analyze → Reload Lua Plugins**) to re-dissect all packets with the updated key.

To see decrypted command traffic:
```
broadlink.command == 0x006a || broadlink.command == 0x03ee
```
