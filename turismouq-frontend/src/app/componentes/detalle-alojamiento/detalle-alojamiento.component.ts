import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { ActivatedRoute, Router, RouterLink } from '@angular/router';
import { TurismoService } from '../../servicios/turismo.service';
import { Alojamiento, Habitacion, Tarifa, CotizacionRespuesta } from '../../modelos/modelos';

@Component({
  selector: 'app-detalle-alojamiento',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './detalle-alojamiento.component.html',
  styleUrl: './detalle-alojamiento.component.css'
})
export class DetalleAlojamientoComponent implements OnInit {

  alojamiento: Alojamiento | null = null;
  habitaciones: Habitacion[] = [];
  cargando = true;

  // Cotizador en tiempo real (Llamando a la función PL/SQL fn_valor_estadia)
  habitacionSeleccionada: Habitacion | null = null;
  tarifasHabitacion: Tarifa[] = [];
  fechaCheckIn = '2026-11-10';
  fechaCheckOut = '2026-11-15';
  cotizacion: CotizacionRespuesta | null = null;
  cargandoCotizacion = false;
  errorCotizacion = '';

  constructor(
    private route: ActivatedRoute,
    private router: Router,
    private turismoService: TurismoService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    const id = Number(this.route.snapshot.paramMap.get('id'));
    if (id) {
      this.cargarDatos(id);
    }
  }

  cargarDatos(id: number): void {
    this.cargando = true;
    this.turismoService.obtenerAlojamientoPorId(id).subscribe({
      next: (a) => {
        this.alojamiento = a;
        this.cargarHabitaciones(id);
        this.cdr.detectChanges();
      },
      error: (e) => {
        console.error('Error al cargar alojamiento', e);
        this.cargando = false;
        this.cdr.detectChanges();
      }
    });
  }

  cargarHabitaciones(idAlojamiento: number): void {
    this.turismoService.obtenerHabitaciones(idAlojamiento).subscribe({
      next: (habs) => {
        this.habitaciones = habs;
        this.cargando = false;
        if (habs.length > 0) {
          this.seleccionarHabitacion(habs[0]);
        }
        this.cdr.detectChanges();
      },
      error: (e) => {
        console.error('Error al cargar habitaciones', e);
        this.cargando = false;
        this.cdr.detectChanges();
      }
    });
  }

  seleccionarHabitacion(hab: Habitacion): void {
    this.habitacionSeleccionada = hab;
    this.cotizacion = null;
    this.errorCotizacion = '';

    this.turismoService.obtenerTarifas(hab.idHabitacion).subscribe({
      next: (t) => {
        this.tarifasHabitacion = t;
        this.calcularCotizacion();
        this.cdr.detectChanges();
      },
      error: (e) => {
        console.error('Error al cargar tarifas', e);
        this.cdr.detectChanges();
      }
    });
  }

  calcularCotizacion(): void {
    if (!this.habitacionSeleccionada || !this.fechaCheckIn || !this.fechaCheckOut) {
      return;
    }

    this.cargandoCotizacion = true;
    this.errorCotizacion = '';

    this.turismoService.cotizarEstadia({
      idHabitacion: this.habitacionSeleccionada.idHabitacion,
      fechaCheckIn: this.fechaCheckIn,
      fechaCheckOut: this.fechaCheckOut
    }).subscribe({
      next: (res) => {
        this.cotizacion = res;
        this.cargandoCotizacion = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        this.errorCotizacion = err.error?.mensaje || 'Error al calcular tarifa en Oracle';
        this.cargandoCotizacion = false;
        this.cotizacion = null;
        this.cdr.detectChanges();
      }
    });
  }

  irAReservar(): void {
    if (!this.habitacionSeleccionada) return;
    this.router.navigate(['/reservas'], {
      queryParams: {
        idHabitacion: this.habitacionSeleccionada.idHabitacion,
        checkIn: this.fechaCheckIn,
        checkOut: this.fechaCheckOut
      }
    });
  }
}
