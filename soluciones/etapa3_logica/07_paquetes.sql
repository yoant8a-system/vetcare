/* =====================================================================
   SOLUCION - 07 PAQUETES PL/SQL
   Ejecutar como: VETERINARIA  (SQL Developer: F5)
   ---------------------------------------------------------------------
   Un paquete = SPEC (lo publico: lo que la app puede llamar)
              + BODY (la implementacion).
   Las reglas de negocio viven aqui; la app solo llama y muestra el error.
   Codigos de error:
     -200xx seguridad   -201xx citas   -202xx atencion
     -203xx tratamientos
   ===================================================================== */


-- =====================================================================
-- PKG_SEGURIDAD: login y claves (nunca se guarda la clave en texto plano)
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

CREATE OR REPLACE PACKAGE BODY PKG_SEGURIDAD AS

    -- Privado (no esta en la SPEC): solo se usa dentro del paquete
    PROCEDURE validar_clave (p_clave IN VARCHAR2) IS
    BEGIN
        IF p_clave IS NULL OR LENGTH(p_clave) < 6 THEN
            RAISE_APPLICATION_ERROR(-20003, 'La clave debe tener al menos 6 caracteres');
        END IF;
    END validar_clave;

    FUNCTION FN_HASH (p_usuario IN VARCHAR2, p_clave IN VARCHAR2) RETURN VARCHAR2 IS
        v_hash VARCHAR2(64);
    BEGIN
        -- STANDARD_HASH solo existe en SQL, por eso el SELECT ... FROM DUAL
        SELECT RAWTOHEX(STANDARD_HASH(LOWER(p_usuario) || ':' || p_clave, 'SHA256'))
          INTO v_hash
          FROM DUAL;
        RETURN v_hash;
    END FN_HASH;

    PROCEDURE PR_LOGIN (
        p_usuario  IN  USUARIO.USUARIO%TYPE,
        p_clave    IN  VARCHAR2,
        o_id       OUT USUARIO.ID_USUARIO%TYPE,
        o_nombre   OUT USUARIO.NOMBRE_COMPLETO%TYPE,
        o_rol      OUT USUARIO.ROL%TYPE,
        o_id_vet   OUT USUARIO.ID_VETERINARIO%TYPE)
    IS
        v_hash   USUARIO.CLAVE_HASH%TYPE;
        v_activo USUARIO.ACTIVO%TYPE;
    BEGIN
        SELECT ID_USUARIO, NOMBRE_COMPLETO, ROL, ID_VETERINARIO, CLAVE_HASH, ACTIVO
          INTO o_id, o_nombre, o_rol, o_id_vet, v_hash, v_activo
          FROM USUARIO
         WHERE USUARIO = LOWER(TRIM(p_usuario));

        -- Mismo mensaje si falla el usuario o la clave: no revelar cual existe
        IF v_hash <> FN_HASH(p_usuario, p_clave) THEN
            RAISE_APPLICATION_ERROR(-20001, 'Usuario o clave incorrectos');
        END IF;
        IF v_activo = 'N' THEN
            RAISE_APPLICATION_ERROR(-20002, 'El usuario esta desactivado');
        END IF;

        UPDATE USUARIO SET ULTIMO_ACCESO = SYSDATE WHERE ID_USUARIO = o_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Usuario o clave incorrectos');
    END PR_LOGIN;

    PROCEDURE PR_CREAR_USUARIO (
        p_usuario  IN  USUARIO.USUARIO%TYPE,
        p_clave    IN  VARCHAR2,
        p_nombre   IN  USUARIO.NOMBRE_COMPLETO%TYPE,
        p_rol      IN  USUARIO.ROL%TYPE,
        p_id_vet   IN  USUARIO.ID_VETERINARIO%TYPE,
        o_id       OUT USUARIO.ID_USUARIO%TYPE)
    IS
    BEGIN
        validar_clave(p_clave);
        INSERT INTO USUARIO (USUARIO, CLAVE_HASH, NOMBRE_COMPLETO, ROL, ID_VETERINARIO)
        VALUES (LOWER(TRIM(p_usuario)), FN_HASH(TRIM(p_usuario), p_clave), p_nombre, p_rol, p_id_vet)
        RETURNING ID_USUARIO INTO o_id;
    END PR_CREAR_USUARIO;

    PROCEDURE PR_CAMBIAR_CLAVE (p_id IN USUARIO.ID_USUARIO%TYPE, p_clave IN VARCHAR2) IS
    BEGIN
        validar_clave(p_clave);
        UPDATE USUARIO
           SET CLAVE_HASH = FN_HASH(USUARIO, p_clave)
         WHERE ID_USUARIO = p_id;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20004, 'El usuario ' || p_id || ' no existe');
        END IF;
    END PR_CAMBIAR_CLAVE;

END PKG_SEGURIDAD;
/


-- =====================================================================
-- PKG_CITAS: agenda, llegada con triaje y cancelacion
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

