package co.edu.uniquindio.turismouq.dto;

import java.time.LocalDate;

public class CotizacionPeticionDTO {

    private Long idHabitacion;
    private LocalDate fechaCheckIn;
    private LocalDate fechaCheckOut;

    public CotizacionPeticionDTO() {}

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
}
