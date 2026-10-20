/* =====================================================================
   SOLUCION - CONSULTAS DE LA APLICACION (todas las sentencias de los *Repositorio.java)
   ---------------------------------------------------------------------
   - Cada bloque empieza con su ID: -- [PR-01] ...
   - Los parametros :nombre se pueden probar tal cual en SQL Developer (F9 pide sus valores).
   - Para usarlas en Java: copiar la sentencia (SIN el ; final) entre las triples comillas.
   - Con app.completar_con_solucion=true en config/db.properties, la app toma de ESTE
     archivo las sentencias que el equipo aun no escribio.
   ===================================================================== */

/* #####################################################################
   SistemaRepositorio  ->  src/main/java/com/vet/modulos/sistema/SistemaRepositorio.java
   ##################################################################### */
-- [US-01] Usuarios de la aplicacion con el nombre del veterinario vinculado (si tiene). Ordenar por usuario.
-- Columnas: ID_USUARIO, USUARIO, NOMBRE_COMPLETO, ROL, ACTIVO, ULTIMO_ACCESO, ID_VETERINARIO, VETERINARIO
SELECT u.ID_USUARIO, u.USUARIO, u.NOMBRE_COMPLETO, u.ROL, u.ACTIVO, u.ULTIMO_ACCESO, u.ID_VETERINARIO,
       v.NOMBRES || ' ' || v.APELLIDOS AS VETERINARIO
  FROM USUARIO u
  LEFT JOIN VETERINARIO v ON v.ID_VETERINARIO = u.ID_VETERINARIO
 ORDER BY u.USUARIO;
-- [US-02] Un usuario (SIN la clave).
-- Columnas: ID_USUARIO, USUARIO, NOMBRE_COMPLETO, ROL, ACTIVO, ID_VETERINARIO
-- Parametros: :id
SELECT ID_USUARIO, USUARIO, NOMBRE_COMPLETO, ROL, ACTIVO, ID_VETERINARIO FROM USUARIO WHERE ID_USUARIO = :id;
-- [US-03] Actualizar datos del usuario (la clave se cambia con PKG_SEGURIDAD).  Parametros: :nombre, :rol, :id_veterinario, :activo, :id
UPDATE USUARIO
   SET NOMBRE_COMPLETO = :nombre, ROL = :rol, ID_VETERINARIO = :id_veterinario, ACTIVO = :activo
 WHERE ID_USUARIO = :id;
-- [AL-01] Ultimas 100 alertas: primero las NO leidas, luego por fecha (mas reciente primero).
-- Columnas: ID_ALERTA, TIPO, ID_REFERENCIA, MENSAJE, FECHA, LEIDA
SELECT ID_ALERTA, TIPO, ID_REFERENCIA, MENSAJE, FECHA, LEIDA
  FROM ALERTA
 ORDER BY LEIDA, FECHA DESC, ID_ALERTA DESC
 FETCH FIRST 100 ROWS ONLY;
-- [AL-02] Marcar una alerta como leida.  Parametros: :id
UPDATE ALERTA SET LEIDA = 'S' WHERE ID_ALERTA = :id;
-- [AL-03] Marcar TODAS las alertas como leidas.
UPDATE ALERTA SET LEIDA = 'S' WHERE LEIDA = 'N';
-- [AL-04] Cantidad de alertas sin leer (un numero; se muestra en la campanita).
SELECT COUNT(*) FROM ALERTA WHERE LEIDA = 'N';
-- [AU-01] Ultimos 200 registros de auditoria, opcionalmente de una tabla (:tabla NULL = todas).
-- Columnas: ID_AUDITORIA, FECHA, TABLA, OPERACION, ID_REGISTRO, DETALLE, USUARIO_APP, USUARIO_BD
-- Parametros: :tabla
SELECT ID_AUDITORIA, FECHA, TABLA, OPERACION, ID_REGISTRO, DETALLE, USUARIO_APP, USUARIO_BD
  FROM AUDITORIA
 WHERE :tabla IS NULL OR TABLA = :tabla
 ORDER BY ID_AUDITORIA DESC
 FETCH FIRST 200 ROWS ONLY;
-- [DA-01] Indicadores del tablero en UNA fila (pista: varias subconsultas escalares FROM DUAL).
-- Columnas: CITAS_HOY (de hoy, sin contar CANCELADAS), EN_ESPERA, EN_ATENCION,
--           ATENCIONES_MES (desde el dia 1 del mes actual), MASCOTAS (ACTIVAS),
--           TRATAMIENTOS (EN_CURSO), STOCK_BAJO (medicamentos activos con stock <= minimo)
SELECT (SELECT COUNT(*) FROM CITA
         WHERE FECHA_HORA >= TRUNC(SYSDATE) AND FECHA_HORA < TRUNC(SYSDATE) + 1
           AND ESTADO <> 'CANCELADA') AS CITAS_HOY,
       (SELECT COUNT(*) FROM CITA WHERE ESTADO = 'EN_ESPERA') AS EN_ESPERA,
       (SELECT COUNT(*) FROM CITA WHERE ESTADO = 'EN_ATENCION') AS EN_ATENCION,
       (SELECT COUNT(*) FROM ATENCION WHERE FECHA_INICIO >= TRUNC(SYSDATE, 'MM')) AS ATENCIONES_MES,
       (SELECT COUNT(*) FROM MASCOTA WHERE ESTADO = 'ACTIVO') AS MASCOTAS,
       (SELECT COUNT(*) FROM TRATAMIENTO WHERE ESTADO = 'EN_CURSO') AS TRATAMIENTOS,
       (SELECT COUNT(*) FROM MEDICAMENTO WHERE ACTIVO = 'S' AND STOCK_ACTUAL <= STOCK_MINIMO) AS STOCK_BAJO
  FROM DUAL;
