package com.vet.modulos.propietario;

import com.vet.modulos.mascota.MascotaRepositorio;
import com.vet.web.Mensajes;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.Map;

@Controller
@RequestMapping("/propietarios")
public class PropietarioController {

    private final PropietarioRepositorio repo;
    private final MascotaRepositorio mascotas;

    public PropietarioController(PropietarioRepositorio repo, MascotaRepositorio mascotas) {
        this.repo = repo;
        this.mascotas = mascotas;
    }

    @GetMapping
    public String lista(@RequestParam(required = false) String q, Model model) {
        model.addAttribute("q", q);
        model.addAttribute("propietarios", repo.buscar(q));
        return "propietarios/lista";
    }

    @GetMapping("/nuevo")
    public String nuevo(Model model) {
        model.addAttribute("p", Map.of());
        return "propietarios/form";
    }

    @GetMapping("/{id}")
    public String detalle(@PathVariable long id, Model model) {
        model.addAttribute("p", repo.obtener(id));
        model.addAttribute("mascotas", mascotas.dePropietario(id));
        return "propietarios/detalle";
    }

    @GetMapping("/{id}/editar")
    public String editar(@PathVariable long id, Model model) {
        model.addAttribute("p", repo.obtener(id));
        return "propietarios/form";
    }

    @PostMapping("/guardar")
    public String guardar(@RequestParam Map<String, String> f, RedirectAttributes ra) {
        String id = f.get("id");
        long[] nuevo = new long[1];
        boolean ok = Mensajes.intentar(ra, "Propietario guardado", () -> {
            if (id == null || id.isBlank()) {
                nuevo[0] = repo.insertar(f);
            } else {
                repo.actualizar(Long.parseLong(id), f);
            }
        });
        if (!ok) {
            ra.addFlashAttribute("form", f);
            return id == null || id.isBlank() ? "redirect:/propietarios/nuevo" : "redirect:/propietarios/" + id + "/editar";
        }
        return "redirect:/propietarios/" + (id == null || id.isBlank() ? nuevo[0] : id);
    }

    @PostMapping("/{id}/eliminar")
    public String eliminar(@PathVariable long id, RedirectAttributes ra) {
        if (Mensajes.intentar(ra, "Propietario eliminado", () -> repo.eliminar(id))) {
            return "redirect:/propietarios";
        }
        return "redirect:/propietarios/" + id;
    }
}
