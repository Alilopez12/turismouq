-- ============================================================================
-- PROYECTO INTEGRADOR: TURISMOUQ - BASES DE DATOS II
-- SCRIPT 01: CREACIÓN DE TABLESPACE PARA HISTÓRICO DE RESERVAS
-- MOTOR: ORACLE XE 21c (PDB: XEPDB1)
-- ============================================================================
-- JUSTIFICACIÓN TÉCNICA Y DE ARQUITECTURA:
-- 1. AISLAMIENTO DE I/O (PERFORMANCE OLTP):
--    Las tablas transaccionales RESERVA y RESERVA_HABITACION reciben miles de 
--    transacciones concurrentes (DML continuo: INSERT, UPDATE, SELECT FOR UPDATE).
--    Separar las reservas históricas (años cerrados como 2024 o anteriores) en un 
--    tablespace físico independiente (TBS_HISTORICO_RESERVAS) garantiza que las
--    consultas de reportería analítica masiva y minería de datos histórica NO
--    compitan por los mismos bloques de disco ni por el mismo buffer cache que
--    las operaciones de reserva activa en tiempo real.
--
-- 2. POLÍTICAS DIFERENCIADAS DE BACKUP Y RECUPERACIÓN (RMAN):
--    El tablespace primario USERS requiere copias de seguridad incrementales
--    frecuentes (diarias). En contraste, el tablespace histórico contiene datos
--    estáticos que pueden marcarse en modo READ ONLY (ALTER TABLESPACE 
--    TBS_HISTORICO_RESERVAS READ ONLY;), reduciendo sustancialmente el tamaño y
--    la ventana horaria requerida para las ventanas de backup de la base de datos.
--
-- 3. COMPRESIÓN Y TIERS DE ALMACENAMIENTO (ILM - Information Lifecycle Management):
--    Permite habilitar compresión avanzada de datos (COMPRESS FOR OLTP / QUERY HIGH)
--    en el tablespace histórico, logrando ahorros de espacio en almacenamiento de hasta
--    un 70%, o mapear el datafile hacia discos de almacenamiento masivo secundario.
-- ============================================================================

ALTER SESSION SET CONTAINER = XEPDB1;

-- 1. Creación del Tablespace Dedicado
BEGIN
    EXECUTE IMMEDIATE '
        CREATE TABLESPACE TBS_HISTORICO_RESERVAS
        DATAFILE ''C:\APP\DELL\PRODUCT\21C\ORADATA\XE\XEPDB1\TBS_HISTORICO_RESERVAS01.DBF''
        SIZE 50M
        AUTOEXTEND ON NEXT 10M MAXSIZE 2G
        EXTENT MANAGEMENT LOCAL
        SEGMENT SPACE MANAGEMENT AUTO
    ';
    DBMS_OUTPUT.PUT_LINE('Tablespace TBS_HISTORICO_RESERVAS creado exitosamente.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -959 OR SQLCODE = -1543 THEN
            DBMS_OUTPUT.PUT_LINE('El tablespace TBS_HISTORICO_RESERVAS ya existe.');
        ELSE
            RAISE;
        END IF;
END;
/

-- 2. Otorgar cuota ilimitada al usuario de la aplicación
ALTER USER TURISMO_UQ QUOTA UNLIMITED ON TBS_HISTORICO_RESERVAS;

-- 3. Conexión al esquema TURISMO_UQ y creación de tablas históricas
ALTER SESSION SET CURRENT_SCHEMA = TURISMO_UQ;

-- Tabla histórica de reservas archivadas
BEGIN
    EXECUTE IMMEDIATE '
        CREATE TABLE HISTORICO_RESERVA (
            ID_HISTORICO        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            ID_RESERVA          NUMBER NOT NULL,
            FECHA_CREACION      DATE NOT NULL,
            FECHA_CHECK_IN      DATE NOT NULL,
            FECHA_CHECK_OUT     DATE NOT NULL,
            TOTAL               NUMBER(14,2) NOT NULL,
            ESTADO              VARCHAR2(25) NOT NULL,
            ID_CLIENTE          NUMBER NOT NULL,
            FECHA_ARCHIVADO     DATE DEFAULT SYSDATE NOT NULL,
            MOTIVO_ARCHIVADO    VARCHAR2(100) DEFAULT ''CIERRE DE VIGENCIA HISTORICA'' NOT NULL
        ) TABLESPACE TBS_HISTORICO_RESERVAS
    ';
    DBMS_OUTPUT.PUT_LINE('Tabla HISTORICO_RESERVA creada en TBS_HISTORICO_RESERVAS.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN
            DBMS_OUTPUT.PUT_LINE('La tabla HISTORICO_RESERVA ya existe.');
        ELSE
            RAISE;
        END IF;
END;
/

-- Tabla histórica de habitaciones de reservas archivadas
BEGIN
    EXECUTE IMMEDIATE '
        CREATE TABLE HISTORICO_RESERVA_HABITACION (
            ID_HISTORICO_HAB    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            ID_HISTORICO        NUMBER NOT NULL,
            ID_RESERVA          NUMBER NOT NULL,
            ID_HABITACION       NUMBER NOT NULL,
            PRECIO_UNITARIO     NUMBER(12,2) NOT NULL,
            SUBTOTAL            NUMBER(14,2) NOT NULL,
            CONSTRAINT FK_HIST_HAB_RESERVA FOREIGN KEY (ID_HISTORICO)
                REFERENCES HISTORICO_RESERVA(ID_HISTORICO) ON DELETE CASCADE
        ) TABLESPACE TBS_HISTORICO_RESERVAS
    ';
    DBMS_OUTPUT.PUT_LINE('Tabla HISTORICO_RESERVA_HABITACION creada en TBS_HISTORICO_RESERVAS.');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN
            DBMS_OUTPUT.PUT_LINE('La tabla HISTORICO_RESERVA_HABITACION ya existe.');
        ELSE
            RAISE;
        END IF;
END;
/

-- 4. Segregación física de tablas transaccionales masivas en TBS_HISTORICO_RESERVAS
BEGIN
    FOR t IN (SELECT table_name FROM user_tables WHERE table_name IN ('RESERVA', 'RESERVA_HABITACION', 'RESERVA_SERVICIO', 'PAGO', 'LIQUIDACION_MENSUAL') AND tablespace_name != 'TBS_HISTORICO_RESERVAS') LOOP
        EXECUTE IMMEDIATE 'ALTER TABLE ' || t.table_name || ' MOVE TABLESPACE TBS_HISTORICO_RESERVAS';
        DBMS_OUTPUT.PUT_LINE('Tabla ' || t.table_name || ' reubicada en TBS_HISTORICO_RESERVAS.');
    END LOOP;
END;
/

-- Reconstrucción de índices asociados en el tablespace dedicado
BEGIN
    FOR i IN (SELECT index_name FROM user_indexes WHERE table_name IN ('RESERVA', 'RESERVA_HABITACION', 'RESERVA_SERVICIO', 'PAGO', 'LIQUIDACION_MENSUAL') AND (tablespace_name != 'TBS_HISTORICO_RESERVAS' OR status = 'UNUSABLE')) LOOP
        EXECUTE IMMEDIATE 'ALTER INDEX ' || i.index_name || ' REBUILD TABLESPACE TBS_HISTORICO_RESERVAS';
        DBMS_OUTPUT.PUT_LINE('Índice ' || i.index_name || ' reconstruido en TBS_HISTORICO_RESERVAS.');
    END LOOP;
END;
/
