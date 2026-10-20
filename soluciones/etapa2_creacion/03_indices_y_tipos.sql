/* =====================================================================
   SOLUCION - 03 INDICES Y TIPOS
   Ejecutar como: VETERINARIA
   ===================================================================== */

-- ---------------------------------------------------------------------
-- 3.1 Indices sobre las FK (Oracle NO los crea solo).
--     Sin ellos, borrar/actualizar un padre bloquea toda la tabla hija
--     y los JOIN recorren la tabla completa.
-- ---------------------------------------------------------------------
CREATE INDEX IDX_RAZA_ESPECIE         ON RAZA (ID_ESPECIE);
CREATE INDEX IDX_MASCOTA_PROPIETARIO  ON MASCOTA (ID_PROPIETARIO);
CREATE INDEX IDX_MASCOTA_RAZA         ON MASCOTA (ID_RAZA);
CREATE INDEX IDX_MASCOTA_PADRE        ON MASCOTA (ID_PADRE);
CREATE INDEX IDX_MASCOTA_MADRE        ON MASCOTA (ID_MADRE);
CREATE INDEX IDX_VETESP_ESPECIALIDAD  ON VETERINARIO_ESPECIALIDAD (ID_ESPECIALIDAD);
CREATE INDEX IDX_CITA_MASCOTA         ON CITA (ID_MASCOTA);
CREATE INDEX IDX_ATENCION_VETERINARIO ON ATENCION (ID_VETERINARIO);
CREATE INDEX IDX_ATDIAG_DIAGNOSTICO   ON ATENCION_DIAGNOSTICO (ID_DIAGNOSTICO);
CREATE INDEX IDX_TRATAMIENTO_ATENCION ON TRATAMIENTO (ID_ATENCION);
CREATE INDEX IDX_VACUNACION_MASCOTA   ON VACUNACION (ID_MASCOTA, ID_VACUNA);
CREATE INDEX IDX_MOVIMIENTO_MED_FECHA ON MOVIMIENTO_STOCK (ID_MEDICAMENTO, FECHA);
CREATE INDEX IDX_MOVIMIENTO_ATENCION  ON MOVIMIENTO_STOCK (ID_ATENCION);

-- ---------------------------------------------------------------------
-- 3.2 Indices para las consultas mas frecuentes
-- ---------------------------------------------------------------------
-- Agenda: citas de un veterinario en un rango de fechas (y validar choques de horario)
CREATE INDEX IDX_CITA_VET_FECHA     ON CITA (ID_VETERINARIO, FECHA_HORA);
-- Cola de atencion: WHERE ESTADO = 'EN_ESPERA'
CREATE INDEX IDX_CITA_ESTADO        ON CITA (ESTADO, FECHA_HORA);
-- Busqueda de propietarios por apellido sin importar mayusculas (indice basado en funcion)
CREATE INDEX IDX_PROPIETARIO_APELL  ON PROPIETARIO (UPPER(APELLIDOS));
-- Vacunas por vencer
CREATE INDEX IDX_VACUNACION_PROXIMA ON VACUNACION (PROXIMA_DOSIS);
-- Auditoria por tabla y fecha
CREATE INDEX IDX_AUDITORIA_TABLA    ON AUDITORIA (TABLA, FECHA);

-- Una alerta del mismo tipo y referencia solo una vez por dia (indice UNICO basado en funcion)
CREATE UNIQUE INDEX UX_ALERTA_DIA ON ALERTA (TIPO, ID_REFERENCIA, TRUNC(FECHA));

-- ---------------------------------------------------------------------
-- 3.3 Tipo coleccion: permite enviar una LISTA de numeros desde Java a PL/SQL
--     (diagnosticos y medicamentos de una atencion, en una sola llamada)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TYPE T_NUMEROS AS TABLE OF NUMBER;
/

-- Comprobar
SELECT index_name, table_name, uniqueness, index_type FROM user_indexes
 WHERE index_name NOT LIKE 'PK%' AND index_name NOT LIKE 'UK%' AND index_name NOT LIKE 'SYS%'
 ORDER BY table_name, index_name;
SELECT type_name, typecode FROM user_types;
