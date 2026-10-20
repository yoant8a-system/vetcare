package com.vet;

import com.vet.db.Sql;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.io.FileInputStream;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Properties;

/**
 * Sistema Veterinario - servidor web.
 * Ejecutar y abrir http://localhost:8080  (los compañeros: http://IP-DE-ESTA-PC:8080)
 */
@SpringBootApplication
public class VeterinariaApplication {

    public static void main(String[] args) throws Exception {
        completarConSolucionSiSePide();
        SpringApplication.run(VeterinariaApplication.class, args);
    }

    /** app.completar_con_solucion=true -> las sentencias pendientes se toman de la solucion. */
    private static void completarConSolucionSiSePide() throws Exception {
        Path config = Path.of("config/db.properties");
        if (!Files.exists(config)) {
            return;
        }
        Properties p = new Properties();
        try (InputStream in = new FileInputStream(config.toFile())) {
            p.load(in);
        }
        if (Boolean.parseBoolean(p.getProperty("app.completar_con_solucion", "false").trim())) {
            Path soluciones = Path.of("soluciones/etapa3_logica/consultas_app.sql");
            if (!Files.exists(soluciones)) {
                System.out.println(">>> AVISO: app.completar_con_solucion=true pero no existe " + soluciones
                        + ". Se arranca en modo plantilla: las consultas no escritas mostraran 'Falta implementar'.");
                return;
            }
            Sql.cargarSoluciones(soluciones);
            System.out.println(">>> MODO SOLUCION: " + Sql.cantidadSoluciones()
                    + " sentencias disponibles para completar las que falten (" + soluciones + ")");
        }
    }
}
