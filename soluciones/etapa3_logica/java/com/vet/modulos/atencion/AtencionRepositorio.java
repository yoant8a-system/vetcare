package com.vet.modulos.atencion;

import com.vet.db.Db;
import com.vet.db.Plsql;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Map;

import static com.vet.db.Plsql.in;
import static com.vet.db.Plsql.numeros;
import static com.vet.db.Plsql.outNumero;

/** Consultorio del veterinario: cola de atencion, paciente actual y registro de la atencion (PKG_ATENCION). */
@Repository
public class AtencionRepositorio {

    /**
     * [AT-01] Cola de atencion: pacientes EN_ESPERA con su triaje (vista VW_COLA_ATENCION).
     * Orden: primero el NIVEL_URGENCIA mas bajo (1 = emergencia) y, a igual urgencia, el que llego antes.
     * Columnas: ID_CITA, MASCOTA, ESPECIE, PROPIETARIO, ID_VETERINARIO, VETERINARIO, MOTIVO, ORIGEN,
     *           FECHA_LLEGADA, MINUTOS_ESPERA, NIVEL_URGENCIA, URGENCIA, PESO_KG, TEMPERATURA
     */
    private static final String AT_01 = """
            SELECT ID_CITA, MASCOTA, ESPECIE, PROPIETARIO, ID_VETERINARIO, VETERINARIO, MOTIVO, ORIGEN,
                   FECHA_LLEGADA, MINUTOS_ESPERA, NIVEL_URGENCIA, URGENCIA, PESO_KG, TEMPERATURA
              FROM VW_COLA_ATENCION
             ORDER BY NIVEL_URGENCIA, FECHA_LLEGADA
            """;

    /**
     * [AT-02] Paciente que el veterinario tiene EN_ATENCION ahora (0 o 1 fila), con su triaje y datos de la mascota.
     * Pista: VW_CITA_DETALLE + TRIAJE + VW_MASCOTA_DETALLE.
     * Columnas: ID_CITA, ID_MASCOTA, MASCOTA, ESPECIE, ID_ESPECIE, RAZA, SEXO, EDAD, PROPIETARIO, TELEFONO,
     *           MOTIVO, CONSULTORIO, FECHA_LLAMADO, NIVEL_URGENCIA, PESO_KG, TEMPERATURA, FREC_CARDIACA,
     *           FREC_RESPIRATORIA, OBS_TRIAJE (= TRIAJE.OBSERVACIONES)
     * Parametros: :id_veterinario
     */
    private static final String AT_02 = """
            SELECT c.ID_CITA, c.ID_MASCOTA, c.MASCOTA, c.ESPECIE, m.ID_ESPECIE, m.RAZA, m.SEXO, m.EDAD,
                   c.PROPIETARIO, c.TELEFONO, c.MOTIVO, c.CONSULTORIO, c.FECHA_LLAMADO, c.NIVEL_URGENCIA,
                   t.PESO_KG, t.TEMPERATURA, t.FREC_CARDIACA, t.FREC_RESPIRATORIA, t.OBSERVACIONES AS OBS_TRIAJE
              FROM VW_CITA_DETALLE c
              JOIN TRIAJE t             ON t.ID_CITA = c.ID_CITA
              JOIN VW_MASCOTA_DETALLE m ON m.ID_MASCOTA = c.ID_MASCOTA
             WHERE c.ESTADO = 'EN_ATENCION'
               AND c.ID_VETERINARIO = :id_veterinario
            """;

    /**
     * [AT-03] Diagnosticos que aplican a una especie: los de esa especie + los generales (ID_ESPECIE NULL).
     * Ordenar por categoria y nombre.
     * Columnas: ID_DIAGNOSTICO, CODIGO, NOMBRE, CATEGORIA
     * Parametros: :id_especie
     */
    private static final String AT_03 = """
            SELECT ID_DIAGNOSTICO, CODIGO, NOMBRE, CATEGORIA
              FROM DIAGNOSTICO
             WHERE ID_ESPECIE IS NULL OR ID_ESPECIE = :id_especie
             ORDER BY CATEGORIA, NOMBRE
            """;

