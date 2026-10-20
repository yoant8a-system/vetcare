# Etapa 1 — Enunciado: Clínica veterinaria "VetCare"

> Diseñen su modelo Entidad-Relación **solo con este texto**. Durante esta etapa no abran `sql/`,
> `soluciones/` ni los `*Repositorio.java`: ahí están las columnas.

## El negocio

Una clínica veterinaria quiere un sistema cliente-servidor para gestionar su atención diaria.

### Clientes y pacientes
1. Los **propietarios** se registran con su DNI (8 a 12 dígitos, no se repite), nombres, apellidos y teléfono;
   el email y la dirección son opcionales.
2. Cada propietario puede tener varias **mascotas**. De cada mascota se guarda el nombre, sexo (macho/hembra),
   fecha de nacimiento (puede no saberse), color, si está esterilizada y si está activa o **falleció**.
3. Cada mascota es de una **raza**, y cada raza pertenece a una **especie** (perro, gato, conejo, ave…). Una
   misma raza (por ejemplo "Mestizo") puede existir en varias especies, pero no repetirse dentro de una.
4. La clínica también lleva **genealogía**: una mascota puede tener registrados a su **padre** y a su **madre**,
   que son otras mascotas de la clínica. El padre debe ser macho, la madre hembra, de la misma especie y
   nacidos antes que la cría. Si se borra un padre, la cría sigue existiendo, pero sin padre registrado.

### Personal
5. Los **veterinarios** tienen número de colegiatura (CMVP, único), nombres, apellidos, teléfono y email, y
   pueden desactivarse. Cada uno tiene **una o varias especialidades** (y una especialidad la tienen varios).
6. Cada veterinario tiene un **horario**: bloques por día de la semana con hora de inicio y de fin
   (ej. lunes 08:00–14:00). Si se elimina un veterinario, su horario y sus especialidades se van con él.
7. Hay **consultorios** (Consultorio 1, 2, 3, Emergencias) que se pueden desactivar.

### Agenda, triaje y cola
8. Recepción **agenda citas** de una mascota con un veterinario, en una fecha y hora futura, con duración
   y motivo. No se puede citar fuera del horario del veterinario, ni cruzar dos citas del mismo veterinario
   o de la misma mascota.
9. Cuando el paciente **llega**, se hace el **triaje**: peso, temperatura, frecuencia cardiaca y respiratoria,
   observaciones y un **nivel de urgencia del 1 al 5** (1 = emergencia … 5 = no urgente). Cada cita tiene
   como máximo un triaje.
10. También llegan pacientes **sin cita** (emergencias): se registran en el momento, sin veterinario asignado.
11. Los pacientes que pasaron el triaje forman la **cola de atención**, ordenada por urgencia y luego por hora
    de llegada. El veterinario **llama al siguiente** desde un consultorio libre; en ese momento la cita queda
    asignada a ese veterinario y consultorio, y se anuncia en la **pantalla de la sala de espera**.
12. Estados de una cita: programada → en espera (llegó) → en atención (llamada) → atendida; o bien
    programada → cancelada / no asistió. Hay que guardar cuándo llegó y cuándo fue llamada.

### Atención clínica
13. Cada cita atendida genera una **atención**: inicio, fin, anamnesis (obligatoria), examen físico e indicaciones.
14. En una atención se registran **uno o varios diagnósticos** de un **catálogo de enfermedades** (código único,
    nombre, categoría y, opcionalmente, la especie a la que aplica). De cada diagnóstico se indica si es
    presuntivo o definitivo.
15. Una atención puede indicar un **tratamiento** (descripción, número de sesiones, cada cuántos días) que se
    cumple en **sesiones** numeradas (1, 2, 3…), cada una con fecha, veterinario y observaciones. Un tratamiento
    está en curso, completado o suspendido.
16. **Vacunación**: se registra qué vacuna (del catálogo de vacunas de su especie, con días de refuerzo o dosis
    única), cuándo, quién la aplicó y el lote. La fecha de la próxima dosis se calcula sola.

### Inventario (uso interno, no es tienda)
17. La clínica controla sus **insumos/medicamentos** (nombre, presentación, unidad, stock actual y mínimo).
    El stock **no se edita a mano**: cada **entrada** (compra) o **salida** (uso en una atención, merma) queda
    registrada en un **kardex** que no se puede modificar ni borrar. El stock nunca puede quedar negativo.

### Sistema
18. **Usuarios** de la aplicación con rol administrador, recepción o veterinario (un veterinario tiene a lo más
    una cuenta). La clave nunca se guarda en texto plano.
19. **Auditoría**: cada cambio importante (mascotas, estados de citas, usuarios) se registra con fecha,
    usuario de BD y **usuario de la aplicación** que lo hizo.
20. **Alertas** automáticas cada noche: vacunas vencidas o por vencer, stock bajo y citas a las que no asistieron.
    Una misma alerta no debe repetirse el mismo día.

## Preguntas guía
- ¿Cuáles son las entidades? ¿Cuáles son **relaciones N:M** que necesitan tabla intermedia? ¿Alguna tiene atributos propios?
- ¿Hay alguna **relación recursiva** (una tabla que se referencia a sí misma)?
- ¿Qué relaciones son **1:1**? ¿Cómo se garantiza eso en SQL?
- Para cada FK: ¿obligatoria u opcional? ¿Qué pasa al borrar el padre: **restringir, CASCADE o SET NULL**?
- ¿Qué reglas se pueden hacer con **CHECK**, cuáles necesitan **triggers** y cuáles **procedimientos**?
- ¿Qué datos son **derivados** (no se guardan, se calculan)? ¿Y cuál conviene calcular y guardar (con un trigger)?
