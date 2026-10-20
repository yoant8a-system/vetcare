/* =====================================================================
   07 - PAQUETES PL/SQL                                Ejecutar como: VETERINARIA
   ---------------------------------------------------------------------
   La SPEC de cada paquete ya esta escrita: es el CONTRATO que usa la app Java
   (nombres, orden y tipos de parametros). NO la cambien.
   Ustedes escriben el PACKAGE BODY. Las reglas y codigos de error estan
   indicados: la app muestra el mensaje de RAISE_APPLICATION_ERROR tal cual.
   Solucion: soluciones/etapa3_logica/07_paquetes.sql
   ===================================================================== */

-- =====================================================================
-- PKG_SEGURIDAD
-- =====================================================================
CREATE OR REPLACE PACKAGE PKG_SEGURIDAD AS
    FUNCTION FN_HASH (p_usuario IN VARCHAR2, p_clave IN VARCHAR2) RETURN VARCHAR2;

    PROCEDURE PR_LOGIN (
        p_usuario  IN  USUARIO.USUARIO%TYPE,
        p_clave    IN  VARCHAR2,
        o_id       OUT USUARIO.ID_USUARIO%TYPE,
        o_nombre   OUT USUARIO.NOMBRE_COMPLETO%TYPE,
        o_rol      OUT USUARIO.ROL%TYPE,
        o_id_vet   OUT USUARIO.ID_VETERINARIO%TYPE);

    PROCEDURE PR_CREAR_USUARIO (
        p_usuario  IN  USUARIO.USUARIO%TYPE,
        p_clave    IN  VARCHAR2,
        p_nombre   IN  USUARIO.NOMBRE_COMPLETO%TYPE,
        p_rol      IN  USUARIO.ROL%TYPE,
        p_id_vet   IN  USUARIO.ID_VETERINARIO%TYPE,
        o_id       OUT USUARIO.ID_USUARIO%TYPE);

    PROCEDURE PR_CAMBIAR_CLAVE (p_id IN USUARIO.ID_USUARIO%TYPE, p_clave IN VARCHAR2);
END PKG_SEGURIDAD;
/
/* Pistas para el BODY:
   FN_HASH: SELECT RAWTOHEX(STANDARD_HASH(LOWER(usuario) || ':' || clave, 'SHA256')) INTO ... FROM DUAL
            (STANDARD_HASH solo existe en SQL, no en PL/SQL directo)
   PR_LOGIN: buscar el usuario (LOWER/TRIM); si no existe o el hash no coincide -> -20001 'Usuario o clave incorrectos'
             (MISMO mensaje en ambos casos); si ACTIVO='N' -> -20002; actualizar ULTIMO_ACCESO.
   PR_CREAR_USUARIO: validar clave >= 6 caracteres (-20003); INSERT ... RETURNING ID_USUARIO INTO o_id
   PR_CAMBIAR_CLAVE: validar; UPDATE; si SQL%ROWCOUNT = 0 -> -20004
*/
-- TODO  CREATE OR REPLACE PACKAGE BODY PKG_SEGURIDAD AS ... END PKG_SEGURIDAD;
-- /

