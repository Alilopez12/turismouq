# GUÍA DE SUSTENTACIÓN: ENTREGA 2 Y TABLESPACE (ENTREGA 1)
## Proyecto Integrador: TurismoUQ · Plataforma de Reservas Turísticas del Quindío
**Asignatura:** Bases de Datos II (Código 12338) · Facultad de Ingeniería · Universidad del Quindío  
**Motor de Base de Datos:** Oracle Database 21c Express Edition (PDB: `XEPDB1`, Esquema: `TURISMO_UQ`)  
**Documento Base:** *Proyecto Integrador BDII - TurismoUQ.pdf* (Enunciado Oficial de Cátedra)

---

## 📌 ALINEACIÓN CON EL ENUNCIADO OFICIAL DEL PROFESOR

En la página 1 del enunciado oficial se establece la regla de oro de la asignatura:

> *"Ustedes no construyen la interfaz: el entregable es la base de datos — el modelo, la lógica que vive dentro del motor y su administración. Todo sobre Oracle XE 21c instalado localmente."*

Este documento se enfoca **exclusivamente en los dos pilares evaluables solicitados**:
1. **Tablespace propio para el histórico de reservas** (Requisito de infraestructura de la **Entrega 1**).
2. **Capa PL/SQL completa** (**Entrega 2 - 30% de la nota final**):
   - Función `fn_valor_estadia` (cálculo noche a noche cruzando temporadas).
   - Procedimiento `sp_crear_reserva` con excepciones personalizadas (`ORA-20001`, `ORA-20002`, `ORA-20003`).
   - Cursor explícito parametrizado para proceso masivo: `sp_liquidacion_mensual_alojamiento`.
   - Agrupación modular en el paquete `PKG_TURISMO_UQ`.
   - Disparador a nivel de sentencia: auditoría de cambios sobre `TARIFA`.
   - Disparador a nivel de fila: anti-solapamiento de reservas en la misma habitación.
3. **Defensa de las 2 decisiones de diseño obligatorias** exigidas en la sección 2 del PDF.

---

# 1. LAS DOS DECISIONES DE DISEÑO EXIGIDAS EN EL PDF

En la Sección 2 (*Modelo mínimo*), el profesor advierte explícitamente:
> *"Dos decisiones de diseño que van a tener que defender: cómo modelan que una reserva tome varias habitaciones, y cómo modelan que una estadía atraviese dos temporadas con tarifas distintas."*

Estas son las respuestas exactas con las que deben defender su diseño:

### Decisión 1: ¿Cómo modelan que una reserva tome varias habitaciones?
- **Modelo Relacional:** Se implementó la entidad asociativa **`RESERVA_HABITACION`** que rompe la relación muchos a muchos ($M:N$) entre `RESERVA` y `HABITACION`.
- **Estructura de la tabla:**
  ```sql
  CREATE TABLE RESERVA_HABITACION (
      ID_RESERVA      NUMBER NOT NULL,
      ID_HABITACION   NUMBER NOT NULL,
      PRECIO_UNITARIO NUMBER(12,2) NOT NULL,
      SUBTOTAL        NUMBER(14,2) NOT NULL,
      CONSTRAINT PK_RESERVA_HABITACION PRIMARY KEY (ID_RESERVA, ID_HABITACION),
      CONSTRAINT FK_RESHAB_RESERVA FOREIGN KEY (ID_RESERVA) REFERENCES RESERVA(ID_RESERVA) ON DELETE CASCADE,
      CONSTRAINT FK_RESHAB_HABITACION FOREIGN KEY (ID_HABITACION) REFERENCES HABITACION(ID_HABITACION)
  ) TABLESPACE TBS_HISTORICO_RESERVAS;
  ```
- **Defensa Técnica:** Una sola cabecera de reserva (`RESERVA`) alberga los datos globales (cliente, fecha de creación, estado, total consolidado). En `RESERVA_HABITACION`, una reserva puede contener $1, 2, \dots, N$ habitaciones reservadas, cada una congelando su precio unitario y subtotal al momento de la compra. Si las habitaciones cambian de tarifa en el futuro, el subtotal histórico de la reserva se mantiene inmutable.

---

### Decisión 2: ¿Cómo modelan que una estadía atraviese dos temporadas con tarifas distintas?
- **Modelo Relacional:** Se desacoplaron las tablas `TEMPORADA`, `PERIODO_TEMPORADA` y `TARIFA`:
  1. `TEMPORADA`: Define los 2 conceptos de negocio: **Temporada Baja (ID: 1)** y **Temporada Alta (ID: 2)**.
  2. `PERIODO_TEMPORADA`: Define los rangos de fechas del calendario civil donde aplica la Temporada Alta (Semana Santa, vacaciones de mitad de año y fin de año para 2024, 2025 y 2026).
  3. `TARIFA`: Contiene el precio por noche para cada habitación en cada temporada (`UK_TARIFA_HAB_TEMP UNIQUE (ID_HABITACION, ID_TEMPORADA)`).
