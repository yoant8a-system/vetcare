/* =====================================================================
   CONSULTAS DE LA APLICACION - LO QUE EL EQUIPO DEBE ESCRIBIR
   ---------------------------------------------------------------------
   Para cada [ID]:
     1. Escriba la sentencia debajo de su descripcion y pruebela en SQL Developer
        (los parametros :nombre se piden al ejecutar con F9).
     2. Copiela (sin el ; final) al *Repositorio.java indicado, reemplazando
           Sql.pendiente("PR-01")
        por
           """
           SELECT ...
           """
     3. Recargue la pagina: si dice "Falta implementar [ID]", aun falta esa.
   Las columnas (alias) y parametros deben llamarse EXACTAMENTE como se indica,
   porque las paginas HTML los leen por nombre.
   ===================================================================== */

/* #####################################################################
   SistemaRepositorio  ->  src/main/java/com/vet/modulos/sistema/SistemaRepositorio.java
   ##################################################################### */
-- [US-01] Usuarios de la aplicacion con el nombre del veterinario vinculado (si tiene). Ordenar por usuario.
-- Columnas: ID_USUARIO, USUARIO, NOMBRE_COMPLETO, ROL, ACTIVO, ULTIMO_ACCESO, ID_VETERINARIO, VETERINARIO
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [US-02] Un usuario (SIN la clave).
-- Columnas: ID_USUARIO, USUARIO, NOMBRE_COMPLETO, ROL, ACTIVO, ID_VETERINARIO
-- Parametros: :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [US-03] Actualizar datos del usuario (la clave se cambia con PKG_SEGURIDAD).  Parametros: :nombre, :rol, :id_veterinario, :activo, :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [AL-01] Ultimas 100 alertas: primero las NO leidas, luego por fecha (mas reciente primero).
-- Columnas: ID_ALERTA, TIPO, ID_REFERENCIA, MENSAJE, FECHA, LEIDA
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [AL-02] Marcar una alerta como leida.  Parametros: :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [AL-03] Marcar TODAS las alertas como leidas.
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [AL-04] Cantidad de alertas sin leer (un numero; se muestra en la campanita).
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [AU-01] Ultimos 200 registros de auditoria, opcionalmente de una tabla (:tabla NULL = todas).
-- Columnas: ID_AUDITORIA, FECHA, TABLA, OPERACION, ID_REGISTRO, DETALLE, USUARIO_APP, USUARIO_BD
-- Parametros: :tabla
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [DA-01] Indicadores del tablero en UNA fila (pista: varias subconsultas escalares FROM DUAL).
-- Columnas: CITAS_HOY (de hoy, sin contar CANCELADAS), EN_ESPERA, EN_ATENCION,
--           ATENCIONES_MES (desde el dia 1 del mes actual), MASCOTAS (ACTIVAS),
--           TRATAMIENTOS (EN_CURSO), STOCK_BAJO (medicamentos activos con stock <= minimo)
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [DA-02] Atenciones por dia de los ultimos 14 dias, INCLUYENDO los dias con 0
-- (pista: generar los 14 dias con CONNECT BY LEVEL y hacer LEFT JOIN con ATENCION).
-- Columnas: DIA, TOTAL      (14 filas, del mas antiguo al de hoy)
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [DA-03] Atenciones de los ultimos 30 dias agrupadas por especie (de mayor a menor).
-- Columnas: ESPECIE, TOTAL
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [DA-04] Proximas 8 citas de HOY que siguen activas (PROGRAMADA, EN_ESPERA o EN_ATENCION), por hora.
-- Columnas: ID_CITA, FECHA_HORA, MASCOTA, PROPIETARIO, VETERINARIO, MOTIVO, ESTADO
-- Escriba aqui su sentencia y pruebela en SQL Developer:



/* #####################################################################
   PropietarioRepositorio  ->  src/main/java/com/vet/modulos/propietario/PropietarioRepositorio.java
   ##################################################################### */
