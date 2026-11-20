# TurismoUQ - Plataforma de Reservas Turísticas del Quindío
**Asignatura:** Bases de Datos II (Código 12338)  
**Institución:** Universidad del Quindío - Facultad de Ingeniería de Sistemas y Computación  
**Motor de Base de Datos:** Oracle Database 21c Express Edition (PDB: `XEPDB1`, Esquema: `TURISMO_UQ`)  
**Stack Tecnológico:** Spring Boot 3 (Java 21) + Angular (HTML5 & CSS3)

---

## 📁 Estructura del Proyecto

```
turismouq/
├── 01_basedatos/                               # Scripts SQL/PL-SQL organizados por entrega
│   ├── 00_master_instalacion_completa.sql      # Script maestro idempotente (14 pasos en orden)
│   │
│   ├── entrega_1/                              # Entrega 1: Modelo, Tablespace, Carga y BI
│   │   ├── 00_crear_esquema_tablas.sql         # DDL completo de las 16 entidades + PK/FK/CHECK
│   │   ├── 01_tablespace_historico.sql         # Tablespace TBS_HISTORICO_RESERVAS y tabla histórica
│   │   ├── 01_cargar_datos_volumen.sql         # Carga masiva idempotente (25.000 reservas, 3.000 clientes)
│   │   ├── 02_consultas_analisis.sql           # MV_OCUPACION_MENSUAL + 10 consultas analíticas (8+2)
│   │   └── SQL consultas.md                    # Documentación analítica
│   │
│   ├── entrega_2/                              # Entrega 2: PL/SQL, Paquetes y Triggers
│   │   ├── 01_adecuacion_modelo.sql            # 4 tipos de alojamiento, 2 temporadas, PERIODO_TEMPORADA, 800 tarifas
│   │   ├── 02_auditoria_tarifa.sql             # Trigger compuesto/sentencia sobre TARIFA + AUDITORIA_TARIFA
│   │   ├── 03_trigger_solapamiento.sql         # Compound Trigger anti-solapamiento (sin ORA-04091)
│   │   ├── 04_paquete_turismo_espec.sql        # Especificación de PKG_TURISMO_UQ + LIQUIDACION_MENSUAL
│   │   ├── 05_paquete_turismo_cuerpo.sql       # Cuerpo completo (fn_valor_estadia, sp, cursor explícito, SAVEPOINT)
│   │   ├── 06_pruebas_verificacion.sql         # Suite automatizada ORA-20001 / ORA-20002 / ORA-20003
│   │   └── 07_indices_rendimiento.sql          # Índices B-Tree de rendimiento sobre claves foráneas
│   │
│   └── entrega_3/                              # Entrega 3: Transacciones, Concurrencia, CBO y Seguridad
│       ├── 01_transacciones_savepoint.sql      # Demos de transacción atómica (COMMIT y ROLLBACK TO SAVEPOINT)
│       ├── 02_concurrencia_bloqueos.sql        # sp_reserva_concurrente_for_update (FOR UPDATE WAIT 5 + SLEEP)
│       ├── 03_indices_optimizacion_cbo.sql     # Planes EXPLAIN PLAN ANTES/DESPUÉS, Q1-Q3 + Caso Negativo Q4
│       ├── 04_seguridad_roles_vistas_perfil.sql# Perfil PRF_TURISMO_SEGURIDAD, 3 vistas, 4 roles y 4 usuarios Oracle
│       └── 05_tabla_usuarios_sistema.sql       # Tabla USUARIO_SISTEMA y credenciales RBAC de la aplicación web
│
├── 02_documentacion/                           # Entregable documental final para Moodle
│   ├── TurismoUQ_Documento_Tecnico_Entrega3.html
│   └── TurismoUQ_Modelo_Diseno_y_Entrega3.pdf  # Modelo ER, 2 decisiones de diseño y evidencias reales Oracle XE
│
├── turismouq-backend/                          # Backend Spring Boot 3 (Java 21 + JDBC/JPA)
│   ├── pom.xml
│   └── src/main/java/co/edu/uniquindio/turismouq/
│       ├── controlador/                        # Alojamiento, Analitica, Auth, EntregaTres, Liquidacion, Recepcion, Reserva
│       ├── servicio/                           # Invocaciones a PKG_TURISMO_UQ, JDBC y CBO
│       ├── repositorio/
│       ├── entidad/
│       ├── dto/
│       ├── excepcion/
│       └── configuracion/
│
└── turismouq-frontend/                         # Frontend Angular Standalone
    └── src/app/componentes/
        ├── catalogo/                           # Explorador de los 60 alojamientos por municipio
        ├── detalle-alojamiento/                # Habitaciones y cotizador en vivo (fn_valor_estadia)
        ├── formulario-reserva/                 # Creación de reservas (sp_crear_reserva)
        ├── recepcion/                          # Check-In y Vouchers mediante vistas V_RECEPCION_*
        ├── liquidaciones/                      # Liquidación mensual masiva con cursor explícito
        ├── transacciones/                      # Demo interactiva SAVEPOINT (Commit / Rollback Parcial)
        ├── concurrencia/                       # Simulador de bloqueos TX Lock / FOR UPDATE WAIT 5
        ├── optimizador-cbo/                    # Comparador visual EXPLAIN PLAN Q1-Q4 + caso negativo
        ├── analitica/                          # Data Studio con las 10 consultas analíticas (PIVOT..LISTAGG)
        ├── auditoria/                          # Trazas del trigger en TARIFA + seguridad RBAC
        └── tablespace/                         # Monitoreo físico de TBS_HISTORICO_RESERVAS
```

