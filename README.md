# TurismoUQ - Plataforma de Reservas Turísticas del Quindío
**Asignatura:** Bases de Datos II (Código 12338)  
**Institución:** Universidad del Quindío - Facultad de Ingeniería de Sistemas y Computación  
**Motor de Base de Datos:** Oracle Database 21c Express Edition (PDB: `XEPDB1`, Esquema: `TURISMO_UQ`)  
**Stack Tecnológico:** Spring Boot 3 (Java 21) + Angular (HTML5 & CSS3)

---

## 📁 Estructura del Proyecto

```
Proyecto bases II/
├── 01_basedatos/                               # Organización formal por entregas
│   ├── 00_master_instalacion_completa.sql      # Script maestro de instalación limpia
│   ├── entrega_1/                              # Contenido de la Entrega 1 (30%)
│   │   ├── 01_tablespace_historico.sql         # Tablespace TBS_HISTORICO_RESERVAS con justificación técnica
│   │   ├── 02_consultas_analisis.sql           # Las 8 consultas analíticas oficiales en SQL
│   │   └── SQL consultas.md                    # Documentación Markdown de las 8 consultas (Obsidian)
│   │
│   └── entrega_2/                              # Contenido de la Entrega 2
│       ├── 01_adecuacion_modelo.sql            # 4 tipos de alojamiento, 2 temporadas y 800 tarifas
│       ├── 02_auditoria_tarifa.sql             # Trigger a nivel de sentencia en TARIFA (con tabla de log)
│       ├── 03_trigger_solapamiento.sql         # Trigger compound para evitar solapamiento (sin ORA-04091)
│       ├── 04_paquete_turismo_espec.sql        # Especificación de PKG_TURISMO_UQ
│       ├── 05_paquete_turismo_cuerpo.sql       # Cuerpo completo de PKG_TURISMO_UQ (fn, sp, cursor explícito)
│       └── 06_pruebas_verificacion.sql         # Suite de pruebas automatizadas en PL/SQL
│
├── turismouq-backend/                          # Backend Spring Boot 3 (Java 21)
│   ├── pom.xml
│   └── src/main/java/co/edu/uniquindio/turismouq/
│       ├── controlador/                        # Capa Web REST 100% en español
│       ├── servicio/                           # Capa de Lógica y llamadas PL/SQL en español
│       ├── repositorio/                        # Capa de Acceso a Datos Spring Data JPA
│       ├── entidad/                            # Modelado de Entidades JPA en español
│       ├── dto/                                # Data Transfer Objects
│       ├── excepcion/                          # Manejo global de excepciones Oracle
│       └── configuracion/                      # CORS y conexión Oracle XE (HikariCP)
│
└── turismouq-frontend/                         # Frontend Angular (HTML5 + CSS3)
    └── src/app/
        ├── componentes/
        │   ├── catalogo/                       # Explorador de los 60 alojamientos por municipio
        │   ├── detalle-alojamiento/            # Habitaciones y cotizador en vivo (fn_valor_estadia)
        │   ├── formulario-reserva/             # Creación de reservas atómicas (sp_crear_reserva)
        │   ├── liquidaciones/                  # Proceso masivo con cursor explícito en Oracle
        │   ├── analitica/                      # Módulo gráfico con las 8 consultas de Entrega 1
        │   └── auditoria/                      # Visor de trazas del trigger de sentencias
        ├── servicios/                          # Servicios HttpClient en español
        └── modelos/                            # Interfaces TypeScript en español
```

---

## 🚀 Guía de Puesta en Marcha

### 1. Base de Datos Oracle XE 21c
Conexión estándar:
```powershell
sqlplus TURISMO_UQ/Turismo2026#@localhost:1521/XEPDB1
```

Ejecutar la suite de pruebas de Entrega 2:
```powershell
@"C:\Users\DELL\Documents\Proyecto bases II\01_basedatos\entrega_2\06_pruebas_verificacion.sql"
```

### 2. Backend Spring Boot (Puerto 8080)
```powershell
cd "C:\Users\DELL\Documents\Proyecto bases II\turismouq-backend"
mvn spring-boot:run
```
El backend estará disponible en `http://localhost:8080`.

### 3. Frontend Angular (Puerto 4200)
```powershell
cd "C:\Users\DELL\Documents\Proyecto bases II\turismouq-frontend"
ng serve --open
```
El cliente web se abrirá automáticamente en `http://localhost:4200`.
