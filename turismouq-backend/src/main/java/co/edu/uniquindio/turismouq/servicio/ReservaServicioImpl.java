package co.edu.uniquindio.turismouq.servicio;

import co.edu.uniquindio.turismouq.dto.CotizacionPeticionDTO;
import co.edu.uniquindio.turismouq.dto.CotizacionRespuestaDTO;
import co.edu.uniquindio.turismouq.dto.ReservaPeticionDTO;
import co.edu.uniquindio.turismouq.dto.ReservaRespuestaDTO;
import co.edu.uniquindio.turismouq.entidad.Cliente;
import co.edu.uniquindio.turismouq.entidad.Habitacion;
import co.edu.uniquindio.turismouq.entidad.Reserva;
import co.edu.uniquindio.turismouq.excepcion.NegocioExcepcion;
import co.edu.uniquindio.turismouq.repositorio.ClienteRepositorio;
import co.edu.uniquindio.turismouq.repositorio.HabitacionRepositorio;
import co.edu.uniquindio.turismouq.repositorio.ReservaRepositorio;
import org.springframework.stereotype.Service;

import javax.sql.DataSource;
import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Date;
import java.sql.Types;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
public class ReservaServicioImpl implements ReservaServicio {

    private final DataSource dataSource;
    private final ReservaRepositorio reservaRepositorio;
    private final HabitacionRepositorio habitacionRepositorio;
    private final ClienteRepositorio clienteRepositorio;

    public ReservaServicioImpl(
            DataSource dataSource,
            ReservaRepositorio reservaRepositorio,
            HabitacionRepositorio habitacionRepositorio,
            ClienteRepositorio clienteRepositorio
    ) {
        this.dataSource = dataSource;
        this.reservaRepositorio = reservaRepositorio;
        this.habitacionRepositorio = habitacionRepositorio;
        this.clienteRepositorio = clienteRepositorio;
    }

    @Override
    public CotizacionRespuestaDTO cotizarEstadia(CotizacionPeticionDTO peticion) {
        if (peticion.getFechaCheckOut() == null || peticion.getFechaCheckIn() == null) {
            throw new NegocioExcepcion("Las fechas de check-in y check-out son obligatorias.");
        }
        if (!peticion.getFechaCheckOut().isAfter(peticion.getFechaCheckIn())) {
            throw new NegocioExcepcion(20001, "La fecha de check-out debe ser posterior al check-in.");
        }

        // Llamada a la función PL/SQL PKG_TURISMO_UQ.fn_valor_estadia
        try (Connection conexion = dataSource.getConnection();
             CallableStatement sentencia = conexion.prepareCall("{? = call PKG_TURISMO_UQ.fn_valor_estadia(?, ?, ?)}")) {

            sentencia.registerOutParameter(1, Types.NUMERIC);
            sentencia.setLong(2, peticion.getIdHabitacion());
            sentencia.setDate(3, Date.valueOf(peticion.getFechaCheckIn()));
            sentencia.setDate(4, Date.valueOf(peticion.getFechaCheckOut()));

            sentencia.execute();
            BigDecimal totalCalculado = sentencia.getBigDecimal(1);

            long noches = ChronoUnit.DAYS.between(peticion.getFechaCheckIn(), peticion.getFechaCheckOut());

            CotizacionRespuestaDTO respuesta = new CotizacionRespuestaDTO();
            respuesta.setIdHabitacion(peticion.getIdHabitacion());
            respuesta.setFechaCheckIn(peticion.getFechaCheckIn());
            respuesta.setFechaCheckOut(peticion.getFechaCheckOut());
            respuesta.setTotalNoches(noches);
            respuesta.setTotalPagar(totalCalculado);
            respuesta.setDescripcionTemporadas("Cálculo ponderado por noches según tarifas de Temporada Baja y Temporada Alta");

            return respuesta;

        } catch (Exception ex) {
            throw new NegocioExcepcion("Error al calcular cotización en base de datos: " + ex.getMessage());
        }
    }

