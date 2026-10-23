import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TurismoService } from '../../servicios/turismo.service';

interface InfoConsultaSql {
  numero: number;
  nombre: string;
  tecnica: string;
  proposito: string;
  codigoSql: string;
}

@Component({
  selector: 'app-analitica',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './analitica.component.html',
  styleUrl: './analitica.component.css'
})
export class AnaliticaComponent implements OnInit {

  pestanaActiva = 1;
  cargando = false;
  errorMensaje = '';

  // Datos devueltos por el backend
  datosPivot: any[] = [];
  datosRollup: any[] = [];
  datosRank: any[] = [];
  datosLag: any[] = [];
  datosRango: any[] = [];
  datosVistaMat: any[] = [];
  datosUnpivot: any[] = [];
  datosServicios: any[] = [];

  // Filtros
  fechaInicio = '2025-01-01';
  fechaFin = '2025-12-31';
  municipioSeleccionadoRank = 'TODOS';

  // Control de acordeón SQL por consulta
  verSql: { [key: number]: boolean } = {};

  // Nombres de los 12 meses para PIVOT
  readonly nombresMeses = [
    { clave: 'ENERO', etiqueta: 'Ene' },
    { clave: 'FEBRERO', etiqueta: 'Feb' },
    { clave: 'MARZO', etiqueta: 'Mar' },
    { clave: 'ABRIL', etiqueta: 'Abr' },
    { clave: 'MAYO', etiqueta: 'May' },
    { clave: 'JUNIO', etiqueta: 'Jun' },
    { clave: 'JULIO', etiqueta: 'Jul' },
    { clave: 'AGOSTO', etiqueta: 'Ago' },
    { clave: 'SEPTIEMBRE', etiqueta: 'Sep' },
    { clave: 'OCTUBRE', etiqueta: 'Oct' },
    { clave: 'NOVIEMBRE', etiqueta: 'Nov' },
    { clave: 'DICIEMBRE', etiqueta: 'Dic' }
  ];