    /**
     * [AT-04] Medicamentos activos que tienen stock (> 0), ordenados por nombre.
     * Columnas: ID_MEDICAMENTO, NOMBRE, PRESENTACION, UNIDAD, STOCK_ACTUAL
     */
    private static final String AT_04 = """
            SELECT ID_MEDICAMENTO, NOMBRE, PRESENTACION, UNIDAD, STOCK_ACTUAL
              FROM MEDICAMENTO
             WHERE ACTIVO = 'S' AND STOCK_ACTUAL > 0
             ORDER BY NOMBRE, PRESENTACION
            """;

    /**
     * [AT-05] Consultorios activos y LIBRES (sin ninguna cita EN_ATENCION en ellos). Pista: NOT EXISTS.
     * Columnas: ID_CONSULTORIO, NOMBRE
     */
    private static final String AT_05 = """
            SELECT co.ID_CONSULTORIO, co.NOMBRE
              FROM CONSULTORIO co
             WHERE co.ACTIVO = 'S'
               AND NOT EXISTS (SELECT 1 FROM CITA c
                                WHERE c.ID_CONSULTORIO = co.ID_CONSULTORIO AND c.ESTADO = 'EN_ATENCION')
             ORDER BY co.NOMBRE
            """;

    /**
     * [AT-06] Atenciones que el veterinario registro HOY (la mas reciente primero), con su duracion en minutos.
     * Columnas: ID_ATENCION, ID_MASCOTA, MASCOTA, PROPIETARIO, FECHA_INICIO, FECHA_FIN, MINUTOS
     * Parametros: :id_veterinario
     */
    private static final String AT_06 = """
            SELECT a.ID_ATENCION, c.ID_MASCOTA, c.MASCOTA, c.PROPIETARIO, a.FECHA_INICIO, a.FECHA_FIN,
                   ROUND((a.FECHA_FIN - a.FECHA_INICIO) * 24 * 60) AS MINUTOS
              FROM ATENCION a
              JOIN VW_CITA_DETALLE c ON c.ID_CITA = a.ID_CITA
             WHERE a.ID_VETERINARIO = :id_veterinario
               AND a.FECHA_INICIO >= TRUNC(SYSDATE)
             ORDER BY a.FECHA_INICIO DESC
            """;

    private final Db db;
    private final Plsql plsql;

    public AtencionRepositorio(Db db, Plsql plsql) {
        this.db = db;
        this.plsql = plsql;
    }

    public List<Map<String, Object>> cola() { return db.lista(AT_01); }

    public Map<String, Object> pacienteActual(long idVet) { return db.uno(AT_02, "id_veterinario", idVet); }

    public List<Map<String, Object>> diagnosticos(long idEspecie) { return db.lista(AT_03, "id_especie", idEspecie); }

    public List<Map<String, Object>> medicamentos() { return db.lista(AT_04); }

    public List<Map<String, Object>> consultoriosLibres() { return db.lista(AT_05); }

    public List<Map<String, Object>> atendidosHoy(long idVet) { return db.lista(AT_06, "id_veterinario", idVet); }

    // ------------------------------------------------------------ PL/SQL: PKG_ATENCION

    /** Devuelve el ID de la cita llamada, o null si la cola esta vacia. */
    public Long llamarSiguiente(long idVet, long idConsultorio) {
        return plsql.llamar("PKG_ATENCION.PR_LLAMAR_SIGUIENTE", in(idVet), in(idConsultorio), outNumero()).numero(0);
    }

    public void rellamar(long idCita) {
        plsql.llamar("PKG_ATENCION.PR_RELLAMAR", in(idCita));
    }

    public long registrar(long idCita, long idVet, Atencion a) {
        return plsql.llamar("PKG_ATENCION.PR_REGISTRAR_ATENCION",
                in(idCita), in(idVet), in(a.anamnesis()), in(a.examen()), in(a.indicaciones()),
                numeros(a.diagnosticos()), numeros(a.definitivos()),
                in(a.tratamiento()), in(a.sesiones()), in(a.frecuencia()),
                numeros(a.medicamentos()), numeros(a.cantidades()),
                outNumero()).numero(0);
    }

    /** Lo que el veterinario llena en el formulario de atencion. */
    public record Atencion(String anamnesis, String examen, String indicaciones,
                           List<Long> diagnosticos, List<Long> definitivos,
                           String tratamiento, Integer sesiones, Integer frecuencia,
                           List<Long> medicamentos, List<java.math.BigDecimal> cantidades) {
    }
}