- **Lógica en el Motor:** La función `fn_valor_estadia` **no realiza una multiplicación plana** (`noches * tarifa`). En su lugar, ejecuta un **bucle iterativo fecha por fecha** (`WHILE v_fecha_actual < p_fecha_out`):
  - Para cada noche, consulta si esa fecha específica está comprendida en algún registro de `PERIODO_TEMPORADA` con `id_temporada = 2`.
  - Si coincide, suma el valor de la tarifa alta; de lo contrario, suma la tarifa baja.
- **Defensa Técnica:** Esto permite que si un turista reserva del 21 al 26 de marzo de 2024, las noches del 21 y 22 se facturen a tarifa baja, y las noches del 23, 24 y 25 (inicio de Semana Santa) se liquiden automáticamente a tarifa alta, garantizando precisión contable al centavo.

---

# 2. TABLESPACE DEDICADO: TBS_HISTORICO_RESERVAS (ENTREGA 1)

### Requisito del PDF:
> *"Un tablespace propio para el histórico de reservas, con la justificación de por qué separarlo."*

### Ubicación del Script:
- **Ruta:** `01_basedatos/entrega_1/01_tablespace_historico.sql` (Líneas 31 a 125).

### Código DDL Implementado:
```sql
ALTER SESSION SET CONTAINER = XEPDB1;

-- 1. Creación del Tablespace Dedicado
CREATE TABLESPACE TBS_HISTORICO_RESERVAS
DATAFILE 'C:\APP\DELL\PRODUCT\21C\ORADATA\XE\XEPDB1\TBS_HISTORICO_RESERVAS01.DBF'
SIZE 50M
AUTOEXTEND ON NEXT 10M MAXSIZE 2G
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;

-- 2. Asignación de cuota ilimitada al esquema
ALTER USER TURISMO_UQ QUOTA UNLIMITED ON TBS_HISTORICO_RESERVAS;

-- 3. Creación de tablas históricas en el nuevo tablespace
CREATE TABLE HISTORICO_RESERVA (...) TABLESPACE TBS_HISTORICO_RESERVAS;
CREATE TABLE HISTORICO_RESERVA_HABITACION (...) TABLESPACE TBS_HISTORICO_RESERVAS;

-- 4. Segregación física de tablas transaccionales masivas
ALTER TABLE RESERVA MOVE TABLESPACE TBS_HISTORICO_RESERVAS;
ALTER TABLE RESERVA_HABITACION MOVE TABLESPACE TBS_HISTORICO_RESERVAS;
ALTER TABLE RESERVA_SERVICIO MOVE TABLESPACE TBS_HISTORICO_RESERVAS;
ALTER TABLE PAGO MOVE TABLESPACE TBS_HISTORICO_RESERVAS;
ALTER TABLE LIQUIDACION_MENSUAL MOVE TABLESPACE TBS_HISTORICO_RESERVAS;

-- 5. Reconstrucción obligatoria de índices
ALTER INDEX PK_RESERVA REBUILD TABLESPACE TBS_HISTORICO_RESERVAS;
ALTER INDEX IDX_RESHAB_RESERVA REBUILD TABLESPACE TBS_HISTORICO_RESERVAS;
ALTER INDEX IDX_RESERVA_CHECKIN REBUILD TABLESPACE TBS_HISTORICO_RESERVAS;
```

---

### Los 3 Argumentos de Justificación que Exige el Profesor:

```
+-----------------------------------------------------------------------------------+
|               ARQUITECTURA DE SEGREGACIÓN FÍSICA EN ORACLE 21c                    |
+-----------------------------------------------------------------------------------+
|  TABLESPACE: USERS (users01.dbf)         |  TABLESPACE: TBS_HISTORICO_RESERVAS     |
|  - Catálogos Maestros y Configuración   |  - Transacciones Masivas & Históricos   |
|  - ALOJAMIENTO, HABITACION, CLIENTE,    |  - RESERVA (25.000 filas)               |
|    MUNICIPIO, TARIFA, TEMPORADA          |  - RESERVA_HABITACION, RESERVA_SERVICIO |
|  - Operatividad: READ WRITE continuo    |  - PAGO, LIQUIDACION_MENSUAL            |
|  - Backup RMAN: Incremental diario      |  - Backup RMAN: Modo READ ONLY cerrado  |
+-----------------------------------------------------------------------------------+
```

