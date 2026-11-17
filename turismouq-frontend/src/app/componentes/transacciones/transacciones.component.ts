import { Component, ChangeDetectorRef } from '@angular/core';
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
export class TransaccionesComponent {

  peticionSavepoint: TransaccionPeticion = {
    idHabitacion: 1,
    idCliente: 1,
    fechaCheckIn: '2026-12-01',
    fechaCheckOut: '2026-12-05',
    numeroHuespedes: 2,
    metodoPago: 'TARJETA_CREDITO',
    simularFallo: false
  };

  resultadoSavepoint: TransaccionRespuesta | null = null;
  ejecutandoSavepoint = false;
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

  alternarFallo(): void {
    this.peticionSavepoint.simularFallo = !this.peticionSavepoint.simularFallo;
  }

  ejecutarTransaccion(): void {
    this.ejecutandoSavepoint = true;
    this.errorSavepoint = '';
    this.resultadoSavepoint = null;

    this.turismoService.ejecutarTransaccionSavepoint(this.peticionSavepoint).subscribe({
      next: (res) => {
        this.resultadoSavepoint = res;
        this.ejecutandoSavepoint = false;
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
