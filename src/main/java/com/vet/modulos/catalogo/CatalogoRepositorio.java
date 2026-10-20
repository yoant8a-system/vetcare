package com.vet.modulos.catalogo;

import com.vet.db.Db;
import com.vet.db.Sql;
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
    private static final String CA_01 = Sql.pendiente("CA-01");

    /** [CA-02] Registrar especie.  Parametros: :nombre */
    private static final String CA_02 = Sql.pendiente("CA-02");

    /** [CA-03] Eliminar especie.  Parametros: :id */
    private static final String CA_03 = Sql.pendiente("CA-03");

    // ============================================================== RAZA

    /**
     * [CA-04] Razas con su especie y la cantidad de mascotas de esa raza. Ordenar por especie y raza.
     * Columnas: ID_RAZA, NOMBRE, ESPECIE, MASCOTAS
     */
    private static final String CA_04 = Sql.pendiente("CA-04");

    /** [CA-05] Registrar raza.  Parametros: :id_especie, :nombre */
    private static final String CA_05 = Sql.pendiente("CA-05");

    /** [CA-06] Eliminar raza.  Parametros: :id */
    private static final String CA_06 = Sql.pendiente("CA-06");

    // ============================================================== ESPECIALIDAD

    /**
     * [CA-07] Especialidades con la cantidad de veterinarios que la tienen.
     * Columnas: ID_ESPECIALIDAD, NOMBRE, VETERINARIOS
     */
    private static final String CA_07 = Sql.pendiente("CA-07");

    /** [CA-08] Registrar especialidad.  Parametros: :nombre */
    private static final String CA_08 = Sql.pendiente("CA-08");

    /** [CA-09] Eliminar especialidad.  Parametros: :id */
    private static final String CA_09 = Sql.pendiente("CA-09");

    // ============================================================== CONSULTORIO

    /**
     * [CA-10] Consultorios ordenados por nombre.
     * Columnas: ID_CONSULTORIO, NOMBRE, ACTIVO
     */
    private static final String CA_10 = Sql.pendiente("CA-10");

    /** [CA-11] Registrar consultorio.  Parametros: :nombre */
    private static final String CA_11 = Sql.pendiente("CA-11");

    /** [CA-12] Activar/desactivar: si ACTIVO es 'S' pasa a 'N' y viceversa (un solo UPDATE con CASE).  Parametros: :id */
    private static final String CA_12 = Sql.pendiente("CA-12");

    // ============================================================== DIAGNOSTICO

    /**
     * [CA-13] Catalogo de diagnosticos con el nombre de la especie ('Todas' si ID_ESPECIE es NULL). Ordenar por codigo.
     * Columnas: ID_DIAGNOSTICO, CODIGO, NOMBRE, CATEGORIA, ESPECIE
     */
    private static final String CA_13 = Sql.pendiente("CA-13");

    /** [CA-14] Registrar diagnostico.  Parametros: :codigo, :nombre, :categoria, :id_especie (puede ser NULL) */
    private static final String CA_14 = Sql.pendiente("CA-14");

    /** [CA-15] Eliminar diagnostico.  Parametros: :id */
    private static final String CA_15 = Sql.pendiente("CA-15");

    // ============================================================== VACUNA

    /**
     * [CA-16] Vacunas con su especie. Ordenar por especie y nombre.
     * Columnas: ID_VACUNA, NOMBRE, ESPECIE, REFUERZO_DIAS
     */
    private static final String CA_16 = Sql.pendiente("CA-16");

    /** [CA-17] Registrar vacuna.  Parametros: :nombre, :id_especie, :refuerzo_dias (NULL = dosis unica) */
    private static final String CA_17 = Sql.pendiente("CA-17");

    /** [CA-18] Eliminar vacuna.  Parametros: :id */
    private static final String CA_18 = Sql.pendiente("CA-18");

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