-- [DA-02] Atenciones por dia de los ultimos 14 dias, INCLUYENDO los dias con 0
-- (pista: generar los 14 dias con CONNECT BY LEVEL y hacer LEFT JOIN con ATENCION).
-- Columnas: DIA, TOTAL      (14 filas, del mas antiguo al de hoy)
SELECT d.DIA, COUNT(a.ID_ATENCION) AS TOTAL
  FROM (SELECT TRUNC(SYSDATE) - LEVEL + 1 AS DIA FROM DUAL CONNECT BY LEVEL <= 14) d
  LEFT JOIN ATENCION a ON a.FECHA_INICIO >= d.DIA AND a.FECHA_INICIO < d.DIA + 1
 GROUP BY d.DIA
 ORDER BY d.DIA;
-- [DA-03] Atenciones de los ultimos 30 dias agrupadas por especie (de mayor a menor).
-- Columnas: ESPECIE, TOTAL
SELECT e.NOMBRE AS ESPECIE, COUNT(*) AS TOTAL
  FROM ATENCION a
  JOIN CITA c    ON c.ID_CITA = a.ID_CITA
  JOIN MASCOTA m ON m.ID_MASCOTA = c.ID_MASCOTA
  JOIN RAZA r    ON r.ID_RAZA = m.ID_RAZA
  JOIN ESPECIE e ON e.ID_ESPECIE = r.ID_ESPECIE
 WHERE a.FECHA_INICIO >= TRUNC(SYSDATE) - 30
 GROUP BY e.NOMBRE
 ORDER BY TOTAL DESC;
-- [DA-04] Proximas 8 citas de HOY que siguen activas (PROGRAMADA, EN_ESPERA o EN_ATENCION), por hora.
-- Columnas: ID_CITA, FECHA_HORA, MASCOTA, PROPIETARIO, VETERINARIO, MOTIVO, ESTADO
SELECT ID_CITA, FECHA_HORA, MASCOTA, PROPIETARIO, VETERINARIO, MOTIVO, ESTADO
  FROM VW_CITA_DETALLE
 WHERE FECHA_HORA >= TRUNC(SYSDATE) AND FECHA_HORA < TRUNC(SYSDATE) + 1
   AND ESTADO IN ('PROGRAMADA', 'EN_ESPERA', 'EN_ATENCION')
 ORDER BY FECHA_HORA
 FETCH FIRST 8 ROWS ONLY;

/* #####################################################################
   PropietarioRepositorio  ->  src/main/java/com/vet/modulos/propietario/PropietarioRepositorio.java
   ##################################################################### */
-- [PR-01] Buscar propietarios por DNI (empieza con), nombres o apellidos (contiene, sin importar mayusculas).
-- Si :texto es NULL, devuelve todos. Ordenar por apellidos y nombres. Maximo 200 filas.
-- Columnas: ID_PROPIETARIO, DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL,
--           MASCOTAS (cantidad de mascotas del propietario: subconsulta con COUNT)
-- Parametros: :texto
SELECT p.ID_PROPIETARIO, p.DNI, p.NOMBRES, p.APELLIDOS, p.TELEFONO, p.EMAIL,
       (SELECT COUNT(*) FROM MASCOTA m WHERE m.ID_PROPIETARIO = p.ID_PROPIETARIO) AS MASCOTAS
  FROM PROPIETARIO p
 WHERE :texto IS NULL
    OR p.DNI LIKE :texto || '%'
    OR UPPER(p.APELLIDOS) LIKE '%' || UPPER(:texto) || '%'
    OR UPPER(p.NOMBRES) LIKE '%' || UPPER(:texto) || '%'
 ORDER BY p.APELLIDOS, p.NOMBRES
 FETCH FIRST 200 ROWS ONLY;
-- [PR-02] Un propietario por su ID.
-- Columnas: ID_PROPIETARIO, DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL, DIRECCION, FECHA_REGISTRO
-- Parametros: :id
SELECT ID_PROPIETARIO, DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL, DIRECCION, FECHA_REGISTRO
  FROM PROPIETARIO
 WHERE ID_PROPIETARIO = :id;
-- [PR-03] Registrar propietario (el ID es IDENTITY y FECHA_REGISTRO tiene DEFAULT: no se envian).
-- Parametros: :dni, :nombres, :apellidos, :telefono, :email, :direccion
INSERT INTO PROPIETARIO (DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL, DIRECCION)
VALUES (:dni, :nombres, :apellidos, :telefono, :email, :direccion);
-- [PR-04] Actualizar propietario.
-- Parametros: :dni, :nombres, :apellidos, :telefono, :email, :direccion, :id
UPDATE PROPIETARIO
   SET DNI = :dni, NOMBRES = :nombres, APELLIDOS = :apellidos,
       TELEFONO = :telefono, EMAIL = :email, DIRECCION = :direccion
 WHERE ID_PROPIETARIO = :id;
-- [PR-05] Eliminar propietario. Si tiene mascotas, Oracle lo impide (FK -> ORA-02292).
-- Parametros: :id
DELETE FROM PROPIETARIO WHERE ID_PROPIETARIO = :id;

/* #####################################################################
   MascotaRepositorio  ->  src/main/java/com/vet/modulos/mascota/MascotaRepositorio.java
   ##################################################################### */
-- [MA-01] Buscar mascotas por nombre de la mascota, nombre del propietario (contiene) o DNI (empieza con),
-- y opcionalmente por especie. Parametros NULL = sin filtro. Ordenar por nombre. Maximo 200 filas.
-- Columnas: ID_MASCOTA, NOMBRE, ESPECIE, RAZA, SEXO, EDAD, PROPIETARIO, TELEFONO, ESTADO
-- Parametros: :texto, :id_especie
SELECT ID_MASCOTA, NOMBRE, ESPECIE, RAZA, SEXO, EDAD, PROPIETARIO, TELEFONO, ESTADO
  FROM VW_MASCOTA_DETALLE
 WHERE (:texto IS NULL
        OR UPPER(NOMBRE) LIKE '%' || UPPER(:texto) || '%'
        OR UPPER(PROPIETARIO) LIKE '%' || UPPER(:texto) || '%'
        OR DNI LIKE :texto || '%')
   AND (:id_especie IS NULL OR ID_ESPECIE = :id_especie)
 ORDER BY NOMBRE
 FETCH FIRST 200 ROWS ONLY;
