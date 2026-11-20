import { Injectable } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import {
  RespuestaApi,
  Municipio,
  TipoAlojamiento,
  Alojamiento,
  Habitacion,
  Tarifa,
  CotizacionPeticion,
  CotizacionRespuesta,
  ReservaPeticion,
  ReservaRespuesta,
  ReservaItem,
  LiquidacionItem,
  AuditoriaTarifaItem,
  MonitoreoTablespace,
  TransaccionPeticion,
  TransaccionRespuesta,
  CboAnalisisItem,
  SeguridadInfo,
  RecepcionCheckin,
  RecepcionDisponibilidad,
  RecepcionVoucher
} from '../modelos/modelos';

@Injectable({
  providedIn: 'root'
})
export class TurismoService {

  private readonly urlBase = 'http://localhost:8080/api';

  constructor(private http: HttpClient) {}

  obtenerMunicipios(): Observable<Municipio[]> {
    return this.http.get<RespuestaApi<Municipio[]>>(`${this.urlBase}/municipios`)
      .pipe(map(r => r.datos));
  }

  obtenerTiposAlojamiento(): Observable<TipoAlojamiento[]> {
    return this.http.get<RespuestaApi<TipoAlojamiento[]>>(`${this.urlBase}/tipos-alojamiento`)
      .pipe(map(r => r.datos));
  }

  obtenerAlojamientos(idMunicipio?: number, idTipo?: number): Observable<Alojamiento[]> {
    let params = new HttpParams();
    if (idMunicipio) params = params.set('idMunicipio', idMunicipio.toString());
    if (idTipo) params = params.set('idTipoAlojamiento', idTipo.toString());

    return this.http.get<RespuestaApi<Alojamiento[]>>(`${this.urlBase}/alojamientos`, { params })
      .pipe(map(r => r.datos));
  }

  obtenerAlojamientoPorId(id: number): Observable<Alojamiento> {
    return this.http.get<RespuestaApi<Alojamiento>>(`${this.urlBase}/alojamientos/${id}`)
      .pipe(map(r => r.datos));
  }

  obtenerHabitaciones(idAlojamiento: number): Observable<Habitacion[]> {
    return this.http.get<RespuestaApi<Habitacion[]>>(`${this.urlBase}/alojamientos/${idAlojamiento}/habitaciones`)
      .pipe(map(r => r.datos));
  }

  obtenerTarifas(idHabitacion: number): Observable<Tarifa[]> {
    return this.http.get<RespuestaApi<Tarifa[]>>(`${this.urlBase}/habitaciones/${idHabitacion}/tarifas`)
      .pipe(map(r => r.datos));
  }

  cotizarEstadia(peticion: CotizacionPeticion): Observable<CotizacionRespuesta> {
    return this.http.post<RespuestaApi<CotizacionRespuesta>>(`${this.urlBase}/reservas/cotizar`, peticion)
      .pipe(map(r => r.datos));
  }

  crearReserva(peticion: ReservaPeticion): Observable<ReservaRespuesta> {
    return this.http.post<RespuestaApi<ReservaRespuesta>>(`${this.urlBase}/reservas`, peticion)
      .pipe(map(r => r.datos));
  }

  obtenerReservasRecientes(): Observable<ReservaItem[]> {
    return this.http.get<RespuestaApi<ReservaItem[]>>(`${this.urlBase}/reservas/recientes`)
      .pipe(map(r => r.datos));
  }

  ejecutarLiquidacion(mes: number, anio: number, idAlojamiento?: number): Observable<number> {
    return this.http.post<RespuestaApi<number>>(`${this.urlBase}/liquidaciones/ejecutar`, {
      mes,
      anio,
      idAlojamiento: idAlojamiento || null
    }).pipe(map(r => r.datos));
  }

  consultarLiquidaciones(mes?: number, anio?: number): Observable<LiquidacionItem[]> {
    let params = new HttpParams();
    if (mes) params = params.set('mes', mes.toString());
    if (anio) params = params.set('anio', anio.toString());

    return this.http.get<RespuestaApi<LiquidacionItem[]>>(`${this.urlBase}/liquidaciones`, { params })
      .pipe(map(r => r.datos));
  }

  // --- Módulo Analítico (Entrega 1) ---
  obtenerOcupacionPivot(): Observable<any[]> {
    return this.http.get<RespuestaApi<any[]>>(`${this.urlBase}/analitica/ocupacion-pivot`)
      .pipe(map(r => r.datos));
  }

  obtenerIngresosRollup(): Observable<any[]> {
    return this.http.get<RespuestaApi<any[]>>(`${this.urlBase}/analitica/ingresos-rollup`)
      .pipe(map(r => r.datos));
  }

  obtenerTop3Municipio(): Observable<any[]> {
    return this.http.get<RespuestaApi<any[]>>(`${this.urlBase}/analitica/top3-municipio`)
      .pipe(map(r => r.datos));
  }

