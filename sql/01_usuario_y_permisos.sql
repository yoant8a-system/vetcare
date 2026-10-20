/* =====================================================================
   01 - TABLESPACE, USUARIO Y PERMISOS            Ejecutar como: SYSTEM
   Solucion: soluciones/etapa2_creacion/01_usuario_y_permisos.sql
   ===================================================================== */

-- Los usuarios locales van en la PDB, no en CDB$ROOT (si no: ORA-65096)
ALTER SESSION SET CONTAINER = XEPDB1;

-- TODO 1.1  Tablespace propio TS_VETERINARIA (100 MB, autoextensible hasta 1 GB).
--   Pista: averigue la carpeta de los archivos con
--          SELECT file_name FROM dba_data_files WHERE tablespace_name = 'USERS';
--   y cree el datafile TS_VETERINARIA01.DBF en esa misma carpeta.
--   (Extra: hacerlo con SQL dinamico -EXECUTE IMMEDIATE- para que funcione en cualquier PC.)


-- TODO 1.2  Usuario VETERINARIA, con TS_VETERINARIA por defecto, TEMP temporal
--           y cuota ilimitada en su tablespace.


-- TODO 1.3  Privilegios MINIMOS de sistema (nada de GRANT DBA):
--   sesion, tablas, vistas, vistas materializadas, secuencias, procedimientos,
--   triggers, tipos y jobs (DBMS_SCHEDULER).


-- Comprobar
SELECT username, default_tablespace, account_status FROM dba_users WHERE username = 'VETERINARIA';
SELECT privilege FROM dba_sys_privs WHERE grantee = 'VETERINARIA' ORDER BY privilege;
