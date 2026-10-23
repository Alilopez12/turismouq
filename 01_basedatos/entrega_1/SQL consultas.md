# Consultas SQL de Análisis - Entrega 1

**Asignatura:** Bases de Datos II (Código 12338)  
**Proyecto:** TurismoUQ  
**Motor:** Oracle Database 21c Express Edition (PDB: `XEPDB1`, Esquema: `TURISMO_UQ`)

---

## Consulta 1: Ocupación por Municipio y Mes con PIVOT

Distribución mensual del total de reservas para cada uno de los 12 municipios del Quindío usando la cláusula `PIVOT`.

```sql
SELECT *
FROM (
    SELECT
        m.nombre AS municipio,
        TO_CHAR(r.fecha_check_in, 'MM') AS mes,
        r.id_reserva
    FROM MUNICIPIO m
    JOIN ALOJAMIENTO a
        ON m.id_municipio = a.id_municipio
    JOIN HABITACION h
        ON a.id_alojamiento = h.id_alojamiento
    JOIN RESERVA_HABITACION rh
        ON h.id_habitacion = rh.id_habitacion
    JOIN RESERVA r
        ON rh.id_reserva = r.id_reserva
)
PIVOT (
    COUNT(id_reserva)
    FOR mes IN (
        '01' AS ENERO,
        '02' AS FEBRERO,
        '03' AS MARZO,
        '04' AS ABRIL,
        '05' AS MAYO,
        '06' AS JUNIO,
        '07' AS JULIO,
        '08' AS AGOSTO,
        '09' AS SEPTIEMBRE,
        '10' AS OCTUBRE,
        '11' AS NOVIEMBRE,
        '12' AS DICIEMBRE
    )
)
ORDER BY municipio;
```

---

## Consulta 2: Ingresos por Municipio, Tipo de Alojamiento y Temporada con ROLLUP y GROUPING

Agregación multidimensional de ingresos diferenciando los subtotales por nivel jerárquico mediante la función `GROUPING`.

```sql
SELECT
    CASE
        WHEN GROUPING(m.nombre) = 1 THEN 'TOTAL GENERAL'
        ELSE m.nombre
    END AS municipio,

    CASE
        WHEN GROUPING(ta.nombre) = 1 THEN 'TOTAL'
        ELSE ta.nombre
    END AS tipo_alojamiento,

    CASE
        WHEN GROUPING(t.nombre) = 1 THEN 'TOTAL'
        ELSE t.nombre
    END AS temporada,

    SUM(r.total) AS ingresos

FROM MUNICIPIO m

JOIN ALOJAMIENTO a
    ON m.id_municipio = a.id_municipio

JOIN TIPO_ALOJAMIENTO ta
    ON a.id_tipo_alojamiento = ta.id_tipo_alojamiento

JOIN HABITACION h
    ON a.id_alojamiento = h.id_alojamiento

JOIN RESERVA_HABITACION rh
    ON h.id_habitacion = rh.id_habitacion

JOIN RESERVA r
    ON rh.id_reserva = r.id_reserva

JOIN TEMPORADA t
    ON r.fecha_check_in BETWEEN t.fecha_inicio AND t.fecha_fin

GROUP BY ROLLUP (
    m.nombre,
    ta.nombre,
    t.nombre
);
```

---

## Consulta 3: Top 3 Alojamientos de Mayor Ingreso por Municipio con RANK() OVER (PARTITION BY)

Función analítica de ventana particionada por municipio para identificar los 3 alojamientos con mayor facturación histórica.

```sql
SELECT municipio, alojamiento, ingresos, posicion
FROM (
    SELECT
        m.nombre AS municipio,
        a.nombre AS alojamiento,
        SUM(r.total) AS ingresos,
        RANK() OVER (
            PARTITION BY m.nombre
            ORDER BY SUM(r.total) DESC
        ) AS posicion
    FROM MUNICIPIO m
    JOIN ALOJAMIENTO a
        ON m.id_municipio = a.id_municipio
    JOIN HABITACION h
        ON a.id_alojamiento = h.id_alojamiento
    JOIN RESERVA_HABITACION rh
        ON h.id_habitacion = rh.id_habitacion
    JOIN RESERVA r
        ON rh.id_reserva = r.id_reserva
    GROUP BY m.nombre, a.nombre
)
WHERE posicion <= 3
ORDER BY municipio, posicion;
```

---

## Consulta 4: Variación de Ingresos Mes contra Mes con LAG()

Función de desplazamiento `LAG()` para calcular la variación absoluta respecto al mes calendario anterior.

