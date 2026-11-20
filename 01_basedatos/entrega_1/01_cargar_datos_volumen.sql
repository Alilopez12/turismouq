-- ============================================================================
-- PROYECTO INTEGRADOR: TURISMOUQ - BASES DE DATOS II
-- SCRIPT 00B: CARGA MASIVA IDEMPOTENTE DEL VOLUMEN MÍNIMO EXIGIDO (ENTREGA 1)
-- MOTOR: ORACLE XE 21c (PDB: XEPDB1)
-- ============================================================================
-- Volumen mínimo garantizado:
-- 12 municipios · 60 alojamientos · 400 habitaciones · 3.000 clientes
-- 25.000 reservas (2024-2026) · 40.000 líneas en RESERVA_SERVICIO
-- ============================================================================

BEGIN
    IF SYS_CONTEXT('USERENV', 'SESSION_USER') IN ('SYS', 'SYSTEM') THEN
        EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA = TURISMO_UQ';
    END IF;
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/
SET SERVEROUTPUT ON SIZE UNLIMITED;

DECLARE
    v_existe_datos NUMBER := 0;

    TYPE t_nombres IS VARRAY(12) OF VARCHAR2(60);
    v_municipios t_nombres := t_nombres(
        'Armenia', 'Salento', 'Filandia', 'Circasia',
        'Calarcá', 'Montenegro', 'Quimbaya', 'La Tebaida',
        'Pijao', 'Génova', 'Buenavista', 'Córdoba'
    );

    TYPE t_tipos IS VARRAY(4) OF VARCHAR2(60);
    v_tipos t_tipos := t_tipos('Finca cafetera', 'Glamping', 'Hotel', 'Hostal');

    TYPE t_camas IS VARRAY(4) OF VARCHAR2(50);
    v_camas t_camas := t_camas('Doble King', 'Sencilla Doble', 'Suite Queen', 'Multiple Familiar');

    TYPE t_pnombres IS VARRAY(12) OF VARCHAR2(40);
    v_pnombres t_pnombres := t_pnombres(
        'Sofia', 'Andres', 'Camila', 'Daniel', 'David', 'Maria',
        'Laura', 'Valentina', 'Sebastian', 'Carlos', 'Mariana', 'Juan'
    );

    TYPE t_papellidos IS VARRAY(10) OF VARCHAR2(40);
    v_papellidos t_papellidos := t_papellidos(
        'Perez', 'Gomez', 'Garcia', 'Rodriguez', 'Ramirez',
        'Lopez', 'Torres', 'Quintero', 'Restrepo', 'Cardona'
    );

    TYPE t_metodos IS VARRAY(3) OF VARCHAR2(30);
    v_metodos t_metodos := t_metodos('PSE', 'TARJETA_CREDITO', 'TRANSFERENCIA');

    TYPE t_servicios_nom IS VARRAY(5) OF VARCHAR2(80);
    v_srv_nombres t_servicios_nom := t_servicios_nom(
        'Desayuno Típico Quindiano', 'Tour Cafetero Guiado', 'Acceso Spa y Jacuzzi',
        'Transporte Aeropuerto El Edén', 'Cabalgata Ecológica Valle del Cocora'
    );

    v_id_muni      NUMBER;
    v_id_tipo      NUMBER;
    v_id_prop      NUMBER;
    v_id_aloj      NUMBER;
    v_id_hab       NUMBER;
    v_hab_count    NUMBER := 0;
    v_cap_hab      NUMBER;
    v_tar_baja     NUMBER;
    v_tar_alta     NUMBER;
    v_nom_cli      VARCHAR2(80);

    TYPE t_num_tab IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    TYPE t_date_tab IS TABLE OF DATE INDEX BY PLS_INTEGER;
    TYPE t_var_tab IS TABLE OF VARCHAR2(30) INDEX BY PLS_INTEGER;

    v_res_ids      t_num_tab;
    v_res_ci       t_date_tab;
    v_res_co       t_date_tab;
    v_res_tot      t_num_tab;
    v_res_est      t_var_tab;
    v_res_cli      t_num_tab;
    v_res_hab      t_num_tab;
    v_res_met      t_var_tab;

    v_dia_offset   NUMBER;
    v_noches       NUMBER;
    v_anio_rand    NUMBER;
    v_rand_est     NUMBER;
    v_precio_noche NUMBER;

    v_rs_res       t_num_tab;
    v_rs_srv       t_num_tab;
    v_rs_cnt       t_num_tab;
    v_rs_pru       t_num_tab;
    v_rs_sub       t_num_tab;
    v_rs_idx       NUMBER := 0;
    v_srv_id_1     NUMBER;
    v_srv_id_2     NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe_datos FROM RESERVA;

    IF v_existe_datos >= 25000 THEN
        DBMS_OUTPUT.PUT_LINE('La base ya cuenta con ' || v_existe_datos || ' reservas. Se omite carga inicial.');
        RETURN;
    END IF;

    DBMS_OUTPUT.PUT_LINE('Iniciando carga masiva de datos en TURISMO_UQ...');

    -- 1. Municipios (12)
    FOR i IN 1..12 LOOP
        BEGIN
            INSERT INTO MUNICIPIO (ID_MUNICIPIO, NOMBRE) VALUES (i, v_municipios(i));
        EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
    END LOOP;

    -- 2. Tipos de Alojamiento (4)
    FOR i IN 1..4 LOOP
        BEGIN
            INSERT INTO TIPO_ALOJAMIENTO (ID_TIPO_ALOJAMIENTO, NOMBRE, DESCRIPCION)
            VALUES (i, v_tipos(i), 'Alojamiento turístico en el departamento del Quindío');
        EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
    END LOOP;

    -- 3. Propietarios (20)
    FOR i IN 1..20 LOOP
        BEGIN
            INSERT INTO PROPIETARIO (ID_PROPIETARIO, DOCUMENTO, NOMBRES, TELEFONO, CORREO)
            VALUES (i, 'CC-4000' || LPAD(i, 4, '0'), 'Propietario UQ ' || i,
                    '311' || LPAD(i, 7, '0'), 'prop' || i || '@turismouq.com');
        EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
    END LOOP;

    -- 4. Temporadas base (2)
    BEGIN INSERT INTO TEMPORADA (ID_TEMPORADA, NOMBRE) VALUES (1, 'TEMPORADA BAJA'); EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
    BEGIN INSERT INTO TEMPORADA (ID_TEMPORADA, NOMBRE) VALUES (2, 'TEMPORADA ALTA'); EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;

    -- 5. Alojamientos (60) + Servicios (300) + Habitaciones (400) + Tarifas (800)
    FOR i IN 1..60 LOOP
        v_id_muni := MOD(i - 1, 12) + 1;
        v_id_tipo := MOD(i - 1, 4) + 1;
        v_id_prop := MOD(i - 1, 20) + 1;

        BEGIN
            INSERT INTO ALOJAMIENTO (ID_ALOJAMIENTO, NOMBRE, DIRECCION, TELEFONO, CAPACIDAD, ID_MUNICIPIO, ID_TIPO_ALOJAMIENTO, ID_PROPIETARIO)
            VALUES (i, 'Alojamiento Turistico UQ ' || i, 'Vereda Central Km ' || i,
                    '312' || LPAD(i, 7, '0'), 24, v_id_muni, v_id_tipo, v_id_prop);
        EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;

        -- 5 servicios por alojamiento = 300 servicios
        FOR s IN 1..5 LOOP
            BEGIN
                INSERT INTO SERVICIO (ID_SERVICIO, NOMBRES, PRECIO, ID_ALOJAMIENTO)
                VALUES (((i - 1) * 5) + s, v_srv_nombres(s), 25000 + (s * 15000), i);
            EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
        END LOOP;

        -- Primeros 40 alojamientos tienen 7 habitaciones (280), últimos 20 tienen 6 (120) => Total exacto = 400
        FOR h IN 1..(CASE WHEN i <= 40 THEN 7 ELSE 6 END) LOOP
            v_hab_count := v_hab_count + 1;
            v_cap_hab := MOD(v_hab_count, 4) + 2; -- 2 a 5 personas
            BEGIN
                INSERT INTO HABITACION (ID_HABITACION, NUMERO_NOMBRE, CAPACIDAD, TIPO_CAMA, ID_ALOJAMIENTO)
                VALUES (v_hab_count, 'Habitacion ' || (100 + h), v_cap_hab, v_camas(MOD(v_hab_count, 4) + 1), i);
            EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;

            v_tar_baja := 130000 + (MOD(v_hab_count, 10) * 15000);
            v_tar_alta := ROUND(v_tar_baja * 1.45, -3);
            BEGIN INSERT INTO TARIFA (PRECIO_NOCHE, ID_TEMPORADA, ID_HABITACION) VALUES (v_tar_baja, 1, v_hab_count); EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
            BEGIN INSERT INTO TARIFA (PRECIO_NOCHE, ID_TEMPORADA, ID_HABITACION) VALUES (v_tar_alta, 2, v_hab_count); EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL; END;
        END LOOP;
    END LOOP;

    -- 6. Clientes (3.000)
    FOR c IN 1..3000 LOOP
        IF c = 1 THEN
            v_nom_cli := 'Carlos Andres';
        ELSIF c = 2 THEN
            v_nom_cli := 'Carlos Eduardo';
        ELSE
            v_nom_cli := v_pnombres(MOD(c - 1, 12) + 1);
        END IF;

        INSERT INTO CLIENTE (DOCUMENTO, NOMBRES, APELLIDOS, TELEFONO, CORREO)
        VALUES (
            '1000' || LPAD(c, 6, '0'),
            v_nom_cli,
            v_papellidos(MOD(c - 1, 10) + 1),
            '300' || LPAD(c, 7, '0'),
            'cliente' || c || '@turismouq.com'
        );
    END LOOP;
    COMMIT;

    -- 7. Preparar y cargar 25.000 Reservas repartidas entre 2024 y 2026
    FOR r IN 1..25000 LOOP
        v_anio_rand := MOD(r, 3); -- 0: 2024, 1: 2025, 2: 2026
        -- Concentrar más reservas en meses pico (Mar/Abr, Jun/Jul, Dic)
        IF MOD(r, 5) IN (0, 1) THEN
            v_dia_offset := CASE MOD(r, 3)
                WHEN 0 THEN TRUNC(DBMS_RANDOM.VALUE(165, 200)) -- Mitad de año
                WHEN 1 THEN TRUNC(DBMS_RANDOM.VALUE(348, 364)) -- Diciembre
                ELSE TRUNC(DBMS_RANDOM.VALUE(82, 105))         -- Semana Santa
            END;
        ELSE
            v_dia_offset := TRUNC(DBMS_RANDOM.VALUE(0, 360));
        END IF;

        v_res_ci(r) := TO_DATE((2024 + v_anio_rand) || '-01-01', 'YYYY-MM-DD') + v_dia_offset;
        v_noches := TRUNC(DBMS_RANDOM.VALUE(2, 6));
        v_res_co(r) := v_res_ci(r) + v_noches;
        v_res_hab(r) := TRUNC(DBMS_RANDOM.VALUE(1, 401));
        IF v_res_hab(r) > 400 THEN v_res_hab(r) := 400; END IF;
        v_res_cli(r) := TRUNC(DBMS_RANDOM.VALUE(1, 3001));
        IF v_res_cli(r) > 3000 THEN v_res_cli(r) := 3000; END IF;

        v_precio_noche := 160000 + (MOD(v_res_hab(r), 8) * 20000);
        v_res_tot(r) := v_noches * v_precio_noche;
        v_res_met(r) := v_metodos(MOD(r, 3) + 1);

        v_rand_est := MOD(r, 100);
        IF r <= 10 THEN
            v_res_est(r) := 'PENDIENTE';
        ELSIF v_rand_est < 8 THEN
            v_res_est(r) := 'CANCELADA';
        ELSIF v_anio_rand = 2 AND v_dia_offset > 300 THEN
            v_res_est(r) := 'CONFIRMADA';
        ELSE
            v_res_est(r) := 'FINALIZADA';
        END IF;
    END LOOP;

    FORALL r IN 1..25000
        INSERT INTO RESERVA (FECHA_CREACION, FECHA_CHECK_IN, FECHA_CHECK_OUT, TOTAL, ESTADO, ID_CLIENTE)
        VALUES (v_res_ci(r) - 10, v_res_ci(r), v_res_co(r), v_res_tot(r), v_res_est(r), v_res_cli(r))
        RETURNING ID_RESERVA BULK COLLECT INTO v_res_ids;

    FORALL r IN 1..25000
        INSERT INTO RESERVA_HABITACION (ID_RESERVA, ID_HABITACION, PRECIO_UNITARIO, SUBTOTAL)
        VALUES (v_res_ids(r), v_res_hab(r), v_res_tot(r), v_res_tot(r));

    FORALL r IN 1..25000
        INSERT INTO PAGO (FECHA_PAGO, MONTO, METODO_PAGO, ESTADO, ID_RESERVA)
        VALUES (v_res_ci(r) - 5, v_res_tot(r), v_res_met(r),
                CASE WHEN v_res_est(r) = 'PENDIENTE' THEN 'PENDIENTE' ELSE 'APROBADO' END,
                v_res_ids(r));

    -- 8. Cargar 40.000 líneas en RESERVA_SERVICIO (2 servicios por cada una de las primeras 20.000 reservas)
    FOR r IN 1..20000 LOOP
        v_srv_id_1 := MOD((r * 2), 300) + 1;
        v_srv_id_2 := MOD((r * 2) + 1, 300) + 1;
        IF v_srv_id_2 = v_srv_id_1 THEN v_srv_id_2 := MOD(v_srv_id_1, 300) + 1; END IF;

        v_rs_idx := v_rs_idx + 1;
        v_rs_res(v_rs_idx) := v_res_ids(r);
        v_rs_srv(v_rs_idx) := v_srv_id_1;
        v_rs_cnt(v_rs_idx) := 1;
        v_rs_pru(v_rs_idx) := 45000;
        v_rs_sub(v_rs_idx) := 45000;

        v_rs_idx := v_rs_idx + 1;
        v_rs_res(v_rs_idx) := v_res_ids(r);
        v_rs_srv(v_rs_idx) := v_srv_id_2;
        v_rs_cnt(v_rs_idx) := 2;
        v_rs_pru(v_rs_idx) := 35000;
        v_rs_sub(v_rs_idx) := 70000;
    END LOOP;

    FORALL i IN 1..40000
        INSERT INTO RESERVA_SERVICIO (ID_RESERVA, ID_SERVICIO, CANTIDAD, PRECIO_UNITARIO, SUBTOTAL)
        VALUES (v_rs_res(i), v_rs_srv(i), v_rs_cnt(i), v_rs_pru(i), v_rs_sub(i));

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Carga masiva completada: 12 municipios, 60 alojamientos, 400 habitaciones, 3.000 clientes, 25.000 reservas, 40.000 reserva_servicio.');
END;
/
