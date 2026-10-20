/* =====================================================================
   03 - INDICES Y TIPOS                                Ejecutar como: VETERINARIA
   Solucion: soluciones/etapa2_creacion/03_indices_y_tipos.sql
   ===================================================================== */

/* 3.1 Indices a crear (Oracle crea solo los de PK y UNIQUE; los de las FK NO).
   Piensen para cada uno: ¿que consulta o FK lo necesita?

   UX_ALERTA_DIA              UNIQUE ON ALERTA (TIPO,ID_REFERENCIA,TRUNC(FECHA))
   IDX_ATENCION_VETERINARIO   ON ATENCION (ID_VETERINARIO)
   IDX_ATDIAG_DIAGNOSTICO     ON ATENCION_DIAGNOSTICO (ID_DIAGNOSTICO)
   IDX_AUDITORIA_TABLA        ON AUDITORIA (TABLA,FECHA)
   IDX_CITA_ESTADO            ON CITA (ESTADO,FECHA_HORA)
   IDX_CITA_MASCOTA           ON CITA (ID_MASCOTA)
   IDX_CITA_VET_FECHA         ON CITA (ID_VETERINARIO,FECHA_HORA)
   IDX_MASCOTA_MADRE          ON MASCOTA (ID_MADRE)
   IDX_MASCOTA_PADRE          ON MASCOTA (ID_PADRE)
   IDX_MASCOTA_PROPIETARIO    ON MASCOTA (ID_PROPIETARIO)
   IDX_MASCOTA_RAZA           ON MASCOTA (ID_RAZA)
   IDX_MOVIMIENTO_ATENCION    ON MOVIMIENTO_STOCK (ID_ATENCION)
   IDX_MOVIMIENTO_MED_FECHA   ON MOVIMIENTO_STOCK (ID_MEDICAMENTO,FECHA)
   IDX_PROPIETARIO_APELL      ON PROPIETARIO (UPPER(APELLIDOS))
   IDX_RAZA_ESPECIE           ON RAZA (ID_ESPECIE)
   IDX_TRATAMIENTO_ATENCION   ON TRATAMIENTO (ID_ATENCION)
   IDX_VACUNACION_MASCOTA     ON VACUNACION (ID_MASCOTA,ID_VACUNA)
   IDX_VACUNACION_PROXIMA     ON VACUNACION (PROXIMA_DOSIS)
   IDX_VETESP_ESPECIALIDAD    ON VETERINARIO_ESPECIALIDAD (ID_ESPECIALIDAD)

   UX_ALERTA_DIA es un indice UNICO BASADO EN FUNCION: una alerta del mismo tipo y referencia
   solo una vez por dia (TRUNC(FECHA)).
*/
-- TODO  CREATE INDEX ... ;   (19 indices)



/* 3.2 Tipo coleccion T_NUMEROS: una tabla anidada de NUMBER. La app lo usa para enviar
       la LISTA de diagnosticos y de medicamentos a PKG_ATENCION en una sola llamada.
       (Despues del CREATE TYPE va una linea con / sola.)
*/
-- TODO  CREATE OR REPLACE TYPE T_NUMEROS AS ... ;
-- /

-- Comprobar
SELECT index_name, table_name, uniqueness, index_type FROM user_indexes ORDER BY table_name;
SELECT type_name, typecode FROM user_types;
