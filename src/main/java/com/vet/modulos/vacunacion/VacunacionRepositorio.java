package com.vet.modulos.vacunacion;

import com.vet.db.Db;
import com.vet.db.Sql;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

/** Carnet de vacunacion. La PROXIMA_DOSIS la calcula el trigger TRG_VACUNACION. */
@Repository
public class VacunacionRepositorio {

    /**
     * [VC-01] Carnet de vacunacion de una mascota (lo mas reciente primero).
     * SITUACION: 'HISTORICA' si despues hubo otra dosis de la MISMA vacuna (pista: ROW_NUMBER() OVER (PARTITION BY ...));
     *            si es la ultima: 'VENCIDA' (proxima < hoy), 'POR VENCER' (en 30 dias o menos), 'VIGENTE',
     *            o 'DOSIS UNICA' si no tiene proxima dosis.
     * Columnas: ID_VACUNACION, VACUNA, FECHA_APLICACION, PROXIMA_DOSIS, LOTE, VETERINARIO, SITUACION
     * Parametros: :id_mascota
     */
    private static final String VC_01 = Sql.pendiente("VC-01");

    /**
     * [VC-02] Vacunas disponibles para una especie, ordenadas por nombre.
     * Columnas: ID_VACUNA, NOMBRE, REFUERZO_DIAS
     * Parametros: :id_especie
     */
    private static final String VC_02 = Sql.pendiente("VC-02");

    /**
     * [VC-03] Registrar una vacunacion. NO enviar PROXIMA_DOSIS: la calcula el trigger.
     * Parametros: :id_mascota, :id_vacuna, :id_veterinario, :fecha, :lote
     */
    private static final String VC_03 = Sql.pendiente("VC-03");

    private final Db db;

    public VacunacionRepositorio(Db db) {
        this.db = db;
    }

    public List<Map<String, Object>> carnet(long idMascota) { return db.lista(VC_01, "id_mascota", idMascota); }

    public List<Map<String, Object>> vacunasDeEspecie(long idEspecie) { return db.lista(VC_02, "id_especie", idEspecie); }

    public void registrar(long idMascota, long idVacuna, long idVet, LocalDate fecha, String lote) {
        db.ejecutar(VC_03, "id_mascota", idMascota, "id_vacuna", idVacuna, "id_veterinario", idVet,
                "fecha", fecha, "lote", lote);
    }
}