-- [PR-01] Buscar propietarios por DNI (empieza con), nombres o apellidos (contiene, sin importar mayusculas).
-- Si :texto es NULL, devuelve todos. Ordenar por apellidos y nombres. Maximo 200 filas.
-- Columnas: ID_PROPIETARIO, DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL,
--           MASCOTAS (cantidad de mascotas del propietario: subconsulta con COUNT)
-- Parametros: :texto
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [PR-02] Un propietario por su ID.
-- Columnas: ID_PROPIETARIO, DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL, DIRECCION, FECHA_REGISTRO
-- Parametros: :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [PR-03] Registrar propietario (el ID es IDENTITY y FECHA_REGISTRO tiene DEFAULT: no se envian).
-- Parametros: :dni, :nombres, :apellidos, :telefono, :email, :direccion
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [PR-04] Actualizar propietario.
-- Parametros: :dni, :nombres, :apellidos, :telefono, :email, :direccion, :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [PR-05] Eliminar propietario. Si tiene mascotas, Oracle lo impide (FK -> ORA-02292).
-- Parametros: :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:



/* #####################################################################
   MascotaRepositorio  ->  src/main/java/com/vet/modulos/mascota/MascotaRepositorio.java
   ##################################################################### */
-- [MA-01] Buscar mascotas por nombre de la mascota, nombre del propietario (contiene) o DNI (empieza con),
-- y opcionalmente por especie. Parametros NULL = sin filtro. Ordenar por nombre. Maximo 200 filas.
-- Columnas: ID_MASCOTA, NOMBRE, ESPECIE, RAZA, SEXO, EDAD, PROPIETARIO, TELEFONO, ESTADO
-- Parametros: :texto, :id_especie
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [MA-02] Una mascota con todos sus datos de la vista VW_MASCOTA_DETALLE.
-- Columnas: todas las de la vista (ID_MASCOTA, NOMBRE, SEXO, FECHA_NACIMIENTO, EDAD, COLOR, ESTERILIZADO,
--           ESTADO, ID_RAZA, RAZA, ID_ESPECIE, ESPECIE, ID_PROPIETARIO, PROPIETARIO, DNI, TELEFONO,
--           ID_PADRE, PADRE, ID_MADRE, MADRE, FECHA_REGISTRO)
-- Parametros: :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [MA-03] Mascotas de un propietario, ordenadas por nombre.
-- Columnas: ID_MASCOTA, NOMBRE, ESPECIE, RAZA, SEXO, EDAD, ESTADO
-- Parametros: :id_propietario
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [MA-04] Registrar mascota. (El trigger TRG_MASCOTA_PADRES valida a los padres.)
-- Parametros: :id_propietario, :id_raza, :nombre, :sexo, :fecha_nacimiento, :color, :esterilizado,
--             :id_padre, :id_madre
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [MA-05] Actualizar mascota (incluye ESTADO: ACTIVO / FALLECIDO).
-- Parametros: :id_raza, :nombre, :sexo, :fecha_nacimiento, :color, :esterilizado, :id_padre, :id_madre,
--             :estado, :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [MA-06] Eliminar mascota (falla con ORA-02292 si ya tiene citas o vacunas: es lo correcto).
-- Parametros: :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [MA-07] Posibles padres/madres: TODAS las mascotas excepto la que se esta editando (:id_mascota puede ser NULL).
-- La pagina luego filtra por especie y sexo.
-- Columnas: ID_MASCOTA, ETIQUETA (ej. "Max (Labrador Retriever, Perez Gonzales)"), SEXO, ID_ESPECIE
-- Parametros: :id_mascota
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [MA-08] Todas las razas con su especie, ordenadas por especie y raza (para el combo agrupado).
-- Columnas: ID_RAZA, NOMBRE, ID_ESPECIE, ESPECIE
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [MA-09] Especies ordenadas por nombre (para filtros).
-- Columnas: ID_ESPECIE, NOMBRE
-- Escriba aqui su sentencia y pruebela en SQL Developer:



/* #####################################################################
   CatalogoRepositorio  ->  src/main/java/com/vet/modulos/catalogo/CatalogoRepositorio.java
   ##################################################################### */
