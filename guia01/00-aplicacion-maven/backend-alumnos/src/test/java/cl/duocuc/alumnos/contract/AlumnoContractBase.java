package cl.duocuc.alumnos.contract;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.MockitoAnnotations;

import cl.duocuc.alumnos.application.AlumnoService;
import cl.duocuc.alumnos.domain.Alumno;
import cl.duocuc.alumnos.infrastructure.controller.AlumnoController;
import io.restassured.module.mockmvc.RestAssuredMockMvc;

/**
 * Clase base para los tests de contrato generados por Spring Cloud Contract.
 *
 * <p>Usa standaloneSetup (sin contexto Spring ni filtros de seguridad) para que los contratos
 * POST/PUT/DELETE funcionen sin token CSRF.
 */
public abstract class AlumnoContractBase {

    @Mock private AlumnoService service;

    @InjectMocks private AlumnoController controller;

    @BeforeEach
    void setUp() {
        MockitoAnnotations.openMocks(this);

        // Stub: GET /alumnos → lista vacía
        when(service.listar()).thenReturn(List.of());

        // Stub: POST /alumnos → alumno creado con id=1
        when(service.crear(any(Alumno.class))).thenReturn(new Alumno(1L, "Juan", "Perez"));

        // standaloneSetup: sin Spring context, sin filtros de seguridad, sin CSRF
        RestAssuredMockMvc.standaloneSetup(controller);
    }
}
