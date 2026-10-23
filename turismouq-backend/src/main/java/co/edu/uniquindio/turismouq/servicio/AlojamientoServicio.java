package co.edu.uniquindio.turismouq.servicio;

import co.edu.uniquindio.turismouq.entidad.*;

import java.util.List;

public interface AlojamientoServicio {

    List<Alojamiento> listarAlojamientos(Long idMunicipio, Long idTipoAlojamiento);

    Alojamiento obtenerPorId(Long idAlojamiento);

    List<Habitacion> listarHabitacionesPorAlojamiento(Long idAlojamiento);

    List<Tarifa> listarTarifasPorHabitacion(Long idHabitacion);

    List<Municipio> listarMunicipios();

    List<TipoAlojamiento> listarTiposAlojamiento();
}
