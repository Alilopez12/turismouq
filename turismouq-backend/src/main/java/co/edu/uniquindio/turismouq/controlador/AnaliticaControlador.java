package co.edu.uniquindio.turismouq.controlador;

import co.edu.uniquindio.turismouq.dto.RespuestaApiDTO;
import co.edu.uniquindio.turismouq.servicio.AnaliticaServicio;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/analitica")
public class AnaliticaControlador {

    private final AnaliticaServicio analiticaServicio;

    public AnaliticaControlador(AnaliticaServicio analiticaServicio) {
        this.analiticaServicio = analiticaServicio;
    }

    @GetMapping("/ocupacion-pivot")
    public ResponseEntity<RespuestaApiDTO<List<Map<String, Object>>>> obtenerOcupacionPivot() {
        return ResponseEntity.ok(RespuestaApiDTO.exito(
                "Consulta 1: Ocupación por municipio y mes con PIVOT",
                analiticaServicio.obtenerOcupacionPivot()
        ));
    }

    @GetMapping("/ingresos-rollup")
    public ResponseEntity<RespuestaApiDTO<List<Map<String, Object>>>> obtenerIngresosRollup() {
        return ResponseEntity.ok(RespuestaApiDTO.exito(
                "Consulta 2: Ingresos por municipio, tipo y temporada con ROLLUP y GROUPING",
                analiticaServicio.obtenerIngresosRollup()
        ));
    }

    @GetMapping("/top3-municipio")
    public ResponseEntity<RespuestaApiDTO<List<Map<String, Object>>>> obtenerTop3PorMunicipio() {
        return ResponseEntity.ok(RespuestaApiDTO.exito(
                "Consulta 3: Top 3 alojamientos con mayor ingreso por municipio (RANK OVER PARTITION BY)",
                analiticaServicio.obtenerTop3PorMunicipio()
        ));
    }

    @GetMapping("/variacion-lag")
    public ResponseEntity<RespuestaApiDTO<List<Map<String, Object>>>> obtenerVariacionLag() {
        return ResponseEntity.ok(RespuestaApiDTO.exito(
                "Consulta 4: Variación de ingresos mes contra mes (LAG)",
                analiticaServicio.obtenerVariacionLag()
        ));
    }

    @GetMapping("/rango-fechas")
    public ResponseEntity<RespuestaApiDTO<List<Map<String, Object>>>> obtenerConsultaParametrizada(
            @RequestParam(required = false) String fechaInicio,
            @RequestParam(required = false) String fechaFin
    ) {
        return ResponseEntity.ok(RespuestaApiDTO.exito(
                "Consulta 5: Consulta parametrizada con variables bind",
                analiticaServicio.obtenerConsultaParametrizada(fechaInicio, fechaFin)
        ));
    }

    @GetMapping("/vista-materializada")
    public ResponseEntity<RespuestaApiDTO<List<Map<String, Object>>>> obtenerVistaMaterializada() {
        return ResponseEntity.ok(RespuestaApiDTO.exito(
                "Consulta 6: Vista Materializada de ocupación mensual (MV_OCUPACION_MENSUAL)",
                analiticaServicio.obtenerVistaMaterializadaOcupacion()
        ));
    }

    @GetMapping("/unpivot")
    public ResponseEntity<RespuestaApiDTO<List<Map<String, Object>>>> obtenerUnpivot() {
        return ResponseEntity.ok(RespuestaApiDTO.exito(
                "Consulta 7: Desagregación matricial con UNPIVOT",
                analiticaServicio.obtenerConsultaUnpivot()
        ));
    }

    @GetMapping("/servicios-negocio")
    public ResponseEntity<RespuestaApiDTO<List<Map<String, Object>>>> obtenerServiciosNegocio() {
        return ResponseEntity.ok(RespuestaApiDTO.exito(
                "Consulta 8: Consulta libre de negocio sobre servicios complementarios",
                analiticaServicio.obtenerServiciosNegocioLibre()
        ));
    }

    @GetMapping("/auditoria-tarifas")
    public ResponseEntity<RespuestaApiDTO<List<Map<String, Object>>>> obtenerAuditoriaTarifas() {
        return ResponseEntity.ok(RespuestaApiDTO.exito(
                "Auditoría a nivel de sentencia en TARIFA",
                analiticaServicio.obtenerAuditoriaTarifas()
        ));
    }

    @GetMapping("/tablespace")
    public ResponseEntity<RespuestaApiDTO<Map<String, Object>>> obtenerMonitoreoTablespace() {
        return ResponseEntity.ok(RespuestaApiDTO.exito(
                "Monitoreo de almacenamiento físico y arquitectura de Tablespace (Oracle 21c)",
                analiticaServicio.obtenerMonitoreoTablespace()
        ));
    }
}
