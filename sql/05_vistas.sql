/* =====================================================================
   05 - VISTAS Y VISTA MATERIALIZADA                Ejecutar como: VETERINARIA
   Las consultas de la app usan estas vistas: las COLUMNAS deben llamarse asi.
   Solucion: soluciones/etapa3_logica/05_vistas.sql
   ===================================================================== */

/* 5.1 VW_MASCOTA_DETALLE: mascota + raza + especie + propietario + padres
   Columnas: ID_MASCOTA, NOMBRE, SEXO, FECHA_NACIMIENTO,
             EDAD (texto '3 a 2 m'; pista: MONTHS_BETWEEN, TRUNC, MOD),
             COLOR, ESTERILIZADO, ESTADO, ID_RAZA, RAZA, ID_ESPECIE, ESPECIE,
             ID_PROPIETARIO, PROPIETARIO ('Apellidos, Nombres'), DNI, TELEFONO,
             ID_PADRE, PADRE (nombre), ID_MADRE, MADRE (nombre), FECHA_REGISTRO
   Pista: MASCOTA aparece 3 veces (hijo, padre, madre): alias distintos y LEFT JOIN para los padres */
-- TODO


/* 5.2 VW_CITA_DETALLE: cita con todos sus nombres
   Columnas: ID_CITA, FECHA_HORA, DURACION_MIN, ORIGEN, MOTIVO, ESTADO, FECHA_LLEGADA, FECHA_LLAMADO,
             ID_MASCOTA, MASCOTA, ESPECIE, ID_PROPIETARIO, PROPIETARIO, TELEFONO,
             ID_VETERINARIO, VETERINARIO ('Nombres Apellidos'), ID_CONSULTORIO, CONSULTORIO, NIVEL_URGENCIA
   Ojo: una cita sin veterinario debe dar VETERINARIO NULL... y NULL || ' ' || NULL NO es NULL. */
-- TODO


/* 5.3 VW_COLA_ATENCION: citas EN_ESPERA con su triaje
   Columnas: ID_CITA, ID_MASCOTA, MASCOTA, ESPECIE, PROPIETARIO, ID_VETERINARIO, VETERINARIO, MOTIVO, ORIGEN,
             FECHA_LLEGADA, MINUTOS_ESPERA (desde la llegada hasta ahora), NIVEL_URGENCIA,
             URGENCIA (1 Emergencia, 2 Muy urgente, 3 Urgente, 4 Poco urgente, 5 No urgente), PESO_KG, TEMPERATURA */
-- TODO


/* 5.4 VW_PANTALLA: citas EN_ATENCION llamadas HOY (para el TV de la sala)
   Columnas: ID_CITA, MASCOTA, APELLIDO (solo el primer apellido: REGEXP_SUBSTR), CONSULTORIO,
             VETERINARIO, FECHA_LLAMADO, NIVEL_URGENCIA */
-- TODO


/* 5.5 MV_ATENCIONES_MES: VISTA MATERIALIZADA (guarda el resultado), REFRESH COMPLETE ON DEMAND
   Columnas: MES (TRUNC(fecha, 'MM')), ESPECIE, ATENCIONES (COUNT), MASCOTAS (COUNT DISTINCT)
   La usa el reporte R7; la refresca el job del archivo 09 con DBMS_MVIEW.REFRESH. */
-- TODO
