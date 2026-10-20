/* =====================================================================
   SOLUCION - 08 DATOS DE DEMOSTRACION (historial de ~5 meses)
   Ejecutar como: VETERINARIA, DESPUES de 04 a 07 (antes del job, archivo 09).
   ---------------------------------------------------------------------
   Genera con PL/SQL + DBMS_RANDOM: citas, triajes, atenciones,
   diagnosticos, tratamientos con sesiones, vacunaciones y consumo de
   insumos, para que los reportes y graficos tengan datos.
   DBMS_RANDOM.SEED fija la "semilla": siempre salen los mismos datos.
   Las fechas pasadas se insertan directo (los paquetes no aceptan citas
   en el pasado); los triggers de stock y vacunacion SI se ejecutan.
   ===================================================================== */

SET SERVEROUTPUT ON

DECLARE
    c_dias      CONSTANT PLS_INTEGER := 150;
    v_inicio    DATE := TRUNC(SYSDATE) - c_dias;
    v_dia       DATE;
    v_dow       PLS_INTEGER;
    v_vet       NUMBER;
    v_h_ini     NUMBER;
    v_h_fin     NUMBER;
    v_mascota   NUMBER;
    v_especie   VARCHAR2(40);
    v_nac       DATE;
    v_fecha     DATE;
    v_llegada   DATE;
    v_llamado   DATE;
    v_fin       DATE;
    v_urg       PLS_INTEGER;
    v_r         NUMBER;
    v_estado    VARCHAR2(11);
    v_origen    VARCHAR2(8);
    v_consult   NUMBER;
    v_cita      NUMBER;
    v_atencion  NUMBER;
    v_trat      NUMBER;
    v_ses_prog  PLS_INTEGER;
    v_frec      PLS_INTEGER;
    v_hechas    PLS_INTEGER;
    v_motivo    VARCHAR2(200);
    v_total     PLS_INTEGER := 0;
    v_a         NUMBER; v_b NUMBER; v_c NUMBER;
    v_n         PLS_INTEGER;

    TYPE t_textos IS TABLE OF VARCHAR2(200);
    v_motivos t_textos := t_textos(
        'Control general', 'Vomitos y diarrea', 'Picazon y caida de pelo', 'Cojera de pata trasera',
        'Tos persistente', 'No quiere comer', 'Herida en el cuello', 'Ojos llorosos',
        'Sacude mucho la cabeza', 'Decaimiento', 'Control de peso', 'Orina con frecuencia');
    -- Nota: dentro de una sentencia SQL solo se pueden llamar funciones guardadas en la BD
    -- (como DBMS_RANDOM.VALUE). Una funcion declarada aqui mismo daria PLS-00231.
