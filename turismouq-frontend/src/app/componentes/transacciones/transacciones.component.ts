import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TurismoService } from '../../servicios/turismo.service';
import { TransaccionPeticion, TransaccionRespuesta } from '../../modelos/modelos';

@Component({
  selector: 'app-transacciones',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './transacciones.component.html',
  styleUrl: './transacciones.component.css'
})
export class TransaccionesComponent implements OnInit {

  peticionSavepoint: TransaccionPeticion = {
    idHabitacion: 1,
    idCliente: 1,
    fechaCheckIn: '2028-06-01',
    fechaCheckOut: '2028-06-05',
    numeroHuespedes: 2,
    metodoPago: 'TARJETA_CREDITO',
    simularFallo: false
  };

  infoHabitacion: {
    nombreHabitacion: string;
    alojamiento: string;
    capacidadMaxima: number;
  } | null = null;

  rangoEjecutado: {
    idHabitacion: number;
    fechaCheckIn: string;
    fechaCheckOut: string;
  } | null = null;

  resultadoSavepoint: TransaccionRespuesta | null = null;
  ejecutandoSavepoint = false;
  buscandoDisponibilidad = false;
  fechasAutoAvanzadas = false;
  errorSavepoint = '';

  metodosPago = [
    { valor: 'TARJETA_CREDITO', nombre: 'Tarjeta de Crédito (Visa / Mastercard)' },
    { valor: 'TARJETA_DEBITO', nombre: 'Tarjeta de Débito' },
    { valor: 'PSE', nombre: 'PSE - Transferencia Débito en Línea' },
    { valor: 'TRANSFERENCIA', nombre: 'Transferencia Bancolombia / Davivienda' },
    { valor: 'EFECTIVO', nombre: 'Pago en Efectivo en Recepción' }
  ];

  constructor(
    private turismoService: TurismoService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.buscarFechasDisponibles(false);
  }

  buscarFechasDisponibles(porAutoAvance: boolean = false): void {
    const idHab = this.peticionSavepoint.idHabitacion;
    if (!idHab || idHab < 1) return;

    this.buscandoDisponibilidad = true;
    this.turismoService.obtenerSiguienteDisponibilidadSavepoint(idHab).subscribe({
      next: (disp) => {
        this.peticionSavepoint.fechaCheckIn = disp.fechaCheckIn;
        this.peticionSavepoint.fechaCheckOut = disp.fechaCheckOut;
        this.infoHabitacion = {
          nombreHabitacion: disp.nombreHabitacion,
          alojamiento: disp.alojamiento,
          capacidadMaxima: disp.capacidadMaxima
        };
        if (this.peticionSavepoint.numeroHuespedes > disp.capacidadMaxima) {
          this.peticionSavepoint.numeroHuespedes = Math.min(2, disp.capacidadMaxima);
        }
        this.fechasAutoAvanzadas = porAutoAvance;
        if (!porAutoAvance) {
          this.errorSavepoint = '';
        }
        this.buscandoDisponibilidad = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.buscandoDisponibilidad = false;
        this.infoHabitacion = null;
        if (!porAutoAvance) {
          this.errorSavepoint = err?.error?.mensaje || `No se encontró disponibilidad para la habitación #${idHab}.`;
        }
        this.cdr.detectChanges();
      }
    });
  }

  alternarFallo(): void {
    this.peticionSavepoint.simularFallo = !this.peticionSavepoint.simularFallo;
  }

  ejecutarTransaccion(): void {
    this.ejecutandoSavepoint = true;
    this.errorSavepoint = '';
    this.resultadoSavepoint = null;
    this.fechasAutoAvanzadas = false;

    const rangoActual = {
      idHabitacion: this.peticionSavepoint.idHabitacion,
      fechaCheckIn: this.peticionSavepoint.fechaCheckIn,
      fechaCheckOut: this.peticionSavepoint.fechaCheckOut
    };

    this.turismoService.ejecutarTransaccionSavepoint(this.peticionSavepoint).subscribe({
      next: (res) => {
        this.resultadoSavepoint = res;
        this.rangoEjecutado = rangoActual;
        this.ejecutandoSavepoint = false;
        // Avanzar automáticamente al siguiente rango libre para permitir pruebas consecutivas sin ORA-20002
        this.buscarFechasDisponibles(true);
        this.cdr.detectChanges();
      },
      error: (err) => {
        console.error('Error al ejecutar transacción con SAVEPOINT', err);
        this.errorSavepoint = err?.error?.mensaje || 'Error al ejecutar la transacción en Oracle Database 21c.';
        this.ejecutandoSavepoint = false;
        this.cdr.detectChanges();
      }
    });
  }
}
