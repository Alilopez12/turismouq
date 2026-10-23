package co.edu.uniquindio.turismouq.servicio;

import co.edu.uniquindio.turismouq.entidad.AuditoriaTarifa;
import co.edu.uniquindio.turismouq.repositorio.AuditoriaTarifaRepositorio;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
@Transactional(readOnly = true)
public class AnaliticaServicioImpl implements AnaliticaServicio {

    private final JdbcTemplate jdbcTemplate;
    private final AuditoriaTarifaRepositorio auditoriaTarifaRepositorio;

    public AnaliticaServicioImpl(JdbcTemplate jdbcTemplate, AuditoriaTarifaRepositorio auditoriaTarifaRepositorio) {
        this.jdbcTemplate = jdbcTemplate;
        this.auditoriaTarifaRepositorio = auditoriaTarifaRepositorio;
    }

    @Override
    public List<Map<String, Object>> obtenerOcupacionPivot() {
        String sql = """
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
                    '01' AS ENERO,
                    '02' AS FEBRERO,
                    '03' AS MARZO,
                    '04' AS ABRIL,
                    '05' AS MAYO,
                    '06' AS JUNIO,
                    '07' AS JULIO,
                    '08' AS AGOSTO,
                    '09' AS SEPTIEMBRE,
                    '10' AS OCTUBRE,
                    '11' AS NOVIEMBRE,
                    '12' AS DICIEMBRE
                )
            )
            ORDER BY municipio
        """;
        return jdbcTemplate.queryForList(sql);
    }

    @Override
    public List<Map<String, Object>> obtenerIngresosRollup() {
        String sql = """
            SELECT 
                CASE WHEN GROUPING(m.nombre) = 1 THEN 'TOTAL QUINDIO' ELSE m.nombre END AS municipio,
                CASE WHEN GROUPING(ta.nombre) = 1 THEN 'Todos los Tipos' ELSE ta.nombre END AS tipo_alojamiento,
                CASE WHEN GROUPING(t.nombre) = 1 THEN 'Todas las Temporadas' ELSE t.nombre END AS temporada,
                GROUPING(m.nombre) AS agrupado_municipio,
                GROUPING(ta.nombre) AS agrupado_tipo,
                GROUPING(t.nombre) AS agrupado_temporada,
                COUNT(DISTINCT r.id_reserva) AS cantidad_reservas,
                SUM(r.total) AS total_ingresos
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
            GROUP BY ROLLUP(m.nombre, ta.nombre, t.nombre)
            ORDER BY GROUPING(m.nombre), m.nombre, GROUPING(ta.nombre), ta.nombre, GROUPING(t.nombre)
        """;
        return jdbcTemplate.queryForList(sql);
    }

    @Override
    public List<Map<String, Object>> obtenerTop3PorMunicipio() {
        String sql = """
            SELECT 
                municipio,
                nombre_alojamiento,
                tipo_alojamiento,
                total_ingresos,
                posicion_ranking
            FROM (
                SELECT 
                    m.nombre AS municipio,
                    a.nombre AS nombre_alojamiento,
                    ta.nombre AS tipo_alojamiento,
                    NVL(SUM(r.total), 0) AS total_ingresos,
                    RANK() OVER (PARTITION BY m.nombre ORDER BY NVL(SUM(r.total), 0) DESC) AS posicion_ranking
                FROM MUNICIPIO m
                JOIN ALOJAMIENTO a ON m.id_municipio = a.id_municipio
                JOIN TIPO_ALOJAMIENTO ta ON a.id_tipo_alojamiento = ta.id_tipo_alojamiento
                JOIN HABITACION h ON a.id_alojamiento = h.id_alojamiento
                JOIN RESERVA_HABITACION rh ON h.id_habitacion = rh.id_habitacion
                JOIN RESERVA r ON rh.id_reserva = r.id_reserva
                GROUP BY m.nombre, a.nombre, ta.nombre
            )
            WHERE posicion_ranking <= 3
            ORDER BY municipio, posicion_ranking
        """;
        return jdbcTemplate.queryForList(sql);
    }