-- [MA-02] Una mascota con todos sus datos de la vista VW_MASCOTA_DETALLE.
-- Columnas: todas las de la vista (ID_MASCOTA, NOMBRE, SEXO, FECHA_NACIMIENTO, EDAD, COLOR, ESTERILIZADO,
--           ESTADO, ID_RAZA, RAZA, ID_ESPECIE, ESPECIE, ID_PROPIETARIO, PROPIETARIO, DNI, TELEFONO,
--           ID_PADRE, PADRE, ID_MADRE, MADRE, FECHA_REGISTRO)
-- Parametros: :id
SELECT * FROM VW_MASCOTA_DETALLE WHERE ID_MASCOTA = :id;
-- [MA-03] Mascotas de un propietario, ordenadas por nombre.
-- Columnas: ID_MASCOTA, NOMBRE, ESPECIE, RAZA, SEXO, EDAD, ESTADO
-- Parametros: :id_propietario
SELECT ID_MASCOTA, NOMBRE, ESPECIE, RAZA, SEXO, EDAD, ESTADO
  FROM VW_MASCOTA_DETALLE
 WHERE ID_PROPIETARIO = :id_propietario
 ORDER BY NOMBRE;
-- [MA-04] Registrar mascota. (El trigger TRG_MASCOTA_PADRES valida a los padres.)
-- Parametros: :id_propietario, :id_raza, :nombre, :sexo, :fecha_nacimiento, :color, :esterilizado,
--             :id_padre, :id_madre
INSERT INTO MASCOTA (ID_PROPIETARIO, ID_RAZA, NOMBRE, SEXO, FECHA_NACIMIENTO, COLOR,
                     ESTERILIZADO, ID_PADRE, ID_MADRE)
VALUES (:id_propietario, :id_raza, :nombre, :sexo, :fecha_nacimiento, :color,
        :esterilizado, :id_padre, :id_madre);
-- [MA-05] Actualizar mascota (incluye ESTADO: ACTIVO / FALLECIDO).
-- Parametros: :id_raza, :nombre, :sexo, :fecha_nacimiento, :color, :esterilizado, :id_padre, :id_madre,
--             :estado, :id
UPDATE MASCOTA
   SET ID_RAZA = :id_raza, NOMBRE = :nombre, SEXO = :sexo, FECHA_NACIMIENTO = :fecha_nacimiento,
       COLOR = :color, ESTERILIZADO = :esterilizado, ID_PADRE = :id_padre, ID_MADRE = :id_madre,
       ESTADO = :estado
 WHERE ID_MASCOTA = :id;
-- [MA-06] Eliminar mascota (falla con ORA-02292 si ya tiene citas o vacunas: es lo correcto).
-- Parametros: :id
DELETE FROM MASCOTA WHERE ID_MASCOTA = :id;
-- [MA-07] Posibles padres/madres: TODAS las mascotas excepto la que se esta editando (:id_mascota puede ser NULL).
-- La pagina luego filtra por especie y sexo.
-- Columnas: ID_MASCOTA, ETIQUETA (ej. "Max (Labrador Retriever, Perez Gonzales)"), SEXO, ID_ESPECIE
-- Parametros: :id_mascota
SELECT m.ID_MASCOTA,
       m.NOMBRE || ' (' || r.NOMBRE || ', ' || p.APELLIDOS || ')' AS ETIQUETA,
       m.SEXO, r.ID_ESPECIE
  FROM MASCOTA m
  JOIN RAZA r        ON r.ID_RAZA = m.ID_RAZA
  JOIN PROPIETARIO p ON p.ID_PROPIETARIO = m.ID_PROPIETARIO
 WHERE :id_mascota IS NULL OR m.ID_MASCOTA <> :id_mascota
 ORDER BY m.NOMBRE;
-- [MA-08] Todas las razas con su especie, ordenadas por especie y raza (para el combo agrupado).
-- Columnas: ID_RAZA, NOMBRE, ID_ESPECIE, ESPECIE
SELECT r.ID_RAZA, r.NOMBRE, e.ID_ESPECIE, e.NOMBRE AS ESPECIE
  FROM RAZA r
  JOIN ESPECIE e ON e.ID_ESPECIE = r.ID_ESPECIE
 ORDER BY e.NOMBRE, r.NOMBRE;
-- [MA-09] Especies ordenadas por nombre (para filtros).
-- Columnas: ID_ESPECIE, NOMBRE
SELECT ID_ESPECIE, NOMBRE FROM ESPECIE ORDER BY NOMBRE;

/* #####################################################################
   CatalogoRepositorio  ->  src/main/java/com/vet/modulos/catalogo/CatalogoRepositorio.java
   ##################################################################### */
-- [CA-01] Especies con la cantidad de razas de cada una, ordenadas por nombre.
-- Columnas: ID_ESPECIE, NOMBRE, RAZAS
SELECT e.ID_ESPECIE, e.NOMBRE,
       (SELECT COUNT(*) FROM RAZA r WHERE r.ID_ESPECIE = e.ID_ESPECIE) AS RAZAS
  FROM ESPECIE e
 ORDER BY e.NOMBRE;
-- [CA-02] Registrar especie.  Parametros: :nombre
INSERT INTO ESPECIE (NOMBRE) VALUES (:nombre);
-- [CA-03] Eliminar especie.  Parametros: :id
DELETE FROM ESPECIE WHERE ID_ESPECIE = :id;
-- [CA-04] Razas con su especie y la cantidad de mascotas de esa raza. Ordenar por especie y raza.
-- Columnas: ID_RAZA, NOMBRE, ESPECIE, MASCOTAS
SELECT r.ID_RAZA, r.NOMBRE, e.NOMBRE AS ESPECIE,
       (SELECT COUNT(*) FROM MASCOTA m WHERE m.ID_RAZA = r.ID_RAZA) AS MASCOTAS
  FROM RAZA r
  JOIN ESPECIE e ON e.ID_ESPECIE = r.ID_ESPECIE
 ORDER BY e.NOMBRE, r.NOMBRE;
