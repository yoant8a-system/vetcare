package com.vet.web;

import com.vet.db.ErroresOracle;
import com.vet.db.SqlPendienteException;
import com.vet.modulos.sistema.SistemaRepositorio;
import com.vet.seguridad.UsuarioSesion;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ModelAttribute;

/**
 * Para TODAS las paginas: el usuario logueado, la ruta actual (menu activo) y las alertas sin leer.
 * Y si una pagina falla al cargar, muestra el error dentro de la plantilla en vez de una pagina en blanco.
 */
@ControllerAdvice
public class GlobalAdvice {

    private static final Logger log = LoggerFactory.getLogger(GlobalAdvice.class);

    private final SistemaRepositorio sistema;

    public GlobalAdvice(SistemaRepositorio sistema) {
        this.sistema = sistema;
    }

    @ModelAttribute
    public void datosComunes(Model model, HttpSession sesion, HttpServletRequest req) {
        UsuarioSesion u = (UsuarioSesion) sesion.getAttribute(UsuarioSesion.ATRIBUTO);
        model.addAttribute("u", u);
        model.addAttribute("ruta", req.getRequestURI());
        model.addAttribute("modoSolucion", com.vet.db.Sql.cantidadSoluciones());
        if (u != null) {
            try {
                model.addAttribute("alertasPendientes", sistema.alertasPendientes());
            } catch (RuntimeException e) {
                model.addAttribute("alertasPendientes", null);
            }
        }
    }

    // Los manejadores de error reciben un Model nuevo: se vuelven a cargar los datos comunes (menu, usuario)

    @ExceptionHandler(SqlPendienteException.class)
    public String pendiente(SqlPendienteException e, Model model, HttpSession sesion, HttpServletRequest req) {
        datosComunes(model, sesion, req);
        model.addAttribute("idSql", e.getId());
        return "error/pendiente";
    }

    @ExceptionHandler(Exception.class)
    public String error(Exception e, Model model, HttpSession sesion, HttpServletRequest req) {
        datosComunes(model, sesion, req);
        log.warn("Error en pagina: {}", e.toString());
        model.addAttribute("mensaje", ErroresOracle.mensaje(e));
        return "error/general";
    }
}
