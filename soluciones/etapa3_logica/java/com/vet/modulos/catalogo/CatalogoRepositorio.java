package com.vet.modulos.catalogo;

import com.vet.db.Db;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

/** SQL de las tablas de catalogo: ESPECIE, RAZA, ESPECIALIDAD, CONSULTORIO, DIAGNOSTICO, VACUNA. */
@Repository
public class CatalogoRepositorio {

    // ============================================================== ESPECIE

    /**
     * [CA-01] Especies con la cantidad de razas de cada una, ordenadas por nombre.
     * Columnas: ID_ESPECIE, NOMBRE, RAZAS
     */
    private static final String CA_01 = """
            SELECT e.ID_ESPECIE, e.NOMBRE,
                   (SELECT COUNT(*) FROM RAZA r WHERE r.ID_ESPECIE = e.ID_ESPECIE) AS RAZAS
              FROM ESPECIE e
             ORDER BY e.NOMBRE
            """;

    /** [CA-02] Registrar especie.  Parametros: :nombre */
    private static final String CA_02 = """
            INSERT INTO ESPECIE (NOMBRE) VALUES (:nombre)
            """;

    /** [CA-03] Eliminar especie.  Parametros: :id */
    private static final String CA_03 = """
            DELETE FROM ESPECIE WHERE ID_ESPECIE = :id
            """;

    // ============================================================== RAZA

    /**
     * [CA-04] Razas con su especie y la cantidad de mascotas de esa raza. Ordenar por especie y raza.
     * Columnas: ID_RAZA, NOMBRE, ESPECIE, MASCOTAS
     */
    private static final String CA_04 = """
            SELECT r.ID_RAZA, r.NOMBRE, e.NOMBRE AS ESPECIE,
                   (SELECT COUNT(*) FROM MASCOTA m WHERE m.ID_RAZA = r.ID_RAZA) AS MASCOTAS
              FROM RAZA r
              JOIN ESPECIE e ON e.ID_ESPECIE = r.ID_ESPECIE
             ORDER BY e.NOMBRE, r.NOMBRE
            """;

    /** [CA-05] Registrar raza.  Parametros: :id_especie, :nombre */
    private static final String CA_05 = """
            INSERT INTO RAZA (ID_ESPECIE, NOMBRE) VALUES (:id_especie, :nombre)
            """;

    /** [CA-06] Eliminar raza.  Parametros: :id */
    private static final String CA_06 = """
            DELETE FROM RAZA WHERE ID_RAZA = :id
            """;

    // ============================================================== ESPECIALIDAD

    /**
     * [CA-07] Especialidades con la cantidad de veterinarios que la tienen.
     * Columnas: ID_ESPECIALIDAD, NOMBRE, VETERINARIOS
     */
    private static final String CA_07 = """
            SELECT e.ID_ESPECIALIDAD, e.NOMBRE,
                   (SELECT COUNT(*) FROM VETERINARIO_ESPECIALIDAD ve WHERE ve.ID_ESPECIALIDAD = e.ID_ESPECIALIDAD) AS VETERINARIOS
              FROM ESPECIALIDAD e
             ORDER BY e.NOMBRE
            """;

    /** [CA-08] Registrar especialidad.  Parametros: :nombre */
    private static final String CA_08 = """
            INSERT INTO ESPECIALIDAD (NOMBRE) VALUES (:nombre)
            """;

    /** [CA-09] Eliminar especialidad.  Parametros: :id */
    private static final String CA_09 = """
            DELETE FROM ESPECIALIDAD WHERE ID_ESPECIALIDAD = :id
            """;

    // ============================================================== CONSULTORIO

    /**
     * [CA-10] Consultorios ordenados por nombre.
     * Columnas: ID_CONSULTORIO, NOMBRE, ACTIVO
     */
    private static final String CA_10 = """
            SELECT ID_CONSULTORIO, NOMBRE, ACTIVO FROM CONSULTORIO ORDER BY NOMBRE
            """;

    /** [CA-11] Registrar consultorio.  Parametros: :nombre */
    private static final String CA_11 = """
            INSERT INTO CONSULTORIO (NOMBRE) VALUES (:nombre)
            """;

    /** [CA-12] Activar/desactivar: si ACTIVO es 'S' pasa a 'N' y viceversa (un solo UPDATE con CASE).  Parametros: :id */
    private static final String CA_12 = """
            UPDATE CONSULTORIO
               SET ACTIVO = CASE ACTIVO WHEN 'S' THEN 'N' ELSE 'S' END
             WHERE ID_CONSULTORIO = :id
            """;

