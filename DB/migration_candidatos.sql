-- -----------------------------------------------------------------------------
-- MIGRACIÓN BASE DE DATOS: TABLA CANDIDATO
-- Fecha: 2026-02-05
-- Descripción: Script para agregar la tabla de candidatos, vista relacionada
-- y datos iniciales de los candidatos presidenciales existentes.
-- -----------------------------------------------------------------------------

SET NAMES utf8mb4;

-- 1. Crear la tabla `candidato`
-- Se incluye el campo `region` para candidatos regionales y `id_partido` como FK.
DROP TABLE IF EXISTS `candidato`;
CREATE TABLE `candidato` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `nombres` varchar(100) NOT NULL,
  `apellidos` varchar(100) NOT NULL,
  `cargo` enum('presidente',
               '1er vicepresidente',
               '2do vicepresidente',
               'diputado',
               'senador nacional',
               'senador regional',
               'parlamento andino') NOT NULL,
  `region` varchar(100) DEFAULT NULL COMMENT 'Solo para congresistas/senadores regionales',
  `foto` varchar(500) DEFAULT NULL COMMENT 'URL de la foto',
  `hojavida` varchar(500) DEFAULT NULL COMMENT 'URL de la hoja de vida',
  `id_partido` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_cargo` (`cargo`),
  KEY `idx_partido_candidato` (`id_partido`),
  CONSTRAINT `fk_candidato_partido` FOREIGN KEY (`id_partido`) REFERENCES `partido` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 2. Crear la vista `vista_candidatos`
-- Facilita la consulta de candidatos junto con la información de su partido (logo, color).
CREATE OR REPLACE VIEW `vista_candidatos` AS
SELECT 
    c.id AS candidato_id,
    c.nombres,
    c.apellidos,
    CONCAT(c.nombres, ' ', c.apellidos) AS nombre_completo,
    c.cargo,
    c.region,
    c.foto,
    c.hojavida,
    c.id_partido,
    p.nombre AS partido_nombre,
    p.sigla AS partido_sigla,
    pm.logo_key,
    pm.color_primario
FROM candidato c
JOIN partido p ON c.id_partido = p.id
LEFT JOIN partido_metadata pm ON p.id = pm.partido_id;

-- 3. Insertar datos iniciales (Candidatos Presidenciales)
-- Basado en los datos existentes en partido_metadata
INSERT INTO `candidato` (`nombres`, `apellidos`, `cargo`, `id_partido`) VALUES
('Alfonso', 'Lopez Chau', 'presidente', 2),        -- AHORA NACION
('Keiko', 'Fujimori', 'presidente', 9),            -- FUERZA POPULAR
('Rafael', 'Belaúnde Llosa', 'presidente', 12),    -- LIBERTAD POPULAR
('Ronald', 'Atencio', 'presidente', 34),           -- VOCES DEL PUEBLO
('Marisol', 'Pérez Tello', 'presidente', 41),      -- PRIMERO LA GENTE
('Rafael', 'López Aliaga', 'presidente', 43);      -- RENOVACION POPULAR

-- 4. Ejemplos de otros cargos (Comentados como referencia para llenar después)
-- INSERT INTO `candidato` (`nombres`, `apellidos`, `cargo`, `id_partido`, `region`) VALUES
-- ('Juan', 'Perez', 'senador regional', 9, 'Lima'),
-- ('Maria', 'Gomez', '1er vicepresidente', 43, NULL);
