package com.vet.web;

import org.springframework.stereotype.Component;

import java.util.Set;

/** Ayudantes para las paginas HTML:  ${@vista.imagen(m.ESPECIE)}  ${@vista.dia(h.DIA_SEMANA)} */
@Component("vista")
public class Vista {

    private static final Set<String> CON_IMAGEN = Set.of("perro", "gato", "conejo", "ave");
    private static final String[] DIAS = {"", "Lunes", "Martes", "Miercoles", "Jueves", "Viernes", "Sabado", "Domingo"};
    private static final String[] URGENCIAS = {"", "Emergencia", "Muy urgente", "Urgente", "Poco urgente", "No urgente"};

    public String imagen(Object especie) {
        String e = especie == null ? "" : especie.toString().toLowerCase();
        return "/img/" + (CON_IMAGEN.contains(e) ? e : "logo") + ".svg";
    }

    public String dia(Object n) {
        int i = n == null ? 0 : ((Number) n).intValue();
        return i >= 1 && i <= 7 ? DIAS[i] : "";
    }

    public String urgencia(Object n) {
        int i = n == null ? 0 : ((Number) n).intValue();
        return i >= 1 && i <= 5 ? URGENCIAS[i] : "";
    }

    public String iniciales(String nombre) {
        if (nombre == null || nombre.isBlank()) {
            return "?";
        }
        String[] p = nombre.replace("Dr(a). ", "").trim().split("\\s+");
        return (p[0].substring(0, 1) + (p.length > 1 ? p[1].substring(0, 1) : "")).toUpperCase();
    }
}
