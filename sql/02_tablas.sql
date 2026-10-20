/* =====================================================================
   02 - TABLAS (23)                                    Ejecutar como: VETERINARIA
   ---------------------------------------------------------------------
   Para cada tabla esta la ESPECIFICACION (sale del modelo E-R). Escriban el
   CREATE TABLE debajo de cada TODO.
   - Nombres de tablas, columnas y restricciones: EXACTAMENTE como aqui
     (la aplicacion los usa por nombre y los mensajes de error los muestran).
   - PK con IDENTITY:   ID_X NUMBER(n) GENERATED ALWAYS AS IDENTITY
   - Restricciones con nombre:  CONSTRAINT PK_X PRIMARY KEY (...), FK_, UK_, CK_
   - Sin "ON DELETE" = NO ACTION (restringe).
   - SQL*Plus: no dejen lineas en blanco DENTRO de un CREATE TABLE.
   - Orden sugerido: el de este archivo (padres antes que hijas).
   Solucion: soluciones/etapa2_creacion/02_tablas.sql
   ===================================================================== */


-- =====================================================================
-- CATALOGOS
-- =====================================================================

/* ---------------------------------------------------------------------
   ESPECIE  -  Perro, gato, conejo, ave...
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_ESPECIE            NUMBER(5)      NOT NULL  IDENTITY (PK)
   NOMBRE                VARCHAR2(40)   NOT NULL  UK

   Restricciones a crear:
     PK_ESPECIE                   PRIMARY KEY (ID_ESPECIE)
     UK_ESPECIE_NOMBRE            UNIQUE (NOMBRE)
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE ESPECIE ( ... );



/* ---------------------------------------------------------------------
   RAZA  -  Raza de cada especie
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_RAZA               NUMBER(6)      NOT NULL  IDENTITY (PK)
   ID_ESPECIE            NUMBER(5)      NOT NULL  FK,UK
   NOMBRE                VARCHAR2(60)   NOT NULL  UK

   Restricciones a crear:
     PK_RAZA                      PRIMARY KEY (ID_RAZA)
     FK_RAZA_ESPECIE              FOREIGN KEY (ID_ESPECIE) -> ESPECIE  [restringe (NO ACTION)]
     UK_RAZA_NOMBRE               UNIQUE (ID_ESPECIE, NOMBRE)
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE RAZA ( ... );



/* ---------------------------------------------------------------------
   ESPECIALIDAD  -  Especialidades medicas
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_ESPECIALIDAD       NUMBER(4)      NOT NULL  IDENTITY (PK)
   NOMBRE                VARCHAR2(60)   NOT NULL  UK

   Restricciones a crear:
     PK_ESPECIALIDAD              PRIMARY KEY (ID_ESPECIALIDAD)
     UK_ESPECIALIDAD_NOMBRE       UNIQUE (NOMBRE)
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE ESPECIALIDAD ( ... );



/* ---------------------------------------------------------------------
   CONSULTORIO  -  Consultorios fisicos
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_CONSULTORIO        NUMBER(3)      NOT NULL  IDENTITY (PK)
   NOMBRE                VARCHAR2(30)   NOT NULL  UK
   ACTIVO                CHAR(1)        NOT NULL  DEFAULT 'S'

   Restricciones a crear:
     PK_CONSULTORIO               PRIMARY KEY (ID_CONSULTORIO)
     UK_CONSULTORIO_NOMBRE        UNIQUE (NOMBRE)
     CK_CONSULTORIO_ACTIVO        CHECK (ACTIVO IN ('S', 'N'))
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE CONSULTORIO ( ... );



/* ---------------------------------------------------------------------
   DIAGNOSTICO  -  Catalogo de enfermedades (NULL en especie = aplica a todas)
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_DIAGNOSTICO        NUMBER(6)      NOT NULL  IDENTITY (PK)
   CODIGO                VARCHAR2(10)   NOT NULL  UK
   NOMBRE                VARCHAR2(120)  NOT NULL  
   CATEGORIA             VARCHAR2(40)   NOT NULL  
   ID_ESPECIE            NUMBER(5)      NULL      FK

   Restricciones a crear:
     PK_DIAGNOSTICO               PRIMARY KEY (ID_DIAGNOSTICO)
     FK_DIAGNOSTICO_ESPECIE       FOREIGN KEY (ID_ESPECIE) -> ESPECIE  [restringe (NO ACTION)]
     UK_DIAGNOSTICO_CODIGO        UNIQUE (CODIGO)
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE DIAGNOSTICO ( ... );



/* ---------------------------------------------------------------------
   VACUNA  -  Vacunas por especie y su refuerzo
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_VACUNA             NUMBER(5)      NOT NULL  IDENTITY (PK)
   NOMBRE                VARCHAR2(80)   NOT NULL  UK
   ID_ESPECIE            NUMBER(5)      NOT NULL  FK,UK
   REFUERZO_DIAS         NUMBER(4)      NULL      

   Restricciones a crear:
     PK_VACUNA                    PRIMARY KEY (ID_VACUNA)
     FK_VACUNA_ESPECIE            FOREIGN KEY (ID_ESPECIE) -> ESPECIE  [restringe (NO ACTION)]
     UK_VACUNA_NOMBRE             UNIQUE (NOMBRE, ID_ESPECIE)
     CK_VACUNA_REFUERZO           CHECK (REFUERZO_DIAS > 0)
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE VACUNA ( ... );




-- =====================================================================
-- PERSONAS
-- =====================================================================

/* ---------------------------------------------------------------------
   PROPIETARIO  -  Dueños de las mascotas
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_PROPIETARIO        NUMBER(8)      NOT NULL  IDENTITY (PK)
   DNI                   VARCHAR2(12)   NOT NULL  UK
   NOMBRES               VARCHAR2(60)   NOT NULL  
   APELLIDOS             VARCHAR2(60)   NOT NULL  
   TELEFONO              VARCHAR2(15)   NOT NULL  
   EMAIL                 VARCHAR2(100)  NULL      
   DIRECCION             VARCHAR2(150)  NULL      
   FECHA_REGISTRO        DATE           NOT NULL  DEFAULT SYSDATE

   Restricciones a crear:
     PK_PROPIETARIO               PRIMARY KEY (ID_PROPIETARIO)
     UK_PROPIETARIO_DNI           UNIQUE (DNI)
     CK_PROPIETARIO_DNI           CHECK (REGEXP_LIKE(DNI, '^[0-9]{8,12}$'))
     CK_PROPIETARIO_EMAIL         CHECK (EMAIL LIKE '%_@_%._%')
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE PROPIETARIO ( ... );



/* ---------------------------------------------------------------------
   VETERINARIO  -  Medicos veterinarios
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_VETERINARIO        NUMBER(5)      NOT NULL  IDENTITY (PK)
   CMVP                  VARCHAR2(10)   NOT NULL  UK
   NOMBRES               VARCHAR2(60)   NOT NULL  
   APELLIDOS             VARCHAR2(60)   NOT NULL  
   TELEFONO              VARCHAR2(15)   NULL      
   EMAIL                 VARCHAR2(100)  NULL      
   ACTIVO                CHAR(1)        NOT NULL  DEFAULT 'S'

   Restricciones a crear:
     PK_VETERINARIO               PRIMARY KEY (ID_VETERINARIO)
     UK_VETERINARIO_CMVP          UNIQUE (CMVP)
     CK_VETERINARIO_ACTIVO        CHECK (ACTIVO IN ('S', 'N'))
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE VETERINARIO ( ... );



/* ---------------------------------------------------------------------
   VETERINARIO_ESPECIALIDAD  -  Relacion N:M veterinario-especialidad
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_VETERINARIO        NUMBER(5)      NOT NULL  PK,FK
   ID_ESPECIALIDAD       NUMBER(4)      NOT NULL  PK,FK

   Restricciones a crear:
     PK_VETERINARIO_ESPECIALIDAD  PRIMARY KEY (ID_VETERINARIO, ID_ESPECIALIDAD)
     FK_VETESP_ESPECIALIDAD       FOREIGN KEY (ID_ESPECIALIDAD) -> ESPECIALIDAD  [restringe (NO ACTION)]
     FK_VETESP_VETERINARIO        FOREIGN KEY (ID_VETERINARIO) -> VETERINARIO  [ON DELETE CASCADE]
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE VETERINARIO_ESPECIALIDAD ( ... );



/* ---------------------------------------------------------------------
   HORARIO_VETERINARIO  -  Bloques de atencion por dia
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_HORARIO            NUMBER(6)      NOT NULL  IDENTITY (PK)
   ID_VETERINARIO        NUMBER(5)      NOT NULL  FK,UK
   DIA_SEMANA            NUMBER(1)      NOT NULL  UK
   HORA_INICIO           VARCHAR2(5)    NOT NULL  UK
   HORA_FIN              VARCHAR2(5)    NOT NULL  

   Restricciones a crear:
     PK_HORARIO_VETERINARIO       PRIMARY KEY (ID_HORARIO)
     FK_HORARIO_VETERINARIO       FOREIGN KEY (ID_VETERINARIO) -> VETERINARIO  [ON DELETE CASCADE]
     UK_HORARIO                   UNIQUE (ID_VETERINARIO, DIA_SEMANA, HORA_INICIO)
     CK_HORARIO_DIA               CHECK (DIA_SEMANA BETWEEN 1 AND 7)
     CK_HORARIO_FIN               CHECK (REGEXP_LIKE(HORA_FIN, '^([01][0-9])
     CK_HORARIO_INICIO            CHECK (REGEXP_LIKE(HORA_INICIO, '^([01][0-9])
     CK_HORARIO_RANGO             CHECK (HORA_FIN > HORA_INICIO)
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE HORARIO_VETERINARIO ( ... );




-- =====================================================================
-- MASCOTAS
-- =====================================================================

/* ---------------------------------------------------------------------
   MASCOTA  -  Pacientes (con padre y madre: relacion recursiva)
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_MASCOTA            NUMBER(8)      NOT NULL  IDENTITY (PK)
   ID_PROPIETARIO        NUMBER(8)      NOT NULL  FK
   ID_RAZA               NUMBER(6)      NOT NULL  FK
   NOMBRE                VARCHAR2(40)   NOT NULL  
   SEXO                  CHAR(1)        NOT NULL  
   FECHA_NACIMIENTO      DATE           NULL      
   COLOR                 VARCHAR2(40)   NULL      
   ESTERILIZADO          CHAR(1)        NOT NULL  DEFAULT 'N'
   ID_PADRE              NUMBER(8)      NULL      FK
   ID_MADRE              NUMBER(8)      NULL      FK
   ESTADO                VARCHAR2(10)   NOT NULL  DEFAULT 'ACTIVO'
   FECHA_REGISTRO        DATE           NOT NULL  DEFAULT SYSDATE

   Restricciones a crear:
     PK_MASCOTA                   PRIMARY KEY (ID_MASCOTA)
     FK_MASCOTA_MADRE             FOREIGN KEY (ID_MADRE) -> MASCOTA  [ON DELETE SET NULL]
     FK_MASCOTA_PADRE             FOREIGN KEY (ID_PADRE) -> MASCOTA  [ON DELETE SET NULL]
     FK_MASCOTA_PROPIETARIO       FOREIGN KEY (ID_PROPIETARIO) -> PROPIETARIO  [restringe (NO ACTION)]
     FK_MASCOTA_RAZA              FOREIGN KEY (ID_RAZA) -> RAZA  [restringe (NO ACTION)]
     CK_MASCOTA_ESTADO            CHECK (ESTADO IN ('ACTIVO', 'FALLECIDO'))
     CK_MASCOTA_ESTERILIZADO      CHECK (ESTERILIZADO IN ('S', 'N'))
     CK_MASCOTA_PADRES            CHECK (ID_PADRE <> ID_MASCOTA AND ID_MADRE <> ID_MASCOTA AND ID_PADRE <> ID_MADRE)
     CK_MASCOTA_SEXO              CHECK (SEXO IN ('M', 'H'))
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE MASCOTA ( ... );




-- =====================================================================
-- AGENDA Y COLA
-- =====================================================================

/* ---------------------------------------------------------------------
   CITA  -  Agenda + estado en la cola de atencion
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_CITA               NUMBER(10)     NOT NULL  IDENTITY (PK)
   ID_MASCOTA            NUMBER(8)      NOT NULL  FK
   ID_VETERINARIO        NUMBER(5)      NULL      FK
   FECHA_HORA            DATE           NOT NULL  
   DURACION_MIN          NUMBER(3)      NOT NULL  DEFAULT 30
   ORIGEN                VARCHAR2(8)    NOT NULL  DEFAULT 'AGENDADA'
   MOTIVO                VARCHAR2(200)  NOT NULL  
   ESTADO                VARCHAR2(11)   NOT NULL  DEFAULT 'PROGRAMADA'
   FECHA_LLEGADA         DATE           NULL      
   FECHA_LLAMADO         DATE           NULL      
   ID_CONSULTORIO        NUMBER(3)      NULL      FK
   FECHA_REGISTRO        DATE           NOT NULL  DEFAULT SYSDATE

   Restricciones a crear:
     PK_CITA                      PRIMARY KEY (ID_CITA)
     FK_CITA_CONSULTORIO          FOREIGN KEY (ID_CONSULTORIO) -> CONSULTORIO  [restringe (NO ACTION)]
     FK_CITA_MASCOTA              FOREIGN KEY (ID_MASCOTA) -> MASCOTA  [restringe (NO ACTION)]
     FK_CITA_VETERINARIO          FOREIGN KEY (ID_VETERINARIO) -> VETERINARIO  [restringe (NO ACTION)]
     CK_CITA_COLA                 CHECK ((ESTADO IN ('PROGRAMADA', 'CANCELADA', 'NO_ASISTIO') AND FECHA_LLEGADA IS NULL AND ID_CONSULTORIO IS NULL) OR (ESTADO = 'EN_ESPERA' AND FECHA_LLEGADA IS NOT NULL AND ID_CONSULTORIO IS NULL) OR (ESTADO IN ('EN_ATENCION', 'ATENDIDA') AND FECHA_LLEGADA IS NOT NULL AND FECHA_LLAMADO IS NOT NULL AND ID_CONSULTORIO IS NOT NULL AND ID_VETERINARIO IS NOT NULL))
     CK_CITA_DURACION             CHECK (DURACION_MIN BETWEEN 10 AND 240)
     CK_CITA_ESTADO               CHECK (ESTADO IN ('PROGRAMADA', 'EN_ESPERA', 'EN_ATENCION', 'ATENDIDA', 'CANCELADA', 'NO_ASISTIO'))
     CK_CITA_FECHAS               CHECK (FECHA_LLAMADO >= FECHA_LLEGADA)
     CK_CITA_ORIGEN               CHECK (ORIGEN IN ('AGENDADA', 'SIN_CITA'))
     CK_CITA_VETERINARIO          CHECK (ORIGEN = 'SIN_CITA' OR ID_VETERINARIO IS NOT NULL)
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE CITA ( ... );



/* ---------------------------------------------------------------------
   TRIAJE  -  Signos vitales y nivel de urgencia (1:1 con la cita)
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_TRIAJE             NUMBER(10)     NOT NULL  IDENTITY (PK)
   ID_CITA               NUMBER(10)     NOT NULL  FK,UK
   FECHA                 DATE           NOT NULL  DEFAULT SYSDATE
   PESO_KG               NUMBER(5,2)    NOT NULL  
   TEMPERATURA           NUMBER(3,1)    NOT NULL  
   FREC_CARDIACA         NUMBER(3)      NULL      
   FREC_RESPIRATORIA     NUMBER(3)      NULL      
   NIVEL_URGENCIA        NUMBER(1)      NOT NULL  
   OBSERVACIONES         VARCHAR2(300)  NULL      

   Restricciones a crear:
     PK_TRIAJE                    PRIMARY KEY (ID_TRIAJE)
     FK_TRIAJE_CITA               FOREIGN KEY (ID_CITA) -> CITA  [ON DELETE CASCADE]
     UK_TRIAJE_CITA               UNIQUE (ID_CITA)
     CK_TRIAJE_FC                 CHECK (FREC_CARDIACA BETWEEN 10 AND 400)
     CK_TRIAJE_FR                 CHECK (FREC_RESPIRATORIA BETWEEN 1 AND 200)
     CK_TRIAJE_PESO               CHECK (PESO_KG > 0)
     CK_TRIAJE_TEMPERATURA        CHECK (TEMPERATURA BETWEEN 30 AND 45)
     CK_TRIAJE_URGENCIA           CHECK (NIVEL_URGENCIA BETWEEN 1 AND 5)
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE TRIAJE ( ... );




-- =====================================================================
-- CLINICA
-- =====================================================================

/* ---------------------------------------------------------------------
   ATENCION  -  Consulta medica realizada (1:1 con la cita)
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_ATENCION           NUMBER(10)     NOT NULL  IDENTITY (PK)
   ID_CITA               NUMBER(10)     NOT NULL  FK,UK
   ID_VETERINARIO        NUMBER(5)      NOT NULL  FK
   FECHA_INICIO          DATE           NOT NULL  
   FECHA_FIN             DATE           NOT NULL  
   ANAMNESIS             VARCHAR2(1000) NOT NULL  
   EXAMEN_FISICO         VARCHAR2(1000) NULL      
   INDICACIONES          VARCHAR2(1000) NULL      

   Restricciones a crear:
     PK_ATENCION                  PRIMARY KEY (ID_ATENCION)
     FK_ATENCION_CITA             FOREIGN KEY (ID_CITA) -> CITA  [restringe (NO ACTION)]
     FK_ATENCION_VETERINARIO      FOREIGN KEY (ID_VETERINARIO) -> VETERINARIO  [restringe (NO ACTION)]
     UK_ATENCION_CITA             UNIQUE (ID_CITA)
     CK_ATENCION_FECHAS           CHECK (FECHA_FIN >= FECHA_INICIO)
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE ATENCION ( ... );



/* ---------------------------------------------------------------------
   ATENCION_DIAGNOSTICO  -  Relacion N:M atencion-diagnostico con TIPO
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_ATENCION           NUMBER(10)     NOT NULL  PK,FK
   ID_DIAGNOSTICO        NUMBER(6)      NOT NULL  PK,FK
   TIPO                  VARCHAR2(10)   NOT NULL  DEFAULT 'PRESUNTIVO'

   Restricciones a crear:
     PK_ATENCION_DIAGNOSTICO      PRIMARY KEY (ID_ATENCION, ID_DIAGNOSTICO)
     FK_ATDIAG_ATENCION           FOREIGN KEY (ID_ATENCION) -> ATENCION  [ON DELETE CASCADE]
     FK_ATDIAG_DIAGNOSTICO        FOREIGN KEY (ID_DIAGNOSTICO) -> DIAGNOSTICO  [restringe (NO ACTION)]
     CK_ATDIAG_TIPO               CHECK (TIPO IN ('PRESUNTIVO', 'DEFINITIVO'))
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE ATENCION_DIAGNOSTICO ( ... );



/* ---------------------------------------------------------------------
   TRATAMIENTO  -  Plan indicado en una atencion
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_TRATAMIENTO        NUMBER(10)     NOT NULL  IDENTITY (PK)
   ID_ATENCION           NUMBER(10)     NOT NULL  FK
   DESCRIPCION           VARCHAR2(300)  NOT NULL  
   SESIONES_PROGRAMADAS  NUMBER(3)      NOT NULL  
   FRECUENCIA_DIAS       NUMBER(3)      NOT NULL  DEFAULT 1
   FECHA_INICIO          DATE           NOT NULL  DEFAULT TRUNC(SYSDATE)
   ESTADO                VARCHAR2(10)   NOT NULL  DEFAULT 'EN_CURSO'

   Restricciones a crear:
     PK_TRATAMIENTO               PRIMARY KEY (ID_TRATAMIENTO)
     FK_TRATAMIENTO_ATENCION      FOREIGN KEY (ID_ATENCION) -> ATENCION  [restringe (NO ACTION)]
     CK_TRATAMIENTO_ESTADO        CHECK (ESTADO IN ('EN_CURSO', 'COMPLETADO', 'SUSPENDIDO'))
     CK_TRATAMIENTO_FRECUENCIA    CHECK (FRECUENCIA_DIAS BETWEEN 1 AND 90)
     CK_TRATAMIENTO_SESIONES      CHECK (SESIONES_PROGRAMADAS BETWEEN 1 AND 100)
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE TRATAMIENTO ( ... );



/* ---------------------------------------------------------------------
   SESION_TRATAMIENTO  -  Cada sesion realizada de un tratamiento
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_SESION             NUMBER(10)     NOT NULL  IDENTITY (PK)
   ID_TRATAMIENTO        NUMBER(10)     NOT NULL  FK,UK
   NUMERO                NUMBER(3)      NOT NULL  UK
   FECHA                 DATE           NOT NULL  DEFAULT SYSDATE
   ID_VETERINARIO        NUMBER(5)      NOT NULL  FK
   OBSERVACIONES         VARCHAR2(300)  NULL      

   Restricciones a crear:
     PK_SESION_TRATAMIENTO        PRIMARY KEY (ID_SESION)
     FK_SESION_TRATAMIENTO        FOREIGN KEY (ID_TRATAMIENTO) -> TRATAMIENTO  [ON DELETE CASCADE]
     FK_SESION_VETERINARIO        FOREIGN KEY (ID_VETERINARIO) -> VETERINARIO  [restringe (NO ACTION)]
     UK_SESION_NUMERO             UNIQUE (ID_TRATAMIENTO, NUMERO)
     CK_SESION_NUMERO             CHECK (NUMERO >= 1)
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE SESION_TRATAMIENTO ( ... );



/* ---------------------------------------------------------------------
   VACUNACION  -  Carnet de vacunacion
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_VACUNACION         NUMBER(10)     NOT NULL  IDENTITY (PK)
   ID_MASCOTA            NUMBER(8)      NOT NULL  FK
   ID_VACUNA             NUMBER(5)      NOT NULL  FK
   ID_VETERINARIO        NUMBER(5)      NOT NULL  FK
   FECHA_APLICACION      DATE           NOT NULL  DEFAULT TRUNC(SYSDATE)
   PROXIMA_DOSIS         DATE           NULL      
   LOTE                  VARCHAR2(20)   NULL      

   Restricciones a crear:
     PK_VACUNACION                PRIMARY KEY (ID_VACUNACION)
     FK_VACUNACION_MASCOTA        FOREIGN KEY (ID_MASCOTA) -> MASCOTA  [restringe (NO ACTION)]
     FK_VACUNACION_VACUNA         FOREIGN KEY (ID_VACUNA) -> VACUNA  [restringe (NO ACTION)]
     FK_VACUNACION_VETERINARIO    FOREIGN KEY (ID_VETERINARIO) -> VETERINARIO  [restringe (NO ACTION)]
     CK_VACUNACION_PROXIMA        CHECK (PROXIMA_DOSIS > FECHA_APLICACION)
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE VACUNACION ( ... );




-- =====================================================================
-- INVENTARIO
-- =====================================================================

/* ---------------------------------------------------------------------
   MEDICAMENTO  -  Insumos de uso interno (no es tienda)
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_MEDICAMENTO        NUMBER(6)      NOT NULL  IDENTITY (PK)
   NOMBRE                VARCHAR2(80)   NOT NULL  UK
   PRESENTACION          VARCHAR2(60)   NOT NULL  UK
   UNIDAD                VARCHAR2(15)   NOT NULL  
   STOCK_ACTUAL          NUMBER(8,2)    NOT NULL  DEFAULT 0
   STOCK_MINIMO          NUMBER(8,2)    NOT NULL  DEFAULT 0
   ACTIVO                CHAR(1)        NOT NULL  DEFAULT 'S'

   Restricciones a crear:
     PK_MEDICAMENTO               PRIMARY KEY (ID_MEDICAMENTO)
     UK_MEDICAMENTO               UNIQUE (NOMBRE, PRESENTACION)
     CK_MEDICAMENTO_ACTIVO        CHECK (ACTIVO IN ('S', 'N'))
     CK_MEDICAMENTO_MINIMO        CHECK (STOCK_MINIMO >= 0)
     CK_MEDICAMENTO_STOCK         CHECK (STOCK_ACTUAL >= 0)
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE MEDICAMENTO ( ... );



/* ---------------------------------------------------------------------
   MOVIMIENTO_STOCK  -  Kardex: entradas y salidas
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_MOVIMIENTO         NUMBER(10)     NOT NULL  IDENTITY (PK)
   ID_MEDICAMENTO        NUMBER(6)      NOT NULL  FK
   TIPO                  VARCHAR2(7)    NOT NULL  
   CANTIDAD              NUMBER(8,2)    NOT NULL  
   FECHA                 DATE           NOT NULL  DEFAULT SYSDATE
   ID_ATENCION           NUMBER(10)     NULL      FK
   MOTIVO                VARCHAR2(150)  NULL      

   Restricciones a crear:
     PK_MOVIMIENTO_STOCK          PRIMARY KEY (ID_MOVIMIENTO)
     FK_MOVIMIENTO_ATENCION       FOREIGN KEY (ID_ATENCION) -> ATENCION  [restringe (NO ACTION)]
     FK_MOVIMIENTO_MEDICAMENTO    FOREIGN KEY (ID_MEDICAMENTO) -> MEDICAMENTO  [restringe (NO ACTION)]
     CK_MOVIMIENTO_ATENCION       CHECK (TIPO = 'SALIDA' OR ID_ATENCION IS NULL)
     CK_MOVIMIENTO_CANTIDAD       CHECK (CANTIDAD > 0)
     CK_MOVIMIENTO_TIPO           CHECK (TIPO IN ('ENTRADA', 'SALIDA'))
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE MOVIMIENTO_STOCK ( ... );




-- =====================================================================
-- SISTEMA
-- =====================================================================

/* ---------------------------------------------------------------------
   USUARIO  -  Cuentas de la aplicacion (clave en SHA-256)
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_USUARIO            NUMBER(5)      NOT NULL  IDENTITY (PK)
   USUARIO               VARCHAR2(30)   NOT NULL  UK
   CLAVE_HASH            VARCHAR2(64)   NOT NULL  
   NOMBRE_COMPLETO       VARCHAR2(100)  NOT NULL  
   ROL                   VARCHAR2(11)   NOT NULL  
   ID_VETERINARIO        NUMBER(5)      NULL      FK,UK
   ACTIVO                CHAR(1)        NOT NULL  DEFAULT 'S'
   ULTIMO_ACCESO         DATE           NULL      

   Restricciones a crear:
     PK_USUARIO                   PRIMARY KEY (ID_USUARIO)
     FK_USUARIO_VETERINARIO       FOREIGN KEY (ID_VETERINARIO) -> VETERINARIO  [restringe (NO ACTION)]
     UK_USUARIO                   UNIQUE (USUARIO)
     UK_USUARIO_VETERINARIO       UNIQUE (ID_VETERINARIO)
     CK_USUARIO_ACTIVO            CHECK (ACTIVO IN ('S', 'N'))
     CK_USUARIO_FORMATO           CHECK (REGEXP_LIKE(USUARIO, '^[a-z][a-z0-9._]{2,29}$'))
     CK_USUARIO_ROL               CHECK (ROL IN ('ADMIN', 'RECEPCION', 'VETERINARIO'))
     CK_USUARIO_VET               CHECK (ROL <> 'VETERINARIO' OR ID_VETERINARIO IS NOT NULL)
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE USUARIO ( ... );



/* ---------------------------------------------------------------------
   AUDITORIA  -  Historial de cambios (la llenan triggers)
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_AUDITORIA          NUMBER(12)     NOT NULL  IDENTITY (PK)
   TABLA                 VARCHAR2(30)   NOT NULL  
   OPERACION             VARCHAR2(6)    NOT NULL  
   ID_REGISTRO           NUMBER(12)     NOT NULL  
   DETALLE               VARCHAR2(400)  NULL      
   USUARIO_BD            VARCHAR2(128)  NOT NULL  DEFAULT USER
   USUARIO_APP           VARCHAR2(64)   NULL      DEFAULT SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER')
   FECHA                 DATE           NOT NULL  DEFAULT SYSDATE

   Restricciones a crear:
     PK_AUDITORIA                 PRIMARY KEY (ID_AUDITORIA)
     CK_AUDITORIA_OPERACION       CHECK (OPERACION IN ('INSERT', 'UPDATE', 'DELETE'))
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE AUDITORIA ( ... );



/* ---------------------------------------------------------------------
   ALERTA  -  Avisos generados por el job nocturno
   ---------------------------------------------------------------------
   Columna               Tipo           Nulo      Default / notas
   ID_ALERTA             NUMBER(10)     NOT NULL  IDENTITY (PK)
   TIPO                  VARCHAR2(7)    NOT NULL  
   ID_REFERENCIA         NUMBER(10)     NOT NULL  
   MENSAJE               VARCHAR2(300)  NOT NULL  
   FECHA                 DATE           NOT NULL  DEFAULT SYSDATE
   LEIDA                 CHAR(1)        NOT NULL  DEFAULT 'N'

   Restricciones a crear:
     PK_ALERTA                    PRIMARY KEY (ID_ALERTA)
     CK_ALERTA_LEIDA              CHECK (LEIDA IN ('S', 'N'))
     CK_ALERTA_TIPO               CHECK (TIPO IN ('VACUNA', 'STOCK', 'CITA'))
   --------------------------------------------------------------------- */
-- TODO  CREATE TABLE ALERTA ( ... );



-- Comprobar
SELECT table_name FROM user_tables ORDER BY table_name;
SELECT COUNT(*) AS restricciones FROM user_constraints WHERE constraint_name NOT LIKE 'SYS%';  -- deben ser 109