-- [CA-05] Registrar raza.  Parametros: :id_especie, :nombre
INSERT INTO RAZA (ID_ESPECIE, NOMBRE) VALUES (:id_especie, :nombre);
-- [CA-06] Eliminar raza.  Parametros: :id
DELETE FROM RAZA WHERE ID_RAZA = :id;
-- [CA-07] Especialidades con la cantidad de veterinarios que la tienen.
-- Columnas: ID_ESPECIALIDAD, NOMBRE, VETERINARIOS
SELECT e.ID_ESPECIALIDAD, e.NOMBRE,
       (SELECT COUNT(*) FROM VETERINARIO_ESPECIALIDAD ve WHERE ve.ID_ESPECIALIDAD = e.ID_ESPECIALIDAD) AS VETERINARIOS
  FROM ESPECIALIDAD e
 ORDER BY e.NOMBRE;
-- [CA-08] Registrar especialidad.  Parametros: :nombre
INSERT INTO ESPECIALIDAD (NOMBRE) VALUES (:nombre);
-- [CA-09] Eliminar especialidad.  Parametros: :id
DELETE FROM ESPECIALIDAD WHERE ID_ESPECIALIDAD = :id;
-- [CA-10] Consultorios ordenados por nombre.
-- Columnas: ID_CONSULTORIO, NOMBRE, ACTIVO
SELECT ID_CONSULTORIO, NOMBRE, ACTIVO FROM CONSULTORIO ORDER BY NOMBRE;
-- [CA-11] Registrar consultorio.  Parametros: :nombre
INSERT INTO CONSULTORIO (NOMBRE) VALUES (:nombre);
-- [CA-12] Activar/desactivar: si ACTIVO es 'S' pasa a 'N' y viceversa (un solo UPDATE con CASE).  Parametros: :id
UPDATE CONSULTORIO
   SET ACTIVO = CASE ACTIVO WHEN 'S' THEN 'N' ELSE 'S' END
 WHERE ID_CONSULTORIO = :id;
-- [CA-13] Catalogo de diagnosticos con el nombre de la especie ('Todas' si ID_ESPECIE es NULL). Ordenar por codigo.
-- Columnas: ID_DIAGNOSTICO, CODIGO, NOMBRE, CATEGORIA, ESPECIE
SELECT d.ID_DIAGNOSTICO, d.CODIGO, d.NOMBRE, d.CATEGORIA, NVL(e.NOMBRE, 'Todas') AS ESPECIE
  FROM DIAGNOSTICO d
  LEFT JOIN ESPECIE e ON e.ID_ESPECIE = d.ID_ESPECIE
 ORDER BY d.CODIGO;
-- [CA-14] Registrar diagnostico.  Parametros: :codigo, :nombre, :categoria, :id_especie (puede ser NULL)
INSERT INTO DIAGNOSTICO (CODIGO, NOMBRE, CATEGORIA, ID_ESPECIE)
VALUES (:codigo, :nombre, :categoria, :id_especie);
-- [CA-15] Eliminar diagnostico.  Parametros: :id
DELETE FROM DIAGNOSTICO WHERE ID_DIAGNOSTICO = :id;
-- [CA-16] Vacunas con su especie. Ordenar por especie y nombre.
-- Columnas: ID_VACUNA, NOMBRE, ESPECIE, REFUERZO_DIAS
SELECT v.ID_VACUNA, v.NOMBRE, e.NOMBRE AS ESPECIE, v.REFUERZO_DIAS
  FROM VACUNA v
  JOIN ESPECIE e ON e.ID_ESPECIE = v.ID_ESPECIE
 ORDER BY e.NOMBRE, v.NOMBRE;
-- [CA-17] Registrar vacuna.  Parametros: :nombre, :id_especie, :refuerzo_dias (NULL = dosis unica)
INSERT INTO VACUNA (NOMBRE, ID_ESPECIE, REFUERZO_DIAS) VALUES (:nombre, :id_especie, :refuerzo_dias);
-- [CA-18] Eliminar vacuna.  Parametros: :id
DELETE FROM VACUNA WHERE ID_VACUNA = :id;

/* #####################################################################
   VeterinarioRepositorio  ->  src/main/java/com/vet/modulos/veterinario/VeterinarioRepositorio.java
   ##################################################################### */
-- [VE-01] Veterinarios ordenados por apellidos, con sus especialidades en UNA columna de texto
-- separadas por coma (pista: LISTAGG en una subconsulta) y cuantos bloques de horario tienen.
-- Columnas: ID_VETERINARIO, CMVP, NOMBRES, APELLIDOS, TELEFONO, EMAIL, ACTIVO, ESPECIALIDADES, BLOQUES_HORARIO
SELECT v.ID_VETERINARIO, v.CMVP, v.NOMBRES, v.APELLIDOS, v.TELEFONO, v.EMAIL, v.ACTIVO,
       (SELECT LISTAGG(e.NOMBRE, ', ') WITHIN GROUP (ORDER BY e.NOMBRE)
          FROM VETERINARIO_ESPECIALIDAD ve
          JOIN ESPECIALIDAD e ON e.ID_ESPECIALIDAD = ve.ID_ESPECIALIDAD
         WHERE ve.ID_VETERINARIO = v.ID_VETERINARIO) AS ESPECIALIDADES,
       (SELECT COUNT(*) FROM HORARIO_VETERINARIO h WHERE h.ID_VETERINARIO = v.ID_VETERINARIO) AS BLOQUES_HORARIO
  FROM VETERINARIO v
 ORDER BY v.APELLIDOS, v.NOMBRES;
-- [VE-02] Un veterinario por ID.
-- Columnas: ID_VETERINARIO, CMVP, NOMBRES, APELLIDOS, TELEFONO, EMAIL, ACTIVO
-- Parametros: :id
SELECT ID_VETERINARIO, CMVP, NOMBRES, APELLIDOS, TELEFONO, EMAIL, ACTIVO
  FROM VETERINARIO
 WHERE ID_VETERINARIO = :id;
