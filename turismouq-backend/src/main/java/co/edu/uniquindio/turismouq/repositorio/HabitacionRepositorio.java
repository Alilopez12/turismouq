package co.edu.uniquindio.turismouq.repositorio;

import co.edu.uniquindio.turismouq.entidad.Habitacion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface HabitacionRepositorio extends JpaRepository<Habitacion, Long> {
    List<Habitacion> findByAlojamientoIdAlojamientoOrderByNumeroNombreAsc(Long idAlojamiento);
}
