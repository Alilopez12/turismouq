package co.edu.uniquindio.turismouq.entidad;

import jakarta.persistence.*;

@Entity
@Table(name = "TEMPORADA")
public class Temporada {

    @Id
    @Column(name = "ID_TEMPORADA")
    private Long idTemporada;

    @Column(name = "NOMBRE", nullable = false, length = 50)
    private String nombre;

    public Temporada() {}

    public Long getIdTemporada() {
        return idTemporada;
    }

    public void setIdTemporada(Long idTemporada) {
        this.idTemporada = idTemporada;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }
}
