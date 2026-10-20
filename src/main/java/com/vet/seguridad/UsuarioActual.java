package com.vet.seguridad;

/** Usuario logueado en el hilo de la peticion actual (lo usa la auditoria de Oracle). */
public final class UsuarioActual {

    private static final ThreadLocal<String> USUARIO = new ThreadLocal<>();

    private UsuarioActual() {
    }

    public static void set(String usuario) {
        USUARIO.set(usuario);
    }

    public static String get() {
        String u = USUARIO.get();
        return u == null ? "anonimo" : u;
    }

    public static void limpiar() {
        USUARIO.remove();
    }
}