  obtenerVariacionLag(): Observable<any[]> {
    return this.http.get<RespuestaApi<any[]>>(`${this.urlBase}/analitica/variacion-lag`)
      .pipe(map(r => r.datos));
  }

  obtenerConsultaRango(fechaInicio: string, fechaFin: string): Observable<any[]> {
    const params = new HttpParams()
      .set('fechaInicio', fechaInicio)
      .set('fechaFin', fechaFin);
    return this.http.get<RespuestaApi<any[]>>(`${this.urlBase}/analitica/rango-fechas`, { params })
      .pipe(map(r => r.datos));
  }

  obtenerVistaMaterializada(): Observable<any[]> {
    return this.http.get<RespuestaApi<any[]>>(`${this.urlBase}/analitica/vista-materializada`)
      .pipe(map(r => r.datos));
  }

  obtenerUnpivot(): Observable<any[]> {
    return this.http.get<RespuestaApi<any[]>>(`${this.urlBase}/analitica/unpivot`)
      .pipe(map(r => r.datos));
  }

  obtenerServiciosNegocio(): Observable<any[]> {
    return this.http.get<RespuestaApi<any[]>>(`${this.urlBase}/analitica/servicios-negocio`)
      .pipe(map(r => r.datos));
  }

  obtenerHabitacionTopTemporadaAlta(): Observable<any[]> {
    return this.http.get<RespuestaApi<any[]>>(`${this.urlBase}/analitica/habitacion-top-temporada-alta`)
      .pipe(map(r => r.datos));
  }

  obtenerClientesMasMunicipios(): Observable<any[]> {
    return this.http.get<RespuestaApi<any[]>>(`${this.urlBase}/analitica/clientes-mas-municipios`)
      .pipe(map(r => r.datos));
  }

  obtenerAuditoriaTarifas(): Observable<AuditoriaTarifaItem[]> {
    return this.http.get<RespuestaApi<AuditoriaTarifaItem[]>>(`${this.urlBase}/analitica/auditoria-tarifas`)
      .pipe(map(r => r.datos));
  }

  actualizarTarifa(idHabitacion: number, idTemporada: number, nuevoPrecio: number): Observable<any> {
    return this.http.post<RespuestaApi<any>>(`${this.urlBase}/analitica/actualizar-tarifa`, {
      idHabitacion,
      idTemporada,
      nuevoPrecio
    }).pipe(map(r => r.datos));
  }

  obtenerMonitoreoTablespace(): Observable<MonitoreoTablespace> {
    return this.http.get<RespuestaApi<MonitoreoTablespace>>(`${this.urlBase}/analitica/tablespace`)
      .pipe(map(r => r.datos));
  }

  // --- Módulo Entrega 3 (Transacciones, Concurrencia, Índices CBO y Seguridad) ---
  ejecutarTransaccionSavepoint(peticion: TransaccionPeticion): Observable<TransaccionRespuesta> {
    return this.http.post<RespuestaApi<TransaccionRespuesta>>(`${this.urlBase}/entrega3/transaccion-savepoint`, peticion)
      .pipe(map(r => r.datos));
  }

  obtenerSiguienteDisponibilidadSavepoint(idHabitacion: number): Observable<{
    idHabitacion: number;
    nombreHabitacion: string;
    alojamiento: string;
    capacidadMaxima: number;
    fechaCheckIn: string;
    fechaCheckOut: string;
  }> {
    const params = new HttpParams().set('idHabitacion', idHabitacion.toString());
    return this.http.get<RespuestaApi<any>>(`${this.urlBase}/entrega3/siguiente-disponibilidad`, { params })
      .pipe(map(r => r.datos));
  }

  obtenerPlanesCbo(): Observable<CboAnalisisItem[]> {
    return this.http.get<RespuestaApi<CboAnalisisItem[]>>(`${this.urlBase}/entrega3/planes-cbo`)
      .pipe(map(r => r.datos));
  }

  obtenerSeguridadRoles(): Observable<SeguridadInfo> {
    return this.http.get<RespuestaApi<SeguridadInfo>>(`${this.urlBase}/entrega3/seguridad-roles`)
      .pipe(map(r => r.datos));
  }

  // --- Módulo de Recepción (Vistas de Seguridad Entrega 3) ---
  obtenerCheckinHoy(): Observable<RecepcionCheckin[]> {
    return this.http.get<RespuestaApi<RecepcionCheckin[]>>(`${this.urlBase}/recepcion/checkin-hoy`)
      .pipe(map(r => r.datos));
  }

  obtenerDisponibilidadRecepcion(): Observable<RecepcionDisponibilidad[]> {
    return this.http.get<RespuestaApi<RecepcionDisponibilidad[]>>(`${this.urlBase}/recepcion/disponibilidad`)
      .pipe(map(r => r.datos));
  }

  obtenerVoucherRecepcion(idReserva: number): Observable<RecepcionVoucher> {
    return this.http.get<RespuestaApi<RecepcionVoucher>>(`${this.urlBase}/recepcion/voucher?idReserva=${idReserva}`)
      .pipe(map(r => r.datos));
  }
}