-- [VE-03] Registrar veterinario.  Parametros: :cmvp, :nombres, :apellidos, :telefono, :email
INSERT INTO VETERINARIO (CMVP, NOMBRES, APELLIDOS, TELEFONO, EMAIL)
VALUES (:cmvp, :nombres, :apellidos, :telefono, :email);
-- [VE-04] Actualizar veterinario.  Parametros: :cmvp, :nombres, :apellidos, :telefono, :email, :activo, :id
UPDATE VETERINARIO
   SET CMVP = :cmvp, NOMBRES = :nombres, APELLIDOS = :apellidos,
       TELEFONO = :telefono, EMAIL = :email, ACTIVO = :activo
 WHERE ID_VETERINARIO = :id;
-- [VE-05] IDs de las especialidades de un veterinario.
-- Columnas: ID_ESPECIALIDAD     Parametros: :id
SELECT ID_ESPECIALIDAD FROM VETERINARIO_ESPECIALIDAD WHERE ID_VETERINARIO = :id;
-- [VE-06] Quitar TODAS las especialidades de un veterinario.  Parametros: :id
DELETE FROM VETERINARIO_ESPECIALIDAD WHERE ID_VETERINARIO = :id;
-- [VE-07] Asignar una especialidad a un veterinario.  Parametros: :id_veterinario, :id_especialidad
INSERT INTO VETERINARIO_ESPECIALIDAD (ID_VETERINARIO, ID_ESPECIALIDAD)
VALUES (:id_veterinario, :id_especialidad);
-- [VE-08] Horario de un veterinario, ordenado por dia y hora de inicio.
-- Columnas: ID_HORARIO, DIA_SEMANA, HORA_INICIO, HORA_FIN     Parametros: :id
SELECT ID_HORARIO, DIA_SEMANA, HORA_INICIO, HORA_FIN
  FROM HORARIO_VETERINARIO
 WHERE ID_VETERINARIO = :id
 ORDER BY DIA_SEMANA, HORA_INICIO;
-- [VE-09] Agregar un bloque de horario.  Parametros: :id_veterinario, :dia_semana, :hora_inicio, :hora_fin
INSERT INTO HORARIO_VETERINARIO (ID_VETERINARIO, DIA_SEMANA, HORA_INICIO, HORA_FIN)
VALUES (:id_veterinario, :dia_semana, :hora_inicio, :hora_fin);
-- [VE-10] Eliminar un bloque de horario.  Parametros: :id_horario
DELETE FROM HORARIO_VETERINARIO WHERE ID_HORARIO = :id_horario;
-- [VE-11] Veterinarios ACTIVOS para combos, ordenados por apellidos.
-- Columnas: ID_VETERINARIO, NOMBRE (nombres y apellidos juntos)
SELECT ID_VETERINARIO, NOMBRES || ' ' || APELLIDOS AS NOMBRE
  FROM VETERINARIO
 WHERE ACTIVO = 'S'
 ORDER BY APELLIDOS, NOMBRES;

/* #####################################################################
   CitaRepositorio  ->  src/main/java/com/vet/modulos/cita/CitaRepositorio.java
   ##################################################################### */
-- [CI-01] Agenda de un dia (desde las 00:00 de :fecha hasta antes de las 00:00 del dia siguiente),
-- opcionalmente de un veterinario (:id_veterinario NULL = todos). Usar VW_CITA_DETALLE. Ordenar por hora.
-- Columnas: ID_CITA, FECHA_HORA, DURACION_MIN, ORIGEN, MOTIVO, ESTADO, ID_MASCOTA, MASCOTA, ESPECIE,
--           PROPIETARIO, TELEFONO, VETERINARIO, CONSULTORIO, NIVEL_URGENCIA
-- Parametros: :fecha, :id_veterinario
SELECT ID_CITA, FECHA_HORA, DURACION_MIN, ORIGEN, MOTIVO, ESTADO, ID_MASCOTA, MASCOTA, ESPECIE,
       PROPIETARIO, TELEFONO, VETERINARIO, CONSULTORIO, NIVEL_URGENCIA
  FROM VW_CITA_DETALLE
 WHERE FECHA_HORA >= TRUNC(:fecha)
   AND FECHA_HORA <  TRUNC(:fecha) + 1
   AND (:id_veterinario IS NULL OR ID_VETERINARIO = :id_veterinario)
 ORDER BY FECHA_HORA;
-- [CI-02] Una cita con todos los datos de VW_CITA_DETALLE.
-- Parametros: :id
SELECT * FROM VW_CITA_DETALLE WHERE ID_CITA = :id;
-- [CI-03] Ultimas 50 citas de una mascota (la mas reciente primero).
-- Columnas: ID_CITA, FECHA_HORA, MOTIVO, ESTADO, VETERINARIO, ORIGEN
-- Parametros: :id_mascota
SELECT ID_CITA, FECHA_HORA, MOTIVO, ESTADO, VETERINARIO, ORIGEN
  FROM VW_CITA_DETALLE
 WHERE ID_MASCOTA = :id_mascota
 ORDER BY FECHA_HORA DESC
 FETCH FIRST 50 ROWS ONLY;
-- [CI-04] Mascotas ACTIVAS para el combo de "nueva cita", ordenadas por nombre.
-- Columnas: ID_MASCOTA, ETIQUETA (ej. "Firulais - Chavez Rios, Luis (Perro)")
SELECT ID_MASCOTA, NOMBRE || ' - ' || PROPIETARIO || ' (' || ESPECIE || ')' AS ETIQUETA
  FROM VW_MASCOTA_DETALLE
 WHERE ESTADO = 'ACTIVO'
 ORDER BY NOMBRE;

/* #####################################################################
   AtencionRepositorio  ->  src/main/java/com/vet/modulos/atencion/AtencionRepositorio.java
   ##################################################################### */
