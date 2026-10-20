/* =====================================================================
   09 - TAREA PROGRAMADA                            Ejecutar como: VETERINARIA
   (Antes ejecute los datos de demostracion: soluciones/etapa3_logica/08_datos_demo.sql)
   Solucion: soluciones/etapa3_logica/09_job_programado.sql
   ===================================================================== */

/* TODO  Crear con DBMS_SCHEDULER.CREATE_JOB el job JOB_TAREAS_NOCTURNAS:
     - tipo PLSQL_BLOCK que llame a PKG_ALERTAS.PR_GENERAR, haga COMMIT y refresque
       MV_ATENCIONES_MES con DBMS_MVIEW.REFRESH('MV_ATENCIONES_MES', 'C')
     - todos los dias a las 02:00  (repeat_interval => 'FREQ=DAILY; BYHOUR=2; ...')
     - habilitado
   Luego ejecutelo YA con DBMS_SCHEDULER.RUN_JOB para probarlo. */


-- Comprobar
SELECT job_name, enabled, state, next_run_date FROM user_scheduler_jobs;
SELECT job_name, status, actual_start_date, error# FROM user_scheduler_job_run_details ORDER BY log_date DESC;
