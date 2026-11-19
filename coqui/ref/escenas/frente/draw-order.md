# frente: what draw() draws, in order

Made by `node coqui/tool/ref/escenas/make.mjs` from the canvas calls of every distinct state (291 W, 43 states); each call's place is the first frame of its stack in a scene file. historia/escenas/frente.js draw(): lines 139-175.

## Characters and props

An item is `functions between draw() and the canvas @ the line of draw() that leads there | the sprite maker`. In draw() order (by that line).

| item | class | canvas calls at | sprite (or canvas method) | drawn after it and overlapping it in the same frame (what can cover it) |
|---|---|---|---|---|
| `ambient @frente.js:141 · mkCloud` | prop or effect | frente.js:48 | mkCloud | `drawAve @frente.js:159 · mkAve` (18 of 49) |
| `ambient > fly @frente.js:141` | character | frente.js:47 | fillRect | `@frente.js:144 · mkAbuela` (always); `mesa @frente.js:147` (always); `@frente.js:147 · mkAbuela` (28 of 36); `@frente.js:153 · mkAbuela` (always); `@frente.js:156 · mkCoqui` (8 of 122); `@frente.js:174` (3 of 6) |
| `escondite @frente.js:142` | prop or effect | frente.js:101, frente.js:102 | fillRect | `@frente.js:152 · mkAbuela` (2 of 4); `@frente.js:152` (always); `@frente.js:165` (always) |
| `escondite @frente.js:142 · mkCasita` | prop or effect | frente.js:100 | mkCasita | `escondite @frente.js:142` (always); `@frente.js:156` (3 of 69); `@frente.js:156 · mkCoqui` (3 of 69); `drawAve @frente.js:159 · mkAve` (17 of 38); `@frente.js:165` (always) |
| `escondite @frente.js:142 · mkPalmita` | prop or effect | frente.js:97 | mkPalmita | `escondite @frente.js:142` (2 of 4); `@frente.js:156 · mkCoqui` (14 of 69); `drawAve @frente.js:159 · mkAve` (6 of 38); `@frente.js:165` (always) |
| `@frente.js:143 · mkCoqui` | character | frente.js:143 | mkCoqui | `@frente.js:165` (always) |
| `@frente.js:144 · mkAbuela` | character | frente.js:144 | mkAbuela | `@frente.js:165` (always) |
| `@frente.js:147 · mkAbuela` | character | frente.js:147 | mkAbuela | `@frente.js:148 · mkCoqui` (always); `towel @frente.js:149` (always); `@frente.js:149` (always); `@frente.js:156 · mkCoqui` (40 of 51); `@frente.js:157` (1 of 5); `@frente.js:164` (always); `rain @frente.js:169` (always); `@frente.js:174` (always) |
| `mesa @frente.js:147` | prop or effect | frente.js:64, frente.js:65, frente.js:66 | fillRect | `@frente.js:147 · mkAbuela` (always) |
| `@frente.js:148 · mkCoqui` | character | frente.js:148 | mkCoqui | `towel @frente.js:149` (always); `@frente.js:149` (always); `@frente.js:164` (always); `rain @frente.js:169` (always) |
| `@frente.js:149` | character | frente.js:149 | fillRect | `@frente.js:164` (always); `rain @frente.js:169` (always) |
| `towel @frente.js:149` | character | frente.js:58, frente.js:59 | fillRect | `@frente.js:164` (always); `rain @frente.js:169` (always) |
| `@frente.js:152` | character | frente.js:152 | fillRect | `@frente.js:165` (always) |
| `@frente.js:152 · mkAbuela` | character | frente.js:152 | mkAbuela | `@frente.js:152` (always); `@frente.js:165` (always) |
| `@frente.js:153 · mkAbuela` | character | frente.js:153 | mkAbuela | `@frente.js:156 · mkCoqui` (1 of 15); `@frente.js:164` (always); `@frente.js:174` (1 of 2) |
| `@frente.js:155` | character | frente.js:155 | fillRect | `@frente.js:156` (always); `@frente.js:156 · mkCoqui` (always); `@frente.js:165` (always) |
| `@frente.js:156` | character | frente.js:156 | fillRect | `@frente.js:156 · mkCoqui` (249 of 260); `@frente.js:164` (always); `@frente.js:165` (always); `rain @frente.js:169` (always) |
| `@frente.js:156 · mkCoqui` | character | frente.js:156 | mkCoqui | `@frente.js:157` (always); `@frente.js:158` (always); `drawAve @frente.js:159 · mkAve` (4 of 84); `@frente.js:164` (always); `@frente.js:165` (always); `rain @frente.js:169` (always); `@frente.js:174` (2 of 24) |
| `@frente.js:157` | character | frente.js:157 | fillRect | `@frente.js:164` (always); `rain @frente.js:169` (always) |
| `@frente.js:158` | character | frente.js:158 | fillRect | `@frente.js:164` (always) |
| `drawAve @frente.js:159` | character | frente.js:85, frente.js:86 | fillRect | `@frente.js:165` (always) |
| `drawAve @frente.js:159 · mkAve` | character | frente.js:83 | mkAve | `@frente.js:165` (always); `@frente.js:174` (always) |
| `@frente.js:163` | prop or effect | frente.js:163 | fill | `@frente.js:164` (always); `@frente.js:167 · mkNube` (20 of 88); `rain @frente.js:169` (always) |
| `@frente.js:164` | prop or effect | frente.js:164 | fillRect | `@frente.js:167 · mkNube` (always); `@frente.js:168` (always); `rain @frente.js:169` (always); `@frente.js:172` (always); `@frente.js:173` (always); `@frente.js:174` (always) |
| `@frente.js:165` | prop or effect | frente.js:165 | fillRect | nothing |
| `@frente.js:167 · mkNube` | prop or effect | frente.js:167 | mkNube | `@frente.js:168` (38 of 68); `rain @frente.js:169` (always) |
| `@frente.js:168` | prop or effect | frente.js:168 | fillRect | `@frente.js:172` (always); `@frente.js:173` (4 of 9) |
| `rain @frente.js:169` | prop or effect | frente.js:55, frente.js:56 | fillRect | `@frente.js:172` (always); `@frente.js:174` (always) |
| `@frente.js:172` | character | frente.js:172 | fillRect | nothing |
| `@frente.js:173` | character | frente.js:173 | fillRect | nothing |
| `@frente.js:174` | character | frente.js:174 | fillRect | nothing |