-- [AT-01] Cola de atencion: pacientes EN_ESPERA con su triaje (vista VW_COLA_ATENCION).
-- Orden: primero el NIVEL_URGENCIA mas bajo (1 = emergencia) y, a igual urgencia, el que llego antes.
-- Columnas: ID_CITA, MASCOTA, ESPECIE, PROPIETARIO, ID_VETERINARIO, VETERINARIO, MOTIVO, ORIGEN,
--           FECHA_LLEGADA, MINUTOS_ESPERA, NIVEL_URGENCIA, URGENCIA, PESO_KG, TEMPERATURA
SELECT ID_CITA, MASCOTA, ESPECIE, PROPIETARIO, ID_VETERINARIO, VETERINARIO, MOTIVO, ORIGEN,
       FECHA_LLEGADA, MINUTOS_ESPERA, NIVEL_URGENCIA, URGENCIA, PESO_KG, TEMPERATURA
  FROM VW_COLA_ATENCION
 ORDER BY NIVEL_URGENCIA, FECHA_LLEGADA;
-- [AT-02] Paciente que el veterinario tiene EN_ATENCION ahora (0 o 1 fila), con su triaje y datos de la mascota.
-- Pista: VW_CITA_DETALLE + TRIAJE + VW_MASCOTA_DETALLE.
-- Columnas: ID_CITA, ID_MASCOTA, MASCOTA, ESPECIE, ID_ESPECIE, RAZA, SEXO, EDAD, PROPIETARIO, TELEFONO,
--           MOTIVO, CONSULTORIO, FECHA_LLAMADO, NIVEL_URGENCIA, PESO_KG, TEMPERATURA, FREC_CARDIACA,
--           FREC_RESPIRATORIA, OBS_TRIAJE (= TRIAJE.OBSERVACIONES)
-- Parametros: :id_veterinario
SELECT c.ID_CITA, c.ID_MASCOTA, c.MASCOTA, c.ESPECIE, m.ID_ESPECIE, m.RAZA, m.SEXO, m.EDAD,
       c.PROPIETARIO, c.TELEFONO, c.MOTIVO, c.CONSULTORIO, c.FECHA_LLAMADO, c.NIVEL_URGENCIA,
       t.PESO_KG, t.TEMPERATURA, t.FREC_CARDIACA, t.FREC_RESPIRATORIA, t.OBSERVACIONES AS OBS_TRIAJE
  FROM VW_CITA_DETALLE c
  JOIN TRIAJE t             ON t.ID_CITA = c.ID_CITA
  JOIN VW_MASCOTA_DETALLE m ON m.ID_MASCOTA = c.ID_MASCOTA
 WHERE c.ESTADO = 'EN_ATENCION'
   AND c.ID_VETERINARIO = :id_veterinario;
-- [AT-03] Diagnosticos que aplican a una especie: los de esa especie + los generales (ID_ESPECIE NULL).
-- Ordenar por categoria y nombre.
-- Columnas: ID_DIAGNOSTICO, CODIGO, NOMBRE, CATEGORIA
-- Parametros: :id_especie
SELECT ID_DIAGNOSTICO, CODIGO, NOMBRE, CATEGORIA
  FROM DIAGNOSTICO
 WHERE ID_ESPECIE IS NULL OR ID_ESPECIE = :id_especie
 ORDER BY CATEGORIA, NOMBRE;
-- [AT-04] Medicamentos activos que tienen stock (> 0), ordenados por nombre.
-- Columnas: ID_MEDICAMENTO, NOMBRE, PRESENTACION, UNIDAD, STOCK_ACTUAL
SELECT ID_MEDICAMENTO, NOMBRE, PRESENTACION, UNIDAD, STOCK_ACTUAL
  FROM MEDICAMENTO
 WHERE ACTIVO = 'S' AND STOCK_ACTUAL > 0
 ORDER BY NOMBRE, PRESENTACION;
-- [AT-05] Consultorios activos y LIBRES (sin ninguna cita EN_ATENCION en ellos). Pista: NOT EXISTS.
-- Columnas: ID_CONSULTORIO, NOMBRE
SELECT co.ID_CONSULTORIO, co.NOMBRE
  FROM CONSULTORIO co
 WHERE co.ACTIVO = 'S'
   AND NOT EXISTS (SELECT 1 FROM CITA c
                    WHERE c.ID_CONSULTORIO = co.ID_CONSULTORIO AND c.ESTADO = 'EN_ATENCION')
 ORDER BY co.NOMBRE;
-- [AT-06] Atenciones que el veterinario registro HOY (la mas reciente primero), con su duracion en minutos.
-- Columnas: ID_ATENCION, ID_MASCOTA, MASCOTA, PROPIETARIO, FECHA_INICIO, FECHA_FIN, MINUTOS
-- Parametros: :id_veterinario
SELECT a.ID_ATENCION, c.ID_MASCOTA, c.MASCOTA, c.PROPIETARIO, a.FECHA_INICIO, a.FECHA_FIN,
       ROUND((a.FECHA_FIN - a.FECHA_INICIO) * 24 * 60) AS MINUTOS
  FROM ATENCION a
  JOIN VW_CITA_DETALLE c ON c.ID_CITA = a.ID_CITA
 WHERE a.ID_VETERINARIO = :id_veterinario
   AND a.FECHA_INICIO >= TRUNC(SYSDATE)
 ORDER BY a.FECHA_INICIO DESC;

/* #####################################################################
   PantallaRepositorio  ->  src/main/java/com/vet/modulos/pantalla/PantallaRepositorio.java
   ##################################################################### */
-- [PA-01] Ultimos 6 pacientes llamados hoy (vista VW_PANTALLA), el mas reciente primero.
-- Columnas: ID_CITA, MASCOTA, APELLIDO, CONSULTORIO, VETERINARIO, FECHA_LLAMADO, NIVEL_URGENCIA
SELECT ID_CITA, MASCOTA, APELLIDO, CONSULTORIO, VETERINARIO, FECHA_LLAMADO, NIVEL_URGENCIA
  FROM VW_PANTALLA
 ORDER BY FECHA_LLAMADO DESC
 FETCH FIRST 6 ROWS ONLY;
