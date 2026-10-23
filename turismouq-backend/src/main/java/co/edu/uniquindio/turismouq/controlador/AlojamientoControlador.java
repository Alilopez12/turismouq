package co.edu.uniquindio.turismouq.controlador;

import co.edu.uniquindio.turismouq.dto.RespuestaApiDTO;
import co.edu.uniquindio.turismouq.entidad.*;
import co.edu.uniquindio.turismouq.servicio.AlojamientoServicio;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api")
public class AlojamientoControlador {

    private final AlojamientoServicio alojamientoServicio;

    public AlojamientoControlador(AlojamientoServicio alojamientoServicio) {
        this.alojamientoServicio = alojamientoServicio;
    }

    @GetMapping("/alojamientos")
    public ResponseEntity<RespuestaApiDTO<List<Alojamiento>>> listarAlojamientos(
            @RequestParam(required = false) Long idMunicipio,
            @RequestParam(required = false) Long idTipoAlojamiento
    ) {
        List<Alojamiento> resultado = alojamientoServicio.listarAlojamientos(idMunicipio, idTipoAlojamiento);
        return ResponseEntity.ok(RespuestaApiDTO.exito("Alojamientos obtenidos exitosamente", resultado));
    }

    @GetMapping("/alojamientos/{id}")
    public ResponseEntity<RespuestaApiDTO<Alojamiento>> obtenerAlojamiento(@PathVariable Long id) {
        Alojamiento alojamiento = alojamientoServicio.obtenerPorId(id);
        return ResponseEntity.ok(RespuestaApiDTO.exito("Alojamiento encontrado", alojamiento));
    }

    @GetMapping("/alojamientos/{id}/habitaciones")
    public ResponseEntity<RespuestaApiDTO<List<Habitacion>>> listarHabitaciones(@PathVariable Long id) {
        List<Habitacion> habitaciones = alojamientoServicio.listarHabitacionesPorAlojamiento(id);
        return ResponseEntity.ok(RespuestaApiDTO.exito("Habitaciones obtenidas", habitaciones));
    }

    @GetMapping("/habitaciones/{id}/tarifas")
    public ResponseEntity<RespuestaApiDTO<List<Tarifa>>> listarTarifas(@PathVariable Long id) {
        List<Tarifa> tarifas = alojamientoServicio.listarTarifasPorHabitacion(id);
        return ResponseEntity.ok(RespuestaApiDTO.exito("Tarifas de la habitación", tarifas));
    }

    @GetMapping("/municipios")
    public ResponseEntity<RespuestaApiDTO<List<Municipio>>> listarMunicipios() {
        List<Municipio> municipios = alojamientoServicio.listarMunicipios();
        return ResponseEntity.ok(RespuestaApiDTO.exito("Municipios del Quindío", municipios));
    }

    @GetMapping("/tipos-alojamiento")
    public ResponseEntity<RespuestaApiDTO<List<TipoAlojamiento>>> listarTiposAlojamiento() {
        List<TipoAlojamiento> tipos = alojamientoServicio.listarTiposAlojamiento();
        return ResponseEntity.ok(RespuestaApiDTO.exito("Tipos de alojamiento", tipos));
    }
}