CREATE OR REPLACE PACKAGE BODY PKG_CITAS AS

    FUNCTION FN_DIA_SEMANA (p_fecha IN DATE) RETURN NUMBER IS
    BEGIN
        -- TRUNC(fecha, 'IW') = lunes de esa semana (ISO), sin importar el idioma/territorio
        RETURN TRUNC(p_fecha) - TRUNC(p_fecha, 'IW') + 1;
    END FN_DIA_SEMANA;

    FUNCTION FN_VET_DISPONIBLE (
        p_id_vet    IN NUMBER,
        p_fecha     IN DATE,
        p_duracion  IN NUMBER) RETURN VARCHAR2
    IS
        v_fin    DATE := p_fecha + p_duracion / (24 * 60);
        v_cuenta NUMBER;
    BEGIN
        -- 1) Dentro de algun bloque de su horario ese dia (las horas 'HH24:MI' se comparan como texto)
        SELECT COUNT(*)
          INTO v_cuenta
          FROM HORARIO_VETERINARIO
         WHERE ID_VETERINARIO = p_id_vet
           AND DIA_SEMANA = FN_DIA_SEMANA(p_fecha)
           AND HORA_INICIO <= TO_CHAR(p_fecha, 'HH24:MI')
           AND HORA_FIN    >= TO_CHAR(v_fin,   'HH24:MI')
           AND TRUNC(v_fin) = TRUNC(p_fecha);
        IF v_cuenta = 0 THEN
            RETURN 'N';
        END IF;

        -- 2) Sin cruce con otra cita activa: dos intervalos se cruzan si
        --    inicioA < finB  Y  inicioB < finA
        SELECT COUNT(*)
          INTO v_cuenta
          FROM CITA
         WHERE ID_VETERINARIO = p_id_vet
           AND ESTADO IN ('PROGRAMADA', 'EN_ESPERA', 'EN_ATENCION')
           AND FECHA_HORA < v_fin
           AND p_fecha < FECHA_HORA + DURACION_MIN / (24 * 60);
        RETURN CASE WHEN v_cuenta = 0 THEN 'S' ELSE 'N' END;
    END FN_VET_DISPONIBLE;

    PROCEDURE PR_PROGRAMAR (
        p_id_mascota IN  CITA.ID_MASCOTA%TYPE,
        p_id_vet     IN  CITA.ID_VETERINARIO%TYPE,
        p_fecha      IN  CITA.FECHA_HORA%TYPE,
        p_duracion   IN  CITA.DURACION_MIN%TYPE,
        p_motivo     IN  CITA.MOTIVO%TYPE,
        o_id_cita    OUT CITA.ID_CITA%TYPE)
    IS
        v_estado  MASCOTA.ESTADO%TYPE;
        v_activo  VETERINARIO.ACTIVO%TYPE;
        v_cuenta  NUMBER;
        v_dur     NUMBER := NVL(p_duracion, 30);
    BEGIN
        SELECT ESTADO INTO v_estado FROM MASCOTA WHERE ID_MASCOTA = p_id_mascota;
        IF v_estado <> 'ACTIVO' THEN
            RAISE_APPLICATION_ERROR(-20101, 'La mascota no esta activa');
        END IF;

        SELECT ACTIVO INTO v_activo FROM VETERINARIO WHERE ID_VETERINARIO = p_id_vet;
        IF v_activo <> 'S' THEN
            RAISE_APPLICATION_ERROR(-20102, 'El veterinario no esta activo');
        END IF;

        IF p_fecha <= SYSDATE THEN
            RAISE_APPLICATION_ERROR(-20103, 'La cita debe ser en una fecha y hora futura');
        END IF;

        -- Bloquea al veterinario: dos recepcionistas no pueden reservarle la misma hora a la vez
        SELECT ID_VETERINARIO INTO v_cuenta FROM VETERINARIO WHERE ID_VETERINARIO = p_id_vet FOR UPDATE;

        IF FN_VET_DISPONIBLE(p_id_vet, p_fecha, v_dur) = 'N' THEN
            RAISE_APPLICATION_ERROR(-20104,
                'El veterinario no esta disponible el ' || TO_CHAR(p_fecha, 'DD/MM/YYYY HH24:MI') ||
                ' (fuera de su horario o ya tiene otra cita)');
        END IF;

        SELECT COUNT(*) INTO v_cuenta
          FROM CITA
         WHERE ID_MASCOTA = p_id_mascota
           AND ESTADO IN ('PROGRAMADA', 'EN_ESPERA', 'EN_ATENCION')
           AND FECHA_HORA < p_fecha + v_dur / (24 * 60)
           AND p_fecha < FECHA_HORA + DURACION_MIN / (24 * 60);
        IF v_cuenta > 0 THEN
            RAISE_APPLICATION_ERROR(-20105, 'La mascota ya tiene otra cita en ese horario');
        END IF;

        INSERT INTO CITA (ID_MASCOTA, ID_VETERINARIO, FECHA_HORA, DURACION_MIN, ORIGEN, MOTIVO)
        VALUES (p_id_mascota, p_id_vet, p_fecha, v_dur, 'AGENDADA', p_motivo)
        RETURNING ID_CITA INTO o_id_cita;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20106, 'La mascota o el veterinario no existen');
    END PR_PROGRAMAR;

    PROCEDURE PR_REGISTRAR_LLEGADA (
        p_id_cita    IN CITA.ID_CITA%TYPE,
        p_peso       IN TRIAJE.PESO_KG%TYPE,
        p_temp       IN TRIAJE.TEMPERATURA%TYPE,
        p_fc         IN TRIAJE.FREC_CARDIACA%TYPE,
        p_fr         IN TRIAJE.FREC_RESPIRATORIA%TYPE,
        p_urgencia   IN TRIAJE.NIVEL_URGENCIA%TYPE,
        p_obs        IN TRIAJE.OBSERVACIONES%TYPE)
    IS
        v_estado CITA.ESTADO%TYPE;
        v_fecha  CITA.FECHA_HORA%TYPE;
    BEGIN
        SELECT ESTADO, FECHA_HORA INTO v_estado, v_fecha
          FROM CITA WHERE ID_CITA = p_id_cita
           FOR UPDATE;

        IF v_estado <> 'PROGRAMADA' THEN
            RAISE_APPLICATION_ERROR(-20110, 'La cita esta ' || v_estado || ', no se puede registrar la llegada');
        END IF;
        IF TRUNC(v_fecha) <> TRUNC(SYSDATE) THEN
            RAISE_APPLICATION_ERROR(-20111, 'La cita es del ' || TO_CHAR(v_fecha, 'DD/MM/YYYY') || ', no de hoy');
        END IF;

        INSERT INTO TRIAJE (ID_CITA, PESO_KG, TEMPERATURA, FREC_CARDIACA, FREC_RESPIRATORIA, NIVEL_URGENCIA, OBSERVACIONES)
        VALUES (p_id_cita, p_peso, p_temp, p_fc, p_fr, p_urgencia, p_obs);

        UPDATE CITA
           SET ESTADO = 'EN_ESPERA', FECHA_LLEGADA = SYSDATE
         WHERE ID_CITA = p_id_cita;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20112, 'La cita ' || p_id_cita || ' no existe');
    END PR_REGISTRAR_LLEGADA;

    PROCEDURE PR_REGISTRAR_SIN_CITA (
        p_id_mascota IN  CITA.ID_MASCOTA%TYPE,
        p_motivo     IN  CITA.MOTIVO%TYPE,
        p_peso       IN  TRIAJE.PESO_KG%TYPE,
        p_temp       IN  TRIAJE.TEMPERATURA%TYPE,
        p_fc         IN  TRIAJE.FREC_CARDIACA%TYPE,
        p_fr         IN  TRIAJE.FREC_RESPIRATORIA%TYPE,
        p_urgencia   IN  TRIAJE.NIVEL_URGENCIA%TYPE,
        p_obs        IN  TRIAJE.OBSERVACIONES%TYPE,
        o_id_cita    OUT CITA.ID_CITA%TYPE)
    IS
        v_estado MASCOTA.ESTADO%TYPE;
    BEGIN
        SELECT ESTADO INTO v_estado FROM MASCOTA WHERE ID_MASCOTA = p_id_mascota;
        IF v_estado <> 'ACTIVO' THEN
            RAISE_APPLICATION_ERROR(-20101, 'La mascota no esta activa');
        END IF;

        INSERT INTO CITA (ID_MASCOTA, FECHA_HORA, ORIGEN, MOTIVO)
        VALUES (p_id_mascota, SYSDATE, 'SIN_CITA', p_motivo)
        RETURNING ID_CITA INTO o_id_cita;

        -- Reutiliza la logica de llegada (mismo triaje, mismas validaciones)
        PR_REGISTRAR_LLEGADA(o_id_cita, p_peso, p_temp, p_fc, p_fr, p_urgencia, p_obs);
    END PR_REGISTRAR_SIN_CITA;

    PROCEDURE PR_CANCELAR (p_id_cita IN CITA.ID_CITA%TYPE) IS
    BEGIN
        UPDATE CITA SET ESTADO = 'CANCELADA'
         WHERE ID_CITA = p_id_cita AND ESTADO = 'PROGRAMADA';
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20113, 'Solo se pueden cancelar citas PROGRAMADAS');
        END IF;
    END PR_CANCELAR;

