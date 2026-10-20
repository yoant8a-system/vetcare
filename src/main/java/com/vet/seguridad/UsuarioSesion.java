package com.vet.seguridad;

import java.io.Serializable;

/** Datos del usuario logueado que se guardan en la sesion HTTP. */
public record UsuarioSesion(long id, String usuario, String nombre, String rol, Long idVeterinario)
        implements Serializable {

    public static final String ATRIBUTO = "usuario";

    public boolean esAdmin() {
        return "ADMIN".equals(rol);
    }

    public boolean esRecepcion() {
        return "RECEPCION".equals(rol);
    }

    public boolean esVeterinario() {
        return "VETERINARIO".equals(rol);
    }

    public boolean tieneRol(String... roles) {
        for (String r : roles) {
            if (r.equals(rol)) {
                return true;
            }
        }
        return false;
    }
}
