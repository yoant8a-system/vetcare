/* =====================================================================
   SOLUCION - 04 DATOS INICIALES
   Ejecutar como: VETERINARIA
   ---------------------------------------------------------------------
   Los ID son IDENTITY (GENERATED ALWAYS): NO se escriben en el INSERT.
   Para las FK se busca el ID con una subconsulta por un dato unico
   (nombre, DNI, CMVP...). Asi el script no depende de que ID salio.
   ===================================================================== */

-- ------------------------------------------------------------ especies y razas
INSERT INTO ESPECIE (NOMBRE) VALUES ('Perro');
INSERT INTO ESPECIE (NOMBRE) VALUES ('Gato');
INSERT INTO ESPECIE (NOMBRE) VALUES ('Conejo');
INSERT INTO ESPECIE (NOMBRE) VALUES ('Ave');

INSERT INTO RAZA (ID_ESPECIE, NOMBRE)
SELECT e.ID_ESPECIE, r.NOMBRE
  FROM ESPECIE e
  JOIN (SELECT 'Perro' ESP, 'Mestizo' NOMBRE FROM DUAL
        UNION ALL SELECT 'Perro', 'Labrador Retriever' FROM DUAL
        UNION ALL SELECT 'Perro', 'Pastor Aleman' FROM DUAL
        UNION ALL SELECT 'Perro', 'Shih Tzu' FROM DUAL
        UNION ALL SELECT 'Perro', 'Schnauzer' FROM DUAL
        UNION ALL SELECT 'Perro', 'Golden Retriever' FROM DUAL
        UNION ALL SELECT 'Perro', 'Bulldog Frances' FROM DUAL
        UNION ALL SELECT 'Perro', 'Perro sin pelo del Peru' FROM DUAL
        UNION ALL SELECT 'Gato',  'Mestizo' FROM DUAL
        UNION ALL SELECT 'Gato',  'Siames' FROM DUAL
        UNION ALL SELECT 'Gato',  'Persa' FROM DUAL
        UNION ALL SELECT 'Gato',  'Angora' FROM DUAL
        UNION ALL SELECT 'Conejo','Cabeza de Leon' FROM DUAL
        UNION ALL SELECT 'Conejo','Mini Lop' FROM DUAL
        UNION ALL SELECT 'Ave',   'Periquito' FROM DUAL
        UNION ALL SELECT 'Ave',   'Canario' FROM DUAL) r
    ON r.ESP = e.NOMBRE;

-- ------------------------------------------------------------ especialidades y consultorios
INSERT INTO ESPECIALIDAD (NOMBRE) VALUES ('Medicina general');
INSERT INTO ESPECIALIDAD (NOMBRE) VALUES ('Cirugia');
INSERT INTO ESPECIALIDAD (NOMBRE) VALUES ('Dermatologia');
INSERT INTO ESPECIALIDAD (NOMBRE) VALUES ('Cardiologia');
INSERT INTO ESPECIALIDAD (NOMBRE) VALUES ('Animales exoticos');

INSERT INTO CONSULTORIO (NOMBRE) VALUES ('Consultorio 1');
INSERT INTO CONSULTORIO (NOMBRE) VALUES ('Consultorio 2');
INSERT INTO CONSULTORIO (NOMBRE) VALUES ('Consultorio 3');
INSERT INTO CONSULTORIO (NOMBRE) VALUES ('Emergencias');

