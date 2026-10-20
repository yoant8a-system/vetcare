package com.vet.modulos.atencion;

import com.vet.db.Db;
import com.vet.db.Sql;
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
    private static final String AT_01 = Sql.pendiente("AT-01");

    /**
     * [AT-02] Paciente que el veterinario tiene EN_ATENCION ahora (0 o 1 fila), con su triaje y datos de la mascota.
     * Pista: VW_CITA_DETALLE + TRIAJE + VW_MASCOTA_DETALLE.
     * Columnas: ID_CITA, ID_MASCOTA, MASCOTA, ESPECIE, ID_ESPECIE, RAZA, SEXO, EDAD, PROPIETARIO, TELEFONO,
     *           MOTIVO, CONSULTORIO, FECHA_LLAMADO, NIVEL_URGENCIA, PESO_KG, TEMPERATURA, FREC_CARDIACA,
     *           FREC_RESPIRATORIA, OBS_TRIAJE (= TRIAJE.OBSERVACIONES)
     * Parametros: :id_veterinario
     */
    private static final String AT_02 = Sql.pendiente("AT-02");

    /**
     * [AT-03] Diagnosticos que aplican a una especie: los de esa especie + los generales (ID_ESPECIE NULL).
     * Ordenar por categoria y nombre.
     * Columnas: ID_DIAGNOSTICO, CODIGO, NOMBRE, CATEGORIA
     * Parametros: :id_especie
     */
    private static final String AT_03 = Sql.pendiente("AT-03");

    /**
     * [AT-04] Medicamentos activos que tienen stock (> 0), ordenados por nombre.
     * Columnas: ID_MEDICAMENTO, NOMBRE, PRESENTACION, UNIDAD, STOCK_ACTUAL
     */
    private static final String AT_04 = Sql.pendiente("AT-04");

    /**
     * [AT-05] Consultorios activos y LIBRES (sin ninguna cita EN_ATENCION en ellos). Pista: NOT EXISTS.
     * Columnas: ID_CONSULTORIO, NOMBRE
     */
    private static final String AT_05 = Sql.pendiente("AT-05");

    /**
     * [AT-06] Atenciones que el veterinario registro HOY (la mas reciente primero), con su duracion en minutos.
     * Columnas: ID_ATENCION, ID_MASCOTA, MASCOTA, PROPIETARIO, FECHA_INICIO, FECHA_FIN, MINUTOS
     * Parametros: :id_veterinario
     */
    private static final String AT_06 = Sql.pendiente("AT-06");

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
