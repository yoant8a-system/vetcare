package com.vet.config;

import com.vet.seguridad.UsuarioActual;
import com.zaxxer.hikari.HikariDataSource;
import org.springframework.boot.autoconfigure.jdbc.DataSourceProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.jdbc.datasource.DelegatingDataSource;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.SQLException;

/**
 * Pool de conexiones a Oracle.
 *
 * Todos los usuarios de la app comparten las mismas conexiones (usuario de BD VETERINARIA).
 * Para que la AUDITORIA sepa QUE usuario de la app hizo cada cambio, cada vez que se toma
 * una conexion se le envia el usuario logueado como "client identifier".
 * En Oracle se lee con:  SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER')
 */
@Configuration
public class DataSourceConfig {

    @Bean
    public DataSource dataSource(DataSourceProperties propiedades) {
        HikariDataSource pool = propiedades.initializeDataSourceBuilder().type(HikariDataSource.class).build();
        pool.setPoolName("PoolOracle");
        pool.setMaximumPoolSize(10);

        return new DelegatingDataSource(pool) {
            @Override
            public Connection getConnection() throws SQLException {
                Connection cn = super.getConnection();
                cn.setClientInfo("OCSID.CLIENTID", UsuarioActual.get());
                return cn;
            }
        };
    }
}
