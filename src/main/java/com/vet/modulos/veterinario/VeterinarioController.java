package com.vet.modulos.veterinario;

import com.vet.modulos.catalogo.CatalogoRepositorio;
import com.vet.web.Mensajes;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/admin/veterinarios")
public class VeterinarioController {

    private final VeterinarioRepositorio repo;
    private final CatalogoRepositorio catalogos;

    public VeterinarioController(VeterinarioRepositorio repo, CatalogoRepositorio catalogos) {
        this.repo = repo;
        this.catalogos = catalogos;
    }

    @GetMapping
    public String lista(Model model) {
        model.addAttribute("veterinarios", repo.listar());
        return "admin/veterinarios";
    }

    @GetMapping("/nuevo")
    public String nuevo(Model model) {
        model.addAttribute("v", Map.of());
        return "admin/veterinario-form";
    }

    @GetMapping("/{id}")
    public String editar(@PathVariable long id, Model model) {
        model.addAttribute("v", repo.obtener(id));
        model.addAttribute("especialidades", catalogos.especialidades());
        model.addAttribute("suyas", repo.especialidadesDe(id));
        model.addAttribute("horarios", repo.horarios(id));
        return "admin/veterinario-form";
    }

    @PostMapping("/guardar")
    public String guardar(@RequestParam Map<String, String> f, RedirectAttributes ra) {
        String id = f.get("id");
        long[] nuevo = new long[1];
        boolean ok = Mensajes.intentar(ra, "Veterinario guardado", () -> {
            if (id == null || id.isBlank()) {
                nuevo[0] = repo.insertar(f);
            } else {
                repo.actualizar(Long.parseLong(id), f);
            }
        });
        if (!ok && (id == null || id.isBlank())) {
            return "redirect:/admin/veterinarios/nuevo";
        }
        return "redirect:/admin/veterinarios/" + (id == null || id.isBlank() ? nuevo[0] : id);
    }

    @PostMapping("/{id}/especialidades")
    public String especialidades(@PathVariable long id, @RequestParam(name = "especialidad", required = false) List<Long> esp,
                                 RedirectAttributes ra) {
        Mensajes.intentar(ra, "Especialidades actualizadas", () -> repo.guardarEspecialidades(id, esp == null ? List.of() : esp));
        return "redirect:/admin/veterinarios/" + id;
    }

    @PostMapping("/{id}/horario")
    public String horario(@PathVariable long id, @RequestParam int dia, @RequestParam String inicio,
                          @RequestParam String fin, RedirectAttributes ra) {
        Mensajes.intentar(ra, "Horario agregado", () -> repo.agregarHorario(id, dia, inicio, fin));
        return "redirect:/admin/veterinarios/" + id;
    }

    @PostMapping("/{id}/horario/{idHorario}/eliminar")
    public String quitarHorario(@PathVariable long id, @PathVariable long idHorario, RedirectAttributes ra) {
        Mensajes.intentar(ra, "Horario eliminado", () -> repo.eliminarHorario(idHorario));
        return "redirect:/admin/veterinarios/" + id;
    }
}