## Clip regions

| at | region (scene picture) | what is drawn inside it | seen in |
|---|---|---|---|
| frente.js:147 `if(ab.en==="ventana"){c.save();c.beginPath();c.rect(97,61,30,20);c.clip();if(W.win===1&&W.` | rect [97,61,30,20] | `@frente.js:147 · mkAbuela`; `mesa @frente.js:147`; `@frente.js:148 · mkCoqui`; `@frente.js:149`; `towel @frente.js:149` | 67 W |
| frente.js:143 `if(W.asoma&&W.door===.5){c.save();c.beginPath();c.rect(153,53,11,51);c.clip();c.drawImage(` | rect [153,53,11,51] | `@frente.js:143 · mkCoqui` | 1 W |
| frente.js:144 `if(W.peek&&W.door===.5){c.save();c.beginPath();c.rect(153,53,11,51);c.clip();c.drawImage(A` | rect [153,53,11,51] | `@frente.js:144 · mkAbuela` | 2 W |

## Background

- frente.js:12 bg(door,win,lamp)
- frente.js:140 spr("fr"+W.door+"_"+W.win+"_"+W.lamp, ()=>bg(W.door,W.win,W.lamp))

## Notes

- The bubbles are drawn last (frente.js:171-174, "so they stay bright"): abuela's, the voice from inside (W.dentro), the frog's.
- The storm cloud(s), rain and the lightning flash (frente.js:167-170) are drawn over the characters; W.dark and W.dusk lay a colour over the whole picture (frente.js:164-165), characters included.
- abuela in the window and the frog beside her are clipped to the window opening (frente.js:147); the frog and abuela peeking from behind the half-open door are clipped to the gap (frente.js:143-144).
- The table with the cake (mesa(), frente.js:64) is drawn inside abuela's window clip, before her, only when W.win===1 and W.mesa.
- The hide-and-seek props (small palm, birdhouse: escondite(), frente.js:94) are drawn before abuela and the frog: they never cover a character.
