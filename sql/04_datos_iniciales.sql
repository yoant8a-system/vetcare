/* =====================================================================
   04 - DATOS INICIALES                             Ejecutar como: VETERINARIA
   ---------------------------------------------------------------------
   Los ID son IDENTITY (GENERATED ALWAYS): NO se escriben en el INSERT.
   Para las FK, busque el ID con una subconsulta por un dato unico:
     INSERT INTO RAZA (ID_ESPECIE, NOMBRE)
     VALUES ((SELECT ID_ESPECIE FROM ESPECIE WHERE NOMBRE = 'Perro'), 'Mestizo');

   Este archivo es largo y repetitivo: practiquen con los TODO y luego
   pueden ejecutar directamente la solucion completa:
     soluciones/etapa2_creacion/04_datos_iniciales.sql
   (trae 4 especies, 16 razas, 25 diagnosticos, 9 vacunas, 4 veterinarios con
    horarios, 6 usuarios, 12 insumos, 10 propietarios y 17 mascotas con genealogia)
   ===================================================================== */

-- TODO 4.1  Especies: Perro, Gato, Conejo, Ave

-- TODO 4.2  Algunas razas por especie (subconsulta para ID_ESPECIE)

-- TODO 4.3  Especialidades y consultorios (Consultorio 1, 2, 3 y Emergencias)

-- TODO 4.4  Un veterinario, sus especialidades (tabla N:M) y su horario de lunes a viernes
--           Pista: (SELECT LEVEL AS DIA FROM DUAL CONNECT BY LEVEL <= 5) genera los dias 1..5

-- TODO 4.5  Usuarios de la app. La clave se guarda como SHA-256 de 'usuario:clave':
--   INSERT INTO USUARIO (USUARIO, CLAVE_HASH, NOMBRE_COMPLETO, ROL)
--   VALUES ('admin', RAWTOHEX(STANDARD_HASH('admin:admin123', 'SHA256')), 'Administrador', 'ADMIN');

-- TODO 4.6  Un propietario y dos mascotas

COMMIT;