-- [CA-01] Especies con la cantidad de razas de cada una, ordenadas por nombre.
-- Columnas: ID_ESPECIE, NOMBRE, RAZAS
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [CA-02] Registrar especie.  Parametros: :nombre
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [CA-03] Eliminar especie.  Parametros: :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [CA-04] Razas con su especie y la cantidad de mascotas de esa raza. Ordenar por especie y raza.
-- Columnas: ID_RAZA, NOMBRE, ESPECIE, MASCOTAS
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [CA-05] Registrar raza.  Parametros: :id_especie, :nombre
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [CA-06] Eliminar raza.  Parametros: :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [CA-07] Especialidades con la cantidad de veterinarios que la tienen.
-- Columnas: ID_ESPECIALIDAD, NOMBRE, VETERINARIOS
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [CA-08] Registrar especialidad.  Parametros: :nombre
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [CA-09] Eliminar especialidad.  Parametros: :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [CA-10] Consultorios ordenados por nombre.
-- Columnas: ID_CONSULTORIO, NOMBRE, ACTIVO
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [CA-11] Registrar consultorio.  Parametros: :nombre
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [CA-12] Activar/desactivar: si ACTIVO es 'S' pasa a 'N' y viceversa (un solo UPDATE con CASE).  Parametros: :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [CA-13] Catalogo de diagnosticos con el nombre de la especie ('Todas' si ID_ESPECIE es NULL). Ordenar por codigo.
-- Columnas: ID_DIAGNOSTICO, CODIGO, NOMBRE, CATEGORIA, ESPECIE
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [CA-14] Registrar diagnostico.  Parametros: :codigo, :nombre, :categoria, :id_especie (puede ser NULL)
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [CA-15] Eliminar diagnostico.  Parametros: :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [CA-16] Vacunas con su especie. Ordenar por especie y nombre.
-- Columnas: ID_VACUNA, NOMBRE, ESPECIE, REFUERZO_DIAS
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [CA-17] Registrar vacuna.  Parametros: :nombre, :id_especie, :refuerzo_dias (NULL = dosis unica)
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [CA-18] Eliminar vacuna.  Parametros: :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:



/* #####################################################################
   VeterinarioRepositorio  ->  src/main/java/com/vet/modulos/veterinario/VeterinarioRepositorio.java
   ##################################################################### */
-- [VE-01] Veterinarios ordenados por apellidos, con sus especialidades en UNA columna de texto
-- separadas por coma (pista: LISTAGG en una subconsulta) y cuantos bloques de horario tienen.
-- Columnas: ID_VETERINARIO, CMVP, NOMBRES, APELLIDOS, TELEFONO, EMAIL, ACTIVO, ESPECIALIDADES, BLOQUES_HORARIO
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [VE-02] Un veterinario por ID.
-- Columnas: ID_VETERINARIO, CMVP, NOMBRES, APELLIDOS, TELEFONO, EMAIL, ACTIVO
-- Parametros: :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [VE-03] Registrar veterinario.  Parametros: :cmvp, :nombres, :apellidos, :telefono, :email
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [VE-04] Actualizar veterinario.  Parametros: :cmvp, :nombres, :apellidos, :telefono, :email, :activo, :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [VE-05] IDs de las especialidades de un veterinario.
-- Columnas: ID_ESPECIALIDAD     Parametros: :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [VE-06] Quitar TODAS las especialidades de un veterinario.  Parametros: :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [VE-07] Asignar una especialidad a un veterinario.  Parametros: :id_veterinario, :id_especialidad
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [VE-08] Horario de un veterinario, ordenado por dia y hora de inicio.
-- Columnas: ID_HORARIO, DIA_SEMANA, HORA_INICIO, HORA_FIN     Parametros: :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [VE-09] Agregar un bloque de horario.  Parametros: :id_veterinario, :dia_semana, :hora_inicio, :hora_fin
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [VE-10] Eliminar un bloque de horario.  Parametros: :id_horario
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [VE-11] Veterinarios ACTIVOS para combos, ordenados por apellidos.
-- Columnas: ID_VETERINARIO, NOMBRE (nombres y apellidos juntos)
-- Escriba aqui su sentencia y pruebela en SQL Developer:



/* #####################################################################
   CitaRepositorio  ->  src/main/java/com/vet/modulos/cita/CitaRepositorio.java
   ##################################################################### */
-- [CI-01] Agenda de un dia (desde las 00:00 de :fecha hasta antes de las 00:00 del dia siguiente),
-- opcionalmente de un veterinario (:id_veterinario NULL = todos). Usar VW_CITA_DETALLE. Ordenar por hora.
-- Columnas: ID_CITA, FECHA_HORA, DURACION_MIN, ORIGEN, MOTIVO, ESTADO, ID_MASCOTA, MASCOTA, ESPECIE,
--           PROPIETARIO, TELEFONO, VETERINARIO, CONSULTORIO, NIVEL_URGENCIA
-- Parametros: :fecha, :id_veterinario
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [CI-02] Una cita con todos los datos de VW_CITA_DETALLE.
-- Parametros: :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [CI-03] Ultimas 50 citas de una mascota (la mas reciente primero).
-- Columnas: ID_CITA, FECHA_HORA, MOTIVO, ESTADO, VETERINARIO, ORIGEN
-- Parametros: :id_mascota
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [CI-04] Mascotas ACTIVAS para el combo de "nueva cita", ordenadas por nombre.
-- Columnas: ID_MASCOTA, ETIQUETA (ej. "Firulais - Chavez Rios, Luis (Perro)")
-- Escriba aqui su sentencia y pruebela en SQL Developer:



