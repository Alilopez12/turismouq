package co.edu.uniquindio.turismouq.entidad;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import java.math.BigDecimal;

@Entity
@Table(name = "TARIFA")
public class Tarifa {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID_TARIFA")
    private Long idTarifa;

    @Column(name = "PRECIO_NOCHE", nullable = false, precision = 12, scale = 2)
    private BigDecimal precioNoche;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "ID_TEMPORADA", nullable = false)
    private Temporada temporada;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ID_HABITACION", nullable = false)
    @JsonIgnore
    private Habitacion habitacion;

    public Tarifa() {}

    public Long getIdTarifa() {
        return idTarifa;
    }

    public void setIdTarifa(Long idTarifa) {
        this.idTarifa = idTarifa;
    }

    public BigDecimal getPrecioNoche() {
        return precioNoche;
    }

    public void setPrecioNoche(BigDecimal precioNoche) {
        this.precioNoche = precioNoche;
    }

    public Temporada getTemporada() {
        return temporada;
    }

    public void setTemporada(Temporada temporada) {
        this.temporada = temporada;
    }

    public Habitacion getHabitacion() {
        return habitacion;
    }

    public void setHabitacion(Habitacion habitacion) {
        this.habitacion = habitacion;
    }
}
