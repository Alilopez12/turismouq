package co.edu.uniquindio.turismouq.servicio;

import co.edu.uniquindio.turismouq.dto.LoginPeticionDTO;
import co.edu.uniquindio.turismouq.dto.LoginRespuestaDTO;
import co.edu.uniquindio.turismouq.dto.RegistroPeticionDTO;
import co.edu.uniquindio.turismouq.entidad.UsuarioSistema;
import co.edu.uniquindio.turismouq.excepcion.NegocioExcepcion;
import co.edu.uniquindio.turismouq.repositorio.UsuarioSistemaRepositorio;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
public class AuthServicioImpl implements AuthServicio {

    private final UsuarioSistemaRepositorio usuarioSistemaRepositorio;

    public AuthServicioImpl(UsuarioSistemaRepositorio usuarioSistemaRepositorio) {
        this.usuarioSistemaRepositorio = usuarioSistemaRepositorio;
    }

    @Override
    @Transactional(readOnly = true)
    public LoginRespuestaDTO login(LoginPeticionDTO peticion) {
        UsuarioSistema usuario = usuarioSistemaRepositorio.findByUsuario(peticion.getUsuario().trim())
                .orElseThrow(() -> new NegocioExcepcion("Credenciales inválidas: El usuario no existe"));

        if (!usuario.getContrasena().equals(peticion.getContrasena())) {
            throw new NegocioExcepcion("Credenciales inválidas: Contraseña incorrecta");
        }

        return construirRespuesta(usuario);
    }

    @Override
    @Transactional
    public LoginRespuestaDTO registrar(RegistroPeticionDTO peticion) {
        String usuario = peticion.getUsuario().trim();
        String correo = peticion.getCorreo().trim();

        if (usuarioSistemaRepositorio.existsByUsuario(usuario)) {
            throw new NegocioExcepcion("El nombre de usuario '" + usuario + "' ya se encuentra registrado.");
        }

        if (usuarioSistemaRepositorio.existsByCorreo(correo)) {
            throw new NegocioExcepcion("El correo electrónico '" + correo + "' ya está registrado en el sistema.");
        }

        String rol = peticion.getRol().trim();
        validarRol(rol);

        UsuarioSistema nuevo = new UsuarioSistema(
                usuario,
                peticion.getContrasena(),
                peticion.getNombreCompleto().trim(),
                correo,
                rol
        );

        UsuarioSistema guardado = usuarioSistemaRepositorio.save(nuevo);
        return construirRespuesta(guardado);
    }

    @Override
    public List<Map<String, String>> obtenerRolesDisponibles() {
        return List.of(
                Map.of("rol", "ROL_RECEPCION", "nombre", "Personal de Recepción", "descripcion", "Check-in diario, consulta de disponibilidad e inventario de habitaciones."),
                Map.of("rol", "ROL_ADMIN_ALOJAMIENTO", "nombre", "Administrador de Alojamiento", "descripcion", "Gestión de propiedades, habitaciones y liquidaciones propias."),
                Map.of("rol", "ROL_GERENTE", "nombre", "Gerencia Turística", "descripcion", "Toma de decisiones, liquidaciones masivas y Data Studio analítico."),
                Map.of("rol", "ROL_AUDITOR", "nombre", "Auditor de Cumplimiento", "descripcion", "Pistas de auditoría de tarifas y bitácoras forenses de sentencias DML."),
                Map.of("rol", "ROL_SUPER_ADMIN", "nombre", "Super Administrador", "descripcion", "Acceso irrestricto a todos los módulos del sistema.")
        );
    }

    private void validarRol(String rol) {
        List<String> permitidos = List.of("ROL_RECEPCION", "ROL_ADMIN_ALOJAMIENTO", "ROL_GERENTE", "ROL_AUDITOR", "ROL_SUPER_ADMIN", "RECEPCION", "ADMINISTRADOR", "GERENTE", "AUDITOR");
        if (!permitidos.contains(rol)) {
            throw new NegocioExcepcion("El rol seleccionado '" + rol + "' no es válido.");
        }
    }

    private LoginRespuestaDTO construirRespuesta(UsuarioSistema u) {
        String descripcion;
        List<String> rutas;
        String rol = u.getRol().toUpperCase();

        if (rol.contains("SUPER_ADMIN") || rol.contains("ADMINISTRADOR")) {
            descripcion = "Super Administrador (DBA TurismoUQ - Acceso Total)";
            rutas = List.of(
                    "/catalogo", "/reservas", "/recepcion", "/liquidaciones",
                    "/analitica", "/auditoria", "/tablespace",
                    "/transacciones", "/concurrencia", "/optimizador-cbo"
            );
        } else if (rol.contains("RECEPCION")) {
            descripcion = "Mostrador y Recepción (Vistas operativas seguras)";
            rutas = List.of("/recepcion", "/reservas", "/catalogo");
        } else if (rol.contains("ADMIN_ALOJAMIENTO")) {
            descripcion = "Administración de Alojamientos y Propiedades";
            rutas = List.of("/catalogo", "/reservas", "/liquidaciones");
        } else if (rol.contains("GERENTE")) {
            descripcion = "Gerencia y Dirección Turística";
            rutas = List.of("/catalogo", "/liquidaciones", "/analitica");
        } else if (rol.contains("AUDITOR")) {
            descripcion = "Auditoría Forense e Inspección de Tarifas";
            rutas = List.of("/auditoria", "/tablespace", "/transacciones", "/concurrencia");
        } else {
            descripcion = "Usuario Turista / Huésped";
            rutas = List.of("/catalogo", "/reservas");
        }

        return new LoginRespuestaDTO(
                u.getUsuario(),
                u.getNombreCompleto(),
                u.getCorreo(),
                u.getRol(),
                descripcion,
                rutas
        );
    }
}
