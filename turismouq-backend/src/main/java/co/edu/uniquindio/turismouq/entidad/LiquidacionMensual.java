package co.edu.uniquindio.turismouq.entidad;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
@Table(name = "LIQUIDACION_MENSUAL")
public class LiquidacionMensual {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ID_LIQUIDACION")
    private Long idLiquidacion;

    @Column(name = "ID_ALOJAMIENTO", nullable = false)
    private Long idAlojamiento;

    @Column(name = "NOMBRE_ALOJAMIENTO", nullable = false, length = 120)
    private String nombreAlojamiento;

    @Column(name = "MUNICIPIO", nullable = false, length = 60)
    private String municipio;

    @Column(name = "PROPIETARIO", nullable = false, length = 120)
    private String propietario;

    @Column(name = "MES", nullable = false)
    private Integer mes;

    @Column(name = "ANIO", nullable = false)
    private Integer anio;

    @Column(name = "TOTAL_RESERVAS", nullable = false)
    private Long totalReservas;

    @Column(name = "INGRESOS_HOSPEDAJE", nullable = false, precision = 14, scale = 2)
    private BigDecimal ingresosHospedaje;

    @Column(name = "INGRESOS_SERVICIOS", nullable = false, precision = 14, scale = 2)
    private BigDecimal ingresosServicios;

    @Column(name = "TOTAL_BRUTO", nullable = false, precision = 14, scale = 2)
    private BigDecimal totalBruto;

    @Column(name = "COMISION_PLATAFORMA", nullable = false, precision = 14, scale = 2)
    private BigDecimal comisionPlataforma;

    @Column(name = "PAGO_NETO_PROPIETARIO", nullable = false, precision = 14, scale = 2)
    private BigDecimal pagoNetoPropietario;

    @Column(name = "FECHA_LIQUIDACION", nullable = false)
    private LocalDate fechaLiquidacion;

    public LiquidacionMensual() {}

    public Long getIdLiquidacion() {
        return idLiquidacion;
    }

    public void setIdLiquidacion(Long idLiquidacion) {
        this.idLiquidacion = idLiquidacion;
    }

    public Long getIdAlojamiento() {
        return idAlojamiento;
    }

    public void setIdAlojamiento(Long idAlojamiento) {
        this.idAlojamiento = idAlojamiento;
    }

    public String getNombreAlojamiento() {
        return nombreAlojamiento;
    }

    public void setNombreAlojamiento(String nombreAlojamiento) {
        this.nombreAlojamiento = nombreAlojamiento;
    }

    public String getMunicipio() {
        return municipio;
    }

    public void setMunicipio(String municipio) {
        this.municipio = municipio;
    }

    public String getPropietario() {
        return propietario;
    }

    public void setPropietario(String propietario) {
        this.propietario = propietario;
    }

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

    public Long getTotalReservas() {
        return totalReservas;
    }

    public void setTotalReservas(Long totalReservas) {
        this.totalReservas = totalReservas;
    }

    public BigDecimal getIngresosHospedaje() {
        return ingresosHospedaje;
    }

    public void setIngresosHospedaje(BigDecimal ingresosHospedaje) {
        this.ingresosHospedaje = ingresosHospedaje;
    }

    public BigDecimal getIngresosServicios() {
        return ingresosServicios;
    }

    public void setIngresosServicios(BigDecimal ingresosServicios) {
        this.ingresosServicios = ingresosServicios;
    }

    public BigDecimal getTotalBruto() {
        return totalBruto;
    }

    public void setTotalBruto(BigDecimal totalBruto) {
        this.totalBruto = totalBruto;
    }

    public BigDecimal getComisionPlataforma() {
        return comisionPlataforma;
    }

    public void setComisionPlataforma(BigDecimal comisionPlataforma) {
        this.comisionPlataforma = comisionPlataforma;
    }

    public BigDecimal getPagoNetoPropietario() {
        return pagoNetoPropietario;
    }

    public void setPagoNetoPropietario(BigDecimal pagoNetoPropietario) {
        this.pagoNetoPropietario = pagoNetoPropietario;
    }

    public LocalDate getFechaLiquidacion() {
        return fechaLiquidacion;
    }

    public void setFechaLiquidacion(LocalDate fechaLiquidacion) {
        this.fechaLiquidacion = fechaLiquidacion;
    }
}
