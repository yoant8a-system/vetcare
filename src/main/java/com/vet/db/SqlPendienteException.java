package com.vet.db;

/** La sentencia [id] todavia no fue escrita (ver sql/consultas_app.sql y la clase *Repositorio). */
public class SqlPendienteException extends RuntimeException {

    private final String id;

    public SqlPendienteException(String id) {
        super("Falta implementar la sentencia SQL [" + id + "]");
        this.id = id;
    }

    public String getId() {
        return id;
    }
}
