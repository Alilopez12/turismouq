-- ============================================================================
-- PROYECTO INTEGRADOR: TURISMOUQ - BASES DE DATOS II
-- ENTREGA 3: SCRIPT 01 - TRANSACCIONES ATÓMICAS Y ROLLBACK PARCIAL CON SAVEPOINT
-- MOTOR: ORACLE XE 21c (PDB: XEPDB1)
-- ============================================================================
-- REQUISITO DEL PDF:
-- "Transacciones: procedimiento que registre reserva y pago de forma atómica,
--  con SAVEPOINT y demostración de un rollback parcial."
-- ============================================================================

ALTER SESSION SET CURRENT_SCHEMA = TURISMO_UQ;
SET SERVEROUTPUT ON SIZE UNLIMITED;

PROMPT ============================================================================
PROMPT === DEMOSTRACIÓN 1: FLUJO ATÓMICO EXITOSO (COMMIT COMPLETO)               ===
PROMPT ============================================================================

DECLARE
    v_id_reserva     NUMBER;
    v_id_pago        NUMBER;
    v_total          NUMBER;
    v_estado_reserva VARCHAR2(25);
    v_mensaje        VARCHAR2(500);
BEGIN
    -- Ejecución con p_simular_fallo = 0 (cobro exitoso)
    PKG_TURISMO_UQ.sp_registrar_reserva_con_pago(
        p_id_cliente     => 1,
        p_id_habitacion  => 10,
        p_fecha_in       => TO_DATE('2027-09-01', 'YYYY-MM-DD'),
        p_fecha_out      => TO_DATE('2027-09-05', 'YYYY-MM-DD'),
        p_num_huespedes  => 2,
        p_metodo_pago    => 'TARJETA_CREDITO',
        p_simular_fallo  => 0,
        p_id_reserva     => v_id_reserva,
        p_id_pago        => v_id_pago,
        p_total          => v_total,
        p_estado_reserva => v_estado_reserva,
        p_mensaje        => v_mensaje
    );

    DBMS_OUTPUT.PUT_LINE('Resultado: ' || v_mensaje);
    DBMS_OUTPUT.PUT_LINE('Reserva ID: ' || v_id_reserva || ' | Pago ID: ' || v_id_pago || ' | Estado: ' || v_estado_reserva);
END;
/

PROMPT ============================================================================
PROMPT === DEMOSTRACIÓN 2: DEMOSTRACIÓN DE ROLLBACK PARCIAL CON SAVEPOINT       ===
PROMPT ============================================================================

DECLARE
    v_id_reserva     NUMBER;
    v_id_pago        NUMBER;
    v_total          NUMBER;
    v_estado_reserva VARCHAR2(25);
    v_mensaje        VARCHAR2(500);
    v_conteo_pago    NUMBER;
BEGIN
    -- Ejecución con p_simular_fallo = 1 (simula rechazo de pasarela tras crear reserva)
    PKG_TURISMO_UQ.sp_registrar_reserva_con_pago(
        p_id_cliente     => 2,
        p_id_habitacion  => 12,
        p_fecha_in       => TO_DATE('2027-09-10', 'YYYY-MM-DD'),
        p_fecha_out      => TO_DATE('2027-09-14', 'YYYY-MM-DD'),
        p_num_huespedes  => 2,
        p_metodo_pago    => 'PSE',
        p_simular_fallo  => 1,
        p_id_reserva     => v_id_reserva,
        p_id_pago        => v_id_pago,
        p_total          => v_total,
        p_estado_reserva => v_estado_reserva,
        p_mensaje        => v_mensaje
    );

    DBMS_OUTPUT.PUT_LINE('Resultado: ' || v_mensaje);
    DBMS_OUTPUT.PUT_LINE('Reserva ID: ' || v_id_reserva || ' | Estado: ' || v_estado_reserva || ' | Pago ID: ' || NVL(TO_CHAR(v_id_pago), 'NULL (NO EXISTE)'));

    -- Verificación en tablas físicas: La reserva EXISTE en estado PENDIENTE, pero el PAGO NO se insertó
    SELECT COUNT(*) INTO v_conteo_pago FROM PAGO WHERE id_reserva = v_id_reserva;
    DBMS_OUTPUT.PUT_LINE('Verificación de integridad: Pagos asociados en base de datos = ' || v_conteo_pago);
    IF v_conteo_pago = 0 AND v_estado_reserva = 'PENDIENTE' THEN
        DBMS_OUTPUT.PUT_LINE('>>> ROLLBACK PARCIAL VERIFICADO CON ÉXITO: La reserva se preservó y el pago se revirtió.');
    END IF;
END;
/
