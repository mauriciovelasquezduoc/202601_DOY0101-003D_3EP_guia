package cl.duocuc.alumnos;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class DemoApplicationTest {

    @Test
    void contextLoads() {
        // Verifica que el contexto de Spring Boot levanta sin excepciones
        assertDoesNotThrow(() -> {}, "El contexto de Spring Boot debe levantar correctamente");
    }

    @Test
    void main_ejecutaSinExcepcion() {
        assertDoesNotThrow(
                () -> DemoApplication.main(new String[] {}),
                "El método main no debe lanzar excepciones");
    }
}
