-- =============================================================
-- Script de inicialización de base de datos: alumnosdb
-- Alineado con AlumnoEntity (@Table(name = "alumnos"))
-- =============================================================

CREATE DATABASE IF NOT EXISTS alumnosdb
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE alumnosdb;

-- Tabla principal de alumnos
-- Campos: id (PK auto-incremental), nombre, apellido
CREATE TABLE IF NOT EXISTS alumnos (
    id       BIGINT       NOT NULL AUTO_INCREMENT,
    nombre   VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    CONSTRAINT pk_alumnos PRIMARY KEY (id)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;

-- Datos de ejemplo para desarrollo / smoke-test
INSERT INTO alumnos (nombre, apellido) VALUES
    ('Ana',     'González'),
    ('Carlos',  'Ramírez'),
    ('Valentina','Morales');