END PKG_CITAS;
/


-- =====================================================================
-- PKG_ATENCION: llamar pacientes y registrar la atencion completa
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

CREATE OR REPLACE PACKAGE BODY PKG_ATENCION AS

    PROCEDURE PR_LLAMAR_SIGUIENTE (
        p_id_vet         IN  CITA.ID_VETERINARIO%TYPE,
        p_id_consultorio IN  CITA.ID_CONSULTORIO%TYPE,
        o_id_cita        OUT CITA.ID_CITA%TYPE)
    IS
        v_cuenta NUMBER;
        v_activo CONSULTORIO.ACTIVO%TYPE;

        -- SKIP LOCKED: si otro veterinario ya bloqueo ese paciente, se salta al siguiente
        CURSOR c_cola IS
            SELECT c.ID_CITA
              FROM CITA c
              JOIN TRIAJE t ON t.ID_CITA = c.ID_CITA
             WHERE c.ESTADO = 'EN_ESPERA'
               AND (c.ID_VETERINARIO = p_id_vet OR c.ID_VETERINARIO IS NULL)
             ORDER BY t.NIVEL_URGENCIA, c.FECHA_LLEGADA
               FOR UPDATE OF c.ESTADO SKIP LOCKED;
    BEGIN
        SELECT COUNT(*) INTO v_cuenta
          FROM CITA WHERE ID_VETERINARIO = p_id_vet AND ESTADO = 'EN_ATENCION';
        IF v_cuenta > 0 THEN
            RAISE_APPLICATION_ERROR(-20201, 'Ya tiene un paciente en atencion: finalicelo antes de llamar a otro');
        END IF;

        SELECT ACTIVO INTO v_activo FROM CONSULTORIO WHERE ID_CONSULTORIO = p_id_consultorio;
        SELECT COUNT(*) INTO v_cuenta
          FROM CITA WHERE ID_CONSULTORIO = p_id_consultorio AND ESTADO = 'EN_ATENCION';
        IF v_activo <> 'S' OR v_cuenta > 0 THEN
            RAISE_APPLICATION_ERROR(-20202, 'El consultorio no esta disponible');
        END IF;

        OPEN c_cola;
        FETCH c_cola INTO o_id_cita;
        IF c_cola%FOUND THEN
            -- La fila ya quedo bloqueada por el FOR UPDATE. Ojo: "WHERE CURRENT OF c_cola"
            -- NO sirve aqui porque el cursor tiene un JOIN (da ORA-01410); se usa la PK.
            UPDATE CITA
               SET ESTADO = 'EN_ATENCION',
                   ID_VETERINARIO = p_id_vet,
                   ID_CONSULTORIO = p_id_consultorio,
                   FECHA_LLAMADO = SYSDATE
             WHERE ID_CITA = o_id_cita;
        ELSE
            o_id_cita := NULL;
        END IF;
        CLOSE c_cola;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20203, 'El consultorio no existe');
    END PR_LLAMAR_SIGUIENTE;

    PROCEDURE PR_RELLAMAR (p_id_cita IN CITA.ID_CITA%TYPE) IS
    BEGIN
        UPDATE CITA SET FECHA_LLAMADO = SYSDATE
         WHERE ID_CITA = p_id_cita AND ESTADO = 'EN_ATENCION';
    END PR_RELLAMAR;

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
        o_id_atencion   OUT ATENCION.ID_ATENCION%TYPE)
    IS
        v_estado   CITA.ESTADO%TYPE;
        v_vet      CITA.ID_VETERINARIO%TYPE;
        v_llamado  CITA.FECHA_LLAMADO%TYPE;
        v_defs     T_NUMEROS := NVL(p_definitivos, T_NUMEROS());
    BEGIN
        SAVEPOINT sp_atencion;

        SELECT ESTADO, ID_VETERINARIO, FECHA_LLAMADO
          INTO v_estado, v_vet, v_llamado
          FROM CITA WHERE ID_CITA = p_id_cita
           FOR UPDATE;

        IF v_estado <> 'EN_ATENCION' OR v_vet <> p_id_vet THEN
            RAISE_APPLICATION_ERROR(-20210, 'Esta cita no esta en atencion con este veterinario');
        END IF;
        IF p_diagnosticos IS NULL OR p_diagnosticos.COUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20211, 'Registre al menos un diagnostico');
        END IF;
        -- Ojo: .COUNT de una coleccion NULL da error (COLLECTION_IS_NULL), por eso el CASE
        IF CASE WHEN p_medicamentos IS NULL THEN 0 ELSE p_medicamentos.COUNT END
           <> CASE WHEN p_cantidades IS NULL THEN 0 ELSE p_cantidades.COUNT END THEN
            RAISE_APPLICATION_ERROR(-20212, 'Cada medicamento debe tener su cantidad');
        END IF;

        INSERT INTO ATENCION (ID_CITA, ID_VETERINARIO, FECHA_INICIO, FECHA_FIN, ANAMNESIS, EXAMEN_FISICO, INDICACIONES)
        VALUES (p_id_cita, p_id_vet, v_llamado, SYSDATE, p_anamnesis, p_examen, p_indicaciones)
        RETURNING ID_ATENCION INTO o_id_atencion;

        -- TABLE() convierte la coleccion en filas; MEMBER OF pregunta si un valor esta en otra coleccion
        INSERT INTO ATENCION_DIAGNOSTICO (ID_ATENCION, ID_DIAGNOSTICO, TIPO)
        SELECT DISTINCT o_id_atencion, d.COLUMN_VALUE,
               CASE WHEN d.COLUMN_VALUE MEMBER OF v_defs THEN 'DEFINITIVO' ELSE 'PRESUNTIVO' END
          FROM TABLE(p_diagnosticos) d;

        IF p_trat_desc IS NOT NULL THEN
            INSERT INTO TRATAMIENTO (ID_ATENCION, DESCRIPCION, SESIONES_PROGRAMADAS, FRECUENCIA_DIAS)
            VALUES (o_id_atencion, p_trat_desc, NVL(p_trat_sesiones, 1), NVL(p_trat_frec, 1));
        END IF;

        -- Cada salida dispara TRG_MOVIMIENTO_STOCK: si falta stock, falla TODO (por el SAVEPOINT)
        IF p_medicamentos IS NOT NULL THEN
            FOR i IN 1 .. p_medicamentos.COUNT LOOP
                INSERT INTO MOVIMIENTO_STOCK (ID_MEDICAMENTO, TIPO, CANTIDAD, ID_ATENCION, MOTIVO)
                VALUES (p_medicamentos(i), 'SALIDA', p_cantidades(i), o_id_atencion, 'Uso en atencion');
            END LOOP;
        END IF;

        UPDATE CITA SET ESTADO = 'ATENDIDA' WHERE ID_CITA = p_id_cita;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK TO sp_atencion;
            RAISE_APPLICATION_ERROR(-20213, 'La cita ' || p_id_cita || ' no existe');
        WHEN OTHERS THEN
            ROLLBACK TO sp_atencion;
            RAISE;
    END PR_REGISTRAR_ATENCION;

