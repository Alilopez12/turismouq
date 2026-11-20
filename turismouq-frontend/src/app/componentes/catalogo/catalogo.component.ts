import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { RouterLink } from '@angular/router';
import { TurismoService } from '../../servicios/turismo.service';
import { Alojamiento, Municipio, TipoAlojamiento } from '../../modelos/modelos';

@Component({
  selector: 'app-catalogo',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './catalogo.component.html',
  styleUrl: './catalogo.component.css'
})
export class CatalogoComponent implements OnInit {

  municipios: Municipio[] = [];
  tiposAlojamiento: TipoAlojamiento[] = [];
  alojamientos: Alojamiento[] = [];
  cargando = true;

  idMunicipioSeleccionado: number | null = null;
  idTipoSeleccionado: number | null = null;
  busquedaTexto: string = '';
  ordenSeleccionado: 'destacados' | 'capacidad' | 'nombre' = 'destacados';

  constructor(
    private turismoService: TurismoService,
    private cdr: ChangeDetectorRef
  ) {}

  ngOnInit(): void {
    this.cargarFiltros();
    this.cargarAlojamientos();
  }

  get alojamientosFiltrados(): Alojamiento[] {
    const termino = this.busquedaTexto.trim().toLowerCase();
    let lista = !termino
      ? [...this.alojamientos]
      : this.alojamientos.filter((a) =>
          a.nombre?.toLowerCase().includes(termino) ||
          a.municipio?.nombre?.toLowerCase().includes(termino) ||
          a.direccion?.toLowerCase().includes(termino) ||
          a.propietario?.nombres?.toLowerCase().includes(termino) ||
          a.tipoAlojamiento?.nombre?.toLowerCase().includes(termino)
        );

    if (this.ordenSeleccionado === 'capacidad') {
      lista.sort((a, b) => (b.capacidad || 0) - (a.capacidad || 0));
    } else if (this.ordenSeleccionado === 'nombre') {
      lista.sort((a, b) => (a.nombre || '').localeCompare(b.nombre || ''));
    }
    return lista;
  }

  cargarFiltros(): void {
    this.turismoService.obtenerMunicipios().subscribe({
      next: (m) => {
        this.municipios = m;
        this.cdr.detectChanges();
      },
      error: (e) => {
        console.error('Error al cargar municipios', e);
        this.cdr.detectChanges();
      }
    });

    this.turismoService.obtenerTiposAlojamiento().subscribe({
      next: (t) => {
        this.tiposAlojamiento = t;
        this.cdr.detectChanges();
      },
      error: (e) => {
        console.error('Error al cargar tipos', e);
        this.cdr.detectChanges();
      }
    });
  }

  cargarAlojamientos(): void {
    this.cargando = true;
    this.cdr.detectChanges();
    this.turismoService.obtenerAlojamientos(
      this.idMunicipioSeleccionado || undefined,
      this.idTipoSeleccionado || undefined
    ).subscribe({
      next: (a) => {
        this.alojamientos = a;
        this.cargando = false;
        this.cdr.detectChanges();
      },
      error: (e) => {
        console.error('Error al cargar alojamientos', e);
        this.cargando = false;
        this.cdr.detectChanges();
      }
    });
  }

  seleccionarTipoRapido(idTipo: number | null): void {
    this.idTipoSeleccionado = idTipo;
    this.cargarAlojamientos();
  }

  limpiarFiltros(): void {
    this.idMunicipioSeleccionado = null;
    this.idTipoSeleccionado = null;
    this.busquedaTexto = '';
    this.cargarAlojamientos();
  }

  obtenerClaseTipo(nombreTipo: string): string {
    const tipo = nombreTipo?.toLowerCase() || '';
    if (tipo.includes('finca')) return 'insignia-finca';
    if (tipo.includes('glamping')) return 'insignia-glamping';
    if (tipo.includes('hotel')) return 'insignia-hotel';
    return 'insignia-hostal';
  }

  obtenerClasePortada(nombreTipo: string, idAlojamiento = 0): string {
    const tipo = nombreTipo?.toLowerCase() || '';
    const v = (idAlojamiento || 0) % 2 === 0 ? 'a' : 'b';
    if (tipo.includes('finca')) return `portada-finca portada-var-${v}`;
    if (tipo.includes('glamping')) return `portada-glamping portada-var-${v}`;
    if (tipo.includes('hotel')) return `portada-hotel portada-var-${v}`;
    return `portada-hostal portada-var-${v}`;
  }

  esTipoPortada(nombreTipo: string, clave: 'finca' | 'glamping' | 'hotel'): boolean {
    return (nombreTipo || '').toLowerCase().includes(clave);
  }

  obtenerEtiquetaDestacado(idAlojamiento: number): string {
    const etiquetas = ['Favorito en Quindío', 'Vista al Valle', 'Café de Origen', 'Recomendado'];
    return etiquetas[(idAlojamiento || 0) % etiquetas.length];
  }

  obtenerCalificacion(idAlojamiento: number): string {
    const puntajes = ['4.96', '4.92', '4.89', '4.95', '4.87', '4.98', '4.91', '4.94'];
    return puntajes[(idAlojamiento || 0) % puntajes.length];
  }
}
