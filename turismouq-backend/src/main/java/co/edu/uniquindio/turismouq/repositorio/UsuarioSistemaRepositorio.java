package co.edu.uniquindio.turismouq.repositorio;

import co.edu.uniquindio.turismouq.entidad.UsuarioSistema;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UsuarioSistemaRepositorio extends JpaRepository<UsuarioSistema, Long> {
    Optional<UsuarioSistema> findByUsuario(String usuario);
    boolean existsByUsuario(String usuario);
    boolean existsByCorreo(String correo);
}
