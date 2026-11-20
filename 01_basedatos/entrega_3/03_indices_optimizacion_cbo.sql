-- ============================================================================
-- PROYECTO INTEGRADOR: TURISMOUQ - BASES DE DATOS II
-- ENTREGA 3: SCRIPT 03 - OPTIMIZACIÓN CON ÍNDICES AVANZADOS Y PLANES CBO
-- MOTOR: ORACLE XE 21c (PDB: XEPDB1)
-- ============================================================================
-- REQUISITO DEL PDF:
-- "Índices: identifiquen 3 consultas lentas, capturen el plan de ejecución
--  antes y después, creen los índices (al menos uno compuesto y uno basado
--  en función) y midan. Incluyan además un caso donde el índice no ayude
--  y expliquen por qué. Ese punto vale tanto como los otros tres."
-- ============================================================================

BEGIN
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') IN ('SYS', 'SYSTEM') THEN
        EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA = TURISMO_UQ';
    END IF;
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

SET SERVEROUTPUT ON SIZE UNLIMITED;
SET LINESIZE 250;
SET PAGESIZE 100;
SET TIMING ON;

PROMPT ============================================================================
PROMPT === PREPARACIÓN: LIMPIEZA IDEMPOTENTE DE LOS 4 ÍNDICES CBO Y STATS     ===
PROMPT ============================================================================
BEGIN
    FOR idx IN (
        SELECT index_name
        FROM user_indexes
        WHERE index_name IN (
            'IDX_COMP_RES_EST_FEC_TOT',
            'IDX_FUNC_CLIENTE_UPPER_NOM',
            'IDX_FUNC_RES_TRUNC_MES_TOT',
            'IDX_RESERVA_ESTADO'
        )
    ) LOOP
        EXECUTE IMMEDIATE 'DROP INDEX ' || idx.index_name;
    END LOOP;
END;
/