  // Catálogo completo de sentencias SQL de la Entrega 1
  readonly infoConsultas: { [key: number]: InfoConsultaSql } = {
    1: {
      numero: 1,
      nombre: 'Ocupación por Municipio y Mes con Cláusula PIVOT',
      tecnica: 'PIVOT nativo de Oracle 21c (12 meses x 12 municipios)',
      proposito: 'Cruzar el volumen de reservas transformando valores de fila (meses 01 a 12) en 12 columnas analíticas para analizar estacionalidad.',
      codigoSql: `-- ============================================================================
-- CONSULTA 1: Ocupación por municipio y mes con PIVOT (12 meses)
-- ============================================================================
SELECT *
FROM (
    SELECT
        m.nombre AS municipio,
        TO_CHAR(r.fecha_check_in, 'MM') AS mes,
        r.id_reserva
    FROM MUNICIPIO m
    JOIN ALOJAMIENTO a ON m.id_municipio = a.id_municipio
    JOIN HABITACION h ON a.id_alojamiento = h.id_alojamiento
    JOIN RESERVA_HABITACION rh ON h.id_habitacion = rh.id_habitacion
    JOIN RESERVA r ON rh.id_reserva = r.id_reserva
)
PIVOT (
    COUNT(id_reserva)
    FOR mes IN (
        '01' AS ENERO, '02' AS FEBRERO, '03' AS MARZO, '04' AS ABRIL,
        '05' AS MAYO, '06' AS JUNIO, '07' AS JULIO, '08' AS AGOSTO,
        '09' AS SEPTIEMBRE, '10' AS OCTUBRE, '11' AS NOVIEMBRE, '12' AS DICIEMBRE
    )
)
ORDER BY municipio;`
    },
    2: {
      numero: 2,
      nombre: 'Ingresos por Municipio, Tipo y Temporada con ROLLUP',
      tecnica: 'GROUP BY ROLLUP(...) con GROUPING() para detección de subtotales',
      proposito: 'Generar subtotales multinivel (por Temporada, por Tipo de Alojamiento, por Municipio y Total General Quindío).',
      codigoSql: `-- ============================================================================
-- CONSULTA 2: Ingresos por municipio, tipo y temporada con ROLLUP
-- ============================================================================
SELECT
    CASE WHEN GROUPING(m.nombre) = 1 THEN 'TOTAL GENERAL' ELSE m.nombre END AS municipio,
    CASE WHEN GROUPING(ta.nombre) = 1 THEN 'TOTAL' ELSE ta.nombre END AS tipo_alojamiento,
    CASE WHEN GROUPING(t.nombre) = 1 THEN 'TOTAL' ELSE t.nombre END AS temporada,
    SUM(r.total) AS ingresos
FROM MUNICIPIO m
JOIN ALOJAMIENTO a ON m.id_municipio = a.id_municipio
JOIN TIPO_ALOJAMIENTO ta ON a.id_tipo_alojamiento = ta.id_tipo_alojamiento
JOIN HABITACION h ON a.id_alojamiento = h.id_alojamiento
JOIN RESERVA_HABITACION rh ON h.id_habitacion = rh.id_habitacion
JOIN RESERVA r ON rh.id_reserva = r.id_reserva
JOIN (
    SELECT r_sub.id_reserva,
           NVL((SELECT temp.nombre 
                FROM PERIODO_TEMPORADA pt 
                JOIN TEMPORADA temp ON pt.id_temporada = temp.id_temporada
                WHERE r_sub.fecha_check_in BETWEEN pt.fecha_inicio AND pt.fecha_fin
                  AND ROWNUM = 1), 'TEMPORADA BAJA') AS nombre
    FROM RESERVA r_sub
) t ON r.id_reserva = t.id_reserva
GROUP BY ROLLUP (m.nombre, ta.nombre, t.nombre);`
    },
    3: {
      numero: 3,
      nombre: 'Top 3 Alojamientos de Mayor Ingreso por Municipio con RANK()',
      tecnica: 'Función analítica RANK() OVER (PARTITION BY municipio ORDER BY ingresos DESC)',
      proposito: 'Identificar a los líderes comerciales de cada uno de los 12 municipios premiando el podio (🥇 Oro, 🥈 Plata, 🥉 Bronce).',
      codigoSql: `-- ============================================================================
-- CONSULTA 3: Top 3 alojamientos con mayor ingreso por municipio con RANK()
-- ============================================================================
SELECT municipio, alojamiento, ingresos, posicion
FROM (
    SELECT
        m.nombre AS municipio,
        a.nombre AS alojamiento,
        SUM(r.total) AS ingresos,
        RANK() OVER (PARTITION BY m.nombre ORDER BY SUM(r.total) DESC) AS posicion
    FROM MUNICIPIO m
    JOIN ALOJAMIENTO a ON m.id_municipio = a.id_municipio
    JOIN HABITACION h ON a.id_alojamiento = h.id_alojamiento
    JOIN RESERVA_HABITACION rh ON h.id_habitacion = rh.id_habitacion
    JOIN RESERVA r ON rh.id_reserva = r.id_reserva
    GROUP BY m.nombre, a.nombre
)
WHERE posicion <= 3
ORDER BY municipio, posicion;`
    },
    4: {
      numero: 4,
      nombre: 'Variación de Ingresos Mes contra Mes con LAG()',
      tecnica: 'Función de ventana LAG(ingresos) OVER (ORDER BY mes)',
      proposito: 'Calcular el crecimiento económico o desaceleración relativa de los ingresos comparando cada mes contra su inmediato anterior.',
      codigoSql: `-- ============================================================================
-- CONSULTA 4: Variación de ingresos mes contra mes con LAG()
-- ============================================================================
SELECT
    mes,
    ingresos,
    LAG(ingresos) OVER (ORDER BY mes) AS ingreso_mes_anterior,
    ingresos - LAG(ingresos) OVER (ORDER BY mes) AS variacion
FROM (
    SELECT
        TRUNC(fecha_check_in, 'MM') AS mes,
        SUM(total) AS ingresos
    FROM RESERVA
    GROUP BY TRUNC(fecha_check_in, 'MM')
)
ORDER BY mes;`
    },
    5: {
      numero: 5,
      nombre: 'Consulta Parametrizada con Variables Bind (:fecha_inicio, :fecha_fin)',
      tecnica: 'Variables Bind de Oracle para reuso del Execution Plan en Shared Pool',
      proposito: 'Garantizar alto rendimiento con soft parses sin recompilación de planes SQL al filtrar por cualquier rango temporal.',
      codigoSql: `-- ============================================================================
-- CONSULTA 5: Consulta parametrizada con variables bind (:fecha_inicio, :fecha_fin)
-- ============================================================================
VARIABLE fecha_inicio VARCHAR2(10);
VARIABLE fecha_fin VARCHAR2(10);
EXEC :fecha_inicio := '01/01/2025';
EXEC :fecha_fin := '31/12/2025';

SELECT
    r.id_reserva,
    r.fecha_check_in,
    r.fecha_check_out,
    r.total,
    r.estado
FROM RESERVA r
WHERE r.fecha_check_in BETWEEN
      TO_DATE(:fecha_inicio, 'DD/MM/YYYY')
      AND TO_DATE(:fecha_fin, 'DD/MM/YYYY')
  AND ROWNUM <= 25
ORDER BY r.fecha_check_in;`
    },
    6: {
      numero: 6,
      nombre: 'Lectura de Vista Materializada (MV_OCUPACION_MENSUAL)',
      tecnica: 'CREATE MATERIALIZED VIEW ... REFRESH ON DEMAND COMPLETE',
      proposito: 'Demostrar aceleración de consultas analíticas pesadas mediante almacenamiento físico precalculado que aísla la carga OLTP.',
      codigoSql: `-- ============================================================================
-- CONSULTA 6: Vista materializada de ocupación mensual (MV_OCUPACION_MENSUAL)
-- ============================================================================
EXEC DBMS_MVIEW.REFRESH('TURISMO_UQ.MV_OCUPACION_MENSUAL', 'C');

SELECT *
FROM MV_OCUPACION_MENSUAL
WHERE ROWNUM <= 24
ORDER BY municipio, mes;`
    },
    7: {
      numero: 7,
      nombre: 'Desagregación Matricial de Métodos de Pago con UNPIVOT',
      tecnica: 'Cláusula UNPIVOT de columnas agregadas a tuplas estructuradas',
      proposito: 'Transformar columnas horizontales agregadas (PSE, Tarjeta de Crédito, Transferencia) en filas aptas para gráficos de participación.',
      codigoSql: `-- ============================================================================
-- CONSULTA 7: Desagregación de métodos de pago con UNPIVOT
-- ============================================================================
SELECT metodo_pago, cantidad_pagos
FROM (
    SELECT
        SUM(CASE WHEN metodo_pago = 'PSE' THEN 1 ELSE 0 END) AS PSE,
        SUM(CASE WHEN metodo_pago = 'TARJETA_CREDITO' THEN 1 ELSE 0 END) AS TARJETA_CREDITO,
        SUM(CASE WHEN metodo_pago = 'TRANSFERENCIA' THEN 1 ELSE 0 END) AS TRANSFERENCIA
    FROM PAGO
)
UNPIVOT (
    cantidad_pagos
    FOR metodo_pago IN (
        PSE AS 'PSE',
        TARJETA_CREDITO AS 'TARJETA_CREDITO',
        TRANSFERENCIA AS 'TRANSFERENCIA'
    )
)
ORDER BY cantidad_pagos DESC;`
    },
    8: {
      numero: 8,
      nombre: 'Pregunta de Negocio Libre: Cuatro Tipos de Alojamiento',
      tecnica: 'Agrupación y agregación multidimensional de negocio (JOIN + COUNT DISTINCT + SUM)',
      proposito: 'Comparar el rendimiento de los 4 tipos de hospedaje del Quindío (Finca cafetera, Glamping, Hotel, Hostal) en facturación y demanda.',
      codigoSql: `-- ============================================================================
-- CONSULTA 8: Consulta libre de negocio - Reservas e ingresos por Tipo
-- ============================================================================
SELECT
    ta.nombre AS tipo_alojamiento,
    COUNT(DISTINCT r.id_reserva) AS total_reservas,
    SUM(r.total) AS ingresos_totales
FROM TIPO_ALOJAMIENTO ta
JOIN ALOJAMIENTO a ON ta.id_tipo_alojamiento = a.id_tipo_alojamiento
JOIN HABITACION h ON a.id_alojamiento = h.id_alojamiento
JOIN RESERVA_HABITACION rh ON h.id_habitacion = rh.id_habitacion
JOIN RESERVA r ON rh.id_reserva = r.id_reserva
GROUP BY ta.nombre
ORDER BY ingresos_totales DESC;`
    }
  };

