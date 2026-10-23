package co.edu.uniquindio.turismouq.repositorio;

import co.edu.uniquindio.turismouq.entidad.LiquidacionMensual;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface LiquidacionMensualRepositorio extends JpaRepository<LiquidacionMensual, Long> {
    List<LiquidacionMensual> findByMesAndAnioOrderByTotalBrutoDesc(Integer mes, Integer anio);
    List<LiquidacionMensual> findByIdAlojamientoOrderByAnioDescMesDesc(Long idAlojamiento);
}
