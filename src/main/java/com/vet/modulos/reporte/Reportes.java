package com.vet.modulos.reporte;

import java.util.List;

/**
 * Catalogo de reportes. Cada uno es una FUNCION de PKG_REPORTES que devuelve un SYS_REFCURSOR;
 * la app no tiene el SQL: solo pasa los parametros y dibuja las columnas que lleguen.
 */
public final class Reportes {

    private Reportes() {
    }

    public enum Tipo { FECHA, NUMERO, MASCOTA, MEDICAMENTO }

    public record Param(String nombre, String etiqueta, Tipo tipo, String porDefecto) {
    }

    public record Reporte(String codigo, String titulo, String descripcion, String icono,
                          String funcion, String conceptoOracle, List<Param> params) {
    }

    private static final Param DESDE = new Param("desde", "Desde", Tipo.FECHA, "-90");
    private static final Param HASTA = new Param("hasta", "Hasta", Tipo.FECHA, "0");

    public static final List<Reporte> TODOS = List.of(
            new Reporte("historia", "Historia clinica", "Todas las atenciones de una mascota con diagnosticos, tratamientos e insumos.",
                    "bi-journal-medical", "PKG_REPORTES.FN_HISTORIA_CLINICA", "Subconsultas escalares + LISTAGG",
                    List.of(new Param("mascota", "Mascota", Tipo.MASCOTA, null))),
            new Reporte("atenciones-veterinario", "Atenciones por veterinario", "Atenciones por veterinario y especie con subtotales y total general.",
                    "bi-person-badge", "PKG_REPORTES.FN_ATENCIONES_VETERINARIO", "GROUP BY ROLLUP + GROUPING()",
                    List.of(DESDE, HASTA)),
            new Reporte("diagnosticos", "Diagnosticos mas frecuentes", "Ranking de enfermedades por especie y su porcentaje.",
                    "bi-clipboard2-pulse", "PKG_REPORTES.FN_DIAGNOSTICOS_FRECUENTES", "DENSE_RANK() y RATIO_TO_REPORT() OVER (PARTITION BY)",
                    List.of(new Param("desde", "Desde", Tipo.FECHA, "-150"), HASTA, new Param("top", "Top por especie", Tipo.NUMERO, "5"))),
            new Reporte("vacunas", "Vacunas pendientes", "Ultima dosis de cada vacuna que ya vencio o vence pronto, con telefono del dueño.",
                    "bi-shield-plus", "PKG_REPORTES.FN_VACUNAS_PENDIENTES", "ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)",
                    List.of(new Param("dias", "Vencen en los proximos (dias)", Tipo.NUMERO, "30"))),
            new Reporte("kardex", "Kardex de medicamento", "Entradas, salidas y saldo acumulado de un insumo.",
                    "bi-box-seam", "PKG_REPORTES.FN_KARDEX", "SUM() OVER (ORDER BY ... ROWS UNBOUNDED PRECEDING)",
                    List.of(new Param("medicamento", "Medicamento", Tipo.MEDICAMENTO, null))),
            new Reporte("espera", "Tiempos de espera", "Espera y duracion de la atencion segun el nivel de urgencia del triaje.",
                    "bi-hourglass-split", "PKG_REPORTES.FN_TIEMPOS_ESPERA", "Aritmetica de fechas + AVG/MAX",
                    List.of(DESDE, HASTA)),
            new Reporte("mensual", "Atenciones mensuales", "Atenciones por mes, acumulado y variacion contra el mes anterior.",
                    "bi-graph-up-arrow", "PKG_REPORTES.FN_ATENCIONES_MENSUALES", "Vista materializada + LAG() + SUM() OVER",
                    List.of(new Param("anio", "Año", Tipo.NUMERO, "anio"))),
            new Reporte("tratamientos", "Tratamientos en curso", "Avance de cada tratamiento y si va atrasado.",
                    "bi-bandaid", "PKG_REPORTES.FN_TRATAMIENTOS_EN_CURSO", "Funcion de otro paquete dentro de un SELECT",
                    List.of()),
            new Reporte("genealogia", "Genealogia", "Padres, abuelos y bisabuelos de una mascota.",
                    "bi-diagram-3", "PKG_REPORTES.FN_GENEALOGIA", "Consulta jerarquica CONNECT BY + SYS_CONNECT_BY_PATH",
                    List.of(new Param("mascota", "Mascota", Tipo.MASCOTA, null)))
    );

    public static Reporte buscar(String codigo) {
        return TODOS.stream().filter(r -> r.codigo().equals(codigo)).findFirst()
                .orElseThrow(() -> new IllegalArgumentException("No existe el reporte " + codigo));
    }
}
