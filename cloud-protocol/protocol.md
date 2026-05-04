# Cloud Protocols

Next to the regular protocol also another protocol is used (at least with the RM5+).

## Adapted LAN Protocol

Similar to the [LAN protocol](/lan-protocol/protocol.md), but the date/time field bytes are used differently.


## Protocol 1812 

Communicates over UDP port `1812` (server side for both receive and send). 

**Warning**: The table below is based on limited captures and is definitely inaccurate.


| Offset    | Request example              | Response example             | Meaning                                        |
|-----------|------------------------------|------------------------------|------------------------------------------------|
| 0x00–0x03 | `d2 7f df 02`                | `d2 7f df 02`                | Magic                                          |
| 0x04–0x05 | `01 00`                      | `01 00`                      | Unknown (constant in all observed packets)     |
| 0x06–0x07 | `8c 00` (= 140)              | `8c 01` (= 396)              | Total packet length (LE uint16)                |
| 0x08–0x09 | `5a e3`                      | `5d a5`                      | Check sum?  (LE uint16)                    |
| 0x0a–0x0b | `00 00`                      | `ec 0f`                      | Unknown                                        |
| 0x0c–0x0f | `54 18 4c 15`                | `4e 5e a0 1a`                | Session token?                                 |
| 0x10–0x17 | `c5 bd 2c eb fc 64 00 00`    | `b2 b5 76 9d fb 22 ec 0f`    | Unknown                                        |
| 0x18–0x19 | `a5 e3`                      | `5c a5`                      | Unknown (secondary sequence?)                  |
| 0x1a–0x1b | `00 02`                      | `ec 0d`                      | Unknown                                        |
| 0x1c      | `00`                         | `07`                         | Unknown                                        |
| 0x1d–0x23 | `7f 3f ed c9 fb 80 50`       | `39 d3 e2 ce bd 6c 5f`       | Unknown                                        |
| 0x24      | `31`                         | `36`                         | Retry counter (counts down from 50)            |
| 0x25–0x27 | `36 59 86`                   | `70 b5 89`                   | Unknown                                        |
| 0x28      | `06`                         | `01`                         | Sub-sequence (counts up)                       |
| 0x29–0x2f | `bf 4e 6a 28 e5 da 64`       | `f9 a2 65 2f a3 36 6b`       | Unknown                                        |
| 0x30–end  | 92 B encrypted               | 348 B encrypted              | AES-128-CBC encrypted payload                  |


### Example Data

Send from RM5+ to Cloud:

```
0000   d2 7f df 02 01 00 8c 00 5a e3 00 00 54 18 4c 15
0010   c5 bd 2c eb fc 64 00 00 a5 e3 00 02 00 7f 3f ed
0020   c9 fb 80 50 31 36 59 86 06 bf 4e 6a 28 e5 da 64
0030   8a f8 d8 6a 4a 1c 40 e1 db 20 3c 37 ef 42 ac 74
0040   17 60 20 87 2f a8 8d 9b 28 8a 38 9f 10 96 be c6
0050   45 75 92 22 ac 61 44 47 9f c9 8f 79 10 e2 45 09
0060   10 8a 68 6e 95 37 fc 71 71 00 5d f9 74 0e 15 cb
0070   9f dc 37 b3 48 de 79 83 70 50 39 3e 6b 42 ae ad
0080   2a fc 23 d9 2f 41 05 2c 17 3a fb c1
```

Response from Cloud to RM5+:
```
0000   d2 7f df 02 01 00 8c 01 5d a5 ec 0f 4e 5e a0 1a
0010   b2 b5 76 9d fb 22 ec 0f 5c a5 ec 0d 07 39 d3 e2
0020   ce bd 6c 5f 36 70 b5 89 01 f9 a2 65 2f a3 36 6b
0030   8d be 34 65 4d 5a ac ee dc 66 d0 38 c9 59 5a c5
0040   c4 44 a4 1e b2 57 06 ec fb 0f 81 92 00 c6 ac 55
0050   84 8c f3 c8 67 22 98 24 c5 0e 14 27 ce 7f 5b ff
0060   ea 5f a8 22 1d 3b 97 58 02 61 0d 0d 33 ad 41 56
0070   db aa 61 30 4e 31 8e 53 0e a7 7b 31 c1 7b 66 f0
0080   74 fe 46 32 1c 9b 72 b3 29 ce 32 f9 94 51 4d 20
0090   bd 6b 02 d2 e4 af 50 c3 5a 12 b9 61 8e e3 32 33
00a0   49 fe 3c 43 30 46 8d d9 80 f5 13 f6 79 f2 18 ec
00b0   a7 26 1d f6 35 a9 51 b4 64 41 9e b6 df 63 f7 e5
00c0   9e 30 56 b4 b7 b8 5b 0e 20 9b be d4 2c e3 29 4f
00d0   1f c6 4f 48 d5 bd bf 88 30 e7 3f bc 6d c5 73 da
00e0   17 78 31 b8 8d d2 2a bd 71 18 e1 4a 2b 5c ba be
00f0   bf 61 38 d0 d7 45 5a d9 31 4a c6 0a 85 8b 49 5e
0100   1c db 57 f9 04 41 47 b5 6b 8a 2b f1 e6 33 b6 4f
0110   54 07 5b be c7 49 d1 7d 27 1c 74 f9 76 06 1f 75
0120   0f c7 99 55 7c 31 a2 8a 39 89 fc a6 d3 e0 46 28
0130   9e a3 97 90 3c cf aa fc 16 99 7d c8 86 43 c0 50
0140   94 ed 3f d8 09 ae 02 82 f0 08 64 e3 fb 18 4f da
0150   85 9f 31 1f f4 65 22 56 5a a1 d8 55 a0 de c0 9b
0160   2e 97 fd bd 2c 94 47 49 60 21 b5 7d 21 c3 b6 4b
0170   e6 93 69 e7 9f 63 cc ba d8 7c 8d e7 d0 9b 99 f3
0180   be 2b 85 b8 ed 5b 0c 37 a6 12 db b7
```