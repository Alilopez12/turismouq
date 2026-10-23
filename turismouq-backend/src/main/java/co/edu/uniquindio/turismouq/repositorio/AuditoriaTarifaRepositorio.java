package co.edu.uniquindio.turismouq.repositorio;

import co.edu.uniquindio.turismouq.entidad.AuditoriaTarifa;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AuditoriaTarifaRepositorio extends JpaRepository<AuditoriaTarifa, Long> {
    List<AuditoriaTarifa> findTop50ByOrderByFechaAccionDesc();
}
