export interface RespuestaApi<T> {
  exitoso: boolean;
  mensaje: string;
  datos: T;
}

export interface Municipio {
  idMunicipio: number;
  nombre: string;
}

export interface TipoAlojamiento {
  idTipoAlojamiento: number;
  nombre: string;
  descripcion: string;
}

export interface Propietario {
  idPropietario: number;
  documento: string;
  nombres: string;
  telefono: string;
  correo: string;
}

export interface Alojamiento {
  idAlojamiento: number;
  nombre: string;
  direccion: string;
  telefono: string;
  capacidad: number;
  municipio: Municipio;
  tipoAlojamiento: TipoAlojamiento;
  propietario: Propietario;
}

export interface Habitacion {
  idHabitacion: number;
  numeroNombre: string;
  capacidad: number;
  tipoCama: string;
  alojamiento?: Alojamiento;
}

export interface Tarifa {
  idTarifa: number;
  precioNoche: number;
  temporada: {
    idTemporada: number;
    nombre: string;
  };
}

export interface CotizacionPeticion {
  idHabitacion: number;
  fechaCheckIn: string;
  fechaCheckOut: string;
}

export interface CotizacionRespuesta {
  idHabitacion: number;
  fechaCheckIn: string;
  fechaCheckOut: string;
  totalNoches: number;
  totalPagar: number;
  descripcionTemporadas: string;

  // Desglose por temporadas
  nochesTemporadaAlta?: number;
  tarifaNocheAlta?: number;
  subtotalAlta?: number;
  nochesTemporadaBaja?: number;
  tarifaNocheBaja?: number;
  subtotalBaja?: number;
  totalEstimado?: number;
}

export interface ReservaPeticion {
  idCliente?: number;
  idHabitacion: number;
  fechaCheckIn: string;
  fechaCheckOut: string;
  numeroHuespedes: number;
  documentoCliente?: string;
  nombresCliente?: string;
  apellidosCliente?: string;
  telefonoCliente?: string;
  correoCliente?: string;
}

export interface ReservaRespuesta {
  idReserva: number;
  idHabitacion: number;
  nombreAlojamiento: string;
  nombreHabitacion: string;
  nombreCliente: string;
  fechaCheckIn: string;
  fechaCheckOut: string;
  total: number;
  estado: string;
  mensaje: string;
}

export interface ReservaItem {
  idReserva: number;
  fechaCreacion: string;
  fechaCheckIn: string;
  fechaCheckOut: string;
  total: number;
  estado: string;
  cliente: {
    idCliente: number;
    nombres: string;
    apellidos: string;
    documento: string;
  };
}

export interface LiquidacionItem {
  idLiquidacion: number;
  idAlojamiento: number;
  nombreAlojamiento: string;
  municipio: string;
  propietario: string;
  mes: number;
  anio: number;
  totalReservas: number;
  ingresosHospedaje: number;
  ingresosServicios: number;
  totalBruto: number;
  comisionPlataforma: number;
  pagoNetoPropietario: number;
  fechaLiquidacion: string;
}

export interface AuditoriaTarifaItem {
  ID_AUDITORIA: number;
  ID_TARIFA: number;
  ID_HABITACION: number;
  ID_TEMPORADA: number;
  PRECIO_ANTERIOR: number;
  PRECIO_NUEVO: number;
  USUARIO_ORACLE: string;
  FECHA_ACCION: string;
  TIPO_OPERACION: string;
  DETALLE_SENTENCIA: string;
}

export interface ItemTablespace {
  TABLESPACE_NAME: string;
  STATUS: string;
  CONTENTS: string;
  EXTENT_MANAGEMENT: string;
  ALLOCATION_TYPE: string;
  SEGMENT_SPACE_MANAGEMENT: string;
  BYTES_CONSUMIDOS: number;
  MAX_BYTES: number;
}

export interface ItemSegmento {
  SEGMENT_NAME: string;
  SEGMENT_TYPE: string;
  BYTES: number;
  MEGABYTES: number;
  EXTENTS: number;
}

export interface ItemResumenTablespace {
  TABLESPACE_NAME: string;
  NUM_SEGMENTOS: number;
  TOTAL_BYTES: number;
  TOTAL_MEGABYTES: number;
  TOTAL_EXTENTS: number;
}