-- =====================================================================
-- PKG_CITAS
-- =====================================================================
CREATE OR REPLACE PACKAGE PKG_CITAS AS
    -- 1 = lunes ... 7 = domingo, sin depender de NLS_TERRITORY
    FUNCTION FN_DIA_SEMANA (p_fecha IN DATE) RETURN NUMBER;

    -- 'S' si el veterinario atiende a esa hora y no tiene otra cita que se cruce
    FUNCTION FN_VET_DISPONIBLE (
        p_id_vet    IN NUMBER,
        p_fecha     IN DATE,
        p_duracion  IN NUMBER) RETURN VARCHAR2;

    PROCEDURE PR_PROGRAMAR (
        p_id_mascota IN  CITA.ID_MASCOTA%TYPE,
        p_id_vet     IN  CITA.ID_VETERINARIO%TYPE,
        p_fecha      IN  CITA.FECHA_HORA%TYPE,
        p_duracion   IN  CITA.DURACION_MIN%TYPE,
        p_motivo     IN  CITA.MOTIVO%TYPE,
        o_id_cita    OUT CITA.ID_CITA%TYPE);

    PROCEDURE PR_REGISTRAR_LLEGADA (
        p_id_cita    IN CITA.ID_CITA%TYPE,
        p_peso       IN TRIAJE.PESO_KG%TYPE,
        p_temp       IN TRIAJE.TEMPERATURA%TYPE,
        p_fc         IN TRIAJE.FREC_CARDIACA%TYPE,
        p_fr         IN TRIAJE.FREC_RESPIRATORIA%TYPE,
        p_urgencia   IN TRIAJE.NIVEL_URGENCIA%TYPE,
        p_obs        IN TRIAJE.OBSERVACIONES%TYPE);

    -- Paciente que llega sin cita (o emergencia): crea la cita y registra el triaje
    PROCEDURE PR_REGISTRAR_SIN_CITA (
        p_id_mascota IN  CITA.ID_MASCOTA%TYPE,
        p_motivo     IN  CITA.MOTIVO%TYPE,
        p_peso       IN  TRIAJE.PESO_KG%TYPE,
        p_temp       IN  TRIAJE.TEMPERATURA%TYPE,
        p_fc         IN  TRIAJE.FREC_CARDIACA%TYPE,
        p_fr         IN  TRIAJE.FREC_RESPIRATORIA%TYPE,
        p_urgencia   IN  TRIAJE.NIVEL_URGENCIA%TYPE,
        p_obs        IN  TRIAJE.OBSERVACIONES%TYPE,
        o_id_cita    OUT CITA.ID_CITA%TYPE);

    PROCEDURE PR_CANCELAR (p_id_cita IN CITA.ID_CITA%TYPE);
END PKG_CITAS;
/
/* Pistas para el BODY:
   FN_DIA_SEMANA: TRUNC(fecha) - TRUNC(fecha, 'IW') + 1   (1 = lunes, sin depender de NLS)
   FN_VET_DISPONIBLE: 'S' si (1) hay un bloque de HORARIO_VETERINARIO ese dia que contiene [fecha, fecha+duracion]
                      (horas 'HH24:MI' se comparan como texto) y (2) ninguna cita activa del vet se cruza:
                      inicioA < finB AND inicioB < finA
   PR_PROGRAMAR: mascota ACTIVA (-20101), vet activo (-20102), fecha futura (-20103), bloquear al vet con
                 SELECT ... FOR UPDATE, disponible (-20104), la mascota no tiene otra cita a esa hora (-20105),
                 INSERT ... RETURNING. NO_DATA_FOUND -> -20106
   PR_REGISTRAR_LLEGADA: cita FOR UPDATE; debe estar PROGRAMADA (-20110) y ser de hoy (-20111);
                 INSERT TRIAJE; UPDATE CITA a EN_ESPERA con FECHA_LLEGADA = SYSDATE. No existe -> -20112
   PR_REGISTRAR_SIN_CITA: mascota activa; INSERT CITA (ORIGEN 'SIN_CITA', FECHA_HORA SYSDATE, sin vet)
                 y reutilizar PR_REGISTRAR_LLEGADA
   PR_CANCELAR: UPDATE ... WHERE ESTADO = 'PROGRAMADA'; si 0 filas -> -20113
*/
-- TODO  CREATE OR REPLACE PACKAGE BODY PKG_CITAS AS ... END PKG_CITAS;
-- /

-- =====================================================================
-- PKG_ATENCION
-- =====================================================================
CREATE OR REPLACE PACKAGE PKG_ATENCION AS
    -- Toma el siguiente de la cola segun URGENCIA y hora de llegada. o_id_cita NULL = cola vacia
    PROCEDURE PR_LLAMAR_SIGUIENTE (
        p_id_vet         IN  CITA.ID_VETERINARIO%TYPE,
        p_id_consultorio IN  CITA.ID_CONSULTORIO%TYPE,
        o_id_cita        OUT CITA.ID_CITA%TYPE);

    -- Vuelve a anunciar en la pantalla
    PROCEDURE PR_RELLAMAR (p_id_cita IN CITA.ID_CITA%TYPE);

    -- Todo o nada: atencion + diagnosticos + tratamiento + salida de insumos + cita ATENDIDA
    PROCEDURE PR_REGISTRAR_ATENCION (
        p_id_cita       IN  CITA.ID_CITA%TYPE,
        p_id_vet        IN  ATENCION.ID_VETERINARIO%TYPE,
        p_anamnesis     IN  ATENCION.ANAMNESIS%TYPE,
        p_examen        IN  ATENCION.EXAMEN_FISICO%TYPE,
        p_indicaciones  IN  ATENCION.INDICACIONES%TYPE,
        p_diagnosticos  IN  T_NUMEROS,
        p_definitivos   IN  T_NUMEROS,
        p_trat_desc     IN  TRATAMIENTO.DESCRIPCION%TYPE,
        p_trat_sesiones IN  TRATAMIENTO.SESIONES_PROGRAMADAS%TYPE,
        p_trat_frec     IN  TRATAMIENTO.FRECUENCIA_DIAS%TYPE,
        p_medicamentos  IN  T_NUMEROS,
        p_cantidades    IN  T_NUMEROS,
        o_id_atencion   OUT ATENCION.ID_ATENCION%TYPE);