  constructor(
    private turismoService: TurismoService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.seleccionarPestana(1);
  }

  seleccionarPestana(num: number): void {
    this.pestanaActiva = num;
    this.cargando = true;
    this.errorMensaje = '';

    switch (num) {
      case 1:
        this.turismoService.obtenerOcupacionPivot().subscribe({
          next: d => { this.datosPivot = d || []; this.cargando = false; this.cdr.detectChanges(); },
          error: e => { console.error(e); this.errorMensaje = 'No se pudo conectar con el backend o la consulta falló.'; this.cargando = false; this.cdr.detectChanges(); }
        });
        break;
      case 2:
        this.turismoService.obtenerIngresosRollup().subscribe({
          next: d => { this.datosRollup = d || []; this.cargando = false; this.cdr.detectChanges(); },
          error: e => { console.error(e); this.errorMensaje = 'No se pudo conectar con el backend o la consulta falló.'; this.cargando = false; this.cdr.detectChanges(); }
        });
        break;
      case 3:
        this.turismoService.obtenerTop3Municipio().subscribe({
          next: d => { this.datosRank = d || []; this.cargando = false; this.cdr.detectChanges(); },
          error: e => { console.error(e); this.errorMensaje = 'No se pudo conectar con el backend o la consulta falló.'; this.cargando = false; this.cdr.detectChanges(); }
        });
        break;
      case 4:
        this.turismoService.obtenerVariacionLag().subscribe({
          next: d => { this.datosLag = d || []; this.cargando = false; this.cdr.detectChanges(); },
          error: e => { console.error(e); this.errorMensaje = 'No se pudo conectar con el backend o la consulta falló.'; this.cargando = false; this.cdr.detectChanges(); }
        });
        break;
      case 5:
        this.ejecutarConsultaRango();
        break;
      case 6:
        this.turismoService.obtenerVistaMaterializada().subscribe({
          next: d => { this.datosVistaMat = d || []; this.cargando = false; this.cdr.detectChanges(); },
          error: e => { console.error(e); this.errorMensaje = 'No se pudo conectar con el backend o la consulta falló.'; this.cargando = false; this.cdr.detectChanges(); }
        });
        break;
      case 7:
        this.turismoService.obtenerUnpivot().subscribe({
          next: d => { this.datosUnpivot = d || []; this.cargando = false; this.cdr.detectChanges(); },
          error: e => { console.error(e); this.errorMensaje = 'No se pudo conectar con el backend o la consulta falló.'; this.cargando = false; this.cdr.detectChanges(); }
        });
        break;
      case 8:
        this.turismoService.obtenerServiciosNegocio().subscribe({
          next: d => { this.datosServicios = d || []; this.cargando = false; this.cdr.detectChanges(); },
          error: e => { console.error(e); this.errorMensaje = 'No se pudo conectar con el backend o la consulta falló.'; this.cargando = false; this.cdr.detectChanges(); }
        });
        break;
    }
  }

