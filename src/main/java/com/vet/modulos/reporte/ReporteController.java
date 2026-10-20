package com.vet.modulos.reporte;

import com.vet.db.ErroresOracle;
import com.vet.db.Plsql;
import com.vet.modulos.cita.CitaRepositorio;
import com.vet.modulos.inventario.InventarioRepositorio;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/reportes")
public class ReporteController {

    private final Plsql plsql;
    private final CitaRepositorio citas;
    private final InventarioRepositorio inventario;

    public ReporteController(Plsql plsql, CitaRepositorio citas, InventarioRepositorio inventario) {
        this.plsql = plsql;
        this.citas = citas;
        this.inventario = inventario;
    }

    @GetMapping
    public String indice(Model model) {
        model.addAttribute("reportes", Reportes.TODOS);
        return "reportes/indice";
    }

    @GetMapping("/{codigo}")
    public String ver(@PathVariable String codigo, @RequestParam Map<String, String> valores, Model model) {
        Reportes.Reporte r = Reportes.buscar(codigo);
        model.addAttribute("r", r);

        // Valores del formulario (o por defecto) y argumentos para la funcion PL/SQL
        Map<String, String> actuales = new LinkedHashMap<>();
        List<Object> args = new ArrayList<>();
        boolean completo = true;
        for (Reportes.Param p : r.params()) {
            String v = valores.get(p.nombre());
            if (v == null || v.isBlank()) {
                v = porDefecto(p);
            }
            actuales.put(p.nombre(), v);
            if (v == null || v.isBlank()) {
                completo = false;
                args.add(null);
            } else {
                args.add(switch (p.tipo()) {
                    case FECHA -> LocalDate.parse(v);
                    case NUMERO, MASCOTA, MEDICAMENTO -> new BigDecimal(v);
                });
            }
            if (p.tipo() == Reportes.Tipo.MASCOTA && !model.containsAttribute("mascotas")) {
                model.addAttribute("mascotas", citas.mascotasActivas());
            }
            if (p.tipo() == Reportes.Tipo.MEDICAMENTO) {
                model.addAttribute("medicamentos", inventario.listar());
            }
        }
        model.addAttribute("valores", actuales);

        if (completo) {
            try {
                model.addAttribute("tabla", plsql.cursor(r.funcion(), args.toArray()));
            } catch (RuntimeException e) {
                model.addAttribute("error", ErroresOracle.mensaje(e));
            }
        }
        return "reportes/ver";
    }

    private static String porDefecto(Reportes.Param p) {
        if (p.porDefecto() == null) {
            return null;
        }
        if (p.tipo() == Reportes.Tipo.FECHA) {
            return LocalDate.now().plusDays(Long.parseLong(p.porDefecto())).toString();
        }
        if ("anio".equals(p.porDefecto())) {
            return String.valueOf(LocalDate.now().getYear());
        }
        return p.porDefecto();
    }
}
