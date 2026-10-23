package co.edu.uniquindio.turismouq.servicio;

import co.edu.uniquindio.turismouq.dto.CotizacionPeticionDTO;
import co.edu.uniquindio.turismouq.dto.CotizacionRespuestaDTO;
import co.edu.uniquindio.turismouq.dto.ReservaPeticionDTO;
import co.edu.uniquindio.turismouq.dto.ReservaRespuestaDTO;
import co.edu.uniquindio.turismouq.entidad.Reserva;

import java.util.List;

public interface ReservaServicio {

    CotizacionRespuestaDTO cotizarEstadia(CotizacionPeticionDTO peticion);

    ReservaRespuestaDTO crearReserva(ReservaPeticionDTO peticion);

    List<Reserva> listarReservasRecientes();
}
