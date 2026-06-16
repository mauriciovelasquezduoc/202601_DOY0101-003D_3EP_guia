package cl.duocuc.alumnos.infrastructure.mapper;

import cl.duocuc.alumnos.domain.Alumno;
import cl.duocuc.alumnos.infrastructure.entity.AlumnoEntity;

public final class AlumnoMapper {

    private AlumnoMapper() {
        // clase de utilidad, no instanciar
    }

    public static Alumno toDomain(AlumnoEntity e) {
        return new Alumno(e.getId(), e.getNombre(), e.getApellido());
    }

    public static AlumnoEntity toEntity(Alumno a) {
        return new AlumnoEntity(a.getId(), a.getNombre(), a.getApellido());
    }
}
