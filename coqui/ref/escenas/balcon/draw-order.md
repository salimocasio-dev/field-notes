# balcon: what draw() draws, in order

Made by `node coqui/tool/ref/escenas/make.mjs` from the canvas calls of every distinct state (288 W, 50 states); each call's place is the first frame of its stack in a scene file. historia/escenas/balcon.js draw(): lines 120-156.

## Characters and props

An item is `functions between draw() and the canvas @ the line of draw() that leads there | the sprite maker`. In draw() order (by that line).

| item | class | canvas calls at | sprite (or canvas method) | drawn after it and overlapping it in the same frame (what can cover it) |
|---|---|---|---|---|
| `dePie @balcon.js:126` | character | balcon.js:125 | fillRect | `dePie > vaso @balcon.js:126` (always); `@balcon.js:127 · mkSillaG` (always) |
| `dePie @balcon.js:126 · mkAbuela` | character | balcon.js:124 | mkAbuela | `dePie @balcon.js:126` (always); `dePie > vaso @balcon.js:126` (always); `@balcon.js:127 · mkSillaG` (16 of 27); `@balcon.js:135 · mkSillaP` (11 of 27); `@balcon.js:136 · mkMesa` (16 of 27); `vaso @balcon.js:137` (always); `rana @balcon.js:143 · mkCoqui` (3 of 27); `gota @balcon.js:144` (2 of 18) |
| `dePie > vaso @balcon.js:126` | character | balcon.js:81, balcon.js:82, balcon.js:83, balcon.js:84, balcon.js:85 | fillRect | `@balcon.js:127 · mkSillaG` (always) |
| `@balcon.js:127 · mkSillaG` | prop or effect | balcon.js:127 | mkSillaG | `@balcon.js:129 · KIT.mkAbuelaS` (always); `abanico @balcon.js:130` (always); `medio > abanico @balcon.js:130` (always); `vaso @balcon.js:131` (always); `gota @balcon.js:134` (always); `dePie @balcon.js:141 · mkAbuela` (always); `rana @balcon.js:143 · mkCoqui` (6 of 274); `drawAve @balcon.js:150 · mkAve` (6 of 107); `bub2 @balcon.js:155` (4 of 11) |
| `@balcon.js:129 · KIT.mkAbuelaS` | character | balcon.js:129 | KIT.mkAbuelaS | `abanico @balcon.js:130` (always); `medio > abanico @balcon.js:130` (always); `vaso @balcon.js:131` (always); `gota @balcon.js:134` (always); `@balcon.js:136 · mkMesa` (always); `jarra @balcon.js:140` (always); `rana @balcon.js:143 · mkCoqui` (6 of 245); `gota @balcon.js:144` (22 of 93); `drawAve @balcon.js:150 · mkAve` (20 of 105); `bub2 @balcon.js:155` (4 of 8) |
| `abanico @balcon.js:130` | character | balcon.js:176, balcon.js:177 | fillRect | nothing |
| `medio > abanico @balcon.js:130` | character | balcon.js:176, balcon.js:177 | fillRect | `gota @balcon.js:134` (1 of 12) |
| `vaso @balcon.js:131` | character | balcon.js:81, balcon.js:82, balcon.js:83, balcon.js:84, balcon.js:85 | fillRect | `bub2 @balcon.js:155` (always) |
| `gota @balcon.js:134` | character | balcon.js:114 | fillRect | nothing |
| `@balcon.js:135 · mkSillaP` | prop or effect | balcon.js:135 | mkSillaP | `vaso @balcon.js:137` (8 of 147); `rana @balcon.js:143 · mkCoqui` (130 of 274); `rana @balcon.js:143` (6 of 225); `gota @balcon.js:144` (12 of 112); `vaso @balcon.js:147` (3 of 21); `jarra @balcon.js:148` (always); `drawAve @balcon.js:150 · mkAve` (15 of 107); `bub2 @balcon.js:155` (2 of 11) |
| `@balcon.js:136 · mkMesa` | prop or effect | balcon.js:136 | mkMesa | `vaso @balcon.js:137` (always); `medio > abanico @balcon.js:138` (always); `medio > abanico @balcon.js:139` (always); `jarra @balcon.js:140` (always); `dePie @balcon.js:141 · mkAbuela` (always); `rana @balcon.js:143 · mkCoqui` (212 of 274); `gota @balcon.js:144` (86 of 112); `medio > abanico @balcon.js:145` (always); `vaso @balcon.js:147` (4 of 21); `jarra @balcon.js:148` (always); `drawAve @balcon.js:150 · mkAve` (38 of 107); `bub2 @balcon.js:155` (10 of 11) |
| `vaso @balcon.js:137` | prop or effect | balcon.js:81, balcon.js:82, balcon.js:83, balcon.js:84, balcon.js:85 | fillRect | `medio > abanico @balcon.js:138` (always); `jarra @balcon.js:140` (always); `drawAve @balcon.js:150 · mkAve` (24 of 102); `bub2 @balcon.js:155` (always) |
| `medio > abanico @balcon.js:138` | prop or effect | balcon.js:176, balcon.js:177 | fillRect | `jarra @balcon.js:140` (always) |
| `medio > abanico @balcon.js:139` | prop or effect | balcon.js:176, balcon.js:177 | fillRect | nothing |
| `jarra @balcon.js:140` | prop or effect | balcon.js:88, balcon.js:89, balcon.js:90, balcon.js:91, balcon.js:92 | fillRect | `bub2 @balcon.js:155` (always) |
| `dePie @balcon.js:141 · mkAbuela` | character | balcon.js:124 | mkAbuela | nothing |
| `rana @balcon.js:143` | character | balcon.js:118 | fillRect | `rana @balcon.js:143 · mkCoqui` (212 of 225) |
| `rana @balcon.js:143 · mkCoqui` | character | balcon.js:119 | mkCoqui | `gota @balcon.js:144` (109 of 112); `medio > abanico @balcon.js:145` (4 of 11); `vaso @balcon.js:147` (always); `jarra @balcon.js:148` (always); `bub2 @balcon.js:155` (2 of 11) |
| `gota @balcon.js:144` | character | balcon.js:114 | fillRect | `vaso @balcon.js:147` (4 of 11); `bub2 @balcon.js:155` (always) |
| `medio > abanico @balcon.js:145` | character | balcon.js:176, balcon.js:177 | fillRect | nothing |
| `vaso @balcon.js:147` | character | balcon.js:81, balcon.js:82, balcon.js:83, balcon.js:84, balcon.js:85 | fillRect | nothing |
| `jarra @balcon.js:148` | character | balcon.js:88, balcon.js:89, balcon.js:90, balcon.js:91, balcon.js:92 | fillRect | nothing |
| `drawAve @balcon.js:150 · mkAve` | character | kit.js:28 | mkAve | nothing |
| `drawAve > Z @balcon.js:150` | character | kit.js:29 | fillRect | nothing |
| `bub2 @balcon.js:154` | character | balcon.js:116 | fillRect | nothing |
| `bub2 @balcon.js:155` | character | balcon.js:116 | fillRect | nothing |

## Clip regions

| at | region (scene picture) | what is drawn inside it | seen in |
|---|---|---|---|
| balcon.js:124 `if(ab.en==="puerta"){c.save();c.beginPath();c.rect(165,57,24,69);c.clip();c.drawImage(spr(` | rect [165,57,24,69] | `dePie @balcon.js:126 · mkAbuela` | 11 W |

## Background

- balcon.js:15 bg(door,win)
- balcon.js:121 spr("bal"+W.door+"_"+W.win, ()=>bg(W.door,W.win))

## Notes

- abuela standing is drawn twice in the code: before the furniture when her feet are above y 144 (balcon.js:126), after the table and jugs when at or below (balcon.js:141).
- Standing in the doorway she is clipped to the door opening (balcon.js:124).
- Her picture bubbles and the frog's are drawn last, at twice their size (bub2, balcon.js:116, 154-155).