  toggleSql(num: number): void {
    this.verSql[num] = !this.verSql[num];
  }

  // Acceso seguro insensible a mayúsculas/minúsculas
  getProp(obj: any, clave: string): any {
    if (!obj) return null;
    if (obj[clave] !== undefined) return obj[clave];
    const keyMatch = Object.keys(obj).find(k => k.toLowerCase() === clave.toLowerCase());
    return keyMatch ? obj[keyMatch] : null;
  }

  // --- Helpers Consulta 1 (PIVOT) ---
  obtenerTotalFilaPivot(fila: any): number {
    return this.nombresMeses.reduce((acc, m) => acc + (Number(this.getProp(fila, m.clave)) || 0), 0);
  }

  obtenerTotalAnualPivot(): number {
    return this.datosPivot.reduce((acc, f) => acc + this.obtenerTotalFilaPivot(f), 0);
  }

  obtenerMaxMesPivot(): number {
    let max = 1;
    for (const f of this.datosPivot) {
      for (const m of this.nombresMeses) {
        const val = Number(this.getProp(f, m.clave)) || 0;
        if (val > max) max = val;
      }
    }
    return max;
  }

  obtenerIntensidadPivot(valor: number): string {
    const max = this.obtenerMaxMesPivot();
    const ratio = valor / max;
    if (ratio > 0.8) return 'nivel-alto';
    if (ratio > 0.4) return 'nivel-medio';
    return 'nivel-normal';
  }

