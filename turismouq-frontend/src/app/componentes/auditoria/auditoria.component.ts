import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TurismoService } from '../../servicios/turismo.service';
import { AuditoriaTarifaItem } from '../../modelos/modelos';

@Component({
  selector: 'app-auditoria',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './auditoria.component.html',
  styleUrl: './auditoria.component.css'
})
export class AuditoriaComponent implements OnInit {

  registros: AuditoriaTarifaItem[] = [];
  cargando = true;

  // Formulario interactivo para demostración del Trigger TRG_AUDITORIA_TARIFA_STMT
  idHabitacionModificar: number = 1;
  idTemporadaModificar: number = 1; // 1: Temporada Baja, 2: Temporada Alta
  nuevoPrecioModificar: number = 195000;
  guardandoTarifa: boolean = false;
  mensajeTarifa: string = '';
  tipoMensajeTarifa: 'exito' | 'error' = 'exito';
  ultimoCambio: any = null;

  constructor(
    private turismoService: TurismoService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarAuditorias();
  }

  cargarAuditorias(): void {
    this.cargando = true;
    this.turismoService.obtenerAuditoriaTarifas().subscribe({
      next: (datos) => {
        this.registros = datos;
        this.cargando = false;
        this.cdr.detectChanges();
      },
      error: (e) => {
        console.error('Error al cargar auditoría', e);
        this.cargando = false;
        this.cdr.detectChanges();
      }
    });
  }

  ajustarPrecio(delta: number): void {
    const nuevo = (Number(this.nuevoPrecioModificar) || 150000) + delta;
    this.nuevoPrecioModificar = Math.max(10000, nuevo);
  }

  fijarPrecio(monto: number): void {
    this.nuevoPrecioModificar = monto;
  }

  modificarTarifa(): void {
    if (!this.idHabitacionModificar || this.idHabitacionModificar < 1) {
      this.tipoMensajeTarifa = 'error';
      this.mensajeTarifa = 'Por favor ingresa un ID de habitación válido (ej: 1 a 400).';
      return;
    }
    if (!this.nuevoPrecioModificar || this.nuevoPrecioModificar <= 0) {
      this.tipoMensajeTarifa = 'error';
      this.mensajeTarifa = 'El precio debe ser un número mayor a 0.';
      return;
    }

    this.guardandoTarifa = true;
    this.mensajeTarifa = '';
    this.ultimoCambio = null;

    this.turismoService.actualizarTarifa(
      Number(this.idHabitacionModificar),
      Number(this.idTemporadaModificar),
      Number(this.nuevoPrecioModificar)
    ).subscribe({
      next: (res) => {
        this.guardandoTarifa = false;
        this.tipoMensajeTarifa = 'exito';
        this.ultimoCambio = res;
        this.mensajeTarifa = res.mensaje || 'Tarifa actualizada en Oracle. El trigger TRG_AUDITORIA_TARIFA_STMT registró la traza exitosamente.';
        // Recargar inmediatamente la bitácora para que el nuevo log se observe al inicio
        this.cargarAuditorias();
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.guardandoTarifa = false;
        this.tipoMensajeTarifa = 'error';
        const msgError = err?.error?.error || err?.message || 'Error al actualizar tarifa';
        this.mensajeTarifa = `Error al actualizar tarifa: ${msgError}`;
        this.cdr.detectChanges();
      }
    });
  }
}
