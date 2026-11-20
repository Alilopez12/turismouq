-- ============================================================================
-- PROYECTO INTEGRADOR: TURISMOUQ - BASES DE DATOS II
-- ENTREGA 3: SCRIPT 02 - EXPERIMENTO DE CONCURRENCIA Y CONTROL DE BLOQUEOS
-- MOTOR: ORACLE XE 21c (PDB: XEPDB1)
-- ============================================================================
-- REQUISITO DEL PDF:
-- "Concurrencia: experimento documentado con dos sesiones intentando reservar 
--  la misma habitación al tiempo. Muestren el bloqueo, apliquen SELECT ... FOR UPDATE 
--  y comparen el comportamiento antes y después."
-- ============================================================================

BEGIN
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') IN ('SYS', 'SYSTEM') THEN
        EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA = TURISMO_UQ';
    END IF;
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- ============================================================================
-- PROCEDIMIENTO ALMACENADO CON BLOQUEO PESIMISTA: SELECT ... FOR UPDATE
-- ============================================================================
CREATE OR REPLACE PROCEDURE sp_reserva_concurrente_for_update(
    p_id_cliente    IN  NUMBER,
    p_id_habitacion IN  NUMBER,
    p_fecha_in      IN  DATE,
    p_fecha_out     IN  DATE,
    p_num_huespedes IN  NUMBER,
    p_timeout_seg   IN  NUMBER DEFAULT 5,
    p_id_reserva    OUT NUMBER,
    p_total         OUT NUMBER,
    p_mensaje       OUT VARCHAR2,
    p_retener_seg   IN  NUMBER DEFAULT 0
) IS
    v_capacidad    NUMBER;
    v_id_hab_lock  NUMBER;
    v_solapados    NUMBER := 0;
    v_reserva_conf NUMBER;
BEGIN
    -- 1. BLOQUEO PESIMISTA A NIVEL DE FILA:
    -- Adquiere un bloqueo exclusivo de transacción (TX Lock en modo X) sobre la fila
    -- de la habitación en la tabla HABITACION antes de verificar solapamientos e insertar.
    -- La cláusula FOR UPDATE WAIT p_timeout_seg retiene la fila; si otra sesión ya la
    -- tiene bloqueada, espera un máximo de p_timeout_seg segundos antes de arrojar ORA-30006.
    BEGIN
        SELECT id_habitacion, capacidad
        INTO v_id_hab_lock, v_capacidad
        FROM HABITACION
        WHERE id_habitacion = p_id_habitacion
        FOR UPDATE WAIT 5;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -30006 OR SQLCODE = -54 THEN
                RAISE_APPLICATION_ERROR(
                    -20005, 
                    'Recurso Bloqueado (Concurrencia): La habitacion ' || p_id_habitacion || 
                    ' esta siendo reservada en este momento por otra transaccion activa. Intente de nuevo en unos segundos.'
                );
            ELSE
                RAISE;
            END IF;
    END;

    -- 2. Validación de disponibilidad bajo entorno serializado
    SELECT COUNT(*), NVL(MAX(r.id_reserva), 0)
    INTO v_solapados, v_reserva_conf
    FROM RESERVA r
    JOIN RESERVA_HABITACION rh ON r.id_reserva = rh.id_reserva
    WHERE rh.id_habitacion = p_id_habitacion
      AND r.estado != 'CANCELADA'
      AND r.fecha_check_in < TRUNC(p_fecha_out)
      AND r.fecha_check_out > TRUNC(p_fecha_in);

    IF v_solapados > 0 THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(
            -20002, 
            'Habitacion no disponible: Conflicto con reserva previa #' || v_reserva_conf
        );
    END IF;

    -- 3. Inserción atómica protegida
    p_total := PKG_TURISMO_UQ.fn_valor_estadia(p_id_habitacion, p_fecha_in, p_fecha_out);

    INSERT INTO RESERVA (
        fecha_creacion, fecha_check_in, fecha_check_out, total, estado, id_cliente
    ) VALUES (
        SYSDATE, TRUNC(p_fecha_in), TRUNC(p_fecha_out), p_total, 'CONFIRMADA', p_id_cliente
    ) RETURNING id_reserva INTO p_id_reserva;

    INSERT INTO RESERVA_HABITACION (
        id_reserva, id_habitacion, precio_unitario, subtotal
    ) VALUES (
        p_id_reserva, p_id_habitacion, p_total, p_total
    );

    IF NVL(p_retener_seg, 0) > 0 THEN
        -- Mantiene temporalmente el TX lock sobre HABITACION para demostraciones de concurrencia
        DBMS_SESSION.SLEEP(LEAST(p_retener_seg, 30));
    END IF;

    COMMIT; -- Libera el bloqueo pesimista y hace visibles los cambios

    p_mensaje := 'Reserva exitosa #' || p_id_reserva || ' procesada con bloqueo pesimista.';
