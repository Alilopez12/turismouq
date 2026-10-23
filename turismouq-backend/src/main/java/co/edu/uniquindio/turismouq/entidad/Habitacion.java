package co.edu.uniquindio.turismouq.entidad;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;

@Entity
@Table(name = "HABITACION")
public class Habitacion {

    @Id
    @Column(name = "ID_HABITACION")
    private Long idHabitacion;

    @Column(name = "NUMERO_NOMBRE", nullable = false, length = 60)
    private String numeroNombre;

    @Column(name = "CAPACIDAD", nullable = false)
    private Integer capacidad;

    @Column(name = "TIPO_CAMA", length = 50)
    private String tipoCama;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "ID_ALOJAMIENTO", nullable = false)
    @JsonIgnoreProperties({"hibernateLazyInitializer", "handler"})
    private Alojamiento alojamiento;

    public Habitacion() {}

    public Long getIdHabitacion() {
        return idHabitacion;
    }

    public void setIdHabitacion(Long idHabitacion) {
        this.idHabitacion = idHabitacion;
    }

    public String getNumeroNombre() {
        return numeroNombre;
    }

    public void setNumeroNombre(String numeroNombre) {
        this.numeroNombre = numeroNombre;
    }

    public Integer getCapacidad() {
        return capacidad;
    }

    public void setCapacidad(Integer capacidad) {
        this.capacidad = capacidad;
    }

    public String getTipoCama() {
        return tipoCama;
    }

    public void setTipoCama(String tipoCama) {
        this.tipoCama = tipoCama;
    }

    public Alojamiento getAlojamiento() {
        return alojamiento;
    }

    public void setAlojamiento(Alojamiento alojamiento) {
        this.alojamiento = alojamiento;
    }
}