-- ------------------------------------------------------------ diagnosticos (catalogo)
INSERT INTO DIAGNOSTICO (CODIGO, NOMBRE, CATEGORIA, ID_ESPECIE)
SELECT d.CODIGO, d.NOMBRE, d.CATEGORIA, (SELECT ID_ESPECIE FROM ESPECIE WHERE NOMBRE = d.ESP)
  FROM (SELECT 'INF-001' CODIGO, 'Parvovirosis canina' NOMBRE, 'Infecciosa' CATEGORIA, 'Perro' ESP FROM DUAL
        UNION ALL SELECT 'INF-002', 'Distemper (moquillo)', 'Infecciosa', 'Perro' FROM DUAL
        UNION ALL SELECT 'INF-003', 'Traqueobronquitis infecciosa (tos de las perreras)', 'Infecciosa', 'Perro' FROM DUAL
        UNION ALL SELECT 'INF-004', 'Rinotraqueitis felina', 'Infecciosa', 'Gato' FROM DUAL
        UNION ALL SELECT 'INF-005', 'Leucemia felina', 'Infecciosa', 'Gato' FROM DUAL
        UNION ALL SELECT 'DIG-001', 'Gastroenteritis aguda', 'Digestiva', NULL FROM DUAL
        UNION ALL SELECT 'DIG-002', 'Parasitosis intestinal', 'Digestiva', NULL FROM DUAL
        UNION ALL SELECT 'DIG-003', 'Cuerpo extrano gastrointestinal', 'Digestiva', NULL FROM DUAL
        UNION ALL SELECT 'DIG-004', 'Estasis gastrointestinal', 'Digestiva', 'Conejo' FROM DUAL
        UNION ALL SELECT 'DER-001', 'Dermatitis alergica', 'Dermatologica', NULL FROM DUAL
        UNION ALL SELECT 'DER-002', 'Sarna demodecica', 'Dermatologica', 'Perro' FROM DUAL
        UNION ALL SELECT 'DER-003', 'Dermatofitosis (tina)', 'Dermatologica', NULL FROM DUAL
        UNION ALL SELECT 'DER-004', 'Otitis externa', 'Dermatologica', NULL FROM DUAL
        UNION ALL SELECT 'RES-001', 'Neumonia', 'Respiratoria', NULL FROM DUAL
        UNION ALL SELECT 'RES-002', 'Asma felino', 'Respiratoria', 'Gato' FROM DUAL
        UNION ALL SELECT 'CAR-001', 'Insuficiencia cardiaca congestiva', 'Cardiologica', NULL FROM DUAL
        UNION ALL SELECT 'URI-001', 'Cistitis', 'Urinaria', NULL FROM DUAL
        UNION ALL SELECT 'URI-002', 'Enfermedad renal cronica', 'Urinaria', NULL FROM DUAL
        UNION ALL SELECT 'TRA-001', 'Fractura de extremidad', 'Traumatologica', NULL FROM DUAL
        UNION ALL SELECT 'TRA-002', 'Herida por mordedura', 'Traumatologica', NULL FROM DUAL
        UNION ALL SELECT 'OFT-001', 'Conjuntivitis', 'Oftalmologica', NULL FROM DUAL
        UNION ALL SELECT 'DEN-001', 'Enfermedad periodontal', 'Dental', NULL FROM DUAL
        UNION ALL SELECT 'DEN-002', 'Maloclusion dental', 'Dental', 'Conejo' FROM DUAL
        UNION ALL SELECT 'GEN-001', 'Control sano / chequeo general', 'Preventiva', NULL FROM DUAL
        UNION ALL SELECT 'GEN-002', 'Obesidad', 'Metabolica', NULL FROM DUAL) d;

-- ------------------------------------------------------------ vacunas por especie
INSERT INTO VACUNA (NOMBRE, ID_ESPECIE, REFUERZO_DIAS)
SELECT v.NOMBRE, (SELECT ID_ESPECIE FROM ESPECIE WHERE NOMBRE = v.ESP), v.DIAS
  FROM (SELECT 'Antirrabica' NOMBRE, 'Perro' ESP, 365 DIAS FROM DUAL
        UNION ALL SELECT 'Quintuple (DHPPL)', 'Perro', 365 FROM DUAL
        UNION ALL SELECT 'Sextuple', 'Perro', 365 FROM DUAL
        UNION ALL SELECT 'Tos de las perreras', 'Perro', 180 FROM DUAL
        UNION ALL SELECT 'Antirrabica', 'Gato', 365 FROM DUAL
        UNION ALL SELECT 'Triple felina', 'Gato', 365 FROM DUAL
        UNION ALL SELECT 'Leucemia felina', 'Gato', 365 FROM DUAL
        UNION ALL SELECT 'Mixomatosis', 'Conejo', 180 FROM DUAL
        UNION ALL SELECT 'Enfermedad hemorragica viral', 'Conejo', 365 FROM DUAL) v;

