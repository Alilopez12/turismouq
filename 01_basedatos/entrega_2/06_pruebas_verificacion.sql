-- ============================================================================
-- PROYECTO INTEGRADOR: TURISMOUQ - BASES DE DATOS II
-- SCRIPT 08: PRUEBAS AUTOMATIZADAS DE VERIFICACIÓN (ENTREGA 2)
-- MOTOR: ORACLE XE 21c (PDB: XEPDB1)
-- ============================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED;
ALTER SESSION SET CURRENT_SCHEMA = TURISMO_UQ;

PROMPT ========================================================================
PROMPT INICIANDO BATERIA DE PRUEBAS DE VERIFICACION PL/SQL
PROMPT ========================================================================

DECLARE
    v_total             NUMBER(14,2);
    v_id_reserva        NUMBER;
    v_procesados        NUMBER;
    v_error_20001       BOOLEAN := FALSE;
    v_error_20002       BOOLEAN := FALSE;
    v_error_20003       BOOLEAN := FALSE;
BEGIN
    -- ------------------------------------------------------------------------
    -- TEST 1: fn_valor_estadia cruzando dos temporadas
    -- Del 21/03/2024 al 26/03/2024:
    -- Noches 21 y 22: Temporada Baja
    -- Noches 23, 24 y 25: Temporada Alta (Semana Santa inicia el 23)
    -- ------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- TEST 1: Calculo de estadia cruzando temporadas ---');
    v_total := PKG_TURISMO_UQ.fn_valor_estadia(
        p_id_habitacion => 1,
        p_fecha_in      => TO_DATE('2024-03-21', 'YYYY-MM-DD'),
        p_fecha_out     => TO_DATE('2024-03-26', 'YYYY-MM-DD')
    );
    DBMS_OUTPUT.PUT_LINE('Total estadia calculada (5 noches: 2 baja + 3 alta): $' || TO_CHAR(v_total, 'FM999,999,999'));

    -- ------------------------------------------------------------------------
    -- TEST 2: sp_crear_reserva exitosa
    -- ------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- TEST 2: Creacion de reserva exitosa ---');
    PKG_TURISMO_UQ.sp_crear_reserva(
        p_id_cliente    => 1,
        p_id_habitacion => 1,
        p_fecha_in      => TO_DATE('2027-02-01', 'YYYY-MM-DD'),
        p_fecha_out     => TO_DATE('2027-02-05', 'YYYY-MM-DD'),
        p_num_huespedes => 2,
        p_id_reserva    => v_id_reserva,
        p_total         => v_total
    );
    DBMS_OUTPUT.PUT_LINE('Reserva creada con exito! ID: ' || v_id_reserva || ', Total: $' || TO_CHAR(v_total, 'FM999,999,999'));

    -- ------------------------------------------------------------------------
    -- TEST 3: Excepción Check-out anterior o igual a Check-in (ORA-20001)
    -- ------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- TEST 3: Prueba excepcion ORA-20001 (fechas invalidas) ---');
    BEGIN
        PKG_TURISMO_UQ.sp_crear_reserva(
            p_id_cliente    => 1,
            p_id_habitacion => 1,
            p_fecha_in      => TO_DATE('2027-02-10', 'YYYY-MM-DD'),
            p_fecha_out     => TO_DATE('2027-02-08', 'YYYY-MM-DD'),
            p_num_huespedes => 2,
            p_id_reserva    => v_id_reserva,
            p_total         => v_total
        );
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20001 THEN
                v_error_20001 := TRUE;
                DBMS_OUTPUT.PUT_LINE('Excepcion ORA-20001 capturada correctamente: ' || SQLERRM);
            ELSE
                DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            END IF;
    END;

    -- ------------------------------------------------------------------------
    -- TEST 4: Excepción Capacidad Excedida (ORA-20003)
    -- ------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- TEST 4: Prueba excepcion ORA-20003 (capacidad excedida) ---');
    BEGIN
        PKG_TURISMO_UQ.sp_crear_reserva(
            p_id_cliente    => 1,
            p_id_habitacion => 1, -- Capacidad usual: 2 a 4
            p_fecha_in      => TO_DATE('2027-02-10', 'YYYY-MM-DD'),
            p_fecha_out     => TO_DATE('2027-02-15', 'YYYY-MM-DD'),
            p_num_huespedes => 99, -- Exceso evidente
            p_id_reserva    => v_id_reserva,
            p_total         => v_total
        );
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20003 THEN
                v_error_20003 := TRUE;
                DBMS_OUTPUT.PUT_LINE('Excepcion ORA-20003 capturada correctamente: ' || SQLERRM);
            ELSE
                DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            END IF;
    END;

    -- ------------------------------------------------------------------------
    -- TEST 5: Excepción Habitación No Disponible / Solapamiento (ORA-20002)
    -- Intento de reservar sobre las fechas del TEST 2 (2027-02-01 al 2027-02-05)
    -- ------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- TEST 5: Prueba excepcion ORA-20002 (solapamiento) ---');
    BEGIN
        PKG_TURISMO_UQ.sp_crear_reserva(
            p_id_cliente    => 2,
            p_id_habitacion => 1,
            p_fecha_in      => TO_DATE('2027-02-03', 'YYYY-MM-DD'),
            p_fecha_out     => TO_DATE('2027-02-07', 'YYYY-MM-DD'),
            p_num_huespedes => 2,
            p_id_reserva    => v_id_reserva,
            p_total         => v_total
        );
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20002 THEN
                v_error_20002 := TRUE;
                DBMS_OUTPUT.PUT_LINE('Excepcion ORA-20002 capturada correctamente: ' || SQLERRM);
            ELSE
                DBMS_OUTPUT.PUT_LINE('Error inesperado: ' || SQLERRM);
            END IF;
    END;

    -- ------------------------------------------------------------------------
    -- TEST 6: Cursor explicito parametrizado de liquidacion mensual
    -- ------------------------------------------------------------------------
    DBMS_OUTPUT.PUT_LINE('--- TEST 6: Ejecucion de proceso masivo de liquidacion mensual ---');
    PKG_TURISMO_UQ.sp_liquidacion_mensual_alojamiento(
        p_mes              => 3,
        p_anio             => 2025,
        p_id_alojamiento   => NULL,
        p_total_procesados => v_procesados
    );
    DBMS_OUTPUT.PUT_LINE('Liquidacion masiva completada! Alojamientos procesados: ' || v_procesados);

    -- Limpieza de la reserva de prueba
    DELETE FROM RESERVA_HABITACION WHERE id_reserva = v_id_reserva;
    DELETE FROM RESERVA WHERE id_reserva = v_id_reserva;
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('========================================================================');
    DBMS_OUTPUT.PUT_LINE('RESUMEN DE PRUEBAS:');
    DBMS_OUTPUT.PUT_LINE('Validacion 20001 (Check-in/Check-out): ' || CASE WHEN v_error_20001 THEN 'EXITOSA' ELSE 'FALLIDA' END);
    DBMS_OUTPUT.PUT_LINE('Validacion 20002 (Solapamiento):       ' || CASE WHEN v_error_20002 THEN 'EXITOSA' ELSE 'FALLIDA' END);
    DBMS_OUTPUT.PUT_LINE('Validacion 20003 (Capacidad):          ' || CASE WHEN v_error_20003 THEN 'EXITOSA' ELSE 'FALLIDA' END);
    DBMS_OUTPUT.PUT_LINE('========================================================================');
END;
/
