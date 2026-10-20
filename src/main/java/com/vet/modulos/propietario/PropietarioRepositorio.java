package com.vet.modulos.propietario;

import com.vet.db.Db;
import com.vet.db.Sql;
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
    private static final String PR_01 = Sql.pendiente("PR-01");

    /**
     * [PR-02] Un propietario por su ID.
     * Columnas: ID_PROPIETARIO, DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL, DIRECCION, FECHA_REGISTRO
     * Parametros: :id
     */
    private static final String PR_02 = Sql.pendiente("PR-02");

    /**
     * [PR-03] Registrar propietario (el ID es IDENTITY y FECHA_REGISTRO tiene DEFAULT: no se envian).
     * Parametros: :dni, :nombres, :apellidos, :telefono, :email, :direccion
     */
    private static final String PR_03 = Sql.pendiente("PR-03");

    /**
     * [PR-04] Actualizar propietario.
     * Parametros: :dni, :nombres, :apellidos, :telefono, :email, :direccion, :id
     */
    private static final String PR_04 = Sql.pendiente("PR-04");

    /**
     * [PR-05] Eliminar propietario. Si tiene mascotas, Oracle lo impide (FK -> ORA-02292).
     * Parametros: :id
     */
    private static final String PR_05 = Sql.pendiente("PR-05");

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
