package co.edu.uniquindio.turismouq.repositorio;

import co.edu.uniquindio.turismouq.entidad.Municipio;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MunicipioRepositorio extends JpaRepository<Municipio, Long> {
    List<Municipio> findAllByOrderByNombreAsc();
}
