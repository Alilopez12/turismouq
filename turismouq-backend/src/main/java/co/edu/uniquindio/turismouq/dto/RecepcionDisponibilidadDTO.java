package co.edu.uniquindio.turismouq.dto;

public class RecepcionDisponibilidadDTO {

    private Long idHabitacion;
    private String habitacion;
    private String tipoCama;
    private Integer aforoMaximo;
    private Long idAlojamiento;
    private String alojamiento;
    private String municipio;
    private String telefonoAlojamiento;

    public RecepcionDisponibilidadDTO() {}

    public Long getIdHabitacion() {
        return idHabitacion;
    }

    public void setIdHabitacion(Long idHabitacion) {
        this.idHabitacion = idHabitacion;
    }

    public String getHabitacion() {
        return habitacion;
    }

    public void setHabitacion(String habitacion) {
        this.habitacion = habitacion;
    }

    public String getTipoCama() {
        return tipoCama;
    }

    public void setTipoCama(String tipoCama) {
        this.tipoCama = tipoCama;
    }

    public Integer getAforoMaximo() {
        return aforoMaximo;
    }

    public void setAforoMaximo(Integer aforoMaximo) {
        this.aforoMaximo = aforoMaximo;
    }

    public Long getIdAlojamiento() {
        return idAlojamiento;
    }

    public void setIdAlojamiento(Long idAlojamiento) {
        this.idAlojamiento = idAlojamiento;
    }

    public String getAlojamiento() {
        return alojamiento;
    }

    public void setAlojamiento(String alojamiento) {
        this.alojamiento = alojamiento;
    }

    public String getMunicipio() {
        return municipio;
    }

    public void setMunicipio(String municipio) {
        this.municipio = municipio;
    }

    public String getTelefonoAlojamiento() {
        return telefonoAlojamiento;
    }

    public void setTelefonoAlojamiento(String telefonoAlojamiento) {
        this.telefonoAlojamiento = telefonoAlojamiento;
    }
}
