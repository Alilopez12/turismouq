import { Component, OnInit, ChangeDetectorRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { TurismoService } from '../../servicios/turismo.service';
import { AuditoriaTarifaItem } from '../../modelos/modelos';

@Component({
  selector: 'app-auditoria',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './auditoria.component.html',
  styleUrl: './auditoria.component.css'
})
export class AuditoriaComponent implements OnInit {

  registros: AuditoriaTarifaItem[] = [];
  cargando = true;

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
}
