-- ============================================================================
-- PROYECTO INTEGRADOR: TURISMOUQ - BASES DE DATOS II
-- SCRIPT 07: CUERPO DEL PAQUETE PKG_TURISMO_UQ (ENTREGA 2 Y 3)
-- MOTOR: ORACLE XE 21c (PDB: XEPDB1)
-- ============================================================================

ALTER SESSION SET CURRENT_SCHEMA = TURISMO_UQ;

CREATE OR REPLACE PACKAGE BODY PKG_TURISMO_UQ AS

    -- ------------------------------------------------------------------------
    -- FUNCIÓN 1: fn_valor_estadia
    -- ------------------------------------------------------------------------
    FUNCTION fn_valor_estadia(
        p_id_habitacion IN NUMBER,
        p_fecha_in      IN DATE,
        p_fecha_out     IN DATE
    ) RETURN NUMBER IS
        v_total         NUMBER(14,2) := 0;
        v_tarifa_baja   NUMBER(12,2) := 0;
        v_tarifa_alta   NUMBER(12,2) := 0;
        v_fecha_actual  DATE;
        v_es_alta       NUMBER := 0;
        v_existe_hab    NUMBER := 0;
    BEGIN
        -- 1. Validación de coherencia de fechas
        IF p_fecha_out <= p_fecha_in THEN
            RAISE_APPLICATION_ERROR(
                -20001, 
                'Fechas invalidas: La fecha de check-out (' || TO_CHAR(p_fecha_out, 'DD/MM/YYYY') || 
                ') debe ser estrictamente posterior a la fecha de check-in (' || TO_CHAR(p_fecha_in, 'DD/MM/YYYY') || ').'
            );
        END IF;

        -- 2. Validación de existencia de habitación
        SELECT COUNT(*)
        INTO v_existe_hab
        FROM HABITACION
        WHERE id_habitacion = p_id_habitacion;

        IF v_existe_hab = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20004, 
                'Habitacion no encontrada: El ID de habitacion ' || p_id_habitacion || ' no existe en el sistema.'
            );
        END IF;

        -- 3. Obtención de tarifas configuradas para la habitación
        BEGIN
            SELECT precio_noche INTO v_tarifa_baja 
            FROM TARIFA 
            WHERE id_habitacion = p_id_habitacion AND id_temporada = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_tarifa_baja := 150000;
        END;

        BEGIN
            SELECT precio_noche INTO v_tarifa_alta 
            FROM TARIFA 
            WHERE id_habitacion = p_id_habitacion AND id_temporada = 2;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_tarifa_alta := ROUND(v_tarifa_baja * 1.40, -3);
        END;

        -- 4. Cálculo noche a noche determinando si cruza Temporada Baja o Alta
        v_fecha_actual := TRUNC(p_fecha_in);
        WHILE v_fecha_actual < TRUNC(p_fecha_out) LOOP
            SELECT COUNT(*)
            INTO v_es_alta
            FROM PERIODO_TEMPORADA
            WHERE id_temporada = 2
              AND v_fecha_actual BETWEEN fecha_inicio AND fecha_fin;

            IF v_es_alta > 0 THEN
                v_total := v_total + v_tarifa_alta;
            ELSE
                v_total := v_total + v_tarifa_baja;
            END IF;

            v_fecha_actual := v_fecha_actual + 1;
        END LOOP;

        RETURN v_total;
    END fn_valor_estadia;

    -- ------------------------------------------------------------------------
    -- PROCEDIMIENTO 1: sp_crear_reserva
    -- ------------------------------------------------------------------------
    PROCEDURE sp_crear_reserva(
        p_id_cliente    IN  NUMBER,
        p_id_habitacion IN  NUMBER,
        p_fecha_in      IN  DATE,
        p_fecha_out     IN  DATE,
        p_num_huespedes IN  NUMBER,
        p_id_reserva    OUT NUMBER,
        p_total         OUT NUMBER
    ) IS
        v_capacidad     NUMBER;
        v_solapados     NUMBER := 0;
        v_reserva_conf  NUMBER;
        v_cliente_ok    NUMBER := 0;
    BEGIN
        -- 1. Validación de fechas (ORA-20001)
        IF p_fecha_out <= p_fecha_in THEN
            RAISE_APPLICATION_ERROR(
                -20001,
                'Regla de negocio infringida: La fecha de check-out (' || TO_CHAR(p_fecha_out, 'DD/MM/YYYY') || 
                ') debe ser posterior al check-in (' || TO_CHAR(p_fecha_in, 'DD/MM/YYYY') || ').'
            );
        END IF;

        -- 2. Validación de cliente existente
        SELECT COUNT(*)
        INTO v_cliente_ok
        FROM CLIENTE
        WHERE id_cliente = p_id_cliente;

        IF v_cliente_ok = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20004,
                'Cliente no registrado: El ID de cliente ' || p_id_cliente || ' no existe en la base de datos.'
            );
        END IF;

        -- 3. Validación de capacidad de la habitación (ORA-20003)
        BEGIN
            SELECT capacidad
            INTO v_capacidad
            FROM HABITACION
            WHERE id_habitacion = p_id_habitacion;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(
                    -20004,
                    'Habitacion no encontrada: El ID ' || p_id_habitacion || ' no existe.'
                );
        END;

        IF p_num_huespedes > v_capacidad THEN
            RAISE_APPLICATION_ERROR(
                -20003,
                'Capacidad excedida: El numero de huespedes solicitado (' || p_num_huespedes || 
                ') supera la capacidad maxima permitida de la habitacion (' || v_capacidad || ' personas).'
            );
        END IF;

        IF p_num_huespedes <= 0 THEN
            RAISE_APPLICATION_ERROR(
                -20003,
                'Numero de personas invalido: La reserva debe incluir al menos 1 huesped.'
            );
        END IF;

        -- 4. Validación de solapamiento de fechas (ORA-20002)
        SELECT COUNT(*), NVL(MAX(r.id_reserva), 0)
        INTO v_solapados, v_reserva_conf
        FROM RESERVA r
        JOIN RESERVA_HABITACION rh ON r.id_reserva = rh.id_reserva
        WHERE rh.id_habitacion = p_id_habitacion
          AND r.estado != 'CANCELADA'
          AND r.fecha_check_in < TRUNC(p_fecha_out)
          AND r.fecha_check_out > TRUNC(p_fecha_in);

        IF v_solapados > 0 THEN
            RAISE_APPLICATION_ERROR(
                -20002,
                'Habitacion no disponible: Se solapa con una reserva activa previa (Reserva #' || 
                v_reserva_conf || ') en el rango del ' || TO_CHAR(p_fecha_in, 'DD/MM/YYYY') || 
                ' al ' || TO_CHAR(p_fecha_out, 'DD/MM/YYYY') || '.'
            );
        END IF;

        -- 5. Cálculo exacto del valor total mediante la función fn_valor_estadia
        p_total := fn_valor_estadia(p_id_habitacion, p_fecha_in, p_fecha_out);

        -- 6. Inserción atómica en la tabla RESERVA
        INSERT INTO RESERVA (
            fecha_creacion,
            fecha_check_in,
            fecha_check_out,
            total,
            estado,
            id_cliente
        ) VALUES (
            SYSDATE,
            TRUNC(p_fecha_in),
            TRUNC(p_fecha_out),
            p_total,
            'CONFIRMADA',
            p_id_cliente
        )
        RETURNING id_reserva INTO p_id_reserva;

        -- 7. Inserción en la tabla de detalle RESERVA_HABITACION
        INSERT INTO RESERVA_HABITACION (
            id_reserva,
            id_habitacion,
            precio_unitario,
            subtotal
        ) VALUES (
            p_id_reserva,
            p_id_habitacion,
            p_total,
            p_total
        );

    END sp_crear_reserva;

    -- ------------------------------------------------------------------------
    -- PROCEDIMIENTO 2: sp_liquidacion_mensual_alojamiento
    -- ------------------------------------------------------------------------
    PROCEDURE sp_liquidacion_mensual_alojamiento(
        p_mes              IN  NUMBER,
        p_anio             IN  NUMBER,
        p_id_alojamiento   IN  NUMBER DEFAULT NULL,
        p_total_procesados OUT NUMBER
    ) IS
        CURSOR cur_liquidar(c_alojamiento NUMBER, c_mes NUMBER, c_anio NUMBER) IS
            SELECT 
                a.id_alojamiento,
                a.nombre AS nombre_alojamiento,
                m.nombre AS nombre_municipio,
                p.nombres AS nombre_propietario,
                COUNT(DISTINCT r.id_reserva) AS total_reservas,
                NVL(SUM(CASE WHEN r.id_reserva IS NOT NULL THEN rh.subtotal ELSE 0 END), 0) AS total_hospedaje,
                NVL(SUM(NVL(srv.subtotal_srv, 0)), 0) AS total_servicios
            FROM ALOJAMIENTO a
            JOIN MUNICIPIO m ON a.id_municipio = m.id_municipio
            JOIN PROPIETARIO p ON a.id_propietario = p.id_propietario
            JOIN HABITACION h ON a.id_alojamiento = h.id_alojamiento
            LEFT JOIN RESERVA_HABITACION rh ON h.id_habitacion = rh.id_habitacion
            LEFT JOIN RESERVA r ON rh.id_reserva = r.id_reserva
                AND EXTRACT(MONTH FROM r.fecha_check_in) = c_mes
                AND EXTRACT(YEAR FROM r.fecha_check_in) = c_anio
                AND r.estado != 'CANCELADA'
            LEFT JOIN (
                SELECT id_reserva, SUM(subtotal) AS subtotal_srv
                FROM RESERVA_SERVICIO
                GROUP BY id_reserva
            ) srv ON r.id_reserva = srv.id_reserva
            WHERE (c_alojamiento IS NULL OR a.id_alojamiento = c_alojamiento)
            GROUP BY a.id_alojamiento, a.nombre, m.nombre, p.nombres
            ORDER BY a.id_alojamiento;

        v_reg             cur_liquidar%ROWTYPE;
        v_total_bruto     NUMBER(14,2);
        v_comision        NUMBER(14,2);
        v_pago_neto       NUMBER(14,2);
        v_contador        NUMBER := 0;
    BEGIN
        IF p_id_alojamiento IS NULL THEN
            DELETE FROM LIQUIDACION_MENSUAL WHERE mes = p_mes AND anio = p_anio;
        ELSE
            DELETE FROM LIQUIDACION_MENSUAL WHERE mes = p_mes AND anio = p_anio AND id_alojamiento = p_id_alojamiento;
        END IF;

        OPEN cur_liquidar(p_id_alojamiento, p_mes, p_anio);
        LOOP
            FETCH cur_liquidar INTO v_reg;
            EXIT WHEN cur_liquidar%NOTFOUND;

            v_total_bruto := v_reg.total_hospedaje + v_reg.total_servicios;
            v_comision    := ROUND(v_total_bruto * 0.10, 2);
            v_pago_neto   := v_total_bruto - v_comision;

            INSERT INTO LIQUIDACION_MENSUAL (
                id_alojamiento,
                nombre_alojamiento,
                municipio,
                propietario,
                mes,
                anio,
                total_reservas,
                ingresos_hospedaje,
                ingresos_servicios,
                total_bruto,
                comision_plataforma,
                pago_neto_propietario,
                fecha_liquidacion
            ) VALUES (
                v_reg.id_alojamiento,
                v_reg.nombre_alojamiento,
                v_reg.nombre_municipio,
                v_reg.nombre_propietario,
                p_mes,
                p_anio,
                v_reg.total_reservas,
                v_reg.total_hospedaje,
                v_reg.total_servicios,
                v_total_bruto,
                v_comision,
                v_pago_neto,
                SYSDATE
            );

            v_contador := v_contador + 1;
        END LOOP;
        CLOSE cur_liquidar;

        p_total_procesados := v_contador;
    END sp_liquidacion_mensual_alojamiento;

    -- ------------------------------------------------------------------------
    -- PROCEDIMIENTO 3: sp_cotizar_desglose
    -- ------------------------------------------------------------------------
    PROCEDURE sp_cotizar_desglose(
        p_id_habitacion    IN  NUMBER,
        p_fecha_in         IN  DATE,
        p_fecha_out        IN  DATE,
        p_noches_baja      OUT NUMBER,
        p_tarifa_baja      OUT NUMBER,
        p_subtotal_baja    OUT NUMBER,
        p_noches_alta      OUT NUMBER,
        p_tarifa_alta      OUT NUMBER,
        p_subtotal_alta    OUT NUMBER,
        p_total_estimado   OUT NUMBER
    ) IS
        v_fecha_actual  DATE;
        v_es_alta       NUMBER := 0;
        v_existe_hab    NUMBER := 0;
        v_tarifa_baja   NUMBER(12,2) := 0;
        v_tarifa_alta   NUMBER(12,2) := 0;
    BEGIN
        IF p_fecha_out <= p_fecha_in THEN
            RAISE_APPLICATION_ERROR(
                -20001, 
                'Fechas invalidas: La fecha de check-out (' || TO_CHAR(p_fecha_out, 'DD/MM/YYYY') || 
                ') debe ser estrictamente posterior a la fecha de check-in (' || TO_CHAR(p_fecha_in, 'DD/MM/YYYY') || ').'
            );
        END IF;

        SELECT COUNT(*) INTO v_existe_hab FROM HABITACION WHERE id_habitacion = p_id_habitacion;
        IF v_existe_hab = 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'Habitacion ' || p_id_habitacion || ' no existe en el sistema.');
        END IF;

        BEGIN
            SELECT precio_noche INTO v_tarifa_baja FROM TARIFA WHERE id_habitacion = p_id_habitacion AND id_temporada = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN v_tarifa_baja := 150000;
        END;

        BEGIN
            SELECT precio_noche INTO v_tarifa_alta FROM TARIFA WHERE id_habitacion = p_id_habitacion AND id_temporada = 2;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN v_tarifa_alta := ROUND(v_tarifa_baja * 1.40, -3);
        END;

        p_noches_baja := 0;
        p_noches_alta := 0;
        v_fecha_actual := TRUNC(p_fecha_in);

        WHILE v_fecha_actual < TRUNC(p_fecha_out) LOOP
            SELECT COUNT(*)
            INTO v_es_alta
            FROM PERIODO_TEMPORADA
            WHERE id_temporada = 2
              AND v_fecha_actual BETWEEN fecha_inicio AND fecha_fin;

            IF v_es_alta > 0 THEN
                p_noches_alta := p_noches_alta + 1;
            ELSE
                p_noches_baja := p_noches_baja + 1;
            END IF;

            v_fecha_actual := v_fecha_actual + 1;
        END LOOP;

        p_tarifa_baja    := v_tarifa_baja;
        p_tarifa_alta    := v_tarifa_alta;
        p_subtotal_baja  := p_noches_baja * v_tarifa_baja;
        p_subtotal_alta  := p_noches_alta * v_tarifa_alta;
        p_total_estimado := p_subtotal_baja + p_subtotal_alta;
    END sp_cotizar_desglose;

    -- ------------------------------------------------------------------------
    -- PROCEDIMIENTO 4: sp_registrar_reserva_con_pago (Entrega 3)
    -- ------------------------------------------------------------------------
    PROCEDURE sp_registrar_reserva_con_pago(
        p_id_cliente      IN  NUMBER,
        p_id_habitacion   IN  NUMBER,
        p_fecha_in        IN  DATE,
        p_fecha_out       IN  DATE,
        p_num_huespedes   IN  NUMBER,
        p_metodo_pago     IN  VARCHAR2,
        p_simular_fallo   IN  NUMBER,
        p_id_reserva      OUT NUMBER,
        p_id_pago         OUT NUMBER,
        p_total           OUT NUMBER,
        p_estado_reserva  OUT VARCHAR2,
        p_mensaje         OUT VARCHAR2
    ) IS
        v_id_reserva NUMBER;
        v_total      NUMBER;
        v_metodo     VARCHAR2(30);
    BEGIN
        -- 1. Crear la reserva mediante el procedimiento existente (valida ORA-20001, ORA-20002, ORA-20003)
        sp_crear_reserva(
            p_id_cliente    => p_id_cliente,
            p_id_habitacion => p_id_habitacion,
            p_fecha_in      => p_fecha_in,
            p_fecha_out     => p_fecha_out,
            p_num_huespedes => p_num_huespedes,
            p_id_reserva    => v_id_reserva,
            p_total         => v_total
        );

        p_id_reserva := v_id_reserva;
        p_total      := v_total;

        -- 2. Establecer punto de guardado (SAVEPOINT) antes del cobro financiero
        SAVEPOINT pto_reserva_creada;

        -- 3. Evaluación de flujo de pago: Exitoso vs Fallo simulado
        IF p_simular_fallo = 1 THEN
            -- Simular rechazo de pasarela / fondos insuficientes
            -- Se ejecuta rollback parcial: se deshace el intento de pago
            ROLLBACK TO pto_reserva_creada;

            -- Se actualiza la reserva para conservarla en estado PENDIENTE
            UPDATE RESERVA
            SET ESTADO = 'PENDIENTE'
            WHERE ID_RESERVA = v_id_reserva;

            COMMIT;

            p_id_pago        := NULL;
            p_estado_reserva := 'PENDIENTE';
            p_mensaje        := 'DEMOSTRACIÓN DE ROLLBACK PARCIAL (SAVEPOINT): ' ||
                                'La pasarela rechazó el pago. Se ejecutó ROLLBACK TO pto_reserva_creada. ' ||
                                'La reserva #' || v_id_reserva || ' se conservó en estado PENDIENTE sin perder los datos del huésped.';
        ELSE
            -- Normalizar método de pago para respetar restricción CHK_PAGO_METODO
            -- Valores permitidos: 'PSE', 'TARJETA_CREDITO', 'TARJETA_DEBITO', 'TRANSFERENCIA', 'EFECTIVO'
            v_metodo := UPPER(TRIM(NVL(p_metodo_pago, 'TARJETA_CREDITO')));
            IF v_metodo IN ('TARJETA', 'TC', 'CREDITO') THEN
                v_metodo := 'TARJETA_CREDITO';
            ELSIF v_metodo IN ('TD', 'DEBITO') THEN
                v_metodo := 'TARJETA_DEBITO';
            ELSIF v_metodo NOT IN ('PSE', 'TARJETA_CREDITO', 'TARJETA_DEBITO', 'TRANSFERENCIA', 'EFECTIVO') THEN
                v_metodo := 'TARJETA_CREDITO';
            END IF;

            -- Flujo de cobro exitoso: insertar registro en PAGO
            INSERT INTO PAGO (
                fecha_pago, monto, metodo_pago, estado, id_reserva
            ) VALUES (
                SYSDATE, v_total, v_metodo, 'APROBADO', v_id_reserva
            ) RETURNING id_pago INTO p_id_pago;

            COMMIT;

            p_estado_reserva := 'CONFIRMADA';
            p_mensaje        := 'TRANSACCIÓN ATÓMICA EXITOSA (COMMIT): ' ||
                                'Reserva #' || v_id_reserva || ' confirmada y Pago #' || p_id_pago || 
                                ' registrado por $' || TO_CHAR(v_total, 'FM999,999,999') || ' COP.';
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END sp_registrar_reserva_con_pago;

END PKG_TURISMO_UQ;
/