-- ------------------------------------------------------------ veterinarios
INSERT INTO VETERINARIO (CMVP, NOMBRES, APELLIDOS, TELEFONO, EMAIL) VALUES ('10234', 'Lucia',   'Mendoza Rojas',   '987654321', 'lmendoza@vet.pe');
INSERT INTO VETERINARIO (CMVP, NOMBRES, APELLIDOS, TELEFONO, EMAIL) VALUES ('10587', 'Carlos',  'Quispe Huaman',   '987111222', 'cquispe@vet.pe');
INSERT INTO VETERINARIO (CMVP, NOMBRES, APELLIDOS, TELEFONO, EMAIL) VALUES ('11020', 'Andrea',  'Salazar Vega',    '986333444', 'asalazar@vet.pe');
INSERT INTO VETERINARIO (CMVP, NOMBRES, APELLIDOS, TELEFONO, EMAIL) VALUES ('11456', 'Jorge',   'Paredes Linares', '985555666', 'jparedes@vet.pe');

INSERT INTO VETERINARIO_ESPECIALIDAD (ID_VETERINARIO, ID_ESPECIALIDAD)
SELECT v.ID_VETERINARIO, e.ID_ESPECIALIDAD
  FROM VETERINARIO v
  JOIN (SELECT '10234' CMVP, 'Medicina general' ESP FROM DUAL
        UNION ALL SELECT '10234', 'Dermatologia' FROM DUAL
        UNION ALL SELECT '10587', 'Medicina general' FROM DUAL
        UNION ALL SELECT '10587', 'Cirugia' FROM DUAL
        UNION ALL SELECT '11020', 'Cardiologia' FROM DUAL
        UNION ALL SELECT '11020', 'Medicina general' FROM DUAL
        UNION ALL SELECT '11456', 'Animales exoticos' FROM DUAL
        UNION ALL SELECT '11456', 'Cirugia' FROM DUAL) x ON x.CMVP = v.CMVP
  JOIN ESPECIALIDAD e ON e.NOMBRE = x.ESP;

-- Horarios: lunes a viernes para todos; sabado por la mañana para dos de ellos
INSERT INTO HORARIO_VETERINARIO (ID_VETERINARIO, DIA_SEMANA, HORA_INICIO, HORA_FIN)
SELECT v.ID_VETERINARIO, d.DIA,
       CASE WHEN v.CMVP IN ('10234', '11020') THEN '08:00' ELSE '14:00' END,
       CASE WHEN v.CMVP IN ('10234', '11020') THEN '14:00' ELSE '20:00' END
  FROM VETERINARIO v
 CROSS JOIN (SELECT LEVEL AS DIA FROM DUAL CONNECT BY LEVEL <= 5) d;

INSERT INTO HORARIO_VETERINARIO (ID_VETERINARIO, DIA_SEMANA, HORA_INICIO, HORA_FIN)
SELECT ID_VETERINARIO, 6, '09:00', '13:00' FROM VETERINARIO WHERE CMVP IN ('10587', '11456');

-- ------------------------------------------------------------ usuarios de la aplicacion
-- Clave guardada como SHA-256 de 'usuario:clave' (el usuario actua de "sal").
-- Claves de prueba:  admin/admin123   recepcion/recep123   lmendoza, cquispe, asalazar, jparedes / vet123
INSERT INTO USUARIO (USUARIO, CLAVE_HASH, NOMBRE_COMPLETO, ROL)
VALUES ('admin', RAWTOHEX(STANDARD_HASH('admin:admin123', 'SHA256')), 'Administrador del sistema', 'ADMIN');
INSERT INTO USUARIO (USUARIO, CLAVE_HASH, NOMBRE_COMPLETO, ROL)
VALUES ('recepcion', RAWTOHEX(STANDARD_HASH('recepcion:recep123', 'SHA256')), 'Rosa Recepcion', 'RECEPCION');

