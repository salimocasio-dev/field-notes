// every group of pictures, in the order they are taken (and so numbered)
import * as app from './g-app.mjs';
import * as les from './g-lessons.mjs';
import * as hab from './g-hablar.mjs';
import * as sto from './g-story.mjs';

export const GROUPS = [
  { id: 'bienvenida', run: app.bienvenida },
  { id: 'mapa', run: app.mapa },
  { id: 'lugar', run: app.lugar },
  { id: 'palabras', run: app.palabras },
  { id: 'palabra', run: app.palabra },
  { id: 'biblioteca', run: app.biblioteca },
  { id: 'libro', run: app.libro },
  { id: 'hablar', run: app.hablar },
  { id: 'yo', run: app.yo },
  { id: 'despues-del-nivel', run: app.despuesDelNivel },
  { id: 'despues-del-nivel-1', run: app.despuesDelNivel1 },
  { id: 'repaso', run: les.repaso },
  { id: 'nivel', run: les.nivel },
  { id: 'llamada', run: hab.llamada },
  { id: 'llamada-una-palabra', run: hab.llamadaUnaPalabra },
  { id: 'llamada-errores', run: hab.llamadaErrores },
  { id: 'llamada-movimiento', run: hab.llamadaMovimiento },
  { id: 'prueba-de-voz', run: hab.pruebaDeVoz },
  { id: 'cuento', run: sto.cuento },
  { id: 'burbujas', run: sto.burbujas },
  { id: 'micro', run: sto.micro },
];