BEGIN
    DBMS_RANDOM.SEED(2026);

    -- ------------------------------------------------ 1. stock inicial y una reposicion (kardex)
    INSERT INTO MOVIMIENTO_STOCK (ID_MEDICAMENTO, TIPO, CANTIDAD, FECHA, MOTIVO)
    SELECT ID_MEDICAMENTO, 'ENTRADA',
           CASE NOMBRE WHEN 'Tramadol' THEN 10 ELSE STOCK_MINIMO * 6 END,
           v_inicio - 1, 'Inventario inicial'
      FROM MEDICAMENTO;

    INSERT INTO MOVIMIENTO_STOCK (ID_MEDICAMENTO, TIPO, CANTIDAD, FECHA, MOTIVO)
    SELECT ID_MEDICAMENTO, 'ENTRADA', STOCK_MINIMO * 3, v_inicio + 75, 'Compra a proveedor'
      FROM MEDICAMENTO
     WHERE NOMBRE NOT IN ('Tramadol', 'Ketoconazol');

    -- ------------------------------------------------ 2. historial de citas y atenciones
    FOR d IN 0 .. c_dias - 1 LOOP
        v_dia := v_inicio + d;
        v_dow := v_dia - TRUNC(v_dia, 'IW') + 1;
        CONTINUE WHEN v_dow = 7;

        FOR k IN 1 .. TRUNC(DBMS_RANDOM.VALUE(2, 6)) LOOP
            -- Veterinario que atiende ese dia
            SELECT ID_VETERINARIO, TO_NUMBER(SUBSTR(HORA_INICIO, 1, 2)), TO_NUMBER(SUBSTR(HORA_FIN, 1, 2))
              INTO v_vet, v_h_ini, v_h_fin
              FROM HORARIO_VETERINARIO
             WHERE DIA_SEMANA = v_dow
             ORDER BY DBMS_RANDOM.VALUE
             FETCH FIRST 1 ROWS ONLY;

            -- Mascota que ya habia nacido ese dia
            SELECT m.ID_MASCOTA, e.NOMBRE, m.FECHA_NACIMIENTO
              INTO v_mascota, v_especie, v_nac
              FROM MASCOTA m
              JOIN RAZA r    ON r.ID_RAZA = m.ID_RAZA
              JOIN ESPECIE e ON e.ID_ESPECIE = r.ID_ESPECIE
             WHERE m.FECHA_NACIMIENTO < v_dia - 30
             ORDER BY DBMS_RANDOM.VALUE
             FETCH FIRST 1 ROWS ONLY;

            v_fecha := v_dia + (v_h_ini + TRUNC(DBMS_RANDOM.VALUE(0, v_h_fin - v_h_ini - 1))) / 24 + TRUNC(DBMS_RANDOM.VALUE(0, 4)) * 15 / 1440;
            v_motivo := v_motivos(TRUNC(DBMS_RANDOM.VALUE(1, v_motivos.COUNT + 1)));

            v_r := DBMS_RANDOM.VALUE(0, 1);
            v_urg := CASE WHEN v_r < 0.05 THEN 1 WHEN v_r < 0.15 THEN 2 WHEN v_r < 0.40 THEN 3
                          WHEN v_r < 0.75 THEN 4 ELSE 5 END;
            v_origen := CASE WHEN v_urg <= 2 OR DBMS_RANDOM.VALUE(0, 1) < 0.25 THEN 'SIN_CITA' ELSE 'AGENDADA' END;

            v_r := DBMS_RANDOM.VALUE(0, 1);
            v_estado := CASE WHEN v_origen = 'SIN_CITA' OR v_r < 0.85 THEN 'ATENDIDA'
                             WHEN v_r < 0.93 THEN 'CANCELADA' ELSE 'NO_ASISTIO' END;

            IF v_estado = 'ATENDIDA' THEN
                v_llegada := v_fecha - DBMS_RANDOM.VALUE(0, 10) / 1440;
                v_llamado := v_llegada + (CASE v_urg WHEN 1 THEN DBMS_RANDOM.VALUE(0, 5) WHEN 2 THEN DBMS_RANDOM.VALUE(5, 15)
                                          WHEN 3 THEN DBMS_RANDOM.VALUE(10, 30) WHEN 4 THEN DBMS_RANDOM.VALUE(15, 45) ELSE DBMS_RANDOM.VALUE(20, 60) END) / 1440;
                v_fin := v_llamado + DBMS_RANDOM.VALUE(15, 40) / 1440;
                SELECT ID_CONSULTORIO INTO v_consult
                  FROM CONSULTORIO
                 WHERE (v_urg = 1 AND NOMBRE = 'Emergencias') OR (v_urg > 1 AND NOMBRE <> 'Emergencias')
                 ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROWS ONLY;

                INSERT INTO CITA (ID_MASCOTA, ID_VETERINARIO, FECHA_HORA, DURACION_MIN, ORIGEN, MOTIVO, ESTADO,
                                  FECHA_LLEGADA, FECHA_LLAMADO, ID_CONSULTORIO, FECHA_REGISTRO)
                VALUES (v_mascota, v_vet, v_fecha, 30, v_origen, CASE WHEN v_urg = 1 THEN 'EMERGENCIA: ' END || v_motivo,
                        'ATENDIDA', v_llegada, v_llamado, v_consult, v_fecha - CASE WHEN v_origen = 'AGENDADA' THEN DBMS_RANDOM.VALUE(1, 7) ELSE 0 END)
                RETURNING ID_CITA INTO v_cita;

                INSERT INTO TRIAJE (ID_CITA, FECHA, PESO_KG, TEMPERATURA, FREC_CARDIACA, FREC_RESPIRATORIA, NIVEL_URGENCIA)
                VALUES (v_cita, v_llegada,
                        ROUND(CASE v_especie WHEN 'Perro' THEN DBMS_RANDOM.VALUE(4, 35) WHEN 'Gato' THEN DBMS_RANDOM.VALUE(2.5, 6.5)
                                             WHEN 'Conejo' THEN DBMS_RANDOM.VALUE(1, 2.8) ELSE DBMS_RANDOM.VALUE(0.03, 0.06) END, 2),
                        ROUND(CASE WHEN v_urg <= 2 THEN DBMS_RANDOM.VALUE(39.5, 41) WHEN v_especie = 'Ave' THEN DBMS_RANDOM.VALUE(40, 42) ELSE DBMS_RANDOM.VALUE(37.8, 39.4) END, 1),
                        ROUND(CASE v_especie WHEN 'Perro' THEN DBMS_RANDOM.VALUE(70, 140) WHEN 'Gato' THEN DBMS_RANDOM.VALUE(140, 200)
                                             WHEN 'Conejo' THEN DBMS_RANDOM.VALUE(180, 280) ELSE DBMS_RANDOM.VALUE(250, 380) END),
                        ROUND(CASE v_especie WHEN 'Ave' THEN DBMS_RANDOM.VALUE(40, 70) ELSE DBMS_RANDOM.VALUE(15, 40) END),
                        v_urg);

                INSERT INTO ATENCION (ID_CITA, ID_VETERINARIO, FECHA_INICIO, FECHA_FIN, ANAMNESIS, EXAMEN_FISICO, INDICACIONES)
                VALUES (v_cita, v_vet, v_llamado, v_fin,
                        'Propietario refiere: ' || LOWER(v_motivo) || '. Inicio hace ' || TRUNC(DBMS_RANDOM.VALUE(1, 8)) || ' dias.',
                        'Mucosas rosadas, hidratacion adecuada, ganglios normales.',
                        CASE WHEN DBMS_RANDOM.VALUE(0, 1) < 0.5 THEN 'Control en ' || TRUNC(DBMS_RANDOM.VALUE(5, 15)) || ' dias.' ELSE 'Dieta blanda y reposo.' END)
                RETURNING ID_ATENCION INTO v_atencion;

                -- 1 o 2 diagnosticos de su especie (o generales); algunos aparecen mas que otros
                v_n := TRUNC(DBMS_RANDOM.VALUE(1, 3));
                INSERT INTO ATENCION_DIAGNOSTICO (ID_ATENCION, ID_DIAGNOSTICO, TIPO)
                SELECT v_atencion, ID_DIAGNOSTICO, CASE WHEN DBMS_RANDOM.VALUE < 0.6 THEN 'DEFINITIVO' ELSE 'PRESUNTIVO' END
                  FROM (SELECT d.ID_DIAGNOSTICO
                          FROM DIAGNOSTICO d
                          LEFT JOIN ESPECIE e ON e.ID_ESPECIE = d.ID_ESPECIE
                         WHERE d.ID_ESPECIE IS NULL OR e.NOMBRE = v_especie
                         ORDER BY DBMS_RANDOM.VALUE *
                                  CASE WHEN d.CODIGO IN ('GEN-001', 'DIG-002', 'DER-004', 'DIG-001') THEN 0.25
                                       WHEN d.ID_ESPECIE IS NOT NULL THEN 0.6 ELSE 1 END
                         FETCH FIRST v_n ROWS ONLY);

                -- Insumos usados (el trigger descuenta el stock; si no alcanza, se omite)
                IF DBMS_RANDOM.VALUE(0, 1) < 0.5 THEN
                    v_n := TRUNC(DBMS_RANDOM.VALUE(1, 3));
                    FOR x IN (SELECT ID_MEDICAMENTO, UNIDAD FROM MEDICAMENTO
                               ORDER BY DBMS_RANDOM.VALUE FETCH FIRST v_n ROWS ONLY) LOOP
                        BEGIN
                            INSERT INTO MOVIMIENTO_STOCK (ID_MEDICAMENTO, TIPO, CANTIDAD, FECHA, ID_ATENCION, MOTIVO)
                            VALUES (x.ID_MEDICAMENTO, 'SALIDA',
                                    CASE x.UNIDAD WHEN 'ml' THEN TRUNC(DBMS_RANDOM.VALUE(1, 6)) WHEN 'tableta' THEN TRUNC(DBMS_RANDOM.VALUE(2, 11)) ELSE 1 END,
                                    v_fin, v_atencion, 'Uso en atencion');
                        EXCEPTION
                            WHEN OTHERS THEN NULL;
                        END;
                    END LOOP;
                END IF;

                -- Algunos casos terminan en tratamiento con sesiones
                IF DBMS_RANDOM.VALUE(0, 1) < 0.22 THEN
                    v_ses_prog := TRUNC(DBMS_RANDOM.VALUE(3, 9));
                    v_frec := TRUNC(DBMS_RANDOM.VALUE(1, 8));
                    INSERT INTO TRATAMIENTO (ID_ATENCION, DESCRIPCION, SESIONES_PROGRAMADAS, FRECUENCIA_DIAS, FECHA_INICIO)
                    VALUES (v_atencion,
                            CASE TRUNC(DBMS_RANDOM.VALUE(1, 5)) WHEN 1 THEN 'Antibioticoterapia' WHEN 2 THEN 'Curacion de herida'
                                 WHEN 3 THEN 'Fisioterapia' ELSE 'Banos medicados' END,
                            v_ses_prog, v_frec, TRUNC(v_fin))
                    RETURNING ID_TRATAMIENTO INTO v_trat;

                    v_hechas := LEAST(v_ses_prog, TRUNC((TRUNC(SYSDATE) - TRUNC(v_fin)) / v_frec) + 1);
                    IF DBMS_RANDOM.VALUE(0, 1) < 0.3 THEN
                        v_hechas := TRUNC(v_hechas * DBMS_RANDOM.VALUE(0.3, 0.9));
                    END IF;
                    FOR s IN 1 .. v_hechas LOOP
                        INSERT INTO SESION_TRATAMIENTO (ID_TRATAMIENTO, NUMERO, FECHA, ID_VETERINARIO, OBSERVACIONES)
                        VALUES (v_trat, s, LEAST(TRUNC(v_fin) + (s - 1) * v_frec + 10 / 24, SYSDATE), v_vet,
                                CASE WHEN s = 1 THEN 'Inicio del tratamiento' ELSE 'Evolucion favorable' END);
                    END LOOP;

                    IF v_hechas >= v_ses_prog THEN
                        UPDATE TRATAMIENTO SET ESTADO = 'COMPLETADO' WHERE ID_TRATAMIENTO = v_trat;
                    ELSIF TRUNC(v_fin) + v_ses_prog * v_frec < TRUNC(SYSDATE) - 15 AND DBMS_RANDOM.VALUE(0, 1) < 0.5 THEN
                        UPDATE TRATAMIENTO SET ESTADO = 'SUSPENDIDO' WHERE ID_TRATAMIENTO = v_trat;
                    END IF;
                END IF;
            ELSE
                INSERT INTO CITA (ID_MASCOTA, ID_VETERINARIO, FECHA_HORA, ORIGEN, MOTIVO, ESTADO, FECHA_REGISTRO)
                VALUES (v_mascota, v_vet, v_fecha, 'AGENDADA', v_motivo, v_estado, v_fecha - DBMS_RANDOM.VALUE(1, 7));
            END IF;
            v_total := v_total + 1;
        END LOOP;
    END LOOP;

    -- ------------------------------------------------ 3. vacunaciones (el trigger calcula la proxima dosis)
    FOR m IN (SELECT m.ID_MASCOTA, r.ID_ESPECIE, m.FECHA_NACIMIENTO
                FROM MASCOTA m JOIN RAZA r ON r.ID_RAZA = m.ID_RAZA) LOOP
        FOR v IN (SELECT ID_VACUNA FROM VACUNA WHERE ID_ESPECIE = m.ID_ESPECIE) LOOP
            IF DBMS_RANDOM.VALUE(0, 1) < 0.75 THEN
                v_fecha := GREATEST(TRUNC(SYSDATE) - TRUNC(DBMS_RANDOM.VALUE(5, 420)), m.FECHA_NACIMIENTO + 60);
                IF v_fecha < TRUNC(SYSDATE) THEN
                    INSERT INTO VACUNACION (ID_MASCOTA, ID_VACUNA, ID_VETERINARIO, FECHA_APLICACION, LOTE)
                    VALUES (m.ID_MASCOTA, v.ID_VACUNA,
                            (SELECT ID_VETERINARIO FROM VETERINARIO ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROWS ONLY),
                            v_fecha, 'L' || TRUNC(DBMS_RANDOM.VALUE(1000, 9999)));
                END IF;
            END IF;
        END LOOP;
    END LOOP;

    -- ------------------------------------------------ 4. hoy: cola con pacientes y agenda futura
    FOR x IN (SELECT m.ID_MASCOTA, ROWNUM AS N
                FROM MASCOTA m WHERE m.NOMBRE IN ('Firulais', 'Garfield', 'Copito')) LOOP
        PKG_CITAS.PR_REGISTRAR_SIN_CITA(
            x.ID_MASCOTA,
            CASE x.N WHEN 1 THEN 'Vomitos desde anoche' WHEN 2 THEN 'Control de peso' ELSE 'No come hace 2 dias' END,
            CASE x.N WHEN 1 THEN 18.5 WHEN 2 THEN 6.2 ELSE 1.9 END,
            CASE x.N WHEN 1 THEN 39.8 WHEN 2 THEN 38.6 ELSE 38.9 END,
            110, 30,
            CASE x.N WHEN 1 THEN 2 WHEN 2 THEN 5 ELSE 3 END,
            NULL, v_cita);
    END LOOP;

    -- Citas futuras: se intentan varios horarios; las que choquen o caigan fuera de horario se saltan
    FOR dd IN 0 .. 6 LOOP
        FOR x IN (SELECT m.ID_MASCOTA FROM MASCOTA m WHERE m.ESTADO = 'ACTIVO'
                   ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 4 ROWS ONLY) LOOP
            FOR v IN (SELECT ID_VETERINARIO FROM VETERINARIO ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROWS ONLY) LOOP
                BEGIN
                    PKG_CITAS.PR_PROGRAMAR(x.ID_MASCOTA, v.ID_VETERINARIO,
                        TRUNC(SYSDATE) + dd + TRUNC(DBMS_RANDOM.VALUE(8, 19)) / 24 + TRUNC(DBMS_RANDOM.VALUE(0, 2)) * 30 / 1440,
                        30, v_motivos(TRUNC(DBMS_RANDOM.VALUE(1, v_motivos.COUNT + 1))), v_cita);
                EXCEPTION
                    WHEN OTHERS THEN NULL;
                END;
            END LOOP;
        END LOOP;
    END LOOP;

    COMMIT;

    -- ------------------------------------------------ 5. resumenes y alertas
    DBMS_MVIEW.REFRESH('MV_ATENCIONES_MES', 'C');
    PKG_ALERTAS.PR_GENERAR(v_a, v_b, v_c);
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Citas historicas generadas: ' || v_total);
    DBMS_OUTPUT.PUT_LINE('Alertas: vacunas=' || v_a || ' stock=' || v_b || ' citas=' || v_c);
END;
/

-- Comprobar
SELECT ESTADO, COUNT(*) FROM CITA GROUP BY ESTADO ORDER BY 2 DESC;
SELECT 'ATENCION' T, COUNT(*) N FROM ATENCION UNION ALL
SELECT 'TRATAMIENTO', COUNT(*) FROM TRATAMIENTO UNION ALL
SELECT 'SESION_TRATAMIENTO', COUNT(*) FROM SESION_TRATAMIENTO UNION ALL
SELECT 'VACUNACION', COUNT(*) FROM VACUNACION UNION ALL
SELECT 'MOVIMIENTO_STOCK', COUNT(*) FROM MOVIMIENTO_STOCK UNION ALL
SELECT 'ALERTA', COUNT(*) FROM ALERTA;