#### 1. Aislamiento Físico de I/O y Concurrencia (OLTP vs. OLAP)
- **Problema:** En el volumen mínimo exigido (25.000 reservas y 40.000 consumos), las operaciones DML transaccionales (`INSERT`, `UPDATE`, `SELECT FOR UPDATE`) compiten permanentemente por los mismos bloques de datos y el mismo espacio en el *Buffer Cache* (SGA).
- **Solución:** Al mover las tablas transaccionales a un archivo de datos físico independiente (`.DBF`), las consultas analíticas pesadas (como `PIVOT`, `ROLLUP` o el reporte de liquidaciones) leen bloques del disco sin competir con las transacciones concurrentes sobre los catálogos maestros (`ALOJAMIENTO`, `CLIENTE`, `HABITACION`) ubicados en `USERS`.

#### 2. Políticas Diferenciadas de Backup & Recuperación con Oracle RMAN
- **Problema:** Respaldar diariamente toda la base de datos con decenas de miles de registros históricos cerrados incrementa innecesariamente el consumo de cinta/disco y satura la ventana horaria nocturna de backup.
- **Solución:** Los períodos anuales cerrados (por ejemplo vigencias 2024 o 2025) pueden sellarse en Oracle mediante:
  ```sql
  ALTER TABLESPACE TBS_HISTORICO_RESERVAS READ ONLY;
  ```
  Al estar en modo de solo lectura, Oracle RMAN detecta que los bloques del datafile no han cambiado y **omite el tablespace de las copias de seguridad incrementales diarias**. Solo se respalda una vez, acortando la ventana de backup hasta en un 80%.

#### 3. Ciclo de Vida de la Información (ILM) y Compresión Avanzada
- Permite aplicar compresión relacional avanzada (`COMPRESS FOR OLTP` o `QUERY HIGH`) exclusivamente sobre el datafile de histórico de reservas, logrando reducciones de almacenamiento físico de hasta un 70%. Además, permite que el administrador reubique físicamente el archivo `.DBF` hacia discos de almacenamiento masivo secundario (NAS/SAN) de menor costo, reservando los discos SSD de alta velocidad para el tablespace maestro `USERS`.

---

### ¿Por qué fue obligatorio ejecutar `REBUILD` en los índices? (Pregunta Típica)
Cuando se ejecuta `ALTER TABLE ... MOVE TABLESPACE`, Oracle traslada físicamente las filas a nuevos bloques de datos en el nuevo archivo. Como los índices B-Tree almacenan pares de `(Clave, ROWID)`, y el **ROWID** representa la dirección física del bloque y la fila, todos los índices existentes quedan apuntando a ubicaciones inexistentes y Oracle los marca automáticamente en estado **`UNUSABLE`**.  
El comando `ALTER INDEX ... REBUILD TABLESPACE TBS_HISTORICO_RESERVAS` realiza un escaneo de la tabla en su nueva ubicación, recalcula los árboles B-Tree con los nuevos ROWIDs y los devuelve al estado **`VALID`**.

---

# 3. ENTREGA 2: CAPA PL/SQL (30% DE LA CALIFICACIÓN)

---

## 3.1 Función `fn_valor_estadia` (Cálculo Noche a Noche)

### Requisito del PDF:
> *"fn_valor_estadia(id_habitacion, fecha_in, fecha_out): calcula el valor aplicando la tarifa de cada temporada que atraviese la estadía. Es la función más difícil del proyecto."*

### Ubicación del Código:
- **Especificación:** `01_basedatos/entrega_2/04_paquete_turismo_espec.sql` (Líneas 40 a 50).
- **Cuerpo:** `01_basedatos/entrega_2/05_paquete_turismo_cuerpo.sql` (Líneas 14 a 87).

### Código PL/SQL Completo:
```sql
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
    -- 1. Validación de coherencia de fechas (ORA-20001)
    IF p_fecha_out <= p_fecha_in THEN
        RAISE_APPLICATION_ERROR(
            -20001, 
            'Fechas invalidas: La fecha de check-out (' || TO_CHAR(p_fecha_out, 'DD/MM/YYYY') || 
            ') debe ser estrictamente posterior a la fecha de check-in (' || TO_CHAR(p_fecha_in, 'DD/MM/YYYY') || ').'
        );
    END IF;

    -- 2. Validación de existencia de la habitación (ORA-20004)
    SELECT COUNT(*) INTO v_existe_hab FROM HABITACION WHERE id_habitacion = p_id_habitacion;
    IF v_existe_hab = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Habitacion ' || p_id_habitacion || ' no existe en el sistema.');
    END IF;

    -- 3. Obtención de tarifas configuradas para la habitación
    BEGIN
        SELECT precio_noche INTO v_tarifa_baja 
        FROM TARIFA WHERE id_habitacion = p_id_habitacion AND id_temporada = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN v_tarifa_baja := 150000;
    END;

    BEGIN
        SELECT precio_noche INTO v_tarifa_alta 
        FROM TARIFA WHERE id_habitacion = p_id_habitacion AND id_temporada = 2;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN v_tarifa_alta := ROUND(v_tarifa_baja * 1.40, -3);
    END;

    -- 4. Bucle noche a noche: Determina dinámicamente si cada jornada cruza temporada alta
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
```

