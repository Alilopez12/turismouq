import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TurismoService } from '../../servicios/turismo.service';
import { MonitoreoTablespace, ItemSegmento, ItemTablaTablespace, ItemTablespace } from '../../modelos/modelos';

@Component({
  selector: 'app-tablespace',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './tablespace.component.html',
  styleUrl: './tablespace.component.css'
})
export class TablespaceComponent implements OnInit {

  datos: MonitoreoTablespace | null = null;
  cargando = true;
  errorMensaje = '';
  copiadoExito = false;

  // Filtros interactivos
  pestanaActiva: 'resumen' | 'segmentos' | 'tablas' | 'pilares' | 'ddl' = 'resumen';
  filtroTipoSegmento: string = 'TODOS';
  filtroTablespaceTabla: string = 'TODOS';

  constructor(
    private turismoService: TurismoService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarDatos();
  }

  cargarDatos(): void {
    this.cargando = true;
    this.errorMensaje = '';
    this.turismoService.obtenerMonitoreoTablespace().subscribe({
      next: (res) => {
        this.datos = res;
        this.cargando = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        console.error('Error al cargar métricas de Tablespace', err);
        this.errorMensaje = 'No se pudo conectar con el motor Oracle 21c o falló la consulta de almacenamiento.';
        this.cargando = false;
        this.cdr.detectChanges();
      }
    });
  }

  seleccionarPestana(p: 'resumen' | 'segmentos' | 'tablas' | 'pilares' | 'ddl'): void {
    this.pestanaActiva = p;
  }

  // --- Helpers de cálculo y métricas ---
  obtenerTablespaceHistorico(): ItemTablespace | undefined {
    return this.datos?.tablespaces.find(t => t.TABLESPACE_NAME === 'TBS_HISTORICO_RESERVAS');
  }

  obtenerMbConsumidosHistorico(): number {
    const ts = this.obtenerTablespaceHistorico();
    if (!ts || !ts.BYTES_CONSUMIDOS) return 9.31;
    return Number((ts.BYTES_CONSUMIDOS / (1024 * 1024)).toFixed(2));
  }

  obtenerPorcentajeUsoInicial(): number {
    const mb = this.obtenerMbConsumidosHistorico();
    const tamInicial = this.datos?.datafileInfo.tamanoInicialMb || 50;
    return Number(((mb / tamInicial) * 100).toFixed(1));
  }

  obtenerPorcentajeUsoMaximo(): number {
    const mb = this.obtenerMbConsumidosHistorico();
    const tamMax = this.datos?.datafileInfo.tamanoMaximoMb || 2048;
    return Number(((mb / tamMax) * 100).toFixed(2));
  }

  obtenerTotalFilasHistorico(): number {
    if (!this.datos) return 0;
    return this.datos.tablasPorTablespace
      .filter(t => t.TABLESPACE_NAME === 'TBS_HISTORICO_RESERVAS')
      .reduce((acc, t) => acc + (t.NUM_ROWS || 0), 0);
  }

  obtenerTotalFilasUsers(): number {
    if (!this.datos) return 0;
    return this.datos.tablasPorTablespace
      .filter(t => t.TABLESPACE_NAME === 'USERS')
      .reduce((acc, t) => acc + (t.NUM_ROWS || 0), 0);
  }

  obtenerSegmentosFiltrados(): ItemSegmento[] {
    if (!this.datos) return [];
    if (this.filtroTipoSegmento === 'TODOS') {
      return this.datos.segmentosHistorico;
    }
    return this.datos.segmentosHistorico.filter(s => s.SEGMENT_TYPE === this.filtroTipoSegmento);
  }

  obtenerTablasFiltradas(): ItemTablaTablespace[] {
    if (!this.datos) return [];
    if (this.filtroTablespaceTabla === 'TODOS') {
      return this.datos.tablasPorTablespace;
    }
    return this.datos.tablasPorTablespace.filter(t => t.TABLESPACE_NAME === this.filtroTablespaceTabla);
  }

  obtenerIconoSegmento(tipo: string): string {
    if (tipo === 'TABLE') return '🗄️';
    if (tipo === 'INDEX') return '⚡';
    return '📦';
  }

  obtenerColorBadge(tablespace: string): string {
    return tablespace === 'TBS_HISTORICO_RESERVAS' ? 'badge-historico' : 'badge-users';
  }

  copiarDdl(): void {
    if (!this.datos?.scriptDdl) return;
    navigator.clipboard.writeText(this.datos.scriptDdl).then(() => {
      this.copiadoExito = true;
      this.cdr.detectChanges();
      setTimeout(() => {
        this.copiadoExito = false;
        this.cdr.detectChanges();
      }, 2500);
    });
  }
}
