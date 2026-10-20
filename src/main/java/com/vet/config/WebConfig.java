package com.vet.config;

import com.vet.seguridad.SesionInterceptor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(new SesionInterceptor())
                .addPathPatterns("/**")
                // Paginas publicas: login, pantalla de sala (TV) y archivos estaticos
                .excludePathPatterns("/login", "/pantalla", "/api/pantalla", "/css/**", "/js/**",
                        "/img/**", "/webjars/**", "/favicon.ico", "/error");
    }
}
