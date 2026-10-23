package co.edu.uniquindio.turismouq.servicio;

import java.util.List;
import java.util.Map;

public interface AnaliticaServicio {

    List<Map<String, Object>> obtenerOcupacionPivot();

    List<Map<String, Object>> obtenerIngresosRollup();

    List<Map<String, Object>> obtenerTop3PorMunicipio();

    List<Map<String, Object>> obtenerVariacionLag();

    List<Map<String, Object>> obtenerConsultaParametrizada(String fechaInicio, String fechaFin);

    List<Map<String, Object>> obtenerVistaMaterializadaOcupacion();

    List<Map<String, Object>> obtenerConsultaUnpivot();

    List<Map<String, Object>> obtenerServiciosNegocioLibre();

    List<Map<String, Object>> obtenerAuditoriaTarifas();

    Map<String, Object> obtenerMonitoreoTablespace();
}
