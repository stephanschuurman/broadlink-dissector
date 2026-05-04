# Sequences

The protocol lifecycle follows three phases:
1. [**Provisioning**](#provisioning) — device is in AP mode; the host scans for WiFi networks (`Discover`) and sends credentials (`Join`).
2. [**Discovery**](#discovery) — the host broadcasts a `Hello` packet to find devices on the local network.
3. [**Control**](#control) — the host authenticates (`Auth`orization) to obtain a session key and device ID, then issues `Command` packets.



## Provisioning

Device is in **AP mode**. The client connects to the device's own WiFi network and performs WiFi provisioning.

```mermaid
sequenceDiagram
    autonumber
    participant C as Client
    participant D as Broadlink Device (AP mode)

    Note over C,D: AP-mode (client connects directly)
    C->>D: Discover Request (0x001a)
    Note over D: Scans for WiFi networks
    D-->>C: Discover Response (0x001b)
    Note over C: Receives list of SSIDs + encryption types

    C->>D: Join Request (0x0014)
    Note over C: Payload contains SSID + password + security mode
    D-->>C: Join Response (0x0015)
    Note over D,C: Device connects to target WiFi network
```

## Discovery

The client sends a `Hello` packet to locate BroadLink devices on the local network; the device replies with its identity and network info. The packet is typically broadcast to `255.255.255.255:80`, and some clients additionally send it in parallel to `224.0.0.251:80` and `224.0.0.251:16680` — the mDNS multicast group — presumably to avoid it being dropped by routers that filter directed broadcasts. `Authenticated` and `Locked` devices may not respond to multicast and require a directed broadcast or unicast to their known IP.

To unlock a BroadLink device (RM4/RM Pro), open the BroadLink-app, select the device, tap the top-right menu (...) -> "Property", and toggle "Lock device" to OFF.

```mermaid
sequenceDiagram
    autonumber
    participant C as Client
    participant D as Broadlink Device

    Note over C: Build 0x30-byte Hello packet<br/>PayloadType 0x26..0x27 = 0x0006

    C->>D: Hello Request (0x0006) — UDP broadcast 255.255.255.255:80

    Note over D: PayloadType = 0x0006 → Hello<br/>Replies unless locked

    D-->>C: Hello Response (0x0007)
    Note over C: Payload contains Device ID, Type, IP, MAC, Name
```

## Control

After discovery the client authenticates to obtain a session key and device ID, then issues encrypted commands.

```mermaid
sequenceDiagram
    autonumber
    participant C as Client
    participant D as Broadlink Device

    Note over C: Encrypt Auth payload with default key + IV<br/>PayloadType 0x26..0x27 = 0x0065

    C->>D: Auth Request (0x0065)
    Note over D: Decrypts payload, assigns Device ID<br/>Generates session AES key

    D-->>C: Auth Response (0x03e9)
    Note over C: Decrypts response → stores Device ID + Session Key<br/>All subsequent packets use Session Key

    loop Commands
        C->>D: Command Request (0x006a)
        Note over C: Extended header includes Device ID<br/>Payload encrypted with Session Key
        D-->>C: Command Response (0x03ee)
    end
```

## Example

```mermaid
sequenceDiagram
    autonumber
    participant C as Client
    participant D as Broadlink Device

    Note over C: Build Hello packet
    Note over C: offset 0x26..0x27 = command = 0x0006 (LE)
    Note over C: offset 0x18..0x1B = client IP
    Note over C: offset 0x1C..0x1F = client port
    Note over C: offset 0x20..0x21 = checksum
    Note over C: 48-byte discovery packet

    C->>D: UDP broadcast Hello request

    Note over D: Parse command at offset 0x26
    Note over D: command = 0x06 => Hello request

    D-->>C: Hello response

    Note over C: Parse response command at 0x26..0x27 = 0x0007
    Note over C: Response contains:
    Note over C: 0x34..0x35 = device type
    Note over C: 0x36..0x39 = device IP
    Note over C: 0x3A..0x3F = MAC
    Note over C: 0x40.. = device name

    C->>D: Auth request
    Note over C: command at 0x26..0x27 = 0x0065

    D-->>C: Auth response
    Note over D,C: command at 0x26..0x27 = 0x03e9

    C->>D: Command request
    Note over C: command at 0x26..0x27 = 0x006a

    D-->>C: Command response
    Note over D,C: command at 0x26..0x27 = 0x03ee
```

## RM Learn Command (checked with RM5+)

Puts the RM device into IR learning mode and polls until a code is captured (max 30 seconds).

```mermaid
sequenceDiagram
    autonumber
    participant C as Client
    participant D as RM Device

    Note over C,D: Requires active Auth session (Session Key + Device ID)

    Note over C,D: Enter learning mode — 3 requests sent back-to-back
    C->>D: Command Request (0x006a) ×3 — subcmd 0x03 (enter learning)
    D-->>C: Command Response (0x03ee) ×3
    Note over D: RM enters learning mode, waiting for IR signal

    Note over C,D: Hello broadcast — app re-discovers device (~2 s timer)
    C->>D: Hello Request (0x0006) ×3 — 255.255.255.255 + 224.0.0.251
    D-->>C: Hello Response (0x0007)

    loop Poll for captured data (~every 2 sec, max 10×)
        C->>D: Command Request (0x006a) ×3 — subcmd 0x04 (check_data)
        C->>D: Hello Request (0x0006) ×3 — concurrent re-discovery broadcast
        D-->>C: Command Response (0x03ee) ×3
        D-->>C: Hello Response (0x0007)
        Note over C: error code 0x0000 → IR data captured<br/>error code 0xfffb → null data (not ready), continue polling
    end
```
Three requests are sent back-to-back for every command type. On a successful `check_data` (error `0x0000`) the response payload is 180 bytes (vs. 100 for an error), containing the captured IR data. The two trailing responses to the duplicate requests carry error `0xfffb` (null data / not yet captured). Hello broadcasts run on a ~2 s timer concurrently with the polling.

Once the IR data is captured, the app does two more Hello broadcast rounds before playing back the learned signal:

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant C as Client
    participant D as RM Device

    Note over C,D: Playback — 3 requests back-to-back
    C->>D: Command Request (0x006a) ×3 — subcmd 0x02 (send_data, IR payload)
    D-->>C: Command Response (0x03ee) ×2
    Note over D: RM transmits learned IR signal

    C->>U: "Did the device respond?"
    alt Yes
        Note over C: Save learned command
    else No
        Note over C: Discard and restart learning
    end
```
