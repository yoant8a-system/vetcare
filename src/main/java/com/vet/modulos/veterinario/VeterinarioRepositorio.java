package com.vet.modulos.veterinario;

import com.vet.db.Db;
import com.vet.db.Sql;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

/** SQL de VETERINARIO, VETERINARIO_ESPECIALIDAD (N:M) y HORARIO_VETERINARIO. */
@Repository
public class VeterinarioRepositorio {

    /**
     * [VE-01] Veterinarios ordenados por apellidos, con sus especialidades en UNA columna de texto
     * separadas por coma (pista: LISTAGG en una subconsulta) y cuantos bloques de horario tienen.
     * Columnas: ID_VETERINARIO, CMVP, NOMBRES, APELLIDOS, TELEFONO, EMAIL, ACTIVO, ESPECIALIDADES, BLOQUES_HORARIO
     */
    private static final String VE_01 = Sql.pendiente("VE-01");

    /**
     * [VE-02] Un veterinario por ID.
     * Columnas: ID_VETERINARIO, CMVP, NOMBRES, APELLIDOS, TELEFONO, EMAIL, ACTIVO
     * Parametros: :id
     */
    private static final String VE_02 = Sql.pendiente("VE-02");

    /** [VE-03] Registrar veterinario.  Parametros: :cmvp, :nombres, :apellidos, :telefono, :email */
    private static final String VE_03 = Sql.pendiente("VE-03");

    /** [VE-04] Actualizar veterinario.  Parametros: :cmvp, :nombres, :apellidos, :telefono, :email, :activo, :id */
    private static final String VE_04 = Sql.pendiente("VE-04");

    /**
     * [VE-05] IDs de las especialidades de un veterinario.
     * Columnas: ID_ESPECIALIDAD     Parametros: :id
     */
    private static final String VE_05 = Sql.pendiente("VE-05");

    /** [VE-06] Quitar TODAS las especialidades de un veterinario.  Parametros: :id */
    private static final String VE_06 = Sql.pendiente("VE-06");

    /** [VE-07] Asignar una especialidad a un veterinario.  Parametros: :id_veterinario, :id_especialidad */
    private static final String VE_07 = Sql.pendiente("VE-07");

    /**
     * [VE-08] Horario de un veterinario, ordenado por dia y hora de inicio.
     * Columnas: ID_HORARIO, DIA_SEMANA, HORA_INICIO, HORA_FIN     Parametros: :id
     */
    private static final String VE_08 = Sql.pendiente("VE-08");

    /** [VE-09] Agregar un bloque de horario.  Parametros: :id_veterinario, :dia_semana, :hora_inicio, :hora_fin */
    private static final String VE_09 = Sql.pendiente("VE-09");

    /** [VE-10] Eliminar un bloque de horario.  Parametros: :id_horario */
    private static final String VE_10 = Sql.pendiente("VE-10");

    /**
     * [VE-11] Veterinarios ACTIVOS para combos, ordenados por apellidos.
     * Columnas: ID_VETERINARIO, NOMBRE (nombres y apellidos juntos)
     */
    private static final String VE_11 = Sql.pendiente("VE-11");

    private final Db db;

    public VeterinarioRepositorio(Db db) {
        this.db = db;
    }

    public List<Map<String, Object>> listar() { return db.lista(VE_01); }

    public Map<String, Object> obtener(long id) { return db.uno(VE_02, "id", id); }

    public long insertar(Map<String, String> f) {
        return db.insertar(VE_03, "ID_VETERINARIO", "cmvp", f.get("cmvp"), "nombres", f.get("nombres"),
                "apellidos", f.get("apellidos"), "telefono", f.get("telefono"), "email", f.get("email"));
    }

    public void actualizar(long id, Map<String, String> f) {
        db.ejecutar(VE_04, "cmvp", f.get("cmvp"), "nombres", f.get("nombres"), "apellidos", f.get("apellidos"),
                "telefono", f.get("telefono"), "email", f.get("email"), "activo", f.getOrDefault("activo", "N"), "id", id);
    }

    public List<Long> especialidadesDe(long id) {
        return db.lista(VE_05, "id", id).stream()
                .map(f -> ((Number) f.get("ID_ESPECIALIDAD")).longValue()).toList();
    }

    /** Borrar e insertar en UNA transaccion: si falla un INSERT, no se pierden las anteriores. */
    @Transactional
    public void guardarEspecialidades(long id, List<Long> especialidades) {
        db.ejecutar(VE_06, "id", id);
        for (Long e : especialidades) {
            db.ejecutar(VE_07, "id_veterinario", id, "id_especialidad", e);
        }
    }

    public List<Map<String, Object>> horarios(long id) { return db.lista(VE_08, "id", id); }

    public void agregarHorario(long id, int dia, String inicio, String fin) {
        db.ejecutar(VE_09, "id_veterinario", id, "dia_semana", dia, "hora_inicio", inicio, "hora_fin", fin);
    }

    public void eliminarHorario(long idHorario) { db.ejecutar(VE_10, "id_horario", idHorario); }

    public List<Map<String, Object>> activos() { return db.lista(VE_11); }
}