END PKG_ATENCION;
/
/* Pistas para el BODY:
   PR_LLAMAR_SIGUIENTE: el vet no debe tener otra cita EN_ATENCION (-20201); el consultorio debe estar
        activo y libre (-20202, no existe -20203). CURSOR sobre CITA JOIN TRIAJE, EN_ESPERA, del vet o sin vet,
        ORDER BY NIVEL_URGENCIA, FECHA_LLEGADA  FOR UPDATE OF c.ESTADO SKIP LOCKED.
        Si hay fila: UPDATE a EN_ATENCION (vet, consultorio, FECHA_LLAMADO). OJO: WHERE CURRENT OF no sirve
        con un cursor con JOIN (ORA-01410): actualizar por ID_CITA.
   PR_RELLAMAR: UPDATE FECHA_LLAMADO = SYSDATE si esta EN_ATENCION
   PR_REGISTRAR_ATENCION (todo o nada): SAVEPOINT; cita FOR UPDATE EN_ATENCION con ese vet (-20210);
        al menos un diagnostico (-20211); mismas cantidades de medicamentos y cantidades (-20212; cuidado:
        .COUNT de una coleccion NULL da error); INSERT ATENCION (inicio = FECHA_LLAMADO, fin = SYSDATE);
        INSERT ATENCION_DIAGNOSTICO ... SELECT ... FROM TABLE(p_diagnosticos), TIPO 'DEFINITIVO' si
        COLUMN_VALUE MEMBER OF p_definitivos; tratamiento si p_trat_desc no es NULL; un MOVIMIENTO_STOCK
        SALIDA por medicamento (el trigger descuenta); cita ATENDIDA. EXCEPTION: ROLLBACK TO savepoint; RAISE
*/
-- TODO  CREATE OR REPLACE PACKAGE BODY PKG_ATENCION AS ... END PKG_ATENCION;
-- /

-- =====================================================================
-- PKG_TRATAMIENTO
-- =====================================================================
CREATE OR REPLACE PACKAGE PKG_TRATAMIENTO AS
    -- Porcentaje de avance (0 a 100)
    FUNCTION FN_AVANCE (p_id_tratamiento IN NUMBER) RETURN NUMBER;

    PROCEDURE PR_REGISTRAR_SESION (
        p_id_tratamiento IN  SESION_TRATAMIENTO.ID_TRATAMIENTO%TYPE,
        p_id_vet         IN  SESION_TRATAMIENTO.ID_VETERINARIO%TYPE,
        p_obs            IN  SESION_TRATAMIENTO.OBSERVACIONES%TYPE,
        o_numero         OUT SESION_TRATAMIENTO.NUMERO%TYPE);

    PROCEDURE PR_SUSPENDER (p_id_tratamiento IN TRATAMIENTO.ID_TRATAMIENTO%TYPE);
END PKG_TRATAMIENTO;
/
/* Pistas para el BODY:
   FN_AVANCE: ROUND(sesiones hechas / SESIONES_PROGRAMADAS * 100) (maximo 100)
   PR_REGISTRAR_SESION: tratamiento FOR UPDATE, debe estar EN_CURSO (-20301; no existe -20302);
        NUMERO = MAX + 1; INSERT; si llego a SESIONES_PROGRAMADAS -> ESTADO 'COMPLETADO'
   PR_SUSPENDER: solo EN_CURSO (-20303)
*/
-- TODO  CREATE OR REPLACE PACKAGE BODY PKG_TRATAMIENTO AS ... END PKG_TRATAMIENTO;
-- /

-- =====================================================================
-- PKG_ALERTAS
-- =====================================================================
CREATE OR REPLACE PACKAGE PKG_ALERTAS AS
    PROCEDURE PR_GENERAR (
        o_vacunas OUT NUMBER,
        o_stock   OUT NUMBER,
        o_citas   OUT NUMBER);
