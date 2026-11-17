package co.edu.uniquindio.turismouq.servicio;

import co.edu.uniquindio.turismouq.dto.RecepcionCheckinDTO;
import co.edu.uniquindio.turismouq.dto.RecepcionDisponibilidadDTO;
import co.edu.uniquindio.turismouq.dto.RecepcionVoucherDTO;
import co.edu.uniquindio.turismouq.excepcion.NegocioExcepcion;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.sql.Date;
import java.util.List;

@Service
public class RecepcionServicioImpl implements RecepcionServicio {

    private final JdbcTemplate jdbcTemplate;

    public RecepcionServicioImpl(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    @Transactional(readOnly = true)
    public List<RecepcionCheckinDTO> obtenerCheckinHoy() {
        String sql = """
            SELECT id_reserva, documento_huesped, nombre_huesped, telefono_contacto,
                   alojamiento, municipio, habitacion, fecha_check_in, fecha_check_out,
                   total_noches, estado
            FROM V_RECEPCION_CHECKIN_HOY
            ORDER BY id_reserva DESC
            FETCH FIRST 50 ROWS ONLY
        """;

        return jdbcTemplate.query(sql, (rs, rowNum) -> {
            RecepcionCheckinDTO dto = new RecepcionCheckinDTO();
            dto.setIdReserva(rs.getLong("id_reserva"));
            dto.setDocumentoHuesped(rs.getString("documento_huesped"));
            dto.setNombreHuesped(rs.getString("nombre_huesped"));
            dto.setTelefonoContacto(rs.getString("telefono_contacto"));
            dto.setAlojamiento(rs.getString("alojamiento"));
            dto.setMunicipio(rs.getString("municipio"));
            dto.setHabitacion(rs.getString("habitacion"));
            Date in = rs.getDate("fecha_check_in");
            dto.setFechaCheckIn(in != null ? in.toLocalDate() : null);
            Date out = rs.getDate("fecha_check_out");
            dto.setFechaCheckOut(out != null ? out.toLocalDate() : null);
            dto.setTotalNoches(rs.getInt("total_noches"));
            dto.setEstado(rs.getString("estado"));
            return dto;
        });
    }

    @Override
    @Transactional(readOnly = true)
    public List<RecepcionDisponibilidadDTO> obtenerDisponibilidad() {
        String sql = """
            SELECT id_habitacion, habitacion, tipo_cama, aforo_maximo,
                   id_alojamiento, alojamiento, municipio, telefono_alojamiento
            FROM V_RECEPCION_DISPONIBILIDAD
            ORDER BY id_alojamiento, id_habitacion
            FETCH FIRST 60 ROWS ONLY
        """;

        return jdbcTemplate.query(sql, (rs, rowNum) -> {
            RecepcionDisponibilidadDTO dto = new RecepcionDisponibilidadDTO();
            dto.setIdHabitacion(rs.getLong("id_habitacion"));
            dto.setHabitacion(rs.getString("habitacion"));
            dto.setTipoCama(rs.getString("tipo_cama"));
            dto.setAforoMaximo(rs.getInt("aforo_maximo"));
            dto.setIdAlojamiento(rs.getLong("id_alojamiento"));
            dto.setAlojamiento(rs.getString("alojamiento"));
            dto.setMunicipio(rs.getString("municipio"));
            dto.setTelefonoAlojamiento(rs.getString("telefono_alojamiento"));
            return dto;
        });
    }

    @Override
    @Transactional(readOnly = true)
    public RecepcionVoucherDTO obtenerVoucher(Long idReserva) {
        String sql;
        Object[] params;

        if (idReserva != null && idReserva > 0) {
            sql = """
                SELECT id_reserva, fecha_creacion, documento_cliente, cliente_titular,
                       alojamiento, direccion, municipio, habitacion, fecha_check_in,
                       fecha_check_out, total_facturado, estado_reserva
                FROM V_RECEPCION_VOUCHER_RESERVA
                WHERE id_reserva = ?
            """;
            params = new Object[]{idReserva};
        } else {
            sql = """
                SELECT id_reserva, fecha_creacion, documento_cliente, cliente_titular,
                       alojamiento, direccion, municipio, habitacion, fecha_check_in,
                       fecha_check_out, total_facturado, estado_reserva
                FROM V_RECEPCION_VOUCHER_RESERVA
                ORDER BY id_reserva DESC
                FETCH FIRST 1 ROWS ONLY
            """;
            params = new Object[]{};
        }

        List<RecepcionVoucherDTO> lista = jdbcTemplate.query(sql, (rs, rowNum) -> {
            RecepcionVoucherDTO dto = new RecepcionVoucherDTO();
            dto.setIdReserva(rs.getLong("id_reserva"));
            Date creacion = rs.getDate("fecha_creacion");
            dto.setFechaCreacion(creacion != null ? creacion.toLocalDate() : null);
            dto.setDocumentoCliente(rs.getString("documento_cliente"));
            dto.setClienteTitular(rs.getString("cliente_titular"));
            dto.setAlojamiento(rs.getString("alojamiento"));
            dto.setDireccion(rs.getString("direccion"));
            dto.setMunicipio(rs.getString("municipio"));
            dto.setHabitacion(rs.getString("habitacion"));
            Date in = rs.getDate("fecha_check_in");
            dto.setFechaCheckIn(in != null ? in.toLocalDate() : null);
            Date out = rs.getDate("fecha_check_out");
            dto.setFechaCheckOut(out != null ? out.toLocalDate() : null);
            dto.setTotalFacturado(rs.getBigDecimal("total_facturado"));
            dto.setEstadoReserva(rs.getString("estado_reserva"));
            return dto;
        }, params);

        if (lista.isEmpty()) {
            String detalle = (idReserva != null)
                    ? "No se encontró comprobante de voucher para la reserva #" + idReserva + "."
                    : "No se encontraron comprobantes de reserva registrados.";
            throw new NegocioExcepcion(detalle);
        }

        return lista.get(0);
    }
}