/* #####################################################################
   AtencionRepositorio  ->  src/main/java/com/vet/modulos/atencion/AtencionRepositorio.java
   ##################################################################### */
-- [AT-01] Cola de atencion: pacientes EN_ESPERA con su triaje (vista VW_COLA_ATENCION).
-- Orden: primero el NIVEL_URGENCIA mas bajo (1 = emergencia) y, a igual urgencia, el que llego antes.
-- Columnas: ID_CITA, MASCOTA, ESPECIE, PROPIETARIO, ID_VETERINARIO, VETERINARIO, MOTIVO, ORIGEN,
--           FECHA_LLEGADA, MINUTOS_ESPERA, NIVEL_URGENCIA, URGENCIA, PESO_KG, TEMPERATURA
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [AT-02] Paciente que el veterinario tiene EN_ATENCION ahora (0 o 1 fila), con su triaje y datos de la mascota.
-- Pista: VW_CITA_DETALLE + TRIAJE + VW_MASCOTA_DETALLE.
-- Columnas: ID_CITA, ID_MASCOTA, MASCOTA, ESPECIE, ID_ESPECIE, RAZA, SEXO, EDAD, PROPIETARIO, TELEFONO,
--           MOTIVO, CONSULTORIO, FECHA_LLAMADO, NIVEL_URGENCIA, PESO_KG, TEMPERATURA, FREC_CARDIACA,
--           FREC_RESPIRATORIA, OBS_TRIAJE (= TRIAJE.OBSERVACIONES)
-- Parametros: :id_veterinario
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [AT-03] Diagnosticos que aplican a una especie: los de esa especie + los generales (ID_ESPECIE NULL).
-- Ordenar por categoria y nombre.
-- Columnas: ID_DIAGNOSTICO, CODIGO, NOMBRE, CATEGORIA
-- Parametros: :id_especie
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [AT-04] Medicamentos activos que tienen stock (> 0), ordenados por nombre.
-- Columnas: ID_MEDICAMENTO, NOMBRE, PRESENTACION, UNIDAD, STOCK_ACTUAL
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [AT-05] Consultorios activos y LIBRES (sin ninguna cita EN_ATENCION en ellos). Pista: NOT EXISTS.
-- Columnas: ID_CONSULTORIO, NOMBRE
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [AT-06] Atenciones que el veterinario registro HOY (la mas reciente primero), con su duracion en minutos.
-- Columnas: ID_ATENCION, ID_MASCOTA, MASCOTA, PROPIETARIO, FECHA_INICIO, FECHA_FIN, MINUTOS
-- Parametros: :id_veterinario
-- Escriba aqui su sentencia y pruebela en SQL Developer:



/* #####################################################################
   PantallaRepositorio  ->  src/main/java/com/vet/modulos/pantalla/PantallaRepositorio.java
   ##################################################################### */
-- [PA-01] Ultimos 6 pacientes llamados hoy (vista VW_PANTALLA), el mas reciente primero.
-- Columnas: ID_CITA, MASCOTA, APELLIDO, CONSULTORIO, VETERINARIO, FECHA_LLAMADO, NIVEL_URGENCIA
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [PA-02] Los proximos 10 de la cola (mismo orden que AT-01).
-- Columnas: MASCOTA, NIVEL_URGENCIA
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [PA-03] Cuantos pacientes hay en la cola (un numero).
-- Escriba aqui su sentencia y pruebela en SQL Developer:



/* #####################################################################
   TratamientoRepositorio  ->  src/main/java/com/vet/modulos/tratamiento/TratamientoRepositorio.java
   ##################################################################### */