END PKG_ATENCION;
/


-- =====================================================================
-- PKG_TRATAMIENTO: sesiones y avance
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

CREATE OR REPLACE PACKAGE BODY PKG_TRATAMIENTO AS

    FUNCTION FN_AVANCE (p_id_tratamiento IN NUMBER) RETURN NUMBER IS
        v_avance NUMBER;
    BEGIN
        SELECT ROUND(LEAST(COUNT(s.ID_SESION) / t.SESIONES_PROGRAMADAS, 1) * 100)
          INTO v_avance
          FROM TRATAMIENTO t
          LEFT JOIN SESION_TRATAMIENTO s ON s.ID_TRATAMIENTO = t.ID_TRATAMIENTO
         WHERE t.ID_TRATAMIENTO = p_id_tratamiento
         GROUP BY t.SESIONES_PROGRAMADAS;
        RETURN v_avance;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END FN_AVANCE;

    PROCEDURE PR_REGISTRAR_SESION (
        p_id_tratamiento IN  SESION_TRATAMIENTO.ID_TRATAMIENTO%TYPE,
        p_id_vet         IN  SESION_TRATAMIENTO.ID_VETERINARIO%TYPE,
        p_obs            IN  SESION_TRATAMIENTO.OBSERVACIONES%TYPE,
        o_numero         OUT SESION_TRATAMIENTO.NUMERO%TYPE)
    IS
        v_estado     TRATAMIENTO.ESTADO%TYPE;
        v_programadas TRATAMIENTO.SESIONES_PROGRAMADAS%TYPE;
    BEGIN
        -- FOR UPDATE: dos sesiones registradas a la vez no pueden tomar el mismo NUMERO
        SELECT ESTADO, SESIONES_PROGRAMADAS INTO v_estado, v_programadas
          FROM TRATAMIENTO WHERE ID_TRATAMIENTO = p_id_tratamiento
           FOR UPDATE;
        IF v_estado <> 'EN_CURSO' THEN
            RAISE_APPLICATION_ERROR(-20301, 'El tratamiento esta ' || v_estado);
        END IF;

        SELECT NVL(MAX(NUMERO), 0) + 1 INTO o_numero
          FROM SESION_TRATAMIENTO WHERE ID_TRATAMIENTO = p_id_tratamiento;

        INSERT INTO SESION_TRATAMIENTO (ID_TRATAMIENTO, NUMERO, ID_VETERINARIO, OBSERVACIONES)
        VALUES (p_id_tratamiento, o_numero, p_id_vet, p_obs);

        IF o_numero >= v_programadas THEN
            UPDATE TRATAMIENTO SET ESTADO = 'COMPLETADO' WHERE ID_TRATAMIENTO = p_id_tratamiento;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20302, 'El tratamiento no existe');
    END PR_REGISTRAR_SESION;

    PROCEDURE PR_SUSPENDER (p_id_tratamiento IN TRATAMIENTO.ID_TRATAMIENTO%TYPE) IS
    BEGIN
        UPDATE TRATAMIENTO SET ESTADO = 'SUSPENDIDO'
         WHERE ID_TRATAMIENTO = p_id_tratamiento AND ESTADO = 'EN_CURSO';
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20303, 'Solo se suspenden tratamientos EN_CURSO');
        END IF;
    END PR_SUSPENDER;

