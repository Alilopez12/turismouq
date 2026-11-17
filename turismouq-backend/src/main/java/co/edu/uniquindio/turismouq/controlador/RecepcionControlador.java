package co.edu.uniquindio.turismouq.controlador;

import co.edu.uniquindio.turismouq.dto.RecepcionCheckinDTO;
import co.edu.uniquindio.turismouq.dto.RecepcionDisponibilidadDTO;
import co.edu.uniquindio.turismouq.dto.RecepcionVoucherDTO;
import co.edu.uniquindio.turismouq.dto.RespuestaApiDTO;
import co.edu.uniquindio.turismouq.servicio.RecepcionServicio;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/recepcion")
public class RecepcionControlador {

    private final RecepcionServicio recepcionServicio;

    public RecepcionControlador(RecepcionServicio recepcionServicio) {
        this.recepcionServicio = recepcionServicio;
    }

    @GetMapping("/checkin-hoy")
    public ResponseEntity<RespuestaApiDTO<List<RecepcionCheckinDTO>>> obtenerCheckinHoy() {
        List<RecepcionCheckinDTO> lista = recepcionServicio.obtenerCheckinHoy();
        return ResponseEntity.ok(RespuestaApiDTO.exito("Llegadas para Check-In del día (V_RECEPCION_CHECKIN_HOY)", lista));
    }

    @GetMapping("/disponibilidad")
    public ResponseEntity<RespuestaApiDTO<List<RecepcionDisponibilidadDTO>>> obtenerDisponibilidad() {
        List<RecepcionDisponibilidadDTO> lista = recepcionServicio.obtenerDisponibilidad();
        return ResponseEntity.ok(RespuestaApiDTO.exito("Inventario de disponibilidad operativa (V_RECEPCION_DISPONIBILIDAD)", lista));
    }

    @GetMapping("/voucher")
    public ResponseEntity<RespuestaApiDTO<RecepcionVoucherDTO>> obtenerVoucherUltimo() {
        RecepcionVoucherDTO voucher = recepcionServicio.obtenerVoucher(null);
        return ResponseEntity.ok(RespuestaApiDTO.exito("Comprobante de reserva (V_RECEPCION_VOUCHER_RESERVA)", voucher));
    }

    @GetMapping("/voucher/{idReserva}")
    public ResponseEntity<RespuestaApiDTO<RecepcionVoucherDTO>> obtenerVoucherPorId(@PathVariable Long idReserva) {
        RecepcionVoucherDTO voucher = recepcionServicio.obtenerVoucher(idReserva);
        return ResponseEntity.ok(RespuestaApiDTO.exito("Comprobante de reserva #" + idReserva, voucher));
    }
}
