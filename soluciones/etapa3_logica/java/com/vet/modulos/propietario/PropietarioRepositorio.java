package com.vet.modulos.propietario;

import com.vet.db.Db;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

/** SQL de la tabla PROPIETARIO. */
@Repository
public class PropietarioRepositorio {

    /**
     * [PR-01] Buscar propietarios por DNI (empieza con), nombres o apellidos (contiene, sin importar mayusculas).
     * Si :texto es NULL, devuelve todos. Ordenar por apellidos y nombres. Maximo 200 filas.
     * Columnas: ID_PROPIETARIO, DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL,
     *           MASCOTAS (cantidad de mascotas del propietario: subconsulta con COUNT)
     * Parametros: :texto
     */
    private static final String PR_01 = """
            SELECT p.ID_PROPIETARIO, p.DNI, p.NOMBRES, p.APELLIDOS, p.TELEFONO, p.EMAIL,
                   (SELECT COUNT(*) FROM MASCOTA m WHERE m.ID_PROPIETARIO = p.ID_PROPIETARIO) AS MASCOTAS
              FROM PROPIETARIO p
             WHERE :texto IS NULL
                OR p.DNI LIKE :texto || '%'
                OR UPPER(p.APELLIDOS) LIKE '%' || UPPER(:texto) || '%'
                OR UPPER(p.NOMBRES) LIKE '%' || UPPER(:texto) || '%'
             ORDER BY p.APELLIDOS, p.NOMBRES
             FETCH FIRST 200 ROWS ONLY
            """;

    /**
     * [PR-02] Un propietario por su ID.
     * Columnas: ID_PROPIETARIO, DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL, DIRECCION, FECHA_REGISTRO
     * Parametros: :id
     */
    private static final String PR_02 = """
            SELECT ID_PROPIETARIO, DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL, DIRECCION, FECHA_REGISTRO
              FROM PROPIETARIO
             WHERE ID_PROPIETARIO = :id
            """;

    /**
     * [PR-03] Registrar propietario (el ID es IDENTITY y FECHA_REGISTRO tiene DEFAULT: no se envian).
     * Parametros: :dni, :nombres, :apellidos, :telefono, :email, :direccion
     */
    private static final String PR_03 = """
            INSERT INTO PROPIETARIO (DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL, DIRECCION)
            VALUES (:dni, :nombres, :apellidos, :telefono, :email, :direccion)
            """;

    /**
     * [PR-04] Actualizar propietario.
     * Parametros: :dni, :nombres, :apellidos, :telefono, :email, :direccion, :id
     */
    private static final String PR_04 = """
            UPDATE PROPIETARIO
               SET DNI = :dni, NOMBRES = :nombres, APELLIDOS = :apellidos,
                   TELEFONO = :telefono, EMAIL = :email, DIRECCION = :direccion
             WHERE ID_PROPIETARIO = :id
            """;

    /**
     * [PR-05] Eliminar propietario. Si tiene mascotas, Oracle lo impide (FK -> ORA-02292).
     * Parametros: :id
     */
    private static final String PR_05 = """
            DELETE FROM PROPIETARIO WHERE ID_PROPIETARIO = :id
            """;

    private final Db db;

    public PropietarioRepositorio(Db db) {
        this.db = db;
    }

    public List<Map<String, Object>> buscar(String texto) {
        return db.lista(PR_01, "texto", texto);
    }

    public Map<String, Object> obtener(long id) {
        return db.uno(PR_02, "id", id);
    }

    public long insertar(Map<String, String> f) {
        return db.insertar(PR_03, "ID_PROPIETARIO",
                "dni", f.get("dni"), "nombres", f.get("nombres"), "apellidos", f.get("apellidos"),
                "telefono", f.get("telefono"), "email", f.get("email"), "direccion", f.get("direccion"));
    }

    public void actualizar(long id, Map<String, String> f) {
        db.ejecutar(PR_04,
                "dni", f.get("dni"), "nombres", f.get("nombres"), "apellidos", f.get("apellidos"),
                "telefono", f.get("telefono"), "email", f.get("email"), "direccion", f.get("direccion"),
                "id", id);
    }

    public void eliminar(long id) {
        db.ejecutar(PR_05, "id", id);
    }
}
