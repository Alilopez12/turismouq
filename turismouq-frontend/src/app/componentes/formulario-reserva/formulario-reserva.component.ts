import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { TurismoService } from '../../servicios/turismo.service';
import { Habitacion, ReservaItem, ReservaPeticion, ReservaRespuesta, CotizacionRespuesta } from '../../modelos/modelos';

@Component({
  selector: 'app-formulario-reserva',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './formulario-reserva.component.html',
  styleUrl: './formulario-reserva.component.css'
})
export class FormularioReservaComponent implements OnInit {

  // Campos de la reserva
  idHabitacion: number = 1;
  fechaCheckIn: string = '2026-12-01';
  fechaCheckOut: string = '2026-12-05';
  numeroHuespedes: number = 2;

  // Cotización en vivo con desglose por temporadas
  cotizacion: CotizacionRespuesta | null = null;
  cargandoCotizacion: boolean = false;

  // Datos del cliente
  documentoCliente: string = 'CC-1094857201';
  nombresCliente: string = 'Carlos Andrés';
  apellidosCliente: string = 'Gómez Quintero';
  telefonoCliente: string = '3128495021';
  correoCliente: string = 'carlos.gomez@gmail.com';

  // Estados de proceso
  procesando = false;
  mensajeExito = '';
  mensajeError = '';
  reservaCreada: ReservaRespuesta | null = null;
  reservasRecientes: ReservaItem[] = [];

  // Banco de pruebas docente PL/SQL
  casoPruebaActivo: string = '';
  detallePrueba: string = '';

  constructor(
    private route: ActivatedRoute,
    private turismoService: TurismoService,
    private cdr: ChangeDetectorRef
  ) {}

  bloquearNegativos(event: KeyboardEvent): void {
    if (['-', '+', 'e', 'E', '.'].includes(event.key)) {
      event.preventDefault();
    }
  }

  validarNumerosPositivos(): void {
    if (this.idHabitacion !== null && this.idHabitacion < 1) {
      this.idHabitacion = 1;
    }
    if (this.numeroHuespedes !== null && this.numeroHuespedes < 1 && this.casoPruebaActivo !== 'ORA-20003') {
      this.numeroHuespedes = 1;
    }
    this.calcularCotizacionLive();
  }

  ngOnInit(): void {
    this.route.queryParams.subscribe(params => {
      if (params['idHabitacion']) this.idHabitacion = Number(params['idHabitacion']);
      if (params['checkIn']) this.fechaCheckIn = params['checkIn'];
      if (params['checkOut']) this.fechaCheckOut = params['checkOut'];

      this.calcularCotizacionLive();
      this.cdr.detectChanges();
    });

    this.cargarReservasRecientes();
  }

  calcularCotizacionLive(): void {
    if (!this.idHabitacion || !this.fechaCheckIn || !this.fechaCheckOut) {
      this.cotizacion = null;
      return;
    }
    if (this.fechaCheckOut <= this.fechaCheckIn) {
      this.cotizacion = null;
      return;
    }

    this.cargandoCotizacion = true;
    this.turismoService.cotizarEstadia({
      idHabitacion: this.idHabitacion,
      fechaCheckIn: this.fechaCheckIn,
      fechaCheckOut: this.fechaCheckOut
    }).subscribe({
      next: (res) => {
        this.cotizacion = res;
        this.cargandoCotizacion = false;
        this.cdr.detectChanges();
      },
      error: () => {
        this.cotizacion = null;
        this.cargandoCotizacion = false;
        this.cdr.detectChanges();
      }
    });
  }

  cargarReservasRecientes(): void {
    this.turismoService.obtenerReservasRecientes().subscribe({
      next: (res) => {
        this.reservasRecientes = (res || []).slice(0, 5);
        this.cdr.detectChanges();
      },
      error: (e) => {
        console.error('Error al cargar reservas recientes', e);
        this.cdr.detectChanges();
      }
    });
  }

  // ========================================================================
  // BANCO DE PRUEBAS DOCENTE (1-CLIC TEST BENCH PARA SUSTENTACIÓN ORAL)
  // ========================================================================
  cargarCasoValido(): void {
    this.casoPruebaActivo = 'COMMIT';
    this.idHabitacion = 1;
    this.numeroHuespedes = 2;
    this.fechaCheckIn = '2027-04-10';
    this.fechaCheckOut = '2027-04-15';
    this.documentoCliente = 'CC-1094857201';
    this.nombresCliente = 'Carlos Andrés';
    this.apellidosCliente = 'Gómez Quintero';
    this.telefonoCliente = '3128495021';
    this.correoCliente = 'carlos.gomez@gmail.com';
    this.detallePrueba = 'Parámetros válidos: Check-in 2027-04-10 a Check-out 2027-04-15 (5 noches), 2 huéspedes. Reserva y disponibilidad comprobadas exitosamente.';
    this.mensajeError = '';
    this.mensajeExito = '';
    this.reservaCreada = null;

    this.calcularCotizacionLive();
    this.cdr.detectChanges();
  }

