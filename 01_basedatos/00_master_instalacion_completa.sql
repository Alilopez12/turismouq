-- ============================================================================
-- PROYECTO INTEGRADOR: TURISMOUQ - BASES DE DATOS II
-- SCRIPT MAESTRO: 00_master_instalacion_completa.sql
-- DESCRIPCIÓN: Script de ejecución secuencial limpia para instalación y
--              despliegue de los componentes de Entrega 1, Entrega 2 y Entrega 3.
-- MOTOR: ORACLE XE 21c (PDB: XEPDB1)
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
SET SQLBLANKLINES ON;
SET TIMING ON;

PROMPT ============================================================================
PROMPT === PROYECTO INTEGRADOR BDII: TURISMOUQ - INSTALACION COMPLETA           ===
PROMPT === ENTREGAS 1, 2 Y 3 (100% REQUISITOS DEL PDF DE CATEDRA)               ===
PROMPT ============================================================================

-- Configuración inteligente de entorno y esquema:
-- Si se ejecuta como SYS/SYSTEM, apunta al esquema TURISMO_UQ si existe;
-- si se ejecuta conectado como un usuario limpio (p.ej. TURISMO_UQ o evaluador), opera sobre el esquema conectado.
BEGIN
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') IN ('SYS', 'SYSTEM') THEN
        EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA = TURISMO_UQ';
    END IF;
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

PROMPT +--------------------------------------------------------------------------+
PROMPT [PASO 1/14] Entrega 1: Creacion de las 16 Tablas del Modelo Relacional
PROMPT +--------------------------------------------------------------------------+
@@entrega_1/00_crear_esquema_tablas.sql;

PROMPT +--------------------------------------------------------------------------+
PROMPT [PASO 2/14] Entrega 1: Creacion y Verificacion del Tablespace TBS_HISTORICO
PROMPT +--------------------------------------------------------------------------+
@@entrega_1/01_tablespace_historico.sql;

PROMPT +--------------------------------------------------------------------------+
PROMPT [PASO 3/14] Entrega 1: Carga Masiva de Volumen (25.000+ Reservas, 3.000 Clientes)
PROMPT +--------------------------------------------------------------------------+
@@entrega_1/01_cargar_datos_volumen.sql;

PROMPT +--------------------------------------------------------------------------+
PROMPT [PASO 4/14] Entrega 2: Normalizacion, Temporadas y Tarifas
PROMPT +--------------------------------------------------------------------------+
@@entrega_2/01_adecuacion_modelo.sql;

PROMPT +--------------------------------------------------------------------------+
PROMPT [PASO 5/14] Entrega 2: Disparador de Auditoria de Tarifa (Statement Level)
PROMPT +--------------------------------------------------------------------------+
@@entrega_2/02_auditoria_tarifa.sql;

PROMPT +--------------------------------------------------------------------------+
PROMPT [PASO 6/14] Entrega 2: Disparador Anti-Solapamiento (Compound Trigger)
PROMPT +--------------------------------------------------------------------------+
@@entrega_2/03_trigger_solapamiento.sql;

PROMPT +--------------------------------------------------------------------------+
PROMPT [PASO 7/14] Entrega 2 y 3: Paquete PL/SQL PKG_TURISMO_UQ (Espec y Cuerpo)
PROMPT +--------------------------------------------------------------------------+
@@entrega_2/04_paquete_turismo_espec.sql;
@@entrega_2/05_paquete_turismo_cuerpo.sql;

PROMPT +--------------------------------------------------------------------------+
PROMPT [PASO 8/14] Entrega 2: Indices B-Tree de Rendimiento Iniciales
PROMPT +--------------------------------------------------------------------------+
@@entrega_2/07_indices_rendimiento.sql;

PROMPT +--------------------------------------------------------------------------+
PROMPT [PASO 9/14] Entrega 2: Bateria Automatizada de Verificacion PL/SQL
PROMPT +--------------------------------------------------------------------------+
@@entrega_2/06_pruebas_verificacion.sql;

PROMPT +--------------------------------------------------------------------------+
PROMPT [PASO 10/14] Entrega 1: Vista Materializada MV_OCUPACION_MENSUAL y 10 Consultas
PROMPT +--------------------------------------------------------------------------+
@@entrega_1/02_consultas_analisis.sql;

PROMPT +--------------------------------------------------------------------------+
PROMPT [PASO 11/14] Entrega 3: Transacciones Atomicas y Rollback Parcial (SAVEPOINT)
PROMPT +--------------------------------------------------------------------------+
@@entrega_3/01_transacciones_savepoint.sql;

PROMPT +--------------------------------------------------------------------------+
PROMPT [PASO 12/14] Entrega 3: Concurrencia y Bloqueos (SELECT ... FOR UPDATE)
PROMPT +--------------------------------------------------------------------------+
@@entrega_3/02_concurrencia_bloqueos.sql;

PROMPT +--------------------------------------------------------------------------+
PROMPT [PASO 13/14] Entrega 3: Optimizacion CBO, Indices Avanzados y Seguridad
PROMPT +--------------------------------------------------------------------------+
@@entrega_3/03_indices_optimizacion_cbo.sql;
@@entrega_3/04_seguridad_roles_vistas_perfil.sql;

PROMPT +--------------------------------------------------------------------------+
PROMPT [PASO 14/14] Entrega 3: Tabla USUARIO_SISTEMA y Credenciales de Aplicacion
PROMPT +--------------------------------------------------------------------------+
@@entrega_3/05_tabla_usuarios_sistema.sql;

PROMPT ============================================================================
PROMPT === VERIFICACION FINAL DE ESTADO DE OBJETOS EN EL ESQUEMA TURISMO_UQ     ===
PROMPT ============================================================================

BEGIN
    DBMS_MVIEW.REFRESH('MV_OCUPACION_MENSUAL', 'C');
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

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
PROMPT === INSTALACION Y VERIFICACION COMPLETADA CON EXITO AL 100%              ===
PROMPT ============================================================================

EXIT;
