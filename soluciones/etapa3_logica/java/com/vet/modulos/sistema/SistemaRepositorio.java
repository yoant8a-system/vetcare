package com.vet.modulos.sistema;

import com.vet.db.Db;
import com.vet.db.Plsql;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

import static com.vet.db.Plsql.in;
import static com.vet.db.Plsql.outNumero;
import static com.vet.db.Plsql.outTexto;

/** Usuarios de la app, alertas, auditoria y tablero (dashboard). */
@Repository
public class SistemaRepositorio {

    // ============================================================== USUARIOS

    /**
     * [US-01] Usuarios de la aplicacion con el nombre del veterinario vinculado (si tiene). Ordenar por usuario.
     * Columnas: ID_USUARIO, USUARIO, NOMBRE_COMPLETO, ROL, ACTIVO, ULTIMO_ACCESO, ID_VETERINARIO, VETERINARIO
     */
    private static final String US_01 = """
            SELECT u.ID_USUARIO, u.USUARIO, u.NOMBRE_COMPLETO, u.ROL, u.ACTIVO, u.ULTIMO_ACCESO, u.ID_VETERINARIO,
                   v.NOMBRES || ' ' || v.APELLIDOS AS VETERINARIO
              FROM USUARIO u
              LEFT JOIN VETERINARIO v ON v.ID_VETERINARIO = u.ID_VETERINARIO
             ORDER BY u.USUARIO
            """;

    /**
     * [US-02] Un usuario (SIN la clave).
     * Columnas: ID_USUARIO, USUARIO, NOMBRE_COMPLETO, ROL, ACTIVO, ID_VETERINARIO
     * Parametros: :id
     */
    private static final String US_02 = """
            SELECT ID_USUARIO, USUARIO, NOMBRE_COMPLETO, ROL, ACTIVO, ID_VETERINARIO FROM USUARIO WHERE ID_USUARIO = :id
            """;

    /** [US-03] Actualizar datos del usuario (la clave se cambia con PKG_SEGURIDAD).  Parametros: :nombre, :rol, :id_veterinario, :activo, :id */
    private static final String US_03 = """
            UPDATE USUARIO
               SET NOMBRE_COMPLETO = :nombre, ROL = :rol, ID_VETERINARIO = :id_veterinario, ACTIVO = :activo
             WHERE ID_USUARIO = :id
            """;

    // ============================================================== ALERTAS

    /**
     * [AL-01] Ultimas 100 alertas: primero las NO leidas, luego por fecha (mas reciente primero).
     * Columnas: ID_ALERTA, TIPO, ID_REFERENCIA, MENSAJE, FECHA, LEIDA
     */
    private static final String AL_01 = """
            SELECT ID_ALERTA, TIPO, ID_REFERENCIA, MENSAJE, FECHA, LEIDA
              FROM ALERTA
             ORDER BY LEIDA, FECHA DESC, ID_ALERTA DESC
             FETCH FIRST 100 ROWS ONLY
            """;

    /** [AL-02] Marcar una alerta como leida.  Parametros: :id */
    private static final String AL_02 = """
            UPDATE ALERTA SET LEIDA = 'S' WHERE ID_ALERTA = :id
            """;

    /** [AL-03] Marcar TODAS las alertas como leidas. */
    private static final String AL_03 = """
            UPDATE ALERTA SET LEIDA = 'S' WHERE LEIDA = 'N'
            """;

    /** [AL-04] Cantidad de alertas sin leer (un numero; se muestra en la campanita). */
    private static final String AL_04 = """
            SELECT COUNT(*) FROM ALERTA WHERE LEIDA = 'N'
            """;

    // ============================================================== AUDITORIA

    /**
     * [AU-01] Ultimos 200 registros de auditoria, opcionalmente de una tabla (:tabla NULL = todas).
     * Columnas: ID_AUDITORIA, FECHA, TABLA, OPERACION, ID_REGISTRO, DETALLE, USUARIO_APP, USUARIO_BD
     * Parametros: :tabla
     */
    private static final String AU_01 = """
            SELECT ID_AUDITORIA, FECHA, TABLA, OPERACION, ID_REGISTRO, DETALLE, USUARIO_APP, USUARIO_BD
              FROM AUDITORIA
             WHERE :tabla IS NULL OR TABLA = :tabla
             ORDER BY ID_AUDITORIA DESC
             FETCH FIRST 200 ROWS ONLY
            """;

    // ============================================================== DASHBOARD

    /**
     * [DA-01] Indicadores del tablero en UNA fila (pista: varias subconsultas escalares FROM DUAL).
     * Columnas: CITAS_HOY (de hoy, sin contar CANCELADAS), EN_ESPERA, EN_ATENCION,
     *           ATENCIONES_MES (desde el dia 1 del mes actual), MASCOTAS (ACTIVAS),
     *           TRATAMIENTOS (EN_CURSO), STOCK_BAJO (medicamentos activos con stock <= minimo)
     */
    private static final String DA_01 = """
            SELECT (SELECT COUNT(*) FROM CITA
                     WHERE FECHA_HORA >= TRUNC(SYSDATE) AND FECHA_HORA < TRUNC(SYSDATE) + 1
                       AND ESTADO <> 'CANCELADA') AS CITAS_HOY,
                   (SELECT COUNT(*) FROM CITA WHERE ESTADO = 'EN_ESPERA') AS EN_ESPERA,
                   (SELECT COUNT(*) FROM CITA WHERE ESTADO = 'EN_ATENCION') AS EN_ATENCION,
                   (SELECT COUNT(*) FROM ATENCION WHERE FECHA_INICIO >= TRUNC(SYSDATE, 'MM')) AS ATENCIONES_MES,
                   (SELECT COUNT(*) FROM MASCOTA WHERE ESTADO = 'ACTIVO') AS MASCOTAS,
                   (SELECT COUNT(*) FROM TRATAMIENTO WHERE ESTADO = 'EN_CURSO') AS TRATAMIENTOS,
                   (SELECT COUNT(*) FROM MEDICAMENTO WHERE ACTIVO = 'S' AND STOCK_ACTUAL <= STOCK_MINIMO) AS STOCK_BAJO
              FROM DUAL
            """;