END PKG_TRATAMIENTO;
/


-- =====================================================================
-- PKG_ALERTAS: lo ejecuta el job nocturno (y el boton "Generar ahora")
-- =====================================================================
CREATE OR REPLACE PACKAGE PKG_ALERTAS AS
    PROCEDURE PR_GENERAR (
        o_vacunas OUT NUMBER,
        o_stock   OUT NUMBER,
        o_citas   OUT NUMBER);
END PKG_ALERTAS;
/

CREATE OR REPLACE PACKAGE BODY PKG_ALERTAS AS

    PROCEDURE PR_GENERAR (
        o_vacunas OUT NUMBER,
        o_stock   OUT NUMBER,
        o_citas   OUT NUMBER)
    IS
    BEGIN
        -- 1) Citas de dias pasados que siguen PROGRAMADAS -> NO_ASISTIO (+ alerta)
        MERGE INTO ALERTA a
        USING (SELECT c.ID_CITA, m.NOMBRE, c.FECHA_HORA
                 FROM CITA c JOIN MASCOTA m ON m.ID_MASCOTA = c.ID_MASCOTA
                WHERE c.ESTADO = 'PROGRAMADA' AND c.FECHA_HORA < TRUNC(SYSDATE)) x
           ON (a.TIPO = 'CITA' AND a.ID_REFERENCIA = x.ID_CITA AND TRUNC(a.FECHA) = TRUNC(SYSDATE))
         WHEN NOT MATCHED THEN
              INSERT (TIPO, ID_REFERENCIA, MENSAJE)
              VALUES ('CITA', x.ID_CITA, x.NOMBRE || ' no asistio a su cita del ' || TO_CHAR(x.FECHA_HORA, 'DD/MM HH24:MI'));

        UPDATE CITA SET ESTADO = 'NO_ASISTIO'
         WHERE ESTADO = 'PROGRAMADA' AND FECHA_HORA < TRUNC(SYSDATE);
        o_citas := SQL%ROWCOUNT;

        -- 2) Vacunas vencidas o que vencen en 7 dias (solo la ULTIMA aplicacion de cada vacuna por mascota)
        MERGE INTO ALERTA a
        USING (SELECT ID_VACUNACION, MASCOTA, VACUNA, PROXIMA_DOSIS
                 FROM (SELECT va.ID_VACUNACION, m.NOMBRE MASCOTA, v.NOMBRE VACUNA, va.PROXIMA_DOSIS,
                              ROW_NUMBER() OVER (PARTITION BY va.ID_MASCOTA, va.ID_VACUNA
                                                 ORDER BY va.FECHA_APLICACION DESC) AS ORDEN
                         FROM VACUNACION va
                         JOIN MASCOTA m ON m.ID_MASCOTA = va.ID_MASCOTA
                         JOIN VACUNA v  ON v.ID_VACUNA = va.ID_VACUNA
                        WHERE m.ESTADO = 'ACTIVO')
                WHERE ORDEN = 1 AND PROXIMA_DOSIS <= TRUNC(SYSDATE) + 7) x
           ON (a.TIPO = 'VACUNA' AND a.ID_REFERENCIA = x.ID_VACUNACION AND TRUNC(a.FECHA) = TRUNC(SYSDATE))
         WHEN NOT MATCHED THEN
              INSERT (TIPO, ID_REFERENCIA, MENSAJE)
              VALUES ('VACUNA', x.ID_VACUNACION,
                      x.MASCOTA || ': ' || x.VACUNA ||
                      CASE WHEN x.PROXIMA_DOSIS < TRUNC(SYSDATE) THEN ' vencida desde el ' ELSE ' vence el ' END ||
                      TO_CHAR(x.PROXIMA_DOSIS, 'DD/MM/YYYY'));
        o_vacunas := SQL%ROWCOUNT;

        -- 3) Insumos en o bajo el stock minimo
        MERGE INTO ALERTA a
        USING (SELECT ID_MEDICAMENTO, NOMBRE, STOCK_ACTUAL, STOCK_MINIMO, UNIDAD
                 FROM MEDICAMENTO
                WHERE ACTIVO = 'S' AND STOCK_ACTUAL <= STOCK_MINIMO) x
           ON (a.TIPO = 'STOCK' AND a.ID_REFERENCIA = x.ID_MEDICAMENTO AND TRUNC(a.FECHA) = TRUNC(SYSDATE))
         WHEN NOT MATCHED THEN
              INSERT (TIPO, ID_REFERENCIA, MENSAJE)
              VALUES ('STOCK', x.ID_MEDICAMENTO,
                      'Stock bajo de ' || x.NOMBRE || ': ' || x.STOCK_ACTUAL || ' ' || x.UNIDAD ||
                      ' (minimo ' || x.STOCK_MINIMO || ')');
        o_stock := SQL%ROWCOUNT;
    END PR_GENERAR;

END PKG_ALERTAS;
/


-- =====================================================================
-- PKG_REPORTES: cada reporte es una funcion que devuelve un SYS_REFCURSOR.
-- La app solo abre el cursor y pinta las columnas que lleguen.
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

