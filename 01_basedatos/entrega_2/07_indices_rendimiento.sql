-- ============================================================================
-- PROYECTO INTEGRADOR: TURISMOUQ - BASES DE DATOS II
-- SCRIPT 07: ÍNDICES B-TREE DE OPTIMIZACIÓN Y RENDIMIENTO
-- MOTOR: ORACLE XE 21c (PDB: XEPDB1)
-- ============================================================================
-- JUSTIFICACIÓN DE RENDIMIENTO:
-- 1. CLAVES FORÁNEAS INDEXADAS:
--    Por defecto, Oracle no indexa las columnas de Foreign Key (FK). En consultas
--    con JOIN sobre 25.000 registros (RESERVA, RESERVA_HABITACION, ALOJAMIENTO),
--    la ausencia de índices fuerza Full Table Scans y bloqueos de tabla.
-- 2. FILTRADO TEMPORAL:
--    Indexar FECHA_CHECK_IN acelera drásticamente las consultas analíticas 
--    (PIVOT, LAG, Variables Bind y Rollup) permitiendo Index Range Scans.
-- ============================================================================

ALTER SESSION SET CURRENT_SCHEMA = TURISMO_UQ;

-- 1. Índices en RESERVA_HABITACION
CREATE INDEX IDX_RESHAB_RESERVA ON RESERVA_HABITACION(ID_RESERVA);
CREATE INDEX IDX_RESHAB_HABITACION ON RESERVA_HABITACION(ID_HABITACION);

-- 2. Índices en RESERVA
CREATE INDEX IDX_RESERVA_CHECKIN ON RESERVA(FECHA_CHECK_IN);
CREATE INDEX IDX_RESERVA_CLIENTE ON RESERVA(ID_CLIENTE);

-- 3. Índices en HABITACION y ALOJAMIENTO
CREATE INDEX IDX_HAB_ALOJAMIENTO ON HABITACION(ID_ALOJAMIENTO);
CREATE INDEX IDX_ALOJ_MUNICIPIO ON ALOJAMIENTO(ID_MUNICIPIO);
CREATE INDEX IDX_ALOJ_TIPO ON ALOJAMIENTO(ID_TIPO_ALOJAMIENTO);

-- 4. Índices en TARIFA y PERIODO_TEMPORADA
CREATE INDEX IDX_TARIFA_HABITACION ON TARIFA(ID_HABITACION);
CREATE INDEX IDX_PERIODO_TEMP_FECHAS ON PERIODO_TEMPORADA(FECHA_INICIO, FECHA_FIN);

-- 5. Recalcular estadísticas del optimizador basado en costos (CBO)
EXEC DBMS_STATS.GATHER_SCHEMA_STATS('TURISMO_UQ');

PROMPT Índices de rendimiento creados y estadísticas actualizadas exitosamente.
