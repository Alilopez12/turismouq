package co.edu.uniquindio.turismouq.controlador;

import co.edu.uniquindio.turismouq.dto.CotizacionPeticionDTO;
import co.edu.uniquindio.turismouq.dto.CotizacionRespuestaDTO;
import co.edu.uniquindio.turismouq.dto.ReservaPeticionDTO;
import co.edu.uniquindio.turismouq.dto.ReservaRespuestaDTO;
import co.edu.uniquindio.turismouq.dto.RespuestaApiDTO;
import co.edu.uniquindio.turismouq.entidad.Reserva;
import co.edu.uniquindio.turismouq.servicio.ReservaServicio;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/reservas")
public class ReservaControlador {

    private final ReservaServicio reservaServicio;

    public ReservaControlador(ReservaServicio reservaServicio) {
        this.reservaServicio = reservaServicio;
    }

    @PostMapping("/cotizar")
    public ResponseEntity<RespuestaApiDTO<CotizacionRespuestaDTO>> cotizarEstadia(
            @RequestBody CotizacionPeticionDTO peticion
    ) {
        CotizacionRespuestaDTO cotizacion = reservaServicio.cotizarEstadia(peticion);
        return ResponseEntity.ok(RespuestaApiDTO.exito("Cotización calculada con la función de temporadas", cotizacion));
    }

    @PostMapping
    public ResponseEntity<RespuestaApiDTO<ReservaRespuestaDTO>> crearReserva(
            @RequestBody ReservaPeticionDTO peticion
    ) {
        ReservaRespuestaDTO respuesta = reservaServicio.crearReserva(peticion);
        return ResponseEntity.ok(RespuestaApiDTO.exito("Reserva creada exitosamente en Oracle XE", respuesta));
    }

    @GetMapping("/recientes")
    public ResponseEntity<RespuestaApiDTO<List<Reserva>>> listarReservasRecientes() {
        List<Reserva> reservas = reservaServicio.listarReservasRecientes();
        return ResponseEntity.ok(RespuestaApiDTO.exito("Últimas reservas registradas", reservas));
    }
}