export interface ItemTablaTablespace {
  TABLE_NAME: string;
  TABLESPACE_NAME: string;
  NUM_ROWS: number;
}

export interface DatafileInfo {
  tablespaceName: string;
  datafile: string;
  tamanoInicialMb: number;
  incrementoMb: number;
  tamanoMaximoMb: number;
  gestionExtensiones: string;
  gestionEspacio: string;
  politicaBackup: string;
  aislamiento: string;
}

export interface MonitoreoTablespace {
  tablespaces: ItemTablespace[];
  segmentosHistorico: ItemSegmento[];
  resumenPorTablespace: ItemResumenTablespace[];
  tablasPorTablespace: ItemTablaTablespace[];
  datafileInfo: DatafileInfo;
  scriptDdl: string;
}

// ============================================================================
// MODELOS PARA ENTREGA 3 (Transacciones, Concurrencia, CBO y Seguridad)
// ============================================================================
export interface TransaccionPeticion {
  idCliente?: number;
  idHabitacion: number;
  fechaCheckIn: string;
  fechaCheckOut: string;
  numeroHuespedes: number;
  metodoPago: string;
  simularFallo: boolean;
}

export interface TransaccionRespuesta {
  idReserva: number;
  idPago?: number;
  total: number;
  saldoPendiente?: number;
  exito?: boolean;
  estadoReserva: string;
  mensaje: string;
  rollbackParcial: boolean;
}

export interface CboAnalisisItem {
  id: string;
  titulo: string;
  consultaSql: string;
  tipoIndice: string;
  ddlIndice: string;
  costoAntes: string;
  costoDespues: string;
  planAntes: string;
  planDespues: string;
  explicacion: string;
  casoNegativo: boolean;
}

export interface SeguridadInfo {
  perfilSesion: { [key: string]: string };
  roles: Array<{
    rol: string;
    descripcion: string;
    vistasAsignadas?: string[];
    tablasBase?: string;
    privilegios?: string;
    paquete?: string;
  }>;
  vistasRecepcion: Array<{
    vista: string;
    proposito: string;
  }>;
  reglaOroRecepcion: string;
}

// ============================================================================
// MODELOS PARA AUTENTICACIÓN, LOGIN Y RECEPCIÓN
// ============================================================================
export interface LoginPeticion {
  usuario: string;
  nombreUsuario?: string;
  contrasena: string;
}

export interface RegistroPeticion {
  usuario: string;
  nombreUsuario?: string;
  contrasena: string;
  nombreCompleto: string;
  correo: string;
  rol: string;
}

export interface LoginRespuesta {
  usuario: string;
  nombreUsuario?: string;
  nombreCompleto: string;
  correo: string;
  rol: string;
  descripcionRol: string;
  rolDesc?: string;
  rutasPermitidas: string[];
}

export interface RecepcionCheckin {
  idReserva: number;
  documentoHuesped: string;
  nombreHuesped: string;
  nombreCliente?: string;
  telefonoContacto: string;
  telefono?: string;
  alojamiento: string;
  municipio: string;
  habitacion: string;
  fechaCheckIn: string;
  fechaCheckOut: string;
  totalNoches: number;
  estado: string;
  estadoPago?: string;
  saldoPendiente?: number;
  adultos?: number;
  ninos?: number;
}

export interface RecepcionDisponibilidad {
  idHabitacion: number;
  habitacion: string;
  tipoCama: string;
  tipoHabitacion?: string;
  aforoMaximo: number;
  capacidad?: number;
  tarifaBase?: number;
  piso?: number;
  idAlojamiento: number;
  alojamiento: string;
  municipio: string;
  telefonoAlojamiento: string;
}

export interface RecepcionVoucher {
  idReserva: number;
  fechaCreacion: string;
  fechaRegistro?: string;
  documentoCliente: string;
  identificacionCliente?: string;
  clienteTitular: string;
  nombreCliente?: string;
  correoCliente?: string;
  telefonoCliente?: string;
  alojamiento: string;
  tipoHabitacion?: string;
  direccion: string;
  municipio: string;
  habitacion: string;
  fechaCheckIn: string;
  fechaCheckOut: string;
  noches?: number;
  adultos?: number;
  ninos?: number;
  totalFacturado: number;
  montoPagado?: number;
  saldoPendiente?: number;
  estadoReserva: string;
}
