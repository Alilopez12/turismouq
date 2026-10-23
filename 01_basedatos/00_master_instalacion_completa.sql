-- ============================================================================
-- PROYECTO INTEGRADOR: TURISMOUQ - BASES DE DATOS II
-- SCRIPT MAESTRO: 00_master_instalacion_completa.sql
-- DESCRIPCIÓN: Script de ejecución secuencial limpia para instalación y
--              despliegue de los componentes de Entrega 1 y Entrega 2.
-- MOTOR: ORACLE XE 21c (PDB: XEPDB1)
-- AUTOR: Alilopez12 <allisonlopez1928@gmail.com>
-- ============================================================================
-- INSTRUCCIONES DE EJECUCIÓN:
-- 1. En SQL Developer / SQL*Plus, conectarse a la base de datos como SYSTEM o TURISMO_UQ
-- 2. Asegurarse de estar posicionado en el contenedor pluggable XEPDB1:
--    ALTER SESSION SET CONTAINER = XEPDB1;
-- 3. Ejecutar este script mediante:
--    @00_master_instalacion_completa.sql
-- ============================================================================

SET ECHO OFF;
SET FEEDBACK ON;
SET SERVEROUTPUT ON SIZE UNLIMITED;
SET TIMING ON;

PROMPT ============================================================================
PROMPT === PROYECTO INTEGRADOR BDII: TURISMOUQ - INSTALACION COMPLETA           ===
PROMPT ============================================================================

-- Configuración de entorno y esquema
ALTER SESSION SET CURRENT_SCHEMA = TURISMO_UQ;

PROMPT ----------------------------------------------------------------------------
PROMPT [PASO 1/7] Ejecutando Script 01: Creacion y verificacion de Tablespace
PROMPT ----------------------------------------------------------------------------
@@entrega_1/01_tablespace_historico.sql;

PROMPT ----------------------------------------------------------------------------
PROMPT [PASO 2/7] Ejecutando Script 02: Normalizacion, Temporadas y Tarifas
PROMPT ----------------------------------------------------------------------------
@@entrega_2/01_adecuacion_modelo.sql;

PROMPT ----------------------------------------------------------------------------
PROMPT [PASO 3/7] Ejecutando Script 03: Disparador de Auditoria de Tarifa (Statement)
PROMPT ----------------------------------------------------------------------------
@@entrega_2/02_auditoria_tarifa.sql;

PROMPT ----------------------------------------------------------------------------
PROMPT [PASO 4/7] Ejecutando Script 04: Disparador Anti-Solapamiento (Compound)
PROMPT ----------------------------------------------------------------------------
@@entrega_2/03_trigger_solapamiento.sql;

PROMPT ----------------------------------------------------------------------------
PROMPT [PASO 5/7] Ejecutando Script 05 y 06: Paquete PL/SQL PKG_TURISMO_UQ
PROMPT ----------------------------------------------------------------------------
@@entrega_2/04_paquete_turismo_espec.sql;
@@entrega_2/05_paquete_turismo_cuerpo.sql;

PROMPT ----------------------------------------------------------------------------
PROMPT [PASO 6/7] Ejecutando Script 07: Indices B-Tree de Rendimiento
PROMPT ----------------------------------------------------------------------------
@@entrega_2/07_indices_rendimiento.sql;

PROMPT ----------------------------------------------------------------------------
PROMPT [PASO 7/7] Ejecutando Script 08: Bateria Automatizada de Verificacion PL/SQL
PROMPT ----------------------------------------------------------------------------
@@entrega_2/06_pruebas_verificacion.sql;

PROMPT ============================================================================
PROMPT === VERIFICACION FINAL DE ESTADO DE OBJETOS EN EL ESQUEMA TURISMO_UQ     ===
PROMPT ============================================================================

COLUMN OBJECT_NAME FORMAT A30;
COLUMN OBJECT_TYPE FORMAT A20;
COLUMN STATUS FORMAT A10;

SELECT object_name, object_type, status
FROM user_objects
WHERE object_type IN ('PACKAGE', 'PACKAGE BODY', 'TRIGGER', 'TABLE', 'INDEX', 'VIEW', 'MATERIALIZED VIEW')
  AND status = 'INVALID'
ORDER BY object_type, object_name;

PROMPT Objetos invalidos (debe ser 0 filas si todo compilo correctamente).

PROMPT ============================================================================
PROMPT === CONTEO DE REGISTROS CLAVE EN MODELO RELACIONAL                       ===
PROMPT ============================================================================

SELECT 'MUNICIPIOS' AS ENTIDAD, COUNT(*) AS TOTAL FROM MUNICIPIO
UNION ALL
SELECT 'ALOJAMIENTOS', COUNT(*) FROM ALOJAMIENTO
UNION ALL
SELECT 'HABITACIONES', COUNT(*) FROM HABITACION
UNION ALL
SELECT 'CLIENTES', COUNT(*) FROM CLIENTE
UNION ALL
SELECT 'RESERVAS', COUNT(*) FROM RESERVA
UNION ALL
SELECT 'TARIFAS', COUNT(*) FROM TARIFA
UNION ALL
SELECT 'PERIODOS TEMPORADA', COUNT(*) FROM PERIODO_TEMPORADA;

PROMPT ============================================================================
PROMPT === INSTALACION Y VERIFICACION COMPLETADA CON EXITO                      ===
PROMPT ============================================================================
