package co.edu.uniquindio.turismouq.dto;

import java.time.LocalDate;

public class TransaccionPeticionDTO {

    private Long idCliente;
    private Long idHabitacion;
    private LocalDate fechaCheckIn;
    private LocalDate fechaCheckOut;
    private Integer numeroHuespedes;
    private String metodoPago;
    private boolean simularFallo;

    public TransaccionPeticionDTO() {}

    public Long getIdCliente() {
        return idCliente;
    }

    public void setIdCliente(Long idCliente) {
        this.idCliente = idCliente;
    }

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

    public Integer getNumeroHuespedes() {
        return numeroHuespedes;
    }

    public void setNumeroHuespedes(Integer numeroHuespedes) {
        this.numeroHuespedes = numeroHuespedes;
    }

    public String getMetodoPago() {
        return metodoPago;
    }

    public void setMetodoPago(String metodoPago) {
        this.metodoPago = metodoPago;
    }

    public boolean isSimularFallo() {
        return simularFallo;
    }

    public void setSimularFallo(boolean simularFallo) {
        this.simularFallo = simularFallo;
    }
}
