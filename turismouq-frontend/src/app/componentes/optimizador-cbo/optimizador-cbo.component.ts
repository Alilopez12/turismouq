import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TurismoService } from '../../servicios/turismo.service';
import { CboAnalisisItem } from '../../modelos/modelos';

@Component({
  selector: 'app-optimizador-cbo',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './optimizador-cbo.component.html',
  styleUrl: './optimizador-cbo.component.css'
})
export class OptimizadorCboComponent implements OnInit {

  planesCbo: CboAnalisisItem[] = [];
  cargandoCbo = false;
  cboActivoId: string = 'Q1';

  constructor(
    private turismoService: TurismoService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarPlanesCbo();
  }

  cargarPlanesCbo(): void {
    this.cargandoCbo = true;
    this.turismoService.obtenerPlanesCbo().subscribe({
      next: (res) => {
        this.planesCbo = res || [];
        this.cargandoCbo = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        console.error('Error al cargar planes CBO', err);
        this.cargandoCbo = false;
        this.cdr.detectChanges();
      }
    });
  }

  seleccionarPlan(id: string): void {
    this.cboActivoId = id;
  }

  obtenerPlanActivo(): CboAnalisisItem | undefined {
    return this.planesCbo.find(p => p.id === this.cboActivoId);
  }
}
