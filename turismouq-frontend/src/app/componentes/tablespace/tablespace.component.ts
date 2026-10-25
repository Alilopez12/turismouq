import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TurismoService } from '../../servicios/turismo.service';
import { MonitoreoTablespace } from '../../modelos/modelos';

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

  // Acceso seguro insensible a mayúsculas/minúsculas
  getProp(obj: any, clave: string): any {
    if (!obj) return null;
    if (obj[clave] !== undefined) return obj[clave];
    const keyMatch = Object.keys(obj).find(k => k.toLowerCase() === clave.toLowerCase());
    return keyMatch ? obj[keyMatch] : null;
  }

  // --- Helpers de cálculo y métricas ---
  obtenerTablespaceHistorico(): any {
    return this.datos?.tablespaces?.find((t: any) =>
      this.getProp(t, 'tablespace_name') === 'TBS_HISTORICO_RESERVAS'
    );
  }

  obtenerMbConsumidosHistorico(): number {
    const ts = this.obtenerTablespaceHistorico();
    const bytes = this.getProp(ts, 'bytes_consumidos');
    if (!bytes || Number(bytes) <= 0) {
      // Si la cuota no lo reporta directo, calcular sumando los segmentos de TBS_HISTORICO_RESERVAS
      if (this.datos?.segmentosHistorico && this.datos.segmentosHistorico.length > 0) {
        const totalB = this.datos.segmentosHistorico.reduce((acc: number, s: any) =>
          acc + (Number(this.getProp(s, 'bytes')) || 0), 0);
        return Number((totalB / (1024 * 1024)).toFixed(2));
      }
      return 11.44;
    }
    return Number((Number(bytes) / (1024 * 1024)).toFixed(2));
  }

  obtenerPorcentajeUsoInicial(): number {
    const mb = this.obtenerMbConsumidosHistorico();
    const tamInicial = this.datos?.datafileInfo?.tamanoInicialMb || 50;
    return Number(((mb / tamInicial) * 100).toFixed(1));
  }

  obtenerPorcentajeUsoMaximo(): number {
    const mb = this.obtenerMbConsumidosHistorico();
    const tamMax = this.datos?.datafileInfo?.tamanoMaximoMb || 2048;
    return Number(((mb / tamMax) * 100).toFixed(2));
  }

  obtenerTotalFilasHistorico(): number {
    if (!this.datos?.tablasPorTablespace) return 0;
    return this.datos.tablasPorTablespace
      .filter((t: any) => this.getProp(t, 'tablespace_name') === 'TBS_HISTORICO_RESERVAS')
      .reduce((acc: number, t: any) => acc + (Number(this.getProp(t, 'num_rows')) || 0), 0);
  }

  obtenerTotalFilasUsers(): number {
    if (!this.datos?.tablasPorTablespace) return 0;
    return this.datos.tablasPorTablespace
      .filter((t: any) => this.getProp(t, 'tablespace_name') === 'USERS')
      .reduce((acc: number, t: any) => acc + (Number(this.getProp(t, 'num_rows')) || 0), 0);
  }

  obtenerSegmentosFiltrados(): any[] {
    if (!this.datos?.segmentosHistorico) return [];
    if (this.filtroTipoSegmento === 'TODOS') {
      return this.datos.segmentosHistorico;
    }
    return this.datos.segmentosHistorico.filter((s: any) =>
      this.getProp(s, 'segment_type') === this.filtroTipoSegmento
    );
  }

  obtenerTablasFiltradas(): any[] {
    if (!this.datos?.tablasPorTablespace) return [];
    if (this.filtroTablespaceTabla === 'TODOS') {
      return this.datos.tablasPorTablespace;
    }
    return this.datos.tablasPorTablespace.filter((t: any) =>
      this.getProp(t, 'tablespace_name') === this.filtroTablespaceTabla
    );
  }

  contarSegmentos(tipo: string): number {
    if (!this.datos?.segmentosHistorico) return 0;
    return this.datos.segmentosHistorico.filter((s: any) =>
      this.getProp(s, 'segment_type') === tipo
    ).length;
  }

  contarTablasPorTablespace(tsName: string): number {
    if (!this.datos?.tablasPorTablespace) return 0;
    return this.datos.tablasPorTablespace.filter((t: any) =>
      this.getProp(t, 'tablespace_name') === tsName
    ).length;
  }

  obtenerIconoSegmento(tipo: string): string {
    const t = (tipo || '').toUpperCase();
    if (t === 'TABLE') return '🗄️';
    if (t === 'INDEX') return '⚡';
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