  // --- Helpers Consulta 2 (ROLLUP) ---
  esFilaSubtotal(fila: any): boolean {
    const agrMuni = Number(this.getProp(fila, 'agrupado_municipio'));
    const agrTipo = Number(this.getProp(fila, 'agrupado_tipo'));
    const agrTemp = Number(this.getProp(fila, 'agrupado_temporada'));
    return agrMuni === 1 || agrTipo === 1 || agrTemp === 1;
  }

  obtenerTotalGeneralRollup(): number {
    const filaTotal = this.datosRollup.find(f => {
      const muni = String(this.getProp(f, 'municipio') || '').toUpperCase();
      return muni.includes('TOTAL');
    });
    return filaTotal ? (Number(this.getProp(filaTotal, 'total_ingresos') || this.getProp(filaTotal, 'ingresos')) || 0) : 0;
  }

  // --- Helpers Consulta 3 (RANK) ---
  obtenerMunicipiosDisponiblesRank(): string[] {
    const set = new Set<string>();
    this.datosRank.forEach(f => {
      const m = this.getProp(f, 'municipio');
      if (m) set.add(m);
    });
    return Array.from(set).sort();
  }

  obtenerFilasRankFiltradas(): any[] {
    if (this.municipioSeleccionadoRank === 'TODOS') {
      return this.datosRank;
    }
    return this.datosRank.filter(f => this.getProp(f, 'municipio') === this.municipioSeleccionadoRank);
  }

  obtenerPodioPorMunicipio(municipio: string): { primero?: any; segundo?: any; tercero?: any } {
    const filtrados = this.datosRank.filter(f => this.getProp(f, 'municipio') === municipio);
    return {
      primero: filtrados.find(f => Number(this.getProp(f, 'posicion_ranking') || this.getProp(f, 'posicion')) === 1),
      segundo: filtrados.find(f => Number(this.getProp(f, 'posicion_ranking') || this.getProp(f, 'posicion')) === 2),
      tercero: filtrados.find(f => Number(this.getProp(f, 'posicion_ranking') || this.getProp(f, 'posicion')) === 3)
    };
  }

  obtenerMaxIngresoRank(): number {
    let max = 1;
    for (const f of this.datosRank) {
      const ing = Number(this.getProp(f, 'total_ingresos') || this.getProp(f, 'ingresos')) || 0;
      if (ing > max) max = ing;
    }
    return max;
  }

  // --- Helpers Consulta 4 (LAG) ---
  obtenerMaxIngresoLag(): number {
    let max = 1;
    for (const f of this.datosLag) {
      const ing = Number(this.getProp(f, 'total_ingresos') || this.getProp(f, 'ingresos')) || 0;
      if (ing > max) max = ing;
    }
    return max;
  }

