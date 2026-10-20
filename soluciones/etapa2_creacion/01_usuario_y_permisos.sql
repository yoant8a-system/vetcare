/* =====================================================================
   SOLUCION - 01 USUARIO Y PERMISOS
   Ejecutar como: SYSTEM (o SYS AS SYSDBA)
   Nota SQL*Plus: no poner comentarios despues del ; en la misma linea.
   ===================================================================== */

-- Los usuarios "locales" se crean dentro de la PDB, no en CDB$ROOT (ORA-65096)
ALTER SESSION SET CONTAINER = XEPDB1;

-- Tablespace propio: los datos del sistema quedan separados de USERS
-- (facilita respaldos, cuotas y monitoreo de espacio).
-- La ruta del archivo cambia en cada PC (C:\APP\<usuario>\...), asi que se arma
-- con SQL dinamico usando la misma carpeta donde esta el archivo de USERS.
-- Forma "a mano" equivalente:
--   CREATE TABLESPACE TS_VETERINARIA
--       DATAFILE 'C:\APP\<usuario>\PRODUCT\21C\ORADATA\XE\XEPDB1\TS_VETERINARIA01.DBF'
--       SIZE 100M AUTOEXTEND ON NEXT 20M MAXSIZE 1G;
DECLARE
    v_carpeta VARCHAR2(500);
BEGIN
    SELECT SUBSTR(file_name, 1, INSTR(file_name, '\', -1))
      INTO v_carpeta
      FROM dba_data_files
     WHERE tablespace_name = 'USERS';

    EXECUTE IMMEDIATE 'CREATE TABLESPACE TS_VETERINARIA DATAFILE '''
                   || v_carpeta || 'TS_VETERINARIA01.DBF'' SIZE 100M AUTOEXTEND ON NEXT 20M MAXSIZE 1G';
END;
/

-- Esquema dueño de todos los objetos (cambien la contraseña)
CREATE USER VETERINARIA IDENTIFIED BY "Vet2026"
    DEFAULT TABLESPACE TS_VETERINARIA
    TEMPORARY TABLESPACE TEMP
    QUOTA UNLIMITED ON TS_VETERINARIA;

-- Minimo privilegio: solo lo que el esquema necesita
GRANT CREATE SESSION,
      CREATE TABLE,
      CREATE VIEW,
      CREATE MATERIALIZED VIEW,
      CREATE SEQUENCE,
      CREATE PROCEDURE,
      CREATE TRIGGER,
      CREATE TYPE,
      CREATE JOB
   TO VETERINARIA;

-- Comprobar
SELECT username, default_tablespace, account_status FROM dba_users WHERE username = 'VETERINARIA';
SELECT privilege FROM dba_sys_privs WHERE grantee = 'VETERINARIA' ORDER BY privilege;
SELECT tablespace_name, file_name, bytes / 1024 / 1024 AS mb, autoextensible
  FROM dba_data_files WHERE tablespace_name = 'TS_VETERINARIA';
