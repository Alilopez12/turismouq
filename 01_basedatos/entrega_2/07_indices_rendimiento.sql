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

BEGIN
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') IN ('SYS', 'SYSTEM') THEN
        EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA = TURISMO_UQ';
    END IF;
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

DECLARE
    PROCEDURE crear_indice(p_ddl IN VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_ddl;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE IN (-955, -1408) THEN
                NULL; -- El índice o columnas ya están indexadas
            ELSE
                RAISE;
            END IF;
    END;
BEGIN
    -- 1. Índices en RESERVA_HABITACION
    crear_indice('CREATE INDEX IDX_RESHAB_RESERVA ON RESERVA_HABITACION(ID_RESERVA)');
    crear_indice('CREATE INDEX IDX_RESHAB_HABITACION ON RESERVA_HABITACION(ID_HABITACION)');

    -- 2. Índices en RESERVA
    crear_indice('CREATE INDEX IDX_RESERVA_CHECKIN ON RESERVA(FECHA_CHECK_IN)');
    crear_indice('CREATE INDEX IDX_RESERVA_CLIENTE ON RESERVA(ID_CLIENTE)');

    -- 3. Índices en HABITACION y ALOJAMIENTO
    crear_indice('CREATE INDEX IDX_HAB_ALOJAMIENTO ON HABITACION(ID_ALOJAMIENTO)');
    crear_indice('CREATE INDEX IDX_ALOJ_MUNICIPIO ON ALOJAMIENTO(ID_MUNICIPIO)');
    crear_indice('CREATE INDEX IDX_ALOJ_TIPO ON ALOJAMIENTO(ID_TIPO_ALOJAMIENTO)');

    -- 4. Índices en TARIFA y PERIODO_TEMPORADA
    crear_indice('CREATE INDEX IDX_TARIFA_HABITACION ON TARIFA(ID_HABITACION)');
    crear_indice('CREATE INDEX IDX_PERIODO_TEMP_FECHAS ON PERIODO_TEMPORADA(FECHA_INICIO, FECHA_FIN)');
END;
/

-- 5. Recalcular estadísticas del optimizador basado en costos (CBO)
BEGIN
    DBMS_STATS.GATHER_SCHEMA_STATS(SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'));
END;
/

PROMPT Índices de rendimiento verificados/creados y estadísticas actualizadas exitosamente.
