package co.edu.uniquindio.turismouq.dto;

public class RespuestaApiDTO<T> {

    private boolean exitoso;
    private String mensaje;
    private T datos;

    public RespuestaApiDTO() {}

    public RespuestaApiDTO(boolean exitoso, String mensaje, T datos) {
        this.exitoso = exitoso;
        this.mensaje = mensaje;
        this.datos = datos;
    }

    public static <T> RespuestaApiDTO<T> exito(String mensaje, T datos) {
        return new RespuestaApiDTO<>(true, mensaje, datos);
    }

    public static <T> RespuestaApiDTO<T> error(String mensaje) {
        return new RespuestaApiDTO<>(false, mensaje, null);
    }

    public boolean isExitoso() {
        return exitoso;
    }

    public void setExitoso(boolean exitoso) {
        this.exitoso = exitoso;
    }

    public String getMensaje() {
        return mensaje;
    }

    public void setMensaje(String mensaje) {
        this.mensaje = mensaje;
    }

    public T getDatos() {
        return datos;
    }

    public void setDatos(T datos) {
        this.datos = datos;
    }
}