    /**
     * [DA-02] Atenciones por dia de los ultimos 14 dias, INCLUYENDO los dias con 0
     * (pista: generar los 14 dias con CONNECT BY LEVEL y hacer LEFT JOIN con ATENCION).
     * Columnas: DIA, TOTAL      (14 filas, del mas antiguo al de hoy)
     */
    private static final String DA_02 = """
            SELECT d.DIA, COUNT(a.ID_ATENCION) AS TOTAL
              FROM (SELECT TRUNC(SYSDATE) - LEVEL + 1 AS DIA FROM DUAL CONNECT BY LEVEL <= 14) d
              LEFT JOIN ATENCION a ON a.FECHA_INICIO >= d.DIA AND a.FECHA_INICIO < d.DIA + 1
             GROUP BY d.DIA
             ORDER BY d.DIA
            """;

    /**
     * [DA-03] Atenciones de los ultimos 30 dias agrupadas por especie (de mayor a menor).
     * Columnas: ESPECIE, TOTAL
     */
    private static final String DA_03 = """
            SELECT e.NOMBRE AS ESPECIE, COUNT(*) AS TOTAL
              FROM ATENCION a
              JOIN CITA c    ON c.ID_CITA = a.ID_CITA
              JOIN MASCOTA m ON m.ID_MASCOTA = c.ID_MASCOTA
              JOIN RAZA r    ON r.ID_RAZA = m.ID_RAZA
              JOIN ESPECIE e ON e.ID_ESPECIE = r.ID_ESPECIE
             WHERE a.FECHA_INICIO >= TRUNC(SYSDATE) - 30
             GROUP BY e.NOMBRE
             ORDER BY TOTAL DESC
            """;

    /**
     * [DA-04] Proximas 8 citas de HOY que siguen activas (PROGRAMADA, EN_ESPERA o EN_ATENCION), por hora.
     * Columnas: ID_CITA, FECHA_HORA, MASCOTA, PROPIETARIO, VETERINARIO, MOTIVO, ESTADO
     */
    private static final String DA_04 = """
            SELECT ID_CITA, FECHA_HORA, MASCOTA, PROPIETARIO, VETERINARIO, MOTIVO, ESTADO
              FROM VW_CITA_DETALLE
             WHERE FECHA_HORA >= TRUNC(SYSDATE) AND FECHA_HORA < TRUNC(SYSDATE) + 1
               AND ESTADO IN ('PROGRAMADA', 'EN_ESPERA', 'EN_ATENCION')
             ORDER BY FECHA_HORA
             FETCH FIRST 8 ROWS ONLY
            """;

    private final Db db;
    private final Plsql plsql;

    public SistemaRepositorio(Db db, Plsql plsql) {
        this.db = db;
        this.plsql = plsql;
    }

    // ---- usuarios
    public List<Map<String, Object>> usuarios() { return db.lista(US_01); }

    public Map<String, Object> usuario(long id) { return db.uno(US_02, "id", id); }

    public void actualizarUsuario(long id, String nombre, String rol, Long idVet, String activo) {
        db.ejecutar(US_03, "nombre", nombre, "rol", rol, "id_veterinario", idVet, "activo", activo, "id", id);
    }

    /** PKG_SEGURIDAD.PR_LOGIN -> [id, nombre, rol, id_veterinario] */
    public Plsql.Resultado login(String usuario, String clave) {
        return plsql.llamar("PKG_SEGURIDAD.PR_LOGIN",
                in(usuario), in(clave), outNumero(), outTexto(), outTexto(), outNumero());
    }

    public long crearUsuario(String usuario, String clave, String nombre, String rol, Long idVet) {
        return plsql.llamar("PKG_SEGURIDAD.PR_CREAR_USUARIO",
                in(usuario), in(clave), in(nombre), in(rol), in(idVet), outNumero()).numero(0);
    }

    public void cambiarClave(long id, String clave) {
        plsql.llamar("PKG_SEGURIDAD.PR_CAMBIAR_CLAVE", in(id), in(clave));
    }

    // ---- alertas
    public List<Map<String, Object>> alertas() { return db.lista(AL_01); }

    public void marcarLeida(long id) { db.ejecutar(AL_02, "id", id); }

    public void marcarTodas() { db.ejecutar(AL_03); }

    public int alertasPendientes() {
        Integer n = db.valor(AL_04, Integer.class);
        return n == null ? 0 : n;
    }

    /** PKG_ALERTAS.PR_GENERAR -> [vacunas, stock, citas] */
    public Plsql.Resultado generarAlertas() {
        return plsql.llamar("PKG_ALERTAS.PR_GENERAR", outNumero(), outNumero(), outNumero());
    }

    // ---- auditoria
    public List<Map<String, Object>> auditoria(String tabla) { return db.lista(AU_01, "tabla", tabla); }

    // ---- dashboard
    public Map<String, Object> indicadores() { return db.uno(DA_01); }

    public List<Map<String, Object>> atencionesPorDia() { return db.lista(DA_02); }

    public List<Map<String, Object>> atencionesPorEspecie() { return db.lista(DA_03); }

    public List<Map<String, Object>> proximasCitas() { return db.lista(DA_04); }
}
