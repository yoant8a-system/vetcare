# Plan de trabajo del equipo: primero lo hacemos, después comparamos

| Etapa | Ustedes hacen | Parten de | Comparan con |
|---|---|---|---|
| **1. Modelo E-R** | El diagrama completo (PK, FK, NULL, UNIQUE, CHECK, DEFAULT, cardinalidad, ON DELETE) | [`etapa1_enunciado.md`](etapa1_enunciado.md) | `soluciones/etapa1_modelo_ER/modelo_ER.html` |
| **2. Crear la BD** | `sql/01` a `sql/04` | **Mi** modelo E-R | `soluciones/etapa2_creacion/` |
| **3. Lógica en Oracle** | `sql/05` vistas, `06` triggers, `07` paquetes, `09` job | **Mi** BD de la etapa 2 | `soluciones/etapa3_logica/` |
| **4. SQL de la app** | Las 81 sentencias de `sql/consultas_app.sql` → `*Repositorio.java` | **Mi** BD de la etapa 3 | `soluciones/etapa3_logica/consultas_app.sql` |

Empiecen cada etapa desde **mi** solución de la anterior: la app lee columnas por nombre exacto, y arrastrar
diferencias rompería las etapas siguientes. Sus diseños sirven para aprender comparando.

**Reparto sugerido (3 personas)**

| Integrante | Oracle | SQL de la app |
|---|---|---|
| A | 01, 02, 03 (usuario, tablas, índices) · PKG_SEGURIDAD | PR, MA, CA, US, AU |
| B | 05 vistas · 06 triggers · PKG_CITAS · PKG_ATENCION | CI, AT, PA, VC |
| C | 04 datos · PKG_TRATAMIENTO · PKG_ALERTAS · PKG_REPORTES · 09 job | VE, TR, IN, AL, DA |

---

## Lista de cotejo — Etapa 1 (modelo E-R)
- [ ] ¿Están las 23 tablas? ¿Crearon tablas intermedias para **veterinario–especialidad** y **atención–diagnóstico**? ¿Esta última tiene el atributo `TIPO`?
- [ ] ¿La genealogía es una **FK recursiva** de MASCOTA a sí misma (padre y madre) con **ON DELETE SET NULL**?
- [ ] ¿TRIAJE y ATENCIÓN son **1:1** con CITA (FK + UNIQUE)?
- [ ] ¿La cola de atención está **en la CITA** (estado, llegada, llamado, consultorio) y no en una tabla aparte? (Ambas son válidas: discutan.)
- [ ] ¿El stock se guarda en MEDICAMENTO **y** existe un kardex (MOVIMIENTO_STOCK)? ¿Por qué ambos?
- [ ] ¿Guardaron la **edad**? Es derivada (se calcula en la vista). ¿Y la **próxima dosis**? Se guarda, pero la calcula un trigger.
- [ ] ON DELETE: **CASCADE** solo donde el hijo no tiene sentido sin el padre (horario, especialidades del vet, triaje, diagnósticos de una atención, sesiones). **Restringir** en lo histórico (citas, atenciones, kardex).
- [ ] ¿Qué validaron con CHECK de varias columnas? (`CK_CITA_COLA`, `CK_HORARIO_RANGO`, `CK_MOVIMIENTO_ATENCION`, `CK_USUARIO_VET`)

## Lista de cotejo — Etapa 2 (creación)
- [ ] Tablespace propio y cuota; usuario en **XEPDB1**; privilegios mínimos (incluye `CREATE JOB`, `CREATE TYPE`, `CREATE MATERIALIZED VIEW`).
- [ ] PK con `GENERATED ALWAYS AS IDENTITY` (y por eso los INSERT de datos no llevan ID).
- [ ] Las **109 restricciones** con nombre (`SELECT COUNT(*) FROM user_constraints WHERE constraint_name NOT LIKE 'SYS%'`).
- [ ] Índices en todas las FK; el índice basado en función `UPPER(APELLIDOS)` y el único `UX_ALERTA_DIA`.
- [ ] SQL\*Plus: sin líneas en blanco dentro de un CREATE TABLE y sin comentarios después del `;`.

## Lista de cotejo — Etapa 3 (lógica en Oracle)
- [ ] `TRG_MASCOTA_PADRES` es **COMPOUND**: prueben un UPDATE de padre con un trigger normal → ORA-04091 (tabla mutante).
- [ ] En `PR_LLAMAR_SIGUIENTE`: `FOR UPDATE SKIP LOCKED` (dos veterinarios a la vez no toman al mismo paciente). `WHERE CURRENT OF` **no** funciona con un cursor con JOIN (ORA-01410).
- [ ] `PR_REGISTRAR_ATENCION` es todo-o-nada: SAVEPOINT + ROLLBACK TO. Prueben con una cantidad mayor al stock: no debe quedar nada guardado.
- [ ] Colecciones: `TABLE(p_diagnosticos)` y `MEMBER OF`; `.COUNT` de una colección NULL da error.
- [ ] `STANDARD_HASH` solo existe en SQL (no en PL/SQL directo) → `SELECT ... INTO ... FROM DUAL`.
- [ ] `INSERTING`/`UPDATING` no se pueden usar dentro de un INSERT (ORA-00920).
- [ ] En un INSERT ... SELECT no se puede llamar a una función PL/SQL **local** (PLS-00231): solo funciones guardadas.
- [ ] `NULL || ' ' || NULL` da `' '`, no NULL (por eso el CASE en `VW_CITA_DETALLE`).
- [ ] Reportes: ROLLUP+GROUPING, DENSE_RANK, RATIO_TO_REPORT, ROW_NUMBER, SUM() OVER, LAG, CONNECT BY, vista materializada.

## Lista de cotejo — Etapa 4 (SQL de la app)
- [ ] Alias **exactos** (las páginas leen `NOMBRE_SERVICIO`, `MASCOTAS`, `AVANCE`…).
- [ ] Parámetros con nombre (`:texto`): se prueban igual en SQL Developer.
- [ ] `:texto IS NULL OR ...` para filtros opcionales.
- [ ] Rangos de fecha con `>= TRUNC(:fecha) AND < TRUNC(:fecha) + 1` (usa índices) y no `TRUNC(columna) = ...`.
- [ ] [DA-02]: los días con 0 atenciones también aparecen (CONNECT BY LEVEL + LEFT JOIN).
- [ ] [AT-05]: consultorios libres con NOT EXISTS.
