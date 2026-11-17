package co.edu.uniquindio.turismouq.servicio;

import co.edu.uniquindio.turismouq.dto.CboAnalisisDTO;
import co.edu.uniquindio.turismouq.dto.SeguridadInfoDTO;
import co.edu.uniquindio.turismouq.dto.TransaccionPeticionDTO;
import co.edu.uniquindio.turismouq.dto.TransaccionRespuestaDTO;

import java.util.List;

public interface EntregaTresServicio {

    TransaccionRespuestaDTO ejecutarTransaccionSavepoint(TransaccionPeticionDTO peticion);

    List<CboAnalisisDTO> obtenerAnalisisCbo();

    SeguridadInfoDTO obtenerSeguridadRoles();
}