---

## 3.2 Procedimiento `sp_crear_reserva` con Excepciones Propias

### Requisito del PDF:
> *"sp_crear_reserva: con excepciones propias vía RAISE_APPLICATION_ERROR para habitación no disponible, checkout anterior o igual al checkin, y capacidad excedida."*

### Códigos de Error Reservados y Controlados:
| Código Oracle | Causa de la Excepción | Regla de Negocio Evaluada |
| :--- | :--- | :--- |
| **`ORA-20001`** | **Fechas Inválidas** | `p_fecha_out <= p_fecha_in`. El checkout debe ser posterior al checkin. |
| **`ORA-20002`** | **Habitación No Disponible** | Conflicto de solapamiento temporal con una reserva activa previa. |
| **`ORA-20003`** | **Capacidad Excedida** | `p_num_huespedes > v_capacidad` o `p_num_huespedes <= 0`. |
| **`ORA-20004`** | **Entidad Inexistente** | El `id_cliente` o `id_habitacion` no existen en la base de datos. |

### Ubicación del Código:
- **Cuerpo:** `01_basedatos/entrega_2/05_paquete_turismo_cuerpo.sql` (Líneas 92 a 202).

### Código PL/SQL Completo:
```sql
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
        RAISE_APPLICATION_ERROR(-20001, 'Regla de negocio infringida: La fecha de check-out debe ser posterior al check-in.');
    END IF;

    -- 2. Validación de cliente existente
    SELECT COUNT(*) INTO v_cliente_ok FROM CLIENTE WHERE id_cliente = p_id_cliente;
    IF v_cliente_ok = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Cliente no registrado: ID ' || p_id_cliente || ' no existe.');
    END IF;

    -- 3. Validación de capacidad de la habitación (ORA-20003)
    BEGIN
        SELECT capacidad INTO v_capacidad FROM HABITACION WHERE id_habitacion = p_id_habitacion;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20004, 'Habitacion no encontrada: ID ' || p_id_habitacion);
    END;

    IF p_num_huespedes > v_capacidad THEN
        RAISE_APPLICATION_ERROR(-20003, 'Capacidad excedida: El numero de huespedes (' || p_num_huespedes || ') supera el maximo (' || v_capacidad || ').');
    END IF;
    IF p_num_huespedes <= 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'El numero de personas debe ser al menos 1.');
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

    -- 5. Cálculo exacto del total invocando la función interna
    p_total := fn_valor_estadia(p_id_habitacion, p_fecha_in, p_fecha_out);

    -- 6. Inserción atómica en RESERVA
    INSERT INTO RESERVA (
        fecha_creacion, fecha_check_in, fecha_check_out, total, estado, id_cliente
    ) VALUES (
        SYSDATE, TRUNC(p_fecha_in), TRUNC(p_fecha_out), p_total, 'CONFIRMADA', p_id_cliente
    ) RETURNING id_reserva INTO p_id_reserva;

    -- 7. Inserción en RESERVA_HABITACION
    INSERT INTO RESERVA_HABITACION (
        id_reserva, id_habitacion, precio_unitario, subtotal
    ) VALUES (
        p_id_reserva, p_id_habitacion, p_total, p_total
    );

END sp_crear_reserva;
```

---

## 3.3 Cursor Explícito Parametrizado para Proceso Masivo

### Requisito del PDF:
> *"Un cursor explícito con parámetros para un proceso masivo: la liquidación mensual por alojamiento."*

### Ubicación del Código:
- **Cuerpo:** `01_basedatos/entrega_2/05_paquete_turismo_cuerpo.sql` (Líneas 208 a 305).

