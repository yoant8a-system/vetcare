package com.vet.db;

import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.jdbc.support.GeneratedKeyHolder;
import org.springframework.jdbc.support.KeyHolder;
import org.springframework.stereotype.Component;

import java.sql.Timestamp;
import java.sql.Types;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

/**
 * Ayudante para ejecutar SQL con PARAMETROS CON NOMBRE (:dni, :nombres...).
 * Es el mismo formato que usa SQL Developer: la sentencia se puede probar alli tal cual.
 *
 *   db.lista(PR_01, "texto", "perez");      // SELECT ... WHERE APELLIDOS LIKE :texto
 *
 * Los parametros se pasan en pares: "nombre", valor, "nombre", valor ...
 * Las filas vuelven como Map<String,Object> con el nombre de cada columna (sin importar mayusculas),
 * asi que los ALIAS del SELECT son los que usan las paginas HTML.
 */
@Component
public class Db {

    private final NamedParameterJdbcTemplate jdbc;

    public Db(NamedParameterJdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    /** SELECT de varias filas. */
    public List<Map<String, Object>> lista(String sql, Object... params) {
        verificar(sql);
        return jdbc.queryForList(sql, parametros(params));
    }

    /** SELECT de una fila (null si no hay ninguna). */
    public Map<String, Object> uno(String sql, Object... params) {
        List<Map<String, Object>> filas = lista(sql, params);
        return filas.isEmpty() ? null : filas.get(0);
    }

    /** SELECT de un solo valor (COUNT, SUM...). */
    public <T> T valor(String sql, Class<T> tipo, Object... params) {
        verificar(sql);
        try {
            return jdbc.queryForObject(sql, parametros(params), tipo);
        } catch (EmptyResultDataAccessException e) {
            return null;
        }
    }

    /** INSERT / UPDATE / DELETE. Devuelve cuantas filas cambio. */
    public int ejecutar(String sql, Object... params) {
        verificar(sql);
        return jdbc.update(sql, parametros(params));
    }

    /** INSERT que devuelve el ID generado por la columna IDENTITY indicada. */
    public long insertar(String sql, String columnaId, Object... params) {
        verificar(sql);
        KeyHolder kh = new GeneratedKeyHolder();
        jdbc.update(sql, parametros(params), kh, new String[]{columnaId});
        return kh.getKey().longValue();
    }

    // -----------------------------------------------------------------

    private void verificar(String sql) {
        if (Sql.esPendiente(sql)) {
            throw new SqlPendienteException(Sql.id(sql));
        }
    }

    static MapSqlParameterSource parametros(Object... pares) {
        if (pares.length % 2 != 0) {
            throw new IllegalArgumentException("Los parametros van en pares: nombre, valor");
        }
        MapSqlParameterSource p = new MapSqlParameterSource();
        for (int i = 0; i < pares.length; i += 2) {
            String nombre = (String) pares[i];
            Object v = convertir(pares[i + 1]);
            if (v == null) {
                // Oracle acepta un NULL de tipo VARCHAR para cualquier columna
                p.addValue(nombre, null, Types.VARCHAR);
            } else {
                p.addValue(nombre, v);
            }
        }
        return p;
    }

    static Object convertir(Object v) {
        if (v instanceof String s && s.isBlank()) {
            return null;
        }
        if (v instanceof LocalDateTime ldt) {
            return Timestamp.valueOf(ldt);
        }
        if (v instanceof LocalDate ld) {
            return java.sql.Date.valueOf(ld);
        }
        if (v instanceof Boolean b) {
            return b ? "S" : "N";
        }
        return v;
    }
}
