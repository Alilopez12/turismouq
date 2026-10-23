import { Routes } from '@angular/router';
import { CatalogoComponent } from './componentes/catalogo/catalogo.component';
import { DetalleAlojamientoComponent } from './componentes/detalle-alojamiento/detalle-alojamiento.component';
import { FormularioReservaComponent } from './componentes/formulario-reserva/formulario-reserva.component';
import { LiquidacionesComponent } from './componentes/liquidaciones/liquidaciones.component';
import { AnaliticaComponent } from './componentes/analitica/analitica.component';
import { AuditoriaComponent } from './componentes/auditoria/auditoria.component';
import { TablespaceComponent } from './componentes/tablespace/tablespace.component';

export const routes: Routes = [
  { path: '', redirectTo: 'catalogo', pathMatch: 'full' },
  { path: 'catalogo', component: CatalogoComponent },
  { path: 'alojamientos/:id', component: DetalleAlojamientoComponent },
  { path: 'reservas', component: FormularioReservaComponent },
  { path: 'liquidaciones', component: LiquidacionesComponent },
  { path: 'analitica', component: AnaliticaComponent },
  { path: 'auditoria', component: AuditoriaComponent },
  { path: 'tablespace', component: TablespaceComponent },
  { path: '**', redirectTo: 'catalogo' }
];