### Código PL/SQL Completo:
```sql
PROCEDURE sp_liquidacion_mensual_alojamiento(
    p_mes              IN  NUMBER,
    p_anio             IN  NUMBER,
    p_id_alojamiento   IN  NUMBER DEFAULT NULL,
    p_total_procesados OUT NUMBER
) IS
    -- DECLARACIÓN FORMAL DEL CURSOR EXPLÍCITO CON 3 PARÁMETROS
    CURSOR cur_liquidar(
        c_alojamiento NUMBER, 
        c_mes         NUMBER, 
        c_anio        NUMBER
    ) IS
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

    v_reg         cur_liquidar%ROWTYPE;
    v_total_bruto NUMBER(14,2);
    v_comision    NUMBER(14,2);
    v_pago_neto   NUMBER(14,2);
    v_contador    NUMBER := 0;
BEGIN
    -- Limpieza previa para garantizar idempotencia al reprocesar
    IF p_id_alojamiento IS NULL THEN
        DELETE FROM LIQUIDACION_MENSUAL WHERE mes = p_mes AND anio = p_anio;
    ELSE
        DELETE FROM LIQUIDACION_MENSUAL WHERE mes = p_mes AND anio = p_anio AND id_alojamiento = p_id_alojamiento;
    END IF;

    -- CICLO DE VIDA DEL CURSOR EXPLÍCITO: OPEN -> FETCH -> CLOSE
    OPEN cur_liquidar(p_id_alojamiento, p_mes, p_anio);
    LOOP
        FETCH cur_liquidar INTO v_reg;
        EXIT WHEN cur_liquidar%NOTFOUND;

        v_total_bruto := v_reg.total_hospedaje + v_reg.total_servicios;
        v_comision    := ROUND(v_total_bruto * 0.10, 2); -- 10% de intermediación TurismoUQ
        v_pago_neto   := v_total_bruto - v_comision;

        INSERT INTO LIQUIDACION_MENSUAL (
            id_alojamiento, nombre_alojamiento, municipio, propietario,
            mes, anio, total_reservas, ingresos_hospedaje, ingresos_servicios,
            total_bruto, comision_plataforma, pago_neto_propietario, fecha_liquidacion
        ) VALUES (
            v_reg.id_alojamiento, v_reg.nombre_alojamiento, v_reg.nombre_municipio, v_reg.nombre_propietario,
            p_mes, p_anio, v_reg.total_reservas, v_reg.total_hospedaje, v_reg.total_servicios,
            v_total_bruto, v_comision, v_pago_neto, SYSDATE
        );

        v_contador := v_contador + 1;
    END LOOP;
    CLOSE cur_liquidar;

    p_total_procesados := v_contador;
END sp_liquidacion_mensual_alojamiento;
```

---

## 3.4 Agrupación en Paquete PL/SQL (`PKG_TURISMO_UQ`)

### Requisito del PDF:
> *"Todo agrupado en un paquete."*

### Justificación de Ingeniería para Sustentar:
1. **Encapsulamiento y Modularidad:** La especificación (`PACKAGE`) actúa como contrato público (interfaz), mientras que el cuerpo (`PACKAGE BODY`) oculta los detalles de implementación de las consultas y algoritmos.
2. **Rendimiento de Memoria (Shared Pool):** La primera vez que se invoca cualquier miembro del paquete, Oracle carga todo el paquete compilado en la **Library Cache** de la SGA. Las siguientes llamadas a la función o procedimientos no requieren análisis sintáctico (*parsing*) ni I/O adicional.
3. **Gestión de Seguridad y Privilegios:** En lugar de otorgar permisos objeto por objeto (`GRANT EXECUTE ON fn_valor_estadia...`, `GRANT EXECUTE ON sp_crear_reserva...`), se concede un único permiso atómico:
   ```sql
   GRANT EXECUTE ON PKG_TURISMO_UQ TO rol_usuario;
   ```
4. **Mantenibilidad:** Si se modifica el cuerpo del paquete (`05_paquete_turismo_cuerpo.sql`), los objetos dependientes no quedan en estado `INVALID` siempre que la especificación pública no cambie.

---

## 3.5 Disparador a Nivel de Sentencia: Auditoría sobre TARIFA

### Requisito del PDF:
> *"Disparador a nivel de sentencia: auditoría de cambios sobre TARIFA (quién, cuándo, valor anterior y nuevo)."*

### Ubicación del Código:
- **Ruta:** `01_basedatos/entrega_2/02_auditoria_tarifa.sql` (Líneas 47 a 153).

### Tablas de Soporte Creadas:
1. `AUDITORIA_TARIFA`: Guarda la pista de auditoría detallada fila por fila (`id_tarifa`, `precio_anterior`, `precio_nuevo`, `usuario_oracle`, `fecha_accion`, `tipo_operacion`).
2. `LOG_SENTENCIA_TARIFA`: Guarda el registro consolidado de la sentencia DML ejecutada (`usuario_oracle`, `fecha_accion`, `tipo_operacion`, `filas_afectadas`).

