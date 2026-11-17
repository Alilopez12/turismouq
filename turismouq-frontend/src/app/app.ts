import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RouterOutlet, RouterLink, RouterLinkActive } from '@angular/router';
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

  constructor(public authService: AuthService) {}

  abrirLogin(): void {
    this.mostrarModalLogin.set(true);
  }

  cerrarLogin(): void {
    this.mostrarModalLogin.set(false);
  }

  cerrarSesion(): void {
    this.authService.logout();
  }
}
