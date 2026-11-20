import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router, RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
import { AuthService } from './servicios/auth.service';
import { LoginModalComponent } from './componentes/login-modal/login-modal.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, RouterOutlet, RouterLink, RouterLinkActive, LoginModalComponent],
  templateUrl: './app.html',
  styleUrl: './app.css'
})
export class App {
  title = 'TurismoUQ';
  mostrarModalLogin = signal<boolean>(false);
  sidebarAbierto = signal<boolean>(false);

  constructor(
    public authService: AuthService,
    private router: Router
  ) {}

  abrirLogin(): void {
    this.mostrarModalLogin.set(true);
  }

  cerrarLogin(): void {
    this.mostrarModalLogin.set(false);
  }

  toggleSidebar(): void {
    this.sidebarAbierto.update(v => !v);
  }

  cerrarSidebar(): void {
    this.sidebarAbierto.set(false);
  }

  cerrarSesion(): void {
    this.authService.logout();
    this.sidebarAbierto.set(false);
    this.router.navigate(['/catalogo']);
  }

  tieneAccesoGrupo(rutas: string[]): boolean {
    return rutas.some(r => this.authService.tieneAcceso(r));
  }
}
