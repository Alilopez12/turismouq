package co.edu.uniquindio.turismouq.controlador;

import co.edu.uniquindio.turismouq.dto.LiquidacionPeticionDTO;
import co.edu.uniquindio.turismouq.dto.RespuestaApiDTO;
import co.edu.uniquindio.turismouq.entidad.LiquidacionMensual;
import co.edu.uniquindio.turismouq.servicio.LiquidacionServicio;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/liquidaciones")
public class LiquidacionControlador {

    private final LiquidacionServicio liquidacionServicio;

    public LiquidacionControlador(LiquidacionServicio liquidacionServicio) {
        this.liquidacionServicio = liquidacionServicio;
    }

    @PostMapping("/ejecutar")
    public ResponseEntity<RespuestaApiDTO<Integer>> ejecutarLiquidacion(
            @RequestBody LiquidacionPeticionDTO peticion
    ) {
        int totalProcesados = liquidacionServicio.ejecutarLiquidacionMensual(peticion);
        return ResponseEntity.ok(RespuestaApiDTO.exito(
                "Proceso masivo completado exitosamente mediante cursor explícito",
                totalProcesados
        ));
    }

    @GetMapping
    public ResponseEntity<RespuestaApiDTO<List<LiquidacionMensual>>> consultarLiquidaciones(
            @RequestParam(required = false) Integer mes,
            @RequestParam(required = false) Integer anio
    ) {
        List<LiquidacionMensual> liquidaciones = liquidacionServicio.consultarLiquidaciones(mes, anio);
        return ResponseEntity.ok(RespuestaApiDTO.exito("Liquidaciones mensuales", liquidaciones));
    }
}
