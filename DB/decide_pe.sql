-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 07-02-2026 a las 20:28:55
-- Versión del servidor: 10.4.32-MariaDB
-- Versión de PHP: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `decide_pe`
--
CREATE DATABASE IF NOT EXISTS `decide_pe` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE `decide_pe`;

DELIMITER $$
--
-- Procedimientos
--
DROP PROCEDURE IF EXISTS `CalcularPosicionPartido`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `CalcularPosicionPartido` (IN `p_partido_id` INT)   BEGIN
    DECLARE total_x, total_y DECIMAL(10,2);
    DECLARE count_x, count_y INT;
    DECLARE pos_x, pos_y DECIMAL(5,2);
    
    -- Calcular sumas y conteos por eje (EXCLUYENDO valor 0)
    SELECT 
        SUM(CASE WHEN p.eje = 'X' THEN pr.valor * p.direccion ELSE 0 END),
        SUM(CASE WHEN p.eje = 'Y' THEN pr.valor * p.direccion ELSE 0 END),
        SUM(CASE WHEN p.eje = 'X' AND pr.valor != 0 THEN 1 ELSE 0 END),
        SUM(CASE WHEN p.eje = 'Y' AND pr.valor != 0 THEN 1 ELSE 0 END)
    INTO total_x, total_y, count_x, count_y
    FROM PartidoRespuesta pr
    JOIN Pregunta p ON pr.pregunta_id = p.id
    WHERE pr.partido_id = p_partido_id AND p.estado = 'activa';
    
    -- Factor 2: (Valor_Max / 2) * 100 = 100. (Protección división por cero con GREATEST)
    SET pos_x = (IFNULL(total_x, 0) / (GREATEST(1, IFNULL(count_x, 0)) * 2)) * 100;
    SET pos_y = (IFNULL(total_y, 0) / (GREATEST(1, IFNULL(count_y, 0)) * 2)) * 100;
    
    -- Asegurar límites -100 a +100
    SET pos_x = GREATEST(-100, LEAST(100, pos_x));
    SET pos_y = GREATEST(-100, LEAST(100, pos_y));
    
    INSERT INTO PartidoPosicionCache (partido_id, posicion_x, posicion_y, fecha_calculo)
    VALUES (p_partido_id, pos_x, pos_y, NOW())
    ON DUPLICATE KEY UPDATE posicion_x = pos_x, posicion_y = pos_y, fecha_calculo = NOW();
END$$

DROP PROCEDURE IF EXISTS `CalcularPosicionUsuario`$$
CREATE DEFINER=`root`@`localhost` PROCEDURE `CalcularPosicionUsuario` (IN `p_sesion_id` INT)   BEGIN
    DECLARE total_x, total_y DECIMAL(10,2);
    DECLARE count_x, count_y INT;
    DECLARE pos_x, pos_y DECIMAL(5,2);
    DECLARE v_token VARCHAR(12);
    DECLARE v_exists INT;
    
    -- Calcular sumas y conteos por eje
    SELECT 
        SUM(CASE WHEN p.eje = 'X' THEN ur.valor * p.direccion ELSE 0 END),
        SUM(CASE WHEN p.eje = 'Y' THEN ur.valor * p.direccion ELSE 0 END),
        SUM(CASE WHEN p.eje = 'X' AND ur.valor != 0 THEN 1 ELSE 0 END),
        SUM(CASE WHEN p.eje = 'Y' AND ur.valor != 0 THEN 1 ELSE 0 END)
    INTO total_x, total_y, count_x, count_y
    FROM UsuarioRespuesta ur
    JOIN Pregunta p ON ur.pregunta_id = p.id
    WHERE ur.sesion_id = p_sesion_id AND p.estado = 'activa';
    
    SET pos_x = (IFNULL(total_x, 0) / (GREATEST(1, IFNULL(count_x, 0)) * 2)) * 100;
    SET pos_y = (IFNULL(total_y, 0) / (GREATEST(1, IFNULL(count_y, 0)) * 2)) * 100;
    
    -- Generar token único de 10 caracteres
    token_loop: LOOP
        SET v_token = SUBSTRING(MD5(RAND()), 1, 10);
        SELECT COUNT(*) INTO v_exists FROM UsuarioSesion WHERE token = v_token;
        IF v_exists = 0 THEN
            LEAVE token_loop;
        END IF;
    END LOOP;
    
    UPDATE UsuarioSesion 
    SET resultado_x = GREATEST(-100, LEAST(100, pos_x)), 
        resultado_y = GREATEST(-100, LEAST(100, pos_y)),
        completado = TRUE,
        token = v_token
    WHERE id = p_sesion_id;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `candidato`
--