END PKG_ALERTAS;
/
/* Pistas para el BODY:
   PR_GENERAR (usar MERGE ... WHEN NOT MATCHED THEN INSERT para no duplicar alertas del dia):
        1) citas PROGRAMADAS de dias pasados -> alerta 'CITA' y UPDATE a NO_ASISTIO (o_citas)
        2) ULTIMA aplicacion de cada vacuna por mascota (ROW_NUMBER) con PROXIMA_DOSIS <= hoy + 7 -> 'VACUNA'
        3) medicamentos activos con STOCK_ACTUAL <= STOCK_MINIMO -> 'STOCK'
*/
-- TODO  CREATE OR REPLACE PACKAGE BODY PKG_ALERTAS AS ... END PKG_ALERTAS;
-- /

-- =====================================================================
-- PKG_REPORTES
-- =====================================================================
CREATE OR REPLACE PACKAGE PKG_REPORTES AS
    FUNCTION FN_HISTORIA_CLINICA        (p_id_mascota IN NUMBER) RETURN SYS_REFCURSOR;
    FUNCTION FN_ATENCIONES_VETERINARIO  (p_desde IN DATE, p_hasta IN DATE) RETURN SYS_REFCURSOR;
    FUNCTION FN_DIAGNOSTICOS_FRECUENTES (p_desde IN DATE, p_hasta IN DATE, p_top IN NUMBER) RETURN SYS_REFCURSOR;
    FUNCTION FN_VACUNAS_PENDIENTES      (p_dias IN NUMBER) RETURN SYS_REFCURSOR;
    FUNCTION FN_KARDEX                  (p_id_medicamento IN NUMBER) RETURN SYS_REFCURSOR;
    FUNCTION FN_TIEMPOS_ESPERA          (p_desde IN DATE, p_hasta IN DATE) RETURN SYS_REFCURSOR;
    FUNCTION FN_ATENCIONES_MENSUALES    (p_anio IN NUMBER) RETURN SYS_REFCURSOR;
    FUNCTION FN_TRATAMIENTOS_EN_CURSO   RETURN SYS_REFCURSOR;
    FUNCTION FN_GENEALOGIA              (p_id_mascota IN NUMBER) RETURN SYS_REFCURSOR;
END PKG_REPORTES;
/
/* Pistas para el BODY:
   Cada funcion: OPEN rc FOR SELECT ...; RETURN rc;  (las columnas las pinta la app tal cual)
   R1 FN_HISTORIA_CLINICA: atenciones de la mascota con diagnosticos/tratamientos/insumos en texto (LISTAGG
      en subconsultas escalares para no multiplicar filas)
   R2 FN_ATENCIONES_VETERINARIO: GROUP BY ROLLUP((apellidos, nombres), especie) + GROUPING() para rotular
   R3 FN_DIAGNOSTICOS_FRECUENTES: DENSE_RANK() OVER (PARTITION BY especie ...) y RATIO_TO_REPORT
   R4 FN_VACUNAS_PENDIENTES: ROW_NUMBER() para la ultima dosis; dias restantes; VENCIDA / POR VENCER
   R5 FN_KARDEX: SUM(+entrada/-salida) OVER (ORDER BY fecha ROWS UNBOUNDED PRECEDING) = saldo
   R6 FN_TIEMPOS_ESPERA: por NIVEL_URGENCIA: espera (llegada->llamado) y duracion promedio en minutos
   R7 FN_ATENCIONES_MENSUALES: desde MV_ATENCIONES_MES; SUM() OVER (acumulado) y LAG() (vs mes anterior)
   R8 FN_TRATAMIENTOS_EN_CURSO: sesiones hechas, PKG_TRATAMIENTO.FN_AVANCE, proxima sesion, ATRASADO
   R9 FN_GENEALOGIA: START WITH ID_MASCOTA = p CONNECT BY NOCYCLE ID_MASCOTA IN (PRIOR ID_PADRE, PRIOR ID_MADRE)
      con LEVEL y SYS_CONNECT_BY_PATH
*/
-- TODO  CREATE OR REPLACE PACKAGE BODY PKG_REPORTES AS ... END PKG_REPORTES;
-- /

-- Comprobar (todo debe estar VALID)
SELECT object_name, object_type, status FROM user_objects WHERE object_type LIKE 'PACKAGE%' ORDER BY 1, 2;
SELECT name, type, line, text FROM user_errors ORDER BY name, line;
