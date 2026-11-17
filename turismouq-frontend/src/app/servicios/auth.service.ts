import { Injectable, signal, computed } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, tap, map } from 'rxjs';
import { LoginPeticion, RegistroPeticion, LoginRespuesta, RespuestaApi } from '../modelos/modelos';

@Injectable({
  providedIn: 'root'
})
export class AuthService {

  private readonly API_URL = 'http://localhost:8080/api/auth';
  private readonly STORAGE_KEY = 'turismouq_usuario_activo';

  // Señal reactiva con el usuario autenticado
  private usuarioSignal = signal<LoginRespuesta | null>(this.cargarUsuarioAlmacenado());

  // Señales derivadas
  readonly usuarioActual = computed(() => this.usuarioSignal());
  readonly estaAutenticado = computed(() => this.usuarioSignal() !== null);
  readonly rolActual = computed(() => this.usuarioSignal()?.rol || 'GUEST');
  readonly esSuperAdmin = computed(() => this.usuarioSignal()?.rol === 'ROL_SUPER_ADMIN');

  constructor(private http: HttpClient) {}

  private cargarUsuarioAlmacenado(): LoginRespuesta | null {
    try {
      const data = sessionStorage.getItem(this.STORAGE_KEY);
      return data ? JSON.parse(data) : null;
    } catch {
      return null;
    }
  }

  login(peticion: LoginPeticion): Observable<LoginRespuesta> {
    return this.http.post<RespuestaApi<LoginRespuesta>>(`${this.API_URL}/login`, peticion)
      .pipe(
        map(res => res.datos),
        tap(usuario => {
          this.guardarSesion(usuario);
        })
      );
  }

  registro(peticion: RegistroPeticion): Observable<LoginRespuesta> {
    return this.http.post<RespuestaApi<LoginRespuesta>>(`${this.API_URL}/registro`, peticion)
      .pipe(
        map(res => res.datos),
        tap(usuario => {
          this.guardarSesion(usuario);
        })
      );
  }

  logout(): void {
    try {
      sessionStorage.removeItem(this.STORAGE_KEY);
    } catch {}
    this.usuarioSignal.set(null);
  }

  private guardarSesion(usuario: LoginRespuesta): void {
    try {
      sessionStorage.setItem(this.STORAGE_KEY, JSON.stringify(usuario));
    } catch {}
    this.usuarioSignal.set(usuario);
  }

  /**
   * Determina si la ruta está permitida para el rol actual
   */
  tieneAcceso(ruta: string): boolean {
    const usuario = this.usuarioSignal();

    // Modo Huésped / Público (Sin iniciar sesión)
    if (!usuario) {
      return ruta === '/catalogo' || ruta === '/reservas';
    }

    // Super Admin tiene acceso irrestricto
    if (usuario.rol === 'ROL_SUPER_ADMIN') {
      return true;
    }

    // Rutas permitidas reportadas por el backend para el rol
    return usuario.rutasPermitidas.some(r => ruta.startsWith(r));
  }
}
