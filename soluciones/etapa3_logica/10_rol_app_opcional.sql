/* =====================================================================
   SOLUCION - 10 (OPCIONAL) ROL Y USUARIO DE APLICACION
   ---------------------------------------------------------------------
   La app NO deberia conectarse con el dueño de las tablas (VETERINARIA
   puede hacer DROP TABLE). Se crea VET_APP, que solo puede manipular
   datos y ejecutar los paquetes, a traves del rol ROL_VET_APP.
   Ejecutar DESPUES de todos los scripts de la etapa 3.
   ===================================================================== */

-- ---- PARTE A: como SYSTEM -------------------------------------------
ALTER SESSION SET CONTAINER = XEPDB1;

CREATE ROLE ROL_VET_APP;

-- Sin QUOTA: no puede crear objetos propios
CREATE USER VET_APP IDENTIFIED BY "VetApp2026";
GRANT CREATE SESSION TO VET_APP;
GRANT ROL_VET_APP TO VET_APP;

-- Para que la app use "PROPIETARIO" sin escribir "VETERINARIA.PROPIETARIO":
-- cada vez que VET_APP se conecta, su esquema por defecto pasa a ser VETERINARIA
CREATE OR REPLACE TRIGGER VET_APP_LOGON
    AFTER LOGON ON VET_APP.SCHEMA
BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA = VETERINARIA';
END;
/


-- ---- PARTE B: como VETERINARIA (el dueño otorga permisos sobre SUS objetos)
-- Se generan los GRANT recorriendo el diccionario de datos (SQL dinamico)
BEGIN
    FOR t IN (SELECT table_name FROM user_tables
               WHERE table_name NOT IN ('AUDITORIA', 'MOVIMIENTO_STOCK')
                 AND table_name NOT LIKE 'MV%') LOOP
        EXECUTE IMMEDIATE 'GRANT SELECT, INSERT, UPDATE, DELETE ON ' || t.table_name || ' TO ROL_VET_APP';
    END LOOP;

    -- Auditoria: solo lectura (la escriben los triggers). Kardex: leer e insertar, nunca editar
    EXECUTE IMMEDIATE 'GRANT SELECT ON AUDITORIA TO ROL_VET_APP';
    EXECUTE IMMEDIATE 'GRANT SELECT, INSERT ON MOVIMIENTO_STOCK TO ROL_VET_APP';

    FOR v IN (SELECT view_name AS nombre FROM user_views
              UNION ALL SELECT mview_name FROM user_mviews) LOOP
        EXECUTE IMMEDIATE 'GRANT SELECT ON ' || v.nombre || ' TO ROL_VET_APP';
    END LOOP;

    FOR p IN (SELECT object_name FROM user_objects WHERE object_type IN ('PACKAGE', 'TYPE')) LOOP
        EXECUTE IMMEDIATE 'GRANT EXECUTE ON ' || p.object_name || ' TO ROL_VET_APP';
    END LOOP;
END;
/

-- Comprobar
SELECT privilege, COUNT(*) FROM user_tab_privs_made WHERE grantee = 'ROL_VET_APP' GROUP BY privilege;


-- ---- PARTE C: probar con VET_APP -----------------------------------
--   SELECT COUNT(*) FROM MASCOTA;          -- funciona (CURRENT_SCHEMA = VETERINARIA)
--   DROP TABLE MASCOTA;                    -- ORA-01031: privilegios insuficientes
--   DELETE FROM AUDITORIA;                 -- ORA-01031
-- En config/db.properties:  db.usuario=VET_APP
