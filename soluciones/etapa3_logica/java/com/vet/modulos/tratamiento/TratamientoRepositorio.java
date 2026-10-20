package com.vet.modulos.tratamiento;

import com.vet.db.Db;
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
    private static final String TR_01 = """
            SELECT t.ID_TRATAMIENTO, c.ID_MASCOTA, m.NOMBRE AS MASCOTA, t.DESCRIPCION, t.FECHA_INICIO,
                   t.SESIONES_PROGRAMADAS, t.FRECUENCIA_DIAS, t.ESTADO,
                   (SELECT COUNT(*) FROM SESION_TRATAMIENTO s WHERE s.ID_TRATAMIENTO = t.ID_TRATAMIENTO) AS REALIZADAS,
                   PKG_TRATAMIENTO.FN_AVANCE(t.ID_TRATAMIENTO) AS AVANCE
              FROM TRATAMIENTO t
              JOIN ATENCION a ON a.ID_ATENCION = t.ID_ATENCION
              JOIN CITA c     ON c.ID_CITA = a.ID_CITA
              JOIN MASCOTA m  ON m.ID_MASCOTA = c.ID_MASCOTA
             WHERE :estado IS NULL OR t.ESTADO = :estado
             ORDER BY t.FECHA_INICIO DESC, t.ID_TRATAMIENTO DESC
             FETCH FIRST 200 ROWS ONLY
            """;

    /**
     * [TR-02] Un tratamiento con su mascota, propietario y el veterinario que lo indico.
     * Columnas: ID_TRATAMIENTO, ID_MASCOTA, MASCOTA, PROPIETARIO, VETERINARIO, DESCRIPCION, FECHA_INICIO,
     *           SESIONES_PROGRAMADAS, FRECUENCIA_DIAS, ESTADO, AVANCE
     * Parametros: :id
     */
    private static final String TR_02 = """
            SELECT t.ID_TRATAMIENTO, m.ID_MASCOTA, m.NOMBRE AS MASCOTA,
                   p.APELLIDOS || ', ' || p.NOMBRES AS PROPIETARIO,
                   v.NOMBRES || ' ' || v.APELLIDOS AS VETERINARIO,
                   t.DESCRIPCION, t.FECHA_INICIO, t.SESIONES_PROGRAMADAS, t.FRECUENCIA_DIAS, t.ESTADO,
                   PKG_TRATAMIENTO.FN_AVANCE(t.ID_TRATAMIENTO) AS AVANCE
              FROM TRATAMIENTO t
              JOIN ATENCION a    ON a.ID_ATENCION = t.ID_ATENCION
              JOIN VETERINARIO v ON v.ID_VETERINARIO = a.ID_VETERINARIO
              JOIN CITA c        ON c.ID_CITA = a.ID_CITA
              JOIN MASCOTA m     ON m.ID_MASCOTA = c.ID_MASCOTA
              JOIN PROPIETARIO p ON p.ID_PROPIETARIO = m.ID_PROPIETARIO
             WHERE t.ID_TRATAMIENTO = :id
            """;

    /**
     * [TR-03] Sesiones de un tratamiento en orden.
     * Columnas: NUMERO, FECHA, VETERINARIO, OBSERVACIONES
     * Parametros: :id
     */
    private static final String TR_03 = """
            SELECT s.NUMERO, s.FECHA, v.NOMBRES || ' ' || v.APELLIDOS AS VETERINARIO, s.OBSERVACIONES
              FROM SESION_TRATAMIENTO s
              JOIN VETERINARIO v ON v.ID_VETERINARIO = s.ID_VETERINARIO
             WHERE s.ID_TRATAMIENTO = :id
             ORDER BY s.NUMERO
            """;

    /**
     * [TR-04] Tratamientos de una mascota (los mas recientes primero).
     * Columnas: ID_TRATAMIENTO, DESCRIPCION, FECHA_INICIO, SESIONES_PROGRAMADAS, REALIZADAS, ESTADO
     * Parametros: :id_mascota
     */
    private static final String TR_04 = """
            SELECT t.ID_TRATAMIENTO, t.DESCRIPCION, t.FECHA_INICIO, t.SESIONES_PROGRAMADAS,
                   (SELECT COUNT(*) FROM SESION_TRATAMIENTO s WHERE s.ID_TRATAMIENTO = t.ID_TRATAMIENTO) AS REALIZADAS,
                   t.ESTADO
              FROM TRATAMIENTO t
              JOIN ATENCION a ON a.ID_ATENCION = t.ID_ATENCION
              JOIN CITA c     ON c.ID_CITA = a.ID_CITA
             WHERE c.ID_MASCOTA = :id_mascota
             ORDER BY t.FECHA_INICIO DESC
            """;

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