-- [PA-02] Los proximos 10 de la cola (mismo orden que AT-01).
-- Columnas: MASCOTA, NIVEL_URGENCIA
SELECT MASCOTA, NIVEL_URGENCIA
  FROM VW_COLA_ATENCION
 ORDER BY NIVEL_URGENCIA, FECHA_LLEGADA
 FETCH FIRST 10 ROWS ONLY;
-- [PA-03] Cuantos pacientes hay en la cola (un numero).
SELECT COUNT(*) FROM VW_COLA_ATENCION;

/* #####################################################################
   TratamientoRepositorio  ->  src/main/java/com/vet/modulos/tratamiento/TratamientoRepositorio.java
   ##################################################################### */
-- [TR-01] Tratamientos filtrados por estado (:estado NULL = todos), el mas reciente primero. Maximo 200.
-- Para llegar a la mascota: TRATAMIENTO -> ATENCION -> CITA -> MASCOTA.
-- Columnas: ID_TRATAMIENTO, ID_MASCOTA, MASCOTA, DESCRIPCION, FECHA_INICIO, SESIONES_PROGRAMADAS,
--           FRECUENCIA_DIAS, ESTADO, REALIZADAS (sesiones hechas: subconsulta COUNT),
--           AVANCE (porcentaje: se puede llamar a PKG_TRATAMIENTO.FN_AVANCE dentro del SELECT)
-- Parametros: :estado
SELECT t.ID_TRATAMIENTO, c.ID_MASCOTA, m.NOMBRE AS MASCOTA, t.DESCRIPCION, t.FECHA_INICIO,
       t.SESIONES_PROGRAMADAS, t.FRECUENCIA_DIAS, t.ESTADO,
       (SELECT COUNT(*) FROM SESION_TRATAMIENTO s WHERE s.ID_TRATAMIENTO = t.ID_TRATAMIENTO) AS REALIZADAS,
       PKG_TRATAMIENTO.FN_AVANCE(t.ID_TRATAMIENTO) AS AVANCE
  FROM TRATAMIENTO t
  JOIN ATENCION a ON a.ID_ATENCION = t.ID_ATENCION
  JOIN CITA c     ON c.ID_CITA = a.ID_CITA
  JOIN MASCOTA m  ON m.ID_MASCOTA = c.ID_MASCOTA
 WHERE :estado IS NULL OR t.ESTADO = :estado
 ORDER BY t.FECHA_INICIO DESC, t.ID_TRATAMIENTO DESC
 FETCH FIRST 200 ROWS ONLY;
-- [TR-02] Un tratamiento con su mascota, propietario y el veterinario que lo indico.
-- Columnas: ID_TRATAMIENTO, ID_MASCOTA, MASCOTA, PROPIETARIO, VETERINARIO, DESCRIPCION, FECHA_INICIO,
--           SESIONES_PROGRAMADAS, FRECUENCIA_DIAS, ESTADO, AVANCE
-- Parametros: :id
SELECT t.ID_TRATAMIENTO, m.ID_MASCOTA, m.NOMBRE AS MASCOTA,
       p.APELLIDOS || ', ' || p.NOMBRES AS PROPIETARIO,
       v.NOMBRES || ' ' || v.APELLIDOS AS VETERINARIO,
       t.DESCRIPCION, t.FECHA_INICIO, t.SESIONES_PROGRAMADAS, t.FRECUENCIA_DIAS, t.ESTADO,
       PKG_TRATAMIENTO.FN_AVANCE(t.ID_TRATAMIENTO) AS AVANCE
  FROM TRATAMIENTO t
  JOIN ATENCION a    ON a.ID_ATENCION = t.ID_ATENCION
  JOIN VETERINARIO v ON v.ID_VETERINARIO = a.ID_VETERINARIO
  JOIN CITA c        ON c.ID_CITA = a.ID_CITA
  JOIN MASCOTA m     ON m.ID_MASCOTA = c.ID_MASCOTA
  JOIN PROPIETARIO p ON p.ID_PROPIETARIO = m.ID_PROPIETARIO
 WHERE t.ID_TRATAMIENTO = :id;
-- [TR-03] Sesiones de un tratamiento en orden.
-- Columnas: NUMERO, FECHA, VETERINARIO, OBSERVACIONES
-- Parametros: :id
SELECT s.NUMERO, s.FECHA, v.NOMBRES || ' ' || v.APELLIDOS AS VETERINARIO, s.OBSERVACIONES
  FROM SESION_TRATAMIENTO s
  JOIN VETERINARIO v ON v.ID_VETERINARIO = s.ID_VETERINARIO
 WHERE s.ID_TRATAMIENTO = :id
 ORDER BY s.NUMERO;
-- [TR-04] Tratamientos de una mascota (los mas recientes primero).
-- Columnas: ID_TRATAMIENTO, DESCRIPCION, FECHA_INICIO, SESIONES_PROGRAMADAS, REALIZADAS, ESTADO
-- Parametros: :id_mascota
SELECT t.ID_TRATAMIENTO, t.DESCRIPCION, t.FECHA_INICIO, t.SESIONES_PROGRAMADAS,
       (SELECT COUNT(*) FROM SESION_TRATAMIENTO s WHERE s.ID_TRATAMIENTO = t.ID_TRATAMIENTO) AS REALIZADAS,
       t.ESTADO
  FROM TRATAMIENTO t
  JOIN ATENCION a ON a.ID_ATENCION = t.ID_ATENCION
  JOIN CITA c     ON c.ID_CITA = a.ID_CITA
 WHERE c.ID_MASCOTA = :id_mascota
 ORDER BY t.FECHA_INICIO DESC;

/* #####################################################################
   VacunacionRepositorio  ->  src/main/java/com/vet/modulos/vacunacion/VacunacionRepositorio.java
   ##################################################################### */
