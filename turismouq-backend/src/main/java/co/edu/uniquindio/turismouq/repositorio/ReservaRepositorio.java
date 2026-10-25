package co.edu.uniquindio.turismouq.repositorio;

import co.edu.uniquindio.turismouq.entidad.Reserva;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ReservaRepositorio extends JpaRepository<Reserva, Long> {
    List<Reserva> findTop5ByOrderByIdReservaDesc();
    List<Reserva> findTop30ByOrderByIdReservaDesc();
    List<Reserva> findTop30ByOrderByFechaCreacionDesc();
    List<Reserva> findByClienteIdClienteOrderByFechaCreacionDesc(Long idCliente);
}
