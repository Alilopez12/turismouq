package co.edu.uniquindio.turismouq.servicio;

import co.edu.uniquindio.turismouq.dto.LiquidacionPeticionDTO;
import co.edu.uniquindio.turismouq.entidad.LiquidacionMensual;
import co.edu.uniquindio.turismouq.excepcion.NegocioExcepcion;
import co.edu.uniquindio.turismouq.repositorio.LiquidacionMensualRepositorio;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.sql.DataSource;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Types;
import java.util.List;

@Service
public class LiquidacionServicioImpl implements LiquidacionServicio {

    private final DataSource dataSource;
    private final LiquidacionMensualRepositorio liquidacionMensualRepositorio;

    public LiquidacionServicioImpl(DataSource dataSource, LiquidacionMensualRepositorio liquidacionMensualRepositorio) {
        this.dataSource = dataSource;
        this.liquidacionMensualRepositorio = liquidacionMensualRepositorio;
    }

    @Override
    @Transactional
    public int ejecutarLiquidacionMensual(LiquidacionPeticionDTO peticion) {
        if (peticion.getMes() == null || peticion.getMes() < 1 || peticion.getMes() > 12) {
            throw new NegocioExcepcion("El mes debe ser un valor entre 1 y 12.");
        }
        if (peticion.getAnio() == null || peticion.getAnio() < 2020) {
            throw new NegocioExcepcion("El año ingresado no es válido.");
        }

        // Llamada al procedimiento masivo con cursor explícito PKG_TURISMO_UQ.sp_liquidacion_mensual_alojamiento
        try (Connection conexion = dataSource.getConnection();
             CallableStatement sentencia = conexion.prepareCall("{call PKG_TURISMO_UQ.sp_liquidacion_mensual_alojamiento(?, ?, ?, ?)}")) {

            sentencia.setInt(1, peticion.getMes());
            sentencia.setInt(2, peticion.getAnio());

            if (peticion.getIdAlojamiento() != null) {
                sentencia.setLong(3, peticion.getIdAlojamiento());
            } else {
                sentencia.setNull(3, Types.NUMERIC);
            }

            sentencia.registerOutParameter(4, Types.NUMERIC); // p_total_procesados

            sentencia.execute();

            return sentencia.getInt(4);

        } catch (Exception ex) {
            throw new NegocioExcepcion("Error al ejecutar liquidación masiva en Oracle: " + ex.getMessage());
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<LiquidacionMensual> consultarLiquidaciones(Integer mes, Integer anio) {
        if (mes != null && anio != null) {
            return liquidacionMensualRepositorio.findByMesAndAnioOrderByTotalBrutoDesc(mes, anio);
        }
        return liquidacionMensualRepositorio.findAll();
    }
}
