package co.edu.uniquindio.turismouq.dto;

import java.util.List;
import java.util.Map;

public class SeguridadInfoDTO {

    private Map<String, String> perfilSesion;
    private List<Map<String, Object>> roles;
    private List<Map<String, String>> vistasRecepcion;
    private String reglaOroRecepcion;

    public SeguridadInfoDTO() {}

    public Map<String, String> getPerfilSesion() {
        return perfilSesion;
    }

    public void setPerfilSesion(Map<String, String> perfilSesion) {
        this.perfilSesion = perfilSesion;
    }

    public List<Map<String, Object>> getRoles() {
        return roles;
    }

    public void setRoles(List<Map<String, Object>> roles) {
        this.roles = roles;
    }

    public List<Map<String, String>> getVistasRecepcion() {
        return vistasRecepcion;
    }

    public void setVistasRecepcion(List<Map<String, String>> vistasRecepcion) {
        this.vistasRecepcion = vistasRecepcion;
    }

    public String getReglaOroRecepcion() {
        return reglaOroRecepcion;
    }

    public void setReglaOroRecepcion(String reglaOroRecepcion) {
        this.reglaOroRecepcion = reglaOroRecepcion;
    }
}
