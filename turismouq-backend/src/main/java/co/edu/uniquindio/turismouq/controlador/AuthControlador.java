package co.edu.uniquindio.turismouq.controlador;

import co.edu.uniquindio.turismouq.dto.LoginPeticionDTO;
import co.edu.uniquindio.turismouq.dto.LoginRespuestaDTO;
import co.edu.uniquindio.turismouq.dto.RegistroPeticionDTO;
import co.edu.uniquindio.turismouq.dto.RespuestaApiDTO;
import co.edu.uniquindio.turismouq.servicio.AuthServicio;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthControlador {

    private final AuthServicio authServicio;

    public AuthControlador(AuthServicio authServicio) {
        this.authServicio = authServicio;
    }

    @PostMapping("/login")
    public ResponseEntity<RespuestaApiDTO<LoginRespuestaDTO>> login(@Valid @RequestBody LoginPeticionDTO peticion) {
        LoginRespuestaDTO respuesta = authServicio.login(peticion);
        return ResponseEntity.ok(RespuestaApiDTO.exito("Autenticación exitosa", respuesta));
    }

    @PostMapping("/registro")
    public ResponseEntity<RespuestaApiDTO<LoginRespuestaDTO>> registrar(@Valid @RequestBody RegistroPeticionDTO peticion) {
        LoginRespuestaDTO respuesta = authServicio.registrar(peticion);
        return ResponseEntity.ok(RespuestaApiDTO.exito("Usuario registrado exitosamente con el rol seleccionado", respuesta));
    }

    @GetMapping("/roles")
    public ResponseEntity<RespuestaApiDTO<List<Map<String, String>>>> obtenerRoles() {
        List<Map<String, String>> roles = authServicio.obtenerRolesDisponibles();
        return ResponseEntity.ok(RespuestaApiDTO.exito("Roles disponibles en el sistema", roles));
    }
}