### Código del Compound Trigger:
```sql
CREATE OR REPLACE TRIGGER TRG_AUDITORIA_TARIFA_STMT
FOR INSERT OR UPDATE OR DELETE ON TARIFA
COMPOUND TRIGGER

    TYPE t_id_tarifa IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    TYPE t_precio IS TABLE OF NUMBER(12,2) INDEX BY PLS_INTEGER;
    
    v_ids_tarifa     t_id_tarifa;
    v_precios_ant    t_precio;
    v_precios_nue    t_precio;
    v_idx            PLS_INTEGER := 0;
    v_tipo_op        VARCHAR2(20);

    BEFORE STATEMENT IS
    BEGIN
        v_idx := 0;
        v_ids_tarifa.DELETE;
        v_precios_ant.DELETE;
        v_precios_nue.DELETE;
        IF INSERTING THEN v_tipo_op := 'INSERT';
        ELSIF UPDATING THEN v_tipo_op := 'UPDATE';
        ELSIF DELETING THEN v_tipo_op := 'DELETE'; END IF;
    END BEFORE STATEMENT;

    AFTER EACH ROW IS
    BEGIN
        v_idx := v_idx + 1;
        v_ids_tarifa(v_idx)  := NVL(:NEW.id_tarifa, :OLD.id_tarifa);
        v_precios_ant(v_idx) := :OLD.precio_noche;
        v_precios_nue(v_idx) := :NEW.precio_noche;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
    BEGIN
        -- Inserta en lote las filas auditadas
        FOR i IN 1..v_idx LOOP
            INSERT INTO AUDITORIA_TARIFA (
                id_tarifa, precio_anterior, precio_nuevo, usuario_oracle, fecha_accion, tipo_operacion
            ) VALUES (
                v_ids_tarifa(i), v_precios_ant(i), v_precios_nue(i), USER, SYSDATE, v_tipo_op
            );
        END LOOP;

        -- Inserta el log de sentencia única con el total de filas afectadas
        INSERT INTO LOG_SENTENCIA_TARIFA (
            usuario_oracle, fecha_accion, tipo_operacion, filas_afectadas
        ) VALUES (
            USER, SYSDATE, v_tipo_op, v_idx
        );
    END AFTER STATEMENT;

END TRG_AUDITORIA_TARIFA_STMT;
/
```

---

## 3.6 Disparador Anti-Solapamiento (Evitando la Tabla Mutante)

### Requisito del PDF:
> *"Disparador a nivel de fila: impedir que se registre una reserva que se solape con otra de la misma habitación."*

### Ubicación del Código:
- **Ruta:** `01_basedatos/entrega_2/03_trigger_solapamiento.sql` (Líneas 9 a 84).

### ¿Por qué ocurre el error ORA-04091 y cómo se soluciona?
Si se crea un trigger simple `BEFORE INSERT ON RESERVA_HABITACION FOR EACH ROW` e intenta consultar `RESERVA_HABITACION`, Oracle detiene la transacción con:  
**`ORA-04091: table TURISMO_UQ.RESERVA_HABITACION is mutating, trigger/function may not see it`**.  
Esto sucede porque la tabla está en mitad del proceso de modificación física de bloques y su lectura no es consistente.

### La Solución con Compound Trigger:
```sql
CREATE OR REPLACE TRIGGER TRG_IMPEDIR_SOLAPAMIENTO_RES
FOR INSERT OR UPDATE ON RESERVA_HABITACION
COMPOUND TRIGGER

    TYPE t_solicitud IS RECORD (id_reserva NUMBER, id_habitacion NUMBER);
    TYPE t_solicitudes IS TABLE OF t_solicitud INDEX BY PLS_INTEGER;
    v_solicitudes t_solicitudes;
    v_total       PLS_INTEGER := 0;

    BEFORE STATEMENT IS
    BEGIN
        v_total := 0;
        v_solicitudes.DELETE;
    END BEFORE STATEMENT;

    -- En la fila solo almacenamos en memoria RAM (PGA)
    BEFORE EACH ROW IS
    BEGIN
        v_total := v_total + 1;
        v_solicitudes(v_total).id_reserva    := :NEW.id_reserva;
        v_solicitudes(v_total).id_habitacion := :NEW.id_habitacion;
    END BEFORE EACH ROW;

    -- En la sentencia la tabla YA NO ESTÁ MUTANDO: se consulta con total seguridad
    AFTER STATEMENT IS
        v_check_in   DATE;
        v_check_out  DATE;
        v_estado     VARCHAR2(25);
        v_solapados  NUMBER := 0;
        v_conflicto  NUMBER;
    BEGIN
        FOR i IN 1..v_total LOOP
            SELECT fecha_check_in, fecha_check_out, estado
            INTO v_check_in, v_check_out, v_estado
            FROM RESERVA
            WHERE id_reserva = v_solicitudes(i).id_reserva;

            IF v_estado = 'CANCELADA' THEN CONTINUE; END IF;

            -- Fórmula matemática de solapamiento de intervalos cerrados:
            -- (check_in_existente < check_out_nuevo) Y (check_out_existente > check_in_nuevo)
            SELECT COUNT(*), NVL(MAX(r.id_reserva), 0)
            INTO v_solapados, v_conflicto
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
                    ' ya tiene una reserva activa (Reserva #' || v_conflicto || 
                    ') que se cruza con las fechas solicitadas.'
                );
            END IF;
        END LOOP;
    END AFTER STATEMENT;

END TRG_IMPEDIR_SOLAPAMIENTO_RES;
/
```

