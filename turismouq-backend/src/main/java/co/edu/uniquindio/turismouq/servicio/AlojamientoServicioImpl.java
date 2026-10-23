package co.edu.uniquindio.turismouq.servicio;

import co.edu.uniquindio.turismouq.entidad.*;
import co.edu.uniquindio.turismouq.excepcion.NegocioExcepcion;
import co.edu.uniquindio.turismouq.repositorio.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class AlojamientoServicioImpl implements AlojamientoServicio {

    private final AlojamientoRepositorio alojamientoRepositorio;
    private final HabitacionRepositorio habitacionRepositorio;
    private final TarifaRepositorio tarifaRepositorio;
    private final MunicipioRepositorio municipioRepositorio;
    private final TipoAlojamientoRepositorio tipoAlojamientoRepositorio;

    public AlojamientoServicioImpl(
            AlojamientoRepositorio alojamientoRepositorio,
            HabitacionRepositorio habitacionRepositorio,
            TarifaRepositorio tarifaRepositorio,
            MunicipioRepositorio municipioRepositorio,
            TipoAlojamientoRepositorio tipoAlojamientoRepositorio
    ) {
        this.alojamientoRepositorio = alojamientoRepositorio;
        this.habitacionRepositorio = habitacionRepositorio;
        this.tarifaRepositorio = tarifaRepositorio;
        this.municipioRepositorio = municipioRepositorio;
        this.tipoAlojamientoRepositorio = tipoAlojamientoRepositorio;
    }

    @Override
    public List<Alojamiento> listarAlojamientos(Long idMunicipio, Long idTipoAlojamiento) {
        return alojamientoRepositorio.filtrarAlojamientos(idMunicipio, idTipoAlojamiento);
    }

    @Override
    public Alojamiento obtenerPorId(Long idAlojamiento) {
        return alojamientoRepositorio.findById(idAlojamiento)
                .orElseThrow(() -> new NegocioExcepcion("No se encontró el alojamiento con ID: " + idAlojamiento));
    }

    @Override
    public List<Habitacion> listarHabitacionesPorAlojamiento(Long idAlojamiento) {
        return habitacionRepositorio.findByAlojamientoIdAlojamientoOrderByNumeroNombreAsc(idAlojamiento);
    }

    @Override
    public List<Tarifa> listarTarifasPorHabitacion(Long idHabitacion) {
        return tarifaRepositorio.findByHabitacionIdHabitacion(idHabitacion);
    }

    @Override
    public List<Municipio> listarMunicipios() {
        return municipioRepositorio.findAllByOrderByNombreAsc();
    }

    @Override
    public List<TipoAlojamiento> listarTiposAlojamiento() {
        return tipoAlojamientoRepositorio.findAllByOrderByNombreAsc();
    }
}