EXEC DBMS_STATS.GATHER_SCHEMA_STATS(SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'), METHOD_OPT => 'FOR ALL COLUMNS SIZE 254');

-- ============================================================================
-- CONSULTA 1: FILTRO COMBINADO DE ESTADO, RANGO TEMPORAL Y MONTO
-- TIPO DE ÍNDICE: ÍNDICE COMPUESTO B-TREE (COMPOSITE INDEX)
-- ============================================================================
PROMPT +--------------------------------------------------------------------------+
PROMPT [CONSULTA 1] Plan de Ejecución ANTES de crear el Índice Compuesto
PROMPT +--------------------------------------------------------------------------+
EXPLAIN PLAN SET STATEMENT_ID = 'Q1_ANTES' FOR
SELECT id_reserva, fecha_check_in, total, estado
FROM RESERVA
WHERE estado = 'CONFIRMADA'
  AND fecha_check_in BETWEEN TO_DATE('2026-10-01', 'YYYY-MM-DD') AND TO_DATE('2026-10-15', 'YYYY-MM-DD')
  AND total > 800000;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q1_ANTES', 'TYPICAL'));

DECLARE
    v_t0 NUMBER := DBMS_UTILITY.GET_TIME;
    v_cnt NUMBER := 0;
    v_tmp NUMBER;
BEGIN
    FOR i IN 1..50 LOOP
        SELECT COUNT(*) INTO v_tmp
        FROM (
            SELECT id_reserva, fecha_check_in, total, estado
            FROM RESERVA
            WHERE estado = 'CONFIRMADA'
              AND fecha_check_in BETWEEN TO_DATE('2026-10-01', 'YYYY-MM-DD') AND TO_DATE('2026-10-15', 'YYYY-MM-DD')
              AND total > 800000
        );
        v_cnt := v_tmp;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('[MEDICIÓN Q1 ANTES] 50 ejecuciones | Filas=' || v_cnt || ' | Tiempo=' || ((DBMS_UTILITY.GET_TIME - v_t0) * 10) || ' ms');
END;
/

-- Creación del Índice Compuesto
CREATE INDEX IDX_COMP_RES_EST_FEC_TOT
ON RESERVA(ESTADO, FECHA_CHECK_IN, TOTAL)
TABLESPACE TBS_HISTORICO_RESERVAS;

EXEC DBMS_STATS.GATHER_TABLE_STATS(SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'), 'RESERVA', METHOD_OPT => 'FOR ALL COLUMNS SIZE 254');

PROMPT +--------------------------------------------------------------------------+
PROMPT [CONSULTA 1] Plan de Ejecución DESPUÉS de crear el Índice Compuesto
PROMPT +--------------------------------------------------------------------------+
EXPLAIN PLAN SET STATEMENT_ID = 'Q1_DESPUES' FOR
SELECT id_reserva, fecha_check_in, total, estado
FROM RESERVA
WHERE estado = 'CONFIRMADA'
  AND fecha_check_in BETWEEN TO_DATE('2026-10-01', 'YYYY-MM-DD') AND TO_DATE('2026-10-15', 'YYYY-MM-DD')
  AND total > 800000;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q1_DESPUES', 'TYPICAL'));

DECLARE
    v_t0 NUMBER := DBMS_UTILITY.GET_TIME;
    v_cnt NUMBER := 0;
    v_tmp NUMBER;
BEGIN
    FOR i IN 1..50 LOOP
        SELECT COUNT(*) INTO v_tmp
        FROM (
            SELECT id_reserva, fecha_check_in, total, estado
            FROM RESERVA
            WHERE estado = 'CONFIRMADA'
              AND fecha_check_in BETWEEN TO_DATE('2026-10-01', 'YYYY-MM-DD') AND TO_DATE('2026-10-15', 'YYYY-MM-DD')
              AND total > 800000
        );
        v_cnt := v_tmp;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('[MEDICIÓN Q1 DESPUÉS] 50 ejecuciones | Filas=' || v_cnt || ' | Tiempo=' || ((DBMS_UTILITY.GET_TIME - v_t0) * 10) || ' ms');
END;
/

-- ============================================================================
-- CONSULTA 2: BÚSQUEDA INSENSIBLE A MAYÚSCULAS/MINÚSCULAS POR NOMBRE
-- TIPO DE ÍNDICE: ÍNDICE BASADO EN FUNCIÓN (FUNCTION-BASED INDEX)
-- ============================================================================
PROMPT +--------------------------------------------------------------------------+
PROMPT [CONSULTA 2] Plan de Ejecución ANTES del Índice Basado en Función
PROMPT +--------------------------------------------------------------------------+
EXPLAIN PLAN SET STATEMENT_ID = 'Q2_ANTES' FOR
SELECT id_cliente, documento, nombres, apellidos, correo
FROM CLIENTE
WHERE UPPER(nombres) LIKE 'CARLOS %';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q2_ANTES', 'TYPICAL'));

DECLARE
    v_t0 NUMBER := DBMS_UTILITY.GET_TIME;
    v_cnt NUMBER := 0;
    v_tmp NUMBER;
BEGIN
    FOR i IN 1..100 LOOP
        SELECT COUNT(*) INTO v_tmp
        FROM (
            SELECT id_cliente, documento, nombres, apellidos, correo
            FROM CLIENTE
            WHERE UPPER(nombres) LIKE 'CARLOS %'
        );
        v_cnt := v_tmp;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('[MEDICIÓN Q2 ANTES] 100 ejecuciones | Filas=' || v_cnt || ' | Tiempo=' || ((DBMS_UTILITY.GET_TIME - v_t0) * 10) || ' ms');
END;
/

-- Creación del Índice Basado en Función
CREATE INDEX IDX_FUNC_CLIENTE_UPPER_NOM
ON CLIENTE(UPPER(NOMBRES));

EXEC DBMS_STATS.GATHER_TABLE_STATS(SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'), 'CLIENTE', METHOD_OPT => 'FOR ALL COLUMNS SIZE 254');

PROMPT +--------------------------------------------------------------------------+
PROMPT [CONSULTA 2] Plan de Ejecución DESPUÉS del Índice Basado en Función
PROMPT +--------------------------------------------------------------------------+
EXPLAIN PLAN SET STATEMENT_ID = 'Q2_DESPUES' FOR
SELECT id_cliente, documento, nombres, apellidos, correo
FROM CLIENTE
WHERE UPPER(nombres) LIKE 'CARLOS %';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q2_DESPUES', 'TYPICAL'));

DECLARE
    v_t0 NUMBER := DBMS_UTILITY.GET_TIME;
    v_cnt NUMBER := 0;
    v_tmp NUMBER;
BEGIN
    FOR i IN 1..100 LOOP
        SELECT COUNT(*) INTO v_tmp
        FROM (
            SELECT id_cliente, documento, nombres, apellidos, correo
            FROM CLIENTE
            WHERE UPPER(nombres) LIKE 'CARLOS %'
        );
        v_cnt := v_tmp;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('[MEDICIÓN Q2 DESPUÉS] 100 ejecuciones | Filas=' || v_cnt || ' | Tiempo=' || ((DBMS_UTILITY.GET_TIME - v_t0) * 10) || ' ms');
END;
/

-- ============================================================================
-- CONSULTA 3: RESUMEN FINANCIERO MENSUAL POR FECHA TRUNCADA (COVERING FBI)
-- TIPO DE ÍNDICE: ÍNDICE BASADO EN FUNCIÓN MULTICOLUMNA CON AGREGACIÓN
-- ============================================================================
PROMPT +--------------------------------------------------------------------------+
PROMPT [CONSULTA 3] Plan de Ejecución ANTES del Índice Basado en Función TRUNC
PROMPT +--------------------------------------------------------------------------+
EXPLAIN PLAN SET STATEMENT_ID = 'Q3_ANTES' FOR
SELECT TO_DATE('2025-06-01', 'YYYY-MM-DD') AS mes,
       COUNT(*) AS reservas,
       NVL(SUM(total), 0) AS ingresos
FROM RESERVA
WHERE TRUNC(fecha_check_in, 'MM') = TO_DATE('2025-06-01', 'YYYY-MM-DD');

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q3_ANTES', 'TYPICAL'));

DECLARE
    v_t0 NUMBER := DBMS_UTILITY.GET_TIME;
    v_cnt NUMBER := 0;
    v_sum NUMBER := 0;
BEGIN
    FOR i IN 1..50 LOOP
        SELECT COUNT(*), NVL(SUM(total), 0) INTO v_cnt, v_sum
        FROM RESERVA
        WHERE TRUNC(fecha_check_in, 'MM') = TO_DATE('2025-06-01', 'YYYY-MM-DD');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('[MEDICIÓN Q3 ANTES] 50 ejecuciones | Reservas=' || v_cnt || ' | Tiempo=' || ((DBMS_UTILITY.GET_TIME - v_t0) * 10) || ' ms');
END;
/

-- Creación del Índice Basado en Función con inclusión de columna de agregado TOTAL
CREATE INDEX IDX_FUNC_RES_TRUNC_MES_TOT
ON RESERVA(TRUNC(FECHA_CHECK_IN, 'MM'), TOTAL)
TABLESPACE TBS_HISTORICO_RESERVAS;

EXEC DBMS_STATS.GATHER_TABLE_STATS(SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'), 'RESERVA', METHOD_OPT => 'FOR ALL COLUMNS SIZE 254');

PROMPT +--------------------------------------------------------------------------+
PROMPT [CONSULTA 3] Plan de Ejecución DESPUÉS del Índice Basado en Función TRUNC
PROMPT +--------------------------------------------------------------------------+
EXPLAIN PLAN SET STATEMENT_ID = 'Q3_DESPUES' FOR
SELECT TO_DATE('2025-06-01', 'YYYY-MM-DD') AS mes,
       COUNT(*) AS reservas,
       NVL(SUM(total), 0) AS ingresos
FROM RESERVA
WHERE TRUNC(fecha_check_in, 'MM') = TO_DATE('2025-06-01', 'YYYY-MM-DD');

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q3_DESPUES', 'TYPICAL'));

DECLARE
    v_t0 NUMBER := DBMS_UTILITY.GET_TIME;
    v_cnt NUMBER := 0;
    v_sum NUMBER := 0;
BEGIN
    FOR i IN 1..50 LOOP
        SELECT COUNT(*), NVL(SUM(total), 0) INTO v_cnt, v_sum
        FROM RESERVA
        WHERE TRUNC(fecha_check_in, 'MM') = TO_DATE('2025-06-01', 'YYYY-MM-DD');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('[MEDICIÓN Q3 DESPUÉS] 50 ejecuciones | Reservas=' || v_cnt || ' | Tiempo=' || ((DBMS_UTILITY.GET_TIME - v_t0) * 10) || ' ms');
END;
/

-- ============================================================================
-- CASO NEGATIVO OBLIGATORIO: DONDE EL ÍNDICE NO AYUDA Y EL CBO LO DESCARTA
-- ============================================================================
PROMPT ============================================================================
PROMPT === CASO NEGATIVO: CONSULTA CON BAJA SELECTIVIDAD (PREDICADO NO SELECTIVO)===
PROMPT ============================================================================
CREATE INDEX IDX_RESERVA_ESTADO ON RESERVA(ESTADO) TABLESPACE TBS_HISTORICO_RESERVAS;
EXEC DBMS_STATS.GATHER_TABLE_STATS(SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'), 'RESERVA', METHOD_OPT => 'FOR ALL COLUMNS SIZE 254');

PROMPT [CASO NEGATIVO - NATURAL CBO] El optimizador descarta IDX_RESERVA_ESTADO:
EXPLAIN PLAN SET STATEMENT_ID = 'CASO_NEG_NATURAL' FOR
SELECT *
FROM RESERVA
WHERE estado != 'CANCELADA';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CASO_NEG_NATURAL', 'TYPICAL'));

PROMPT [CASO NEGATIVO - HINT FORZADO] Degradación al forzar /*+ INDEX(r IDX_RESERVA_ESTADO) */:
EXPLAIN PLAN SET STATEMENT_ID = 'CASO_NEG_FORZADO' FOR
SELECT /*+ INDEX(r IDX_RESERVA_ESTADO) */ *
FROM RESERVA r
WHERE estado != 'CANCELADA';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CASO_NEG_FORZADO', 'TYPICAL'));

DECLARE
    v_t0 NUMBER := DBMS_UTILITY.GET_TIME;
    v_cnt NUMBER := 0;
BEGIN
    FOR i IN 1..20 LOOP
        SELECT COUNT(*) INTO v_cnt FROM (SELECT * FROM RESERVA WHERE estado != 'CANCELADA');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('[MEDICIÓN Q4 NATURAL FTS] 20 ejecuciones | Filas=' || v_cnt || ' | Tiempo=' || ((DBMS_UTILITY.GET_TIME - v_t0) * 10) || ' ms');

    v_t0 := DBMS_UTILITY.GET_TIME;
    FOR i IN 1..20 LOOP
        SELECT COUNT(*) INTO v_cnt FROM (SELECT /*+ INDEX(r IDX_RESERVA_ESTADO) */ * FROM RESERVA r WHERE estado != 'CANCELADA');
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('[MEDICIÓN Q4 FORZADO INDEX] 20 ejecuciones | Filas=' || v_cnt || ' | Tiempo=' || ((DBMS_UTILITY.GET_TIME - v_t0) * 10) || ' ms');
END;
/

/*
JUSTIFICACIÓN TÉCNICA DEL CASO NEGATIVO:
1. Naturaleza de los Datos y Selectividad:
   En TurismoUQ, prácticamente el 100% (o >92%) de las 25.000+ reservas tienen estado
   'FINALIZADA', 'CONFIRMADA' o 'PENDIENTE'. El predicado WHERE estado != 'CANCELADA'
   recupera casi la totalidad de la tabla (baja selectividad).
2. Costo Matemático evaluado por el CBO:
   - Vía Índice: Leer el índice IDX_RESERVA_ESTADO y efectuar más de 23.000 accesos
     aleatorios bloque por bloque (TABLE ACCESS BY INDEX ROWID -> db file sequential read)
     multiplica drásticamente el costo de I/O y CPU frente a leer la tabla una sola vez.
   - Vía Full Table Scan (FTS): Lectura secuencial multibloque contigua (db file scattered read)
     controlada por DB_FILE_MULTIBLOCK_READ_COUNT.
3. Conclusión:
   Los índices B-Tree benefician consultas de ALTA SELECTIVIDAD (< 5%-10% de filas).
   En baja selectividad el índice empeora el rendimiento si se fuerza con HINTS.
*/