CREATE OR REPLACE PACKAGE BODY PKG_REPORTES AS

    -- R1: historia clinica (subconsultas escalares con LISTAGG para no multiplicar filas)
    FUNCTION FN_HISTORIA_CLINICA (p_id_mascota IN NUMBER) RETURN SYS_REFCURSOR IS
        rc SYS_REFCURSOR;
    BEGIN
        OPEN rc FOR
            SELECT TO_CHAR(a.FECHA_INICIO, 'DD/MM/YYYY HH24:MI') AS FECHA,
                   v.NOMBRES || ' ' || v.APELLIDOS AS VETERINARIO,
                   c.MOTIVO,
                   t.PESO_KG AS "PESO (KG)",
                   t.TEMPERATURA AS "T (C)",
                   (SELECT LISTAGG(d.NOMBRE || CASE ad.TIPO WHEN 'DEFINITIVO' THEN ' (def.)' ELSE ' (pres.)' END, '; ')
                           WITHIN GROUP (ORDER BY d.NOMBRE)
                      FROM ATENCION_DIAGNOSTICO ad JOIN DIAGNOSTICO d ON d.ID_DIAGNOSTICO = ad.ID_DIAGNOSTICO
                     WHERE ad.ID_ATENCION = a.ID_ATENCION) AS DIAGNOSTICOS,
                   (SELECT LISTAGG(tr.DESCRIPCION || ' [' || tr.ESTADO || ']', '; ')
                           WITHIN GROUP (ORDER BY tr.ID_TRATAMIENTO)
                      FROM TRATAMIENTO tr WHERE tr.ID_ATENCION = a.ID_ATENCION) AS TRATAMIENTO,
                   (SELECT LISTAGG(md.NOMBRE || ' ' || ms.CANTIDAD || ' ' || md.UNIDAD, '; ')
                           WITHIN GROUP (ORDER BY md.NOMBRE)
                      FROM MOVIMIENTO_STOCK ms JOIN MEDICAMENTO md ON md.ID_MEDICAMENTO = ms.ID_MEDICAMENTO
                     WHERE ms.ID_ATENCION = a.ID_ATENCION) AS INSUMOS,
                   a.INDICACIONES
              FROM ATENCION a
              JOIN CITA c        ON c.ID_CITA = a.ID_CITA
              JOIN VETERINARIO v ON v.ID_VETERINARIO = a.ID_VETERINARIO
              LEFT JOIN TRIAJE t ON t.ID_CITA = c.ID_CITA
             WHERE c.ID_MASCOTA = p_id_mascota
             ORDER BY a.FECHA_INICIO DESC;
        RETURN rc;
    END FN_HISTORIA_CLINICA;

    -- R2: GROUP BY ROLLUP = subtotales por veterinario + total general en la misma consulta
    FUNCTION FN_ATENCIONES_VETERINARIO (p_desde IN DATE, p_hasta IN DATE) RETURN SYS_REFCURSOR IS
        rc SYS_REFCURSOR;
    BEGIN
        OPEN rc FOR
            SELECT CASE WHEN GROUPING(v.APELLIDOS) = 1 THEN '== TOTAL GENERAL =='
                        ELSE v.APELLIDOS || ', ' || v.NOMBRES END AS VETERINARIO,
                   CASE WHEN GROUPING(e.NOMBRE) = 1 AND GROUPING(v.APELLIDOS) = 0 THEN '-- Subtotal --'
                        ELSE e.NOMBRE END AS ESPECIE,
                   COUNT(*) AS ATENCIONES,
                   ROUND(AVG((a.FECHA_FIN - a.FECHA_INICIO) * 24 * 60)) AS "DURACION PROM. (MIN)"
              FROM ATENCION a
              JOIN VETERINARIO v ON v.ID_VETERINARIO = a.ID_VETERINARIO
              JOIN CITA c        ON c.ID_CITA = a.ID_CITA
              JOIN MASCOTA m     ON m.ID_MASCOTA = c.ID_MASCOTA
              JOIN RAZA r        ON r.ID_RAZA = m.ID_RAZA
              JOIN ESPECIE e     ON e.ID_ESPECIE = r.ID_ESPECIE
             WHERE a.FECHA_INICIO >= TRUNC(p_desde)
               AND a.FECHA_INICIO <  TRUNC(p_hasta) + 1
             GROUP BY ROLLUP ((v.APELLIDOS, v.NOMBRES), e.NOMBRE)
             ORDER BY GROUPING(v.APELLIDOS), v.APELLIDOS, GROUPING(e.NOMBRE), COUNT(*) DESC;
        RETURN rc;
    END FN_ATENCIONES_VETERINARIO;

    -- R3: funciones analiticas: DENSE_RANK por especie y RATIO_TO_REPORT (porcentaje del total)
    FUNCTION FN_DIAGNOSTICOS_FRECUENTES (p_desde IN DATE, p_hasta IN DATE, p_top IN NUMBER) RETURN SYS_REFCURSOR IS
        rc SYS_REFCURSOR;
    BEGIN
        OPEN rc FOR
            SELECT ESPECIE, PUESTO, DIAGNOSTICO, CATEGORIA, CASOS, PORCENTAJE || ' %' AS "% DE LA ESPECIE"
              FROM (SELECT e.NOMBRE AS ESPECIE,
                           d.NOMBRE AS DIAGNOSTICO,
                           d.CATEGORIA,
                           COUNT(*) AS CASOS,
                           DENSE_RANK() OVER (PARTITION BY e.NOMBRE ORDER BY COUNT(*) DESC) AS PUESTO,
                           ROUND(RATIO_TO_REPORT(COUNT(*)) OVER (PARTITION BY e.NOMBRE) * 100, 1) AS PORCENTAJE
                      FROM ATENCION_DIAGNOSTICO ad
                      JOIN DIAGNOSTICO d ON d.ID_DIAGNOSTICO = ad.ID_DIAGNOSTICO
                      JOIN ATENCION a    ON a.ID_ATENCION = ad.ID_ATENCION
                      JOIN CITA c        ON c.ID_CITA = a.ID_CITA
                      JOIN MASCOTA m     ON m.ID_MASCOTA = c.ID_MASCOTA
                      JOIN RAZA r        ON r.ID_RAZA = m.ID_RAZA
                      JOIN ESPECIE e     ON e.ID_ESPECIE = r.ID_ESPECIE
                     WHERE a.FECHA_INICIO >= TRUNC(p_desde)
                       AND a.FECHA_INICIO <  TRUNC(p_hasta) + 1
                     GROUP BY e.NOMBRE, d.NOMBRE, d.CATEGORIA)
             WHERE PUESTO <= NVL(p_top, 5)
             ORDER BY ESPECIE, PUESTO, DIAGNOSTICO;
        RETURN rc;
    END FN_DIAGNOSTICOS_FRECUENTES;

    -- R4: ultima aplicacion de cada vacuna por mascota (ROW_NUMBER) que vence pronto o ya vencio
    FUNCTION FN_VACUNAS_PENDIENTES (p_dias IN NUMBER) RETURN SYS_REFCURSOR IS
        rc SYS_REFCURSOR;
    BEGIN
        OPEN rc FOR
            SELECT MASCOTA, ESPECIE, PROPIETARIO, TELEFONO, VACUNA,
                   TO_CHAR(FECHA_APLICACION, 'DD/MM/YYYY') AS "ULTIMA DOSIS",
                   TO_CHAR(PROXIMA_DOSIS, 'DD/MM/YYYY') AS "PROXIMA DOSIS",
                   PROXIMA_DOSIS - TRUNC(SYSDATE) AS "DIAS RESTANTES",
                   CASE WHEN PROXIMA_DOSIS < TRUNC(SYSDATE) THEN 'VENCIDA' ELSE 'POR VENCER' END AS SITUACION
              FROM (SELECT m.NOMBRE AS MASCOTA, e.NOMBRE AS ESPECIE,
                           p.APELLIDOS || ', ' || p.NOMBRES AS PROPIETARIO, p.TELEFONO,
                           v.NOMBRE AS VACUNA, va.FECHA_APLICACION, va.PROXIMA_DOSIS,
                           ROW_NUMBER() OVER (PARTITION BY va.ID_MASCOTA, va.ID_VACUNA
                                              ORDER BY va.FECHA_APLICACION DESC) AS ORDEN
                      FROM VACUNACION va
                      JOIN VACUNA v      ON v.ID_VACUNA = va.ID_VACUNA
                      JOIN MASCOTA m     ON m.ID_MASCOTA = va.ID_MASCOTA
                      JOIN RAZA r        ON r.ID_RAZA = m.ID_RAZA
                      JOIN ESPECIE e     ON e.ID_ESPECIE = r.ID_ESPECIE
                      JOIN PROPIETARIO p ON p.ID_PROPIETARIO = m.ID_PROPIETARIO
                     WHERE m.ESTADO = 'ACTIVO')
             WHERE ORDEN = 1
               AND PROXIMA_DOSIS <= TRUNC(SYSDATE) + NVL(p_dias, 30)
             ORDER BY PROXIMA_DOSIS;
        RETURN rc;
    END FN_VACUNAS_PENDIENTES;

    -- R5: kardex con saldo acumulado: SUM() OVER (ORDER BY ...) = suma "corrida"
    FUNCTION FN_KARDEX (p_id_medicamento IN NUMBER) RETURN SYS_REFCURSOR IS
        rc SYS_REFCURSOR;
    BEGIN
        OPEN rc FOR
            SELECT TO_CHAR(ms.FECHA, 'DD/MM/YYYY HH24:MI') AS FECHA,
                   ms.TIPO,
                   CASE WHEN ms.TIPO = 'ENTRADA' THEN ms.CANTIDAD END AS ENTRADA,
                   CASE WHEN ms.TIPO = 'SALIDA'  THEN ms.CANTIDAD END AS SALIDA,
                   SUM(CASE WHEN ms.TIPO = 'ENTRADA' THEN ms.CANTIDAD ELSE -ms.CANTIDAD END)
                       OVER (ORDER BY ms.FECHA, ms.ID_MOVIMIENTO ROWS UNBOUNDED PRECEDING) AS SALDO,
                   NVL2(ms.ID_ATENCION, 'Atencion de ' || m.NOMBRE, ms.MOTIVO) AS DETALLE
              FROM MOVIMIENTO_STOCK ms
              LEFT JOIN ATENCION a ON a.ID_ATENCION = ms.ID_ATENCION
              LEFT JOIN CITA c     ON c.ID_CITA = a.ID_CITA
              LEFT JOIN MASCOTA m  ON m.ID_MASCOTA = c.ID_MASCOTA
             WHERE ms.ID_MEDICAMENTO = p_id_medicamento
             ORDER BY ms.FECHA, ms.ID_MOVIMIENTO;
        RETURN rc;
    END FN_KARDEX;

    -- R6: espera (llegada -> llamado) y duracion de la atencion por nivel de urgencia
    FUNCTION FN_TIEMPOS_ESPERA (p_desde IN DATE, p_hasta IN DATE) RETURN SYS_REFCURSOR IS
        rc SYS_REFCURSOR;
    BEGIN
        OPEN rc FOR
            SELECT t.NIVEL_URGENCIA AS NIVEL,
                   CASE t.NIVEL_URGENCIA WHEN 1 THEN 'Emergencia' WHEN 2 THEN 'Muy urgente'
                        WHEN 3 THEN 'Urgente' WHEN 4 THEN 'Poco urgente' ELSE 'No urgente' END AS URGENCIA,
                   COUNT(*) AS ATENCIONES,
                   ROUND(AVG((c.FECHA_LLAMADO - c.FECHA_LLEGADA) * 1440), 1) AS "ESPERA PROM. (MIN)",
                   ROUND(MAX((c.FECHA_LLAMADO - c.FECHA_LLEGADA) * 1440)) AS "ESPERA MAX. (MIN)",
                   ROUND(AVG((a.FECHA_FIN - a.FECHA_INICIO) * 1440), 1) AS "ATENCION PROM. (MIN)"
              FROM CITA c
              JOIN TRIAJE t   ON t.ID_CITA = c.ID_CITA
              JOIN ATENCION a ON a.ID_CITA = c.ID_CITA
             WHERE c.FECHA_LLEGADA >= TRUNC(p_desde)
               AND c.FECHA_LLEGADA <  TRUNC(p_hasta) + 1
             GROUP BY t.NIVEL_URGENCIA
             ORDER BY t.NIVEL_URGENCIA;
        RETURN rc;
    END FN_TIEMPOS_ESPERA;

    -- R7: desde la VISTA MATERIALIZADA (resumen precalculado). LAG = valor del mes anterior
    FUNCTION FN_ATENCIONES_MENSUALES (p_anio IN NUMBER) RETURN SYS_REFCURSOR IS
        rc SYS_REFCURSOR;
    BEGIN
        OPEN rc FOR
            SELECT TO_CHAR(MES, 'MM - Month', 'NLS_DATE_LANGUAGE=SPANISH') AS MES,
                   ATENCIONES,
                   MASCOTAS AS "MASCOTAS DISTINTAS",
                   SUM(ATENCIONES) OVER (ORDER BY MES) AS ACUMULADO,
                   CASE WHEN LAG(ATENCIONES) OVER (ORDER BY MES) IS NULL THEN NULL
                        ELSE ROUND((ATENCIONES - LAG(ATENCIONES) OVER (ORDER BY MES)) * 100
                                   / LAG(ATENCIONES) OVER (ORDER BY MES), 1) || ' %'
                   END AS "VS. MES ANTERIOR"
              FROM (SELECT MES, SUM(ATENCIONES) AS ATENCIONES, SUM(MASCOTAS) AS MASCOTAS
                      FROM MV_ATENCIONES_MES
                     WHERE EXTRACT(YEAR FROM MES) = p_anio
                     GROUP BY MES)
             ORDER BY 1;
        RETURN rc;
    END FN_ATENCIONES_MENSUALES;

    -- R8: avance de tratamientos (usa la funcion de otro paquete) y si van atrasados
    FUNCTION FN_TRATAMIENTOS_EN_CURSO RETURN SYS_REFCURSOR IS
        rc SYS_REFCURSOR;
    BEGIN
        OPEN rc FOR
            SELECT MASCOTA, PROPIETARIO, TRATAMIENTO,
                   TO_CHAR(FECHA_INICIO, 'DD/MM/YYYY') AS INICIO,
                   REALIZADAS || ' / ' || SESIONES_PROGRAMADAS AS SESIONES,
                   PKG_TRATAMIENTO.FN_AVANCE(ID_TRATAMIENTO) || ' %' AS AVANCE,
                   TO_CHAR(PROXIMA, 'DD/MM/YYYY') AS "PROXIMA SESION",
                   CASE WHEN PROXIMA < TRUNC(SYSDATE) THEN 'ATRASADO' ELSE 'AL DIA' END AS SITUACION
              FROM (SELECT t.ID_TRATAMIENTO, m.NOMBRE AS MASCOTA,
                           p.APELLIDOS || ', ' || p.NOMBRES AS PROPIETARIO,
                           t.DESCRIPCION AS TRATAMIENTO, t.FECHA_INICIO, t.SESIONES_PROGRAMADAS,
                           COUNT(s.ID_SESION) AS REALIZADAS,
                           NVL(MAX(TRUNC(s.FECHA)), t.FECHA_INICIO - t.FRECUENCIA_DIAS) + t.FRECUENCIA_DIAS AS PROXIMA
                      FROM TRATAMIENTO t
                      JOIN ATENCION a    ON a.ID_ATENCION = t.ID_ATENCION
                      JOIN CITA c        ON c.ID_CITA = a.ID_CITA
                      JOIN MASCOTA m     ON m.ID_MASCOTA = c.ID_MASCOTA
                      JOIN PROPIETARIO p ON p.ID_PROPIETARIO = m.ID_PROPIETARIO
                      LEFT JOIN SESION_TRATAMIENTO s ON s.ID_TRATAMIENTO = t.ID_TRATAMIENTO
                     WHERE t.ESTADO = 'EN_CURSO'
                     GROUP BY t.ID_TRATAMIENTO, m.NOMBRE, p.APELLIDOS, p.NOMBRES, t.DESCRIPCION,
                              t.FECHA_INICIO, t.SESIONES_PROGRAMADAS, t.FRECUENCIA_DIAS)
             ORDER BY PROXIMA;
        RETURN rc;
    END FN_TRATAMIENTOS_EN_CURSO;

    -- R9: consulta jerarquica hacia los ancestros (cada mascota tiene DOS padres)
    FUNCTION FN_GENEALOGIA (p_id_mascota IN NUMBER) RETURN SYS_REFCURSOR IS
        rc SYS_REFCURSOR;
    BEGIN
        OPEN rc FOR
            SELECT LEVEL - 1 AS GENERACION,
                   CASE WHEN LEVEL = 1 THEN 'La mascota'
                        ELSE LPAD(' ', (LEVEL - 2) * 4) ||
                             CASE LEVEL WHEN 2 THEN '' WHEN 3 THEN 'Abuel' ELSE 'Bisabuel' END ||
                             CASE WHEN LEVEL = 2 THEN DECODE(m.SEXO, 'M', 'Padre', 'Madre')
                                  ELSE DECODE(m.SEXO, 'M', 'o', 'a') END
                   END AS PARENTESCO,
                   m.NOMBRE, DECODE(m.SEXO, 'M', 'Macho', 'Hembra') AS SEXO, r.NOMBRE AS RAZA,
                   TO_CHAR(m.FECHA_NACIMIENTO, 'DD/MM/YYYY') AS NACIMIENTO,
                   SYS_CONNECT_BY_PATH(m.NOMBRE, ' <- ') AS LINAJE
              FROM MASCOTA m
              JOIN RAZA r ON r.ID_RAZA = m.ID_RAZA
             START WITH m.ID_MASCOTA = p_id_mascota
           CONNECT BY NOCYCLE m.ID_MASCOTA IN (PRIOR m.ID_PADRE, PRIOR m.ID_MADRE);
        RETURN rc;
    END FN_GENEALOGIA;

END PKG_REPORTES;
/


-- Comprobar
SELECT object_name, object_type, status FROM user_objects
 WHERE object_type IN ('PACKAGE', 'PACKAGE BODY') ORDER BY object_name, object_type;
SELECT name, type, line, text FROM user_errors ORDER BY name, type, line;
