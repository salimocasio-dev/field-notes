# The speaking turns in the 31 existing stories

Decided Nov 16 2026 by the planning chat. Machine-readable copy: 02-marcas.json (story id → clip id → targets). Apply exactly; change nothing else in the story files.

How the lines were chosen:
- Only coquí lines played as a plain line, inside elige, or inside a signed ask. Never lines used only inside a costed decide (where a clip is used both ways, the turn only happens in the allowed places).
- Lines with a real word to say (answers, greetings, thanks, naming). No bare exclamations. 1 to 5 words, except one 6-word reply in story 5.
- At most 4 turns in one play (01, "Once per play": a clip is a turn only at its first live occurrence; repeats play as today).
- Targets are the course words in the line, at most 2, as spelled in the word records. Names (Coquí, Canelo, Carmen, Luis) are never targets.
- Checked Nov 16: every target is a course word (in some story's focus_words). 8 targets in the first stories (bien, gracias, vamos, aquí, de nada) are taught later; those turns stay touch until the word is open, then come alive on a replay. This is intended.
- The opening rule (01) decides when each turn is live, per word. On a first play almost none are; on later plays and in later stories they come alive by themselves.

- Reviewed Nov 16 by a fresh reviewer; fixes applied (quien-eres-tu: soy, and cq_tu_hermano added; el-bizcocho elige: sí / no alone; uno-dos-tres: digits accepted).
- "palabra" is a word record key: it may come from focus_words, back_again or the story's palabras map (e.g. "de nada").

| story | clip | line | must hear (accepted forms) |
|---|---|---|---|
| la-lluvia | hola_abuela | ¡Hola, abuela! | hola (hola) + abuela (abuela) |
| la-lluvia | abre_puerta_tu | ¡Abre la puerta, abuela! | abre (abre) + puerta (puerta) |
| la-lluvia | abre_ventana_tu | ¡Abre la ventana, abuela! | abre (abre) + ventana (ventana) |
| la-lluvia | bien_gracias | ¡Bien, gracias! | bien (bien) + gracias (gracias) |
| el-bizcocho | cq_si | ¡Sí! | sí (si) |
| el-bizcocho | cq_no | ¡No! | no (no) |
| el-bizcocho | cq_si_gracias | ¡Sí, gracias! | sí (si) |
| el-bizcocho | cq_no_gracias | No, gracias. | no (no) |
| donde-esta-el-pajaro | vamos_jugar | ¡Sí! ¡Vamos a jugar! | vamos (vamos) |
| donde-esta-el-pajaro | aqui_estoy | ¡Aquí estoy! | aquí (aqui) |
| donde-esta-el-pajaro | adios_abuela | ¡Adiós, abuela! | adiós (adios) + abuela (abuela) |
| el-jugo | cq_gracias_abuela | ¡Gracias, abuela! | gracias (gracias) + abuela (abuela) |
| el-jugo | no_pajaro | ¡No, pájaro, no! | no (no) |
| que-calor | cq_bien_y_tu | Bien, gracias. ¿Y tú, cómo estás? | bien (bien) + ¿cómo estás? (como estas) |
| que-calor | cq_quiero_jugo | Quiero jugo, por favor. | quiero (quiero) + jugo (jugo) |
| que-calor | cq_quiero_agua | Quiero agua, por favor. | quiero (quiero) + agua (agua) |
| que-calor | cq_de_nada | De nada. | de nada (de nada) |
| que-calor | cq_toma_abuela | Toma, abuela. | toma (toma) |
| la-familia | bien_gracias | ¡Bien, gracias! | bien (bien) + gracias (gracias) |
| la-familia | cq_de_nada | De nada. | de nada (de nada) |
| la-familia | cq_gracias_abuela | ¡Gracias, abuela! | gracias (gracias) + abuela (abuela) |
| la-foto | cq_familia | ¡Familia! | familia (familia) |
| quien-eres-tu | cq_yo_me_llamo | Yo soy Coquí. Me llamo Coquí. | soy (soy) |
| quien-eres-tu | cq_tu_hermana | Tú eres Carmen. | tú (tu) + eres (eres) |
| quien-eres-tu | cq_tu_hermano | Tú eres Luis. | tú (tu) + eres (eres) |
| las-flores | p_cq_yo_tambien | ¡Yo también! | yo (yo) |
| que-es-esto | p_cq_hola_amigo | ¡Hola, amigo! | hola (hola) |
| que-es-esto | p_cq_es_flor | Es una flor. | flor (flor) |
| que-es-esto | p_cq_que_es_esto | ¿Qué es esto? | ¿qué es esto? (que es esto) |
| que-es-esto | p_cq_y_tu_amigo | ¡Y tú eres mi amigo! | tú (tu) + eres (eres) |
| hasta-manana | p_cq_vamos | ¡Vamos! | vamos (vamos) |
| hasta-manana | p_cq_hm_abuela | ¡Hasta mañana, abuela! | hasta mañana (hasta mañana) + abuela (abuela) |
| hasta-manana | p_cq_adios_hm | ¡Adiós! ¡Hasta mañana! | adiós (adios) + hasta mañana (hasta mañana) |
| uno-dos-tres | c12_cq_hola | ¡Hola, Canelo! | hola (hola) |
| uno-dos-tres | c12_cq_uno | ¡Uno, dos, tres! | uno (uno/1) + tres (tres/3) |
| donde-esta-el-gato | c13_cq_amigos | ¡Amigos! | amigo (amigos/amigo) |
| rapido-despacio | c14_cq_despacio | ¡Despacio, Canelo! | despacio (despacio) |
| rapido-despacio | c14_cq_rapido | ¡Rápido, Canelo! | rápido (rapido) |
| rapido-despacio | c14_cq_de_nada | De nada, abuela. | de nada (de nada) + abuela (abuela) |
| la-bola | c15_cq_gracias | Gracias. | gracias (gracias) |
| la-bola | c15_cq_dame | ¡Dame la bola! | dame (dame) |
| la-bola | c15_cq_coge | ¡Coge la bola! | coge (coge) |
| arriba-abajo | c16_cq_abajo | ¡Está abajo! | abajo (abajo) |
| otra-vez | c17_cq_es_mi | ¡Es mi bola! | mi (mi) + bola (bola) |
| otra-vez | c17_cq_es_tu | ¡Es tu bola! | tu (tu) + bola (bola) |
| otra-vez | c17_cq_no_mas | ¡No más! | no (no) + más (mas) |
| pan-para-el-pato | c18_cq_vuela | ¡El pato vuela! | pato (pato) + vuela (vuela) |
| pan-para-el-pato | c18_cq_nada | ¡El pato nada! | pato (pato) + nada (nada) |
| pan-para-el-pato | c18_cq_adios | ¡Adiós, amigos! | adiós (adios) + amigo (amigos/amigo) |
| los-botes | c19_cq_rojo | ¡Es rojo! | rojo (rojo) |
| los-botes | c19_cq_verde | ¡Es verde! | verde (verde) |
| los-botes | c19_cq_aqui | ¡Aquí están los botes! | aquí (aqui) |
| la-piragua | c21_cq_come | ¡El pájaro come! | pájaro (pajaro) + come (come) |
| la-piragua | c21_cq_bebe | ¡El pájaro bebe! | pájaro (pajaro) + bebe (bebe) |
| la-piragua | c17_cq_no_mas | ¡No más! | no (no) + más (mas) |
| senor-senora | c22_cq_senor | ¡Señor! | señor (señor) |
| senor-senora | c22_cq_senora | ¡Señora! | señora (señora) |
| senor-senora | c22_cq_dn_senor | De nada, señor. | de nada (de nada) + señor (señor) |
| senor-senora | c22_cq_adios | ¡Adiós, señor! | adiós (adios) + señor (señor) |
| el-bebe-duerme | c23_cq_contento | ¡Está contento! | contento (contento) |
| el-bebe-duerme | c23_cq_cansado | ¡Está cansado! | cansado (cansado) |
| el-bebe-duerme | c23_cq_triste | ¡Está triste! | triste (triste) |
| el-bebe-duerme | p_cq_hm | ¡Hasta mañana! | hasta mañana (hasta mañana) |
| la-mesa | cq_gracias_abuela | ¡Gracias, abuela! | gracias (gracias) + abuela (abuela) |
| la-mesa | c24_cq_plato | ¡Un plato! | plato (plato) |
| la-mesa | c24_cq_taza | ¡Una taza! | taza (taza) |
| la-cuchara | c25_cq_cuchara | ¡Una cuchara! | cuchara (cuchara) |
| la-cuchara | c25_cq_tenedor | ¡Un tenedor! | tenedor (tenedor) |
| la-cuchara | c25_cq_cuchillo | ¡Un cuchillo! | cuchillo (cuchillo) |
| la-cuchara | c25_cq_mmm | ¡Mmm! ¡La comida de abuela! | comida (comida) + abuela (abuela) |
| tengo-hambre | cq_gracias_abuela | ¡Gracias, abuela! | gracias (gracias) + abuela (abuela) |
| tengo-hambre | c26_cq_hambre | ¡Tengo hambre! | tengo hambre (tengo hambre) |
| tengo-hambre | c26_cq_sed | ¡Tengo sed! | tengo sed (tengo sed) |
| tengo-hambre | c26_cq_canelo | ¡Canelo está contento! | contento (contento) |
| arroz-con-habichuelas | c27_cq_arroz | ¡Arroz! | arroz (arroz) |
| arroz-con-habichuelas | c27_cq_hab | ¡Habichuelas! | habichuelas (habichuelas) |
| arroz-con-habichuelas | cq_gracias_abuela | ¡Gracias, abuela! | gracias (gracias) + abuela (abuela) |
| el-pollo-y-el-huevo | c28_cq_pollo | ¡Abuela, el pollo! | pollo (pollo) |
| el-pollo-y-el-huevo | c28_cq_huevo | ¡Abuela, el huevo! | huevo (huevo) |
| el-pollo-y-el-huevo | c28_cq_fin | ¡Huele bien, abuela! | huele (huele) + bien (bien) |
| cuidado | c29_cq_carmen | ¡Carmen, cuidado! Está caliente. | cuidado (cuidado) + caliente (caliente) |
| no-hay-leche | c30_cq_no_leche | ¡Papá, no hay leche! | no hay (no hay) + leche (leche) |
| no-hay-leche | c30_cq_no_queso | ¡Papá, no hay queso! | no hay (no hay) + queso (queso) |
| no-hay-leche | c30_cq_gracias_papa | ¡Gracias, papá! | gracias (gracias) + papá (papa) |
| para-los-pajaros | c31_cq_guineo | ¡El guineo no huele bien! | guineo (guineo) + huele (huele) |
| para-los-pajaros | c31_cq_manzana | ¡La manzana no huele bien! | manzana (manzana) + huele (huele) |
| para-los-pajaros | c31_cq_adios | ¡Adiós, abuela! | adiós (adios) + abuela (abuela) |
| jugo-de-china | cq_gracias_abuela | ¡Gracias, abuela! | gracias (gracias) + abuela (abuela) |

Format in the story file (on the clip, nothing else changes):

```
"cq_gracias_abuela": {"who": "tu", "text": "¡Gracias, abuela!", "tu_turno": [{"palabra": "gracias", "formas": ["gracias"]}, {"palabra": "abuela", "formas": ["abuela"]}]}
```
