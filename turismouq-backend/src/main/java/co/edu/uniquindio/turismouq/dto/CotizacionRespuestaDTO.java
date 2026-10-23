package co.edu.uniquindio.turismouq.dto;

import java.math.BigDecimal;
import java.time.LocalDate;

public class CotizacionRespuestaDTO {

    private Long idHabitacion;
    private LocalDate fechaCheckIn;
    private LocalDate fechaCheckOut;
    private long totalNoches;
    private BigDecimal totalPagar;
    private String descripcionTemporadas;

    public CotizacionRespuestaDTO() {}

    public Long getIdHabitacion() {
        return idHabitacion;
    }

    public void setIdHabitacion(Long idHabitacion) {
        this.idHabitacion = idHabitacion;
    }

    public LocalDate getFechaCheckIn() {
        return fechaCheckIn;
    }

    public void setFechaCheckIn(LocalDate fechaCheckIn) {
        this.fechaCheckIn = fechaCheckIn;
    }

    public LocalDate getFechaCheckOut() {
        return fechaCheckOut;
    }

    public void setFechaCheckOut(LocalDate fechaCheckOut) {
        this.fechaCheckOut = fechaCheckOut;
    }

    public long getTotalNoches() {
        return totalNoches;
    }

    public void setTotalNoches(long totalNoches) {
        this.totalNoches = totalNoches;
    }

    public BigDecimal getTotalPagar() {
        return totalPagar;
    }

    public void setTotalPagar(BigDecimal totalPagar) {
        this.totalPagar = totalPagar;
    }

    public String getDescripcionTemporadas() {
        return descripcionTemporadas;
    }

    public void setDescripcionTemporadas(String descripcionTemporadas) {
        this.descripcionTemporadas = descripcionTemporadas;
    }
}
