import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TurismoService } from '../../servicios/turismo.service';
import { LiquidacionItem } from '../../modelos/modelos';

@Component({
  selector: 'app-liquidaciones',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './liquidaciones.component.html',
  styleUrl: './liquidaciones.component.css'
})
export class LiquidacionesComponent implements OnInit {

  mesSeleccionado: number = 3;
  anioSeleccionado: number = 2025;
  idAlojamientoFiltro: number | null = null;

  liquidaciones: LiquidacionItem[] = [];
  cargando = true;
  procesandoLiquidacion = false;
  mensajeAlerta = '';
  tipoAlerta: 'exito' | 'error' = 'exito';

  meses = [
    { id: 1, nombre: 'Enero' },
    { id: 2, nombre: 'Febrero' },
    { id: 3, nombre: 'Marzo' },
    { id: 4, nombre: 'Abril' },
    { id: 5, nombre: 'Mayo' },
    { id: 6, nombre: 'Junio' },
    { id: 7, nombre: 'Julio' },
    { id: 8, nombre: 'Agosto' },
    { id: 9, nombre: 'Septiembre' },
    { id: 10, nombre: 'Octubre' },
    { id: 11, nombre: 'Noviembre' },
    { id: 12, nombre: 'Diciembre' }
  ];

  constructor(
    private turismoService: TurismoService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.consultar();
  }

  consultar(): void {
    this.cargando = true;
    this.turismoService.consultarLiquidaciones(this.mesSeleccionado, this.anioSeleccionado).subscribe({
      next: (datos) => {
        this.liquidaciones = datos;
        this.cargando = false;
        this.cdr.detectChanges();
      },
      error: (e) => {
        console.error('Error al consultar liquidaciones', e);
        this.cargando = false;
        this.cdr.detectChanges();
      }
    });
  }

  ejecutarLiquidacionMasiva(): void {
    this.procesandoLiquidacion = true;
    this.mensajeAlerta = '';

    this.turismoService.ejecutarLiquidacion(
      this.mesSeleccionado,
      this.anioSeleccionado,
      this.idAlojamientoFiltro || undefined
    ).subscribe({
      next: (procesados) => {
        this.procesandoLiquidacion = false;
        this.tipoAlerta = 'exito';
        this.mensajeAlerta = `Liquidación masiva completada exitosamente. Se procesaron ${procesados} alojamientos con el cursor explícito.`;
        this.consultar();
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.procesandoLiquidacion = false;
        this.tipoAlerta = 'error';
        this.mensajeAlerta = err.error?.mensaje || 'Error al ejecutar liquidación masiva en Oracle XE';
        this.cdr.detectChanges();
      }
    });
  }

  calcularTotalBruto(): number {
    return this.liquidaciones.reduce((acc, curr) => acc + curr.totalBruto, 0);
  }

  calcularTotalComision(): number {
    return this.liquidaciones.reduce((acc, curr) => acc + curr.comisionPlataforma, 0);
  }

  calcularTotalNeto(): number {
    return this.liquidaciones.reduce((acc, curr) => acc + curr.pagoNetoPropietario, 0);
  }
}
