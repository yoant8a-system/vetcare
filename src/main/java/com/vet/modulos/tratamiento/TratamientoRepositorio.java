package com.vet.modulos.tratamiento;

import com.vet.db.Db;
import com.vet.db.Sql;
import com.vet.db.Plsql;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

import static com.vet.db.Plsql.in;
import static com.vet.db.Plsql.outNumero;

/** Tratamientos y sesiones (las reglas estan en PKG_TRATAMIENTO). */
@Repository
public class TratamientoRepositorio {

    /**
     * [TR-01] Tratamientos filtrados por estado (:estado NULL = todos), el mas reciente primero. Maximo 200.
     * Para llegar a la mascota: TRATAMIENTO -> ATENCION -> CITA -> MASCOTA.
     * Columnas: ID_TRATAMIENTO, ID_MASCOTA, MASCOTA, DESCRIPCION, FECHA_INICIO, SESIONES_PROGRAMADAS,
     *           FRECUENCIA_DIAS, ESTADO, REALIZADAS (sesiones hechas: subconsulta COUNT),
     *           AVANCE (porcentaje: se puede llamar a PKG_TRATAMIENTO.FN_AVANCE dentro del SELECT)
     * Parametros: :estado
     */
    private static final String TR_01 = Sql.pendiente("TR-01");

    /**
     * [TR-02] Un tratamiento con su mascota, propietario y el veterinario que lo indico.
     * Columnas: ID_TRATAMIENTO, ID_MASCOTA, MASCOTA, PROPIETARIO, VETERINARIO, DESCRIPCION, FECHA_INICIO,
     *           SESIONES_PROGRAMADAS, FRECUENCIA_DIAS, ESTADO, AVANCE
     * Parametros: :id
     */
    private static final String TR_02 = Sql.pendiente("TR-02");

    /**
     * [TR-03] Sesiones de un tratamiento en orden.
     * Columnas: NUMERO, FECHA, VETERINARIO, OBSERVACIONES
     * Parametros: :id
     */
    private static final String TR_03 = Sql.pendiente("TR-03");

    /**
     * [TR-04] Tratamientos de una mascota (los mas recientes primero).
     * Columnas: ID_TRATAMIENTO, DESCRIPCION, FECHA_INICIO, SESIONES_PROGRAMADAS, REALIZADAS, ESTADO
     * Parametros: :id_mascota
     */
    private static final String TR_04 = Sql.pendiente("TR-04");

    private final Db db;
    private final Plsql plsql;

    public TratamientoRepositorio(Db db, Plsql plsql) {
        this.db = db;
        this.plsql = plsql;
    }

    public List<Map<String, Object>> listar(String estado) { return db.lista(TR_01, "estado", estado); }

    public Map<String, Object> obtener(long id) { return db.uno(TR_02, "id", id); }

    public List<Map<String, Object>> sesiones(long id) { return db.lista(TR_03, "id", id); }

    public List<Map<String, Object>> deMascota(long idMascota) { return db.lista(TR_04, "id_mascota", idMascota); }

    // ------------------------------------------------------------ PL/SQL: PKG_TRATAMIENTO

    public long registrarSesion(long idTratamiento, long idVet, String obs) {
        return plsql.llamar("PKG_TRATAMIENTO.PR_REGISTRAR_SESION",
                in(idTratamiento), in(idVet), in(obs), outNumero()).numero(0);
    }

    public void suspender(long idTratamiento) {
        plsql.llamar("PKG_TRATAMIENTO.PR_SUSPENDER", in(idTratamiento));
    }
}
