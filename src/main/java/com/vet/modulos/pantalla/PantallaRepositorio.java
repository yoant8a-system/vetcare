package com.vet.modulos.pantalla;

import com.vet.db.Db;
import com.vet.db.Sql;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

/** Pantalla de sala (TV): quien fue llamado y a que consultorio. */
@Repository
public class PantallaRepositorio {

    /**
     * [PA-01] Ultimos 6 pacientes llamados hoy (vista VW_PANTALLA), el mas reciente primero.
     * Columnas: ID_CITA, MASCOTA, APELLIDO, CONSULTORIO, VETERINARIO, FECHA_LLAMADO, NIVEL_URGENCIA
     */
    private static final String PA_01 = Sql.pendiente("PA-01");

    /**
     * [PA-02] Los proximos 10 de la cola (mismo orden que AT-01).
     * Columnas: MASCOTA, NIVEL_URGENCIA
     */
    private static final String PA_02 = Sql.pendiente("PA-02");

    /** [PA-03] Cuantos pacientes hay en la cola (un numero). */
    private static final String PA_03 = Sql.pendiente("PA-03");

    private final Db db;

    public PantallaRepositorio(Db db) {
        this.db = db;
    }

    public List<Map<String, Object>> llamados() { return db.lista(PA_01); }

    public List<Map<String, Object>> proximos() { return db.lista(PA_02); }

    public int enEspera() {
        Integer n = db.valor(PA_03, Integer.class);
        return n == null ? 0 : n;
    }
}
