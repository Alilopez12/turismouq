import { Routes } from '@angular/router';
import { CatalogoComponent } from './componentes/catalogo/catalogo.component';
import { DetalleAlojamientoComponent } from './componentes/detalle-alojamiento/detalle-alojamiento.component';
import { FormularioReservaComponent } from './componentes/formulario-reserva/formulario-reserva.component';
import { RecepcionComponent } from './componentes/recepcion/recepcion.component';
import { LiquidacionesComponent } from './componentes/liquidaciones/liquidaciones.component';
import { TransaccionesComponent } from './componentes/transacciones/transacciones.component';
import { ConcurrenciaComponent } from './componentes/concurrencia/concurrencia.component';
import { OptimizadorCboComponent } from './componentes/optimizador-cbo/optimizador-cbo.component';
import { AnaliticaComponent } from './componentes/analitica/analitica.component';
import { AuditoriaComponent } from './componentes/auditoria/auditoria.component';
import { TablespaceComponent } from './componentes/tablespace/tablespace.component';

export const routes: Routes = [
  { path: '', redirectTo: 'catalogo', pathMatch: 'full' },
  { path: 'catalogo', component: CatalogoComponent },
  { path: 'alojamientos/:id', component: DetalleAlojamientoComponent },
  { path: 'reservas', component: FormularioReservaComponent },
  { path: 'recepcion', component: RecepcionComponent },
  { path: 'liquidaciones', component: LiquidacionesComponent },
  { path: 'transacciones', component: TransaccionesComponent },
  { path: 'concurrencia', component: ConcurrenciaComponent },
  { path: 'optimizador-cbo', component: OptimizadorCboComponent },
  { path: 'analitica', component: AnaliticaComponent },
  { path: 'auditoria', component: AuditoriaComponent },
  { path: 'tablespace', component: TablespaceComponent },
  { path: 'entrega-3', redirectTo: 'transacciones', pathMatch: 'full' },
  { path: '**', redirectTo: 'catalogo' }
];
