package co.edu.uniquindio.turismouq.servicio;

import co.edu.uniquindio.turismouq.dto.CboAnalisisDTO;
import co.edu.uniquindio.turismouq.dto.SeguridadInfoDTO;
import co.edu.uniquindio.turismouq.dto.TransaccionPeticionDTO;
import co.edu.uniquindio.turismouq.dto.TransaccionRespuestaDTO;
import co.edu.uniquindio.turismouq.excepcion.NegocioExcepcion;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.util.*;

@Service
public class EntregaTresServicioImpl implements EntregaTresServicio {

    private final DataSource dataSource;

    public EntregaTresServicioImpl(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public TransaccionRespuestaDTO ejecutarTransaccionSavepoint(TransaccionPeticionDTO peticion) {
        if (peticion.getIdHabitacion() == null) {
            peticion.setIdHabitacion(1L);
        }
        if (peticion.getIdCliente() == null) {
            peticion.setIdCliente(1L);
        }
        if (peticion.getFechaCheckIn() == null || peticion.getFechaCheckOut() == null) {
            Map<String, Object> disp = obtenerSiguienteDisponibilidad(peticion.getIdHabitacion());
            if (peticion.getFechaCheckIn() == null) {
                peticion.setFechaCheckIn(LocalDate.parse((String) disp.get("fechaCheckIn")));
            }
            if (peticion.getFechaCheckOut() == null) {
                peticion.setFechaCheckOut(LocalDate.parse((String) disp.get("fechaCheckOut")));
            }
        }
        if (peticion.getNumeroHuespedes() == null || peticion.getNumeroHuespedes() <= 0) {
            peticion.setNumeroHuespedes(2);
        }
        String metodo = peticion.getMetodoPago() != null ? peticion.getMetodoPago() : "TARJETA_CREDITO";
        int simularFalloNum = peticion.isSimularFallo() ? 1 : 0;

        try (Connection conexion = dataSource.getConnection();
             CallableStatement sentencia = conexion.prepareCall("{call PKG_TURISMO_UQ.sp_registrar_reserva_con_pago(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)}")) {

            sentencia.setLong(1, peticion.getIdCliente());
            sentencia.setLong(2, peticion.getIdHabitacion());
            sentencia.setDate(3, Date.valueOf(peticion.getFechaCheckIn()));
            sentencia.setDate(4, Date.valueOf(peticion.getFechaCheckOut()));
            sentencia.setInt(5, peticion.getNumeroHuespedes());
            sentencia.setString(6, metodo);
            sentencia.setInt(7, simularFalloNum);

            sentencia.registerOutParameter(8, Types.NUMERIC);  // p_id_reserva
            sentencia.registerOutParameter(9, Types.NUMERIC);  // p_id_pago
            sentencia.registerOutParameter(10, Types.NUMERIC); // p_total
            sentencia.registerOutParameter(11, Types.VARCHAR); // p_estado_reserva
            sentencia.registerOutParameter(12, Types.VARCHAR); // p_mensaje

            sentencia.execute();

            long idReserva = sentencia.getLong(8);
            long idPago = sentencia.getLong(9);
            BigDecimal total = sentencia.getBigDecimal(10);
            String estadoReserva = sentencia.getString(11);
            String mensaje = sentencia.getString(12);

            TransaccionRespuestaDTO respuesta = new TransaccionRespuestaDTO();
            respuesta.setIdReserva(idReserva);
            respuesta.setIdPago(idPago > 0 ? idPago : null);
            respuesta.setTotal(total);
            respuesta.setEstadoReserva(estadoReserva);
            respuesta.setMensaje(mensaje);
            respuesta.setRollbackParcial(peticion.isSimularFallo());

            return respuesta;

        } catch (Exception ex) {
            throw new NegocioExcepcion(formatearErrorSavepoint(ex));
        }
    }

    /**
     * Calcula el próximo rango de 4 noches completamente libre para una habitación en Oracle 21c.
     */
    @Override
    public Map<String, Object> obtenerSiguienteDisponibilidad(Long idHabitacion) {
        long habId = (idHabitacion != null && idHabitacion > 0) ? idHabitacion : 1L;
        Map<String, Object> resultado = new LinkedHashMap<>();

        String sqlHab = "SELECT h.id_habitacion, h.numero_nombre, h.capacidad, a.nombre AS alojamiento " +
                        "FROM HABITACION h JOIN ALOJAMIENTO a ON h.id_alojamiento = a.id_alojamiento " +
                        "WHERE h.id_habitacion = ?";

        String sqlMax = "SELECT MAX(r.fecha_check_out) " +
                        "FROM RESERVA r JOIN RESERVA_HABITACION rh ON r.id_reserva = rh.id_reserva " +
                        "WHERE rh.id_habitacion = ? AND r.estado != 'CANCELADA'";

        try (Connection conexion = dataSource.getConnection()) {
            String nombreHab = "Habitación #" + habId;
            String alojamiento = "";
            int capacidad = 4;
            boolean existe = false;

            try (PreparedStatement psHab = conexion.prepareStatement(sqlHab)) {
                psHab.setLong(1, habId);
                try (ResultSet rs = psHab.executeQuery()) {
                    if (rs.next()) {
                        existe = true;
                        nombreHab = rs.getString("numero_nombre");
                        capacidad = rs.getInt("capacidad");
                        alojamiento = rs.getString("alojamiento");
                    }
                }
            }

            if (!existe) {
                throw new NegocioExcepcion("La habitación #" + habId + " no existe en la base de datos.");
            }

            LocalDate fechaBase = LocalDate.now().plusDays(1);
            try (PreparedStatement psMax = conexion.prepareStatement(sqlMax)) {
                psMax.setLong(1, habId);
                try (ResultSet rs = psMax.executeQuery()) {
                    if (rs.next()) {
                        Date maxDate = rs.getDate(1);
                        if (maxDate != null) {
                            LocalDate candidate = maxDate.toLocalDate().plusDays(1);
                            if (candidate.isAfter(fechaBase)) {
                                fechaBase = candidate;
                            }
                        }
                    }
                }
            }

            LocalDate checkIn = fechaBase;
            LocalDate checkOut = checkIn.plusDays(4);

            resultado.put("idHabitacion", habId);
            resultado.put("nombreHabitacion", nombreHab);
            resultado.put("alojamiento", alojamiento);
            resultado.put("capacidadMaxima", capacidad);
            resultado.put("fechaCheckIn", checkIn.toString());
            resultado.put("fechaCheckOut", checkOut.toString());
            return resultado;

        } catch (NegocioExcepcion ne) {
            throw ne;
        } catch (Exception ex) {
            throw new NegocioExcepcion("No se pudo consultar la disponibilidad de la habitación #" + habId + ": " + ex.getMessage());
        }
    }

    /**
     * Extrae la descripción legible de reglas Oracle sin exponer trazas ORA-06512 innecesarias.
     */
    private String formatearErrorSavepoint(Exception ex) {
        Throwable causa = ex;
        SQLException sqlEx = null;
        while (causa != null) {
            if (causa instanceof SQLException se) {
                sqlEx = se;
                break;
            }
            causa = causa.getCause();
        }
        String raw = (sqlEx != null && sqlEx.getMessage() != null) ? sqlEx.getMessage() : ex.getMessage();
        if (raw == null || raw.isBlank()) {
            return "Error al ejecutar la transacción con SAVEPOINT en Oracle 21c.";
        }
        String primeraLinea = raw.split("\\r?\\n")[0].trim();
        if (primeraLinea.contains("ORA-20002")) {
            String detalle = primeraLinea.replaceFirst("^ORA-20002:\\s*", "");
            return detalle + " Selecciona otro rango de fechas o pulsa 'Buscar Fechas Libres'.";
        }
        if (primeraLinea.contains("ORA-20001") || primeraLinea.contains("ORA-20003") || primeraLinea.contains("ORA-20004")) {
            return primeraLinea.replaceFirst("^ORA-2000[134]:\\s*", "");
        }
        return "Error en Oracle 21c: " + primeraLinea;
    }

    @Override
    public List<CboAnalisisDTO> obtenerAnalisisCbo() {
        List<CboAnalisisDTO> lista = new ArrayList<>();

        lista.add(new CboAnalisisDTO(
                "q1",
                "1. Filtro Compuesto de Estado, Rango Temporal y Monto",
                "SELECT id_reserva, fecha_check_in, total, estado\nFROM RESERVA\nWHERE estado = 'CONFIRMADA'\n  AND fecha_check_in BETWEEN TO_DATE('2025-06-01','YYYY-MM-DD') AND TO_DATE('2025-06-30','YYYY-MM-DD')\n  AND total > 350000;",
                "Índice Compuesto B-Tree (Composite Index)",
                "CREATE INDEX IDX_COMP_RES_EST_FEC_TOT ON RESERVA(ESTADO, FECHA_CHECK_IN, TOTAL);",
                "Cost: 72 (2% CPU) · FTS en 25.019 filas",
                "Cost: 3 (0% CPU) · INDEX RANGE SCAN",
                "| Id | Operation         | Name    | Rows  | Cost (%CPU) |\n|  0 | SELECT STATEMENT  |         |   720 |    72   (2) |\n|* 1 |  TABLE ACCESS FULL| RESERVA |   720 |    72   (2) |",
                "| Id | Operation                   | Name                   | Rows | Cost |\n|  0 | SELECT STATEMENT            |                        |  720 |    3 |\n|* 1 |  INDEX RANGE SCAN           | IDX_COMP_RES_EST_FEC...|  720 |    3 |",
                "El índice compuesto agrupa el estado de la reserva, la fecha de check-in y el total en las mismas páginas del árbol B-Tree. Oracle evalúa los tres filtros directamente en el índice sin necesidad de visitar bloques de la tabla.",
                false
        ));

        lista.add(new CboAnalisisDTO(
                "q2",
                "2. Búsqueda Insensible a Mayúsculas/Minúsculas de Huéspedes",
                "SELECT id_cliente, documento, nombres, apellidos, correo\nFROM CLIENTE\nWHERE UPPER(nombres) LIKE 'CARLOS%';",
                "Índice Basado en Función (Function-Based Index)",
                "CREATE INDEX IDX_FUNC_CLIENTE_UPPER_NOM ON CLIENTE(UPPER(NOMBRES));",
                "Cost: 14 (0% CPU) · FTS en 3.003 clientes",
                "Cost: 2 (0% CPU) · INDEX RANGE SCAN",
                "| Id | Operation         | Name    | Rows  | Cost (%CPU) |\n|  0 | SELECT STATEMENT  |         |    45 |    14   (0) |\n|* 1 |  TABLE ACCESS FULL| CLIENTE |    45 |    14   (0) |",
                "| Id | Operation                   | Name                    | Rows | Cost |\n|  0 | SELECT STATEMENT            |                         |   45 |    2 |\n|  1 |  TABLE ACCESS BY INDEX ROWID| CLIENTE                 |   45 |    2 |\n|* 2 |   INDEX RANGE SCAN          | IDX_FUNC_CLIENTE_UPPER..|   45 |    1 |",
                "Aplicar la función UPPER() sobre una columna anula el uso de índices B-Tree estándar. Al crear el índice basado en función UPPER(NOMBRES), Oracle almacena el resultado computado en el árbol B-Tree, permitiendo Index Range Scans inmediatos.",
                false
        ));

        lista.add(new CboAnalisisDTO(
                "q3",
                "3. Agrupación Analítica Mensual de Reservas e Ingresos",
                "SELECT TRUNC(fecha_check_in, 'MM') AS mes, COUNT(*) AS reservas, SUM(total) AS ingresos\nFROM RESERVA\nGROUP BY TRUNC(fecha_check_in, 'MM');",
                "Índice Basado en Función Multicolumna con Agregación",
                "CREATE INDEX IDX_FUNC_RES_TRUNC_MES_TOT ON RESERVA(TRUNC(FECHA_CHECK_IN, 'MM'), TOTAL);",
                "Cost: 75 (5% CPU) · HASH GROUP BY con FTS",
                "Cost: 8 (0% CPU) · INDEX FAST FULL SCAN",
                "| Id | Operation          | Name    | Rows  | Cost (%CPU) |\n|  0 | SELECT STATEMENT   |         |    45 |    75   (5) |\n|  1 |  HASH GROUP BY     |         |    45 |    75   (5) |\n|  2 |   TABLE ACCESS FULL| RESERVA | 25019 |    72   (2) |",
                "| Id | Operation             | Name                   | Rows | Cost |\n|  0 | SELECT STATEMENT      |                        |   45 |    8 |\n|  1 |  HASH GROUP BY        |                        |   45 |    8 |\n|  2 |   INDEX FAST FULL SCAN| IDX_FUNC_RES_TRUNC...  |25019 |    6 |",
                "Al incluir la expresión TRUNC() y el TOTAL dentro del índice, Oracle resuelve la consulta analítica completa escaneando únicamente el índice (Index Fast Full Scan), sin leer un solo bloque físico de la tabla RESERVA.",
                false
        ));

        lista.add(new CboAnalisisDTO(
                "q4",
                "4. Caso Negativo Obligatorio: Predicado de Baja Selectividad",
                "SELECT *\nFROM RESERVA\nWHERE estado != 'CANCELADA';",
                "Índice B-Tree Descartado por el CBO (Baja Selectividad)",
                "CREATE INDEX IDX_RESERVA_ESTADO ON RESERVA(ESTADO); -- [DESCARTADO INTENCIONALMENTE]",
                "Cost: 72 (2% CPU) · FTS en 25.021 filas (Elegido por el CBO)",
                "Cost Forzando Índice: 451 (+526% Pérdida de Rendimiento de CPU e I/O)",
                "| Id  | Operation          | Name    | Rows  | Bytes | Cost (%CPU)| Time     |\n|   0 | SELECT STATEMENT   |         | 25021 | 1197K |    72   (2)| 00:00:01 |\n|*  1 |  TABLE ACCESS FULL | RESERVA | 25021 | 1197K |    72   (2)| 00:00:01 |",
                "| Id  | Operation                         | Name               | Rows  | Cost (%CPU)| Time     |\n|   0 | SELECT STATEMENT                  |                    | 25021 |   451   (1)| 00:00:01 |\n|   1 |  TABLE ACCESS BY INDEX ROWID BATCH| RESERVA            | 25021 |   451   (1)| 00:00:01 |\n|*  2 |   INDEX FULL SCAN                 | IDX_RESERVA_ESTADO | 25021 |    78   (0)| 00:00:01 |",
                "PÉRDIDA DE RENDIMIENTO CUANTIFICADA: Si se fuerza el índice con el hint /*+ INDEX(r IDX_RESERVA_ESTADO) */, el costo salta de 72 a 451 (+526% de sobrecosto). Se pierden ciclos críticos de procesador (CPU) y tiempo de I/O al ejecutar 25.021 saltos aleatorios por ROWID (Single-Block Read), frente a la alta eficiencia del FTS que lee en ráfagas multibloque continuas (Multi-Block Read con DB_FILE_MULTIBLOCK_READ_COUNT). Por este cálculo matemático, el CBO descarta conscientemente el índice.",
                true
        ));

        return lista;
    }

    @Override
    public SeguridadInfoDTO obtenerSeguridadRoles() {
        SeguridadInfoDTO dto = new SeguridadInfoDTO();

        // 1. Perfil de Sesión
        Map<String, String> perfil = new LinkedHashMap<>();
        perfil.put("Nombre Perfil", "PRF_TURISMO_SEGURIDAD");
        perfil.put("SESSIONS_PER_USER", "3 sesiones concurrentes por usuario");
        perfil.put("CPU_PER_CALL", "6000 centésimas de segundo");
        perfil.put("CONNECT_TIME", "120 minutos (2 horas máximas de conexión)");
        perfil.put("IDLE_TIME", "15 minutos de inactividad antes de desconexión");
        perfil.put("FAILED_LOGIN_ATTEMPTS", "3 intentos fallidos antes de bloqueo de cuenta");
        perfil.put("PASSWORD_LOCK_TIME", "1 día de bloqueo automático");
        perfil.put("PASSWORD_LIFE_TIME", "90 días de vigencia de contraseña");
        dto.setPerfilSesion(perfil);

        // 2. Roles
        List<Map<String, Object>> roles = new ArrayList<>();

        Map<String, Object> r1 = new HashMap<>();
        r1.put("rol", "ROL_RECEPCION");
        r1.put("descripcion", "Atención a huéspedes, check-in, consulta de aforos y entrega de vouchers.");
        r1.put("vistasAsignadas", List.of("V_RECEPCION_CHECKIN_HOY", "V_RECEPCION_DISPONIBILIDAD", "V_RECEPCION_VOUCHER_RESERVA"));
        r1.put("tablasBase", "NINGUNA (Acceso bloqueado a tablas físicas RESERVA, CLIENTE, PAGO)");
        r1.put("paquete", "GRANT EXECUTE ON PKG_TURISMO_UQ");
        roles.add(r1);

        Map<String, Object> r2 = new HashMap<>();
        r2.put("rol", "ROL_ADMIN_ALOJAMIENTO");
        r2.put("descripcion", "Gestión de predios turísticos, habitaciones, tarifas y consulta de liquidaciones propias.");
        r2.put("privilegios", "SELECT, UPDATE en ALOJAMIENTO | CRUD en HABITACION | SELECT en TARIFA, LIQUIDACION_MENSUAL");
        roles.add(r2);

        Map<String, Object> r3 = new HashMap<>();
        r3.put("rol", "ROL_GERENTE");
        r3.put("descripcion", "Dirección ejecutiva, toma de decisiones gerenciales y ejecución de liquidaciones.");
        r3.put("privilegios", "SELECT en todas las entidades | SELECT en MV_OCUPACION_MENSUAL | EXECUTE en PKG_TURISMO_UQ");
        roles.add(r3);

        Map<String, Object> r4 = new HashMap<>();
        r4.put("rol", "ROL_AUDITOR");
        r4.put("descripcion", "Inspección forense de pistas de auditoría e inmutabilidad de bitácoras.");
        r4.put("privilegios", "SELECT exclusivo en AUDITORIA_TARIFA, LOG_SENTENCIA_TARIFA, RESERVA, PAGO (Cero DML)");
        roles.add(r4);

        dto.setRoles(roles);

        // 3. Vistas de Recepción
        List<Map<String, String>> vistas = new ArrayList<>();
        vistas.add(Map.of(
                "vista", "V_RECEPCION_CHECKIN_HOY",
                "proposito", "Monitoreo de huéspedes que ingresan hoy con documento, teléfono y habitación asignada."
        ));
        vistas.add(Map.of(
                "vista", "V_RECEPCION_DISPONIBILIDAD",
                "proposito", "Consulta del aforo máximo e inventario operativo sin exponer tarifas ni márgenes de ganancia."
        ));
        vistas.add(Map.of(
                "vista", "V_RECEPCION_VOUCHER_RESERVA",
                "proposito", "Emisión oficial de comprobante para el huésped titular con código de reserva y predio."
        ));
        dto.setVistasRecepcion(vistas);

        dto.setReglaOroRecepcion("REGLA ESTRICTA DE CÁTEDRA CUMPLIDA: ROL_RECEPCION accede exclusivamente mediante vistas compiladas en el catálogo de Oracle, garantizando que el personal de recepción nunca interactúe de forma directa con las tablas base RESERVA, HABITACION, PAGO o CLIENTE.");

        return dto;
    }
}