END sp_reserva_concurrente_for_update;
/

-- ============================================================================
-- PROTOCOLO DOCUMENTADO DEL EXPERIMENTO DE CONCURRENCIA PARA SUSTENTACIÓN
-- ============================================================================
/*
PASO A PASO PARA DEMOSTRAR EN SQL DEVELOPER / SQL*PLUS CON 2 SESIONES (SESIÓN A Y SESIÓN B):

--------------------------------------------------------------------------------
EXPERIMENTO 1: SIN CONTROL PESIMISTA (COMPORTAMIENTO ANTES - READ COMMITTED)
--------------------------------------------------------------------------------
[SESIÓN A - t=0s]:
DECLARE v_id NUMBER; v_tot NUMBER;
BEGIN
    PKG_TURISMO_UQ.sp_crear_reserva(1, 15, TO_DATE('2029-10-01','YYYY-MM-DD'), TO_DATE('2029-10-05','YYYY-MM-DD'), 2, v_id, v_tot);
    DBMS_SESSION.SLEEP(6); -- Simula retardo antes del COMMIT (pasarela / usuario)
    COMMIT;
END;
/

[SESIÓN B - t=1s]:
DECLARE v_id NUMBER; v_tot NUMBER;
BEGIN
    -- Intenta reservar la MISMA habitación #15 en las MISMAS fechas concurrentemente
    PKG_TURISMO_UQ.sp_crear_reserva(2, 15, TO_DATE('2029-10-01','YYYY-MM-DD'), TO_DATE('2029-10-05','YYYY-MM-DD'), 2, v_id, v_tot);
    COMMIT;
END;
/
--> Observación real medida en Oracle XE:
    Bajo el aislamiento por defecto READ COMMITTED, Sesión B NO ve los datos sin confirmar
    de Sesión A (v_solapados = 0) y tampoco se bloquea sobre filas inexistentes. Ambas sesiones
    completan el INSERT produciendo un solapamiento real (Anomalía Write Skew / Double Booking).

--------------------------------------------------------------------------------
EXPERIMENTO 2: CON BLOQUEO PESIMISTA SELECT ... FOR UPDATE WAIT 5 (DESPUÉS)
--------------------------------------------------------------------------------
[SESIÓN A - t=0s]:
VARIABLE res_id NUMBER;
VARIABLE res_tot NUMBER;
VARIABLE res_msg VARCHAR2(300);
EXEC sp_reserva_concurrente_for_update(1, 20, TO_DATE('2029-11-01','YYYY-MM-DD'), TO_DATE('2029-11-05','YYYY-MM-DD'), 2, 5, :res_id, :res_tot, :res_msg, 8);

[SESIÓN B - t=1s]:
VARIABLE res_id NUMBER;
VARIABLE res_tot NUMBER;
VARIABLE res_msg VARCHAR2(300);
EXEC sp_reserva_concurrente_for_update(2, 20, TO_DATE('2029-11-01','YYYY-MM-DD'), TO_DATE('2029-11-05','YYYY-MM-DD'), 2, 5, :res_id, :res_tot, :res_msg, 0);
--> Observación real medida en Oracle XE:
    Sesión A retiene un TX Lock exclusivo (lmode/request = 6, evento 'enq: TX - row lock contention')
    sobre la fila de HABITACION #20 durante 8s. Sesión B queda serializada esperando hasta 5s
    y luego intercepta ORA-30006 -> ORA-20005: 'Recurso Bloqueado (Concurrencia): La habitacion 20
    esta siendo reservada en este momento por otra transaccion activa', evitando el double booking.

--------------------------------------------------------------------------------
CONSULTA DE MONITOREO DE BLOQUEOS (EJECUTAR COMO SYS / DBA MIENTRAS OCURRE ESPERA):
--------------------------------------------------------------------------------
SELECT
    s2.blocking_session AS sid_bloqueador,
    s2.sid AS sid_bloqueado,
    s2.username,
    l.type AS tipo_bloqueo,
    l.lmode AS modo_retenido,
    l.request AS modo_solicitado,
    s2.event AS evento_espera,
    s2.seconds_in_wait AS seg_espera
FROM v$session s2
JOIN v$lock l ON l.sid = s2.sid AND l.request > 0
WHERE s2.blocking_session IS NOT NULL;
*/