    @Override
    public List<Map<String, Object>> obtenerVariacionLag() {
        String sql = """
            SELECT 
                mes,
                total_ingresos,
                ingresos_mes_anterior,
                (total_ingresos - NVL(ingresos_mes_anterior, total_ingresos)) AS variacion_absoluta,
                ROUND(
                    CASE 
                        WHEN ingresos_mes_anterior IS NULL OR ingresos_mes_anterior = 0 THEN 0
                        ELSE ((total_ingresos - ingresos_mes_anterior) / ingresos_mes_anterior) * 100
                    END, 2
                ) AS variacion_porcentual
            FROM (
                SELECT 
                    TO_CHAR(TRUNC(r.fecha_check_in, 'MM'), 'YYYY-MM') AS mes,
                    SUM(r.total) AS total_ingresos,
                    LAG(SUM(r.total), 1) OVER (ORDER BY TRUNC(r.fecha_check_in, 'MM')) AS ingresos_mes_anterior
                FROM RESERVA r
                GROUP BY TRUNC(r.fecha_check_in, 'MM')
            )
            ORDER BY mes
        """;
        return jdbcTemplate.queryForList(sql);
    }

    @Override
    public List<Map<String, Object>> obtenerConsultaParametrizada(String fechaInicio, String fechaFin) {
        String fIni = (fechaInicio != null && !fechaInicio.isBlank()) ? fechaInicio : "2025-06-01";
        String fFin = (fechaFin != null && !fechaFin.isBlank()) ? fechaFin : "2025-08-31";

        String sql = """
            SELECT 
                m.nombre AS municipio,
                COUNT(DISTINCT r.id_reserva) AS total_reservas,
                COUNT(DISTINCT r.id_cliente) AS total_clientes,
                SUM(r.total) AS total_facturado,
                ROUND(AVG(r.total), 2) AS promedio_reserva
            FROM MUNICIPIO m
            JOIN ALOJAMIENTO a ON m.id_municipio = a.id_municipio
            JOIN HABITACION h ON a.id_alojamiento = h.id_alojamiento
            JOIN RESERVA_HABITACION rh ON h.id_habitacion = rh.id_habitacion
            JOIN RESERVA r ON rh.id_reserva = r.id_reserva
            WHERE r.fecha_check_in BETWEEN TO_DATE(?, 'YYYY-MM-DD') AND TO_DATE(?, 'YYYY-MM-DD')
            GROUP BY m.nombre
            ORDER BY total_facturado DESC
        """;
        return jdbcTemplate.queryForList(sql, fIni, fFin);
    }

    @Override
    public List<Map<String, Object>> obtenerVistaMaterializadaOcupacion() {
        String sql = """
            SELECT 
                municipio,
                anio_mes AS periodo_mes,
                total_reservas
            FROM MV_OCUPACION_MENSUAL
            WHERE anio_mes >= '2025-01'
            ORDER BY anio_mes DESC, total_reservas DESC
        """;
        return jdbcTemplate.queryForList(sql);
    }

    @Override
    public List<Map<String, Object>> obtenerConsultaUnpivot() {
        String sql = """
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
            ORDER BY cantidad_pagos DESC
        """;
        return jdbcTemplate.queryForList(sql);
    }

    @Override
    public List<Map<String, Object>> obtenerServiciosNegocioLibre() {
        String sql = """
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
            ORDER BY ingresos_totales DESC
        """;
        return jdbcTemplate.queryForList(sql);
    }

    @Override
    public List<Map<String, Object>> obtenerAuditoriaTarifas() {
        String sql = """
            SELECT 
                id_auditoria,
                id_tarifa,
                id_habitacion,
                id_temporada,
                precio_anterior,
                precio_nuevo,
                usuario AS usuario_oracle,
                TO_CHAR(fecha, 'YYYY-MM-DD HH24:MI:SS') AS fecha_accion,
                accion AS tipo_operacion,
                'Disparador TRG_AUDITORIA_TARIFA' AS detalle_sentencia
            FROM AUDITORIA_TARIFA
            ORDER BY id_auditoria DESC
            FETCH FIRST 50 ROWS ONLY
        """;
        return jdbcTemplate.queryForList(sql);
    }

