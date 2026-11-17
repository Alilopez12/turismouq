ALTER SESSION SET CURRENT_SCHEMA = TURISMO_UQ;
PROMPT Compiling Package Spec...
@"01_basedatos/entrega_2/04_paquete_turismo_espec.sql";
SHOW ERRORS PACKAGE PKG_TURISMO_UQ;

PROMPT Compiling Package Body...
@"01_basedatos/entrega_2/05_paquete_turismo_cuerpo.sql";
SHOW ERRORS PACKAGE BODY PKG_TURISMO_UQ;

PROMPT Running Entrega 3: 01_transacciones_savepoint.sql...
@"01_basedatos/entrega_3/01_transacciones_savepoint.sql";

PROMPT Running Entrega 3: 02_concurrencia_bloqueos.sql...
@"01_basedatos/entrega_3/02_concurrencia_bloqueos.sql";
SHOW ERRORS PROCEDURE sp_reserva_concurrente_for_update;

PROMPT Running Entrega 3: 03_indices_optimizacion_cbo.sql...
@"01_basedatos/entrega_3/03_indices_optimizacion_cbo.sql";

PROMPT Running Entrega 3: 04_seguridad_roles_vistas_perfil.sql...
@"01_basedatos/entrega_3/04_seguridad_roles_vistas_perfil.sql";

SELECT object_name, object_type, status FROM user_objects WHERE status = 'INVALID';
EXIT;