    // ============================================================== DIAGNOSTICO

    /**
     * [CA-13] Catalogo de diagnosticos con el nombre de la especie ('Todas' si ID_ESPECIE es NULL). Ordenar por codigo.
     * Columnas: ID_DIAGNOSTICO, CODIGO, NOMBRE, CATEGORIA, ESPECIE
     */
    private static final String CA_13 = """
            SELECT d.ID_DIAGNOSTICO, d.CODIGO, d.NOMBRE, d.CATEGORIA, NVL(e.NOMBRE, 'Todas') AS ESPECIE
              FROM DIAGNOSTICO d
              LEFT JOIN ESPECIE e ON e.ID_ESPECIE = d.ID_ESPECIE
             ORDER BY d.CODIGO
            """;

    /** [CA-14] Registrar diagnostico.  Parametros: :codigo, :nombre, :categoria, :id_especie (puede ser NULL) */
    private static final String CA_14 = """
            INSERT INTO DIAGNOSTICO (CODIGO, NOMBRE, CATEGORIA, ID_ESPECIE)
            VALUES (:codigo, :nombre, :categoria, :id_especie)
            """;

    /** [CA-15] Eliminar diagnostico.  Parametros: :id */
    private static final String CA_15 = """
            DELETE FROM DIAGNOSTICO WHERE ID_DIAGNOSTICO = :id
            """;

    // ============================================================== VACUNA

    /**
     * [CA-16] Vacunas con su especie. Ordenar por especie y nombre.
     * Columnas: ID_VACUNA, NOMBRE, ESPECIE, REFUERZO_DIAS
     */
    private static final String CA_16 = """
            SELECT v.ID_VACUNA, v.NOMBRE, e.NOMBRE AS ESPECIE, v.REFUERZO_DIAS
              FROM VACUNA v
              JOIN ESPECIE e ON e.ID_ESPECIE = v.ID_ESPECIE
             ORDER BY e.NOMBRE, v.NOMBRE
            """;

    /** [CA-17] Registrar vacuna.  Parametros: :nombre, :id_especie, :refuerzo_dias (NULL = dosis unica) */
    private static final String CA_17 = """
            INSERT INTO VACUNA (NOMBRE, ID_ESPECIE, REFUERZO_DIAS) VALUES (:nombre, :id_especie, :refuerzo_dias)
            """;

    /** [CA-18] Eliminar vacuna.  Parametros: :id */
    private static final String CA_18 = """
            DELETE FROM VACUNA WHERE ID_VACUNA = :id
            """;

    private final Db db;

    public CatalogoRepositorio(Db db) {
        this.db = db;
    }

    public List<Map<String, Object>> especies() { return db.lista(CA_01); }
    public void insertarEspecie(String nombre) { db.ejecutar(CA_02, "nombre", nombre); }
    public void eliminarEspecie(long id) { db.ejecutar(CA_03, "id", id); }

    public List<Map<String, Object>> razas() { return db.lista(CA_04); }
    public void insertarRaza(long idEspecie, String nombre) { db.ejecutar(CA_05, "id_especie", idEspecie, "nombre", nombre); }
    public void eliminarRaza(long id) { db.ejecutar(CA_06, "id", id); }

    public List<Map<String, Object>> especialidades() { return db.lista(CA_07); }
    public void insertarEspecialidad(String nombre) { db.ejecutar(CA_08, "nombre", nombre); }
    public void eliminarEspecialidad(long id) { db.ejecutar(CA_09, "id", id); }

    public List<Map<String, Object>> consultorios() { return db.lista(CA_10); }
    public void insertarConsultorio(String nombre) { db.ejecutar(CA_11, "nombre", nombre); }
    public void alternarConsultorio(long id) { db.ejecutar(CA_12, "id", id); }

    public List<Map<String, Object>> diagnosticos() { return db.lista(CA_13); }
    public void insertarDiagnostico(String codigo, String nombre, String categoria, Long idEspecie) {
        db.ejecutar(CA_14, "codigo", codigo, "nombre", nombre, "categoria", categoria, "id_especie", idEspecie);
    }
    public void eliminarDiagnostico(long id) { db.ejecutar(CA_15, "id", id); }

    public List<Map<String, Object>> vacunas() { return db.lista(CA_16); }
    public void insertarVacuna(String nombre, long idEspecie, Integer refuerzoDias) {
        db.ejecutar(CA_17, "nombre", nombre, "id_especie", idEspecie, "refuerzo_dias", refuerzoDias);
    }
    public void eliminarVacuna(long id) { db.ejecutar(CA_18, "id", id); }
}