---

# 4. DEMOSTRACIÓN EN VIVO (SQL DEVELOPER / SQL*PLUS)

Para la sustentación presencial de 20 minutos, tengan listos estos bloques anónimos en **SQL Developer**. Pueden copiarse y ejecutarse en vivo para demostrar cada punto:

```sql
SET SERVEROUTPUT ON SIZE UNLIMITED;
ALTER SESSION SET CURRENT_SCHEMA = TURISMO_UQ;
```

---

### Demo 1: Inspeccionar el Tablespace Dedicado (Entrega 1)
```sql
-- Verificar estado del Tablespace y Datafile
SELECT tablespace_name, status, extent_management, allocation_type, segment_space_management
FROM user_tablespaces
WHERE tablespace_name = 'TBS_HISTORICO_RESERVAS';

-- Verificar tablas segregadas físicamente
SELECT table_name, tablespace_name, num_rows
FROM user_tables
WHERE tablespace_name = 'TBS_HISTORICO_RESERVAS'
ORDER BY table_name;
```

---

### Demo 2: Probar `fn_valor_estadia` cruzando dos temporadas
```sql
DECLARE
    v_total NUMBER;
BEGIN
    -- Noches 21 y 22 de marzo 2024: Temporada Baja
    -- Noches 23, 24 y 25 de marzo 2024: Temporada Alta (Semana Santa)
    v_total := PKG_TURISMO_UQ.fn_valor_estadia(
        p_id_habitacion => 1,
        p_fecha_in      => TO_DATE('2024-03-21', 'YYYY-MM-DD'),
        p_fecha_out     => TO_DATE('2024-03-26', 'YYYY-MM-DD')
    );
    DBMS_OUTPUT.PUT_LINE('Total liquidado (2 noches bajas + 3 noches altas): $' || TO_CHAR(v_total, 'FM999,999,999'));
END;
/
```

---

### Demo 3: Probar `sp_crear_reserva` (Camino Exitoso)
```sql
DECLARE
    v_id_reserva NUMBER;
    v_total      NUMBER;
BEGIN
    PKG_TURISMO_UQ.sp_crear_reserva(
        p_id_cliente    => 1,
        p_id_habitacion => 5,
        p_fecha_in      => TO_DATE('2027-04-01', 'YYYY-MM-DD'),
        p_fecha_out     => TO_DATE('2027-04-05', 'YYYY-MM-DD'),
        p_num_huespedes => 2,
        p_id_reserva    => v_id_reserva,
        p_total         => v_total
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Reserva creada con éxito ID: ' || v_id_reserva || ' por valor de: $' || TO_CHAR(v_total, 'FM999,999,999'));
END;
/
```

---

### Demo 4: Demostrar las 3 Excepciones Propias de `sp_crear_reserva`

#### A. Checkout anterior al Checkin (`ORA-20001`):
```sql
DECLARE v_id NUMBER; v_tot NUMBER;
BEGIN
    PKG_TURISMO_UQ.sp_crear_reserva(1, 5, TO_DATE('2027-04-10', 'YYYY-MM-DD'), TO_DATE('2027-04-08', 'YYYY-MM-DD'), 2, v_id, v_tot);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Captura ORA-20001: ' || SQLERRM);
END;
/
```

#### B. Capacidad Excedida (`ORA-20003`):
```sql
DECLARE v_id NUMBER; v_tot NUMBER;
BEGIN
    PKG_TURISMO_UQ.sp_crear_reserva(1, 5, TO_DATE('2027-04-10', 'YYYY-MM-DD'), TO_DATE('2027-04-15', 'YYYY-MM-DD'), 50, v_id, v_tot);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Captura ORA-20003: ' || SQLERRM);
END;
/
```

#### C. Solapamiento de Habitación (`ORA-20002`):
```sql
DECLARE v_id NUMBER; v_tot NUMBER;
BEGIN
    -- Intentar reservar la habitación 5 en las mismas fechas de la Demo 3 (2027-04-01 al 2027-04-05)
    PKG_TURISMO_UQ.sp_crear_reserva(2, 5, TO_DATE('2027-04-03', 'YYYY-MM-DD'), TO_DATE('2027-04-07', 'YYYY-MM-DD'), 2, v_id, v_tot);
EXCEPTION
    WHEN OTHERS THEN DBMS_OUTPUT.PUT_LINE('Captura ORA-20002: ' || SQLERRM);
END;
/
```

---

