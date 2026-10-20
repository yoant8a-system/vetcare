package com.vet.db;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Marca una sentencia SQL que el equipo todavia no escribio.
 *
 *   private static final String PR_01 = Sql.pendiente("PR-01");
 *
 * Mientras siga asi, la pagina que la usa muestra "Falta implementar [PR-01]".
 * Cuando la escriban, reemplazan la linea por:
 *
 *   private static final String PR_01 = """
 *           SELECT ...
 *           """;
 *
 * MODO "COMPLETAR CON SOLUCION" (app.completar_con_solucion=true en config/db.properties):
 * las sentencias que aun esten pendientes se toman de soluciones/etapa3_logica/consultas_app.sql.
 * Las que el equipo ya escribio NO se tocan (no pasan por aqui).
 */
public final class Sql {

    private static final String PREFIJO = "--PENDIENTE:";
    private static final Pattern CABECERA = Pattern.compile("^-- \\[([A-Z]{2}-\\d{2})\\].*");
    private static final Map<String, String> SOLUCIONES = new HashMap<>();

    private Sql() {
    }

    public static String pendiente(String id) {
        String solucion = SOLUCIONES.get(id);
        return solucion != null ? solucion : PREFIJO + id;
    }

    static boolean esPendiente(String sql) {
        return sql == null || sql.isBlank() || sql.startsWith(PREFIJO);
    }

    static String id(String sql) {
        return sql == null || !sql.startsWith(PREFIJO) ? "?" : sql.substring(PREFIJO.length());
    }

    public static int cantidadSoluciones() {
        return SOLUCIONES.size();
    }

    /** Lee el archivo de soluciones: cada sentencia va despues de "-- [ID] ..." y termina en ";". */
    public static void cargarSoluciones(Path archivo) throws IOException {
        String actual = null;
        StringBuilder sb = new StringBuilder();
        for (String linea : Files.readAllLines(archivo, StandardCharsets.UTF_8)) {
            Matcher m = CABECERA.matcher(linea);
            if (m.matches()) {
                actual = m.group(1);
                sb.setLength(0);
                continue;
            }
            if (actual == null || linea.trim().startsWith("--") || linea.isBlank()) {
                continue;
            }
            String t = linea.stripTrailing();
            if (t.endsWith(";")) {
                sb.append(t, 0, t.length() - 1);
                SOLUCIONES.put(actual, sb.toString());
                actual = null;
            } else {
                sb.append(t).append('\n');
            }
        }
    }
}
