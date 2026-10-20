package com.vet.modulos.inventario;

import com.vet.web.Mensajes;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.math.BigDecimal;
import java.util.Map;

@Controller
@RequestMapping("/inventario")
public class InventarioController {

    private final InventarioRepositorio repo;

    public InventarioController(InventarioRepositorio repo) {
        this.repo = repo;
    }

    @GetMapping
    public String lista(Model model) {
        model.addAttribute("medicamentos", repo.listar());
        model.addAttribute("movimientos", repo.ultimosMovimientos());
        return "inventario/lista";
    }

    @GetMapping("/nuevo")
    public String nuevo(Model model) {
        model.addAttribute("m", Map.of());
        return "inventario/form";
    }

    @GetMapping("/{id}/editar")
    public String editar(@PathVariable long id, Model model) {
        model.addAttribute("m", repo.obtener(id));
        return "inventario/form";
    }

    @PostMapping("/guardar")
    public String guardar(@RequestParam Map<String, String> f, RedirectAttributes ra) {
        String id = f.get("id");
        boolean ok = Mensajes.intentar(ra, "Medicamento guardado", () -> {
            if (id == null || id.isBlank()) {
                repo.insertar(f);
            } else {
                repo.actualizar(Long.parseLong(id), f);
            }
        });
        if (!ok) {
            return id == null || id.isBlank() ? "redirect:/inventario/nuevo" : "redirect:/inventario/" + id + "/editar";
        }
        return "redirect:/inventario";
    }

    @PostMapping("/movimiento")
    public String movimiento(@RequestParam long medicamento, @RequestParam String tipo,
                             @RequestParam BigDecimal cantidad, @RequestParam(required = false) String motivo,
                             RedirectAttributes ra) {
        Mensajes.intentar(ra, "Movimiento registrado: el stock lo actualizo el trigger",
                () -> repo.movimiento(medicamento, tipo, cantidad, motivo));
        return "redirect:/inventario";
    }
}
