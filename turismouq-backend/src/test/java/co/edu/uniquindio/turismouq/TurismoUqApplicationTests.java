package co.edu.uniquindio.turismouq;

import co.edu.uniquindio.turismouq.dto.CotizacionPeticionDTO;
import co.edu.uniquindio.turismouq.dto.CotizacionRespuestaDTO;
import co.edu.uniquindio.turismouq.entidad.Municipio;
import co.edu.uniquindio.turismouq.servicio.AlojamientoServicio;
import co.edu.uniquindio.turismouq.servicio.AnaliticaServicio;
import co.edu.uniquindio.turismouq.servicio.ReservaServicio;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
class TurismoUqApplicationTests {

    @Autowired
    private AlojamientoServicio alojamientoServicio;

    @Autowired
    private ReservaServicio reservaServicio;

    @Autowired
    private AnaliticaServicio analiticaServicio;

    @Test
    void contextLoads() {
        assertNotNull(alojamientoServicio);
    }

    @Test
    void testListarMunicipios() {
        List<Municipio> municipios = alojamientoServicio.listarMunicipios();
        assertNotNull(municipios);
        assertEquals(12, municipios.size(), "Deben existir exactamente 12 municipios del Quindío");
    }

    @Test
    void testCotizacionEstadiaPlSql() {
        CotizacionPeticionDTO peticion = new CotizacionPeticionDTO();
        peticion.setIdHabitacion(1L);
        // Cruzando baja y alta (Semana Santa inicia el 23 de marzo de 2024)
        peticion.setFechaCheckIn(LocalDate.of(2024, 3, 21));
        peticion.setFechaCheckOut(LocalDate.of(2024, 3, 26));

        CotizacionRespuestaDTO cotizacion = reservaServicio.cotizarEstadia(peticion);
        assertNotNull(cotizacion);
        assertNotNull(cotizacion.getTotalPagar());
        assertTrue(cotizacion.getTotalPagar().doubleValue() > 0);
        assertEquals(5, cotizacion.getTotalNoches());
    }

    @Test
    void testConsultaPivotAnalitica() {
        List<Map<String, Object>> pivot = analiticaServicio.obtenerOcupacionPivot();
        assertNotNull(pivot);
        assertFalse(pivot.isEmpty(), "La consulta PIVOT debe retornar datos para los municipios");
    }
}
