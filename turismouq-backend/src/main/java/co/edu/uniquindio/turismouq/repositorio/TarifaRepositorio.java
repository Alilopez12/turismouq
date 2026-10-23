package co.edu.uniquindio.turismouq.repositorio;

import co.edu.uniquindio.turismouq.entidad.Tarifa;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TarifaRepositorio extends JpaRepository<Tarifa, Long> {
    List<Tarifa> findByHabitacionIdHabitacion(Long idHabitacion);
}
