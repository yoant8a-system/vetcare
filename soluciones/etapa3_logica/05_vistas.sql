/* =====================================================================
   SOLUCION - 05 VISTAS
   Ejecutar como: VETERINARIA
   Las vistas guardan JOIN que se repiten; la app las consulta como tablas.
   (El ORDER BY va en la consulta que usa la vista, no en la vista.)
   ===================================================================== */

-- ---------------------------------------------------------------------
-- Mascota con su raza, especie, propietario, padres y edad calculada
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_MASCOTA_DETALLE AS
SELECT m.ID_MASCOTA,
       m.NOMBRE,
       m.SEXO,
       m.FECHA_NACIMIENTO,
       -- Edad legible: "3 a 2 m". MONTHS_BETWEEN da meses (con decimales) entre dos fechas
       CASE WHEN m.FECHA_NACIMIENTO IS NULL THEN NULL
            ELSE TRUNC(MONTHS_BETWEEN(SYSDATE, m.FECHA_NACIMIENTO) / 12) || ' a ' ||
                 MOD(TRUNC(MONTHS_BETWEEN(SYSDATE, m.FECHA_NACIMIENTO)), 12) || ' m'
       END AS EDAD,
       m.COLOR,
       m.ESTERILIZADO,
       m.ESTADO,
       m.ID_RAZA,
       r.NOMBRE AS RAZA,
       e.ID_ESPECIE,
       e.NOMBRE AS ESPECIE,
       p.ID_PROPIETARIO,
       p.APELLIDOS || ', ' || p.NOMBRES AS PROPIETARIO,
       p.DNI,
       p.TELEFONO,
       m.ID_PADRE,
       pa.NOMBRE AS PADRE,
       m.ID_MADRE,
       ma.NOMBRE AS MADRE,
       m.FECHA_REGISTRO
  FROM MASCOTA m
  JOIN RAZA r          ON r.ID_RAZA = m.ID_RAZA
  JOIN ESPECIE e       ON e.ID_ESPECIE = r.ID_ESPECIE
  JOIN PROPIETARIO p   ON p.ID_PROPIETARIO = m.ID_PROPIETARIO
  LEFT JOIN MASCOTA pa ON pa.ID_MASCOTA = m.ID_PADRE
  LEFT JOIN MASCOTA ma ON ma.ID_MASCOTA = m.ID_MADRE;


-- ---------------------------------------------------------------------
-- Cita con todos sus nombres (agenda, cola, pantalla)
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_CITA_DETALLE AS
SELECT c.ID_CITA,
       c.FECHA_HORA,
       c.DURACION_MIN,
       c.ORIGEN,
       c.MOTIVO,
       c.ESTADO,
       c.FECHA_LLEGADA,
       c.FECHA_LLAMADO,
       m.ID_MASCOTA,
       m.NOMBRE AS MASCOTA,
       e.NOMBRE AS ESPECIE,
       p.ID_PROPIETARIO,
       p.APELLIDOS || ', ' || p.NOMBRES AS PROPIETARIO,
       p.TELEFONO,
       c.ID_VETERINARIO,
       -- Ojo: NULL || ' ' || NULL da ' ' (un espacio), no NULL. Por eso el CASE
       CASE WHEN v.ID_VETERINARIO IS NOT NULL THEN v.NOMBRES || ' ' || v.APELLIDOS END AS VETERINARIO,
       c.ID_CONSULTORIO,
       co.NOMBRE AS CONSULTORIO,
       t.NIVEL_URGENCIA
  FROM CITA c
  JOIN MASCOTA m           ON m.ID_MASCOTA = c.ID_MASCOTA
  JOIN RAZA r              ON r.ID_RAZA = m.ID_RAZA
  JOIN ESPECIE e           ON e.ID_ESPECIE = r.ID_ESPECIE
  JOIN PROPIETARIO p       ON p.ID_PROPIETARIO = m.ID_PROPIETARIO
  LEFT JOIN VETERINARIO v  ON v.ID_VETERINARIO = c.ID_VETERINARIO
  LEFT JOIN CONSULTORIO co ON co.ID_CONSULTORIO = c.ID_CONSULTORIO
  LEFT JOIN TRIAJE t       ON t.ID_CITA = c.ID_CITA;


