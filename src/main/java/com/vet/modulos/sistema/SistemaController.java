package com.vet.modulos.sistema;

import com.vet.db.Plsql;
import com.vet.modulos.veterinario.VeterinarioRepositorio;
import com.vet.web.Mensajes;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.Map;

/** Usuarios (admin), auditoria (admin) y alertas (todos). */
@Controller
public class SistemaController {

    private final SistemaRepositorio repo;
    private final VeterinarioRepositorio veterinarios;

    public SistemaController(SistemaRepositorio repo, VeterinarioRepositorio veterinarios) {
        this.repo = repo;
        this.veterinarios = veterinarios;
    }

    // ------------------------------------------------------------ usuarios

    @GetMapping("/admin/usuarios")
    public String usuarios(@RequestParam(required = false) Long editar, Model model) {
        model.addAttribute("usuarios", repo.usuarios());
        model.addAttribute("veterinarios", veterinarios.activos());
        model.addAttribute("edit", editar == null ? Map.of() : repo.usuario(editar));
        return "admin/usuarios";
    }

    @PostMapping("/admin/usuarios/guardar")
    public String guardarUsuario(@RequestParam(required = false) Long id, @RequestParam(required = false) String usuario,
                                 @RequestParam String nombre, @RequestParam String rol,
                                 @RequestParam(required = false) Long veterinario, @RequestParam(defaultValue = "N") String activo,
                                 @RequestParam(required = false) String clave, RedirectAttributes ra) {
        Mensajes.intentar(ra, "Usuario guardado", () -> {
            Long vet = "VETERINARIO".equals(rol) ? veterinario : null;
            if (id == null) {
                repo.crearUsuario(usuario, clave, nombre, rol, vet);
            } else {
                repo.actualizarUsuario(id, nombre, rol, vet, activo);
                if (clave != null && !clave.isBlank()) {
                    repo.cambiarClave(id, clave);
                }
            }
        });
        return "redirect:/admin/usuarios";
    }

    // ------------------------------------------------------------ auditoria

    @GetMapping("/admin/auditoria")
    public String auditoria(@RequestParam(required = false) String tabla, Model model) {
        model.addAttribute("tabla", tabla);
        model.addAttribute("registros", repo.auditoria(tabla == null || tabla.isBlank() ? null : tabla));
        return "admin/auditoria";
    }

    // ------------------------------------------------------------ alertas

    @GetMapping("/alertas")
    public String alertas(Model model) {
        model.addAttribute("alertas", repo.alertas());
        return "alertas";
    }

    @PostMapping("/alertas/{id}/leer")
    public String leer(@PathVariable long id, RedirectAttributes ra) {
        Mensajes.intentar(ra, null, () -> repo.marcarLeida(id));
        return "redirect:/alertas";
    }

    @PostMapping("/alertas/leer-todas")
    public String leerTodas(RedirectAttributes ra) {
        Mensajes.intentar(ra, "Todas las alertas marcadas como leidas", repo::marcarTodas);
        return "redirect:/alertas";
    }

    /** Ejecuta YA lo mismo que el job nocturno de Oracle. */
    @PostMapping("/alertas/generar")
    public String generar(RedirectAttributes ra) {
        Mensajes.intentar(ra, null, () -> {
            Plsql.Resultado r = repo.generarAlertas();
            Mensajes.ok(ra, "PKG_ALERTAS ejecutado: " + r.numero(0) + " de vacunas, " + r.numero(1)
                    + " de stock y " + r.numero(2) + " citas marcadas como NO_ASISTIO");
        });
        return "redirect:/alertas";
    }
}
