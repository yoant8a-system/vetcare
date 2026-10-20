/* =====================================================================
   SOLUCION - 06 TRIGGERS
   Ejecutar como: VETERINARIA  (SQL Developer: F5)
   Errores de negocio: RAISE_APPLICATION_ERROR(-20xxx, 'mensaje').
   La app muestra el mensaje tal cual al usuario.
   ===================================================================== */


-- ---------------------------------------------------------------------
-- 6.1 TRG_MASCOTA_PADRES (COMPOUND TRIGGER)
--     El padre debe ser macho, la madre hembra y ambos de la misma especie.
--     Para eso hay que LEER la tabla MASCOTA dentro de un trigger de MASCOTA,
--     y un trigger FOR EACH ROW normal daria ORA-04091 (tabla mutante) en un UPDATE.
--     Solucion: guardar los ID en cada fila y validar AFTER STATEMENT,
--     cuando la tabla ya no esta "mutando".
-- ---------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_MASCOTA_PADRES
    FOR INSERT OR UPDATE OF ID_PADRE, ID_MADRE, ID_RAZA ON MASCOTA
    COMPOUND TRIGGER

    TYPE t_ids IS TABLE OF MASCOTA.ID_MASCOTA%TYPE;
    g_ids t_ids := t_ids();

    AFTER EACH ROW IS
    BEGIN
        IF :NEW.ID_PADRE IS NOT NULL OR :NEW.ID_MADRE IS NOT NULL THEN
            g_ids.EXTEND;
            g_ids(g_ids.LAST) := :NEW.ID_MASCOTA;
        END IF;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        v_error VARCHAR2(200);
    BEGIN
        FOR i IN 1 .. g_ids.COUNT LOOP
            SELECT MAX(CASE
                         WHEN pa.ID_MASCOTA IS NOT NULL AND pa.SEXO <> 'M' THEN 'El padre (' || pa.NOMBRE || ') debe ser macho'
                         WHEN ma.ID_MASCOTA IS NOT NULL AND ma.SEXO <> 'H' THEN 'La madre (' || ma.NOMBRE || ') debe ser hembra'
                         WHEN pa.ID_MASCOTA IS NOT NULL AND rp.ID_ESPECIE <> rh.ID_ESPECIE THEN 'El padre es de otra especie'
                         WHEN ma.ID_MASCOTA IS NOT NULL AND rm.ID_ESPECIE <> rh.ID_ESPECIE THEN 'La madre es de otra especie'
                         WHEN pa.FECHA_NACIMIENTO >= h.FECHA_NACIMIENTO
                           OR ma.FECHA_NACIMIENTO >= h.FECHA_NACIMIENTO THEN 'Los padres deben haber nacido antes que la cria'
                       END)
              INTO v_error
              FROM MASCOTA h
              JOIN RAZA rh         ON rh.ID_RAZA = h.ID_RAZA
              LEFT JOIN MASCOTA pa ON pa.ID_MASCOTA = h.ID_PADRE
              LEFT JOIN RAZA rp    ON rp.ID_RAZA = pa.ID_RAZA
              LEFT JOIN MASCOTA ma ON ma.ID_MASCOTA = h.ID_MADRE
              LEFT JOIN RAZA rm    ON rm.ID_RAZA = ma.ID_RAZA
             WHERE h.ID_MASCOTA = g_ids(i);

            IF v_error IS NOT NULL THEN
                RAISE_APPLICATION_ERROR(-20010, v_error);
            END IF;
        END LOOP;
        g_ids.DELETE;
    END AFTER STATEMENT;
END TRG_MASCOTA_PADRES;
/


-- ---------------------------------------------------------------------
-- 6.2 TRG_CITA_ESTADO: solo transiciones validas del ciclo de vida
--     (un CHECK no puede hacerlo: no ve el valor ANTERIOR)
-- ---------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_CITA_ESTADO
    BEFORE UPDATE OF ESTADO ON CITA
    FOR EACH ROW
    WHEN (OLD.ESTADO <> NEW.ESTADO)
BEGIN
    IF NOT (   (:OLD.ESTADO = 'PROGRAMADA'  AND :NEW.ESTADO IN ('EN_ESPERA', 'CANCELADA', 'NO_ASISTIO'))
            OR (:OLD.ESTADO = 'EN_ESPERA'   AND :NEW.ESTADO = 'EN_ATENCION')
            OR (:OLD.ESTADO = 'EN_ATENCION' AND :NEW.ESTADO = 'ATENDIDA')) THEN
        RAISE_APPLICATION_ERROR(-20020,
            'La cita ' || :OLD.ID_CITA || ' no puede pasar de ' || :OLD.ESTADO || ' a ' || :NEW.ESTADO);
    END IF;
