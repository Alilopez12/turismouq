import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TurismoService } from '../../servicios/turismo.service';
import { TransaccionPeticion, TransaccionRespuesta, CboAnalisisItem, SeguridadInfo } from '../../modelos/modelos';

@Component({
  selector: 'app-entrega3',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './entrega3.component.html',
  styleUrl: './entrega3.component.css'
})
export class EntregaTresComponent implements OnInit {

  // Pestaña activa
  pestanaActiva: 'savepoint' | 'concurrencia' | 'cbo' | 'seguridad' = 'savepoint';

  // 1. Pilar Transacciones & SAVEPOINT
  peticionSavepoint: TransaccionPeticion = {
    idHabitacion: 1,
    idCliente: 1,
    fechaCheckIn: '2026-10-01',
    fechaCheckOut: '2026-10-05',
    numeroHuespedes: 2,
    metodoPago: 'TARJETA',
    simularFallo: false
  };
  resultadoSavepoint: TransaccionRespuesta | null = null;
  ejecutandoSavepoint = false;
  errorSavepoint = '';

  // 2. Pilar Concurrencia (Simulación y Guía)
  pasoConcurrencia: number = 1;

  // 3. Pilar Optimizador CBO & Índices
  planesCbo: CboAnalisisItem[] = [];
  cargandoCbo = false;
  cboActivoId: string = 'Q1';

  // 4. Pilar Seguridad & Roles
  seguridadInfo: SeguridadInfo | null = null;
  cargandoSeguridad = false;

  constructor(
    private turismoService: TurismoService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarCbo();
    this.cargarSeguridad();
  }

  seleccionarPestana(p: 'savepoint' | 'concurrencia' | 'cbo' | 'seguridad'): void {
    this.pestanaActiva = p;
  }

  // Ejecución de la transacción con SAVEPOINT
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
        this.errorSavepoint = err?.error?.mensaje || 'Error al ejecutar la transacción en Oracle XE.';
        this.ejecutandoSavepoint = false;
        this.cdr.detectChanges();
      }
    });
  }

  alternarFallo(): void {
    this.peticionSavepoint.simularFallo = !this.peticionSavepoint.simularFallo;
  }

  cargarCbo(): void {
    this.cargandoCbo = true;
    this.turismoService.obtenerPlanesCbo().subscribe({
      next: (res) => {
        this.planesCbo = res || [];
        this.cargandoCbo = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        console.error('Error al obtener planes CBO', err);
        this.cargandoCbo = false;
        this.cdr.detectChanges();
      }
    });
  }

  cargarSeguridad(): void {
    this.cargandoSeguridad = true;
    this.turismoService.obtenerSeguridadRoles().subscribe({
      next: (res) => {
        this.seguridadInfo = res;
        this.cargandoSeguridad = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        console.error('Error al obtener seguridad y roles', err);
        this.cargandoSeguridad = false;
        this.cdr.detectChanges();
      }
    });
  }

  seleccionarPlanCbo(id: string): void {
    this.cboActivoId = id;
  }

  obtenerPlanActivo(): CboAnalisisItem | undefined {
    return this.planesCbo.find(p => p.id === this.cboActivoId);
  }
}
