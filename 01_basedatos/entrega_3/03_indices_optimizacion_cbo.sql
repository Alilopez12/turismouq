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

ALTER SESSION SET CURRENT_SCHEMA = TURISMO_UQ;
SET LINESIZE 250;
SET PAGESIZE 100;

PROMPT ============================================================================
PROMPT === ACTUALIZACIÓN INICIAL DE ESTADÍSTICAS PARA EL CBO                   ===
PROMPT ============================================================================
EXEC DBMS_STATS.GATHER_SCHEMA_STATS('TURISMO_UQ');

-- ============================================================================
-- CONSULTA 1: FILTRO COMBINADO DE ESTADO, RANGO TEMPORAL Y MONTO
-- TIPO DE ÍNDICE: ÍNDICE COMPUESTO (COMPOSITE B-TREE INDEX)
-- ============================================================================
PROMPT ----------------------------------------------------------------------------
PROMPT [CONSULTA 1] Plan de Ejecución ANTES de crear el Índice Compuesto
PROMPT ----------------------------------------------------------------------------
EXPLAIN PLAN SET STATEMENT_ID = 'Q1_ANTES' FOR
SELECT id_reserva, fecha_check_in, total, estado
FROM RESERVA
WHERE estado = 'CONFIRMADA'
  AND fecha_check_in BETWEEN TO_DATE('2025-06-01', 'YYYY-MM-DD') AND TO_DATE('2025-06-30', 'YYYY-MM-DD')
  AND total > 350000;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q1_ANTES', 'TYPICAL'));

-- Creación del Índice Compuesto
CREATE INDEX IDX_COMP_RES_EST_FEC_TOT 
ON RESERVA(ESTADO, FECHA_CHECK_IN, TOTAL)
TABLESPACE TBS_HISTORICO_RESERVAS;

EXEC DBMS_STATS.GATHER_INDEX_STATS('TURISMO_UQ', 'IDX_COMP_RES_EST_FEC_TOT');

PROMPT ----------------------------------------------------------------------------
PROMPT [CONSULTA 1] Plan de Ejecución DESPUÉS de crear el Índice Compuesto
PROMPT ----------------------------------------------------------------------------
EXPLAIN PLAN SET STATEMENT_ID = 'Q1_DESPUES' FOR
SELECT id_reserva, fecha_check_in, total, estado
FROM RESERVA
WHERE estado = 'CONFIRMADA'
  AND fecha_check_in BETWEEN TO_DATE('2025-06-01', 'YYYY-MM-DD') AND TO_DATE('2025-06-30', 'YYYY-MM-DD')
  AND total > 350000;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q1_DESPUES', 'TYPICAL'));


-- ============================================================================
-- CONSULTA 2: BÚSQUEDA INSENSIBLE A MAYÚSCULAS/MINÚSCULAS POR NOMBRE
-- TIPO DE ÍNDICE: ÍNDICE BASADO EN FUNCIÓN (FUNCTION-BASED INDEX)
-- ============================================================================
PROMPT ----------------------------------------------------------------------------
PROMPT [CONSULTA 2] Plan de Ejecución ANTES del Índice Basado en Función
PROMPT ----------------------------------------------------------------------------
EXPLAIN PLAN SET STATEMENT_ID = 'Q2_ANTES' FOR
SELECT id_cliente, documento, nombres, apellidos, correo
FROM CLIENTE
WHERE UPPER(nombres) LIKE 'CARLOS%';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q2_ANTES', 'TYPICAL'));

-- Creación del Índice Basado en Función
CREATE INDEX IDX_FUNC_CLIENTE_UPPER_NOM 
ON CLIENTE(UPPER(NOMBRES));

EXEC DBMS_STATS.GATHER_INDEX_STATS('TURISMO_UQ', 'IDX_FUNC_CLIENTE_UPPER_NOM');

PROMPT ----------------------------------------------------------------------------
PROMPT [CONSULTA 2] Plan de Ejecución DESPUÉS del Índice Basado en Función
PROMPT ----------------------------------------------------------------------------
EXPLAIN PLAN SET STATEMENT_ID = 'Q2_DESPUES' FOR
SELECT id_cliente, documento, nombres, apellidos, correo
FROM CLIENTE
WHERE UPPER(nombres) LIKE 'CARLOS%';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q2_DESPUES', 'TYPICAL'));


