-- ============================================================================
-- PROYECTO INTEGRADOR: TURISMOUQ - BASES DE DATOS II
-- SCRIPT 05: DISPARADOR PARA IMPEDIR SOLAPAMIENTO DE RESERVAS EN LA MISMA HABITACIÓN
-- MOTOR: ORACLE XE 21c (PDB: XEPDB1)
-- ============================================================================

ALTER SESSION SET CURRENT_SCHEMA = TURISMO_UQ;

CREATE OR REPLACE TRIGGER TRG_IMPEDIR_SOLAPAMIENTO_RES
FOR INSERT OR UPDATE ON RESERVA_HABITACION
COMPOUND TRIGGER

    TYPE t_solicitud IS RECORD (
        id_reserva    NUMBER,
        id_habitacion NUMBER
    );
    TYPE t_solicitudes IS TABLE OF t_solicitud INDEX BY PLS_INTEGER;
    
    v_solicitudes t_solicitudes;
    v_total       PLS_INTEGER := 0;

    BEFORE STATEMENT IS
    BEGIN
        v_total := 0;
        v_solicitudes.DELETE;
    END BEFORE STATEMENT;

    BEFORE EACH ROW IS
    BEGIN
        v_total := v_total + 1;
        v_solicitudes(v_total).id_reserva    := :NEW.id_reserva;
        v_solicitudes(v_total).id_habitacion := :NEW.id_habitacion;
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
        v_check_in   DATE;
        v_check_out  DATE;
        v_estado     VARCHAR2(25);
        v_solapados  NUMBER := 0;
        v_conflicto_res NUMBER;
    BEGIN
        FOR i IN 1..v_total LOOP
            -- 1. Obtener las fechas y estado de la reserva solicitada
            BEGIN
                SELECT fecha_check_in, fecha_check_out, estado
                INTO v_check_in, v_check_out, v_estado
                FROM RESERVA
                WHERE id_reserva = v_solicitudes(i).id_reserva;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    CONTINUE;
            END;

            -- Si la reserva está cancelada no genera restricción
            IF v_estado = 'CANCELADA' THEN
                CONTINUE;
            END IF;

            -- 2. Validar solapamiento con cualquier otra reserva activa para la misma habitación
            -- Condición matemática de traslape:
            -- (check_in_existente < check_out_nuevo) Y (check_out_existente > check_in_nuevo)
            SELECT COUNT(*), NVL(MAX(r.id_reserva), 0)
            INTO v_solapados, v_conflicto_res
            FROM RESERVA_HABITACION rh
            JOIN RESERVA r ON rh.id_reserva = r.id_reserva
            WHERE rh.id_habitacion = v_solicitudes(i).id_habitacion
              AND r.id_reserva != v_solicitudes(i).id_reserva
              AND r.estado != 'CANCELADA'
              AND r.fecha_check_in < v_check_out
              AND r.fecha_check_out > v_check_in;

            IF v_solapados > 0 THEN
                RAISE_APPLICATION_ERROR(
                    -20002,
                    'Error de Solapamiento: La habitacion ' || v_solicitudes(i).id_habitacion || 
                    ' ya tiene una reserva activa (Reserva #' || v_conflicto_res || 
                    ') que se cruza con el rango del ' || TO_CHAR(v_check_in, 'DD/MM/YYYY') || 
                    ' al ' || TO_CHAR(v_check_out, 'DD/MM/YYYY') || '.'
                );
            END IF;
        END LOOP;
    END AFTER STATEMENT;

END TRG_IMPEDIR_SOLAPAMIENTO_RES;
/