-- ---------------------------------------------------------------------
-- Cola de atencion: pacientes que llegaron y pasaron triaje, aun sin llamar.
-- El orden correcto es: NIVEL_URGENCIA (1 primero) y luego FECHA_LLEGADA.
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_COLA_ATENCION AS
SELECT c.ID_CITA,
       c.ID_MASCOTA,
       c.MASCOTA,
       c.ESPECIE,
       c.PROPIETARIO,
       c.ID_VETERINARIO,
       c.VETERINARIO,
       c.MOTIVO,
       c.ORIGEN,
       c.FECHA_LLEGADA,
       ROUND((SYSDATE - c.FECHA_LLEGADA) * 24 * 60) AS MINUTOS_ESPERA,
       t.NIVEL_URGENCIA,
       CASE t.NIVEL_URGENCIA
            WHEN 1 THEN 'Emergencia'
            WHEN 2 THEN 'Muy urgente'
            WHEN 3 THEN 'Urgente'
            WHEN 4 THEN 'Poco urgente'
            ELSE        'No urgente'
       END AS URGENCIA,
       t.PESO_KG,
       t.TEMPERATURA
  FROM VW_CITA_DETALLE c
  JOIN TRIAJE t ON t.ID_CITA = c.ID_CITA
 WHERE c.ESTADO = 'EN_ESPERA';


-- ---------------------------------------------------------------------
-- Pantalla de sala: pacientes llamados (EN_ATENCION) hoy
-- ---------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_PANTALLA AS
SELECT ID_CITA,
       MASCOTA,
       -- Solo el primer apellido del propietario (privacidad en pantalla publica)
       REGEXP_SUBSTR(PROPIETARIO, '^\S+') AS APELLIDO,
       CONSULTORIO,
       VETERINARIO,
       FECHA_LLAMADO,
       NIVEL_URGENCIA
  FROM VW_CITA_DETALLE
 WHERE ESTADO = 'EN_ATENCION'
   AND FECHA_LLAMADO >= TRUNC(SYSDATE);


-- ---------------------------------------------------------------------
-- VISTA MATERIALIZADA: a diferencia de una vista normal, GUARDA el resultado.
-- Sirve para resumenes pesados que no necesitan estar al segundo.
-- REFRESH COMPLETE ON DEMAND: se recalcula cuando alguien lo pide
-- (el job nocturno del archivo 09 llama a DBMS_MVIEW.REFRESH).
-- ---------------------------------------------------------------------
CREATE MATERIALIZED VIEW MV_ATENCIONES_MES
    BUILD IMMEDIATE
    REFRESH COMPLETE ON DEMAND
AS
SELECT TRUNC(a.FECHA_INICIO, 'MM') AS MES,
       e.NOMBRE AS ESPECIE,
       COUNT(*) AS ATENCIONES,
       COUNT(DISTINCT m.ID_MASCOTA) AS MASCOTAS
  FROM ATENCION a
  JOIN CITA c    ON c.ID_CITA = a.ID_CITA
  JOIN MASCOTA m ON m.ID_MASCOTA = c.ID_MASCOTA
  JOIN RAZA r    ON r.ID_RAZA = m.ID_RAZA
  JOIN ESPECIE e ON e.ID_ESPECIE = r.ID_ESPECIE
 GROUP BY TRUNC(a.FECHA_INICIO, 'MM'), e.NOMBRE;


-- Comprobar
SELECT view_name FROM user_views ORDER BY view_name;
SELECT mview_name, refresh_method, last_refresh_date FROM user_mviews;