---

## 📊 Consultas Analíticas Implementadas (`02_consultas_analisis.sql` y `/analitica`)

1. **Q01 (`PIVOT`):** Ocupación por municipio y mes (12 meses × 12 municipios).
2. **Q02 (`ROLLUP` + `GROUPING`):** Subtotales jerárquicos de ingresos por municipio, tipo de alojamiento y temporada.
3. **Q03 (`RANK()`):** Top 3 alojamientos de mayor ingreso por cada municipio.
4. **Q04 (`LAG()`):** Variación de ingresos mes contra mes.
5. **Q05 (Bind Variables):** Consulta parametrizada `:fecha_inicio` / `:fecha_fin` reutilizando plan SQL.
6. **Q06 (Vista Materializada):** `MV_OCUPACION_MENSUAL` con refresco `DBMS_MVIEW.REFRESH(..., 'C')`.
7. **Q07 (`UNPIVOT`):** Desagregación de métodos de pago (`PSE`, `TARJETA_CREDITO`, `TRANSFERENCIA`).
8. **Q08 (Negocio libre):** Ingresos y reservas por los 4 tipos oficiales de hospedaje.
9. **Q09 (`RANK()` + `EXISTS`):** Habitación con más reservas en temporada alta (`PERIODO_TEMPORADA`, `id_temporada = 2`).
10. **Q10 (`COUNT DISTINCT` + `LISTAGG`):** Listado de clientes con mayor cantidad de municipios visitados.

---

## 🚀 Guía de Puesta en Marcha

### 1. Base de Datos Oracle XE 21c (Instalación Limpia)
Ejecutar de arriba a abajo en una sola pasada desde SQL*Plus o SQL Developer conectado en `XEPDB1` como `TURISMO_UQ` (o `SYSTEM`):
```powershell
cd "01_basedatos"
sqlplus TURISMO_UQ/Turismo2026#@localhost:1521/XEPDB1 @00_master_instalacion_completa.sql
```

### 2. Backend Spring Boot (Puerto 8080)
```powershell
cd turismouq-backend
.\mvnw spring-boot:run
```
Disponible en `http://localhost:8080`.

### 3. Frontend Angular (Puerto 4200)
```powershell
cd turismouq-frontend
npm install
npm start
```
Disponible en `http://localhost:4200`.

### 4. Credenciales de Prueba

**Aplicación Web (`USUARIO_SISTEMA`, contraseña común `Turismo2026#`):**
- `admin` / `ADMIN_TOTAL` (`ROL_SUPER_ADMIN`)
- `USR_RECEPCION_01` (`ROL_RECEPCION`)
- `USR_ADMIN_01` (`ROL_ADMIN_ALOJAMIENTO`)
- `USR_GERENTE_01` (`ROL_GERENTE`)
- `USR_AUDITOR_01` (`ROL_AUDITOR`)

**Usuarios Nativos de Oracle XE (`04_seguridad_roles_vistas_perfil.sql`, perfil `PRF_TURISMO_SEGURIDAD`):**
- `USR_RECEPCION_01` / `Recep2026#` (`ROL_RECEPCION`)
- `USR_ADMIN_01` / `Admin2026#` (`ROL_ADMIN_ALOJAMIENTO`)
- `USR_GERENTE_01` / `Geren2026#` (`ROL_GERENTE`)
- `USR_AUDITOR_01` / `Audit2026#` (`ROL_AUDITOR`)