-- ============================================================================
-- CONSULTA 3: AGRUPACIÓN MENSUAL DE RESERVAS POR FECHA TRUNCADA
-- TIPO DE ÍNDICE: ÍNDICE BASADO EN FUNCIÓN MULTICOLUMNA
-- ============================================================================
PROMPT ----------------------------------------------------------------------------
PROMPT [CONSULTA 3] Plan de Ejecución ANTES del Índice Basado en Función TRUNC
PROMPT ----------------------------------------------------------------------------
EXPLAIN PLAN SET STATEMENT_ID = 'Q3_ANTES' FOR
SELECT TRUNC(fecha_check_in, 'MM') AS mes, COUNT(*) AS reservas, SUM(total) AS ingresos
FROM RESERVA
GROUP BY TRUNC(fecha_check_in, 'MM');

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q3_ANTES', 'TYPICAL'));

-- Creación del Índice Basado en Función con inclusión de columna de agregado
CREATE INDEX IDX_FUNC_RES_TRUNC_MES_TOT 
ON RESERVA(TRUNC(FECHA_CHECK_IN, 'MM'), TOTAL)
TABLESPACE TBS_HISTORICO_RESERVAS;

EXEC DBMS_STATS.GATHER_INDEX_STATS('TURISMO_UQ', 'IDX_FUNC_RES_TRUNC_MES_TOT');

PROMPT ----------------------------------------------------------------------------
PROMPT [CONSULTA 3] Plan de Ejecución DESPUÉS del Índice Basado en Función TRUNC
PROMPT ----------------------------------------------------------------------------
EXPLAIN PLAN SET STATEMENT_ID = 'Q3_DESPUES' FOR
SELECT TRUNC(fecha_check_in, 'MM') AS mes, COUNT(*) AS reservas, SUM(total) AS ingresos
FROM RESERVA
GROUP BY TRUNC(fecha_check_in, 'MM');

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'Q3_DESPUES', 'TYPICAL'));


-- ============================================================================
-- CASO NEGATIVO OBLIGATORIO: DONDE EL ÍNDICE NO AYUDA Y EL CBO LO DESCARTA
-- ============================================================================
PROMPT ============================================================================
PROMPT === CASO NEGATIVO: CONSULTA CON BAJA SELECTIVIDAD (PREDICADO NO SELECTIVO)===
PROMPT ============================================================================
-- Se crea un índice B-Tree sobre la columna ESTADO
CREATE INDEX IDX_RESERVA_ESTADO ON RESERVA(ESTADO) TABLESPACE TBS_HISTORICO_RESERVAS;
EXEC DBMS_STATS.GATHER_INDEX_STATS('TURISMO_UQ', 'IDX_RESERVA_ESTADO');

EXPLAIN PLAN SET STATEMENT_ID = 'CASO_NEGATIVO' FOR
SELECT *
FROM RESERVA
WHERE estado != 'CANCELADA';

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'CASO_NEGATIVO', 'TYPICAL'));

/*
JUSTIFICACIÓN TÉCNICA DEL CASO NEGATIVO (PARA SUSTENTACIÓN ANTE EL DOCENTE):

1. Naturaleza de los Datos y Selectividad:
   En TurismoUQ, más del 92% de las 25.019 reservas tienen estado 'CONFIRMADA' o 'PENDIENTE_PAGO'.
   Solo un ~8% son 'CANCELADA'. La condición WHERE estado != 'CANCELADA' selecciona aproximadamente
   23.000 filas (selectividad = 92%).

2. Costo Matemático comparativo evaluado por el CBO:
   - Opción Vía Índice: Oracle tendría que leer los bloques del índice B-Tree para encontrar
     los ROWIDs de 23.000 filas y luego realizar 23.000 lecturas individuales aleatorias de bloque 
     (Single-Block I/O: 'db file sequential read') mediante la operación TABLE ACCESS BY INDEX ROWID.
     El costo de 23.000 accesos aleatorios a disco es astronómico.
   - Opción Vía Full Table Scan (FTS): El motor lee los bloques contiguos de la tabla en grandes
     lotes mediante lecturas multiboque (Multi-Block I/O: 'db file scattered read'), gobernadas por
     el parámetro DB_FILE_MULTIBLOCK_READ_COUNT.

3. Decisión del Motor:
   El Optimizador Basado en Costos (CBO) determina con precisión matemática que el Full Table Scan
   consume un costo de I/O y CPU significativamente menor que usar el índice. Por lo tanto,
   el índice IDX_RESERVA_ESTADO ES DESCARTADO y el motor ejecuta conscientemente TABLE ACCESS FULL.
   
   Conclusión Teórica: Los índices B-Tree solo son beneficiosos para consultas de ALTA SELECTIVIDAD
   (que recuperan menos del 5% al 10% del total de filas). Para consultas no selectivas, un índice
   no solo no ayuda, sino que degradaría el rendimiento si se forzara mediante HINTS.
*/
