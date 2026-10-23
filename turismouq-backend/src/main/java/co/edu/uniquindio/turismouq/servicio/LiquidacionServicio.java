package co.edu.uniquindio.turismouq.servicio;

import co.edu.uniquindio.turismouq.dto.LiquidacionPeticionDTO;
import co.edu.uniquindio.turismouq.entidad.LiquidacionMensual;

import java.util.List;

public interface LiquidacionServicio {

    int ejecutarLiquidacionMensual(LiquidacionPeticionDTO peticion);

    List<LiquidacionMensual> consultarLiquidaciones(Integer mes, Integer anio);
}
