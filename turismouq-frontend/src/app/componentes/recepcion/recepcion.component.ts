import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { TurismoService } from '../../servicios/turismo.service';
import { RecepcionCheckin, RecepcionDisponibilidad, RecepcionVoucher } from '../../modelos/modelos';

@Component({
  selector: 'app-recepcion',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './recepcion.component.html',
  styleUrl: './recepcion.component.css'
})
export class RecepcionComponent implements OnInit {

  vistaActiva: 'checkin' | 'disponibilidad' | 'voucher' = 'checkin';

  // Checkin de Hoy
  checkins: RecepcionCheckin[] = [];
  cargandoCheckin = false;
  filtroCheckin = '';

  // Disponibilidad
  disponibilidad: RecepcionDisponibilidad[] = [];
  cargandoDisponibilidad = false;
  filtroAlojamiento = '';

  // Voucher
  idReservaBuscar: number = 1;
  voucherActual: RecepcionVoucher | null = null;
  cargandoVoucher = false;
  errorVoucher = '';

  constructor(
    private turismoService: TurismoService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarCheckinHoy();
    this.cargarDisponibilidad();
    this.consultarVoucher(1);
  }

  cambiarVista(vista: 'checkin' | 'disponibilidad' | 'voucher'): void {
    this.vistaActiva = vista;
    if (vista === 'checkin' && this.checkins.length === 0) {
      this.cargarCheckinHoy();
    } else if (vista === 'disponibilidad' && this.disponibilidad.length === 0) {
      this.cargarDisponibilidad();
    }
  }

  cargarCheckinHoy(): void {
    this.cargandoCheckin = true;
    this.turismoService.obtenerCheckinHoy().subscribe({
      next: (datos) => {
        this.checkins = datos || [];
        this.cargandoCheckin = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        console.error('Error al cargar check-ins de hoy', err);
        this.cargandoCheckin = false;
        this.cdr.detectChanges();
      }
    });
  }

  cargarDisponibilidad(): void {
    this.cargandoDisponibilidad = true;
    this.turismoService.obtenerDisponibilidadRecepcion().subscribe({
      next: (datos) => {
        this.disponibilidad = datos || [];
        this.cargandoDisponibilidad = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        console.error('Error al cargar disponibilidad', err);
        this.cargandoDisponibilidad = false;
        this.cdr.detectChanges();
      }
    });
  }

  consultarVoucher(id?: number): void {
    const idABuscar = id || this.idReservaBuscar;
    if (!idABuscar) return;

    this.idReservaBuscar = idABuscar;
    this.cargandoVoucher = true;
    this.errorVoucher = '';
    this.voucherActual = null;

    this.turismoService.obtenerVoucherRecepcion(idABuscar).subscribe({
      next: (v) => {
        this.voucherActual = v;
        this.cargandoVoucher = false;
        this.cdr.detectChanges();
      },
      error: (err) => {
        console.error('Error al obtener voucher', err);
        this.errorVoucher = err?.error?.mensaje || `No se encontró la reserva #${idABuscar} o no está activa.`;
        this.cargandoVoucher = false;
        this.cdr.detectChanges();
      }
    });
  }

  abrirVoucherDesdeCheckin(idReserva: number): void {
    this.vistaActiva = 'voucher';
    this.consultarVoucher(idReserva);
  }

  imprimirVoucher(): void {
    window.print();
  }

  get checkinsFiltrados(): RecepcionCheckin[] {
    if (!this.filtroCheckin.trim()) return this.checkins;
    const f = this.filtroCheckin.toLowerCase();
    return this.checkins.filter(c =>
      (c.nombreHuesped && c.nombreHuesped.toLowerCase().includes(f)) ||
      (c.alojamiento && c.alojamiento.toLowerCase().includes(f)) ||
      (c.habitacion && c.habitacion.toLowerCase().includes(f)) ||
      (c.documentoHuesped && c.documentoHuesped.toLowerCase().includes(f)) ||
      c.idReserva.toString().includes(f)
    );
  }

  get disponibilidadFiltrada(): RecepcionDisponibilidad[] {
    if (!this.filtroAlojamiento.trim()) return this.disponibilidad;
    const f = this.filtroAlojamiento.toLowerCase();
    return this.disponibilidad.filter(d =>
      (d.alojamiento && d.alojamiento.toLowerCase().includes(f)) ||
      (d.tipoCama && d.tipoCama.toLowerCase().includes(f)) ||
      (d.habitacion && d.habitacion.toLowerCase().includes(f)) ||
      (d.municipio && d.municipio.toLowerCase().includes(f))
    );
  }
}
