import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-concurrencia',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './concurrencia.component.html',
  styleUrl: './concurrencia.component.css'
})
export class ConcurrenciaComponent {

  pasoActual: number = 1;

  irAPaso(paso: number): void {
    this.pasoActual = paso;
  }

  siguientePaso(): void {
    if (this.pasoActual < 4) {
      this.pasoActual++;
    }
  }

  anteriorPaso(): void {
    if (this.pasoActual > 1) {
      this.pasoActual--;
    }
  }

  reiniciar(): void {
    this.pasoActual = 1;
  }
}
