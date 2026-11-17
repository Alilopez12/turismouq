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

    // Desglose noche a noche por temporada exigido
    private long nochesTemporadaAlta;
    private BigDecimal tarifaNocheAlta;
    private BigDecimal subtotalAlta;

    private long nochesTemporadaBaja;
    private BigDecimal tarifaNocheBaja;
    private BigDecimal subtotalBaja;

    private BigDecimal totalEstimado;

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

    public long getNochesTemporadaAlta() {
        return nochesTemporadaAlta;
    }

    public void setNochesTemporadaAlta(long nochesTemporadaAlta) {
        this.nochesTemporadaAlta = nochesTemporadaAlta;
    }

    public BigDecimal getTarifaNocheAlta() {
        return tarifaNocheAlta;
    }

    public void setTarifaNocheAlta(BigDecimal tarifaNocheAlta) {
        this.tarifaNocheAlta = tarifaNocheAlta;
    }

    public BigDecimal getSubtotalAlta() {
        return subtotalAlta;
    }

    public void setSubtotalAlta(BigDecimal subtotalAlta) {
        this.subtotalAlta = subtotalAlta;
    }

    public long getNochesTemporadaBaja() {
        return nochesTemporadaBaja;
    }

    public void setNochesTemporadaBaja(long nochesTemporadaBaja) {
        this.nochesTemporadaBaja = nochesTemporadaBaja;
    }

    public BigDecimal getTarifaNocheBaja() {
        return tarifaNocheBaja;
    }

    public void setTarifaNocheBaja(BigDecimal tarifaNocheBaja) {
        this.tarifaNocheBaja = tarifaNocheBaja;
    }

    public BigDecimal getSubtotalBaja() {
        return subtotalBaja;
    }

    public void setSubtotalBaja(BigDecimal subtotalBaja) {
        this.subtotalBaja = subtotalBaja;
    }

    public BigDecimal getTotalEstimado() {
        return totalEstimado;
    }

    public void setTotalEstimado(BigDecimal totalEstimado) {
        this.totalEstimado = totalEstimado;
    }
}
