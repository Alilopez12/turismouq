-- ============================================================================
-- PROYECTO INTEGRADOR: TURISMOUQ - BASES DE DATOS II
-- ENTREGA 1: LAS 8 CONSULTAS ANALÍTICAS OBLIGATORIAS
-- MOTOR: ORACLE XE 21c (PDB: XEPDB1)
-- ============================================================================

ALTER SESSION SET CURRENT_SCHEMA = TURISMO_UQ;
SET LINESIZE 250;
SET PAGESIZE 100;

PROMPT ========================================================================
PROMPT CONSULTA 1: Ocupación por municipio y mes con PIVOT (12 meses)
PROMPT ========================================================================
SELECT *
FROM (
    SELECT
        m.nombre AS municipio,
        TO_CHAR(r.fecha_check_in, 'MM') AS mes,
        r.id_reserva
    FROM MUNICIPIO m
    JOIN ALOJAMIENTO a
        ON m.id_municipio = a.id_municipio
    JOIN HABITACION h
        ON a.id_alojamiento = h.id_alojamiento
    JOIN RESERVA_HABITACION rh
        ON h.id_habitacion = rh.id_habitacion
    JOIN RESERVA r
        ON rh.id_reserva = r.id_reserva
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
ORDER BY municipio;


PROMPT ========================================================================
PROMPT CONSULTA 2: Ingresos por municipio, tipo y temporada con ROLLUP y GROUPING
PROMPT ========================================================================
SELECT
    CASE
        WHEN GROUPING(m.nombre) = 1 THEN 'TOTAL GENERAL'
        ELSE m.nombre
    END AS municipio,

    CASE
        WHEN GROUPING(ta.nombre) = 1 THEN 'TOTAL'
        ELSE ta.nombre
    END AS tipo_alojamiento,

    CASE
        WHEN GROUPING(t.nombre) = 1 THEN 'TOTAL'
        ELSE t.nombre
    END AS temporada,

    SUM(r.total) AS ingresos

FROM MUNICIPIO m
JOIN ALOJAMIENTO a
    ON m.id_municipio = a.id_municipio
JOIN TIPO_ALOJAMIENTO ta
    ON a.id_tipo_alojamiento = ta.id_tipo_alojamiento
JOIN HABITACION h
    ON a.id_alojamiento = h.id_alojamiento
JOIN RESERVA_HABITACION rh
    ON h.id_habitacion = rh.id_habitacion
JOIN RESERVA r
    ON rh.id_reserva = r.id_reserva
JOIN (
    SELECT r_sub.id_reserva,
           NVL((SELECT temp.nombre 
                FROM PERIODO_TEMPORADA pt 
                JOIN TEMPORADA temp ON pt.id_temporada = temp.id_temporada
                WHERE r_sub.fecha_check_in BETWEEN pt.fecha_inicio AND pt.fecha_fin
                  AND ROWNUM = 1), 'TEMPORADA BAJA') AS nombre
    FROM RESERVA r_sub
) t ON r.id_reserva = t.id_reserva
GROUP BY ROLLUP (
    m.nombre,
    ta.nombre,
    t.nombre
);


PROMPT ========================================================================
PROMPT CONSULTA 3: Top 3 alojamientos con mayor ingreso por municipio con RANK()
PROMPT ========================================================================
SELECT municipio, alojamiento, ingresos, posicion
FROM (
    SELECT
        m.nombre AS municipio,
        a.nombre AS alojamiento,
        SUM(r.total) AS ingresos,
        RANK() OVER (
            PARTITION BY m.nombre
            ORDER BY SUM(r.total) DESC
        ) AS posicion
    FROM MUNICIPIO m
    JOIN ALOJAMIENTO a
        ON m.id_municipio = a.id_municipio
    JOIN HABITACION h
        ON a.id_alojamiento = h.id_alojamiento
    JOIN RESERVA_HABITACION rh
        ON h.id_habitacion = rh.id_habitacion
    JOIN RESERVA r
        ON rh.id_reserva = r.id_reserva
    GROUP BY m.nombre, a.nombre
)
WHERE posicion <= 3
ORDER BY municipio, posicion;


PROMPT ========================================================================
PROMPT CONSULTA 4: Variación de ingresos mes contra mes con LAG()
PROMPT ========================================================================
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
ORDER BY mes;


PROMPT ========================================================================
PROMPT CONSULTA 5: Consulta parametrizada con variables bind (:fecha_inicio, :fecha_fin)
PROMPT ========================================================================
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
ORDER BY r.fecha_check_in;


PROMPT ========================================================================
PROMPT CONSULTA 6: Vista materializada de ocupación mensual (MV_OCUPACION_MENSUAL)
PROMPT ========================================================================
-- Refresco bajo demanda de la vista
EXEC DBMS_MVIEW.REFRESH('TURISMO_UQ.MV_OCUPACION_MENSUAL', 'C');

SELECT *
FROM MV_OCUPACION_MENSUAL
WHERE ROWNUM <= 24
ORDER BY municipio, mes;


PROMPT ========================================================================
PROMPT CONSULTA 7: Desagregación de métodos de pago con UNPIVOT
PROMPT ========================================================================
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
ORDER BY cantidad_pagos DESC;


PROMPT ========================================================================
PROMPT CONSULTA 8: Consulta libre de negocio - Reservas e ingresos por Tipo
PROMPT ========================================================================
SELECT
    ta.nombre AS tipo_alojamiento,
    COUNT(DISTINCT r.id_reserva) AS total_reservas,
    SUM(r.total) AS ingresos_totales
FROM TIPO_ALOJAMIENTO ta
JOIN ALOJAMIENTO a
    ON ta.id_tipo_alojamiento = a.id_tipo_alojamiento
JOIN HABITACION h
    ON a.id_alojamiento = h.id_alojamiento
JOIN RESERVA_HABITACION rh
    ON h.id_habitacion = rh.id_habitacion
JOIN RESERVA r
    ON rh.id_reserva = r.id_reserva
GROUP BY ta.nombre
ORDER BY ingresos_totales DESC;
