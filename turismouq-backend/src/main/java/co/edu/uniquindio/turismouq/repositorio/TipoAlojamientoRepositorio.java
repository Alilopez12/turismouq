package co.edu.uniquindio.turismouq.repositorio;

import co.edu.uniquindio.turismouq.entidad.TipoAlojamiento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TipoAlojamientoRepositorio extends JpaRepository<TipoAlojamiento, Long> {
    List<TipoAlojamiento> findAllByOrderByNombreAsc();
}
