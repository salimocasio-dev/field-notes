"use strict";
/* The A1 course: ten places on the map, three forks, the stories built so far. From page 02-all-40-scenes. */
const CURSO={
  lugares:[
    {id:"casa",n:1,nombre:"La casa",en:"Grandma's house",cuentos:["la-lluvia","el-bizcocho","donde-esta-el-pajaro","el-jugo","que-calor","la-familia","la-foto","quien-eres-tu","las-flores","que-es-esto","hasta-manana"],escenas:["El frente","El balcón","La sala","El patio"]},
    {id:"parque",n:2,nombre:"El parque",en:"The park",fork:"2a",escenas:["El camino","El campo","El lago","El banco"]},
    {id:"cocina",n:3,nombre:"La cocina",en:"The kitchen",fork:"2b",escenas:["La mesa","La estufa","La nevera","A comer"]},
    {id:"colmado",n:4,nombre:"El colmado",en:"The corner shop",escenas:["El mostrador","Los estantes","Las frutas","La caja"]},
    {id:"calle",n:5,nombre:"La calle",en:"The street",fork:"4a",escenas:["La esquina","La parada","Las tiendas","El cruce"]},
    {id:"plaza",n:6,nombre:"La plaza",en:"The town square",fork:"4b",escenas:["El banco de la plaza","El reloj","El quiosco","El calendario"]},
    {id:"playa",n:7,nombre:"La playa",en:"The beach",fork:"5a",escenas:["La orilla","La sombrilla","La ropa","El cielo"]},
    {id:"fonda",n:8,nombre:"La fonda",en:"The diner",fork:"5b",escenas:["La entrada","El pedido","La comida","La cuenta"]},
    {id:"casa2",n:9,nombre:"La casa, un día entero",en:"A whole day at home",escenas:["El cuarto","El baño","La sala, de día","La noche"]},
    {id:"fuerte",n:10,nombre:"El fuerte",en:"The fort",escenas:["El camino al fuerte","La música","Los regalos","La muralla, de noche"]}],
  cuentos:{"la-lluvia":{t:"La lluvia",min:2},"el-bizcocho":{t:"El bizcocho",min:3},"donde-esta-el-pajaro":{t:"¿Dónde está el pájaro?",min:3},
    "el-jugo":{t:"El jugo",min:4},"que-calor":{t:"¡Qué calor!",min:3},
    "la-familia":{t:"La familia",min:4},"la-foto":{t:"La foto",min:3},"quien-eres-tu":{t:"¿Quién eres tú?",min:4},
    "las-flores":{t:"Las flores",min:5},"que-es-esto":{t:"¿Qué es esto?",min:5},"hasta-manana":{t:"Hasta mañana",min:4}},
  cual:["cual-frente","cual-balcon","cual-sala","cual-patio"]   // the next-day picture pairs, one file per scene
};