END;
/


-- ---------------------------------------------------------------------
-- 6.3 TRG_MOVIMIENTO_STOCK: cada movimiento actualiza el stock (kardex)
--     FOR UPDATE bloquea la fila del medicamento: si dos atenciones usan el
--     mismo insumo a la vez, la segunda espera y ve el stock ya descontado.
-- ---------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_MOVIMIENTO_STOCK
    BEFORE INSERT ON MOVIMIENTO_STOCK
    FOR EACH ROW
DECLARE
    v_stock  MEDICAMENTO.STOCK_ACTUAL%TYPE;
    v_nombre MEDICAMENTO.NOMBRE%TYPE;
    v_unidad MEDICAMENTO.UNIDAD%TYPE;
    v_activo MEDICAMENTO.ACTIVO%TYPE;
BEGIN
    SELECT STOCK_ACTUAL, NOMBRE, UNIDAD, ACTIVO
      INTO v_stock, v_nombre, v_unidad, v_activo
      FROM MEDICAMENTO
     WHERE ID_MEDICAMENTO = :NEW.ID_MEDICAMENTO
       FOR UPDATE;

    IF :NEW.TIPO = 'SALIDA' THEN
        IF v_activo = 'N' THEN
            RAISE_APPLICATION_ERROR(-20031, v_nombre || ' esta desactivado');
        END IF;
        IF v_stock < :NEW.CANTIDAD THEN
            RAISE_APPLICATION_ERROR(-20030,
                'Stock insuficiente de ' || v_nombre || ': hay ' || v_stock || ' ' || v_unidad ||
                ' y se piden ' || :NEW.CANTIDAD);
        END IF;
        UPDATE MEDICAMENTO SET STOCK_ACTUAL = STOCK_ACTUAL - :NEW.CANTIDAD WHERE ID_MEDICAMENTO = :NEW.ID_MEDICAMENTO;
    ELSE
        UPDATE MEDICAMENTO SET STOCK_ACTUAL = STOCK_ACTUAL + :NEW.CANTIDAD WHERE ID_MEDICAMENTO = :NEW.ID_MEDICAMENTO;
    END IF;
END;
/

-- El kardex es un registro historico: no se corrige editando, se registra un movimiento inverso
CREATE OR REPLACE TRIGGER TRG_MOVIMIENTO_INMUTABLE
    BEFORE UPDATE OR DELETE ON MOVIMIENTO_STOCK
BEGIN
    RAISE_APPLICATION_ERROR(-20032,
        'Los movimientos de stock no se modifican ni se borran: registre un movimiento inverso');
END;
/


-- ---------------------------------------------------------------------
-- 6.4 TRG_VACUNACION: valida la especie y calcula la PROXIMA_DOSIS
-- ---------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_VACUNACION
    BEFORE INSERT OR UPDATE OF ID_VACUNA, ID_MASCOTA, FECHA_APLICACION ON VACUNACION
    FOR EACH ROW
DECLARE
    v_esp_vacuna   VACUNA.ID_ESPECIE%TYPE;
    v_refuerzo     VACUNA.REFUERZO_DIAS%TYPE;
    v_vacuna       VACUNA.NOMBRE%TYPE;
    v_esp_mascota  RAZA.ID_ESPECIE%TYPE;
    v_estado       MASCOTA.ESTADO%TYPE;
BEGIN
    SELECT ID_ESPECIE, REFUERZO_DIAS, NOMBRE
      INTO v_esp_vacuna, v_refuerzo, v_vacuna
      FROM VACUNA WHERE ID_VACUNA = :NEW.ID_VACUNA;

    SELECT r.ID_ESPECIE, m.ESTADO
      INTO v_esp_mascota, v_estado
      FROM MASCOTA m JOIN RAZA r ON r.ID_RAZA = m.ID_RAZA
     WHERE m.ID_MASCOTA = :NEW.ID_MASCOTA;

    IF v_estado <> 'ACTIVO' THEN
        RAISE_APPLICATION_ERROR(-20041, 'No se puede vacunar a una mascota fallecida');
    END IF;
    IF v_esp_vacuna <> v_esp_mascota THEN
        RAISE_APPLICATION_ERROR(-20040, 'La vacuna ' || v_vacuna || ' no corresponde a la especie de la mascota');
    END IF;

    -- Dato calculado por la BD: la app no tiene que acordarse de hacerlo
    :NEW.PROXIMA_DOSIS := CASE WHEN v_refuerzo IS NULL THEN NULL
                               ELSE :NEW.FECHA_APLICACION + v_refuerzo END;
