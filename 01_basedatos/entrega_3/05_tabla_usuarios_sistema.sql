-- ============================================================================
-- PROYECTO INTEGRADOR: TURISMOUQ - BASES DE DATOS II
-- ENTREGA 3: SCRIPT 05 - TABLA DE USUARIOS DEL SISTEMA Y AUTENTICACIÓN
-- MOTOR: ORACLE XE 21c (PDB: XEPDB1)
-- ============================================================================

ALTER SESSION SET CURRENT_SCHEMA = TURISMO_UQ;

-- 1. Creación de la tabla USUARIO_SISTEMA
BEGIN
    EXECUTE IMMEDIATE '
    CREATE TABLE USUARIO_SISTEMA (
        ID_USUARIO      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        USUARIO         VARCHAR2(50) NOT NULL UNIQUE,
        CONTRASENA      VARCHAR2(100) NOT NULL,
        NOMBRE_COMPLETO VARCHAR2(100) NOT NULL,
        CORREO          VARCHAR2(100) NOT NULL UNIQUE,
        ROL             VARCHAR2(50) NOT NULL,
        FECHA_CREACION  DATE DEFAULT SYSDATE NOT NULL,
        CONSTRAINT CHK_USUARIO_ROL CHECK (
            ROL IN (''ROL_RECEPCION'', ''ROL_ADMIN_ALOJAMIENTO'', ''ROL_GERENTE'', ''ROL_AUDITOR'', ''ROL_SUPER_ADMIN'')
        )
    )';
    DBMS_OUTPUT.PUT_LINE('Tabla USUARIO_SISTEMA creada exitosamente.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN
            DBMS_OUTPUT.PUT_LINE('La tabla USUARIO_SISTEMA ya existe.');
        ELSE RAISE; END IF;
END;
/

-- 2. Poblado de usuarios predeterminados de cátedra
MERGE INTO USUARIO_SISTEMA u
USING (
    SELECT 'USR_RECEPCION_01' AS usuario, 'Recep2026#' AS contrasena, 'Laura Gómez (Recepcionista)' AS nombre_completo, 'recepcion@turismouq.com' AS correo, 'ROL_RECEPCION' AS rol FROM dual UNION ALL
    SELECT 'USR_ADMIN_01', 'Admin2026#', 'Carlos Mendoza (Administrador Alojamientos)', 'admin.aloj@turismouq.com', 'ROL_ADMIN_ALOJAMIENTO' FROM dual UNION ALL
    SELECT 'USR_GERENTE_01', 'Geren2026#', 'Diana Morales (Gerente TurismoUQ)', 'gerencia@turismouq.com', 'ROL_GERENTE' FROM dual UNION ALL
    SELECT 'USR_AUDITOR_01', 'Audit2026#', 'Felipe Restrepo (Auditor de Cumplimiento)', 'auditoria@turismouq.com', 'ROL_AUDITOR' FROM dual UNION ALL
    SELECT 'ADMIN_TOTAL', 'Turismo2026#', 'Administrador Principal (Super Admin DBA)', 'dba@turismouq.com', 'ROL_SUPER_ADMIN' FROM dual UNION ALL
    SELECT 'admin', 'admin123', 'Administrador del Sistema', 'admin@turismouq.com', 'ROL_SUPER_ADMIN' FROM dual
) d ON (u.USUARIO = d.usuario)
WHEN MATCHED THEN
    UPDATE SET u.CONTRASENA = d.contrasena, u.NOMBRE_COMPLETO = d.nombre_completo, u.CORREO = d.correo, u.ROL = d.rol
WHEN NOT MATCHED THEN
    INSERT (USUARIO, CONTRASENA, NOMBRE_COMPLETO, CORREO, ROL, FECHA_CREACION)
    VALUES (d.usuario, d.contrasena, d.nombre_completo, d.correo, d.rol, SYSDATE);

COMMIT;
PROMPT Usuarios de sistema inicializados correctamente en USUARIO_SISTEMA.
EXIT;
