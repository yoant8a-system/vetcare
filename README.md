# VetCare — Sistema de gestión veterinaria

Proyecto del curso de **Administración de Base de Datos**. Es un sistema **cliente-servidor web** sobre
**Oracle Database XE 21c**, con la lógica de negocio en **PL/SQL**.

- **Servidor:** Spring Boot (Java 17) + JDBC puro (`NamedParameterJdbcTemplate`). **Sin JPA/Hibernate**: todo el SQL está a la vista.
- **Clientes:** cualquier navegador de la red (`http://IP-DEL-SERVIDOR:8080`), incluido un TV para la sala de espera.
- **Plantilla visual:** Bootstrap 5 + Bootstrap Icons + Chart.js, servidos desde el propio proyecto (funciona sin internet).

## Módulos

| Módulo | Qué hace | Oracle detrás |
|---|---|---|
| Tablero | Indicadores, gráfico de 14 días y gráfico por especie | Subconsultas escalares, `CONNECT BY LEVEL` |
| Propietarios y mascotas | CRUD, ficha clínica con pestañas y genealogía | Vista con 5 JOIN, trigger **compuesto** de padres, `CONNECT BY` |
| Agenda de citas | Programar, cancelar, llegada con triaje, pacientes sin cita | `PKG_CITAS`: horario, choques, bloqueo `FOR UPDATE` |
| Consultorio (veterinario) | Cola por urgencia, llamar al siguiente, registrar la atención | `PKG_ATENCION`: `SKIP LOCKED`, colecciones `T_NUMEROS`, SAVEPOINT |
| Pantalla de sala | TV con anuncios por voz y animación | Vista `VW_PANTALLA` (JSON cada 3 s) |
| Tratamientos | Sesiones y avance | `PKG_TRATAMIENTO`, función usada dentro de un SELECT |
| Vacunación | Carnet y próxima dosis automática | Trigger que valida la especie y calcula la fecha |
| Inventario | Kardex de entradas y salidas, stock bajo | Trigger de stock, kardex inmutable |
| Reportes (9) | Imprimibles o exportables a PDF | `PKG_REPORTES` con `SYS_REFCURSOR`: ROLLUP, DENSE_RANK, LAG, vista materializada… |
| Alertas | Vacunas vencidas, stock bajo, no asistió | Job `DBMS_SCHEDULER` nocturno + `MERGE` |
| Usuarios y auditoría | Login por roles; quién cambió qué | `STANDARD_HASH`, triggers de auditoría, `CLIENT_IDENTIFIER` |

Usuarios de prueba: `admin`/`admin123` · `recepcion`/`recep123` · `lmendoza`, `cquispe`, `asalazar`, `jparedes` con clave `vet123`.

---

## 1. Puesta en marcha

### Base de datos (en SQL Developer)
| Orden | Script | Como |
|---|---|---|
| 1 | `01_usuario_y_permisos.sql` | SYSTEM |
| 2–4 | `02_tablas`, `03_indices_y_tipos`, `04_datos_iniciales` | VETERINARIA |
| 5–7 | `05_vistas`, `06_triggers`, `07_paquetes` | VETERINARIA |
| 8 | `08_datos_demo.sql` (5 meses de historia para los reportes) | VETERINARIA |
| 9 | `09_job_programado.sql` | VETERINARIA |
| (10) | `10_rol_app_opcional.sql` | SYSTEM + VETERINARIA |

- En `sql/` están las **plantillas**, que escribe el equipo. En `soluciones/` están las versiones completas y **probadas en Oracle XE 21c**.
- Para empezar de nuevo: `99_borrar_todo.sql`.

### Aplicación
1. Copie `config/db.properties.example` como `config/db.properties` y ponga la contraseña.
2. Haga doble clic en **`iniciar.bat`**, o ejecute `mvn spring-boot:run`, y abra http://localhost:8080.
3. En NetBeans o IntelliJ: abra la carpeta (detectan el `pom.xml`) y ejecute `VeterinariaApplication`.

---

## 2. Plantilla vs. solución (cómo trabaja el equipo)

Las **81 sentencias SQL** de la app están vacías a propósito en los `*Repositorio.java`:

```java
/**
 * [PR-01] Buscar propietarios por DNI, nombres o apellidos...
 * Columnas: ID_PROPIETARIO, DNI, NOMBRES, APELLIDOS, TELEFONO, EMAIL, MASCOTAS
 * Parametros: :texto
 */
private static final String PR_01 = Sql.pendiente("PR-01");
```

- Mientras falten, la página correspondiente muestra **"Falta implementar [PR-01]"** y dice dónde escribirla.
- La lista completa, con columnas y parámetros, está en `sql/consultas_app.sql`.
- Con **`app.completar_con_solucion=true`** en `config/db.properties`, la app toma de la solución **solo las sentencias que aún falten**.
  - Sirve para probar el sistema completo desde el primer día.
  - Las que el equipo ya escribió no se tocan.
  - En el menú aparece la etiqueta "Completando con la solución".

El plan por etapas y las listas de cotejo están en [`aprendizaje/README.md`](aprendizaje/README.md).

---

## 3. Estructura

```
aprendizaje/           enunciado (etapa 1) y listas de cotejo
config/                db.properties (no se sube a GitHub)
soluciones/            respuestas probadas: etapa1_modelo_ER/, etapa2_creacion/, etapa3_logica/
sql/                   plantillas para el equipo + consultas_app.sql
src/main/java/com/vet/
  db/                  Db (SQL con :parametros), Plsql (procedimientos, colecciones, cursores), errores ORA
  seguridad/           sesion, roles por ruta, CLIENT_IDENTIFIER para la auditoria
  modulos/<modulo>/    XxxRepositorio (el SQL) + XxxController (las pantallas)
src/main/resources/
  templates/           paginas Thymeleaf (fragments/layout.html = plantilla con menu)
  static/              css, js e imagenes (SVG propios)
```

## 4. Red: los compañeros como clientes

El servidor y Oracle corren en una sola laptop. Los demás solo necesitan el navegador:

1. Hay que permitir el puerto **8080** en el Firewall de Windows de esa laptop.
2. Los compañeros entran a `http://IP-DE-LA-LAPTOP:8080`.
3. El puerto 1521 de Oracle **no** necesita abrirse: solo el servidor habla con la base.

Para la demo:
- Abra `/pantalla` en el proyector y haga clic en "Activar".
- Un compañero hace de recepción, otro de veterinario y otro de administrador.