```sql
SELECT
    mes,
    ingresos,
    LAG(ingresos) OVER (ORDER BY mes) AS ingreso_mes_anterior,
    ingresos - LAG(ingresos) OVER (ORDER BY mes) AS variacion
FROM (
    SELECT
        TRUNC(fecha_check_in, 'MM') AS mes,
        SUM(total) AS ingresos
    FROM RESERVA
    GROUP BY TRUNC(fecha_check_in, 'MM')
)
ORDER BY mes;
```

---

## Consulta 5: Consulta Parametrizada con Variables Bind para Rango de Fechas

Uso de variables de enlace (`:fecha_inicio`, `:fecha_fin`) para favorecer el reuso de cursores en el Shared Pool y evitar hard parsing.

```sql
VARIABLE fecha_inicio VARCHAR2(10);
VARIABLE fecha_fin VARCHAR2(10);

EXEC :fecha_inicio := '01/01/2025';
EXEC :fecha_fin := '31/12/2025';

SELECT
    r.id_reserva,
    r.fecha_check_in,
    r.fecha_check_out,
    r.total,
    r.estado
FROM RESERVA r
WHERE r.fecha_check_in BETWEEN
      TO_DATE(:fecha_inicio, 'DD/MM/YYYY')
      AND TO_DATE(:fecha_fin, 'DD/MM/YYYY')
ORDER BY r.fecha_check_in;
```

---

## Consulta 6: Vista Materializada de Ocupación Mensual (MV_OCUPACION_MENSUAL)

Creación y consulta de la vista materializada con política de refresco `COMPLETE ON DEMAND`.

```sql
-- 1. Otorgar privilegios desde SYS
-- CONNECT / AS SYSDBA
-- ALTER SESSION SET CONTAINER = XEPDB1;
-- GRANT CREATE MATERIALIZED VIEW TO TURISMO_UQ;

-- 2. Creación de la vista materializada
CREATE MATERIALIZED VIEW MV_OCUPACION_MENSUAL
BUILD IMMEDIATE
REFRESH COMPLETE ON DEMAND
AS
SELECT
    m.nombre AS municipio,
    TRUNC(r.fecha_check_in, 'MM') AS mes,
    COUNT(DISTINCT r.id_reserva) AS total_reservas
FROM MUNICIPIO m
JOIN ALOJAMIENTO a
    ON m.id_municipio = a.id_municipio
JOIN HABITACION h
    ON a.id_alojamiento = h.id_alojamiento
JOIN RESERVA_HABITACION rh
    ON h.id_habitacion = rh.id_habitacion
JOIN RESERVA r
    ON rh.id_reserva = r.id_reserva
GROUP BY
    m.nombre,
    TRUNC(r.fecha_check_in, 'MM');

-- 3. Consulta de la vista materializada
SELECT *
FROM MV_OCUPACION_MENSUAL
ORDER BY municipio, mes;
```

---

## Consulta 7: Desagregación con UNPIVOT

Transformación de columnas normalizadas de métodos de pago en filas para reporte de distribución de transacciones.

```sql
SELECT metodo_pago, cantidad_pagos
FROM (
    SELECT
        SUM(CASE WHEN metodo_pago = 'PSE' THEN 1 ELSE 0 END) AS PSE,
        SUM(CASE WHEN metodo_pago = 'TARJETA_CREDITO' THEN 1 ELSE 0 END) AS TARJETA_CREDITO,
        SUM(CASE WHEN metodo_pago = 'TRANSFERENCIA' THEN 1 ELSE 0 END) AS TRANSFERENCIA
    FROM PAGO
)
UNPIVOT (
    cantidad_pagos
    FOR metodo_pago IN (
        PSE AS 'PSE',
        TARJETA_CREDITO AS 'TARJETA_CREDITO',
        TRANSFERENCIA AS 'TRANSFERENCIA'
    )
)
ORDER BY cantidad_pagos DESC;
```

---

## Consulta 8: Consulta Libre de Negocio

Pregunta de negocio: *¿Cuál es el volumen de reservas y facturación total según el tipo de hospedaje en el departamento del Quindío?*

```sql
SELECT
    ta.nombre AS tipo_alojamiento,
    COUNT(DISTINCT r.id_reserva) AS total_reservas,
    SUM(r.total) AS ingresos_totales
FROM TIPO_ALOJAMIENTO ta
JOIN ALOJAMIENTO a
    ON ta.id_tipo_alojamiento = a.id_tipo_alojamiento
JOIN HABITACION h
    ON a.id_alojamiento = h.id_alojamiento
JOIN RESERVA_HABITACION rh
    ON h.id_habitacion = rh.id_habitacion
JOIN RESERVA r
    ON rh.id_reserva = r.id_reserva
GROUP BY ta.nombre
ORDER BY ingresos_totales DESC;
```
