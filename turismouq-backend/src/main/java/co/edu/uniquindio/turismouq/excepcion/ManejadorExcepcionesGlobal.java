package co.edu.uniquindio.turismouq.excepcion;

import co.edu.uniquindio.turismouq.dto.RespuestaApiDTO;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.sql.SQLException;

@RestControllerAdvice
public class ManejadorExcepcionesGlobal {

    private static final Logger log = LoggerFactory.getLogger(ManejadorExcepcionesGlobal.class);

    @ExceptionHandler(NegocioExcepcion.class)
    public ResponseEntity<RespuestaApiDTO<Void>> manejarNegocioExcepcion(NegocioExcepcion ex) {
        log.warn("Excepción de negocio: {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(RespuestaApiDTO.error(ex.getMessage()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<RespuestaApiDTO<Void>> manejarExcepcionGeneral(Exception ex) {
        log.error("Excepción no controlada:", ex);
        String mensaje = ex.getMessage();
        Throwable causa = ex;
        while (causa != null) {
            if (causa instanceof SQLException sqlEx) {
                mensaje = formatearErrorOracle(sqlEx);
                return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                        .body(RespuestaApiDTO.error(mensaje));
            }
            causa = causa.getCause();
        }

        if (mensaje != null && mensaje.contains("ORA-")) {
            mensaje = extraerMensajeOra(mensaje);
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body(RespuestaApiDTO.error(mensaje));
        }

        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(RespuestaApiDTO.error("Ocurrió un error inesperado: " + ex.getMessage()));
    }

    private String formatearErrorOracle(SQLException sqlEx) {
        int codigo = sqlEx.getErrorCode();
        String mensaje = sqlEx.getMessage();

        if (codigo == 20001 || (mensaje != null && mensaje.contains("ORA-20001"))) {
            return "Fechas inválidas: La fecha de check-out debe ser posterior al check-in.";
        } else if (codigo == 20002 || (mensaje != null && mensaje.contains("ORA-20002"))) {
            return "Habitación no disponible: La habitación ya se encuentra reservada en el rango de fechas solicitado.";
        } else if (codigo == 20003 || (mensaje != null && mensaje.contains("ORA-20003"))) {
            return "Capacidad excedida: El número de huéspedes supera la capacidad máxima de la habitación.";
        } else if (codigo == 20004 || (mensaje != null && mensaje.contains("ORA-20004"))) {
            return "Entidad no encontrada: El registro especificado no existe en la base de datos.";
        }

        return extraerMensajeOra(mensaje);
    }

    private String extraerMensajeOra(String mensaje) {
        if (mensaje == null) return "Error de base de datos.";
        int posOra = mensaje.indexOf("ORA-");
        if (posOra != -1) {
            int posFinLinea = mensaje.indexOf("\n", posOra);
            if (posFinLinea != -1) {
                return mensaje.substring(posOra, posFinLinea).trim();
            }
            return mensaje.substring(posOra).trim();
        }
        return mensaje;
    }
}
