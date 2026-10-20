package com.vet.modulos.atencion;

import com.vet.db.Plsql;
import com.vet.seguridad.UsuarioSesion;
import com.vet.web.Mensajes;
import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/** Pantalla del veterinario: cola, llamar al siguiente y registrar la atencion. */
@Controller
@RequestMapping("/consultorio")
public class ConsultorioController {

    private final AtencionRepositorio repo;
    private final Plsql plsql;

    public ConsultorioController(AtencionRepositorio repo, Plsql plsql) {
        this.repo = repo;
        this.plsql = plsql;
    }

    private static long vet(HttpSession s) {
        return ((UsuarioSesion) s.getAttribute(UsuarioSesion.ATRIBUTO)).idVeterinario();
    }

    @GetMapping
    public String consultorio(HttpSession sesion, Model model) {
        long idVet = vet(sesion);
        Map<String, Object> paciente = repo.pacienteActual(idVet);
        model.addAttribute("paciente", paciente);
        model.addAttribute("cola", repo.cola());
        model.addAttribute("atendidos", repo.atendidosHoy(idVet));
        if (paciente == null) {
            model.addAttribute("consultorios", repo.consultoriosLibres());
        } else {
            long especie = ((Number) paciente.get("ID_ESPECIE")).longValue();
            long mascota = ((Number) paciente.get("ID_MASCOTA")).longValue();
            model.addAttribute("diagnosticos", repo.diagnosticos(especie));
            model.addAttribute("medicamentos", repo.medicamentos());
            model.addAttribute("historia", plsql.cursor("PKG_REPORTES.FN_HISTORIA_CLINICA", mascota));
        }
        return "consultorio/consultorio";
    }

    @PostMapping("/llamar")
    public String llamar(@RequestParam long consultorio, HttpSession sesion, RedirectAttributes ra) {
        Mensajes.intentar(ra, null, () -> {
            Long cita = repo.llamarSiguiente(vet(sesion), consultorio);
            if (cita == null) {
                Mensajes.error(ra, "No hay pacientes en la cola");
            } else {
                Mensajes.ok(ra, "Paciente llamado: se anuncia en la pantalla de sala");
            }
        });
        return "redirect:/consultorio";
    }

    @PostMapping("/rellamar")
    public String rellamar(@RequestParam long cita, RedirectAttributes ra) {
        Mensajes.intentar(ra, "Se volvio a anunciar en la pantalla", () -> repo.rellamar(cita));
        return "redirect:/consultorio";
    }

    @PostMapping("/registrar")
    public String registrar(@RequestParam long cita, @RequestParam String anamnesis,
                            @RequestParam(required = false) String examen, @RequestParam(required = false) String indicaciones,
                            @RequestParam(name = "diagnostico", required = false) List<Long> diagnosticos,
                            @RequestParam(name = "definitivo", required = false) List<Long> definitivos,
                            @RequestParam(required = false) String tratamiento,
                            @RequestParam(required = false) Integer sesiones, @RequestParam(required = false) Integer frecuencia,
                            @RequestParam(name = "medicamento", required = false) List<Long> medicamentos,
                            @RequestParam(name = "cantidad", required = false) List<BigDecimal> cantidades,
                            HttpSession sesion, RedirectAttributes ra) {
        // Filas de insumos vacias del formulario se descartan
        List<Long> meds = new ArrayList<>();
        List<BigDecimal> cants = new ArrayList<>();
        if (medicamentos != null) {
            for (int i = 0; i < medicamentos.size(); i++) {
                BigDecimal c = cantidades != null && i < cantidades.size() ? cantidades.get(i) : null;
                if (medicamentos.get(i) != null && c != null && c.signum() > 0) {
                    meds.add(medicamentos.get(i));
                    cants.add(c);
                }
            }
        }
        AtencionRepositorio.Atencion a = new AtencionRepositorio.Atencion(anamnesis, examen, indicaciones,
                sinVacios(diagnosticos), sinVacios(definitivos),
                tratamiento == null || tratamiento.isBlank() ? null : tratamiento, sesiones, frecuencia, meds, cants);
        Mensajes.intentar(ra, null, () -> {
            long id = repo.registrar(cita, vet(sesion), a);
            Mensajes.ok(ra, "Atencion #" + id + " registrada. Diagnosticos, tratamiento e insumos guardados en una sola transaccion.");
        });
        return "redirect:/consultorio";
    }

    /** Casillas vacias del formulario llegan como null: no se envian a Oracle. */
    private static List<Long> sinVacios(List<Long> lista) {
        return lista == null ? List.of() : lista.stream().filter(java.util.Objects::nonNull).toList();
    }
}