INSERT INTO USUARIO (USUARIO, CLAVE_HASH, NOMBRE_COMPLETO, ROL, ID_VETERINARIO)
SELECT LOWER(SUBSTR(NOMBRES, 1, 1) || SUBSTR(APELLIDOS, 1, INSTR(APELLIDOS, ' ') - 1)),
       RAWTOHEX(STANDARD_HASH(LOWER(SUBSTR(NOMBRES, 1, 1) || SUBSTR(APELLIDOS, 1, INSTR(APELLIDOS, ' ') - 1)) || ':vet123', 'SHA256')),
       'Dr(a). ' || NOMBRES || ' ' || APELLIDOS, 'VETERINARIO', ID_VETERINARIO
  FROM VETERINARIO;

-- ------------------------------------------------------------ medicamentos / insumos
-- El stock empieza en 0: se carga con movimientos de ENTRADA (kardex), ver etapa3_logica/08_datos_demo.sql
INSERT INTO MEDICAMENTO (NOMBRE, PRESENTACION, UNIDAD, STOCK_MINIMO) VALUES ('Amoxicilina', 'Suspension 250 mg/5 ml', 'ml', 100);
INSERT INTO MEDICAMENTO (NOMBRE, PRESENTACION, UNIDAD, STOCK_MINIMO) VALUES ('Meloxicam', 'Inyectable 5 mg/ml', 'ml', 20);
INSERT INTO MEDICAMENTO (NOMBRE, PRESENTACION, UNIDAD, STOCK_MINIMO) VALUES ('Ivermectina', 'Inyectable 1%', 'ml', 20);
INSERT INTO MEDICAMENTO (NOMBRE, PRESENTACION, UNIDAD, STOCK_MINIMO) VALUES ('Metronidazol', 'Tableta 250 mg', 'tableta', 50);
INSERT INTO MEDICAMENTO (NOMBRE, PRESENTACION, UNIDAD, STOCK_MINIMO) VALUES ('Cloruro de sodio 0.9%', 'Frasco 1 L', 'frasco', 10);
INSERT INTO MEDICAMENTO (NOMBRE, PRESENTACION, UNIDAD, STOCK_MINIMO) VALUES ('Dexametasona', 'Inyectable 4 mg/ml', 'ml', 20);
INSERT INTO MEDICAMENTO (NOMBRE, PRESENTACION, UNIDAD, STOCK_MINIMO) VALUES ('Ranitidina', 'Inyectable 25 mg/ml', 'ml', 20);
INSERT INTO MEDICAMENTO (NOMBRE, PRESENTACION, UNIDAD, STOCK_MINIMO) VALUES ('Prazicuantel', 'Tableta 50 mg', 'tableta', 30);
INSERT INTO MEDICAMENTO (NOMBRE, PRESENTACION, UNIDAD, STOCK_MINIMO) VALUES ('Clorhexidina', 'Solucion 2%', 'ml', 200);
INSERT INTO MEDICAMENTO (NOMBRE, PRESENTACION, UNIDAD, STOCK_MINIMO) VALUES ('Ketoconazol', 'Shampoo 2%', 'ml', 250);
INSERT INTO MEDICAMENTO (NOMBRE, PRESENTACION, UNIDAD, STOCK_MINIMO) VALUES ('Tramadol', 'Inyectable 50 mg/ml', 'ml', 10);
INSERT INTO MEDICAMENTO (NOMBRE, PRESENTACION, UNIDAD, STOCK_MINIMO) VALUES ('Gasas esteriles', 'Paquete x 10', 'paquete', 15);

