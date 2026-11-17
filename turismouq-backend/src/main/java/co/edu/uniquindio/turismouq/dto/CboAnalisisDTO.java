package co.edu.uniquindio.turismouq.dto;

public class CboAnalisisDTO {

    private String id;
    private String titulo;
    private String consultaSql;
    private String tipoIndice;
    private String ddlIndice;
    private String costoAntes;
    private String costoDespues;
    private String planAntes;
    private String planDespues;
    private String explicacion;
    private boolean casoNegativo;

    public CboAnalisisDTO() {}

    public CboAnalisisDTO(String id, String titulo, String consultaSql, String tipoIndice, String ddlIndice,
                          String costoAntes, String costoDespues, String planAntes, String planDespues,
                          String explicacion, boolean casoNegativo) {
        this.id = id;
        this.titulo = titulo;
        this.consultaSql = consultaSql;
        this.tipoIndice = tipoIndice;
        this.ddlIndice = ddlIndice;
        this.costoAntes = costoAntes;
        this.costoDespues = costoDespues;
        this.planAntes = planAntes;
        this.planDespues = planDespues;
        this.explicacion = explicacion;
        this.casoNegativo = casoNegativo;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getTitulo() {
        return titulo;
    }

    public void setTitulo(String titulo) {
        this.titulo = titulo;
    }

    public String getConsultaSql() {
        return consultaSql;
    }

    public void setConsultaSql(String consultaSql) {
        this.consultaSql = consultaSql;
    }

    public String getTipoIndice() {
        return tipoIndice;
    }

    public void setTipoIndice(String tipoIndice) {
        this.tipoIndice = tipoIndice;
    }

    public String getDdlIndice() {
        return ddlIndice;
    }

    public void setDdlIndice(String ddlIndice) {
        this.ddlIndice = ddlIndice;
    }

    public String getCostoAntes() {
        return costoAntes;
    }

    public void setCostoAntes(String costoAntes) {
        this.costoAntes = costoAntes;
    }

    public String getCostoDespues() {
        return costoDespues;
    }

    public void setCostoDespues(String costoDespues) {
        this.costoDespues = costoDespues;
    }

    public String getPlanAntes() {
        return planAntes;
    }

    public void setPlanAntes(String planAntes) {
        this.planAntes = planAntes;
    }

    public String getPlanDespues() {
        return planDespues;
    }

    public void setPlanDespues(String planDespues) {
        this.planDespues = planDespues;
    }

    public String getExplicacion() {
        return explicacion;
    }

    public void setExplicacion(String explicacion) {
        this.explicacion = explicacion;
    }

    public boolean isCasoNegativo() {
        return casoNegativo;
    }

    public void setCasoNegativo(boolean casoNegativo) {
        this.casoNegativo = casoNegativo;
    }
}
