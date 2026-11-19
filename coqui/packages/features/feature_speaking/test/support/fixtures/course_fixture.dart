// Made by tool/make_fixtures.dart from historia/datos/curso.json and the stories of La casa. Do not edit.
// ignore_for_file: lines_longer_than_80_chars

/// curso.json's `lugares`: the ten places, as one line of JSON.
const String fixturePlacesJson =
    r'''[{"id":"casa","n":1,"nombre":"La casa","en":"Grandma's house","cuentos":["la-lluvia","el-bizcocho","donde-esta-el-pajaro","el-jugo","que-calor","la-familia","la-foto","quien-eres-tu","las-flores","que-es-esto","hasta-manana"],"dibujos":["d-toc-toc","d-agua-pajaro","d-bizcocho-bebe","d-foto-familia","d-la-bola","d-buenas-noches"],"haz":["h-frente","h-balcon","h-sala","h-patio"],"escenas":["El frente","El balcón","La sala","El patio"]},{"id":"parque","n":2,"nombre":"El parque","en":"The park","fork":"2a","cuentos":["uno-dos-tres","donde-esta-el-gato","rapido-despacio","la-bola","arriba-abajo","otra-vez","pan-para-el-pato","los-botes","cual","la-piragua","senor-senora","el-bebe-duerme"],"dibujos":["d-corre","d-bola-canelo","d-pato-pequeno","d-piragua-luis","d-vamos-a-casa"],"haz":["h-camino","h-campo","h-lago","h-banco"],"escenas":["El camino","El campo","El lago","El banco"]},{"id":"cocina","n":3,"nombre":"La cocina","en":"The kitchen","fork":"2b","cuentos":["la-mesa","la-cuchara","tengo-hambre","arroz-con-habichuelas","el-pollo-y-el-huevo","cuidado","no-hay-leche","para-los-pajaros","jugo-de-china"],"escenas":["La mesa","La estufa","La nevera","A comer"]},{"id":"colmado","n":4,"nombre":"El colmado","en":"The corner shop","escenas":["El mostrador","Los estantes","Las frutas","La caja"]},{"id":"calle","n":5,"nombre":"La calle","en":"The street","fork":"4a","escenas":["La esquina","La parada","Las tiendas","El cruce"]},{"id":"plaza","n":6,"nombre":"La plaza","en":"The town square","fork":"4b","escenas":["El banco de la plaza","El reloj","El quiosco","El calendario"]},{"id":"playa","n":7,"nombre":"La playa","en":"The beach","fork":"5a","escenas":["La orilla","La sombrilla","La ropa","El cielo"]},{"id":"fonda","n":8,"nombre":"La fonda","en":"The diner","fork":"5b","escenas":["La entrada","El pedido","La comida","La cuenta"]},{"id":"casa2","n":9,"nombre":"La casa, un día entero","en":"A whole day at home","escenas":["El cuarto","El baño","La sala, de día","La noche"]},{"id":"fuerte","n":10,"nombre":"El fuerte","en":"The fort","escenas":["El camino al fuerte","La música","Los regalos","La muralla, de noche"]}]''';

/// For each story of La casa, what llamada.js reads of it: its `place` and its `focus_words`.
const Map<String, String> fixtureCasaStories = {
  'la-lluvia': r'''{"place":"La casa","focus_words":["casa","puerta","ventana","abuela","hola","toca","abre"]}''',
  'el-bizcocho':
      r'''{"place":"La casa","focus_words":["cierra","sí","no","abre"]}''',
  'donde-esta-el-pajaro':
      r'''{"place":"La casa","focus_words":["grande","pequeña","adiós"]}''',
  'el-jugo': r'''{"place":"La casa","focus_words":["silla","se sienta","vaso","jugo","agua","toma"]}''',
  'que-calor': r'''{"place":"La casa","focus_words":["quiero","gracias","¿cómo estás?","bien"]}''',
  'la-familia': r'''{"place":"La casa","focus_words":["mamá","papá","abuelo","bebé","familia"]}''',
  'la-foto': r'''{"place":"La casa","focus_words":["hermano","hermana","él","ella"]}''',
  'quien-eres-tu': r'''{"place":"La casa","focus_words":["yo","tú","soy","eres","me llamo"]}''',
  'las-flores': r'''{"place":"La casa","focus_words":["niño","niña","juega","flor","sol","aquí","allá"]}''',
  'que-es-esto': r'''{"place":"La casa","focus_words":["¿qué es esto?","amigo","mira","ven"]}''',
  'hasta-manana':
      r'''{"place":"La casa","focus_words":["vamos","hasta mañana"]}''',
};
