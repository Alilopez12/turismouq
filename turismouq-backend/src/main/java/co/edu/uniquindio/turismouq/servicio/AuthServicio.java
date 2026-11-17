package co.edu.uniquindio.turismouq.servicio;

import co.edu.uniquindio.turismouq.dto.LoginPeticionDTO;
import co.edu.uniquindio.turismouq.dto.LoginRespuestaDTO;
import co.edu.uniquindio.turismouq.dto.RegistroPeticionDTO;

import java.util.List;
import java.util.Map;

public interface AuthServicio {
    LoginRespuestaDTO login(LoginPeticionDTO peticion);
    LoginRespuestaDTO registrar(RegistroPeticionDTO peticion);
    List<Map<String, String>> obtenerRolesDisponibles();
}
