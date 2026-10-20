package com.vet.db;

import java.sql.SQLException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Traduce los errores de Oracle a mensajes entendibles para el usuario.
 *   ORA-20xxx  -> el mensaje de RAISE_APPLICATION_ERROR tal cual (reglas de negocio)
 *   ORA-00001  -> "ya existe"           ORA-02292 -> "tiene registros relacionados"
 *   ORA-02290  -> "no cumple la regla"  ORA-00942 / PLS-00201 -> "falta crear el objeto"
 */
public final class ErroresOracle {

    private static final Pattern ORA = Pattern.compile("(ORA|PLS)-(\\d{5}): ?([^\\n]*)");
    private static final Pattern RESTRICCION = Pattern.compile("\\(([A-Z0-9_$#]+\\.)?([A-Z0-9_$#]+)\\)");

    private ErroresOracle() {
    }

    public static String mensaje(Throwable e) {
        if (e instanceof SqlPendienteException p) {
            return p.getMessage();
        }
        String texto = textoCompleto(e);
        Matcher m = ORA.matcher(texto);
        if (!m.find()) {
            return e.getMessage() == null ? e.getClass().getSimpleName() : e.getMessage();
        }
        int codigo = Integer.parseInt(m.group(2));
        String detalle = m.group(3).trim();
        String obj = restriccion(detalle);

        if (m.group(1).equals("ORA") && codigo >= 20000 && codigo <= 20999) {
            return detalle;
        }
        return switch (codigo) {
            case 1 -> "Ya existe un registro con ese dato unico (" + obj + ").";
            case 1400 -> "Falta un dato obligatorio: " + detalle;
            case 1438, 12899 -> "Un valor es demasiado grande o largo para su campo: " + detalle;
            case 2290 -> "El dato no cumple la regla " + obj + ".";
            case 2291 -> "Se hace referencia a un registro que no existe (" + obj + ").";
            case 2292 -> "No se puede eliminar: tiene registros relacionados (" + obj + ").";
            case 942, 4043, 201, 904 -> "Falta crear en Oracle un objeto que usa esta pantalla: " + detalle
                    + "  (revise los scripts de sql/)";
            case 6550 -> "Error al llamar a PL/SQL (¿el paquete existe y esta VALID?): " + siguienteError(texto, m.end());
            case 1017 -> "Usuario o contraseña de Oracle incorrectos (config/db.properties).";
            case 12505, 12514, 12541, 17002 -> "No hay conexion con Oracle: ¿esta encendido el servicio OracleServiceXE?";
            default -> m.group(1) + "-" + m.group(2) + ": " + detalle;
        };
    }

    private static String restriccion(String detalle) {
        Matcher r = RESTRICCION.matcher(detalle);
        return r.find() ? r.group(2) : detalle;
    }

    private static String siguienteError(String texto, int desde) {
        Matcher m = ORA.matcher(texto);
        return m.find(desde) ? m.group(1) + "-" + m.group(2) + ": " + m.group(3) : "";
    }

    private static String textoCompleto(Throwable e) {
        StringBuilder sb = new StringBuilder();
        for (Throwable t = e; t != null; t = t.getCause()) {
            if (t instanceof SQLException || t.getMessage() != null) {
                sb.append(t.getMessage()).append('\n');
            }
        }
        return sb.toString();
    }
}
