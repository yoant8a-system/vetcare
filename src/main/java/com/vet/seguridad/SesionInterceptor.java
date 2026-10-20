package com.vet.seguridad;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.web.servlet.HandlerInterceptor;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Antes de cada pagina: exige login y revisa que el ROL pueda entrar a esa ruta.
 * (Control de acceso de la aplicacion. El de la BD son los GRANT/roles de Oracle.)
 */
public class SesionInterceptor implements HandlerInterceptor {

    /** Prefijo de ruta -> roles permitidos. Lo que no esta aqui lo ve cualquier usuario logueado. */
    private static final Map<String, String[]> PERMISOS = new LinkedHashMap<>();

    static {
        PERMISOS.put("/admin", new String[]{"ADMIN"});
        PERMISOS.put("/consultorio", new String[]{"VETERINARIO"});
        PERMISOS.put("/inventario", new String[]{"ADMIN", "VETERINARIO"});
        PERMISOS.put("/citas/nueva", new String[]{"ADMIN", "RECEPCION"});
        PERMISOS.put("/citas/llegada", new String[]{"ADMIN", "RECEPCION", "VETERINARIO"});
        PERMISOS.put("/tratamientos", new String[]{"ADMIN", "VETERINARIO"});
    }

    @Override
    public boolean preHandle(HttpServletRequest req, HttpServletResponse res, Object handler) throws Exception {
        UsuarioSesion u = (UsuarioSesion) req.getSession().getAttribute(UsuarioSesion.ATRIBUTO);
        if (u == null) {
            res.sendRedirect(req.getContextPath() + "/login");
            return false;
        }
        String ruta = req.getRequestURI().substring(req.getContextPath().length());
        for (Map.Entry<String, String[]> p : PERMISOS.entrySet()) {
            if (ruta.startsWith(p.getKey()) && !u.tieneRol(p.getValue())) {
                res.sendError(HttpServletResponse.SC_FORBIDDEN, "Su rol no tiene acceso a esta seccion");
                return false;
            }
        }
        UsuarioActual.set(u.usuario());
        return true;
    }

    @Override
    public void afterCompletion(HttpServletRequest req, HttpServletResponse res, Object handler, Exception ex) {
        UsuarioActual.limpiar();
    }
}
