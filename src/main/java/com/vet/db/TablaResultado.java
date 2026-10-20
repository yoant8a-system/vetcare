package com.vet.db;

import java.util.List;

/** Resultado generico de un SYS_REFCURSOR: nombres de columnas + filas. Lo usan los reportes. */
public record TablaResultado(List<String> columnas, List<List<Object>> filas) {

    public boolean vacia() {
        return filas.isEmpty();
    }
}
