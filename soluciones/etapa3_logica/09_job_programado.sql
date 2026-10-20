/* =====================================================================
   SOLUCION - 09 TAREA PROGRAMADA (DBMS_SCHEDULER)
   Ejecutar como: VETERINARIA  (necesita el privilegio CREATE JOB)
   ---------------------------------------------------------------------
   Todas las noches a las 02:00 Oracle, sin que nadie abra la app:
     1. marca como NO_ASISTIO las citas pasadas que siguen PROGRAMADAS
     2. genera alertas de vacunas vencidas y de stock bajo
     3. recalcula la vista materializada MV_ATENCIONES_MES
   ===================================================================== */

BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
        job_name        => 'JOB_TAREAS_NOCTURNAS',
        job_type        => 'PLSQL_BLOCK',
        job_action      => 'DECLARE
                                v_vac NUMBER; v_stk NUMBER; v_cit NUMBER;
                            BEGIN
                                PKG_ALERTAS.PR_GENERAR(v_vac, v_stk, v_cit);
                                COMMIT;
                                DBMS_MVIEW.REFRESH(''MV_ATENCIONES_MES'', ''C'');
                            END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=DAILY; BYHOUR=2; BYMINUTE=0; BYSECOND=0',
        enabled         => TRUE,
        comments        => 'Alertas, citas no asistidas y refresco de resumenes');
END;
/

-- Ejecutarlo YA (sin esperar a las 2 a.m.) para probar
BEGIN
    DBMS_SCHEDULER.RUN_JOB('JOB_TAREAS_NOCTURNAS', use_current_session => TRUE);
END;
/

-- Comprobar
SELECT job_name, enabled, state, TO_CHAR(next_run_date, 'DD/MM/YYYY HH24:MI') AS proxima
  FROM user_scheduler_jobs;
SELECT job_name, status, TO_CHAR(actual_start_date, 'DD/MM/YYYY HH24:MI:SS') AS inicio, error#
  FROM user_scheduler_job_run_details
 ORDER BY log_date DESC FETCH FIRST 5 ROWS ONLY;
SELECT mview_name, TO_CHAR(last_refresh_date, 'DD/MM/YYYY HH24:MI:SS') AS refrescada FROM user_mviews;

-- Para pausarlo / borrarlo:
--   EXEC DBMS_SCHEDULER.DISABLE('JOB_TAREAS_NOCTURNAS');
--   EXEC DBMS_SCHEDULER.DROP_JOB('JOB_TAREAS_NOCTURNAS');
