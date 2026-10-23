package co.edu.uniquindio.turismouq.entidad;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "AUDITORIA_TARIFA")
public class AuditoriaTarifa {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID_AUDITORIA")
    private Long idAuditoria;

    @Column(name = "ID_TARIFA")
    private Long idTarifa;

    @Column(name = "ID_HABITACION")
    private Long idHabitacion;

    @Column(name = "ID_TEMPORADA")
    private Long idTemporada;

    @Column(name = "PRECIO_ANTERIOR", precision = 12, scale = 2)
    private BigDecimal precioAnterior;

    @Column(name = "PRECIO_NUEVO", precision = 12, scale = 2)
    private BigDecimal precioNuevo;

    @Column(name = "USUARIO_ORACLE", nullable = false, length = 50)
    private String usuarioOracle;

    @Column(name = "FECHA_ACCION", nullable = false)
    private LocalDateTime fechaAccion;

    @Column(name = "TIPO_OPERACION", nullable = false, length = 20)
    private String tipoOperacion;

    @Column(name = "DETALLE_SENTENCIA", length = 250)
    private String detalleSentencia;

    public AuditoriaTarifa() {}

    public Long getIdAuditoria() {
        return idAuditoria;
    }

    public void setIdAuditoria(Long idAuditoria) {
        this.idAuditoria = idAuditoria;
    }

    public Long getIdTarifa() {
        return idTarifa;
    }

    public void setIdTarifa(Long idTarifa) {
        this.idTarifa = idTarifa;
    }

    public Long getIdHabitacion() {
        return idHabitacion;
    }

    public void setIdHabitacion(Long idHabitacion) {
        this.idHabitacion = idHabitacion;
    }

    public Long getIdTemporada() {
        return idTemporada;
    }

    public void setIdTemporada(Long idTemporada) {
        this.idTemporada = idTemporada;
    }

    public BigDecimal getPrecioAnterior() {
        return precioAnterior;
    }

    public void setPrecioAnterior(BigDecimal precioAnterior) {
        this.precioAnterior = precioAnterior;
    }

    public BigDecimal getPrecioNuevo() {
        return precioNuevo;
    }

    public void setPrecioNuevo(BigDecimal precioNuevo) {
        this.precioNuevo = precioNuevo;
    }

    public String getUsuarioOracle() {
        return usuarioOracle;
    }

    public void setUsuarioOracle(String usuarioOracle) {
        this.usuarioOracle = usuarioOracle;
    }

    public LocalDateTime getFechaAccion() {
        return fechaAccion;
    }

    public void setFechaAccion(LocalDateTime fechaAccion) {
        this.fechaAccion = fechaAccion;
    }

    public String getTipoOperacion() {
        return tipoOperacion;
    }

    public void setTipoOperacion(String tipoOperacion) {
        this.tipoOperacion = tipoOperacion;
    }

    public String getDetalleSentencia() {
        return detalleSentencia;
    }

    public void setDetalleSentencia(String detalleSentencia) {
        this.detalleSentencia = detalleSentencia;
    }
}
