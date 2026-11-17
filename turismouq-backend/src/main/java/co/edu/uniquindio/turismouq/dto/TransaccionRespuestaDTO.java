package co.edu.uniquindio.turismouq.dto;

import java.math.BigDecimal;

public class TransaccionRespuestaDTO {

    private Long idReserva;
    private Long idPago;
    private BigDecimal total;
    private String estadoReserva;
    private String mensaje;
    private boolean rollbackParcial;

    public TransaccionRespuestaDTO() {}

    public Long getIdReserva() {
        return idReserva;
    }

    public void setIdReserva(Long idReserva) {
        this.idReserva = idReserva;
    }

    public Long getIdPago() {
        return idPago;
    }

    public void setIdPago(Long idPago) {
        this.idPago = idPago;
    }

    public BigDecimal getTotal() {
        return total;
    }

    public void setTotal(BigDecimal total) {
        this.total = total;
    }

    public String getEstadoReserva() {
        return estadoReserva;
    }

    public void setEstadoReserva(String estadoReserva) {
        this.estadoReserva = estadoReserva;
    }

    public String getMensaje() {
        return mensaje;
    }

    public void setMensaje(String mensaje) {
        this.mensaje = mensaje;
    }

    public boolean isRollbackParcial() {
        return rollbackParcial;
    }

    public void setRollbackParcial(boolean rollbackParcial) {
        this.rollbackParcial = rollbackParcial;
    }
}
