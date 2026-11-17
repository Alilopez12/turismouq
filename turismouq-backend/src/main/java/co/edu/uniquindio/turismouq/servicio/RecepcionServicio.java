package co.edu.uniquindio.turismouq.servicio;

import co.edu.uniquindio.turismouq.dto.RecepcionCheckinDTO;
import co.edu.uniquindio.turismouq.dto.RecepcionDisponibilidadDTO;
import co.edu.uniquindio.turismouq.dto.RecepcionVoucherDTO;

import java.util.List;

public interface RecepcionServicio {
    List<RecepcionCheckinDTO> obtenerCheckinHoy();
    List<RecepcionDisponibilidadDTO> obtenerDisponibilidad();
    RecepcionVoucherDTO obtenerVoucher(Long idReserva);
}