DROP TABLE IF EXISTS `candidato`;
CREATE TABLE `candidato` (
  `id` int(11) NOT NULL,
  `nombres` varchar(100) NOT NULL,
  `apellidos` varchar(100) NOT NULL,
  `cargo` enum('presidente','1er vicepresidente','2do vicepresidente','diputado','senador nacional','senador regional','parlamento andino') NOT NULL,
  `numero` int(2) DEFAULT NULL,
  `id_region` int(11) DEFAULT 1,
  `region` varchar(100) DEFAULT NULL COMMENT 'Solo para congresistas/senadores regionales',
  `foto` varchar(500) DEFAULT NULL COMMENT 'URL de la foto',
  `hojavida` varchar(500) DEFAULT NULL COMMENT 'URL de la hoja de vida',
  `id_partido` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `candidato`
--

INSERT INTO `candidato` (`id`, `nombres`, `apellidos`, `cargo`, `numero`, `id_region`, `region`, `foto`, `hojavida`, `id_partido`) VALUES
(1, 'Alfonso', 'Lopez Chau', 'presidente', NULL, 1, NULL, 'https://mpesije.jne.gob.pe/apidocs/ddfa74eb-cae3-401c-a34c-35543ae83c57.jpg', 'https://mpesije.jne.gob.pe/apidocs/4ba2cdce-703e-421b-8b75-746b4dd21439.pdf', 2),
(2, 'Keiko', 'Fujimori', 'presidente', NULL, 1, NULL, NULL, NULL, 9),
(3, 'RAFAEL JORGE', 'BELAUNDE LLOSA', 'presidente', NULL, 1, NULL, 'https://mpesije.jne.gob.pe/apidocs/3302e45b-55c8-4979-a60b-2b11097abf1d.jpg', 'https://mpesije.jne.gob.pe/apidocs/74eadffc-2e05-4054-b113-a010d3c4de6c.pdf', 12),
(4, 'Ronald', 'Atencio', 'presidente', NULL, 1, NULL, 'https://mpesije.jne.gob.pe/apidocs/bac0288d-3b21-45ac-8849-39f9177fb020.jpg', 'https://mpesije.jne.gob.pe/apidocs/f589c135-2e56-4b5c-8359-a3749190c8ab.pdf', 34),
(5, 'Marisol', 'Pérez Tello', 'presidente', NULL, 1, NULL, 'https://mpesije.jne.gob.pe/apidocs/073703ca-c427-44f0-94b1-a782223a5e10.jpg', 'https://mpesije.jne.gob.pe/apidocs/8f27eca5-63d1-4c5f-bd71-fbb5d544891e.pdf', 41),
(6, 'Rafael', 'López Aliaga', 'presidente', NULL, 1, NULL, 'https://mpesije.jne.gob.pe/apidocs/b2e00ae2-1e50-4ad3-a103-71fc7e4e8255.jpg', 'https://mpesije.jne.gob.pe/apidocs/3d7498fe-7a54-4f7d-882e-c5cdfd2ba26b.pdf', 43),
(7, 'LUIS ALBERTO', 'VILLANUEVA CARBAJAL', '1er vicepresidente', NULL, 1, NULL, 'https://mpesije.jne.gob.pe/apidocs/41377696-3376-4806-b0eb-87145ffa0bac.jpg', 'https://mpesije.jne.gob.pe/apidocs/91e58256-60be-485f-b75b-0f3c99472b2a.pdf', 2),
(8, 'RUTH ZENAIDA', 'BUENDIA MESTOQUIARI', '2do vicepresidente', NULL, 1, NULL, 'https://mpesije.jne.gob.pe/apidocs/bb54fed8-ee8d-4557-93cf-c3da557f4766.jpg', 'https://mpesije.jne.gob.pe/apidocs/98d47d3f-0bb8-49f9-a872-600adc55306c.pdf', 2),
(9, 'LUIS FERNANDO', 'GALARRETA VELARDE', '1er vicepresidente', NULL, 1, NULL, NULL, 'https://mpesije.jne.gob.pe/apidocs/ba40250f-5762-4f4f-a156-747e54440e5b.pdf', 9),
(10, 'MIGUEL ANGEL', 'TORRES MORALES', '2do vicepresidente', NULL, 1, NULL, NULL, 'https://mpesije.jne.gob.pe/apidocs/99872797-b3bf-452e-939b-06d1cdeaa917.pdf', 9),
(11, 'PEDRO ALVARO', 'CATERIANO BELLIDO', '1er vicepresidente', NULL, 1, NULL, 'https://mpesije.jne.gob.pe/apidocs/8c2fed85-3a83-4227-80b8-6df2ae5627c9.jpg', 'https://mpesije.jne.gob.pe/apidocs/af2bf963-af2a-40dd-b7be-0c3f49072158.pdf', 12),
(12, 'TANIA ULRIKA', 'PORLES BAZALAR', '2do vicepresidente', NULL, 1, NULL, 'https://mpesije.jne.gob.pe/apidocs/0e26188d-ad29-40db-8472-b744e6868485.jpg', 'https://mpesije.jne.gob.pe/apidocs/6290b676-2758-462e-9eff-6511b6532f00.pdf', 12),
(13, 'HARVEY JULIO', 'COLCHADO HUAMANI', 'diputado', 1, 2, 'Lima Metropolitana', 'https://mpesije.jne.gob.pe/apidocs/aaf42d15-51c4-42da-970a-27fc9722d258.jpg', 'https://mpesije.jne.gob.pe/apidocs/c385533c-6800-49cc-a5dd-bc890f9e6f0e.pdf', 2),
(14, 'INDIRA ISABEL', 'HUILCA FLORES', 'diputado', 2, 2, 'Lima Metropolitana', 'https://mpesije.jne.gob.pe/apidocs/00a34212-f067-4014-be90-c9a48610b7d1.jpg', 'https://mpesije.jne.gob.pe/apidocs/df68e47e-04af-4dfe-b08d-ce5fa2659ae8.pdf', 2),
(15, 'JOSEPH ELIAS', 'DAGER ALVA', 'diputado', NULL, 1, 'Lima Metropolitana', 'https://mpesije.jne.gob.pe/apidocs/61a51f93-7501-485c-afe1-6a0325129b3a.jpg', 'https://mpesije.jne.gob.pe/apidocs/33359c37-3017-453d-bceb-395a11697924.pdf', 2),
(16, 'ANITA MILEIDI', 'ABANTO VILLEGAS', 'diputado', NULL, 1, 'Lima Metropolitana', 'https://mpesije.jne.gob.pe/apidocs/56f0e603-5a74-4730-bb7d-bdb19b3b4b9a.jpg', 'https://mpesije.jne.gob.pe/apidocs/c9949abb-c15f-4dda-9854-1df867564c03.pdf', 2);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `partido`
--

DROP TABLE IF EXISTS `partido`;
CREATE TABLE `partido` (
  `id` int(11) NOT NULL,
  `nombre` varchar(50) NOT NULL,
  `nombre_largo` varchar(100) NOT NULL,
  `sigla` varchar(10) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `partido`
--

INSERT INTO `partido` (`id`, `nombre`, `nombre_largo`, `sigla`) VALUES
(2, 'AHORA NACION', 'Ahora Nación', 'AN'),
(9, 'FUERZA POPULAR', 'Fuerza Popular', 'FP'),
(12, 'LIBERTAD POPULAR', 'Libertad Popular', 'LP'),
(34, 'VOCES DEL PUEBLO', 'Partido Político Voces del Pueblo', 'VP'),
(41, 'PRIMERO LA GENTE', 'Primero la Gente - Comunidad, Ecología, Libertad y Progreso', 'PLG'),
(43, 'RENOVACION POPULAR', 'Renovación Popular', 'RP');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `partidoposicioncache`
--

DROP TABLE IF EXISTS `partidoposicioncache`;
CREATE TABLE `partidoposicioncache` (
  `partido_id` int(11) NOT NULL,
  `posicion_x` decimal(5,2) DEFAULT NULL COMMENT '-100.00 a +100.00',
  `posicion_y` decimal(5,2) DEFAULT NULL COMMENT '-100.00 a +100.00',
  `fecha_calculo` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `partidoposicioncache`
--

INSERT INTO `partidoposicioncache` (`partido_id`, `posicion_x`, `posicion_y`, `fecha_calculo`) VALUES
(2, -30.00, -52.78, '2026-02-04 00:00:00'),
(9, 37.50, 0.00, '2026-02-04 02:38:57'),
(12, 60.00, 50.00, '2026-02-04 00:00:00'),
(34, 0.00, 0.00, '2026-02-04 00:00:00'),
(41, -10.00, -40.00, '2026-02-04 00:00:00'),
(43, 77.78, -36.36, '2026-02-04 02:47:03');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `partidorespuesta`
--

DROP TABLE IF EXISTS `partidorespuesta`;
CREATE TABLE `partidorespuesta` (
  `partido_id` int(11) NOT NULL,
  `pregunta_id` int(11) NOT NULL,
  `valor` tinyint(4) NOT NULL COMMENT '-2, -1, 0, +1, +2',
  `fuente` varchar(500) DEFAULT NULL COMMENT 'URL o referencia de la posición'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `partidorespuesta`
--

INSERT INTO `partidorespuesta` (`partido_id`, `pregunta_id`, `valor`, `fuente`) VALUES
(9, 1, 1, 'Necesitamos responsabilidad fiscal, pero el Congreso debe mantener capacidad de fiscalización del gasto'),
(9, 2, -1, 'Preferimos generar riqueza mediante inversión privada y crecimiento económico, no ahuyentar capitales'),
(9, 3, 1, 'Las familias de las zonas mineras merecen beneficiarse directamente de sus recursos'),
(9, 4, -1, 'El mercado es fundamental, pero se necesitan programas sociales focalizados como en los 90'),
(9, 5, 2, 'La seguridad es prioridad y necesitamos usar todos los recursos disponibles contra la delincuencia'),
(9, 6, 1, 'Tolerancia cero con extranjeros que delinquen, el Perú primero'),
(9, 7, 1, 'Necesitamos reformar el Poder Judicial para acabar con la corrupción enquistada'),
(9, 8, -1, 'Necesitamos más cárceles y mano dura, no blandura con los delincuentes'),
(9, 9, 0, 'Debemos mejorar el sistema actual sin experimentos que puedan destruir lo que funciona'),
(9, 10, -1, 'Los padres deben decidir sobre estos temas, no el Estado imponiendo ideologías'),
(9, 11, 1, 'Descentralización educativa con estándares nacionales mínimos'),
(9, 12, 2, 'La meritocracia es fundamental, nuestros niños merecen los mejores maestros'),
(9, 13, -1, 'Debemos equilibrar desarrollo económico con protección ambiental responsable'),
(9, 14, -1, 'Debe evaluarse caso por caso con estudios técnicos, no prohibiciones absolutas'),
(9, 15, 1, 'La minería formal con estándares ambientales adecuados es clave para el desarrollo del Perú'),
(9, 16, 2, 'Petroperú ha sido un barril sin fondo, necesitamos gestión privada eficiente'),
(9, 17, 1, 'Estado eficiente, no elefante blanco que desperdicia recursos del pueblo'),
(9, 18, 2, 'La tecnología debe servir para combatir la corrupción en las compras estatales'),
(9, 19, 1, 'El pueblo debe decidir su futuro en temas fundamentales'),
(9, 20, 2, 'Tolerancia cero con corruptos, fuera para siempre de la función pública'),
(43, 1, 2, 'El Congreso no puede seguir siendo una fuente de gasto irresponsable, necesitamos disciplina total'),
(43, 2, -2, 'Eso es comunismo disfrazado, espanta la inversión y destruye la economía'),
(43, 3, 1, 'El dinero debe ir directo a la gente, no a intermediarios corruptos ni alcaldes ladrones'),
(43, 4, 2, 'El libre mercado, la empresa privada y el trabajo honrado sacan de la pobreza, no el estatismo'),
(43, 5, 2, 'Mano dura contra la delincuencia, las FFAA a las calles ya, a los delincuentes bala'),
(43, 6, 2, 'Fuera inmediatamente, tolerancia cero con venezolanos y extranjeros delincuentes'),
(43, 7, 2, 'Hay que refundar el Poder Judicial de arriba abajo, está podrido y lleno de terrucos'),
(43, 8, 2, 'Eso es ser blando con criminales, necesitamos cárceles de máxima seguridad y cadena perpetuaso es ser blando con criminales, necesitamos cárceles de máxima seguridad y cadena perpetua'),
(43, 9, -1, 'El sistema público es un desastre, hay que fortalecer lo privado y dar libertad de elección'),
(43, 10, 2, 'Eso es ideología de género marxista, los padres educan a sus hijos, no el Estado caviar'),
(43, 11, 1, 'Menos burocracia del Minedu y más libertad para los colegios y los padres de familia'),
(43, 12, 2, 'Meritocracia total, fuera los profesores mediocres protegidos por el Sutep marxista'),
(43, 13, 2, 'Eso es un cuento de ecologistas radicales para frenar el desarrollo del Perú'),
(43, 14, -2, 'Pura demagogia de caviares y ONGs que viven del cuento ecologista'),
(43, 15, 2, 'La minería formal es el futuro, hay que destrabar proyectos y acabar con la burocracia'),
(43, 16, 2, 'Petroperú es un elefante blanco corrupto, hay que privatizarla completamente'),
(43, 17, 2, 'El Estado es un monstruo burocrático ineficiente, hay que achicarlo radicalmente'),
(43, 18, 2, 'Tecnología contra la corrupción, transparencia total en cada sol gastado'),
(43, 19, 1, 'El pueblo debe decidir, no los congresistas corruptos ni las cúpulas políticas'),
(43, 20, 2, 'Corruptos fuera para siempre, y también cadena perpetua para los más graves');

--
-- Disparadores `partidorespuesta`
--
DROP TRIGGER IF EXISTS `actualizar_posicion_partido_delete`;
DELIMITER $$
CREATE TRIGGER `actualizar_posicion_partido_delete` AFTER DELETE ON `partidorespuesta` FOR EACH ROW BEGIN CALL CalcularPosicionPartido(OLD.partido_id); END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `actualizar_posicion_partido_insert`;
DELIMITER $$
CREATE TRIGGER `actualizar_posicion_partido_insert` AFTER INSERT ON `partidorespuesta` FOR EACH ROW BEGIN CALL CalcularPosicionPartido(NEW.partido_id); END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `actualizar_posicion_partido_update`;
DELIMITER $$
CREATE TRIGGER `actualizar_posicion_partido_update` AFTER UPDATE ON `partidorespuesta` FOR EACH ROW BEGIN CALL CalcularPosicionPartido(NEW.partido_id); END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `partido_metadata`
--

DROP TABLE IF EXISTS `partido_metadata`;
CREATE TABLE `partido_metadata` (
  `id` int(11) NOT NULL,
  `partido_id` int(11) NOT NULL,
  `candidato_presidencial` varchar(100) DEFAULT NULL,
  `lider_partido` varchar(100) DEFAULT NULL,
  `color_primario` varchar(7) DEFAULT '#000000',
  `logo_key` varchar(50) NOT NULL,
  `candidato_key` varchar(50) NOT NULL DEFAULT 'DEFAULT_CANDIDATE',
  `anio_fundacion` year(4) DEFAULT NULL,
  `anio_inscripcion_jne` year(4) DEFAULT NULL,
  `tipo_organizacion` varchar(50) DEFAULT 'Partido Político'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `partido_metadata`
--

INSERT INTO `partido_metadata` (`id`, `partido_id`, `candidato_presidencial`, `lider_partido`, `color_primario`, `logo_key`, `candidato_key`, `anio_fundacion`, `anio_inscripcion_jne`, `tipo_organizacion`) VALUES
(2, 2, 'Alfonso Lopez Chau', 'Alfonso Lopez Chau', '#eb0206', 'AHORA NACION', 'A_LCHAU', NULL, NULL, 'Partido Político'),
(9, 9, 'Keiko Fujimori', 'Keiko Fujimori', '#eb6d00', 'FUERZA POPULAR', 'K_FUJIMORI', NULL, NULL, 'Partido Político'),
(12, 12, 'Rafael Belaúnde Llosa', 'Rafael Belaúnde Llosa', '#ffff01', 'LIBERTAD POPULAR', 'R_BELAUNDE', NULL, NULL, 'Partido Político'),
(34, 34, 'Ronald Atencio', 'Guillermo Bermejo', '#d90736', 'VOCES DEL PUEBLO', 'R_ATENCIO', NULL, NULL, 'Partido Político'),
(41, 41, 'Marisol Pérez Tello', 'Manuel Ato Carrera', '#2252a7', 'PRIMERO LA GENTE', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(43, 43, 'Rafael López Aliaga', 'Rafael López Aliaga', '#049ad7', 'RENOVACION POPULAR', 'R_LOPEZ', NULL, NULL, 'Partido Político');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pregunta`
--

DROP TABLE IF EXISTS `pregunta`;
CREATE TABLE `pregunta` (
  `id` int(11) NOT NULL,
  `texto` text NOT NULL,
  `eje` enum('X','Y') NOT NULL COMMENT 'X: económico, Y: social',
  `direccion` tinyint(4) NOT NULL COMMENT '+1 o -1',
  `estado` enum('activa','inactiva') DEFAULT 'activa',
  `categoria` varchar(50) DEFAULT NULL COMMENT 'economia, derechos, ambiental, social'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `pregunta`
--

INSERT INTO `pregunta` (`id`, `texto`, `eje`, `direccion`, `estado`, `categoria`) VALUES
(1, 'El Congreso debe tener prohibido por ley crear cualquier tipo de iniciativa de gasto para garantizar la disciplina fiscal.', 'X', 1, 'activa', 'Economía'),
(2, 'El Estado debe cobrar un impuesto a la riqueza para financiar programas sociales de redistribución.', 'X', -1, 'activa', 'Economía'),
(3, '¿Apoya que se entregue dinero directo del canon minero a las familias de las zonas de influencia (Cheque Minero)?', 'X', -1, 'activa', 'Economía'),
(4, 'La libertad de mercado es suficiente para eliminar la pobreza sin necesidad de una intervención activa del Estado.', 'X', 1, 'activa', 'Economía'),
(5, 'Las Fuerzas Armadas deben patrullar las calles de forma permanente junto a la Policía Nacional.', 'Y', 1, 'activa', 'Seguridad Ciudadana'),
(6, 'Los extranjeros que cometan cualquier delito deben ser expulsados inmediatamente del país.', 'Y', 1, 'activa', 'Seguridad Ciudadana'),
(7, 'Se debe eliminar la reelección de jueces para evitar el clientelismo político en el Poder Judicial.', 'Y', -1, 'activa', 'Justicia y Derechos Humanos'),
(8, 'El hacinamiento en las cárceles se soluciona principalmente con medidas alternativas a la prisión, no con más penas.', 'Y', -1, 'activa', 'Justicia y Derechos Humanos'),
(9, 'El sistema de salud debe unificarse en una sola red pública universal (Minsa, EsSalud, privados).', 'X', -1, 'activa', 'Salud'),
(10, 'La educación sexual con enfoque de género debe ser obligatoria en todas las escuelas para prevenir embarazos adolescentes.', 'Y', -1, 'activa', 'Salud'),
(11, 'Los colegios públicos deben tener autonomía para adaptar el currículo educativo a su realidad regional.', 'Y', -1, 'activa', 'Educación'),
(12, 'La mejora en la educación pasa por evaluar y retirar a los docentes con bajo rendimiento (meritocracia docente).', 'X', 1, 'activa', 'Educación'),
(13, 'El cambio climático es la amenaza más grave y debe ser prioridad que límite cualquier proyecto extractivo.', 'Y', -1, 'activa', 'Medio Ambiente'),
(14, 'Se debe prohibir toda actividad extractiva (minería, hidrocarburos) en las cabeceras de cuenca.', 'Y', -1, 'activa', 'Medio Ambiente'),
(15, 'La minería debe ser el motor principal de la economía, eliminando trámites ambientales lentos que la frenen.', 'X', 1, 'activa', 'Agricultura, Energía y Minas'),
(16, 'El Estado no debe inyectar más presupuesto a Petroperú y debe permitir inversión privada mayoritaria en ella.', 'X', 1, 'activa', 'Agricultura, Energía y Minas'),
(17, 'El número de ministerios debe reducirse drásticamente (de 19 a 10) para evitar burocracia y gasto innecesario.', 'X', 1, 'activa', 'Economía'),
(18, 'Todas las compras del Estado deben ser monitoreadas por Inteligencia Artificial para detectar fraudes automáticamente.', 'Y', -1, 'activa', 'Rendición de Cuentas'),
(19, 'Se debe convocar a referéndum para que el pueblo decida directamente sobre reformas constitucionales importantes.', 'Y', -1, 'activa', 'Rendición de Cuentas'),
(20, 'Se debe aplicar la inhabilitación perpetua para cargos públicos a cualquier sentenciado por corrupción.', 'Y', -1, 'activa', 'Justicia y Derechos Humanos');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `region`
--

DROP TABLE IF EXISTS `region`;
CREATE TABLE `region` (
  `id` int(11) NOT NULL,
  `nombre` varchar(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `region`
--

INSERT INTO `region` (`id`, `nombre`) VALUES
(1, 'No Aplica'),
(2, 'Lima Metropolitana'),
(3, 'Callao');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

DROP TABLE IF EXISTS `usuario`;
CREATE TABLE `usuario` (
  `id` int(11) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `rol` enum('user','admin') DEFAULT 'user',
  `fecha_registro` timestamp NOT NULL DEFAULT current_timestamp(),
  `nombre` varchar(100) NOT NULL DEFAULT 'Usuario'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`id`, `email`, `password_hash`, `rol`, `fecha_registro`, `nombre`) VALUES
(1, 'pepepecas@email.com', '$argon2id$v=19$m=65536,t=2,p=1$cn8qXblaAFaqfd+h0EsKHE80qGKLlNveI1GzHWUCz4g$Dx/cKn+3+wzDb12qerw+FOp4/uXQieLKp3WYts877PU', 'user', '2026-01-22 22:06:36', 'Pepe Pecas'),
(2, 'admin@tubrujula.pe', '$argon2id$v=19$m=65536,t=2,p=1$7yag2hvze7/fXBEdnNAE07rJMp+cHWFbC0ZtTdVHpB8$792ls4jug00Am/0Z8dv1LX0vIU5QVF1rG5cyQlIG4Xc', 'admin', '2026-01-22 22:10:37', 'Miguel Hilario'),
(3, 'coyote@brujulae.com', '$argon2id$v=19$m=65536,t=2,p=1$4yvq28IRTPIbhWAMzuAbXkJmpphbnXfFRlL4f1UVhPk$vWZrdQZhUnyAuF1cjZlbFx1WPnVjsk+CaqoEL65Ay00', 'user', '2026-01-25 21:20:00', 'Peter Coyote'),
(4, 'cosme.fulanito@email.com', '$argon2id$v=19$m=65536,t=2,p=1$X7lF+l/vHUZ+d7xhUNYBOFXfJIqSgum8fmWImgsHBdg$SOmYQ7Z1mncsQCdD7H2AyGRVNDUGQ7yrzR6pYF2CxEQ', 'user', '2026-01-25 21:24:01', 'Peter Coyote2'),
(5, 'viejosabroso@email.com', '$argon2id$v=19$m=65536,t=2,p=1$v+niOt73lK09FcUyq4/ICzGr26isNOcewmB8bUgnPGE$5CUm16qaYYkHutu/yY1AdayCd9KJgv4Vtcsk/5KU61A', 'user', '2026-01-25 21:27:36', 'Peter Coyote3'),
(6, 'asdqwe@email.com', '$argon2id$v=19$m=65536,t=2,p=1$JGtkL8Ztwnx13s7a02YVxB9/4qjOH7Ym4P/E7F8B1J8$w95jnRZlM1BSA2idaJygTwMaBJ1G9Max/2ygfyKjXo0', 'user', '2026-01-25 21:32:35', 'Peter Coyote4'),
(37, 'dani@brujula.pe', '$argon2id$v=19$m=65536,t=2,p=1$m0yExu2kIfpnGqPEZdXHljvcqs5ik4HmoE8hTRdBYDc$LSxTzZC15K8Rfi6NwH059U+9E6nN7+DPqc72kLriEPs', 'user', '2026-02-05 22:43:11', 'Daniela Rocha Pérez');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuariorespuesta`
--

DROP TABLE IF EXISTS `usuariorespuesta`;
CREATE TABLE `usuariorespuesta` (
  `sesion_id` int(11) NOT NULL,
  `pregunta_id` int(11) NOT NULL,
  `valor` tinyint(4) NOT NULL COMMENT '-2, -1, 0, +1, +2',
  `fecha_respuesta` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuariorespuesta`
--

INSERT INTO `usuariorespuesta` (`sesion_id`, `pregunta_id`, `valor`, `fecha_respuesta`) VALUES
(5, 1, 2, '2026-02-05 19:52:26'),
(5, 2, 1, '2026-02-05 19:52:26'),
(5, 3, 2, '2026-02-05 19:52:26'),
(5, 4, 1, '2026-02-05 19:52:26'),
(5, 5, 2, '2026-02-05 19:52:26'),
(5, 6, 2, '2026-02-05 19:52:26'),
(5, 7, -1, '2026-02-05 19:52:26'),
(5, 8, 2, '2026-02-05 19:52:26'),
(5, 9, 2, '2026-02-05 19:52:26'),
(5, 10, 2, '2026-02-05 19:52:26'),
(5, 11, 2, '2026-02-05 19:52:26'),
(5, 12, 2, '2026-02-05 19:52:26'),
(5, 13, 1, '2026-02-05 19:52:26'),
(5, 14, 1, '2026-02-05 19:52:26'),
(5, 15, 1, '2026-02-05 19:52:26'),
(5, 16, 1, '2026-02-05 19:52:26'),
(5, 17, -1, '2026-02-05 19:52:26'),
(5, 18, 2, '2026-02-05 19:52:26'),
(5, 19, 1, '2026-02-05 19:52:26'),
(5, 20, 2, '2026-02-05 19:52:26'),
(18, 1, 2, '2026-02-05 21:45:17'),
(18, 2, 2, '2026-02-05 21:45:17'),
(18, 3, 2, '2026-02-05 21:45:17'),
(18, 4, 2, '2026-02-05 21:45:17'),
(18, 5, 2, '2026-02-05 21:45:17'),
(18, 6, 2, '2026-02-05 21:45:17'),
(18, 7, 2, '2026-02-05 21:45:17'),
(18, 8, 2, '2026-02-05 21:45:17'),
(18, 9, 2, '2026-02-05 21:45:17'),
(18, 10, 2, '2026-02-05 21:45:17'),
(18, 11, 2, '2026-02-05 21:45:17'),
(18, 12, 2, '2026-02-05 21:45:17'),
(18, 13, 2, '2026-02-05 21:45:17'),
(18, 14, 2, '2026-02-05 21:45:17'),
(18, 15, 2, '2026-02-05 21:45:17'),
(18, 16, 2, '2026-02-05 21:45:17'),
(18, 17, 2, '2026-02-05 21:45:17'),
(18, 18, 2, '2026-02-05 21:45:17'),
(18, 19, 2, '2026-02-05 21:45:17'),
(18, 20, 2, '2026-02-05 21:45:17'),
(19, 1, 2, '2026-02-05 22:34:28'),
(19, 2, -1, '2026-02-05 22:34:28'),
(19, 3, -1, '2026-02-05 22:34:28'),
(19, 4, -2, '2026-02-05 22:34:28'),
(19, 5, -2, '2026-02-05 22:34:28'),
(19, 6, 1, '2026-02-05 22:34:28'),
(19, 7, -2, '2026-02-05 22:34:28'),
(19, 8, -1, '2026-02-05 22:34:28'),
(19, 9, 2, '2026-02-05 22:34:28'),
(19, 10, -2, '2026-02-05 22:34:28'),
(19, 11, -1, '2026-02-05 22:34:28'),
(19, 12, -2, '2026-02-05 22:34:28'),
(19, 13, 2, '2026-02-05 22:34:28'),
(19, 14, -2, '2026-02-05 22:34:28'),
(19, 15, 2, '2026-02-05 22:34:28'),
(19, 16, -2, '2026-02-05 22:34:28'),
(19, 17, -2, '2026-02-05 22:34:28'),
(19, 18, 2, '2026-02-05 22:34:28'),
(19, 19, -2, '2026-02-05 22:34:28'),
(19, 20, -2, '2026-02-05 22:34:28'),
(20, 1, -2, '2026-02-05 22:40:12'),
(20, 2, 1, '2026-02-05 22:40:12'),
(20, 3, 2, '2026-02-05 22:40:12'),
(20, 4, -2, '2026-02-05 22:40:12'),
(20, 5, -2, '2026-02-05 22:40:12'),
(20, 6, -2, '2026-02-05 22:40:12'),
(20, 7, 1, '2026-02-05 22:40:12'),
(20, 8, 2, '2026-02-05 22:40:12'),
(20, 9, 2, '2026-02-05 22:40:12'),
(20, 10, -2, '2026-02-05 22:40:12'),
(20, 11, -2, '2026-02-05 22:40:12'),
(20, 12, -2, '2026-02-05 22:40:12'),
(20, 13, -1, '2026-02-05 22:40:12'),
(20, 14, -2, '2026-02-05 22:40:12'),
(20, 15, -2, '2026-02-05 22:40:12'),
(20, 16, 1, '2026-02-05 22:40:12'),
(20, 17, -2, '2026-02-05 22:40:12'),
(20, 18, -2, '2026-02-05 22:40:12'),
(20, 19, -1, '2026-02-05 22:40:12'),
(20, 20, 2, '2026-02-05 22:40:12'),
(22, 1, 2, '2026-02-05 22:42:05'),
(22, 2, -1, '2026-02-05 22:42:05'),
(22, 3, -2, '2026-02-05 22:42:05'),
(22, 4, 1, '2026-02-05 22:42:05'),
(22, 5, -1, '2026-02-05 22:42:05'),
(22, 6, 1, '2026-02-05 22:42:05'),
(22, 7, -1, '2026-02-05 22:42:05'),
(22, 8, -1, '2026-02-05 22:42:05'),
(22, 9, 2, '2026-02-05 22:42:05'),
(22, 10, 1, '2026-02-05 22:42:05'),
(22, 11, 1, '2026-02-05 22:42:05'),
(22, 12, -1, '2026-02-05 22:42:05'),
(22, 13, 1, '2026-02-05 22:42:05'),
(22, 14, 2, '2026-02-05 22:42:05'),
(22, 15, -1, '2026-02-05 22:42:05'),
(22, 16, 1, '2026-02-05 22:42:05'),
(22, 17, 1, '2026-02-05 22:42:05'),
(22, 18, 1, '2026-02-05 22:42:05'),
(22, 19, -1, '2026-02-05 22:42:05'),
(22, 20, 1, '2026-02-05 22:42:05'),
(23, 1, -1, '2026-02-05 23:14:20'),
(23, 2, 1, '2026-02-05 23:14:20'),
(23, 3, 2, '2026-02-05 23:14:20'),
(23, 4, 2, '2026-02-05 23:14:20'),
(23, 5, 1, '2026-02-05 23:14:20'),
(23, 6, -1, '2026-02-05 23:14:20'),
(23, 7, 2, '2026-02-05 23:14:20'),
(23, 8, 2, '2026-02-05 23:14:20'),
(23, 9, 1, '2026-02-05 23:14:20'),
(23, 10, -1, '2026-02-05 23:14:20'),
(23, 11, -1, '2026-02-05 23:14:20'),
(23, 12, 2, '2026-02-05 23:14:20'),
(23, 13, 0, '2026-02-05 23:14:20'),
(23, 14, 2, '2026-02-05 23:14:20'),
(23, 15, 2, '2026-02-05 23:14:20'),
(23, 16, -1, '2026-02-05 23:14:20'),
(23, 17, 2, '2026-02-05 23:14:20'),
(23, 18, 2, '2026-02-05 23:14:20'),
(23, 19, 2, '2026-02-05 23:14:20'),
(23, 20, 1, '2026-02-05 23:14:20'),
(25, 1, 2, '2026-02-05 23:17:56'),
(25, 2, 2, '2026-02-05 23:17:56'),
(25, 3, 2, '2026-02-05 23:17:56'),
(25, 4, 2, '2026-02-05 23:17:56'),
(25, 5, 2, '2026-02-05 23:17:56'),
(25, 6, 2, '2026-02-05 23:17:56'),
(25, 7, 2, '2026-02-05 23:17:56'),
(25, 8, 2, '2026-02-05 23:17:56'),
(25, 9, 1, '2026-02-05 23:17:56'),
(25, 10, 2, '2026-02-05 23:17:56'),
(25, 11, 2, '2026-02-05 23:17:56'),
(25, 12, 2, '2026-02-05 23:17:56'),
(25, 13, 2, '2026-02-05 23:17:56'),
(25, 14, 2, '2026-02-05 23:17:56'),
(25, 15, 2, '2026-02-05 23:17:56'),
(25, 16, 2, '2026-02-05 23:17:56'),
(25, 17, 2, '2026-02-05 23:17:56'),
(25, 18, 2, '2026-02-05 23:17:56'),
(25, 19, 2, '2026-02-05 23:17:56'),
(25, 20, 2, '2026-02-05 23:17:56'),
(26, 1, 2, '2026-02-05 23:18:51'),
(26, 2, 2, '2026-02-05 23:18:51'),
(26, 3, 2, '2026-02-05 23:18:51'),
(26, 4, 2, '2026-02-05 23:18:51'),
(26, 5, 2, '2026-02-05 23:18:51'),
(26, 6, 2, '2026-02-05 23:18:51'),
(26, 7, 1, '2026-02-05 23:18:51'),
(26, 8, -1, '2026-02-05 23:18:51'),
(26, 9, 2, '2026-02-05 23:18:51'),
(26, 10, 1, '2026-02-05 23:18:51'),
(26, 11, 2, '2026-02-05 23:18:51'),
(26, 12, 2, '2026-02-05 23:18:51'),
(26, 13, 2, '2026-02-05 23:18:51'),
(26, 14, 1, '2026-02-05 23:18:51'),
(26, 15, 2, '2026-02-05 23:18:51'),
(26, 16, 2, '2026-02-05 23:18:51'),
(26, 17, 2, '2026-02-05 23:18:51'),
(26, 18, 2, '2026-02-05 23:18:51'),
(26, 19, 2, '2026-02-05 23:18:51'),
(26, 20, 2, '2026-02-05 23:18:51'),
(30, 1, -2, '2026-02-05 23:44:05'),
(30, 2, 2, '2026-02-05 23:44:05'),
(30, 3, 2, '2026-02-05 23:44:05'),
(30, 4, 1, '2026-02-05 23:44:05'),
(30, 5, -1, '2026-02-05 23:44:05'),
(30, 6, 1, '2026-02-05 23:44:05'),
(30, 7, 0, '2026-02-05 23:44:05'),
(30, 8, -2, '2026-02-05 23:44:05'),
(30, 9, 1, '2026-02-05 23:44:05'),
(30, 10, 2, '2026-02-05 23:44:05'),
(30, 11, -1, '2026-02-05 23:44:05'),
(30, 12, -2, '2026-02-05 23:44:05'),
(30, 13, -2, '2026-02-05 23:44:05'),
(30, 14, 1, '2026-02-05 23:44:05'),
(30, 15, -2, '2026-02-05 23:44:05'),
(30, 16, -2, '2026-02-05 23:44:05'),
(30, 17, 2, '2026-02-05 23:44:05'),
(30, 18, 2, '2026-02-05 23:44:05'),
(30, 19, 1, '2026-02-05 23:44:05'),
(30, 20, 1, '2026-02-05 23:44:05'),
(31, 1, 2, '2026-02-05 23:50:47'),
(31, 2, 2, '2026-02-05 23:50:47'),
(31, 3, 2, '2026-02-05 23:50:47'),
(31, 4, 2, '2026-02-05 23:50:47'),
(31, 5, 2, '2026-02-05 23:50:47'),
(31, 6, 2, '2026-02-05 23:50:47'),
(31, 7, 2, '2026-02-05 23:50:47'),
(31, 8, 2, '2026-02-05 23:50:47'),
(31, 9, 2, '2026-02-05 23:50:47'),
(31, 10, 2, '2026-02-05 23:50:47'),
(31, 11, 2, '2026-02-05 23:50:47'),
(31, 12, 2, '2026-02-05 23:50:47'),
(31, 13, 2, '2026-02-05 23:50:47'),
(31, 14, 2, '2026-02-05 23:50:47'),
(31, 15, 2, '2026-02-05 23:50:47'),
(31, 16, 2, '2026-02-05 23:50:47'),
(31, 17, 2, '2026-02-05 23:50:47'),
(31, 18, 2, '2026-02-05 23:50:47'),
(31, 19, 2, '2026-02-05 23:50:47'),
(31, 20, 2, '2026-02-05 23:50:47'),
(32, 1, 2, '2026-02-05 23:51:50'),
(32, 2, 2, '2026-02-05 23:51:50'),
(32, 3, 2, '2026-02-05 23:51:50'),
(32, 4, 2, '2026-02-05 23:51:50'),
(32, 5, 2, '2026-02-05 23:51:50'),
(32, 6, 2, '2026-02-05 23:51:50'),
(32, 7, 2, '2026-02-05 23:51:50'),
(32, 8, 2, '2026-02-05 23:51:50'),
(32, 9, 2, '2026-02-05 23:51:50'),
(32, 10, 2, '2026-02-05 23:51:50'),
(32, 11, 2, '2026-02-05 23:51:50'),
(32, 12, 2, '2026-02-05 23:51:50'),
(32, 13, 2, '2026-02-05 23:51:50'),
(32, 14, 2, '2026-02-05 23:51:50'),
(32, 15, 2, '2026-02-05 23:51:50'),
(32, 16, 2, '2026-02-05 23:51:50'),
(32, 17, 2, '2026-02-05 23:51:50'),
(32, 18, 2, '2026-02-05 23:51:50'),
(32, 19, 2, '2026-02-05 23:51:50'),
(32, 20, 2, '2026-02-05 23:51:50'),
(34, 1, 2, '2026-02-06 00:02:14'),
(34, 2, 2, '2026-02-06 00:02:14'),
(34, 3, 2, '2026-02-06 00:02:14'),
(34, 4, 2, '2026-02-06 00:02:14'),
(34, 5, 2, '2026-02-06 00:02:14'),
(34, 7, 2, '2026-02-06 00:02:14'),
(34, 8, 2, '2026-02-06 00:02:14'),
(34, 9, 2, '2026-02-06 00:02:14'),
(34, 10, 2, '2026-02-06 00:02:14'),
(34, 11, 2, '2026-02-06 00:02:14'),
(34, 12, 2, '2026-02-06 00:02:14'),
(34, 13, 2, '2026-02-06 00:02:14'),
(34, 14, 1, '2026-02-06 00:02:14'),
(34, 15, 2, '2026-02-06 00:02:14'),
(34, 16, 2, '2026-02-06 00:02:14'),
(34, 17, 2, '2026-02-06 00:02:14'),
(34, 18, -1, '2026-02-06 00:02:14'),
(34, 19, 2, '2026-02-06 00:02:14'),
(34, 20, 2, '2026-02-06 00:02:14'),
(36, 1, 2, '2026-02-06 19:19:16'),
(36, 2, 2, '2026-02-06 19:19:16'),
(36, 3, 2, '2026-02-06 19:19:16'),
(36, 4, 2, '2026-02-06 19:19:16'),
(36, 5, 2, '2026-02-06 19:19:16'),
(36, 6, 2, '2026-02-06 19:19:16'),
(36, 7, 2, '2026-02-06 19:19:16'),
(36, 8, 2, '2026-02-06 19:19:16'),
(36, 9, 2, '2026-02-06 19:19:16'),
(36, 10, 2, '2026-02-06 19:19:16'),
(36, 11, 1, '2026-02-06 19:19:16'),
(36, 12, 2, '2026-02-06 19:19:16'),
(36, 13, 2, '2026-02-06 19:19:16'),
(36, 14, 2, '2026-02-06 19:19:16'),
(36, 15, 2, '2026-02-06 19:19:16'),
(36, 16, 1, '2026-02-06 19:19:16'),
(36, 17, 2, '2026-02-06 19:19:16'),
(36, 18, 2, '2026-02-06 19:19:16'),
(36, 19, 2, '2026-02-06 19:19:16'),
(37, 1, 2, '2026-02-06 19:31:37'),
(37, 2, 2, '2026-02-06 19:31:37'),
(37, 3, 2, '2026-02-06 19:31:37'),
(37, 4, 2, '2026-02-06 19:31:37'),
(37, 5, 2, '2026-02-06 19:31:37'),
(37, 6, 2, '2026-02-06 19:31:37'),
(37, 7, 2, '2026-02-06 19:31:37'),
(37, 8, 2, '2026-02-06 19:31:37'),
(37, 9, 2, '2026-02-06 19:31:37'),
(37, 10, 2, '2026-02-06 19:31:37'),
(37, 11, 2, '2026-02-06 19:31:37'),
(37, 12, 2, '2026-02-06 19:31:37'),
(37, 13, 2, '2026-02-06 19:31:37'),
(37, 14, 2, '2026-02-06 19:31:37'),
(37, 15, 1, '2026-02-06 19:31:37'),
(37, 16, 2, '2026-02-06 19:31:37'),
(37, 17, 2, '2026-02-06 19:31:37'),
(37, 18, 2, '2026-02-06 19:31:37'),
(37, 19, 2, '2026-02-06 19:31:37'),
(37, 20, 2, '2026-02-06 19:31:37'),
(38, 1, 1, '2026-02-06 19:57:44'),
(38, 2, 2, '2026-02-06 19:57:44'),
(38, 3, -1, '2026-02-06 19:57:44'),
(38, 4, 2, '2026-02-06 19:57:44'),
(38, 5, 2, '2026-02-06 19:57:44'),
(38, 6, 2, '2026-02-06 19:57:44'),
(38, 7, 2, '2026-02-06 19:57:44'),
(38, 8, 2, '2026-02-06 19:57:44'),
(38, 9, 1, '2026-02-06 19:57:44'),
(38, 10, 1, '2026-02-06 19:57:44'),
(38, 11, 1, '2026-02-06 19:57:44'),
(38, 12, 2, '2026-02-06 19:57:44'),
(38, 13, 2, '2026-02-06 19:57:44'),
(38, 14, 2, '2026-02-06 19:57:44'),
(38, 15, 1, '2026-02-06 19:57:44'),
(38, 16, 2, '2026-02-06 19:57:44'),
(38, 17, 1, '2026-02-06 19:57:44'),
(38, 18, 1, '2026-02-06 19:57:44'),
(38, 19, 1, '2026-02-06 19:57:44'),
(38, 20, 2, '2026-02-06 19:57:44'),
(39, 1, 2, '2026-02-06 20:01:47'),
(39, 2, -2, '2026-02-06 20:01:47'),
(39, 3, 2, '2026-02-06 20:01:47'),
(39, 4, 2, '2026-02-06 20:01:47'),
(39, 5, -1, '2026-02-06 20:01:47'),
(39, 6, 2, '2026-02-06 20:01:47'),
(39, 7, 2, '2026-02-06 20:01:47'),
(39, 8, -1, '2026-02-06 20:01:47'),
(39, 9, 2, '2026-02-06 20:01:47'),
(39, 10, 2, '2026-02-06 20:01:47'),
(39, 11, -2, '2026-02-06 20:01:47'),
(39, 12, 2, '2026-02-06 20:01:47'),
(39, 13, 2, '2026-02-06 20:01:47'),
(39, 14, -2, '2026-02-06 20:01:47'),
(39, 15, -2, '2026-02-06 20:01:47'),
(39, 16, 2, '2026-02-06 20:01:47'),
(39, 17, 2, '2026-02-06 20:01:47'),
(39, 18, -2, '2026-02-06 20:01:47'),
(39, 19, -2, '2026-02-06 20:01:47'),
(39, 20, 1, '2026-02-06 20:01:47'),
(40, 1, 2, '2026-02-06 20:05:27'),
(40, 2, 2, '2026-02-06 20:05:27'),
(40, 3, 2, '2026-02-06 20:05:27'),
(40, 4, 2, '2026-02-06 20:05:27'),
(40, 5, 2, '2026-02-06 20:05:27'),
(40, 6, 2, '2026-02-06 20:05:27'),
(40, 7, 2, '2026-02-06 20:05:27'),
(40, 8, 2, '2026-02-06 20:05:27'),
(40, 9, 2, '2026-02-06 20:05:27'),
(40, 10, 2, '2026-02-06 20:05:27'),
(40, 11, 2, '2026-02-06 20:05:27'),
(40, 12, 2, '2026-02-06 20:05:27'),
(40, 13, 2, '2026-02-06 20:05:27'),
(40, 14, 2, '2026-02-06 20:05:27'),
(40, 15, 2, '2026-02-06 20:05:27'),
(40, 16, 2, '2026-02-06 20:05:27'),
(40, 17, 2, '2026-02-06 20:05:27'),
(40, 18, 2, '2026-02-06 20:05:27'),
(40, 19, 2, '2026-02-06 20:05:27'),
(40, 20, 2, '2026-02-06 20:05:27'),
(41, 1, 2, '2026-02-06 20:06:33'),
(41, 2, 2, '2026-02-06 20:06:33'),
(41, 3, 2, '2026-02-06 20:06:33'),
(41, 4, 2, '2026-02-06 20:06:33'),
(41, 5, 2, '2026-02-06 20:06:33'),
(41, 6, 2, '2026-02-06 20:06:33'),
(41, 7, 2, '2026-02-06 20:06:33'),
(41, 8, 2, '2026-02-06 20:06:33'),
(41, 9, 2, '2026-02-06 20:06:33'),
(41, 10, 2, '2026-02-06 20:06:33'),
(41, 11, 2, '2026-02-06 20:06:33'),
(41, 12, 2, '2026-02-06 20:06:33'),
(41, 13, 2, '2026-02-06 20:06:33'),
(41, 14, 2, '2026-02-06 20:06:33'),
(41, 15, 2, '2026-02-06 20:06:33'),
(41, 16, 2, '2026-02-06 20:06:33'),
(41, 17, 2, '2026-02-06 20:06:33'),
(41, 18, 2, '2026-02-06 20:06:33'),
(41, 19, 2, '2026-02-06 20:06:33'),
(41, 20, 2, '2026-02-06 20:06:33'),
(43, 1, 1, '2026-02-06 23:40:08'),
(43, 2, 1, '2026-02-06 23:40:08'),
(43, 3, 1, '2026-02-06 23:40:08'),
(43, 4, 1, '2026-02-06 23:40:08'),
(43, 5, 1, '2026-02-06 23:40:08'),
(43, 6, 1, '2026-02-06 23:40:08'),
(43, 7, 2, '2026-02-06 23:40:08'),
(43, 8, 1, '2026-02-06 23:40:08'),
(43, 9, 1, '2026-02-06 23:40:08'),
(43, 10, 2, '2026-02-06 23:40:08'),
(43, 11, 1, '2026-02-06 23:40:08'),
(43, 12, 1, '2026-02-06 23:40:08'),
(43, 13, 1, '2026-02-06 23:40:08'),
(43, 14, 1, '2026-02-06 23:40:08'),
(43, 15, 1, '2026-02-06 23:40:08'),
(43, 16, 2, '2026-02-06 23:40:08'),
(43, 17, 1, '2026-02-06 23:40:08'),
(43, 18, 1, '2026-02-06 23:40:08'),
(43, 19, 1, '2026-02-06 23:40:08'),
(43, 20, 1, '2026-02-06 23:40:08'),
(44, 1, 2, '2026-02-07 00:16:16'),
(44, 2, 2, '2026-02-07 00:16:16'),
(44, 3, 2, '2026-02-07 00:16:16'),
(44, 4, 2, '2026-02-07 00:16:16'),
(44, 5, 2, '2026-02-07 00:16:16'),
(44, 6, 2, '2026-02-07 00:16:16'),
(44, 7, 2, '2026-02-07 00:16:16'),
(44, 8, 2, '2026-02-07 00:16:16'),
(44, 9, 2, '2026-02-07 00:16:16'),
(44, 10, 2, '2026-02-07 00:16:16'),
(44, 11, 2, '2026-02-07 00:16:16'),
(44, 12, 2, '2026-02-07 00:16:16'),
(44, 13, 2, '2026-02-07 00:16:16'),
(44, 14, 2, '2026-02-07 00:16:16'),
(44, 15, 2, '2026-02-07 00:16:16'),
(44, 16, 2, '2026-02-07 00:16:16'),
(44, 17, 2, '2026-02-07 00:16:16'),
(44, 18, 2, '2026-02-07 00:16:16'),
(44, 19, 2, '2026-02-07 00:16:16'),
(44, 20, 2, '2026-02-07 00:16:16'),
(45, 1, 2, '2026-02-07 00:22:37'),
(45, 2, 2, '2026-02-07 00:22:37'),
(45, 3, 2, '2026-02-07 00:22:37'),
(45, 4, 2, '2026-02-07 00:22:37'),
(45, 5, 2, '2026-02-07 00:22:37'),
(45, 6, 2, '2026-02-07 00:22:37'),
(45, 7, 2, '2026-02-07 00:22:37'),
(45, 8, 2, '2026-02-07 00:22:37'),
(45, 9, 2, '2026-02-07 00:22:37'),
(45, 10, 2, '2026-02-07 00:22:37'),
(45, 11, 2, '2026-02-07 00:22:37'),
(45, 12, 2, '2026-02-07 00:22:37'),
(45, 13, 2, '2026-02-07 00:22:37'),
(45, 14, 2, '2026-02-07 00:22:37'),
(45, 15, 2, '2026-02-07 00:22:37'),
(45, 16, 2, '2026-02-07 00:22:37'),
(45, 17, 2, '2026-02-07 00:22:37'),
(45, 18, 2, '2026-02-07 00:22:37'),
(45, 19, 2, '2026-02-07 00:22:37'),
(45, 20, 2, '2026-02-07 00:22:37'),
(46, 1, 2, '2026-02-07 18:40:17'),
(46, 2, 2, '2026-02-07 18:40:17'),
(46, 3, 2, '2026-02-07 18:40:17'),
(46, 4, 2, '2026-02-07 18:40:17'),
(46, 5, 2, '2026-02-07 18:40:17'),
(46, 6, 2, '2026-02-07 18:40:17'),
(46, 7, 2, '2026-02-07 18:40:17'),
(46, 8, 2, '2026-02-07 18:40:17'),
(46, 9, 2, '2026-02-07 18:40:17'),
(46, 10, 2, '2026-02-07 18:40:17'),
(46, 11, 2, '2026-02-07 18:40:17'),
(46, 12, 2, '2026-02-07 18:40:17'),
(46, 13, 2, '2026-02-07 18:40:17'),
(46, 14, 2, '2026-02-07 18:40:17'),
(46, 15, 2, '2026-02-07 18:40:17'),
(46, 16, 2, '2026-02-07 18:40:17'),
(46, 17, 2, '2026-02-07 18:40:17'),
(46, 18, 2, '2026-02-07 18:40:17'),
(46, 19, 2, '2026-02-07 18:40:17'),
(46, 20, 2, '2026-02-07 18:40:17');

--
-- Disparadores `usuariorespuesta`
--
DROP TRIGGER IF EXISTS `actualizar_posicion_usuario`;
DELIMITER $$
CREATE TRIGGER `actualizar_posicion_usuario` AFTER INSERT ON `usuariorespuesta` FOR EACH ROW BEGIN
    DECLARE total_resp, total_preg INT;
    SELECT COUNT(*) INTO total_resp FROM UsuarioRespuesta WHERE sesion_id = NEW.sesion_id;
    SELECT COUNT(*) INTO total_preg FROM Pregunta WHERE estado = 'activa';
    IF total_resp >= total_preg THEN CALL CalcularPosicionUsuario(NEW.sesion_id); END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuariosesion`
--

DROP TABLE IF EXISTS `usuariosesion`;
CREATE TABLE `usuariosesion` (
  `id` int(11) NOT NULL,
  `fecha` timestamp NOT NULL DEFAULT current_timestamp(),
  `resultado_x` decimal(5,2) DEFAULT NULL COMMENT '-100.00 a +100.00',
  `resultado_y` decimal(5,2) DEFAULT NULL COMMENT '-100.00 a +100.00',
  `completado` tinyint(1) DEFAULT 0,
  `token` varchar(12) DEFAULT NULL,
  `usuario_id` int(11) DEFAULT NULL COMMENT 'NULL si es anónimo'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuariosesion`
--

INSERT INTO `usuariosesion` (`id`, `fecha`, `resultado_x`, `resultado_y`, `completado`, `token`, `usuario_id`) VALUES
(1, '2026-01-21 20:08:05', -26.92, -61.90, 1, NULL, 2),
(2, '2026-01-25 20:11:33', -12.82, -38.10, 1, NULL, 2),
(3, '2026-01-25 20:37:51', -23.68, -47.62, 1, '3fac4d1496', NULL),
(4, '2026-01-25 21:33:03', -10.29, -7.14, 1, '63d9559e49', NULL),
(5, '2026-02-05 19:51:10', 5.56, -36.36, 1, '4a191a4be5', NULL),
(6, '2026-02-05 20:58:32', NULL, NULL, 0, NULL, NULL),
(8, '2026-02-05 21:28:41', NULL, NULL, 0, NULL, NULL),
(14, '2026-02-05 21:35:30', NULL, NULL, 0, NULL, NULL),
(15, '2026-02-05 21:35:33', NULL, NULL, 0, NULL, NULL),
(18, '2026-02-05 21:44:09', 33.33, -63.64, 1, '24d5a6aef4', 2),
(19, '2026-02-05 22:33:25', -22.22, 31.82, 1, '4a22043d53', NULL),
(20, '2026-02-05 22:39:11', -77.78, 4.55, 1, 'd2d0740eef', NULL),
(21, '2026-02-05 22:40:29', NULL, NULL, 0, NULL, NULL),
(22, '2026-02-05 22:40:50', 22.22, -18.18, 1, '1c8d7b4857', NULL),
(23, '2026-02-05 23:12:52', 11.11, -45.00, 1, 'd955062929', 37),
(24, '2026-02-05 23:16:21', NULL, NULL, 0, NULL, 37),
(25, '2026-02-05 23:17:28', 38.89, -63.64, 1, 'a56e1a6e00', 2),
(26, '2026-02-05 23:18:20', 33.33, -36.36, 1, '1d76716e31', 2),
(27, '2026-02-05 23:25:56', NULL, NULL, 0, NULL, 2),
(28, '2026-02-05 23:31:38', NULL, NULL, 0, NULL, 2),
(29, '2026-02-05 23:43:18', NULL, NULL, 0, NULL, 2),
(30, '2026-02-05 23:43:24', -55.56, -10.00, 1, '44f8845c27', 2),
(31, '2026-02-05 23:45:49', 33.33, -63.64, 1, '25904569cf', 2),
(32, '2026-02-05 23:51:28', 33.33, -63.64, 1, 'b9f7048cb2', 2),
(33, '2026-02-06 00:01:19', NULL, NULL, 0, NULL, 2),
(34, '2026-02-06 00:01:52', NULL, NULL, 0, NULL, 2),
(35, '2026-02-06 19:18:29', NULL, NULL, 0, NULL, NULL),
(36, '2026-02-06 19:18:54', 27.78, -55.00, 1, '8cfaf0bc10', NULL),
(37, '2026-02-06 19:31:12', 27.78, -63.64, 1, '2b009de961', 2),
(38, '2026-02-06 19:57:16', 38.89, -45.45, 1, '254ff26d58', 2),
(39, '2026-02-06 20:01:22', 33.33, 13.64, 1, '9c047a8b0b', 2),
(40, '2026-02-06 20:05:07', 33.33, -63.64, 1, 'c5c798cb74', 2),
(41, '2026-02-06 20:06:11', 33.33, -63.64, 1, 'f052e6a3f1', 2),
(42, '2026-02-06 20:10:54', NULL, NULL, 0, NULL, 2),
(43, '2026-02-06 23:39:42', 22.22, -40.91, 1, 'b36805a976', 37),
(44, '2026-02-07 00:12:53', 33.33, -63.64, 1, '179270c144', 37),
(45, '2026-02-07 00:22:07', 33.33, -63.64, 1, 'e17ffe389b', 37),
(46, '2026-02-07 18:39:55', 33.33, -63.64, 1, '7cb82fb61d', 37);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vistaestadisticasquiz`
-- (Véase abajo para la vista actual)
--
DROP VIEW IF EXISTS `vistaestadisticasquiz`;
CREATE TABLE `vistaestadisticasquiz` (
`fecha` date
,`total_sesiones` bigint(21)
,`completadas` decimal(22,0)
,`anonimas` decimal(22,0)
,`registradas` decimal(22,0)
,`promedio_x` decimal(9,6)
,`promedio_y` decimal(9,6)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vistapreguntasestadisticas`
-- (Véase abajo para la vista actual)
--
DROP VIEW IF EXISTS `vistapreguntasestadisticas`;
CREATE TABLE `vistapreguntasestadisticas` (
`id` int(11)
,`texto` text
,`eje` enum('X','Y')
,`direccion` tinyint(4)
,`categoria` varchar(50)
,`total_respuestas` bigint(21)
,`promedio_respuesta` decimal(7,4)
);

-- --------------------------------------------------------

--
-- Estructura Stand-in para la vista `vistausuariosactividad`
-- (Véase abajo para la vista actual)
--
DROP VIEW IF EXISTS `vistausuariosactividad`;
CREATE TABLE `vistausuariosactividad` (
`id` int(11)
,`email` varchar(255)
,`rol` enum('user','admin')
,`fecha_registro` timestamp
,`total_sesiones` bigint(21)
,`ultima_sesion` timestamp
,`sesiones_completadas` decimal(22,0)
);

-- --------------------------------------------------------

--
-- Estructura para la vista `vistaestadisticasquiz`
--
DROP TABLE IF EXISTS `vistaestadisticasquiz`;

DROP VIEW IF EXISTS `vistaestadisticasquiz`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vistaestadisticasquiz`  AS SELECT cast(`us`.`fecha` as date) AS `fecha`, count(0) AS `total_sesiones`, sum(case when `us`.`completado` = 1 then 1 else 0 end) AS `completadas`, sum(case when `us`.`usuario_id` is null then 1 else 0 end) AS `anonimas`, sum(case when `us`.`usuario_id` is not null then 1 else 0 end) AS `registradas`, avg(`us`.`resultado_x`) AS `promedio_x`, avg(`us`.`resultado_y`) AS `promedio_y` FROM `usuariosesion` AS `us` GROUP BY cast(`us`.`fecha` as date) ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vistapreguntasestadisticas`
--
DROP TABLE IF EXISTS `vistapreguntasestadisticas`;

DROP VIEW IF EXISTS `vistapreguntasestadisticas`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vistapreguntasestadisticas`  AS SELECT `p`.`id` AS `id`, `p`.`texto` AS `texto`, `p`.`eje` AS `eje`, `p`.`direccion` AS `direccion`, `p`.`categoria` AS `categoria`, count(`ur`.`valor`) AS `total_respuestas`, avg(`ur`.`valor`) AS `promedio_respuesta` FROM (`pregunta` `p` left join `usuariorespuesta` `ur` on(`p`.`id` = `ur`.`pregunta_id`)) GROUP BY `p`.`id` ;

-- --------------------------------------------------------

--
-- Estructura para la vista `vistausuariosactividad`
--
DROP TABLE IF EXISTS `vistausuariosactividad`;

DROP VIEW IF EXISTS `vistausuariosactividad`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vistausuariosactividad`  AS SELECT `u`.`id` AS `id`, `u`.`email` AS `email`, `u`.`rol` AS `rol`, `u`.`fecha_registro` AS `fecha_registro`, count(`us`.`id`) AS `total_sesiones`, max(`us`.`fecha`) AS `ultima_sesion`, sum(case when `us`.`completado` = 1 then 1 else 0 end) AS `sesiones_completadas` FROM (`usuario` `u` left join `usuariosesion` `us` on(`u`.`id` = `us`.`usuario_id`)) GROUP BY `u`.`id` ;

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `candidato`
--
ALTER TABLE `candidato`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_cargo` (`cargo`),
  ADD KEY `idx_partido_candidato` (`id_partido`);

--
-- Indices de la tabla `partido`
--
ALTER TABLE `partido`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `nombre` (`nombre`),
  ADD UNIQUE KEY `nombre_largo` (`nombre_largo`),
  ADD KEY `idx_nombre` (`nombre`);

--
-- Indices de la tabla `partidoposicioncache`
--
ALTER TABLE `partidoposicioncache`
  ADD PRIMARY KEY (`partido_id`),
  ADD KEY `idx_posicion_x` (`posicion_x`),
  ADD KEY `idx_posicion_y` (`posicion_y`);

--
-- Indices de la tabla `partidorespuesta`
--
ALTER TABLE `partidorespuesta`
  ADD PRIMARY KEY (`partido_id`,`pregunta_id`),
  ADD KEY `idx_pregunta` (`pregunta_id`);

--
-- Indices de la tabla `partido_metadata`
--
ALTER TABLE `partido_metadata`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_partido` (`partido_id`);

--
-- Indices de la tabla `pregunta`
--
ALTER TABLE `pregunta`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_eje` (`eje`),
  ADD KEY `idx_estado` (`estado`),
  ADD KEY `idx_categoria` (`categoria`);

--
-- Indices de la tabla `region`
--
ALTER TABLE `region`
  ADD PRIMARY KEY (`id`);

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `idx_email` (`email`),
  ADD KEY `idx_rol` (`rol`);

--
-- Indices de la tabla `usuariorespuesta`
--
ALTER TABLE `usuariorespuesta`
  ADD PRIMARY KEY (`sesion_id`,`pregunta_id`),
  ADD KEY `idx_sesion` (`sesion_id`),
  ADD KEY `idx_pregunta` (`pregunta_id`),
  ADD KEY `idx_fecha` (`fecha_respuesta`);

--
-- Indices de la tabla `usuariosesion`
--
ALTER TABLE `usuariosesion`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `token` (`token`),
  ADD KEY `idx_usuario` (`usuario_id`),
  ADD KEY `idx_fecha` (`fecha`),
  ADD KEY `idx_completado` (`completado`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `candidato`
--
ALTER TABLE `candidato`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=17;

--
-- AUTO_INCREMENT de la tabla `partido`
--
ALTER TABLE `partido`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=52;

--
-- AUTO_INCREMENT de la tabla `partido_metadata`
--
ALTER TABLE `partido_metadata`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=122;

--
-- AUTO_INCREMENT de la tabla `pregunta`
--
ALTER TABLE `pregunta`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=124;

--
-- AUTO_INCREMENT de la tabla `region`
--
ALTER TABLE `region`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=38;

--
-- AUTO_INCREMENT de la tabla `usuariosesion`
--
ALTER TABLE `usuariosesion`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=47;

--
-- Restricciones para tablas volcadas
--

--
-- Filtros para la tabla `candidato`
--
ALTER TABLE `candidato`
  ADD CONSTRAINT `fk_candidato_partido` FOREIGN KEY (`id_partido`) REFERENCES `partido` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `partidoposicioncache`
--
ALTER TABLE `partidoposicioncache`
  ADD CONSTRAINT `partidoposicioncache_ibfk_1` FOREIGN KEY (`partido_id`) REFERENCES `partido` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `partidorespuesta`
--
ALTER TABLE `partidorespuesta`
  ADD CONSTRAINT `partidorespuesta_ibfk_1` FOREIGN KEY (`partido_id`) REFERENCES `partido` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `partidorespuesta_ibfk_2` FOREIGN KEY (`pregunta_id`) REFERENCES `pregunta` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `partido_metadata`
--
ALTER TABLE `partido_metadata`
  ADD CONSTRAINT `partido_metadata_ibfk_1` FOREIGN KEY (`partido_id`) REFERENCES `partido` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `usuariorespuesta`
--
ALTER TABLE `usuariorespuesta`
  ADD CONSTRAINT `usuariorespuesta_ibfk_1` FOREIGN KEY (`sesion_id`) REFERENCES `usuariosesion` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `usuariorespuesta_ibfk_2` FOREIGN KEY (`pregunta_id`) REFERENCES `pregunta` (`id`) ON DELETE CASCADE;

--
-- Filtros para la tabla `usuariosesion`
--
ALTER TABLE `usuariosesion`
  ADD CONSTRAINT `usuariosesion_ibfk_1` FOREIGN KEY (`usuario_id`) REFERENCES `usuario` (`id`) ON DELETE SET NULL;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
