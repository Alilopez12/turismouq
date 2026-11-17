package co.edu.uniquindio.turismouq.dto;

import java.time.LocalDate;

public class RecepcionCheckinDTO {

    private Long idReserva;
    private String documentoHuesped;
    private String nombreHuesped;
    private String telefonoContacto;
    private String alojamiento;
    private String municipio;
    private String habitacion;
    private LocalDate fechaCheckIn;
    private LocalDate fechaCheckOut;
    private Integer totalNoches;
    private String estado;

    public RecepcionCheckinDTO() {}

    public Long getIdReserva() {
        return idReserva;
    }

    public void setIdReserva(Long idReserva) {
        this.idReserva = idReserva;
    }

    public String getDocumentoHuesped() {
        return documentoHuesped;
    }

    public void setDocumentoHuesped(String documentoHuesped) {
        this.documentoHuesped = documentoHuesped;
    }

    public String getNombreHuesped() {
        return nombreHuesped;
    }

    public void setNombreHuesped(String nombreHuesped) {
        this.nombreHuesped = nombreHuesped;
    }

    public String getTelefonoContacto() {
        return telefonoContacto;
    }

    public void setTelefonoContacto(String telefonoContacto) {
        this.telefonoContacto = telefonoContacto;
    }

    public String getAlojamiento() {
        return alojamiento;
    }

    public void setAlojamiento(String alojamiento) {
        this.alojamiento = alojamiento;
    }

    public String getMunicipio() {
        return municipio;
    }

    public void setMunicipio(String municipio) {
        this.municipio = municipio;
    }

    public String getHabitacion() {
        return habitacion;
    }

    public void setHabitacion(String habitacion) {
        this.habitacion = habitacion;
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

    public Integer getTotalNoches() {
        return totalNoches;
    }

    public void setTotalNoches(Integer totalNoches) {
        this.totalNoches = totalNoches;
    }

    public String getEstado() {
        return estado;
    }

    public void setEstado(String estado) {
        this.estado = estado;
    }
}
