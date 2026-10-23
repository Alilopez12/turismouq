package co.edu.uniquindio.turismouq.entidad;

import jakarta.persistence.*;

@Entity
@Table(name = "MUNICIPIO")
public class Municipio {

    @Id
    @Column(name = "ID_MUNICIPIO")
    private Long idMunicipio;

    @Column(name = "NOMBRE", nullable = false, length = 60)
    private String nombre;

    public Municipio() {}

    public Municipio(Long idMunicipio, String nombre) {
        this.idMunicipio = idMunicipio;
        this.nombre = nombre;
    }

    public Long getIdMunicipio() {
        return idMunicipio;
    }

    public void setIdMunicipio(Long idMunicipio) {
        this.idMunicipio = idMunicipio;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }
}