  cargarCasoErrorFechas(): void {
    this.casoPruebaActivo = 'ORA-20001';
    this.idHabitacion = 1;
    this.numeroHuespedes = 2;
    this.fechaCheckIn = '2027-05-15';
    this.fechaCheckOut = '2027-05-10'; // Invertidas
    this.documentoCliente = 'CC-1094857201';
    this.nombresCliente = 'Carlos Andrés';
    this.apellidosCliente = 'Gómez Quintero';
    this.telefonoCliente = '3128495021';
    this.correoCliente = 'carlos.gomez@gmail.com';
    this.detallePrueba = 'Incoherencia cronológica: Check-out (2027-05-10) anterior a Check-in (2027-05-15). El sistema detecta y previene fechas invertidas.';
    this.mensajeError = '';
    this.mensajeExito = '';
    this.reservaCreada = null;
    this.cotizacion = null;

    this.cdr.detectChanges();
  }

  cargarCasoErrorCapacidad(): void {
    this.casoPruebaActivo = 'AFORO';
    this.idHabitacion = 1;
    this.numeroHuespedes = 99; // Capacidad superada
    this.fechaCheckIn = '2027-06-01';
    this.fechaCheckOut = '2027-06-05';
    this.documentoCliente = 'CC-1094857201';
    this.nombresCliente = 'Carlos Andrés';
    this.apellidosCliente = 'Gómez Quintero';
    this.telefonoCliente = '3128495021';
    this.correoCliente = 'carlos.gomez@gmail.com';
    this.detallePrueba = 'Límite de aforo superado: Se solicitan 99 huéspedes para una habitación con capacidad de 3 personas.';
    this.mensajeError = '';
    this.mensajeExito = '';
    this.reservaCreada = null;

    this.calcularCotizacionLive();
    this.cdr.detectChanges();
  }

  cargarCasoErrorSolapamiento(): void {
    this.casoPruebaActivo = 'DISPONIBILIDAD';
    this.idHabitacion = 1;
    this.fechaCheckIn = '2026-12-01';
    this.fechaCheckOut = '2026-12-05';
    this.numeroHuespedes = 2;
    this.documentoCliente = 'CC-52849102';
    this.nombresCliente = 'Simulación';
    this.apellidosCliente = 'Solapamiento';
    this.telefonoCliente = '3100000000';
    this.correoCliente = 'solapamiento@test.com';
    this.detallePrueba = 'Habitación ocupada: La habitación seleccionada ya cuenta con una reserva activa en las fechas solicitadas.';
    this.mensajeError = '';
    this.mensajeExito = '';
    this.reservaCreada = null;

    this.calcularCotizacionLive();
    this.cdr.detectChanges();
  }

  confirmarReserva(): void {
    this.procesando = true;
    this.mensajeExito = '';
    this.mensajeError = '';
    this.reservaCreada = null;

    const peticion: ReservaPeticion = {
      idHabitacion: this.idHabitacion,
      fechaCheckIn: this.fechaCheckIn,
      fechaCheckOut: this.fechaCheckOut,
      numeroHuespedes: this.numeroHuespedes,
      documentoCliente: this.documentoCliente,
      nombresCliente: this.nombresCliente,
      apellidosCliente: this.apellidosCliente,
      telefonoCliente: this.telefonoCliente,
      correoCliente: this.correoCliente
    };

    this.turismoService.crearReserva(peticion).subscribe({
      next: (res) => {
        this.procesando = false;
        this.reservaCreada = res;
        this.mensajeExito = `¡Reserva #${res.idReserva} confirmada exitosamente! Total: $${res.total.toLocaleString()} COP`;

        const nuevaReserva: ReservaItem = {
          idReserva: res.idReserva,
          fechaCreacion: new Date().toISOString(),
          fechaCheckIn: res.fechaCheckIn,
          fechaCheckOut: res.fechaCheckOut,
          total: res.total,
          estado: res.estado || 'CONFIRMADA',
          cliente: {
            idCliente: peticion.idCliente || 0,
            nombres: peticion.nombresCliente || '',
            apellidos: peticion.apellidosCliente || '',
            documento: peticion.documentoCliente || ''
          }
        };

        this.reservasRecientes = [nuevaReserva, ...this.reservasRecientes.filter(r => r.idReserva !== res.idReserva)].slice(0, 5);
        this.cdr.detectChanges();
        this.cargarReservasRecientes();
      },
      error: (err) => {
        this.procesando = false;
        this.mensajeError = err.error?.mensaje || 'Error al procesar la reserva';
        this.cdr.detectChanges();
      }
    });
  }
}
