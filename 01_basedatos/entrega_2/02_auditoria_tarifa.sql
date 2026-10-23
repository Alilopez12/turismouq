-- ============================================================================
-- PROYECTO INTEGRADOR: TURISMOUQ - BASES DE DATOS II
-- SCRIPT 04: TABLA Y DISPARADOR A NIVEL DE SENTENCIA DE AUDITORÍA EN TARIFA
-- MOTOR: ORACLE XE 21c (PDB: XEPDB1)
-- ============================================================================

ALTER SESSION SET CURRENT_SCHEMA = TURISMO_UQ;

-- 1. TABLA DE AUDITORÍA DETALLADA DE TARIFAS
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE AUDITORIA_TARIFA CASCADE CONSTRAINTS PURGE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE AUDITORIA_TARIFA (
    ID_AUDITORIA        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ID_TARIFA           NUMBER,
    ID_HABITACION       NUMBER,
    ID_TEMPORADA        NUMBER,
    PRECIO_ANTERIOR     NUMBER(12,2),
    PRECIO_NUEVO        NUMBER(12,2),
    USUARIO_ORACLE      VARCHAR2(50) NOT NULL,
    FECHA_ACCION        DATE DEFAULT SYSDATE NOT NULL,
    TIPO_OPERACION      VARCHAR2(20) NOT NULL,
    DETALLE_SENTENCIA   VARCHAR2(250)
);

-- 2. TABLA DE LOG DE EJECUCIÓN A NIVEL DE SENTENCIA
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE LOG_SENTENCIA_TARIFA CASCADE CONSTRAINTS PURGE';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE LOG_SENTENCIA_TARIFA (
    ID_LOG              NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    USUARIO_ORACLE      VARCHAR2(50) NOT NULL,
    FECHA_ACCION        DATE DEFAULT SYSDATE NOT NULL,
    TIPO_OPERACION      VARCHAR2(20) NOT NULL,
    FILAS_AFECTADAS     NUMBER NOT NULL
);

-- 3. DISPARADOR COMPUESTO DE AUDITORÍA SOBRE TARIFA (NIVEL SENTENCIA Y FILA)
CREATE OR REPLACE TRIGGER TRG_AUDITORIA_TARIFA_STMT
FOR INSERT OR UPDATE OR DELETE ON TARIFA
COMPOUND TRIGGER

    TYPE t_id_tarifa IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    TYPE t_id_habitacion IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    TYPE t_id_temporada IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    TYPE t_precio IS TABLE OF NUMBER(12,2) INDEX BY PLS_INTEGER;
    TYPE t_operacion IS TABLE OF VARCHAR2(20) INDEX BY PLS_INTEGER;

    v_ids_tarifa       t_id_tarifa;
    v_ids_habitacion   t_id_habitacion;
    v_ids_temporada    t_id_temporada;
    v_precios_ant      t_precio;
    v_precios_nue      t_precio;
    v_operaciones      t_operacion;
    v_idx              PLS_INTEGER := 0;
    v_tipo_op          VARCHAR2(20);

    BEFORE STATEMENT IS
    BEGIN
        v_idx := 0;
        v_ids_tarifa.DELETE;
        v_ids_habitacion.DELETE;
        v_ids_temporada.DELETE;
        v_precios_ant.DELETE;
        v_precios_nue.DELETE;
        v_operaciones.DELETE;

        IF INSERTING THEN
            v_tipo_op := 'INSERT';
        ELSIF UPDATING THEN
            v_tipo_op := 'UPDATE';
        ELSIF DELETING THEN
            v_tipo_op := 'DELETE';
        END IF;
    END BEFORE STATEMENT;

    AFTER EACH ROW IS
    BEGIN
        v_idx := v_idx + 1;
        IF INSERTING THEN
            v_ids_tarifa(v_idx)     := :NEW.id_tarifa;
            v_ids_habitacion(v_idx) := :NEW.id_habitacion;
            v_ids_temporada(v_idx)  := :NEW.id_temporada;
            v_precios_ant(v_idx)    := NULL;
            v_precios_nue(v_idx)    := :NEW.precio_noche;
            v_operaciones(v_idx)    := 'INSERT';
        ELSIF UPDATING THEN
            v_ids_tarifa(v_idx)     := :NEW.id_tarifa;
            v_ids_habitacion(v_idx) := :NEW.id_habitacion;
            v_ids_temporada(v_idx)  := :NEW.id_temporada;
            v_precios_ant(v_idx)    := :OLD.precio_noche;
            v_precios_nue(v_idx)    := :NEW.precio_noche;
            v_operaciones(v_idx)    := 'UPDATE';
        ELSIF DELETING THEN
            v_ids_tarifa(v_idx)     := :OLD.id_tarifa;
            v_ids_habitacion(v_idx) := :OLD.id_habitacion;
            v_ids_temporada(v_idx)  := :OLD.id_temporada;
            v_precios_ant(v_idx)    := :OLD.precio_noche;
            v_precios_nue(v_idx)    := NULL;
            v_operaciones(v_idx)    := 'DELETE';
        END IF;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        v_detalle VARCHAR2(250);
    BEGIN
        FOR i IN 1..v_idx LOOP
            v_detalle := 'Sentencia DML ' || v_operaciones(i) || ' ejecutada sobre TARIFA';
            INSERT INTO AUDITORIA_TARIFA (
                id_tarifa,
                id_habitacion,
                id_temporada,
                precio_anterior,
                precio_nuevo,
                usuario_oracle,
                fecha_accion,
                tipo_operacion,
                detalle_sentencia
            ) VALUES (
                v_ids_tarifa(i),
                v_ids_habitacion(i),
                v_ids_temporada(i),
                v_precios_ant(i),
                v_precios_nue(i),
                USER,
                SYSDATE,
                v_operaciones(i),
                v_detalle
            );
        END LOOP;

        INSERT INTO LOG_SENTENCIA_TARIFA (
            usuario_oracle,
            fecha_accion,
            tipo_operacion,
            filas_afectadas
        ) VALUES (
            USER,
            SYSDATE,
            v_tipo_op,
            v_idx
        );
    END AFTER STATEMENT;

END TRG_AUDITORIA_TARIFA_STMT;
/
