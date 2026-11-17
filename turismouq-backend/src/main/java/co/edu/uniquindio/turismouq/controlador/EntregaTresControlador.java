package co.edu.uniquindio.turismouq.controlador;

import co.edu.uniquindio.turismouq.dto.CboAnalisisDTO;
import co.edu.uniquindio.turismouq.dto.RespuestaApiDTO;
import co.edu.uniquindio.turismouq.dto.SeguridadInfoDTO;
import co.edu.uniquindio.turismouq.dto.TransaccionPeticionDTO;
import co.edu.uniquindio.turismouq.dto.TransaccionRespuestaDTO;
import co.edu.uniquindio.turismouq.servicio.EntregaTresServicio;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/entrega3")
public class EntregaTresControlador {

    private final EntregaTresServicio entregaTresServicio;

    public EntregaTresControlador(EntregaTresServicio entregaTresServicio) {
        this.entregaTresServicio = entregaTresServicio;
    }

    @PostMapping("/transaccion-savepoint")
    public ResponseEntity<RespuestaApiDTO<TransaccionRespuestaDTO>> ejecutarTransaccionSavepoint(
            @RequestBody TransaccionPeticionDTO peticion) {
        TransaccionRespuestaDTO respuesta = entregaTresServicio.ejecutarTransaccionSavepoint(peticion);
        return ResponseEntity.ok(RespuestaApiDTO.exito(respuesta.getMensaje(), respuesta));
    }

    @GetMapping("/planes-cbo")
    public ResponseEntity<RespuestaApiDTO<List<CboAnalisisDTO>>> obtenerPlanesCbo() {
        List<CboAnalisisDTO> planes = entregaTresServicio.obtenerAnalisisCbo();
        return ResponseEntity.ok(RespuestaApiDTO.exito("Análisis de planes de ejecución CBO e índices", planes));
    }

    @GetMapping("/seguridad-roles")
    public ResponseEntity<RespuestaApiDTO<SeguridadInfoDTO>> obtenerSeguridadRoles() {
        SeguridadInfoDTO info = entregaTresServicio.obtenerSeguridadRoles();
        return ResponseEntity.ok(RespuestaApiDTO.exito("Configuración de roles, vistas y perfil de sesión", info));
    }
}
