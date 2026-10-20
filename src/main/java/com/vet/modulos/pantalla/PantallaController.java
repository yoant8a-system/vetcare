package com.vet.modulos.pantalla;

import com.vet.db.ErroresOracle;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import java.util.HashMap;
import java.util.Map;

/** Pantalla publica de la sala de espera (sin login). La pagina pide /api/pantalla cada 3 segundos. */
@Controller
public class PantallaController {

    private final PantallaRepositorio repo;

    public PantallaController(PantallaRepositorio repo) {
        this.repo = repo;
    }

    @GetMapping("/pantalla")
    public String pantalla() {
        return "pantalla";
    }

    @GetMapping("/api/pantalla")
    @ResponseBody
    public Map<String, Object> datos() {
        Map<String, Object> r = new HashMap<>();
        try {
            r.put("llamados", repo.llamados());
            r.put("proximos", repo.proximos());
            r.put("enEspera", repo.enEspera());
        } catch (RuntimeException e) {
            r.put("error", ErroresOracle.mensaje(e));
        }
        return r;
    }
}
