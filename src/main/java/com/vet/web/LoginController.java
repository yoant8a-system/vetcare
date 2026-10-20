package com.vet.web;

import com.vet.db.ErroresOracle;
import com.vet.db.Plsql;
import com.vet.modulos.sistema.SistemaRepositorio;
import com.vet.seguridad.UsuarioActual;
import com.vet.seguridad.UsuarioSesion;
import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;

/** Login: la clave se valida en Oracle (PKG_SEGURIDAD.PR_LOGIN), nunca en Java. */
@Controller
public class LoginController {

    private final SistemaRepositorio sistema;

    public LoginController(SistemaRepositorio sistema) {
        this.sistema = sistema;
    }

    @GetMapping("/login")
    public String login(HttpSession sesion) {
        return sesion.getAttribute(UsuarioSesion.ATRIBUTO) != null ? "redirect:/" : "login";
    }

    @PostMapping("/login")
    public String entrar(@RequestParam String usuario, @RequestParam String clave, HttpSession sesion, Model model) {
        try {
            UsuarioActual.set(usuario);
            Plsql.Resultado r = sistema.login(usuario, clave);
            sesion.setAttribute(UsuarioSesion.ATRIBUTO,
                    new UsuarioSesion(r.numero(0), usuario.trim().toLowerCase(), r.texto(1), r.texto(2), r.numero(3)));
            return "redirect:/";
        } catch (Exception e) {
            model.addAttribute("error", ErroresOracle.mensaje(e));
            model.addAttribute("usuario", usuario);
            return "login";
        } finally {
            UsuarioActual.limpiar();
        }
    }

    @GetMapping("/logout")
    public String salir(HttpSession sesion) {
        sesion.invalidate();
        return "redirect:/login";
    }
}