-- [VC-01] Carnet de vacunacion de una mascota (lo mas reciente primero).
-- SITUACION: 'HISTORICA' si despues hubo otra dosis de la MISMA vacuna (pista: ROW_NUMBER() OVER (PARTITION BY ...));
--            si es la ultima: 'VENCIDA' (proxima < hoy), 'POR VENCER' (en 30 dias o menos), 'VIGENTE',
--            o 'DOSIS UNICA' si no tiene proxima dosis.
-- Columnas: ID_VACUNACION, VACUNA, FECHA_APLICACION, PROXIMA_DOSIS, LOTE, VETERINARIO, SITUACION
-- Parametros: :id_mascota
SELECT va.ID_VACUNACION, v.NOMBRE AS VACUNA, va.FECHA_APLICACION, va.PROXIMA_DOSIS, va.LOTE,
       vt.NOMBRES || ' ' || vt.APELLIDOS AS VETERINARIO,
       CASE WHEN ROW_NUMBER() OVER (PARTITION BY va.ID_VACUNA ORDER BY va.FECHA_APLICACION DESC) > 1 THEN 'HISTORICA'
            WHEN va.PROXIMA_DOSIS IS NULL THEN 'DOSIS UNICA'
            WHEN va.PROXIMA_DOSIS < TRUNC(SYSDATE) THEN 'VENCIDA'
            WHEN va.PROXIMA_DOSIS <= TRUNC(SYSDATE) + 30 THEN 'POR VENCER'
            ELSE 'VIGENTE' END AS SITUACION
  FROM VACUNACION va
  JOIN VACUNA v       ON v.ID_VACUNA = va.ID_VACUNA
  JOIN VETERINARIO vt ON vt.ID_VETERINARIO = va.ID_VETERINARIO
 WHERE va.ID_MASCOTA = :id_mascota
 ORDER BY va.FECHA_APLICACION DESC;
-- [VC-02] Vacunas disponibles para una especie, ordenadas por nombre.
-- Columnas: ID_VACUNA, NOMBRE, REFUERZO_DIAS
-- Parametros: :id_especie
SELECT ID_VACUNA, NOMBRE, REFUERZO_DIAS FROM VACUNA WHERE ID_ESPECIE = :id_especie ORDER BY NOMBRE;
-- [VC-03] Registrar una vacunacion. NO enviar PROXIMA_DOSIS: la calcula el trigger.
-- Parametros: :id_mascota, :id_vacuna, :id_veterinario, :fecha, :lote
INSERT INTO VACUNACION (ID_MASCOTA, ID_VACUNA, ID_VETERINARIO, FECHA_APLICACION, LOTE)
VALUES (:id_mascota, :id_vacuna, :id_veterinario, :fecha, :lote);

/* #####################################################################
   InventarioRepositorio  ->  src/main/java/com/vet/modulos/inventario/InventarioRepositorio.java
   ##################################################################### */
-- [IN-01] Medicamentos ordenados por nombre y presentacion, con una marca de stock bajo.
-- Columnas: ID_MEDICAMENTO, NOMBRE, PRESENTACION, UNIDAD, STOCK_ACTUAL, STOCK_MINIMO, ACTIVO,
--           BAJO ('S' si STOCK_ACTUAL <= STOCK_MINIMO, si no 'N')
SELECT ID_MEDICAMENTO, NOMBRE, PRESENTACION, UNIDAD, STOCK_ACTUAL, STOCK_MINIMO, ACTIVO,
       CASE WHEN STOCK_ACTUAL <= STOCK_MINIMO THEN 'S' ELSE 'N' END AS BAJO
  FROM MEDICAMENTO
 ORDER BY NOMBRE, PRESENTACION;
-- [IN-02] Un medicamento.
-- Columnas: ID_MEDICAMENTO, NOMBRE, PRESENTACION, UNIDAD, STOCK_ACTUAL, STOCK_MINIMO, ACTIVO
-- Parametros: :id
SELECT ID_MEDICAMENTO, NOMBRE, PRESENTACION, UNIDAD, STOCK_ACTUAL, STOCK_MINIMO, ACTIVO
  FROM MEDICAMENTO WHERE ID_MEDICAMENTO = :id;
-- [IN-03] Registrar medicamento (sin stock: el stock entra con un movimiento).  Parametros: :nombre, :presentacion, :unidad, :stock_minimo
INSERT INTO MEDICAMENTO (NOMBRE, PRESENTACION, UNIDAD, STOCK_MINIMO)
VALUES (:nombre, :presentacion, :unidad, :stock_minimo);
-- [IN-04] Actualizar datos del medicamento (NO el stock).  Parametros: :nombre, :presentacion, :unidad, :stock_minimo, :activo, :id
UPDATE MEDICAMENTO
   SET NOMBRE = :nombre, PRESENTACION = :presentacion, UNIDAD = :unidad,
       STOCK_MINIMO = :stock_minimo, ACTIVO = :activo
 WHERE ID_MEDICAMENTO = :id;
-- [IN-05] Registrar movimiento manual (ENTRADA por compra o SALIDA por merma).  Parametros: :id_medicamento, :tipo, :cantidad, :motivo
INSERT INTO MOVIMIENTO_STOCK (ID_MEDICAMENTO, TIPO, CANTIDAD, MOTIVO)
VALUES (:id_medicamento, :tipo, :cantidad, :motivo);
-- [IN-06] Ultimos 50 movimientos de todos los medicamentos (el mas reciente primero).
-- DETALLE: 'Atencion #<id>' si vino de una atencion, si no el MOTIVO (pista: NVL2).
-- Columnas: FECHA, ID_MEDICAMENTO, MEDICAMENTO, UNIDAD, TIPO, CANTIDAD, DETALLE
SELECT ms.FECHA, md.ID_MEDICAMENTO, md.NOMBRE AS MEDICAMENTO, md.UNIDAD, ms.TIPO, ms.CANTIDAD,
       NVL2(ms.ID_ATENCION, 'Atencion #' || ms.ID_ATENCION, ms.MOTIVO) AS DETALLE
  FROM MOVIMIENTO_STOCK ms
  JOIN MEDICAMENTO md ON md.ID_MEDICAMENTO = ms.ID_MEDICAMENTO
 ORDER BY ms.FECHA DESC, ms.ID_MOVIMIENTO DESC
 FETCH FIRST 50 ROWS ONLY;
