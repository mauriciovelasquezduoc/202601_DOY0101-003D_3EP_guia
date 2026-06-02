package cl.duocuc.alumnos.infrastructure.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import cl.duocuc.alumnos.infrastructure.entity.AlumnoEntity;

public interface AlumnoRepository extends JpaRepository<AlumnoEntity, Long> {}