### Demo 5: Demostrar la Auditoría de Tarifas
```sql
-- 1. Modificar tarifas de prueba
UPDATE TARIFA SET PRECIO_NOCHE = PRECIO_NOCHE + 10000 WHERE ID_HABITACION = 1;
COMMIT;

-- 2. Consultar log detallado
SELECT id_auditoria, id_tarifa, precio_anterior, precio_nuevo, usuario_oracle, fecha_accion, tipo_operacion
FROM AUDITORIA_TARIFA ORDER BY id_auditoria DESC FETCH FIRST 2 ROWS ONLY;

-- 3. Consultar log de sentencia
SELECT id_log, usuario_oracle, fecha_accion, tipo_operacion, filas_afectadas
FROM LOG_SENTENCIA_TARIFA ORDER BY id_log DESC FETCH FIRST 1 ROWS ONLY;
```

---

### Demo 6: Demostrar el Cursor Explícito de Liquidación Mensual
```sql
DECLARE
    v_procesados NUMBER;
BEGIN
    PKG_TURISMO_UQ.sp_liquidacion_mensual_alojamiento(
        p_mes              => 3,
        p_anio             => 2025,
        p_id_alojamiento   => NULL,
        p_total_procesados => v_procesados
    );
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Liquidación finalizada. Total alojamientos procesados: ' || v_procesados);
END;
/

-- Consultar resultados consolidados en LIQUIDACION_MENSUAL
SELECT nombre_alojamiento, municipio, total_reservas, ingresos_hospedaje, comision_plataforma, pago_neto_propietario
FROM LIQUIDACION_MENSUAL
WHERE mes = 3 AND anio = 2025
ORDER BY total_bruto DESC
FETCH FIRST 5 ROWS ONLY;
```

---

# 5. BANCO DE PREGUNTAS TÉCNICAS DE SUSTENTACIÓN

### 1. ¿Por qué el cursor de liquidación es explícito y no un simple `UPDATE` o cursor implícito?
**Respuesta:**  
Porque realiza un cálculo contable fila por fila que involucra agregaciones de múltiples tablas hijas (`RESERVA_HABITACION` y `RESERVA_SERVICIO`), aplica la lógica de comisión (10%) y maneja parámetros opcionales (`p_id_alojamiento`). Un cursor explícito permite controlar el ciclo de vida en la memoria privada (PGA) con `OPEN`, `FETCH` y `CLOSE`, procesando los 60 alojamientos sin desbordar memoria ni saturar los buffers de Undo.

### 2. ¿Qué ocurre internamente con los bloques de Undo y Redo al invocar `sp_crear_reserva`?
**Respuesta:**  
- Al ejecutar el primer `INSERT` en `RESERVA`, Oracle genera vectores de cambio en el **Redo Log Buffer** para garantizar durabilidad ante caídas, y asigna bloques en el tablespace de **UNDO** para permitir revertir los datos o proveer lectura consistente multiversión (MVCC) a otros usuarios.
- Si la segunda inserción en `RESERVA_HABITACION` falla por solapamiento (`ORA-20002`), Oracle utiliza los bloques de Undo para deshacer la inserción en `RESERVA`. La transacción es 100% atómica.

### 3. ¿Por qué las tablas históricas y transaccionales están en un tablespace distinto al de usuarios?
**Respuesta:**  
Para aislar físicamente la contención de I/O de disco entre las operaciones OLTP continuas y los reportes analíticos masivos; para permitir políticas de backup diferenciadas en RMAN colocando el histórico en modo `READ ONLY`; y para posibilitar compresión avanzada de datos relacionales sin degradar los catálogos del sistema.

### 4. ¿Cómo resolvieron la tabla mutante en el disparador de solapamiento?
**Respuesta:**  
Implementando un **Compound Trigger**. En la sección `BEFORE EACH ROW` únicamente capturamos en memoria RAM (arreglos asociativos en la PGA) los IDs de habitación y reserva solicitados, sin tocar la tabla. En la sección `AFTER STATEMENT`, una vez que el DML concluyó y la tabla ha salido de su estado de mutación, ejecutamos la consulta de conteo de solapamientos con absoluta consistencia de lectura.

### 5. ¿Qué ventaja tiene que las tarifas se liquiden en PL/SQL y no en Java/Spring Boot?
**Respuesta:**  
- **Rendimiento de Red:** Si se calculara en Java, la aplicación tendría que transferir por la red todas las fechas de la temporada y todas las tarifas de la habitación. Al hacerlo dentro de Oracle mediante `fn_valor_estadia`, el cálculo se ejecuta en la misma memoria del motor sin latencia de red.
- **Seguridad e Integridad:** Cualquier cliente (sea la aplicación web, una app móvil o un script de SQL Developer) respeta rigurosamente las mismas tarifas y reglas de negocio sin duplicar código en el backend.