  obtenerPorcentajeBarraLag(ingreso: number): number {
    const max = this.obtenerMaxIngresoLag();
    return Math.max(10, Math.round((ingreso / max) * 100));
  }

  obtenerMesMayorCrecimiento(): any {
    if (!this.datosLag.length) return null;
    return this.datosLag.reduce((prev, curr) => {
      const varCurr = Number(this.getProp(curr, 'variacion_porcentual')) || 0;
      const varPrev = Number(this.getProp(prev, 'variacion_porcentual')) || 0;
      return varCurr > varPrev ? curr : prev;
    }, this.datosLag[0]);
  }

  // --- Helpers Consulta 5 (Bind Variables) ---
  establecerRangoPredefinido(tipo: string): void {
    if (tipo === 'semestre1') {
      this.fechaInicio = '2025-01-01';
      this.fechaFin = '2025-06-30';
    } else if (tipo === 'semestre2') {
      this.fechaInicio = '2025-07-01';
      this.fechaFin = '2025-12-31';
    } else if (tipo === 'mitad_anio') {
      this.fechaInicio = '2025-06-15';
      this.fechaFin = '2025-08-20';
    } else {
      this.fechaInicio = '2025-01-01';
      this.fechaFin = '2025-12-31';
    }
    this.ejecutarConsultaRango();
  }

  ejecutarConsultaRango(): void {
    this.cargando = true;
    this.errorMensaje = '';
    this.turismoService.obtenerConsultaRango(this.fechaInicio, this.fechaFin).subscribe({
      next: d => { this.datosRango = d || []; this.cargando = false; this.cdr.detectChanges(); },
      error: e => { console.error(e); this.errorMensaje = 'No se pudo conectar con el backend o la consulta falló.'; this.cargando = false; this.cdr.detectChanges(); }
    });
  }

  obtenerTotalFacturadoRango(): number {
    return this.datosRango.reduce((acc, f) => acc + (Number(this.getProp(f, 'total_facturado')) || 0), 0);
  }

  obtenerTotalReservasRango(): number {
    return this.datosRango.reduce((acc, f) => acc + (Number(this.getProp(f, 'total_reservas')) || 0), 0);
  }

  // --- Helpers Consulta 6 (Vista Materializada) ---
  obtenerTotalReservasVistaMat(): number {
    return this.datosVistaMat.reduce((acc, f) => acc + (Number(this.getProp(f, 'total_reservas')) || 0), 0);
  }

  // --- Helpers Consulta 7 (UNPIVOT) ---
  obtenerTotalTransaccionesUnpivot(): number {
    return this.datosUnpivot.reduce((acc, f) => acc + (Number(this.getProp(f, 'cantidad_pagos')) || 0), 0);
  }

  obtenerPorcentajeMetodoPago(cantidad: number): number {
    const total = this.obtenerTotalTransaccionesUnpivot();
    if (total === 0) return 0;
    return Math.round((cantidad / total) * 100);
  }

  obtenerIconoMetodo(metodo: string): string {
    const m = (metodo || '').toUpperCase();
    if (m.includes('PSE')) return '💻';
    if (m.includes('TARJETA')) return '💳';
    if (m.includes('TRANSFER')) return '🏦';
    return '💰';
  }

  // --- Helpers Consulta 8 (Consulta de Negocio: 4 tipos) ---
  obtenerIconoTipo(tipo: string): string {
    const t = (tipo || '').toLowerCase();
    if (t.includes('finca')) return '☕';
    if (t.includes('glamping')) return '⛺';
    if (t.includes('hotel')) return '🏨';
    if (t.includes('hostal')) return '🎒';
    return '🏡';
  }

  obtenerTotalIngresosTipos(): number {
    return this.datosServicios.reduce((acc, f) => acc + (Number(this.getProp(f, 'ingresos_totales')) || 0), 0);
  }

  obtenerPorcentajeTipo(ingresos: number): number {
    const total = this.obtenerTotalIngresosTipos();
    if (total === 0) return 0;
    return Math.round((ingresos / total) * 100);
  }
}
