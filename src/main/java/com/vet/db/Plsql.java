package com.vet.db;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.OracleTypes;
import org.springframework.jdbc.core.ConnectionCallback;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

/**
 * Llama a procedimientos y funciones de los paquetes PL/SQL.
 *
 *   Resultado r = plsql.llamar("PKG_CITAS.PR_PROGRAMAR",
 *           Plsql.in(idMascota), Plsql.in(idVet), Plsql.in(fecha), Plsql.in(30), Plsql.in(motivo),
 *           Plsql.outNumero());
 *   long idCita = r.numero(0);
 *
 * El ORDEN de los parametros debe ser exactamente el de la SPEC del paquete (sql/07_paquetes.sql).
 */
@Component
public class Plsql {

    private final JdbcTemplate jdbc;

    public Plsql(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    // ---------------------------------------------------------------- tipos de parametro

    public sealed interface Param permits In, Numeros, Out {
    }

    record In(Object valor) implements Param {
    }

    /** Lista de numeros -> coleccion Oracle T_NUMEROS (CREATE TYPE T_NUMEROS AS TABLE OF NUMBER) */
    record Numeros(List<? extends Number> valores) implements Param {
    }

    record Out(int tipoSql) implements Param {
    }

    public static Param in(Object valor) {
        return new In(valor);
    }

    public static Param numeros(List<? extends Number> valores) {
        return new Numeros(valores == null ? List.of() : valores);
    }

    public static Param outNumero() {
        return new Out(Types.NUMERIC);
    }

    public static Param outTexto() {
        return new Out(Types.VARCHAR);
    }

    /** Valores OUT devueltos por el procedimiento, en el orden en que se declararon. */
    public record Resultado(List<Object> salidas) {
        public Long numero(int i) {
            Object v = salidas.get(i);
            return v == null ? null : ((Number) v).longValue();
        }

        public String texto(int i) {
            Object v = salidas.get(i);
            return v == null ? null : v.toString();
        }
    }

    // ---------------------------------------------------------------- llamadas

    /** Ejecuta  { call NOMBRE(?, ?, ...) } */
    public Resultado llamar(String procedimiento, Param... params) {
        String sql = "{call " + procedimiento + "(" + marcadores(params.length) + ")}";
        return jdbc.execute((ConnectionCallback<Resultado>) cn -> {
            try (CallableStatement cs = cn.prepareCall(sql)) {
                for (int i = 0; i < params.length; i++) {
                    int pos = i + 1;
                    if (params[i] instanceof In in) {
                        Object v = Db.convertir(in.valor());
                        if (v == null) {
                            cs.setNull(pos, Types.VARCHAR);
                        } else {
                            cs.setObject(pos, v);
                        }
                    } else if (params[i] instanceof Numeros n) {
                        Object[] arr = n.valores().stream().map(x -> new BigDecimal(x.toString())).toArray();
                        cs.setArray(pos, cn.unwrap(OracleConnection.class).createOracleArray("T_NUMEROS", arr));
                    } else if (params[i] instanceof Out out) {
                        cs.registerOutParameter(pos, out.tipoSql());
                    }
                }
                cs.execute();
                List<Object> salidas = new ArrayList<>();
                for (int i = 0; i < params.length; i++) {
                    if (params[i] instanceof Out) {
                        salidas.add(cs.getObject(i + 1));
                    }
                }
                return new Resultado(salidas);
            }
        });
    }

    /** Ejecuta  { ? = call FUNCION(?, ...) }  donde la funcion devuelve SYS_REFCURSOR. */
    public TablaResultado cursor(String funcion, Object... argumentos) {
        String sql = "{? = call " + funcion + "(" + marcadores(argumentos.length) + ")}";
        return jdbc.execute((ConnectionCallback<TablaResultado>) cn -> {
            try (CallableStatement cs = cn.prepareCall(sql)) {
                cs.registerOutParameter(1, OracleTypes.CURSOR);
                for (int i = 0; i < argumentos.length; i++) {
                    Object v = Db.convertir(argumentos[i]);
                    if (v == null) {
                        cs.setNull(i + 2, Types.VARCHAR);
                    } else {
                        cs.setObject(i + 2, v);
                    }
                }
                cs.execute();
                try (ResultSet rs = (ResultSet) cs.getObject(1)) {
                    ResultSetMetaData md = rs.getMetaData();
                    List<String> columnas = new ArrayList<>();
                    for (int c = 1; c <= md.getColumnCount(); c++) {
                        columnas.add(md.getColumnLabel(c));
                    }
                    List<List<Object>> filas = new ArrayList<>();
                    while (rs.next()) {
                        List<Object> fila = new ArrayList<>();
                        for (int c = 1; c <= columnas.size(); c++) {
                            fila.add(texto(rs.getObject(c)));
                        }
                        filas.add(fila);
                    }
                    return new TablaResultado(columnas, filas);
                }
            }
        });
    }

    /** Fechas a texto legible (dd/MM/yyyy y la hora si no es medianoche); lo demas tal cual. */
    private static Object texto(Object v) {
        if (v instanceof java.sql.Timestamp ts) {
            java.time.LocalDateTime t = ts.toLocalDateTime();
            String f = t.toLocalTime().equals(java.time.LocalTime.MIDNIGHT) ? "dd/MM/yyyy" : "dd/MM/yyyy HH:mm";
            return t.format(java.time.format.DateTimeFormatter.ofPattern(f));
        }
        return v;
    }

    private static String marcadores(int n) {
        return String.join(", ", java.util.Collections.nCopies(n, "?"));
    }
}
