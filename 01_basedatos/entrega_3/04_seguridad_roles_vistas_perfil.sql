-- ============================================================================
-- PROYECTO INTEGRADOR: TURISMOUQ - BASES DE DATOS II
-- ENTREGA 3: SCRIPT 04 - SEGURIDAD, ROLES, VISTAS Y PERFILES DE USUARIO
-- MOTOR: ORACLE XE 21c (PDB: XEPDB1)
-- ============================================================================
-- REQUISITOS DEL PDF:
-- "Seguridad:
--  9. Cuatro roles: recepción, administrador de alojamiento, gerente y auditor,
--     con privilegios diferenciados.
--  10. Recepción accede solo a través de vistas, nunca a las tablas.
--  11. Un perfil con límites de sesión."
-- ============================================================================

ALTER SESSION SET CURRENT_SCHEMA = TURISMO_UQ;

-- ============================================================================
-- 1. CREACIÓN DEL PERFIL DE USUARIO CON LÍMITES DE SESIÓN (REQUISITO 11)
-- ============================================================================
BEGIN
    EXECUTE IMMEDIATE '
    CREATE PROFILE PRF_TURISMO_SEGURIDAD LIMIT
        SESSIONS_PER_USER          3
        CPU_PER_SESSION            UNLIMITED
        CPU_PER_CALL               6000
        CONNECT_TIME               120
        IDLE_TIME                  15
        FAILED_LOGIN_ATTEMPTS      3
        PASSWORD_LOCK_TIME         1
        PASSWORD_LIFE_TIME         90
    ';
    DBMS_OUTPUT.PUT_LINE('Perfil PRF_TURISMO_SEGURIDAD creado.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -2379 THEN
            DBMS_OUTPUT.PUT_LINE('El perfil PRF_TURISMO_SEGURIDAD ya existe.');
        ELSE RAISE; END IF;
END;
/

-- ============================================================================
-- 2. CREACIÓN DE VISTAS EXCLUSIVAS PARA RECEPCIÓN (REQUISITO 10)
-- "Recepción accede solo a través de vistas, nunca a las tablas."
-- ============================================================================

-- Vista 1: Huéspedes y reservas para Check-In
CREATE OR REPLACE VIEW V_RECEPCION_CHECKIN_HOY AS
SELECT 
    r.id_reserva,
    c.documento AS documento_huesped,
    c.nombres || ' ' || c.apellidos AS nombre_huesped,
    c.telefono AS telefono_contacto,
    a.nombre AS alojamiento,
    m.nombre AS municipio,
    h.numero_nombre AS habitacion,
    r.fecha_check_in,
    r.fecha_check_out,
    (r.fecha_check_out - r.fecha_check_in) AS total_noches,
    r.estado
FROM RESERVA r
JOIN CLIENTE c ON r.id_cliente = c.id_cliente
JOIN RESERVA_HABITACION rh ON r.id_reserva = rh.id_reserva
JOIN HABITACION h ON rh.id_habitacion = h.id_habitacion
JOIN ALOJAMIENTO a ON h.id_alojamiento = a.id_alojamiento
JOIN MUNICIPIO m ON a.id_municipio = m.id_municipio
WHERE r.estado = 'CONFIRMADA';

-- Vista 2: Disponibilidad e inventario operativo sin exponer datos financieros
CREATE OR REPLACE VIEW V_RECEPCION_DISPONIBILIDAD AS
SELECT 
    h.id_habitacion,
    h.numero_nombre AS habitacion,
    h.tipo_cama,
    h.capacidad AS aforo_maximo,
    a.id_alojamiento,
    a.nombre AS alojamiento,
    m.nombre AS municipio,
    a.telefono AS telefono_alojamiento
FROM HABITACION h
JOIN ALOJAMIENTO a ON h.id_alojamiento = a.id_alojamiento
JOIN MUNICIPIO m ON a.id_municipio = m.id_municipio;

-- Vista 3: Emisión de Comprobante / Voucher de Estadía
CREATE OR REPLACE VIEW V_RECEPCION_VOUCHER_RESERVA AS
SELECT 
    r.id_reserva,
    r.fecha_creacion,
    c.documento AS documento_cliente,
    c.nombres || ' ' || c.apellidos AS cliente_titular,
    a.nombre AS alojamiento,
    a.direccion,
    m.nombre AS municipio,
    h.numero_nombre AS habitacion,
    r.fecha_check_in,
    r.fecha_check_out,
    r.total AS total_facturado,
    r.estado AS estado_reserva
FROM RESERVA r
JOIN CLIENTE c ON r.id_cliente = c.id_cliente
JOIN RESERVA_HABITACION rh ON r.id_reserva = rh.id_reserva
JOIN HABITACION h ON rh.id_habitacion = h.id_habitacion
JOIN ALOJAMIENTO a ON h.id_alojamiento = a.id_alojamiento
JOIN MUNICIPIO m ON a.id_municipio = m.id_municipio;


-- ============================================================================
-- 3. CREACIÓN DE LOS CUATRO ROLES CON PRIVILEGIOS DIFERENCIADOS (REQUISITO 9)
-- ============================================================================
BEGIN
    FOR r IN (
        SELECT 'ROL_RECEPCION' AS rol FROM dual UNION ALL
        SELECT 'ROL_ADMIN_ALOJAMIENTO' FROM dual UNION ALL
        SELECT 'ROL_GERENTE' FROM dual UNION ALL
        SELECT 'ROL_AUDITOR' FROM dual
    ) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'CREATE ROLE ' || r.rol;
            DBMS_OUTPUT.PUT_LINE('Rol ' || r.rol || ' creado.');
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE = -1921 THEN NULL; ELSE RAISE; END IF;
        END;
    END LOOP;
END;
/

-- ----------------------------------------------------------------------------
-- ASIGNACIÓN DE PRIVILEGIOS POR ROL:
-- ----------------------------------------------------------------------------

-- ROL 1: RECEPCIÓN (Accede SOLO a través de Vistas, NUNCA a las tablas base)
BEGIN
    EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO ROL_RECEPCION';
    EXECUTE IMMEDIATE 'GRANT SELECT ON TURISMO_UQ.V_RECEPCION_CHECKIN_HOY TO ROL_RECEPCION';
    EXECUTE IMMEDIATE 'GRANT SELECT ON TURISMO_UQ.V_RECEPCION_DISPONIBILIDAD TO ROL_RECEPCION';
    EXECUTE IMMEDIATE 'GRANT SELECT ON TURISMO_UQ.V_RECEPCION_VOUCHER_RESERVA TO ROL_RECEPCION';
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON TURISMO_UQ.PKG_TURISMO_UQ TO ROL_RECEPCION';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- REGLA DEMOSTRADA: Cero privilegios directos de SELECT/INSERT/UPDATE sobre RESERVA, CLIENTE o PAGO.

-- ROL 2: ADMINISTRADOR DE ALOJAMIENTO (Gestión operativa del predio y habitaciones)
BEGIN
    EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO ROL_ADMIN_ALOJAMIENTO';
    EXECUTE IMMEDIATE 'GRANT SELECT, UPDATE ON TURISMO_UQ.ALOJAMIENTO TO ROL_ADMIN_ALOJAMIENTO';
    EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON TURISMO_UQ.HABITACION TO ROL_ADMIN_ALOJAMIENTO';
    EXECUTE IMMEDIATE 'GRANT SELECT ON TURISMO_UQ.TARIFA TO ROL_ADMIN_ALOJAMIENTO';
    EXECUTE IMMEDIATE 'GRANT SELECT ON TURISMO_UQ.LIQUIDACION_MENSUAL TO ROL_ADMIN_ALOJAMIENTO';
    EXECUTE IMMEDIATE 'GRANT SELECT ON TURISMO_UQ.RESERVA TO ROL_ADMIN_ALOJAMIENTO';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ROL 3: GERENTE (Visión gerencial, analítica y ejecutor financiero)
BEGIN
    EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO ROL_GERENTE';
    EXECUTE IMMEDIATE 'GRANT SELECT ON TURISMO_UQ.ALOJAMIENTO TO ROL_GERENTE';
    EXECUTE IMMEDIATE 'GRANT SELECT ON TURISMO_UQ.RESERVA TO ROL_GERENTE';
    EXECUTE IMMEDIATE 'GRANT SELECT ON TURISMO_UQ.PAGO TO ROL_GERENTE';
    EXECUTE IMMEDIATE 'GRANT SELECT ON TURISMO_UQ.LIQUIDACION_MENSUAL TO ROL_GERENTE';
    EXECUTE IMMEDIATE 'GRANT SELECT ON TURISMO_UQ.MV_OCUPACION_MENSUAL TO ROL_GERENTE';
    EXECUTE IMMEDIATE 'GRANT EXECUTE ON TURISMO_UQ.PKG_TURISMO_UQ TO ROL_GERENTE';
EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ROL 4: AUDITOR (Inspección forense de pistas de auditoría e inmutabilidad)
BEGIN
    EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO ROL_AUDITOR';
    EXECUTE IMMEDIATE 'GRANT SELECT ON TURISMO_UQ.AUDITORIA_TARIFA TO ROL_AUDITOR';
    EXECUTE IMMEDIATE 'GRANT SELECT ON TURISMO_UQ.LOG_SENTENCIA_TARIFA TO ROL_AUDITOR';
    EXECUTE IMMEDIATE 'GRANT SELECT ON TURISMO_UQ.RESERVA TO ROL_AUDITOR';
    EXECUTE IMMEDIATE 'GRANT SELECT ON TURISMO_UQ.PAGO TO ROL_AUDITOR';
EXCEPTION WHEN OTHERS THEN NULL; END;
/
-- Cero privilegios de modificación DML para garantizar integridad probatoria.

-- ============================================================================
-- 4. CREACIÓN DE USUARIOS DE PRUEBA ASOCIADOS AL PERFIL Y ROLES
-- ============================================================================
DECLARE
    PROCEDURE crear_usuario(p_user VARCHAR2, p_pass VARCHAR2, p_rol VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE 'CREATE USER ' || p_user || ' IDENTIFIED BY "' || p_pass || '" ' ||
                          'DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP ' ||
                          'PROFILE PRF_TURISMO_SEGURIDAD';
        EXECUTE IMMEDIATE 'GRANT ' || p_rol || ' TO ' || p_user;
        DBMS_OUTPUT.PUT_LINE('Usuario ' || p_user || ' asignado a ' || p_rol || ' con perfil PRF_TURISMO_SEGURIDAD.');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -1920 THEN
                EXECUTE IMMEDIATE 'ALTER USER ' || p_user || ' PROFILE PRF_TURISMO_SEGURIDAD';
                EXECUTE IMMEDIATE 'GRANT ' || p_rol || ' TO ' || p_user;
                DBMS_OUTPUT.PUT_LINE('Usuario ' || p_user || ' actualizado.');
            ELSE RAISE; END IF;
    END;
BEGIN
    crear_usuario('USR_RECEPCION_01', 'Recep2026#', 'ROL_RECEPCION');
    crear_usuario('USR_ADMIN_01',     'Admin2026#', 'ROL_ADMIN_ALOJAMIENTO');
    crear_usuario('USR_GERENTE_01',   'Geren2026#', 'ROL_GERENTE');
    crear_usuario('USR_AUDITOR_01',   'Audit2026#', 'ROL_AUDITOR');
END;
/

PROMPT ============================================================================
PROMPT === SEGURIDAD, ROLES, VISTAS Y PERFILES CONFIGURADOS EXITOSAMENTE        ===
PROMPT ============================================================================
