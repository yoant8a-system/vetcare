package com.vet.modulos.catalogo;

import com.vet.web.Mensajes;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

/** Administracion de catalogos (una pagina con pestañas). */
@Controller
@RequestMapping("/admin/catalogos")
public class CatalogoController {

    private final CatalogoRepositorio repo;

    public CatalogoController(CatalogoRepositorio repo) {
        this.repo = repo;
    }

    @GetMapping
    public String catalogos(@RequestParam(defaultValue = "especies") String tab, Model model) {
        model.addAttribute("tab", tab);
        model.addAttribute("especies", repo.especies());
        switch (tab) {
            case "razas" -> model.addAttribute("filas", repo.razas());
            case "especialidades" -> model.addAttribute("filas", repo.especialidades());
            case "consultorios" -> model.addAttribute("filas", repo.consultorios());
            case "diagnosticos" -> model.addAttribute("filas", repo.diagnosticos());
            case "vacunas" -> model.addAttribute("filas", repo.vacunas());
            default -> model.addAttribute("filas", repo.especies());
        }
        return "admin/catalogos";
    }

    private static String volver(String tab) {
        return "redirect:/admin/catalogos?tab=" + tab;
    }

    @PostMapping("/{tab}/agregar")
    public String agregar(@PathVariable String tab, @RequestParam(required = false) String nombre,
                          @RequestParam(required = false) Long especie, @RequestParam(required = false) String codigo,
                          @RequestParam(required = false) String categoria, @RequestParam(required = false) Integer refuerzo,
                          RedirectAttributes ra) {
        Mensajes.intentar(ra, "Registro agregado", () -> {
            switch (tab) {
                case "especies" -> repo.insertarEspecie(nombre);
                case "razas" -> repo.insertarRaza(especie, nombre);
                case "especialidades" -> repo.insertarEspecialidad(nombre);
                case "consultorios" -> repo.insertarConsultorio(nombre);
                case "diagnosticos" -> repo.insertarDiagnostico(codigo, nombre, categoria, especie);
                case "vacunas" -> repo.insertarVacuna(nombre, especie, refuerzo);
                default -> throw new IllegalArgumentException("Catalogo desconocido");
            }
        });
        return volver(tab);
    }

    @PostMapping("/{tab}/{id}/eliminar")
    public String eliminar(@PathVariable String tab, @PathVariable long id, RedirectAttributes ra) {
        Mensajes.intentar(ra, "Registro eliminado", () -> {
            switch (tab) {
                case "especies" -> repo.eliminarEspecie(id);
                case "razas" -> repo.eliminarRaza(id);
                case "especialidades" -> repo.eliminarEspecialidad(id);
                case "consultorios" -> repo.alternarConsultorio(id);
                case "diagnosticos" -> repo.eliminarDiagnostico(id);
                case "vacunas" -> repo.eliminarVacuna(id);
                default -> throw new IllegalArgumentException("Catalogo desconocido");
            }
        });
        return volver(tab);
    }
}
