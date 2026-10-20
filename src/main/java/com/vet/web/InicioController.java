package com.vet.web;

import com.vet.db.ErroresOracle;
import com.vet.modulos.sistema.SistemaRepositorio;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import java.util.function.Supplier;

/** Tablero principal. Cada bloque se carga por separado: si a uno le falta su SQL, los demas igual se ven. */
@Controller
public class InicioController {

    private final SistemaRepositorio sistema;

    public InicioController(SistemaRepositorio sistema) {
        this.sistema = sistema;
    }

    @GetMapping("/")
    public String inicio(Model model) {
        model.addAttribute("hoyTexto", java.time.LocalDate.now().format(
                java.time.format.DateTimeFormatter.ofPattern("EEEE dd 'de' MMMM 'de' yyyy", new java.util.Locale("es", "PE"))));
        cargar(model, "kpi", sistema::indicadores);
        cargar(model, "porDia", sistema::atencionesPorDia);
        cargar(model, "porEspecie", sistema::atencionesPorEspecie);
        cargar(model, "proximas", sistema::proximasCitas);
        return "inicio";
    }

    /** Pone el dato en el modelo; si falla, pone el mensaje en "<nombre>Error". */
    static void cargar(Model model, String nombre, Supplier<Object> fuente) {
        try {
            model.addAttribute(nombre, fuente.get());
        } catch (RuntimeException e) {
            model.addAttribute(nombre + "Error", ErroresOracle.mensaje(e));
        }
    }
}
