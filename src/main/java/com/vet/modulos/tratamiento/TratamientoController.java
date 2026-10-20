package com.vet.modulos.tratamiento;

import com.vet.modulos.veterinario.VeterinarioRepositorio;
import com.vet.seguridad.UsuarioSesion;
import com.vet.web.Mensajes;
import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/tratamientos")
public class TratamientoController {

    private final TratamientoRepositorio repo;
    private final VeterinarioRepositorio veterinarios;

    public TratamientoController(TratamientoRepositorio repo, VeterinarioRepositorio veterinarios) {
        this.repo = repo;
        this.veterinarios = veterinarios;
    }

    @GetMapping
    public String lista(@RequestParam(defaultValue = "EN_CURSO") String estado, Model model) {
        model.addAttribute("estado", estado);
        model.addAttribute("tratamientos", repo.listar("TODOS".equals(estado) ? null : estado));
        return "tratamientos/lista";
    }

    @GetMapping("/{id}")
    public String detalle(@PathVariable long id, Model model) {
        model.addAttribute("t", repo.obtener(id));
        model.addAttribute("sesiones", repo.sesiones(id));
        model.addAttribute("veterinarios", veterinarios.activos());
        return "tratamientos/detalle";
    }

    @PostMapping("/{id}/sesion")
    public String sesion(@PathVariable long id, @RequestParam(required = false) Long veterinario,
                         @RequestParam(required = false) String obs, HttpSession s, RedirectAttributes ra) {
        UsuarioSesion u = (UsuarioSesion) s.getAttribute(UsuarioSesion.ATRIBUTO);
        Long vet = u.idVeterinario() != null ? u.idVeterinario() : veterinario;
        if (vet == null) {
            Mensajes.error(ra, "Indique el veterinario");
        } else {
            Mensajes.intentar(ra, null, () -> {
                long n = repo.registrarSesion(id, vet, obs);
                Mensajes.ok(ra, "Sesion N° " + n + " registrada");
            });
        }
        return "redirect:/tratamientos/" + id;
    }

    @PostMapping("/{id}/suspender")
    public String suspender(@PathVariable long id, RedirectAttributes ra) {
        Mensajes.intentar(ra, "Tratamiento suspendido", () -> repo.suspender(id));
        return "redirect:/tratamientos/" + id;
    }
}
