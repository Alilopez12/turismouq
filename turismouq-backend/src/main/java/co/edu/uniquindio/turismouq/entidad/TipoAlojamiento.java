package co.edu.uniquindio.turismouq.entidad;

import jakarta.persistence.*;

@Entity
@Table(name = "TIPO_ALOJAMIENTO")
public class TipoAlojamiento {

    @Id
    @Column(name = "ID_TIPO_ALOJAMIENTO")
    private Long idTipoAlojamiento;

    @Column(name = "NOMBRE", nullable = false, length = 60)
    private String nombre;

    @Column(name = "DESCRIPCION", length = 300)
    private String descripcion;

    public TipoAlojamiento() {}

    public Long getIdTipoAlojamiento() {
        return idTipoAlojamiento;
    }

    public void setIdTipoAlojamiento(Long idTipoAlojamiento) {
        this.idTipoAlojamiento = idTipoAlojamiento;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getDescripcion() {
        return descripcion;
    }

    public void setDescripcion(String descripcion) {
        this.descripcion = descripcion;
    }
}
