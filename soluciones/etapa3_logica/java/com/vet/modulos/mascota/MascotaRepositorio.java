package com.vet.modulos.mascota;

import com.vet.db.Db;
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
    private static final String MA_01 = """
            SELECT ID_MASCOTA, NOMBRE, ESPECIE, RAZA, SEXO, EDAD, PROPIETARIO, TELEFONO, ESTADO
              FROM VW_MASCOTA_DETALLE
             WHERE (:texto IS NULL
                    OR UPPER(NOMBRE) LIKE '%' || UPPER(:texto) || '%'
                    OR UPPER(PROPIETARIO) LIKE '%' || UPPER(:texto) || '%'
                    OR DNI LIKE :texto || '%')
               AND (:id_especie IS NULL OR ID_ESPECIE = :id_especie)
             ORDER BY NOMBRE
             FETCH FIRST 200 ROWS ONLY
            """;

    /**
     * [MA-02] Una mascota con todos sus datos de la vista VW_MASCOTA_DETALLE.
     * Columnas: todas las de la vista (ID_MASCOTA, NOMBRE, SEXO, FECHA_NACIMIENTO, EDAD, COLOR, ESTERILIZADO,
     *           ESTADO, ID_RAZA, RAZA, ID_ESPECIE, ESPECIE, ID_PROPIETARIO, PROPIETARIO, DNI, TELEFONO,
     *           ID_PADRE, PADRE, ID_MADRE, MADRE, FECHA_REGISTRO)
     * Parametros: :id
     */
    private static final String MA_02 = """
            SELECT * FROM VW_MASCOTA_DETALLE WHERE ID_MASCOTA = :id
            """;

    /**
     * [MA-03] Mascotas de un propietario, ordenadas por nombre.
     * Columnas: ID_MASCOTA, NOMBRE, ESPECIE, RAZA, SEXO, EDAD, ESTADO
     * Parametros: :id_propietario
     */
    private static final String MA_03 = """
            SELECT ID_MASCOTA, NOMBRE, ESPECIE, RAZA, SEXO, EDAD, ESTADO
              FROM VW_MASCOTA_DETALLE
             WHERE ID_PROPIETARIO = :id_propietario
             ORDER BY NOMBRE
            """;

    /**
     * [MA-04] Registrar mascota. (El trigger TRG_MASCOTA_PADRES valida a los padres.)
     * Parametros: :id_propietario, :id_raza, :nombre, :sexo, :fecha_nacimiento, :color, :esterilizado,
     *             :id_padre, :id_madre
     */
    private static final String MA_04 = """
            INSERT INTO MASCOTA (ID_PROPIETARIO, ID_RAZA, NOMBRE, SEXO, FECHA_NACIMIENTO, COLOR,
                                 ESTERILIZADO, ID_PADRE, ID_MADRE)
            VALUES (:id_propietario, :id_raza, :nombre, :sexo, :fecha_nacimiento, :color,
                    :esterilizado, :id_padre, :id_madre)
            """;

    /**
     * [MA-05] Actualizar mascota (incluye ESTADO: ACTIVO / FALLECIDO).
     * Parametros: :id_raza, :nombre, :sexo, :fecha_nacimiento, :color, :esterilizado, :id_padre, :id_madre,
     *             :estado, :id
     */
    private static final String MA_05 = """
            UPDATE MASCOTA
               SET ID_RAZA = :id_raza, NOMBRE = :nombre, SEXO = :sexo, FECHA_NACIMIENTO = :fecha_nacimiento,
                   COLOR = :color, ESTERILIZADO = :esterilizado, ID_PADRE = :id_padre, ID_MADRE = :id_madre,
                   ESTADO = :estado
             WHERE ID_MASCOTA = :id
            """;

    /**
     * [MA-06] Eliminar mascota (falla con ORA-02292 si ya tiene citas o vacunas: es lo correcto).
     * Parametros: :id
     */
    private static final String MA_06 = """
            DELETE FROM MASCOTA WHERE ID_MASCOTA = :id
            """;

    /**
     * [MA-07] Posibles padres/madres: TODAS las mascotas excepto la que se esta editando (:id_mascota puede ser NULL).
     * La pagina luego filtra por especie y sexo.
     * Columnas: ID_MASCOTA, ETIQUETA (ej. "Max (Labrador Retriever, Perez Gonzales)"), SEXO, ID_ESPECIE
     * Parametros: :id_mascota
     */
    private static final String MA_07 = """
            SELECT m.ID_MASCOTA,
                   m.NOMBRE || ' (' || r.NOMBRE || ', ' || p.APELLIDOS || ')' AS ETIQUETA,
                   m.SEXO, r.ID_ESPECIE
              FROM MASCOTA m
              JOIN RAZA r        ON r.ID_RAZA = m.ID_RAZA
              JOIN PROPIETARIO p ON p.ID_PROPIETARIO = m.ID_PROPIETARIO
             WHERE :id_mascota IS NULL OR m.ID_MASCOTA <> :id_mascota
             ORDER BY m.NOMBRE
            """;

    /**
     * [MA-08] Todas las razas con su especie, ordenadas por especie y raza (para el combo agrupado).
     * Columnas: ID_RAZA, NOMBRE, ID_ESPECIE, ESPECIE
     */
    private static final String MA_08 = """
            SELECT r.ID_RAZA, r.NOMBRE, e.ID_ESPECIE, e.NOMBRE AS ESPECIE
              FROM RAZA r
              JOIN ESPECIE e ON e.ID_ESPECIE = r.ID_ESPECIE
             ORDER BY e.NOMBRE, r.NOMBRE
            """;

    /**
     * [MA-09] Especies ordenadas por nombre (para filtros).
     * Columnas: ID_ESPECIE, NOMBRE
     */
    private static final String MA_09 = """
            SELECT ID_ESPECIE, NOMBRE FROM ESPECIE ORDER BY NOMBRE
            """;

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