    @Override
    public Map<String, Object> obtenerMonitoreoTablespace() {
        Map<String, Object> resultado = new java.util.LinkedHashMap<>();

        // 1. Tablespaces y Cuotas
        String sqlTablespaces = """
            SELECT 
                t.tablespace_name, 
                t.status, 
                t.contents, 
                t.extent_management, 
                t.allocation_type, 
                t.segment_space_management, 
                NVL(q.bytes, 0) AS bytes_consumidos, 
                NVL(q.max_bytes, -1) AS max_bytes 
            FROM user_tablespaces t 
            LEFT JOIN user_ts_quotas q ON t.tablespace_name = q.tablespace_name 
            ORDER BY t.tablespace_name
        """;
        resultado.put("tablespaces", jdbcTemplate.queryForList(sqlTablespaces));

        // 2. Segmentos físicos en TBS_HISTORICO_RESERVAS
        String sqlSegmentosHistorico = """
            SELECT 
                segment_name, 
                segment_type, 
                bytes, 
                ROUND(bytes / (1024 * 1024), 2) AS megabytes, 
                extents 
            FROM user_segments 
            WHERE tablespace_name = 'TBS_HISTORICO_RESERVAS' 
            ORDER BY bytes DESC
        """;
        resultado.put("segmentosHistorico", jdbcTemplate.queryForList(sqlSegmentosHistorico));

        // 3. Resumen agregado por Tablespace
        String sqlResumen = """
            SELECT 
                tablespace_name, 
                COUNT(*) AS num_segmentos, 
                SUM(bytes) AS total_bytes, 
                ROUND(SUM(bytes) / (1024 * 1024), 2) AS total_megabytes, 
                SUM(extents) AS total_extents 
            FROM user_segments 
            GROUP BY tablespace_name
            ORDER BY total_bytes DESC
        """;
        resultado.put("resumenPorTablespace", jdbcTemplate.queryForList(sqlResumen));

        // 4. Tablas por Tablespace y conteo de filas
        String sqlTablas = """
            SELECT 
                table_name, 
                tablespace_name, 
                NVL(num_rows, 0) AS num_rows 
            FROM user_tables 
            ORDER BY tablespace_name DESC, table_name ASC
        """;
        resultado.put("tablasPorTablespace", jdbcTemplate.queryForList(sqlTablas));

        // 5. Metadatos de Datafile y Configuración Física
        Map<String, Object> datafileInfo = new java.util.LinkedHashMap<>();
        datafileInfo.put("tablespaceName", "TBS_HISTORICO_RESERVAS");
        datafileInfo.put("datafile", "C:\\APP\\DELL\\PRODUCT\\21C\\ORADATA\\XE\\XEPDB1\\TBS_HISTORICO_RESERVAS01.DBF");
        datafileInfo.put("tamanoInicialMb", 50);
        datafileInfo.put("incrementoMb", 10);
        datafileInfo.put("tamanoMaximoMb", 2048);
        datafileInfo.put("gestionExtensiones", "LOCAL");
        datafileInfo.put("gestionEspacio", "AUTO (ASSM)");
        datafileInfo.put("politicaBackup", "Apto para modo READ ONLY en vigencias cerradas");
        datafileInfo.put("aislamiento", "Aislamiento total de I/O frente al tablespace transaccional USERS");
        resultado.put("datafileInfo", datafileInfo);

        // 6. Script DDL Oficial
        String ddl = """
-- ============================================================================
-- SCRIPT DDL: CREACIÓN DE TABLESPACE TBS_HISTORICO_RESERVAS (ORACLE 21c)
-- ============================================================================
CREATE TABLESPACE TBS_HISTORICO_RESERVAS
DATAFILE 'C:\\APP\\DELL\\PRODUCT\\21C\\ORADATA\\XE\\XEPDB1\\TBS_HISTORICO_RESERVAS01.DBF'
SIZE 50M
AUTOEXTEND ON NEXT 10M MAXSIZE 2G
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;

-- Otorgar cuota ilimitada al usuario de la aplicación
ALTER USER TURISMO_UQ QUOTA UNLIMITED ON TBS_HISTORICO_RESERVAS;
        """.trim();
        resultado.put("scriptDdl", ddl);

        return resultado;
    }
}
