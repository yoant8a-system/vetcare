package com.vet.modulos.mascota;

import com.vet.db.Db;
import com.vet.db.Sql;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

/** SQL de MASCOTA (usa la vista VW_MASCOTA_DETALLE del archivo 05_vistas.sql). */
@Repository
public class MascotaRepositorio {

    /**
     * [MA-01] Buscar mascotas por nombre de la mascota, nombre del propietario (contiene) o DNI (empieza con),
     * y opcionalmente por especie. Parametros NULL = sin filtro. Ordenar por nombre. Maximo 200 filas.
     * Columnas: ID_MASCOTA, NOMBRE, ESPECIE, RAZA, SEXO, EDAD, PROPIETARIO, TELEFONO, ESTADO
     * Parametros: :texto, :id_especie
     */
    private static final String MA_01 = Sql.pendiente("MA-01");

    /**
     * [MA-02] Una mascota con todos sus datos de la vista VW_MASCOTA_DETALLE.
     * Columnas: todas las de la vista (ID_MASCOTA, NOMBRE, SEXO, FECHA_NACIMIENTO, EDAD, COLOR, ESTERILIZADO,
     *           ESTADO, ID_RAZA, RAZA, ID_ESPECIE, ESPECIE, ID_PROPIETARIO, PROPIETARIO, DNI, TELEFONO,
     *           ID_PADRE, PADRE, ID_MADRE, MADRE, FECHA_REGISTRO)
     * Parametros: :id
     */
    private static final String MA_02 = Sql.pendiente("MA-02");

    /**
     * [MA-03] Mascotas de un propietario, ordenadas por nombre.
     * Columnas: ID_MASCOTA, NOMBRE, ESPECIE, RAZA, SEXO, EDAD, ESTADO
     * Parametros: :id_propietario
     */
    private static final String MA_03 = Sql.pendiente("MA-03");

    /**
     * [MA-04] Registrar mascota. (El trigger TRG_MASCOTA_PADRES valida a los padres.)
     * Parametros: :id_propietario, :id_raza, :nombre, :sexo, :fecha_nacimiento, :color, :esterilizado,
     *             :id_padre, :id_madre
     */
    private static final String MA_04 = Sql.pendiente("MA-04");

    /**
     * [MA-05] Actualizar mascota (incluye ESTADO: ACTIVO / FALLECIDO).
     * Parametros: :id_raza, :nombre, :sexo, :fecha_nacimiento, :color, :esterilizado, :id_padre, :id_madre,
     *             :estado, :id
     */
    private static final String MA_05 = Sql.pendiente("MA-05");

    /**
     * [MA-06] Eliminar mascota (falla con ORA-02292 si ya tiene citas o vacunas: es lo correcto).
     * Parametros: :id
     */
    private static final String MA_06 = Sql.pendiente("MA-06");

    /**
     * [MA-07] Posibles padres/madres: TODAS las mascotas excepto la que se esta editando (:id_mascota puede ser NULL).
     * La pagina luego filtra por especie y sexo.
     * Columnas: ID_MASCOTA, ETIQUETA (ej. "Max (Labrador Retriever, Perez Gonzales)"), SEXO, ID_ESPECIE
     * Parametros: :id_mascota
     */
    private static final String MA_07 = Sql.pendiente("MA-07");

    /**
     * [MA-08] Todas las razas con su especie, ordenadas por especie y raza (para el combo agrupado).
     * Columnas: ID_RAZA, NOMBRE, ID_ESPECIE, ESPECIE
     */
    private static final String MA_08 = Sql.pendiente("MA-08");

    /**
     * [MA-09] Especies ordenadas por nombre (para filtros).
     * Columnas: ID_ESPECIE, NOMBRE
     */
    private static final String MA_09 = Sql.pendiente("MA-09");

    private final Db db;

    public MascotaRepositorio(Db db) {
        this.db = db;
    }

    public List<Map<String, Object>> buscar(String texto, Long idEspecie) {
        return db.lista(MA_01, "texto", texto, "id_especie", idEspecie);
    }

    public Map<String, Object> obtener(long id) {
        return db.uno(MA_02, "id", id);
    }

    public List<Map<String, Object>> dePropietario(long idPropietario) {
        return db.lista(MA_03, "id_propietario", idPropietario);
    }

    public long insertar(long idPropietario, Map<String, String> f) {
        return db.insertar(MA_04, "ID_MASCOTA",
                "id_propietario", idPropietario, "id_raza", f.get("id_raza"), "nombre", f.get("nombre"),
                "sexo", f.get("sexo"), "fecha_nacimiento", fecha(f.get("fecha_nacimiento")), "color", f.get("color"),
                "esterilizado", f.getOrDefault("esterilizado", "N"), "id_padre", f.get("id_padre"),
                "id_madre", f.get("id_madre"));
    }

    public void actualizar(long id, Map<String, String> f) {
        db.ejecutar(MA_05,
                "id_raza", f.get("id_raza"), "nombre", f.get("nombre"), "sexo", f.get("sexo"),
                "fecha_nacimiento", fecha(f.get("fecha_nacimiento")), "color", f.get("color"),
                "esterilizado", f.getOrDefault("esterilizado", "N"), "id_padre", f.get("id_padre"),
                "id_madre", f.get("id_madre"), "estado", f.getOrDefault("estado", "ACTIVO"), "id", id);
    }

    public void eliminar(long id) {
        db.ejecutar(MA_06, "id", id);
    }

    public List<Map<String, Object>> candidatosPadres(Long idMascota) {
        return db.lista(MA_07, "id_mascota", idMascota);
    }

    public List<Map<String, Object>> razas() {
        return db.lista(MA_08);
    }

    public List<Map<String, Object>> especies() {
        return db.lista(MA_09);
    }

    private static java.time.LocalDate fecha(String s) {
        return s == null || s.isBlank() ? null : java.time.LocalDate.parse(s);
    }
}