END;
/


-- ---------------------------------------------------------------------
-- 6.5 Auditoria. USUARIO_APP se llena solo (DEFAULT con CLIENT_IDENTIFIER,
--     que la app Java envia en cada conexion).
-- ---------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_AUD_MASCOTA
    AFTER INSERT OR UPDATE OR DELETE ON MASCOTA
    FOR EACH ROW
DECLARE
    v_op      AUDITORIA.OPERACION%TYPE;
    v_detalle AUDITORIA.DETALLE%TYPE;
BEGIN
    IF INSERTING THEN
        v_op := 'INSERT';
        v_detalle := 'Alta de ' || :NEW.NOMBRE;
    ELSIF UPDATING THEN
        v_op := 'UPDATE';
        v_detalle := 'Nombre: ' || :NEW.NOMBRE ||
                     CASE WHEN :OLD.ESTADO <> :NEW.ESTADO THEN '; estado ' || :OLD.ESTADO || ' -> ' || :NEW.ESTADO END ||
                     CASE WHEN :OLD.ID_PROPIETARIO <> :NEW.ID_PROPIETARIO THEN '; cambio de propietario' END;
    ELSE
        v_op := 'DELETE';
        v_detalle := 'Baja de ' || :OLD.NOMBRE;
    END IF;
    INSERT INTO AUDITORIA (TABLA, OPERACION, ID_REGISTRO, DETALLE)
    VALUES ('MASCOTA', v_op, NVL(:NEW.ID_MASCOTA, :OLD.ID_MASCOTA), v_detalle);
END;
/

CREATE OR REPLACE TRIGGER TRG_AUD_CITA
    AFTER UPDATE OF ESTADO ON CITA
    FOR EACH ROW
    WHEN (OLD.ESTADO <> NEW.ESTADO)
BEGIN
    INSERT INTO AUDITORIA (TABLA, OPERACION, ID_REGISTRO, DETALLE)
    VALUES ('CITA', 'UPDATE', :NEW.ID_CITA, 'Estado ' || :OLD.ESTADO || ' -> ' || :NEW.ESTADO);
END;
/

CREATE OR REPLACE TRIGGER TRG_AUD_USUARIO
    AFTER INSERT OR UPDATE OR DELETE ON USUARIO
    FOR EACH ROW
DECLARE
    v_op      AUDITORIA.OPERACION%TYPE;
    v_detalle AUDITORIA.DETALLE%TYPE := NVL(:NEW.USUARIO, :OLD.USUARIO);
BEGIN
    -- INSERTING / UPDATING son de PL/SQL: no se pueden usar DENTRO de un INSERT (ORA-00920)
    IF INSERTING THEN
        v_op := 'INSERT';
    ELSIF UPDATING THEN
        v_op := 'UPDATE';
        -- Nunca se audita la clave, solo que cambio
        IF :OLD.CLAVE_HASH <> :NEW.CLAVE_HASH THEN v_detalle := v_detalle || ': cambio de clave'; END IF;
        IF :OLD.ROL <> :NEW.ROL THEN v_detalle := v_detalle || ': rol ' || :OLD.ROL || ' -> ' || :NEW.ROL; END IF;
        IF :OLD.ACTIVO <> :NEW.ACTIVO THEN v_detalle := v_detalle || ': activo ' || :OLD.ACTIVO || ' -> ' || :NEW.ACTIVO; END IF;
    ELSE
        v_op := 'DELETE';
    END IF;
    INSERT INTO AUDITORIA (TABLA, OPERACION, ID_REGISTRO, DETALLE)
    VALUES ('USUARIO', v_op, NVL(:NEW.ID_USUARIO, :OLD.ID_USUARIO), v_detalle);
END;
/


-- Comprobar
SELECT trigger_name, table_name, triggering_event, status FROM user_triggers ORDER BY table_name;
SELECT name, line, text FROM user_errors ORDER BY name, line;
