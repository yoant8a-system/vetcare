package com.vet.modulos.cita;

import com.vet.modulos.veterinario.VeterinarioRepositorio;
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
import java.time.LocalDate;
import java.time.LocalDateTime;

@Controller
@RequestMapping("/citas")
public class CitaController {

    private final CitaRepositorio repo;
    private final VeterinarioRepositorio veterinarios;

    public CitaController(CitaRepositorio repo, VeterinarioRepositorio veterinarios) {
        this.repo = repo;
        this.veterinarios = veterinarios;
    }

    @GetMapping
    public String agenda(@RequestParam(required = false) LocalDate fecha,
                         @RequestParam(required = false) Long veterinario, Model model) {
        LocalDate dia = fecha == null ? LocalDate.now() : fecha;
        model.addAttribute("fecha", dia);
        model.addAttribute("veterinario", veterinario);
        model.addAttribute("veterinarios", veterinarios.activos());
        model.addAttribute("citas", repo.agenda(dia, veterinario));
        model.addAttribute("esHoy", dia.equals(LocalDate.now()));
        return "citas/agenda";
    }

    @GetMapping("/nueva")
    public String nueva(@RequestParam(required = false) Long mascota, @RequestParam(required = false) Long veterinario,
                        Model model) {
        model.addAttribute("mascotas", repo.mascotasActivas());
        model.addAttribute("veterinarios", veterinarios.activos());
        model.addAttribute("mascota", mascota);
        model.addAttribute("veterinario", veterinario);
        if (veterinario != null) {
            model.addAttribute("horario", veterinarios.horarios(veterinario));
        }
        model.addAttribute("sugerida", LocalDateTime.now().plusDays(1).withHour(9).withMinute(0).withSecond(0).withNano(0));
        return "citas/nueva";
    }

    @PostMapping("/nueva")
    public String programar(@RequestParam long mascota, @RequestParam long veterinario,
                            @RequestParam LocalDateTime fecha, @RequestParam(defaultValue = "30") int duracion,
                            @RequestParam String motivo, RedirectAttributes ra) {
        boolean ok = Mensajes.intentar(ra, null, () -> {
            long id = repo.programar(mascota, veterinario, fecha, duracion, motivo);
            Mensajes.ok(ra, "Cita #" + id + " programada para el " + fecha.toLocalDate() + " a las " + fecha.toLocalTime());
        });
        if (!ok) {
            return "redirect:/citas/nueva?mascota=" + mascota + "&veterinario=" + veterinario;
        }
        return "redirect:/citas?fecha=" + fecha.toLocalDate() + "&veterinario=" + veterinario;
    }

    /** Llegada de un paciente con cita: formulario de triaje. */
    @GetMapping("/llegada/{id}")
    public String llegada(@PathVariable long id, Model model) {
        model.addAttribute("cita", repo.obtener(id));
        return "citas/llegada";
    }

    /** Paciente sin cita / emergencia. */
    @GetMapping("/llegada")
    public String sinCita(Model model) {
        model.addAttribute("mascotas", repo.mascotasActivas());
        return "citas/llegada";
    }

    @PostMapping("/llegada")
    public String registrarLlegada(@RequestParam(required = false) Long cita, @RequestParam(required = false) Long mascota,
                                   @RequestParam(required = false) String motivo,
                                   @RequestParam BigDecimal peso, @RequestParam BigDecimal temperatura,
                                   @RequestParam(required = false) Integer fc, @RequestParam(required = false) Integer fr,
                                   @RequestParam int urgencia, @RequestParam(required = false) String obs,
                                   RedirectAttributes ra) {
        CitaRepositorio.Triaje t = new CitaRepositorio.Triaje(peso, temperatura, fc, fr, urgencia, obs);
        boolean ok = Mensajes.intentar(ra, "Paciente registrado en la cola de atencion", () -> {
            if (cita != null) {
                repo.registrarLlegada(cita, t);
            } else {
                repo.registrarSinCita(mascota, motivo, t);
            }
        });
        if (!ok) {
            return cita != null ? "redirect:/citas/llegada/" + cita : "redirect:/citas/llegada";
        }
        return "redirect:/citas";
    }

    @PostMapping("/{id}/cancelar")
    public String cancelar(@PathVariable long id, @RequestParam(required = false) String volver, RedirectAttributes ra) {
        Mensajes.intentar(ra, "Cita cancelada", () -> repo.cancelar(id));
        return "redirect:" + (volver == null || volver.isBlank() ? "/citas" : volver);
    }
}
