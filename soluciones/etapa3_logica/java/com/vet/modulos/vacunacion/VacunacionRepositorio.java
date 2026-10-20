package com.vet.modulos.vacunacion;

import com.vet.db.Db;
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
    private static final String VC_01 = """
            SELECT va.ID_VACUNACION, v.NOMBRE AS VACUNA, va.FECHA_APLICACION, va.PROXIMA_DOSIS, va.LOTE,
                   vt.NOMBRES || ' ' || vt.APELLIDOS AS VETERINARIO,
                   CASE WHEN ROW_NUMBER() OVER (PARTITION BY va.ID_VACUNA ORDER BY va.FECHA_APLICACION DESC) > 1 THEN 'HISTORICA'
                        WHEN va.PROXIMA_DOSIS IS NULL THEN 'DOSIS UNICA'
                        WHEN va.PROXIMA_DOSIS < TRUNC(SYSDATE) THEN 'VENCIDA'
                        WHEN va.PROXIMA_DOSIS <= TRUNC(SYSDATE) + 30 THEN 'POR VENCER'
                        ELSE 'VIGENTE' END AS SITUACION
              FROM VACUNACION va
              JOIN VACUNA v       ON v.ID_VACUNA = va.ID_VACUNA
              JOIN VETERINARIO vt ON vt.ID_VETERINARIO = va.ID_VETERINARIO
             WHERE va.ID_MASCOTA = :id_mascota
             ORDER BY va.FECHA_APLICACION DESC
            """;

    /**
     * [VC-02] Vacunas disponibles para una especie, ordenadas por nombre.
     * Columnas: ID_VACUNA, NOMBRE, REFUERZO_DIAS
     * Parametros: :id_especie
     */
    private static final String VC_02 = """
            SELECT ID_VACUNA, NOMBRE, REFUERZO_DIAS FROM VACUNA WHERE ID_ESPECIE = :id_especie ORDER BY NOMBRE
            """;

    /**
     * [VC-03] Registrar una vacunacion. NO enviar PROXIMA_DOSIS: la calcula el trigger.
     * Parametros: :id_mascota, :id_vacuna, :id_veterinario, :fecha, :lote
     */
    private static final String VC_03 = """
            INSERT INTO VACUNACION (ID_MASCOTA, ID_VACUNA, ID_VETERINARIO, FECHA_APLICACION, LOTE)
            VALUES (:id_mascota, :id_vacuna, :id_veterinario, :fecha, :lote)
            """;

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
