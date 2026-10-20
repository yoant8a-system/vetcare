/* =====================================================================
   10 - (OPCIONAL) ROL Y USUARIO DE APLICACION
   Solucion: soluciones/etapa3_logica/10_rol_app_opcional.sql
   ===================================================================== */

/* Idea: la app no deberia conectarse con el DUEÑO de las tablas (puede hacer DROP TABLE).
   TODO (como SYSTEM):  rol ROL_VET_APP, usuario VET_APP con CREATE SESSION y el rol,
                        y un trigger AFTER LOGON que haga ALTER SESSION SET CURRENT_SCHEMA = VETERINARIA
   TODO (como VETERINARIA): GRANT al rol de SELECT/INSERT/UPDATE/DELETE sobre las tablas, solo SELECT
                        sobre AUDITORIA, SELECT/INSERT sobre MOVIMIENTO_STOCK, SELECT sobre las vistas
                        y EXECUTE sobre paquetes y el tipo T_NUMEROS.
                        Extra: generar los GRANT recorriendo USER_TABLES con EXECUTE IMMEDIATE.
   Probar con VET_APP:  SELECT funciona; DROP TABLE MASCOTA -> ORA-01031 */