    @Override
    public ReservaRespuestaDTO crearReserva(ReservaPeticionDTO peticion) {
        // 1. Obtener o registrar cliente con soporte nativo para columna IDENTITY de Oracle 21c
        Long idClienteFinal = peticion.getIdCliente();
        Cliente cliente;

        if (peticion.getIdCliente() == null) {
            if (peticion.getDocumentoCliente() == null || peticion.getDocumentoCliente().isBlank()
                    || peticion.getNombresCliente() == null || peticion.getNombresCliente().isBlank()) {
                cliente = clienteRepositorio.findById(1L)
                        .orElseThrow(() -> new NegocioExcepcion("No se encontró cliente por defecto"));
            } else {
                String docLimpio = peticion.getDocumentoCliente().trim();
                cliente = clienteRepositorio.findByDocumento(docLimpio)
                        .orElseGet(() -> {
                            Cliente nuevo = new Cliente();
                            nuevo.setDocumento(docLimpio);
                            nuevo.setNombres(peticion.getNombresCliente().trim());
                            nuevo.setApellidos(peticion.getApellidosCliente() != null && !peticion.getApellidosCliente().isBlank()
                                    ? peticion.getApellidosCliente().trim() : "UQ");
                            nuevo.setTelefono(peticion.getTelefonoCliente() != null && !peticion.getTelefonoCliente().isBlank()
                                    ? peticion.getTelefonoCliente().trim() : "3001234567");
                            String sufijoUnico = String.valueOf(System.currentTimeMillis() % 1000000);
                            String correoBase = peticion.getCorreoCliente() != null && !peticion.getCorreoCliente().isBlank()
                                    ? peticion.getCorreoCliente().trim() : ("cliente." + sufijoUnico + "@turismouq.com");
                            if (clienteRepositorio.findByCorreo(correoBase).isPresent()) {
                                correoBase = "cliente." + sufijoUnico + "@turismouq.com";
                            }
                            nuevo.setCorreo(correoBase);
                            return clienteRepositorio.saveAndFlush(nuevo);
                        });
            }
            idClienteFinal = cliente.getIdCliente();
        } else {
            final Long idBuscar = peticion.getIdCliente();
            cliente = clienteRepositorio.findById(idBuscar)
                    .orElseThrow(() -> new NegocioExcepcion("Cliente no encontrado con ID: " + idBuscar));
            idClienteFinal = idBuscar;
        }

        Habitacion habitacion = habitacionRepositorio.findById(peticion.getIdHabitacion())
                .orElseThrow(() -> new NegocioExcepcion("Habitación no encontrada con ID: " + peticion.getIdHabitacion()));

        int huespedes = (peticion.getNumeroHuespedes() != null && peticion.getNumeroHuespedes() > 0)
                ? peticion.getNumeroHuespedes() : 2;

        // 2. Invocar procedimiento almacenado PL/SQL PKG_TURISMO_UQ.sp_crear_reserva
        try (Connection conexion = dataSource.getConnection();
             CallableStatement sentencia = conexion.prepareCall("{call PKG_TURISMO_UQ.sp_crear_reserva(?, ?, ?, ?, ?, ?, ?)}")) {

            sentencia.setLong(1, idClienteFinal);
            sentencia.setLong(2, peticion.getIdHabitacion());
            sentencia.setDate(3, Date.valueOf(peticion.getFechaCheckIn()));
            sentencia.setDate(4, Date.valueOf(peticion.getFechaCheckOut()));
            sentencia.setInt(5, huespedes);
            sentencia.registerOutParameter(6, Types.NUMERIC); // p_id_reserva
            sentencia.registerOutParameter(7, Types.NUMERIC); // p_total

            sentencia.execute();

            long idReservaGenerada = sentencia.getLong(6);
            BigDecimal totalReserva = sentencia.getBigDecimal(7);

            ReservaRespuestaDTO respuesta = new ReservaRespuestaDTO();
            respuesta.setIdReserva(idReservaGenerada);
            respuesta.setIdHabitacion(habitacion.getIdHabitacion());
            respuesta.setNombreHabitacion(habitacion.getNumeroNombre());
            respuesta.setNombreAlojamiento(habitacion.getAlojamiento().getNombre());
            respuesta.setNombreCliente(cliente.getNombres() + " " + cliente.getApellidos());
            respuesta.setFechaCheckIn(peticion.getFechaCheckIn());
            respuesta.setFechaCheckOut(peticion.getFechaCheckOut());
            respuesta.setTotal(totalReserva);
            respuesta.setEstado("CONFIRMADA");
            respuesta.setMensaje("Reserva confirmada exitosamente mediante el procedimiento almacenado PKG_TURISMO_UQ.sp_crear_reserva");

            return respuesta;

        } catch (Exception ex) {
            throw new NegocioExcepcion(ex.getMessage());
        }
    }

    @Override
    public List<Reserva> listarReservasRecientes() {
        return reservaRepositorio.findTop30ByOrderByIdReservaDesc();
    }
}