-- ------------------------------------------------------------ propietarios
INSERT INTO PROPIETARIO (DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL, DIRECCION) VALUES ('45879632', 'Maria',    'Perez Gonzales',   '965432187', 'maria.perez@mail.com', 'Av. Arequipa 1520, Lince');
INSERT INTO PROPIETARIO (DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL, DIRECCION) VALUES ('41236578', 'Jose',     'Ramirez Torres',   '954123698', NULL, 'Jr. Huancavelica 340, Cercado');
INSERT INTO PROPIETARIO (DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL, DIRECCION) VALUES ('70125489', 'Ana',      'Flores Castillo',  '943215678', 'ana.flores@mail.com', 'Calle Los Pinos 225, Surco');
INSERT INTO PROPIETARIO (DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL, DIRECCION) VALUES ('46325871', 'Luis',     'Chavez Rios',      '932147856', 'lchavez@mail.com', 'Av. Brasil 2100, Pueblo Libre');
INSERT INTO PROPIETARIO (DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL, DIRECCION) VALUES ('72589634', 'Carmen',   'Diaz Huerta',      '921456387', NULL, 'Mz. B Lt. 12, Los Olivos');
INSERT INTO PROPIETARIO (DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL, DIRECCION) VALUES ('43698521', 'Pedro',    'Sanchez Medina',   '998745632', 'psanchez@mail.com', 'Av. La Marina 890, San Miguel');
INSERT INTO PROPIETARIO (DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL, DIRECCION) VALUES ('75214896', 'Rosa',     'Vargas Ccori',     '987452136', NULL, 'Jr. Junin 455, Rimac');
INSERT INTO PROPIETARIO (DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL, DIRECCION) VALUES ('40258963', 'Miguel',   'Torres Alvarado',  '976321458', 'mtorres@mail.com', 'Calle Las Flores 78, Miraflores');
INSERT INTO PROPIETARIO (DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL, DIRECCION) VALUES ('71458236', 'Lucia',    'Gutierrez Pinto',  '965874123', NULL, 'Av. Universitaria 3300, SMP');
INSERT INTO PROPIETARIO (DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL, DIRECCION) VALUES ('44785123', 'Fernando', 'Castro Nunez',     '954789632', 'fcastro@mail.com', 'Jr. Ica 210, Breña');

-- ------------------------------------------------------------ mascotas
-- Primero los "padres", despues las crias (para poder referenciarlos)
INSERT INTO MASCOTA (ID_PROPIETARIO, ID_RAZA, NOMBRE, SEXO, FECHA_NACIMIENTO, COLOR, ESTERILIZADO)
SELECT (SELECT ID_PROPIETARIO FROM PROPIETARIO WHERE DNI = m.DNI),
       (SELECT r.ID_RAZA FROM RAZA r JOIN ESPECIE e ON e.ID_ESPECIE = r.ID_ESPECIE WHERE e.NOMBRE = m.ESP AND r.NOMBRE = m.RAZA),
       m.NOMBRE, m.SEXO, ADD_MONTHS(TRUNC(SYSDATE), -m.MESES), m.COLOR, m.EST
  FROM (SELECT '45879632' DNI, 'Perro' ESP, 'Labrador Retriever' RAZA, 'Max' NOMBRE, 'M' SEXO, 72 MESES, 'Dorado' COLOR, 'N' EST FROM DUAL
        UNION ALL SELECT '41236578', 'Perro', 'Labrador Retriever', 'Luna', 'H', 66, 'Negro', 'N' FROM DUAL
        UNION ALL SELECT '70125489', 'Gato',  'Siames', 'Michi', 'H', 40, 'Crema', 'S' FROM DUAL
        UNION ALL SELECT '46325871', 'Perro', 'Mestizo', 'Firulais', 'M', 30, 'Marron', 'S' FROM DUAL
        UNION ALL SELECT '72589634', 'Perro', 'Shih Tzu', 'Bobby', 'M', 24, 'Blanco y gris', 'N' FROM DUAL
        UNION ALL SELECT '43698521', 'Gato',  'Persa', 'Garfield', 'M', 60, 'Naranja', 'S' FROM DUAL
        UNION ALL SELECT '75214896', 'Conejo','Mini Lop', 'Copito', 'M', 18, 'Blanco', 'N' FROM DUAL
        UNION ALL SELECT '40258963', 'Perro', 'Pastor Aleman', 'Rocky', 'M', 48, 'Negro y fuego', 'N' FROM DUAL
        UNION ALL SELECT '71458236', 'Gato',  'Mestizo', 'Pelusa', 'H', 14, 'Atigrado', 'N' FROM DUAL
        UNION ALL SELECT '44785123', 'Ave',   'Periquito', 'Kiwi', 'M', 20, 'Verde', 'N' FROM DUAL
        UNION ALL SELECT '45879632', 'Gato',  'Mestizo', 'Tom', 'M', 36, 'Gris', 'S' FROM DUAL
        UNION ALL SELECT '46325871', 'Perro', 'Schnauzer', 'Canela', 'H', 52, 'Sal y pimienta', 'S' FROM DUAL
        UNION ALL SELECT '43698521', 'Perro', 'Bulldog Frances', 'Toby', 'M', 28, 'Atigrado', 'N' FROM DUAL
        UNION ALL SELECT '40258963', 'Perro', 'Golden Retriever', 'Nala', 'H', 44, 'Dorado', 'N' FROM DUAL) m;

