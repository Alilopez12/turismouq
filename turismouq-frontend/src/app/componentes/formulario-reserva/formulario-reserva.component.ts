import { Component, OnInit, ChangeDetectorRef } from '@angular/core';

import { CommonModule } from '@angular/common';

import { FormsModule } from '@angular/forms';

import { ActivatedRoute } from '@angular/router';

import { TurismoService } from '../../servicios/turismo.service';

import { Habitacion, ReservaItem, ReservaPeticion, ReservaRespuesta } from '../../modelos/modelos';



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
  }

  ngOnInit(): void {

    this.route.queryParams.subscribe(params => {

      if (params['idHabitacion']) this.idHabitacion = Number(params['idHabitacion']);

      if (params['checkIn']) this.fechaCheckIn = params['checkIn'];

      if (params['checkOut']) this.fechaCheckOut = params['checkOut'];

      this.cdr.detectChanges();

    });



    this.cargarReservasRecientes();

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

    this.detallePrueba = 'Parámetros válidos: Check-in 2027-04-10 a Check-out 2027-04-15 (5 noches), 2 huéspedes. Se ejecutará COMMIT con inserción atómica en RESERVA y RESERVA_HABITACION.';

    this.mensajeError = '';

    this.mensajeExito = '';

    this.reservaCreada = null;

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

    this.detallePrueba = 'Violación cronológica: Check-out (2027-05-10) anterior a Check-in (2027-05-15). La regla PL/SQL disparará RAISE_APPLICATION_ERROR(-20001).';

    this.mensajeError = '';

    this.mensajeExito = '';

    this.reservaCreada = null;

    this.cdr.detectChanges();

  }



  cargarCasoErrorCapacidad(): void {

    this.casoPruebaActivo = 'ORA-20003';

    this.idHabitacion = 1;

    this.numeroHuespedes = 99; // Capacidad superada

    this.fechaCheckIn = '2027-06-01';

    this.fechaCheckOut = '2027-06-05';

    this.documentoCliente = 'CC-1094857201';

    this.nombresCliente = 'Carlos Andrés';

    this.apellidosCliente = 'Gómez Quintero';

    this.telefonoCliente = '3128495021';

    this.correoCliente = 'carlos.gomez@gmail.com';

    this.detallePrueba = 'Capacidad superada: 99 personas para una habitación con cupo de 3 personas. Disparará RAISE_APPLICATION_ERROR(-20003).';

    this.mensajeError = '';

    this.mensajeExito = '';

    this.reservaCreada = null;

    this.cdr.detectChanges();

  }



  cargarCasoErrorSolapamiento(): void {

    this.casoPruebaActivo = 'ORA-20002';

    this.idHabitacion = 1;

    this.fechaCheckIn = '2026-12-01';

    this.fechaCheckOut = '2026-12-05';

    this.numeroHuespedes = 2;

    this.documentoCliente = 'CC-52849102';

    this.nombresCliente = 'Simulación';

    this.apellidosCliente = 'Solapamiento';

    this.telefonoCliente = '3100000000';

    this.correoCliente = 'solapamiento@test.com';

    this.detallePrueba = 'Conflicto de ocupación: Habitación #1 ocupada del 01/12/2026 al 05/12/2026. El disparador anti-solapamiento disparará RAISE_APPLICATION_ERROR(-20002).';

    this.mensajeError = '';

    this.mensajeExito = '';

    this.reservaCreada = null;

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

        this.mensajeExito = `¡Reserva #${res.idReserva} confirmada exitosamente en el motor Oracle XE! Total: $${res.total.toLocaleString()}`;

        

        // Actualizar feed en tiempo real con las últimas 5 reservas

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

        

        // Sincronizar con Oracle XE

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

