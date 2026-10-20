package com.vet.modulos.cita;

import com.vet.db.Db;
import com.vet.db.Sql;
import com.vet.db.Plsql;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import static com.vet.db.Plsql.in;
import static com.vet.db.Plsql.outNumero;

/**
 * Agenda de citas. Las CONSULTAS son SQL; las OPERACIONES con reglas de negocio
 * (programar, llegada con triaje, cancelar) llaman al paquete PKG_CITAS.
 */
@Repository
public class CitaRepositorio {

    /**
     * [CI-01] Agenda de un dia (desde las 00:00 de :fecha hasta antes de las 00:00 del dia siguiente),
     * opcionalmente de un veterinario (:id_veterinario NULL = todos). Usar VW_CITA_DETALLE. Ordenar por hora.
     * Columnas: ID_CITA, FECHA_HORA, DURACION_MIN, ORIGEN, MOTIVO, ESTADO, ID_MASCOTA, MASCOTA, ESPECIE,
     *           PROPIETARIO, TELEFONO, VETERINARIO, CONSULTORIO, NIVEL_URGENCIA
     * Parametros: :fecha, :id_veterinario
     */
    private static final String CI_01 = Sql.pendiente("CI-01");

    /**
     * [CI-02] Una cita con todos los datos de VW_CITA_DETALLE.
     * Parametros: :id
     */
    private static final String CI_02 = Sql.pendiente("CI-02");

    /**
     * [CI-03] Ultimas 50 citas de una mascota (la mas reciente primero).
     * Columnas: ID_CITA, FECHA_HORA, MOTIVO, ESTADO, VETERINARIO, ORIGEN
     * Parametros: :id_mascota
     */
    private static final String CI_03 = Sql.pendiente("CI-03");

    /**
     * [CI-04] Mascotas ACTIVAS para el combo de "nueva cita", ordenadas por nombre.
     * Columnas: ID_MASCOTA, ETIQUETA (ej. "Firulais - Chavez Rios, Luis (Perro)")
     */
    private static final String CI_04 = Sql.pendiente("CI-04");

    private final Db db;
    private final Plsql plsql;

    public CitaRepositorio(Db db, Plsql plsql) {
        this.db = db;
        this.plsql = plsql;
    }

    public List<Map<String, Object>> agenda(LocalDate fecha, Long idVeterinario) {
        return db.lista(CI_01, "fecha", fecha, "id_veterinario", idVeterinario);
    }

    public Map<String, Object> obtener(long id) {
        return db.uno(CI_02, "id", id);
    }

    public List<Map<String, Object>> deMascota(long idMascota) {
        return db.lista(CI_03, "id_mascota", idMascota);
    }

    public List<Map<String, Object>> mascotasActivas() {
        return db.lista(CI_04);
    }

    // ------------------------------------------------------------ PL/SQL: PKG_CITAS

    public long programar(long idMascota, long idVet, LocalDateTime fecha, int duracion, String motivo) {
        return plsql.llamar("PKG_CITAS.PR_PROGRAMAR",
                in(idMascota), in(idVet), in(fecha), in(duracion), in(motivo), outNumero()).numero(0);
    }

    public void registrarLlegada(long idCita, Triaje t) {
        plsql.llamar("PKG_CITAS.PR_REGISTRAR_LLEGADA",
                in(idCita), in(t.peso()), in(t.temperatura()), in(t.fc()), in(t.fr()), in(t.urgencia()), in(t.obs()));
    }

    public long registrarSinCita(long idMascota, String motivo, Triaje t) {
        return plsql.llamar("PKG_CITAS.PR_REGISTRAR_SIN_CITA",
                in(idMascota), in(motivo), in(t.peso()), in(t.temperatura()), in(t.fc()), in(t.fr()),
                in(t.urgencia()), in(t.obs()), outNumero()).numero(0);
    }

    public void cancelar(long idCita) {
        plsql.llamar("PKG_CITAS.PR_CANCELAR", in(idCita));
    }

    /** Datos del formulario de triaje. */
    public record Triaje(BigDecimal peso, BigDecimal temperatura, Integer fc, Integer fr, int urgencia, String obs) {
    }
}
