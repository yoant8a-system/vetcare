package com.vet.web;

import com.vet.db.ErroresOracle;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

/**
 * Ejecuta una accion de un formulario (POST) y deja un mensaje para la siguiente pagina:
 * verde si salio bien, rojo con el error de Oracle traducido si fallo.
 */
public final class Mensajes {

    private Mensajes() {
    }

    public interface Accion {
        void ejecutar() throws Exception;
    }

    /** Devuelve true si la accion se ejecuto sin errores. */
    public static boolean intentar(RedirectAttributes ra, String mensajeOk, Accion accion) {
        try {
            accion.ejecutar();
            if (mensajeOk != null) {
                ra.addFlashAttribute("ok", mensajeOk);
            }
            return true;
        } catch (Exception e) {
            ra.addFlashAttribute("error", ErroresOracle.mensaje(e));
            return false;
        }
    }

    public static void ok(RedirectAttributes ra, String mensaje) {
        ra.addFlashAttribute("ok", mensaje);
    }

    public static void error(RedirectAttributes ra, String mensaje) {
        ra.addFlashAttribute("error", mensaje);
    }
}
