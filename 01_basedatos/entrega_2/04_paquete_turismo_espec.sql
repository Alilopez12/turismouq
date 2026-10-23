-- ============================================================================
-- PROYECTO INTEGRADOR: TURISMOUQ - BASES DE DATOS II
-- SCRIPT 06: ESPECIFICACIÓN DEL PAQUETE PKG_TURISMO_UQ (ENTREGA 2)
-- MOTOR: ORACLE XE 21c (PDB: XEPDB1)
-- ============================================================================

ALTER SESSION SET CURRENT_SCHEMA = TURISMO_UQ;

-- Tabla para almacenar los consolidados de las liquidaciones mensuales
BEGIN
    EXECUTE IMMEDIATE '
        CREATE TABLE LIQUIDACION_MENSUAL (
            ID_LIQUIDACION          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
            ID_ALOJAMIENTO          NUMBER NOT NULL,
            NOMBRE_ALOJAMIENTO      VARCHAR2(120) NOT NULL,
            MUNICIPIO               VARCHAR2(60) NOT NULL,
            PROPIETARIO             VARCHAR2(120) NOT NULL,
            MES                     NUMBER(2) NOT NULL,
            ANIO                    NUMBER(4) NOT NULL,
            TOTAL_RESERVAS          NUMBER NOT NULL,
            INGRESOS_HOSPEDAJE      NUMBER(14,2) NOT NULL,
            INGRESOS_SERVICIOS      NUMBER(14,2) NOT NULL,
            TOTAL_BRUTO             NUMBER(14,2) NOT NULL,
            COMISION_PLATAFORMA     NUMBER(14,2) NOT NULL,
            PAGO_NETO_PROPIETARIO   NUMBER(14,2) NOT NULL,
            FECHA_LIQUIDACION       DATE DEFAULT SYSDATE NOT NULL,
            CONSTRAINT FK_LIQ_ALOJAMIENTO FOREIGN KEY (ID_ALOJAMIENTO) 
                REFERENCES ALOJAMIENTO(ID_ALOJAMIENTO)
        )
    ';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -955 THEN NULL; ELSE RAISE; END IF;
END;
/

CREATE OR REPLACE PACKAGE PKG_TURISMO_UQ AS

    -- ------------------------------------------------------------------------
    -- FUNCIÓN 1: fn_valor_estadia
    -- Calcula el valor total de una estadía aplicando la tarifa de cada temporada
    -- (Temporada Baja o Temporada Alta) que atraviese la reserva noche a noche.
    -- Lanza excepción si fecha_out <= fecha_in o si la habitación no existe.
    -- ------------------------------------------------------------------------
    FUNCTION fn_valor_estadia(
        p_id_habitacion IN NUMBER,
        p_fecha_in      IN DATE,
        p_fecha_out     IN DATE
    ) RETURN NUMBER;

    -- ------------------------------------------------------------------------
    -- PROCEDIMIENTO 1: sp_crear_reserva
    -- Crea una reserva completa validando:
    -- 1. Checkout posterior a Checkin (ORA-20001)
    -- 2. Habitación disponible / no solapada (ORA-20002)
    -- 3. Capacidad de huéspedes no excedida (ORA-20003)
    -- Calcula el valor total con fn_valor_estadia e inserta en RESERVA y RESERVA_HABITACION.
    -- ------------------------------------------------------------------------
    PROCEDURE sp_crear_reserva(
        p_id_cliente    IN  NUMBER,
        p_id_habitacion IN  NUMBER,
        p_fecha_in      IN  DATE,
        p_fecha_out     IN  DATE,
        p_num_huespedes IN  NUMBER,
        p_id_reserva    OUT NUMBER,
        p_total         OUT NUMBER
    );

    -- ------------------------------------------------------------------------
    -- PROCEDIMIENTO 2: sp_liquidacion_mensual_alojamiento
    -- Realiza la liquidación masiva mensual por alojamiento mediante un cursor
    -- explícito con parámetros. Totaliza hospedaje, servicios adicionales,
    -- calcula la comisión de la plataforma (10%) y el pago neto al dueño.
    -- ------------------------------------------------------------------------
    PROCEDURE sp_liquidacion_mensual_alojamiento(
        p_mes              IN  NUMBER,
        p_anio             IN  NUMBER,
        p_id_alojamiento   IN  NUMBER DEFAULT NULL,
        p_total_procesados OUT NUMBER
    );

END PKG_TURISMO_UQ;
/
