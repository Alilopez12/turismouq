-- ============================================================================
-- PROYECTO INTEGRADOR: TURISMOUQ - BASES DE DATOS II
-- ENTREGA 3: SCRIPT 05 - TABLA DE USUARIOS DEL SISTEMA Y AUTENTICACIÓN
-- MOTOR: ORACLE XE 21c (PDB: XEPDB1)
-- ============================================================================

BEGIN
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') IN ('SYS', 'SYSTEM') THEN
        EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA = TURISMO_UQ';
    END IF;
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- 1. Creación / Adecuación idempotente de USUARIO_SISTEMA
BEGIN
    EXECUTE IMMEDIATE '
    CREATE TABLE USUARIO_SISTEMA (
        ID_USUARIO      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
        NOMBRE_USUARIO  VARCHAR2(50) NOT NULL,
        CORREO          VARCHAR2(120) NOT NULL,
        CONTRASENA      VARCHAR2(256) NOT NULL,
        ROL             VARCHAR2(40) NOT NULL,
        ESTADO          VARCHAR2(20) DEFAULT ''ACTIVO'' NOT NULL,
        NOMBRE_COMPLETO VARCHAR2(100),
        CONSTRAINT UK_USUARIO_NOMBRE UNIQUE (NOMBRE_USUARIO),
        CONSTRAINT UK_USUARIO_CORREO UNIQUE (CORREO)
    )';
    DBMS_OUTPUT.PUT_LINE('Tabla USUARIO_SISTEMA creada exitosamente.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN
            DBMS_OUTPUT.PUT_LINE('La tabla USUARIO_SISTEMA ya existe; validando columnas...');
        ELSE
            RAISE;
        END IF;
END;
/

-- Asegurar columna NOMBRE_COMPLETO si viene de esquema previo
BEGIN
    EXECUTE IMMEDIATE 'ALTER TABLE USUARIO_SISTEMA ADD (NOMBRE_COMPLETO VARCHAR2(100) DEFAULT ''Usuario TurismoUQ'')';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -1430 THEN RAISE; END IF;
END;
/

-- Asegurar restricción CHK_USUARIO_ROL con todos los roles oficiales + Super Admin
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'ALTER TABLE USUARIO_SISTEMA DROP CONSTRAINT CHK_USUARIO_ROL';
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
    EXECUTE IMMEDIATE '
        ALTER TABLE USUARIO_SISTEMA ADD CONSTRAINT CHK_USUARIO_ROL CHECK (
            ROL IN (''RECEPCION'', ''ADMINISTRADOR'', ''GERENTE'', ''AUDITOR'', ''ADMIN_ALOJAMIENTO'',
                    ''ROL_RECEPCION'', ''ROL_ADMIN_ALOJAMIENTO'', ''ROL_GERENTE'', ''ROL_AUDITOR'', ''ROL_SUPER_ADMIN'')
        )
    ';
END;
/

-- 2. Poblado idempotente de usuarios predeterminados de cátedra y aplicación
MERGE INTO USUARIO_SISTEMA u
USING (
    SELECT 'ADMIN_TOTAL' AS nombre_usuario, 'Turismo2026#' AS contrasena, 'Administrador Principal (Super Admin)' AS nombre_completo, 'dba@turismouq.com' AS correo, 'ROL_SUPER_ADMIN' AS rol, 'ACTIVO' AS estado FROM dual UNION ALL
    SELECT 'admin', 'Turismo2026#', 'Administrador del Sistema', 'admin@turismouq.com', 'ROL_SUPER_ADMIN', 'ACTIVO' FROM dual UNION ALL
    SELECT 'USR_RECEPCION_01', 'Turismo2026#', 'Laura Gómez (Recepcionista)', 'recepcion@turismouq.com', 'ROL_RECEPCION', 'ACTIVO' FROM dual UNION ALL
    SELECT 'USR_ADMIN_01', 'Turismo2026#', 'Carlos Mendoza (Admin Alojamiento)', 'admin.aloj@turismouq.com', 'ROL_ADMIN_ALOJAMIENTO', 'ACTIVO' FROM dual UNION ALL
    SELECT 'USR_GERENTE_01', 'Turismo2026#', 'Diana Morales (Gerente TurismoUQ)', 'gerencia@turismouq.com', 'ROL_GERENTE', 'ACTIVO' FROM dual UNION ALL
    SELECT 'USR_AUDITOR_01', 'Turismo2026#', 'Felipe Restrepo (Auditor)', 'auditoria@turismouq.com', 'ROL_AUDITOR', 'ACTIVO' FROM dual
) d ON (u.NOMBRE_USUARIO = d.nombre_usuario)
WHEN MATCHED THEN
    UPDATE SET u.CONTRASENA = d.contrasena,
               u.NOMBRE_COMPLETO = d.nombre_completo,
               u.CORREO = d.correo,
               u.ROL = d.rol,
               u.ESTADO = d.estado
WHEN NOT MATCHED THEN
    INSERT (NOMBRE_USUARIO, CONTRASENA, NOMBRE_COMPLETO, CORREO, ROL, ESTADO)
    VALUES (d.nombre_usuario, d.contrasena, d.nombre_completo, d.correo, d.rol, d.estado);

COMMIT;
PROMPT Usuarios de sistema inicializados correctamente en USUARIO_SISTEMA.
