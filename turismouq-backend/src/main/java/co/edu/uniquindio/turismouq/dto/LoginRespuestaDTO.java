package co.edu.uniquindio.turismouq.dto;

import java.util.List;

public class LoginRespuestaDTO {

    private String usuario;
    private String nombreCompleto;
    private String correo;
    private String rol;
    private String descripcionRol;
    private List<String> rutasPermitidas;

    public LoginRespuestaDTO() {}

    public LoginRespuestaDTO(String usuario, String nombreCompleto, String correo, String rol, String descripcionRol, List<String> rutasPermitidas) {
        this.usuario = usuario;
        this.nombreCompleto = nombreCompleto;
        this.correo = correo;
        this.rol = rol;
        this.descripcionRol = descripcionRol;
        this.rutasPermitidas = rutasPermitidas;
    }

    public String getUsuario() {
        return usuario;
    }

    public void setUsuario(String usuario) {
        this.usuario = usuario;
    }

    public String getNombreCompleto() {
        return nombreCompleto;
    }

    public void setNombreCompleto(String nombreCompleto) {
        this.nombreCompleto = nombreCompleto;
    }

    public String getCorreo() {
        return correo;
    }

    public void setCorreo(String correo) {
        this.correo = correo;
    }

    public String getRol() {
        return rol;
    }

    public void setRol(String rol) {
        this.rol = rol;
    }

    public String getDescripcionRol() {
        return descripcionRol;
    }

    public void setDescripcionRol(String descripcionRol) {
        this.descripcionRol = descripcionRol;
    }

    public List<String> getRutasPermitidas() {
        return rutasPermitidas;
    }

    public void setRutasPermitidas(List<String> rutasPermitidas) {
        this.rutasPermitidas = rutasPermitidas;
    }
}
