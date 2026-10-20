package com.vet.modulos.inventario;

import com.vet.db.Db;
import com.vet.db.Sql;
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
    private static final String IN_01 = Sql.pendiente("IN-01");

    /**
     * [IN-02] Un medicamento.
     * Columnas: ID_MEDICAMENTO, NOMBRE, PRESENTACION, UNIDAD, STOCK_ACTUAL, STOCK_MINIMO, ACTIVO
     * Parametros: :id
     */
    private static final String IN_02 = Sql.pendiente("IN-02");

    /** [IN-03] Registrar medicamento (sin stock: el stock entra con un movimiento).  Parametros: :nombre, :presentacion, :unidad, :stock_minimo */
    private static final String IN_03 = Sql.pendiente("IN-03");

    /** [IN-04] Actualizar datos del medicamento (NO el stock).  Parametros: :nombre, :presentacion, :unidad, :stock_minimo, :activo, :id */
    private static final String IN_04 = Sql.pendiente("IN-04");

    /** [IN-05] Registrar movimiento manual (ENTRADA por compra o SALIDA por merma).  Parametros: :id_medicamento, :tipo, :cantidad, :motivo */
    private static final String IN_05 = Sql.pendiente("IN-05");

    /**
     * [IN-06] Ultimos 50 movimientos de todos los medicamentos (el mas reciente primero).
     * DETALLE: 'Atencion #<id>' si vino de una atencion, si no el MOTIVO (pista: NVL2).
     * Columnas: FECHA, ID_MEDICAMENTO, MEDICAMENTO, UNIDAD, TIPO, CANTIDAD, DETALLE
     */
    private static final String IN_06 = Sql.pendiente("IN-06");

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
