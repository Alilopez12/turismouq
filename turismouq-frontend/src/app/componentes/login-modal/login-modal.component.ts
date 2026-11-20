import { Component, EventEmitter, Output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { AuthService } from '../../servicios/auth.service';
import { LoginPeticion, RegistroPeticion } from '../../modelos/modelos';

@Component({
  selector: 'app-login-modal',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './login-modal.component.html',
  styleUrl: './login-modal.component.css'
})
export class LoginModalComponent {

  @Output() cerrar = new EventEmitter<void>();

  pestanaActiva: 'login' | 'registro' = 'login';
  cargando = false;
  mensajeError = '';
  mensajeExito = '';

  // Formulario Login
  loginForm: LoginPeticion = {
    usuario: '',
    contrasena: ''
  };

  // Formulario Registro
  registroForm: RegistroPeticion = {
    nombreCompleto: '',
    correo: '',
    usuario: '',
    contrasena: '',
    rol: 'ROL_RECEPCION'
  };

  // Roles disponibles para selección en registro
  rolesDisponibles = [
    { valor: 'ROL_RECEPCION', etiqueta: 'Recepción (Check-in, Disponibilidad y Vouchers)' },
    { valor: 'ROL_ADMIN_ALOJAMIENTO', etiqueta: 'Administrador de Alojamiento (Gestión y Liquidaciones)' },
    { valor: 'ROL_GERENTE', etiqueta: 'Gerente (Analítica, Reportes Financieros y Ocupación)' },
    { valor: 'ROL_AUDITOR', etiqueta: 'Auditor de Sistema (Auditoría de Tarifas y Storage)' },
    { valor: 'ROL_SUPER_ADMIN', etiqueta: 'Super Administrador (Acceso Total al Sistema)' }
  ];

  constructor(public authService: AuthService) {}

  cambiarPestana(p: 'login' | 'registro'): void {
    this.pestanaActiva = p;
    this.mensajeError = '';
    this.mensajeExito = '';
  }

  autollenarUsuario(usuario: string, clave: string): void {
    this.pestanaActiva = 'login';
    this.loginForm.usuario = usuario;
    this.loginForm.contrasena = clave;
    this.mensajeError = '';
  }

  iniciarSesion(): void {
    if (!this.loginForm.usuario || !this.loginForm.contrasena) {
      this.mensajeError = 'Por favor ingresa usuario y contraseña.';
      return;
    }

    this.cargando = true;
    this.mensajeError = '';
    this.mensajeExito = '';

    this.authService.login(this.loginForm).subscribe({
      next: (usuario) => {
        this.cargando = false;
        this.mensajeExito = `¡Bienvenido(a), ${usuario.nombreCompleto}! Accediendo como ${usuario.descripcionRol}.`;
        setTimeout(() => {
          this.cerrar.emit();
        }, 800);
      },
      error: (err) => {
        this.cargando = false;
        this.mensajeError = err?.error?.mensaje || 'Credenciales incorrectas o usuario inactivo.';
      }
    });
  }

  registrarUsuario(): void {
    if (!this.registroForm.nombreCompleto || !this.registroForm.correo || 
        !this.registroForm.usuario || !this.registroForm.contrasena) {
      this.mensajeError = 'Todos los campos son obligatorios para el registro.';
      return;
    }

    this.cargando = true;
    this.mensajeError = '';
    this.mensajeExito = '';

    this.authService.registro(this.registroForm).subscribe({
      next: (usuario) => {
        this.cargando = false;
        this.mensajeExito = `Usuario "${usuario.usuario}" registrado y autenticado exitosamente como ${usuario.descripcionRol}.`;
        setTimeout(() => {
          this.cerrar.emit();
        }, 900);
      },
      error: (err) => {
        this.cargando = false;
        this.mensajeError = err?.error?.mensaje || 'Error al registrar el usuario.';
      }
    });
  }

  cerrarModal(): void {
    this.cerrar.emit();
  }
}
