# broadlink-dissector
A Wireshark Lua dissector for the Broadlink Smart Home Protocol. Decodes UDP traffic between clients and Broadlink devices.

Partially based on [csabavirag/broadlink-dissector](https://github.com/csabavirag/broadlink-dissector).

Protocol documentation: [LAN](protocol/index.md) and [Cloud](cloud/protocol.md)


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
| `0x0001` | Discovery request |
| `0x0007` | Discovery response |
| `0x0065` | Authorization / device status |
| `0x0066` | SP1 set power state |
| `0x006a` | Send IR/RF command, learning mode, read data |
| `0x001a` | Query RF data |

---

## 0x006a sub-command hints

For `0x006a` packets the dissector reads the first 3 bytes of the encrypted payload as a hint and annotates the payload field. Because the payload is AES-encrypted on the wire, this is a best-effort annotation based on the ciphertext bytes; it is accurate when the default key is still in use (pre-auth).

| Prefix bytes | Meaning |
|---|---|
| `02 …` | Send IR/RF (RM2/RM3 standard) |
| `03 …` | Enter IR learning (RM2/RM3) |
| `04 …` | Check captured IR data (RM3 standard) |
| `04 00 03` | Enter IR learning (RM4 / Red Bean) |
| `04 00 04` | Check captured IR / RF data (RM4) |
| `04 00 19` | Enter RF sweep (RM4 Pro) |
| `04 00 1a` | Check RF frequency (RM4 Pro) |
| `04 00 1b` | Read captured RF data (RM4 Pro) |
| `04 00 1e` | Cancel RF sweep (RM4 Pro) |
| `d0 00 02` | Send IR/RF (RM3 Red Bean / RM4 Mini) |
| `da 00 02` | Send IR/RF (RM4 Pro) |
| `00 00 24` | Check temperature / humidity (RM4 Pro) |
| `19 …` | Enter RF sweep (RM3) |
| `1a …` | Check RF frequency (RM3) |
| `1b …` | Read captured RF data (RM3) |
| `1e …` | Cancel RF sweep (RM3) |
| `01 …` | Read device status |
| `0a …` | MP1: check power state |
| `0d …` | MP1: set port power state |
| `09 …` | Dooya: set curtain state |

---

## Usage
If everything went well, Wireshark will show the new plugin/dissector registered under About->Plugins

### Ready to capture the communication.
Broadcasts (of hello) packets are easy to sniff out and don't require the options listed below.

_**Option 1**_: I have a DD-WRT router, so it was easy to install **tcpdump** on it and use the router for remote capture. The router is the central place where the traffic goes throuh, so it will "see" the whole communication.

The DHCP table showed me, the bulb got an IP address of 192.168.1.100 (it has been configured to my home network with the Android app I received from the manufacturer!)

So I just executed 
`ssh root@192.168.1.1 tcpdump -i any -s0 -w - "host 192.168.1.100" | /Applications/Wireshark.app/Contents/MacOS/Wireshark -k -i -`

_**Option 2**_: From a rooted Android device, where the tcpdump is also available and can run the vendor's management application

`adb shell su -c tcpdump -i any -s0 -w - "host 192.168.1.100" | /Applications/Wireshark.app/Contents/MacOS/Wireshark -k -i -`

_**Option 3**_: Use a phone or tablet app on your dev machine (e.g. running the [iPad BroadLink-app](https://apps.apple.com/nl/app/broadlink/id1450257910) on macOS).

_**Option 4**_: Use a phone or tablet app and connect you dev machine (e.g. running the `xcrun rvictl -s xxxxxxxxxxxxx-xxxxxxxxxxxxxxxx` on macOS to connect to an iPhone/iPad).


### Analyze the captured packets and use the dissector

Let's look for the AES key. The first authentication is always done with the pre-set encryption keys and the client sends the auth request (command=0x65) to the device. The device responds back to this request and in the auth response (command=0x3e9) there is the AES key which is used in any further communication. To get to these packets, filter for these packets with `broadlink.flags.command == 0x65 || broadlink.flags.command == 0x3e9`.

![image](https://user-images.githubusercontent.com/10976654/72676302-0f9efa00-3a90-11ea-833f-cd80314a32a6.png)

If the AES key is successfully extracted from the payload, set it in the protocol preferences. 

![image](https://user-images.githubusercontent.com/10976654/72676333-715f6400-3a90-11ea-9020-9dcd360b2deb.png)

With the new AES key saved, the following packets can be decrypted. Now filter the capture for command/response (`broadlink.flags.command == 0x6a || broadlink.flags.command == 0x3ee`)

![image](https://user-images.githubusercontent.com/10976654/72676510-26dee700-3a92-11ea-8ff2-31ac74a8e74b.png)

And see the response in the next packet

![image](https://user-images.githubusercontent.com/10976654/72676530-76bdae00-3a92-11ea-9f30-9f4e08231827.png)


<!-- ## Conclusion
I have no other types of Broadlink device (such as RM2*, A1 etc), only these bulbs (devID: 0x60C8) so could not verify if the dissector works properly with other models, but I believe the plugin can be easily extended/modified for others.

Feel free to adjust, fork and use for your own benefit. -->
