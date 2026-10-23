package co.edu.uniquindio.turismouq.entidad;

import jakarta.persistence.*;

@Entity
@Table(name = "ALOJAMIENTO")
public class Alojamiento {

    @Id
    @Column(name = "ID_ALOJAMIENTO")
    private Long idAlojamiento;

    @Column(name = "NOMBRE", nullable = false, length = 120)
    private String nombre;

    @Column(name = "DIRECCION", nullable = false, length = 150)
    private String direccion;

    @Column(name = "TELEFONO", nullable = false, length = 25)
    private String telefono;

    @Column(name = "CAPACIDAD", nullable = false)
    private Integer capacidad;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "ID_MUNICIPIO", nullable = false)
    private Municipio municipio;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "ID_TIPO_ALOJAMIENTO", nullable = false)
    private TipoAlojamiento tipoAlojamiento;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "ID_PROPIETARIO", nullable = false)
    private Propietario propietario;

    public Alojamiento() {}

    public Long getIdAlojamiento() {
        return idAlojamiento;
    }

    public void setIdAlojamiento(Long idAlojamiento) {
        this.idAlojamiento = idAlojamiento;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getDireccion() {
        return direccion;
    }

    public void setDireccion(String direccion) {
        this.direccion = direccion;
    }

    public String getTelefono() {
        return telefono;
    }

    public void setTelefono(String telefono) {
        this.telefono = telefono;
    }

    public Integer getCapacidad() {
        return capacidad;
    }

    public void setCapacidad(Integer capacidad) {
        this.capacidad = capacidad;
    }

    public Municipio getMunicipio() {
        return municipio;
    }

    public void setMunicipio(Municipio municipio) {
        this.municipio = municipio;
    }

    public TipoAlojamiento getTipoAlojamiento() {
        return tipoAlojamiento;
    }

    public void setTipoAlojamiento(TipoAlojamiento tipoAlojamiento) {
        this.tipoAlojamiento = tipoAlojamiento;
    }

    public Propietario getPropietario() {
        return propietario;
    }

    public void setPropietario(Propietario propietario) {
        this.propietario = propietario;
    }
}
