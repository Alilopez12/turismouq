package co.edu.uniquindio.turismouq.excepcion;

public class NegocioExcepcion extends RuntimeException {

    private final int codigoError;

    public NegocioExcepcion(String mensaje) {
        super(mensaje);
        this.codigoError = 400;
    }

    public NegocioExcepcion(int codigoError, String mensaje) {
        super(mensaje);
        this.codigoError = codigoError;
    }

    public int getCodigoError() {
        return codigoError;
    }
}
