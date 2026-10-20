package com.vet.modulos.mascota;

import com.vet.db.ErroresOracle;
import com.vet.db.Plsql;
import com.vet.modulos.cita.CitaRepositorio;
import com.vet.modulos.tratamiento.TratamientoRepositorio;
import com.vet.modulos.vacunacion.VacunacionRepositorio;
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

import java.time.LocalDate;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Supplier;

@Controller
@RequestMapping("/mascotas")
public class MascotaController {

    private final MascotaRepositorio repo;
    private final CitaRepositorio citas;
    private final VacunacionRepositorio vacunas;
    private final TratamientoRepositorio tratamientos;
    private final VeterinarioRepositorio veterinarios;
    private final Plsql plsql;

    public MascotaController(MascotaRepositorio repo, CitaRepositorio citas, VacunacionRepositorio vacunas,
                             TratamientoRepositorio tratamientos, VeterinarioRepositorio veterinarios, Plsql plsql) {
        this.repo = repo;
        this.citas = citas;
        this.vacunas = vacunas;
        this.tratamientos = tratamientos;
        this.veterinarios = veterinarios;
        this.plsql = plsql;
    }

    @GetMapping
    public String lista(@RequestParam(required = false) String q, @RequestParam(required = false) Long especie, Model model) {
        model.addAttribute("q", q);
        model.addAttribute("especie", especie);
        model.addAttribute("especies", repo.especies());
        model.addAttribute("mascotas", repo.buscar(q, especie));
        return "mascotas/lista";
    }

    @GetMapping("/nueva")
    public String nueva(@RequestParam long propietario, Model model) {
        Map<String, Object> m = new HashMap<>();
        m.put("ID_PROPIETARIO", propietario);
        model.addAttribute("m", m);
        cargarCombos(model, null);
        return "mascotas/form";
    }

    @GetMapping("/{id}/editar")
    public String editar(@PathVariable long id, Model model) {
        model.addAttribute("m", repo.obtener(id));
        cargarCombos(model, id);
        return "mascotas/form";
    }

    private void cargarCombos(Model model, Long id) {
        model.addAttribute("razas", repo.razas());
        model.addAttribute("candidatos", repo.candidatosPadres(id));
    }

    /** Ficha clinica: datos + historia (PKG_REPORTES) + vacunas + tratamientos + citas + genealogia. */
    @GetMapping("/{id}")
    public String ficha(@PathVariable long id, Model model) {
        Map<String, Object> m = repo.obtener(id);
        model.addAttribute("m", m);
        cargar(model, "historia", () -> plsql.cursor("PKG_REPORTES.FN_HISTORIA_CLINICA", id));
        cargar(model, "carnet", () -> vacunas.carnet(id));
        cargar(model, "tratamientos", () -> tratamientos.deMascota(id));
        cargar(model, "citas", () -> citas.deMascota(id));
        cargar(model, "genealogia", () -> plsql.cursor("PKG_REPORTES.FN_GENEALOGIA", id));
        if (m != null) {
            long especie = ((Number) m.get("ID_ESPECIE")).longValue();
            cargar(model, "vacunasEspecie", () -> vacunas.vacunasDeEspecie(especie));
        }
        cargar(model, "veterinarios", veterinarios::activos);
        model.addAttribute("hoy", LocalDate.now());
        return "mascotas/ficha";
    }

    private static void cargar(Model model, String nombre, Supplier<Object> fuente) {
        try {
            model.addAttribute(nombre, fuente.get());
        } catch (RuntimeException e) {
            model.addAttribute(nombre + "Error", ErroresOracle.mensaje(e));
        }
    }

    @PostMapping("/guardar")
    public String guardar(@RequestParam Map<String, String> f, RedirectAttributes ra) {
        String id = f.get("id");
        long[] nuevo = new long[1];
        boolean ok = Mensajes.intentar(ra, "Mascota guardada", () -> {
            if (id == null || id.isBlank()) {
                nuevo[0] = repo.insertar(Long.parseLong(f.get("id_propietario")), f);
            } else {
                repo.actualizar(Long.parseLong(id), f);
            }
        });
        if (!ok) {
            return id == null || id.isBlank()
                    ? "redirect:/mascotas/nueva?propietario=" + f.get("id_propietario")
                    : "redirect:/mascotas/" + id + "/editar";
        }
        return "redirect:/mascotas/" + (id == null || id.isBlank() ? nuevo[0] : id);
    }

    @PostMapping("/{id}/eliminar")
    public String eliminar(@PathVariable long id, @RequestParam long propietario, RedirectAttributes ra) {
        if (Mensajes.intentar(ra, "Mascota eliminada", () -> repo.eliminar(id))) {
            return "redirect:/propietarios/" + propietario;
        }
        return "redirect:/mascotas/" + id;
    }

    @PostMapping("/{id}/vacunar")
    public String vacunar(@PathVariable long id, @RequestParam long vacuna, @RequestParam(required = false) Long veterinario,
                          @RequestParam LocalDate fecha, @RequestParam(required = false) String lote,
                          HttpSession sesion, RedirectAttributes ra) {
        UsuarioSesion u = (UsuarioSesion) sesion.getAttribute(UsuarioSesion.ATRIBUTO);
        Long vet = u.idVeterinario() != null ? u.idVeterinario() : veterinario;
        if (vet == null) {
            Mensajes.error(ra, "Indique el veterinario que aplico la vacuna");
        } else {
            Mensajes.intentar(ra, "Vacuna registrada (la proxima dosis la calculo Oracle)",
                    () -> vacunas.registrar(id, vacuna, vet, fecha, lote));
        }
        return "redirect:/mascotas/" + id + "#vacunas";
    }
}
