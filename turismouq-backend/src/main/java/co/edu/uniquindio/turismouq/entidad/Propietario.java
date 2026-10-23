package co.edu.uniquindio.turismouq.entidad;

import jakarta.persistence.*;

@Entity
@Table(name = "PROPIETARIO")
public class Propietario {

    @Id
    @Column(name = "ID_PROPIETARIO")
    private Long idPropietario;

    @Column(name = "DOCUMENTO", nullable = false, length = 25)
    private String documento;

    @Column(name = "NOMBRES", nullable = false, length = 100)
    private String nombres;

    @Column(name = "TELEFONO", nullable = false, length = 25)
    private String telefono;

    @Column(name = "CORREO", nullable = false, length = 120)
    private String correo;

    public Propietario() {}

    public Long getIdPropietario() {
        return idPropietario;
    }

    public void setIdPropietario(Long idPropietario) {
        this.idPropietario = idPropietario;
    }

    public String getDocumento() {
        return documento;
    }

    public void setDocumento(String documento) {
        this.documento = documento;
    }

    public String getNombres() {
        return nombres;
    }

    public void setNombres(String nombres) {
        this.nombres = nombres;
    }

    public String getTelefono() {
        return telefono;
    }

    public void setTelefono(String telefono) {
        this.telefono = telefono;
    }

    public String getCorreo() {
        return correo;
    }

    public void setCorreo(String correo) {
        this.correo = correo;
    }
}
