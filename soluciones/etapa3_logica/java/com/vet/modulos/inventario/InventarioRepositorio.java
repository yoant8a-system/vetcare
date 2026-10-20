package com.vet.modulos.inventario;

import com.vet.db.Db;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/** Insumos y kardex. El STOCK_ACTUAL nunca se edita directo: lo cambia el trigger TRG_MOVIMIENTO_STOCK. */
@Repository
public class InventarioRepositorio {

    /**
     * [IN-01] Medicamentos ordenados por nombre y presentacion, con una marca de stock bajo.
     * Columnas: ID_MEDICAMENTO, NOMBRE, PRESENTACION, UNIDAD, STOCK_ACTUAL, STOCK_MINIMO, ACTIVO,
     *           BAJO ('S' si STOCK_ACTUAL <= STOCK_MINIMO, si no 'N')
     */
    private static final String IN_01 = """
            SELECT ID_MEDICAMENTO, NOMBRE, PRESENTACION, UNIDAD, STOCK_ACTUAL, STOCK_MINIMO, ACTIVO,
                   CASE WHEN STOCK_ACTUAL <= STOCK_MINIMO THEN 'S' ELSE 'N' END AS BAJO
              FROM MEDICAMENTO
             ORDER BY NOMBRE, PRESENTACION
            """;

    /**
     * [IN-02] Un medicamento.
     * Columnas: ID_MEDICAMENTO, NOMBRE, PRESENTACION, UNIDAD, STOCK_ACTUAL, STOCK_MINIMO, ACTIVO
     * Parametros: :id
     */
    private static final String IN_02 = """
            SELECT ID_MEDICAMENTO, NOMBRE, PRESENTACION, UNIDAD, STOCK_ACTUAL, STOCK_MINIMO, ACTIVO
              FROM MEDICAMENTO WHERE ID_MEDICAMENTO = :id
            """;

    /** [IN-03] Registrar medicamento (sin stock: el stock entra con un movimiento).  Parametros: :nombre, :presentacion, :unidad, :stock_minimo */
    private static final String IN_03 = """
            INSERT INTO MEDICAMENTO (NOMBRE, PRESENTACION, UNIDAD, STOCK_MINIMO)
            VALUES (:nombre, :presentacion, :unidad, :stock_minimo)
            """;

    /** [IN-04] Actualizar datos del medicamento (NO el stock).  Parametros: :nombre, :presentacion, :unidad, :stock_minimo, :activo, :id */
    private static final String IN_04 = """
            UPDATE MEDICAMENTO
               SET NOMBRE = :nombre, PRESENTACION = :presentacion, UNIDAD = :unidad,
                   STOCK_MINIMO = :stock_minimo, ACTIVO = :activo
             WHERE ID_MEDICAMENTO = :id
            """;

    /** [IN-05] Registrar movimiento manual (ENTRADA por compra o SALIDA por merma).  Parametros: :id_medicamento, :tipo, :cantidad, :motivo */
    private static final String IN_05 = """
            INSERT INTO MOVIMIENTO_STOCK (ID_MEDICAMENTO, TIPO, CANTIDAD, MOTIVO)
            VALUES (:id_medicamento, :tipo, :cantidad, :motivo)
            """;

    /**
     * [IN-06] Ultimos 50 movimientos de todos los medicamentos (el mas reciente primero).
     * DETALLE: 'Atencion #<id>' si vino de una atencion, si no el MOTIVO (pista: NVL2).
     * Columnas: FECHA, ID_MEDICAMENTO, MEDICAMENTO, UNIDAD, TIPO, CANTIDAD, DETALLE
     */
    private static final String IN_06 = """
            SELECT ms.FECHA, md.ID_MEDICAMENTO, md.NOMBRE AS MEDICAMENTO, md.UNIDAD, ms.TIPO, ms.CANTIDAD,
                   NVL2(ms.ID_ATENCION, 'Atencion #' || ms.ID_ATENCION, ms.MOTIVO) AS DETALLE
              FROM MOVIMIENTO_STOCK ms
              JOIN MEDICAMENTO md ON md.ID_MEDICAMENTO = ms.ID_MEDICAMENTO
             ORDER BY ms.FECHA DESC, ms.ID_MOVIMIENTO DESC
             FETCH FIRST 50 ROWS ONLY
            """;

    private final Db db;

    public InventarioRepositorio(Db db) {
        this.db = db;
    }

    public List<Map<String, Object>> listar() { return db.lista(IN_01); }

    public Map<String, Object> obtener(long id) { return db.uno(IN_02, "id", id); }

    public long insertar(Map<String, String> f) {
        return db.insertar(IN_03, "ID_MEDICAMENTO", "nombre", f.get("nombre"), "presentacion", f.get("presentacion"),
                "unidad", f.get("unidad"), "stock_minimo", f.get("stock_minimo"));
    }

    public void actualizar(long id, Map<String, String> f) {
        db.ejecutar(IN_04, "nombre", f.get("nombre"), "presentacion", f.get("presentacion"), "unidad", f.get("unidad"),
                "stock_minimo", f.get("stock_minimo"), "activo", f.getOrDefault("activo", "N"), "id", id);
    }

    public void movimiento(long idMedicamento, String tipo, BigDecimal cantidad, String motivo) {
        db.ejecutar(IN_05, "id_medicamento", idMedicamento, "tipo", tipo, "cantidad", cantidad, "motivo", motivo);
    }

    public List<Map<String, Object>> ultimosMovimientos() { return db.lista(IN_06); }
}
