package co.edu.uniquindio.turismouq.dto;

public class LiquidacionPeticionDTO {

    private Integer mes;
    private Integer anio;
    private Long idAlojamiento;

    public LiquidacionPeticionDTO() {}

    public Integer getMes() {
        return mes;
    }

    public void setMes(Integer mes) {
        this.mes = mes;
    }

    public Integer getAnio() {
        return anio;
    }

    public void setAnio(Integer anio) {
        this.anio = anio;
    }

    public Long getIdAlojamiento() {
        return idAlojamiento;
    }

    public void setIdAlojamiento(Long idAlojamiento) {
        this.idAlojamiento = idAlojamiento;
    }
}