-- [TR-01] Tratamientos filtrados por estado (:estado NULL = todos), el mas reciente primero. Maximo 200.
-- Para llegar a la mascota: TRATAMIENTO -> ATENCION -> CITA -> MASCOTA.
-- Columnas: ID_TRATAMIENTO, ID_MASCOTA, MASCOTA, DESCRIPCION, FECHA_INICIO, SESIONES_PROGRAMADAS,
--           FRECUENCIA_DIAS, ESTADO, REALIZADAS (sesiones hechas: subconsulta COUNT),
--           AVANCE (porcentaje: se puede llamar a PKG_TRATAMIENTO.FN_AVANCE dentro del SELECT)
-- Parametros: :estado
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [TR-02] Un tratamiento con su mascota, propietario y el veterinario que lo indico.
-- Columnas: ID_TRATAMIENTO, ID_MASCOTA, MASCOTA, PROPIETARIO, VETERINARIO, DESCRIPCION, FECHA_INICIO,
--           SESIONES_PROGRAMADAS, FRECUENCIA_DIAS, ESTADO, AVANCE
-- Parametros: :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [TR-03] Sesiones de un tratamiento en orden.
-- Columnas: NUMERO, FECHA, VETERINARIO, OBSERVACIONES
-- Parametros: :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [TR-04] Tratamientos de una mascota (los mas recientes primero).
-- Columnas: ID_TRATAMIENTO, DESCRIPCION, FECHA_INICIO, SESIONES_PROGRAMADAS, REALIZADAS, ESTADO
-- Parametros: :id_mascota
-- Escriba aqui su sentencia y pruebela en SQL Developer:



/* #####################################################################
   VacunacionRepositorio  ->  src/main/java/com/vet/modulos/vacunacion/VacunacionRepositorio.java
   ##################################################################### */
-- [VC-01] Carnet de vacunacion de una mascota (lo mas reciente primero).
-- SITUACION: 'HISTORICA' si despues hubo otra dosis de la MISMA vacuna (pista: ROW_NUMBER() OVER (PARTITION BY ...));
--            si es la ultima: 'VENCIDA' (proxima < hoy), 'POR VENCER' (en 30 dias o menos), 'VIGENTE',
--            o 'DOSIS UNICA' si no tiene proxima dosis.
-- Columnas: ID_VACUNACION, VACUNA, FECHA_APLICACION, PROXIMA_DOSIS, LOTE, VETERINARIO, SITUACION
-- Parametros: :id_mascota
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [VC-02] Vacunas disponibles para una especie, ordenadas por nombre.
-- Columnas: ID_VACUNA, NOMBRE, REFUERZO_DIAS
-- Parametros: :id_especie
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [VC-03] Registrar una vacunacion. NO enviar PROXIMA_DOSIS: la calcula el trigger.
-- Parametros: :id_mascota, :id_vacuna, :id_veterinario, :fecha, :lote
-- Escriba aqui su sentencia y pruebela en SQL Developer:



/* #####################################################################
   InventarioRepositorio  ->  src/main/java/com/vet/modulos/inventario/InventarioRepositorio.java
   ##################################################################### */
-- [IN-01] Medicamentos ordenados por nombre y presentacion, con una marca de stock bajo.
-- Columnas: ID_MEDICAMENTO, NOMBRE, PRESENTACION, UNIDAD, STOCK_ACTUAL, STOCK_MINIMO, ACTIVO,
--           BAJO ('S' si STOCK_ACTUAL <= STOCK_MINIMO, si no 'N')
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [IN-02] Un medicamento.
-- Columnas: ID_MEDICAMENTO, NOMBRE, PRESENTACION, UNIDAD, STOCK_ACTUAL, STOCK_MINIMO, ACTIVO
-- Parametros: :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [IN-03] Registrar medicamento (sin stock: el stock entra con un movimiento).  Parametros: :nombre, :presentacion, :unidad, :stock_minimo
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [IN-04] Actualizar datos del medicamento (NO el stock).  Parametros: :nombre, :presentacion, :unidad, :stock_minimo, :activo, :id
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [IN-05] Registrar movimiento manual (ENTRADA por compra o SALIDA por merma).  Parametros: :id_medicamento, :tipo, :cantidad, :motivo
-- Escriba aqui su sentencia y pruebela en SQL Developer:


-- [IN-06] Ultimos 50 movimientos de todos los medicamentos (el mas reciente primero).
-- DETALLE: 'Atencion #<id>' si vino de una atencion, si no el MOTIVO (pista: NVL2).
-- Columnas: FECHA, ID_MEDICAMENTO, MEDICAMENTO, UNIDAD, TIPO, CANTIDAD, DETALLE
-- Escriba aqui su sentencia y pruebela en SQL Developer:


