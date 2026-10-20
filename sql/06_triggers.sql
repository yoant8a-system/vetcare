/* =====================================================================
   06 - TRIGGERS                                    Ejecutar como: VETERINARIA
   Errores: RAISE_APPLICATION_ERROR(-20xxx, 'mensaje'); la app lo muestra tal cual.
   Solucion: soluciones/etapa3_logica/06_triggers.sql
   ===================================================================== */

/* 6.1 TRG_MASCOTA_PADRES  (COMPOUND TRIGGER sobre MASCOTA, INSERT o UPDATE de ID_PADRE, ID_MADRE, ID_RAZA)
   Reglas (-20010): el padre debe ser macho, la madre hembra, ambos de la misma especie que la cria
   y nacidos antes que ella.
   ¿Por que compound? Hay que LEER MASCOTA dentro de un trigger de MASCOTA: con un FOR EACH ROW
   normal un UPDATE da ORA-04091 (tabla mutante). Guarde los ID en AFTER EACH ROW y valide en
   AFTER STATEMENT. */
-- TODO


/* 6.2 TRG_CITA_ESTADO (BEFORE UPDATE OF ESTADO ON CITA, FOR EACH ROW, WHEN OLD <> NEW)
   Transiciones validas (si no: -20020):
     PROGRAMADA  -> EN_ESPERA | CANCELADA | NO_ASISTIO
     EN_ESPERA   -> EN_ATENCION
     EN_ATENCION -> ATENDIDA          (un CHECK no puede: no ve el valor anterior) */
-- TODO


/* 6.3 TRG_MOVIMIENTO_STOCK (BEFORE INSERT ON MOVIMIENTO_STOCK, FOR EACH ROW)
   Leer el medicamento con FOR UPDATE. Si es SALIDA: medicamento activo (-20031) y stock suficiente
   (-20030 'Stock insuficiente de X: hay N ... y se piden M'); restar. Si es ENTRADA: sumar.
   6.4 TRG_MOVIMIENTO_INMUTABLE (BEFORE UPDATE OR DELETE, de sentencia): siempre -20032
   (el kardex no se edita: se registra un movimiento inverso) */
-- TODO


/* 6.5 TRG_VACUNACION (BEFORE INSERT OR UPDATE ... ON VACUNACION, FOR EACH ROW)
   La vacuna debe ser de la especie de la mascota (-20040) y la mascota estar ACTIVA (-20041).
   Calcular :NEW.PROXIMA_DOSIS = FECHA_APLICACION + REFUERZO_DIAS (NULL si es dosis unica). */
-- TODO


/* 6.6 Auditoria -> tabla AUDITORIA (TABLA, OPERACION, ID_REGISTRO, DETALLE).
   USUARIO_BD y USUARIO_APP se llenan solos por DEFAULT (USUARIO_APP = CLIENT_IDENTIFIER que envia la app).
   TRG_AUD_MASCOTA  AFTER INSERT OR UPDATE OR DELETE ON MASCOTA
   TRG_AUD_CITA     AFTER UPDATE OF ESTADO ON CITA   (detalle: 'Estado X -> Y')
   TRG_AUD_USUARIO  AFTER INSERT OR UPDATE OR DELETE ON USUARIO  (nunca guardar la clave)
   Ojo: INSERTING / UPDATING son de PL/SQL: no se pueden usar DENTRO de un INSERT (ORA-00920). */
-- TODO


-- Comprobar
SELECT trigger_name, table_name, status FROM user_triggers ORDER BY table_name;
SELECT name, line, text FROM user_errors ORDER BY name, line;