-- Crias de Max (padre) y Luna (madre): genealogia para el reporte con CONNECT BY
INSERT INTO MASCOTA (ID_PROPIETARIO, ID_RAZA, NOMBRE, SEXO, FECHA_NACIMIENTO, COLOR, ID_PADRE, ID_MADRE)
SELECT (SELECT ID_PROPIETARIO FROM PROPIETARIO WHERE DNI = c.DNI),
       (SELECT r.ID_RAZA FROM RAZA r JOIN ESPECIE e ON e.ID_ESPECIE = r.ID_ESPECIE WHERE e.NOMBRE = 'Perro' AND r.NOMBRE = 'Labrador Retriever'),
       c.NOMBRE, c.SEXO, ADD_MONTHS(TRUNC(SYSDATE), -10), c.COLOR,
       (SELECT ID_MASCOTA FROM MASCOTA WHERE NOMBRE = 'Max'),
       (SELECT ID_MASCOTA FROM MASCOTA WHERE NOMBRE = 'Luna')
  FROM (SELECT '45879632' DNI, 'Thor' NOMBRE, 'M' SEXO, 'Dorado' COLOR FROM DUAL
        UNION ALL SELECT '70125489', 'Kira', 'H', 'Negro' FROM DUAL) c;

-- Nieto: hijo de Thor y Nala
INSERT INTO MASCOTA (ID_PROPIETARIO, ID_RAZA, NOMBRE, SEXO, FECHA_NACIMIENTO, COLOR, ID_PADRE, ID_MADRE)
SELECT (SELECT ID_PROPIETARIO FROM PROPIETARIO WHERE DNI = '40258963'),
       (SELECT r.ID_RAZA FROM RAZA r JOIN ESPECIE e ON e.ID_ESPECIE = r.ID_ESPECIE WHERE e.NOMBRE = 'Perro' AND r.NOMBRE = 'Mestizo'),
       'Simba', 'M', ADD_MONTHS(TRUNC(SYSDATE), -2), 'Dorado claro',
       (SELECT ID_MASCOTA FROM MASCOTA WHERE NOMBRE = 'Thor'),
       (SELECT ID_MASCOTA FROM MASCOTA WHERE NOMBRE = 'Nala')
  FROM DUAL;

COMMIT;

-- Comprobar
SELECT 'ESPECIE' TABLA, COUNT(*) FILAS FROM ESPECIE UNION ALL
SELECT 'RAZA', COUNT(*) FROM RAZA UNION ALL
SELECT 'DIAGNOSTICO', COUNT(*) FROM DIAGNOSTICO UNION ALL
SELECT 'VACUNA', COUNT(*) FROM VACUNA UNION ALL
SELECT 'VETERINARIO', COUNT(*) FROM VETERINARIO UNION ALL
SELECT 'HORARIO_VETERINARIO', COUNT(*) FROM HORARIO_VETERINARIO UNION ALL
SELECT 'USUARIO', COUNT(*) FROM USUARIO UNION ALL
SELECT 'MEDICAMENTO', COUNT(*) FROM MEDICAMENTO UNION ALL
SELECT 'PROPIETARIO', COUNT(*) FROM PROPIETARIO UNION ALL
SELECT 'MASCOTA', COUNT(*) FROM MASCOTA;
