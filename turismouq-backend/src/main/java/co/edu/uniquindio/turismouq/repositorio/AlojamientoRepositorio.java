package co.edu.uniquindio.turismouq.repositorio;

import co.edu.uniquindio.turismouq.entidad.Alojamiento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AlojamientoRepositorio extends JpaRepository<Alojamiento, Long> {

    @Query("SELECT a FROM Alojamiento a " +
           "JOIN FETCH a.municipio m " +
           "JOIN FETCH a.tipoAlojamiento ta " +
           "JOIN FETCH a.propietario p " +
           "WHERE (:idMunicipio IS NULL OR m.idMunicipio = :idMunicipio) AND " +
           "(:idTipoAlojamiento IS NULL OR ta.idTipoAlojamiento = :idTipoAlojamiento) " +
           "ORDER BY a.nombre ASC")
    List<Alojamiento> filtrarAlojamientos(
            @Param("idMunicipio") Long idMunicipio,
            @Param("idTipoAlojamiento") Long idTipoAlojamiento
    );
}
