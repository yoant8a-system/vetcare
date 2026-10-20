/* =====================================================================
   99 BORRAR TODO (listo para usar)
   ---------------------------------------------------------------------
   Opcion A (la mas simple), como SYSTEM: borra el usuario con TODOS sus
   objetos y luego el tablespace con su archivo de datos.
   ===================================================================== */

-- ---- Opcion A: como SYSTEM -----------------------------------------
-- ALTER SESSION SET CONTAINER = XEPDB1;
-- DROP USER VET_APP CASCADE;
-- DROP ROLE ROL_VET_APP;
-- DROP USER VETERINARIA CASCADE;
-- DROP TABLESPACE TS_VETERINARIA INCLUDING CONTENTS AND DATAFILES;


-- ---- Opcion B: como VETERINARIA, borrar objeto por objeto -----------
-- (sirve para volver a correr los scripts sin recrear el usuario)
BEGIN
    DBMS_SCHEDULER.DROP_JOB('JOB_TAREAS_NOCTURNAS', force => TRUE);
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- Recorre el diccionario y borra en orden: primero lo que depende de otros.
-- CASCADE CONSTRAINTS evita tener que ordenar las tablas por sus FK. PURGE = sin papelera.
BEGIN
    FOR o IN (SELECT object_name, object_type
                FROM user_objects
               WHERE object_type IN ('MATERIALIZED VIEW', 'VIEW', 'PACKAGE', 'TABLE', 'TYPE')
               ORDER BY DECODE(object_type, 'MATERIALIZED VIEW', 1, 'VIEW', 2, 'PACKAGE', 3, 'TABLE', 4, 5)) LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP ' || o.object_type || ' ' || o.object_name ||
                              CASE o.object_type WHEN 'TABLE' THEN ' CASCADE CONSTRAINTS PURGE'
                                                 WHEN 'TYPE'  THEN ' FORCE' END;
        EXCEPTION
            -- p. ej. la tabla interna de la vista materializada ya se fue junto con ella
            WHEN OTHERS THEN NULL;
        END;
    END LOOP;
END;
/

-- Comprobar que no quedo nada
SELECT object_type, object_name FROM user_objects ORDER BY 1, 2;
