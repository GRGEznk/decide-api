-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 25-01-2026 a las 23:05:16
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
(6, 'ACCION POPULAR', 'Acción Popular', 'AP'),
(7, 'AHORA NACION', 'Ahora Nación', 'AN'),
(8, 'VENCEREMOS', 'Alianza Electorial Venceremos', 'AEV'),
(9, 'ALIANZA PARA EL PROGRESO', 'Alianza Para el Progreso', 'APP'),
(10, 'AVANZA PAIS', 'Avanza País - Partido de Integración Social', 'AV'),
(11, 'BATALLA PERU', 'Batalla Perú', 'BP'),
(12, 'FE EN EL PERU', 'Fe en el Perú', 'FE'),
(13, 'FREPAP', 'Frente Popular Agricola Fía del Perú', 'FREPAP'),
(14, 'FUERZA POPULAR', 'Fuerza Popular', 'FP'),
(15, 'FUERZA Y LIBERTAD', 'Fuerza y Libertad', 'FYL'),
(16, 'JUNTOS POR EL PERU', 'Juntos por el Perú', 'JP'),
(17, 'LIBERTAD POPULAR', 'Libertad Popular', 'LP'),
(18, 'NUEVO PERU', 'Nuevo Perú por el Buen Vivir', 'NP'),
(19, 'APRA', 'Partido Alianza Popular Revolucionaria Americana', 'APRA'),
(20, 'CIUDADANOS POR EL PERU', 'Partido Ciudadanos por el Perú', 'CPP'),
(21, 'OBRAS', 'Partido Cívico Obras', 'OBRAS'),
(22, 'PTE', 'Partido de los Trabajadores y Emprededores - PTE', 'PTE'),
(23, 'BUEN GOBIERNO', 'Partido del Buen Gobierno', 'BG'),
(24, 'UNIDO PERU', 'Partido Demócrata Unido Perú', 'UP'),
(25, 'PARTIDO VERDE', 'Partido Demócrata Verde', 'VERDE'),
(26, 'PERU FEDERAL', 'Partido Democrático Federal', 'PF'),
(27, 'SOMOS PERU', 'Partido Democrático Somos Perú', 'SP'),
(28, 'FRENTE ESPERANZA', 'Partido Frente de la Esperanza 2021', 'PFE'),
(29, 'PARTIDO MORADO', 'Partido Morado', 'M'),
(30, 'PAIS PARA TODOS', 'Partido País Para Todos', 'PPT'),
(31, 'PARTIDO PATRIOTICO', 'Partido Patriótico del Perú ', 'PPP'),
(32, 'COOPERACION POPULAR', 'Partido Político Cooperanción Popular', 'CP'),
(33, 'FUERZA MODERNA', 'Partido Político Fuerza Moderna', 'FM'),
(34, 'INTEGRIDAD DEMOCRATICA', 'Partido Político Integridad Democrática', 'ID'),
(35, 'PERU LIBRE', 'Partido Político Nacional Perú Libre', 'PL'),
(36, 'PERU ACCION', 'Partido Político Perú Acción', 'PA'),
(37, 'PERU PRIMERO', 'Partido Político Perú Primero', 'PP'),
(38, '¡SOMOS LIBRES!', 'Partido Político Peruanos Unidos: ¡Somos Libres!', 'SL'),
(39, 'VOCES DEL PUEBLO', 'Partido Político Voces del Pueblo', 'VP'),
(40, 'PRIN', 'Partido Regionalista de Integración Nacional', 'PRIN'),
(41, 'PPC', 'Partido Popular Cristiano - PPC', 'PPC'),
(42, 'SICREO', 'Partido SíCreo', 'SI'),
(43, 'UNIDAD Y PAZ', 'Partido Unidad y Paz', 'UP'),
(44, 'PERU MODERNO', 'Perú Moderno', 'PM'),
(45, 'PODEMOS PERU', 'Podemos Perú', 'PP'),
(46, 'PRIMERO LA GENTE', 'Primero la Gente - Comunidad, Ecología, Libertad y Progreso', 'PLG'),
(47, 'PROGRESEMOS', 'Progresemos', 'PROG'),
(48, 'RENOVACION POPULAR', 'Renovación Popular', 'RP'),
(49, 'SALVEMOS AL PERU', 'Salvemos al Perú', 'SPP'),
(50, 'UN CAMINO DIFERENTE', 'Un Camino Diferente', 'UD'),
(51, 'UNIDAD NACIONAL', 'Unidad Nacional', 'UN');

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
) ;

--
-- Volcado de datos para la tabla `partidoposicioncache`
--

INSERT INTO `partidoposicioncache` (`partido_id`, `posicion_x`, `posicion_y`, `fecha_calculo`) VALUES
(6, 2.70, -19.05, '2026-01-18 22:04:06'),
(7, -30.00, -52.78, '2026-01-18 23:35:33'),
(8, 0.00, 0.00, '2026-01-18 18:51:46'),
(9, 0.00, 0.00, '2026-01-18 18:51:46'),
(10, 0.00, 0.00, '2026-01-18 18:51:46'),
(11, 0.00, 0.00, '2026-01-18 18:51:46'),
(12, 0.00, 0.00, '2026-01-18 18:51:46'),
(13, 0.00, 0.00, '2026-01-18 18:51:46'),
(14, 0.00, 0.00, '2026-01-18 18:51:46'),
(15, 0.00, 0.00, '2026-01-18 18:51:46'),
(16, 0.00, 0.00, '2026-01-18 18:51:46'),
(17, 0.00, 0.00, '2026-01-18 18:51:46'),
(18, 0.00, 0.00, '2026-01-18 18:51:46'),
(19, 0.00, 0.00, '2026-01-18 18:51:46'),
(20, 0.00, 0.00, '2026-01-18 18:51:46'),
(21, 0.00, 0.00, '2026-01-18 18:51:46'),
(22, 0.00, 0.00, '2026-01-18 18:51:46'),
(23, 0.00, 0.00, '2026-01-18 18:51:46'),
(24, 0.00, 0.00, '2026-01-18 18:51:46'),
(25, 0.00, 0.00, '2026-01-18 18:51:46'),
(26, 0.00, 0.00, '2026-01-18 18:51:46'),
(27, 0.00, 0.00, '2026-01-18 18:51:46'),
(28, 0.00, 0.00, '2026-01-18 18:51:46'),
(29, 0.00, 0.00, '2026-01-18 18:51:46'),
(30, 0.00, 0.00, '2026-01-18 18:51:46'),
(31, 0.00, 0.00, '2026-01-18 18:51:46'),
(32, 0.00, 0.00, '2026-01-18 18:51:46'),
(33, 0.00, 0.00, '2026-01-18 18:51:46'),
(34, 0.00, 0.00, '2026-01-18 18:51:46'),
(35, 0.00, 0.00, '2026-01-18 18:51:46'),
(36, 0.00, 0.00, '2026-01-18 18:51:46'),
(37, 0.00, 0.00, '2026-01-18 18:51:46'),
(38, 0.00, 0.00, '2026-01-18 18:51:46'),
(39, 0.00, 0.00, '2026-01-18 18:51:46'),
(40, 0.00, 0.00, '2026-01-18 18:51:46'),
(41, 0.00, 0.00, '2026-01-18 18:51:46'),
(42, 0.00, 0.00, '2026-01-18 18:51:46'),
(43, 0.00, 0.00, '2026-01-18 18:51:46'),
(44, 0.00, 0.00, '2026-01-18 18:51:46'),
(45, 0.00, 0.00, '2026-01-18 18:51:46'),
(46, 0.00, 0.00, '2026-01-18 18:51:46'),
(47, 0.00, 0.00, '2026-01-18 18:51:46'),
(48, 0.00, 0.00, '2026-01-18 18:51:46'),
(49, 0.00, 0.00, '2026-01-18 18:51:46'),
(50, 0.00, 0.00, '2026-01-18 18:51:46'),
(51, 0.00, 0.00, '2026-01-18 18:51:46');

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
) ;

--
-- Volcado de datos para la tabla `partidorespuesta`
--

INSERT INTO `partidorespuesta` (`partido_id`, `pregunta_id`, `valor`, `fuente`) VALUES
(6, 22, -1, 'AP suscribe la economía social de mercado (Constitución de 1993, que suscribió). La libertad de mercado es un pilar, pero debe estar complementada por justicia social, no subordinada'),
(6, 23, 1, 'Coherente con su tradición democrática, liberal en lo político y su defensa de las libertades individuales frente al estatismo'),
(6, 26, 1, 'Apoyaría políticas de inclusión y no discriminación, pero su discurso no se centra en el \"activismo estatal\" intensivo. Priorizaría la igualdad de oportunidades'),
(6, 27, 2, 'Es un pilar doctrinario clave (\"La Moral como Principio de la Acción\"). El \"honor\" y la ética pública son centrales en su identidad, aunque en la práctica no descartan la eficiencia'),
(6, 30, -1, 'Favorece la mejora y coordinación de los sistemas existentes, pero no una estatización total. Respaldaría una red integrada de información, no la desaparición de los subsistemas'),
(6, 31, 0, 'Posición pragmática. Podría apoyar APP específicas para gestión, pero con cautela. No es una posición ideológica firme; dependería del diseño'),
(6, 32, -1, 'Su ala más conservadora y católica influye. Preferiría un enfoque en \"valores\" y \"familia\", siendo escépticos del término \"enfoque de género\". Podrían apoyar ESI para prevenir embarazos, pero con reservas'),
(6, 33, 1, 'Coherente con modernización, transparencia y empoderamiento ciudadano. Fomentaría la interoperabilidad'),
(6, 36, 1, 'Alineado con su bandera histórica de la regionalización y descentralización. Fernando Belaunde Terry enfatizaba la adaptación a la realidad local'),
(6, 37, 1, 'Defiende la meritocracia en la función pública. Apoyaría evaluaciones, pero con debate interno sobre el \"retiro\" por el costo político'),
(6, 39, 1, 'Pragmático y alineado con necesidades productivas. Belaunde promovió la educación técnica (escuelas taller)'),
(6, 42, 1, 'En su doctrina de \"Peruanidad\" y respeto a las culturas originarias, apoyaría su inclusión en el currículo regionalizado'),
(6, 43, 1, 'Bandera histórica de Belaunde (\"El Perú como Doctrina\", el \"Techo Propio\"). Promovió los \"Pueblos Jóvenes\" y la autoconstrucción asistida'),
(6, 45, 2, 'Es un principio básico. AP buscaría un equilibrio, pero priorizaría el agua para consumo humano'),
(6, 47, 1, 'Compatible con su visión de usar recursos para desarrollo local y vivienda. Apoyaría destinos específicos para el canon, pero con flexibilidad'),
(6, 48, 2, ' Esencia de su doctrina. Belaunde impulsó la titulación. La modernización digital es una evolución natural'),
(6, 49, 1, 'Apunta a protección social extendida, dentro de un enfoque de economía social. Podría verlo como un paso a la formalización'),
(6, 50, -1, 'Lo verían como muy costoso y posiblemente distorsionador. Preferirían fortalecer el sistema de pensiones existente con incentivos al ahorro'),
(6, 52, 1, 'Coincide con el fomento de la pequeña empresa y el desarrollo local/regional'),
(6, 54, 1, 'Su enfoque es más de fomento que de coerción. Apoyarían simplificación tributaria e incentivos'),
(6, 56, -1, 'Podrían aceptar AP para servicios turísticos (cafeterías, limpieza), jamás para la gestión patrimonial del núcleo arqueológico. Defensa de la soberanía sobre el patrimonio'),
(6, 57, 1, 'Promoción de la \"marca Perú\" y la cultura como activo. Alineado con un nacionalismo práctico'),
(6, 58, 2, 'Perfectamente alineado con identidad nacional, protección al pequeño agricultor y promoción de productos bandera'),
(6, 59, 1, 'Coherente con respeto a la diversidad cultural y la descentralización. Apoyaría su uso oficial en zonas donde predominan'),
(6, 60, -1, 'Defiende la separación estricta de roles constitucionales. Apoyaría estados de excepción temporales en crisis, no la militarización permanente de la seguridad pública'),
(6, 62, 1, 'Críticos de la fiscalización excesiva y las demoras. Reclamarían eficiencia y un rol más fuerte para la Policía, aunque no necesariamente \"exclusivo\"'),
(6, 63, 1, 'En su línea de \"moralización\", podría apoyarlo como herramienta de control de confianza, aunque con dudas sobre su validez jurídica absoluta'),
(6, 65, 1, 'Posición firme en seguridad y soberanía. Apoyaría deportación expedita para delitos graves, con posible debate sobre \"cualquier delito\" (ej. faltas menores)'),
(6, 66, 1, 'Partido institucionalista y pro-democracia. Aunque puedan disentir en casos puntuales, defienden el sistema internacional y el Estado de Derecho'),
(6, 67, 2, 'Críticos históricos del CNM y la politización de la justicia. Buscarían una carrera judicial basada en méritos y estabilidad, no en ratificaciones políticas'),
(6, 69, -2, 'Defensores de la institucionalidad humana y el debido proceso. Lo verían como una amenaza al trabajo jurisdiccional y a las garantías'),
(6, 70, -1, 'Apoyarían medidas alternativas para delitos no graves, pero serían firmes en mantener encarcelados a reos peligrosos. Priorizarían construir más penales'),
(6, 71, 1, 'Claramente pro-OCDE (durante el gobierno de Sagasti se postuló). Ven la integración latinoamericana como complementaria, no prioritaria'),
(6, 73, -1, 'Tradición de política exterior de diversificación pero con claro anclaje occidental. Priorizan relaciones con EE.UU., UE, Asia-Pacífico (APEC). BRICS no es una prioridad'),
(6, 74, 1, 'Defienden la dignificación de las FF.AA. y el servicio. Apoyarían mejoras salariales y condiciones, aunque el costo sería un factor a considerar'),
(6, 75, 1, 'Histórico y doctrinario. Belaunde usó la ingeniería militar (ej. sinchis, aviación) para obras de integración en la selva. Lo ven como eficiente y patriótico'),
(6, 76, 1, 'Coherente con su discurso de racionalización del Estado, eficiencia y austeridad. Lo han propuesto en varios planes de gobierno'),
(6, 77, 1, 'Partidarios de la disciplina fiscal. Apoyarían mecanismos para evitar el populismo legislativo que desordena el presupuesto'),
(6, 79, 1, 'Visión de largo plazo y manejo prudente de recursos. Compatible con una economía social de mercado responsable'),
(6, 80, 1, 'Para fomentar la inversión, el emprendimiento y la formalización. Medida típica de incentivo económico que apoyarían'),
(6, 82, 0, 'Visión desarrollista e industrial. Podrían apoyar el liderazgo estatal en un proyecto estratégico'),
(6, 83, 1, 'Partido ferroviario por excelencia (Belaunde: Tren Marginal de la Selva, proyecto del Tren Eléctrico). Ven al tren como integrador y moderno'),
(6, 84, 1, 'Coherente con su visión de planificación urbana y obra pública para el bien común. Fomentarían el transporte público sostenible'),
(6, 86, 1, 'Para impulsar el desarrollo de regiones deprimidas. Alineado con descentralización y atracción de inversión'),
(6, 87, -1, 'Preferirían que el canon se invierta en obra pública dura (infraestructura) que genere desarrollo sostenible, antes que transferencias directas que pueden ser clientelares'),
(6, 89, 1, 'Defensores de la inversión privada y críticos del gasto estatal ineficiente. Buscarían una reestructuración con capital privado, pero no necesariamente desaparecerla por su simbolismo nacional'),
(6, 91, 1, 'Prioridad al agua y al ambiente. Apoyarían una delimitación técnica estricta y protección, incluso si limita a la minería'),
(6, 92, 1, 'Para aprovechar el recurso nacional, mejorar la economía y reducir contaminación. Pragmático y de interés nacional'),
(6, 95, 1, 'Alineado con conservación, justicia social para comunidades y mecanismos de mercado por servicios ambientales'),
(6, 96, 1, 'Desde una visión de responsabilidad ambiental y de mercado, apoyarían mecanismos que internalicen el costo de la contaminación'),
(6, 97, 2, 'Doctrina clave. Belaunde creía en la propiedad como herramienta de desarrollo y conservación. Es la base de su visión para la selva'),
(6, 99, 1, 'Objetivo razonable y moderno. Apoyarían la diversificación de la matriz energética con renovables'),
(6, 100, 2, 'Para transparentar, mejorar servicios y empoderar ciudadanos. Totalmente alineado con modernización y rendición de cuentas'),
(6, 101, 1, ' En su línea de moral y transparencia, apoyarían, aunque con posibles salvedades para seguridad nacional o negociaciones delicadas'),
(6, 103, 2, 'Herramienta poderosa para combatir la corrupción y hacer eficiente el gasto. Lo adoptarían con entusiasmo'),
(6, 105, 2, 'Críticos de la tramitología. Promoverían una gestión por resultados, como parte de la modernización del Estado'),
(6, 107, 1, 'Enfoque de \"mano tendida, no regalada\". Fomentan el trabajo y la superación personal, evitando el asistencialismo permanente'),
(6, 118, -1, 'Lo verían como financieramente insostenible y desincentivador del trabajo. Preferirían programas focalizados y temporales, o subsidios al empleo'),
(6, 119, -2, 'Su ala conservadora y valores tradicionales/católicos predominan. Apoyarían la unión civil (como muchos de sus miembros han dicho), no el matrimonio igualitario'),
(6, 120, -2, 'Defensores de la propiedad privada y el ahorro individual. Buscarían reformas al sistema mixto (AFP/ONP) para mejorarlo, no una estatización total'),
(7, 22, 1, 'Prioriza justicia social y equidad, compatibilizándola con economía de mercado regulada para bien común'),
(7, 23, 0, 'Cree en derechos individuales, pero no de forma absoluta; el Estado debe garantizar derechos colectivos'),
(7, 26, 2, 'Compromiso explícito con justicia social, equidad e interculturalidad'),
(7, 27, 1, 'Integridad y lucha contra corrupción son ejes centrales; desarrollo necesita bases éticas'),
(7, 30, 2, 'Propone sistema de salud universal como meta'),
(7, 31, -1, 'Aunque busca mejora en gestión, fortalecer lo público es prioridad'),
(7, 32, 1, 'Como partido comprometido con juventud y prevención, apoyaría ESI, aunque buscaría consenso social'),
(7, 33, 1, 'Alineado con modernización del Estado y derecho a la información del paciente.'),
(7, 36, 2, 'Concuerda con visión de Estado descentralizado y respeto a la diversidad cultural'),
(7, 37, 0, 'Prioriza mejoras de infraestructura, condiciones laborales y salariales del docente'),
(7, 39, 1, 'Apoyaría becas que impulsen desarrollo productivo e industrialización estratégica'),
(7, 42, 2, 'Comprometido con pluriculturalidad e identidad nacional; educación debe integrar saberes ancestrales'),
(7, 43, -1, 'Apoyaría vivienda social, pero meta de 125 millones parece inviable para Perú; priorizaría enfoque realista.'),
(7, 45, 1, 'Compatibiliza explotación de recursos con tecnologías limpias'),
(7, 47, -1, 'Apoyaría uso del canon para desarrollo local, pero no lo destinaría exclusivamente a un solo fin.'),
(7, 48, 1, 'Modernización del Estado y seguridad jurídica son importantes para el desarrollo.'),
(7, 49, 2, 'Comprometido con protección social y reducción de brechas; apoyaría mecanismos para informales.'),
(7, 50, 0, 'Priorizaría fortalecer sistema público de pensiones antes que esquemas de capital individual.'),
(7, 52, 2, 'Alineado con fomento del emprendimiento y desarrollo económico local'),
(7, 54, 1, 'Promueve un Estado facilitador, aunque sin descuidar lucha contra evasión'),
(7, 56, -1, 'Defiende soberanía y patrimonio nacional; gestión privada total iría contra identidad'),
(7, 57, 1, 'Concuerda con fortalecer identidad nacional y promoción económica de la cultura'),
(7, 58, 2, 'Perfectamente alineado con identidad nacional, protección de diversidad y apoyo a pequeños productores'),
(7, 59, 2, 'Parte esencial de su compromiso con interculturalidad y reconocimiento de la diversidad'),
(7, 60, -1, 'Fortalecería a la Policía con profesionalización y equipos, sin militarizar la seguridad'),
(7, 62, 0, 'Priorizaría fortalecimiento institucional y coordinación, no reversión de facultades'),
(7, 63, 0, 'Apoyaría medidas contra corrupción, pero el polígrafo obligatorio podría ser polémico en su implementación.'),
(7, 65, -1, 'Respetaría debido proceso; expulsión inmediata sin juicio viola derechos humanos y estado de derecho.'),
(7, 66, 2, 'Defiende institucionalidad internacional y permanencia en la Convención Americana'),
(7, 67, 1, 'Buscaría fortalecer independencia judicial; evaluación periódica sin politización es clave.'),
(7, 69, -2, 'La justicia es un acto humano complejo; la IA podría ser apoyo, no reemplazo.'),
(7, 70, 0, 'Propone modernizar sistema penitenciario; alternativas son parte de la discusión, pero no única solución.'),
(7, 71, 1, 'Sin declaración explícita; buscaría relaciones pragmáticas sin descuidar integración regional.'),
(7, 73, -1, 'Buscaría relaciones diversas y equilibradas, sin alineaciones automáticas.'),
(7, 74, 1, 'Concuerda con dignificación de las instituciones; mejoraría condiciones si se mantiene el servicio.'),
(7, 75, -1, 'Priorizaría obras con planificación civil y sostenible; rol militar no sería primera opción.'),
(7, 76, -1, 'Propone mejorar gestión, no reducción drástica; reestructuración sería más técnica que numérica'),
(7, 77, -1, 'Atentaría contra principio democrático de división de poderes; propondría regulación, no prohibición.'),
(7, 79, 1, 'Alineado con visión de industrialización estratégica y uso responsable de recursos para futuro'),
(7, 80, -1, 'Apoyaría incentivos para emprendimiento, pero no está en su programa actual'),
(7, 82, 2, 'Directamente alineado con propuesta de \"industrialización estratégica del Perú\"'),
(7, 83, 1, 'Apoyaría infraestructura de transporte masivo sostenible como parte de su visión de desarrollo.'),
(7, 84, 2, 'Compatible con enfoque de desarrollo sostenible y protección ambiental'),
(7, 86, -1, 'Podría apoyar ZEE para desarrollo regional, pero exoneración total iría contra recaudación justa.'),
(7, 87, -1, 'Preferiría inversión en bienes públicos y proyectos de desarrollo comunitario sostenible.'),
(7, 89, -1, 'Defiende rol estratégico del Estado en sectores clave; buscaría reestructuración con control público.'),
(7, 91, 1, 'Prioriza protección ambiental y recursos hídricos; compatible con uso de tecnologías limpias'),
(7, 92, 0, 'Priorizaría transición a energías renovables; gas sería puente, no obligación permanente.'),
(7, 95, 2, 'Perfectamente alineado con desarrollo sostenible, protección ambiental y justicia con comunidades'),
(7, 96, 1, 'Instrumento para incentivar prácticas sostenibles, en línea con protección ambiental'),
(7, 97, 1, 'Fortalecer derechos territoriales de comunidades es clave para conservación y justicia social.'),
(7, 99, 1, 'Meta concreta y alineada con compromiso de desarrollo sostenible y tecnologías limpias'),
(7, 100, 1, 'Herramienta para transparencia y mejora de servicios públicos, en línea con modernización del Estado.'),
(7, 101, 2, 'Compromiso explícito con transparencia y lucha contra la corrupción'),
(7, 103, 1, 'Apoyaría uso de tecnología para transparentar gestión y combatir corrupción'),
(7, 105, 2, 'Parte esencial de mejorar la gestión pública y la eficiencia del Estado.'),
(7, 107, 1, 'Buscaría equilibrio: apoyo inmediato con estímulo a autonomía; focalización sin castigo.'),
(7, 118, 1, 'Alineado con visión de justicia social y protección; sería parte de red de seguridad social fortalecida.'),
(7, 119, 1, 'Como partido laico con valores progresistas, probablemente lo apoyaría tras debate social, pero no es prioridad declarada.'),
(7, 120, 1, 'Coherente con visión de sistema de salud universal y rol fuerte del Estado en protección social');

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
(1, 6, 'Sin Candidato', 'Sin Lider', '#DB241E', 'ACCION POPULAR', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(2, 7, 'Alfonso Lopez Chau', 'Alfonso Lopez Chau', '#eb0206', 'AHORA NACION', 'A_LCHAU', NULL, NULL, 'Partido Político'),
(3, 8, 'Ronald Atencio', 'Guillermo Bermejo', '#00a324', 'VENCEREMOS', 'R_ATENCIO', NULL, NULL, 'Alianza Electoral'),
(4, 9, 'César Acuña', 'César Acuña', '#1e5ba8', 'ALIANZA PARA EL PROGRESO', 'C_ACUNA', NULL, NULL, 'Partido Político'),
(5, 10, 'José Williams', 'Pedro Cenas Casamayor', '#233d87', 'AVANZA PAIS', 'J_WILLIAMS', NULL, NULL, 'Partido Político'),
(6, 11, 'Zósimo Cárdenas ', 'Zósimo Cárdenas ', '#0c00ff', 'BATALLA PERU', 'Z_CARDENAS', NULL, NULL, 'Partido Político'),
(7, 12, 'Álvaro Paz de la Barra', 'Álvaro Paz de la Barra', '#42c553', 'FE EN EL PERU', 'A_DELABARRA', NULL, NULL, 'Partido Político'),
(8, 13, 'Sin Candidato', 'Ezequiel Jonás Ataucusi Molina', '#0000FF', 'FREPAP', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(9, 14, 'Keiko Fujimori', 'Keiko Fujimori', '#eb6d00', 'FUERZA POPULAR', 'K_FUJIMORI', NULL, NULL, 'Partido Político'),
(10, 15, 'Fiorella Molinelli', 'Fiorella Molinelli', '#0b00fb', 'FUERZA Y LIBERTAD', 'F_MOLLINELI', NULL, NULL, 'Alianza Electoral'),
(11, 16, 'Roberto Sánchez Palomino', 'Roberto Sánchez Palomino', '#5cbe12', 'JUNTOS POR EL PERU', 'R_SANCHEZ', NULL, NULL, 'Partido Político'),
(12, 17, 'Rafael Belaúnde Llosa', 'Rafael Belaúnde Llosa', '#ffff01', 'LIBERTAD POPULAR', 'R_BELAUNDE', NULL, NULL, 'Partido Político'),
(13, 18, 'Vicente Alanoca', 'Verónika Mendoza', '#e11821', 'NUEVO PERU', 'V_ALANOCA', NULL, NULL, 'Partido Político'),
(14, 19, 'Enrique Valderrama', 'Enrique Valderrama', '#ff0103', 'APRA', 'E_VALDERRAMA', NULL, NULL, 'Partido Político'),
(15, 20, 'Sin Candidato', 'Alberto Moreno', '#00b0e1', 'CIUDADANOS POR EL PERU', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(16, 21, 'Ricardo Belmont Cassinelli', 'Ricardo Belmont Cassinelli', '#0b7f3b', 'OBRAS', 'R_BELMONT', NULL, NULL, 'Partido Político'),
(17, 22, 'Napoleón Becerra García', 'Napoleón Becerra García', '#345091', 'PTE', 'N_BECERRA', NULL, NULL, 'Partido Político'),
(18, 23, 'Jorge Nieto Montesinos', 'Jorge Nieto Montesinos', '#db2826', 'BUEN GOBIERNO', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(19, 24, 'Charlie Carrasco Salazar', 'Charlie Carrasco Salazar', '#00a640', 'UNIDO PERU', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(20, 25, 'Álex Gonzales Castillo', 'Álex Gonzales Castillo', '#02a051', 'PARTIDO VERDE', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(21, 26, 'Virgilio Acuña Peralta', 'Virgilio Acuña Peralta', '#02943f', 'PERU FEDERAL', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(22, 27, 'George Forsyth', 'Patrica Li Sotelo', '#FF0080', 'SOMOS PERU', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(23, 28, 'Fernando Olivera', 'Fernando Olivera', '#67bd50', 'FRENTE ESPERANZA', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(24, 29, 'Mesías Guevara', 'Luis Durán Rojo', '#4f1b7f', 'PARTIDO MORADO', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(25, 30, 'Carlos Álvarez', 'Vladimir Meza Villarreal', '#ffcb00', 'PAIS PARA TODOS', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(26, 31, 'Herbert Caller Gutierrez', 'Herbert Caller Gutierrez', '#000000', 'PARTIDO PATRIOTICO', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(27, 32, 'Yonhy Lescano', 'Carlos Zeballos', '#0267af', 'COOPERACION POPULAR', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(28, 33, 'Fiorella Molinelli', 'Fiorella Molinelli', '#1f3765', 'FUERZA MODERNA', 'F_MOLLINELI', NULL, NULL, 'Partido Político'),
(29, 34, 'Wolfgang Grozo', 'Wolfgang Grozo', '#4e86aa', 'INTEGRIDAD DEMOCRATICA', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(30, 35, 'Vladimir Cerrón', 'Vladimir Cerrón', '#e90000', 'PERU LIBRE', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(31, 36, 'Francisco Diez Canseco', 'Francisco Diez Canseco', '#010799', 'PERU ACCION', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(32, 37, 'Mario Vizcarra', 'Martín Vizcarra', '#d1151b', 'PERU PRIMERO', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(33, 38, 'Roberto Chiabra', 'Tomás Gálvez', '#0001f1', '¡SOMOS LIBRES!', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(34, 39, 'Ronald Atencio', 'Guillermo Bermejo', '#d90736', 'VOCES DEL PUEBLO', 'R_ATENCIO', NULL, NULL, 'Partido Político'),
(35, 40, 'Walter Chirinos Purizaga', 'Walter Chirinos Purizaga', '#df0209', 'PRIN', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(36, 41, 'Roberto Chiabra', 'Javier Bedoya Denegri', '#00934a', 'PPC', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(37, 42, 'Carlos Espá', 'Carlos Espá', '#e20614', 'SICREO', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(38, 43, 'Roberto Chiabra', 'Roberto Chiabra', '#ee3137', 'UNIDAD Y PAZ', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(39, 44, 'Carlos Jaico Carranza', 'Wilson Aragón Ponce', '#de0079', 'PERU MODERNO', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(40, 45, 'José Luna Gálvez', 'José Luna Gálvez', '#0a4e9d', 'PODEMOS PERU', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(41, 46, 'Marisol Pérez Tello', 'Manuel Ato Carrera', '#2252a7', 'PRIMERO LA GENTE', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(42, 47, 'Paul Jaimes Blanco', 'Paul Jaimes Blanco', '#28b227', 'PROGRESEMOS', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(43, 48, 'Rafael López Aliaga', 'Rafael López Aliaga', '#049ad7', 'RENOVACION POPULAR', 'R_LOPEZ', NULL, NULL, 'Partido Político'),
(44, 49, 'Antonio Ortiz Villano', 'Guillermo Antenor Suárez Flores', '#fd0100', 'SALVEMOS AL PERU', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(45, 50, 'Arturo Fernández Bazán', 'César Arturo Fernández Bazán', '#d0161f', 'UN CAMINO DIFERENTE', 'DEFAULT_CANDIDATE', NULL, NULL, 'Partido Político'),
(46, 51, 'Roberto Chiabra', 'Roberto Chiabra', '#ff2e34', 'UNIDAD NACIONAL', 'DEFAULT_CANDIDATE', NULL, NULL, 'Alianza Electoral');

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
(22, 'La justicia social y la equidad de oportunidades deben estar por encima de la libertad de mercado.', 'X', -1, 'activa', 'Principios y Visión'),
(23, 'La libertad individual de cada persona es anterior y superior a los fines del Estado.', 'X', 1, 'activa', 'Principios y Visión'),
(24, 'El Perú es una \"Nación en formación\" que requiere un Estado fuerte para consolidar su identidad.', 'X', -1, 'inactiva', 'Principios y Visión'),
(25, 'La propiedad privada es el cimiento irrenunciable de la prosperidad económica.', 'X', 1, 'inactiva', 'Principios y Visión'),
(26, 'El Estado debe intervenir activamente para corregir las desigualdades históricas de género y etnia.', 'Y', -1, 'activa', 'Principios y Visión'),
(27, 'La moral y la honestidad deben ser los motores del desarrollo por encima de la eficiencia técnica.', 'Y', 1, 'activa', 'Principios y Visión'),
(28, 'El Estado debe actuar solo de forma subsidiaria, interviniendo únicamente donde el privado no llega.', 'X', 1, 'inactiva', 'Principios y Visión'),
(29, 'La verdadera democracia solo se logra mediante la participación activa de las organizaciones sociales de base.', 'X', -1, 'inactiva', 'Principios y Visión'),
(30, 'El sistema de salud debe ser unificado (Minsa, EsSalud, Privados) bajo una sola red pública universal.', 'X', -1, 'activa', 'Salud'),
(31, 'La gestión de los hospitales públicos debe entregarse a operadores privados especializados para asegurar eficiencia.', 'X', 1, 'activa', 'Salud'),
(32, 'La Educación Sexual Integral (ESI) con enfoque de género debe ser obligatoria para prevenir embarazos adolescentes.', 'Y', -1, 'activa', 'Salud'),
(33, 'El historial clínico electrónico debe ser de propiedad absoluta del ciudadano y accesible digitalmente en todo el país.', 'Y', -1, 'activa', 'Salud'),
(34, 'La salud mental debe ser tratada como un componente central y obligatorio de la atención primaria.', 'X', -1, 'inactiva', 'Salud'),
(35, 'El Estado debe garantizar el 100% de la cobertura de vacunación infantil de forma obligatoria.', 'X', -1, 'inactiva', 'Salud'),
(36, 'Los colegios públicos deben gozar de autonomía para adaptar el currículo a su realidad regional.', 'Y', -1, 'activa', 'Educación'),
(37, 'La meritocracia docente (evaluación y retiro) debe ser la prioridad para mejorar la calidad educativa.', 'X', 1, 'activa', 'Educación'),
(38, 'Se debe enseñar chino mandarín en las escuelas para mejorar la competitividad en el mercado global.', 'X', 1, 'inactiva', 'Educación'),
(39, 'El Estado debe financiar \"Becas TEC\" que prioricen carreras técnicas sobre las universitarias.', 'X', -1, 'activa', 'Educación'),
(40, 'La educación debe formar ciudadanos con mentalidad de \"Libertad Financiera\" y emprendimiento empresarial.', 'X', 1, 'inactiva', 'Educación'),
(41, 'Los Institutos de Educación Superior deben fusionarse con las universidades regionales para mejorar su calidad.', 'X', -1, 'inactiva', 'Educación'),
(42, 'Es fundamental que las escuelas enseñen la cosmovisión y saberes de los pueblos indígenas.', 'Y', -1, 'activa', 'Educación'),
(43, 'El Estado debe financiar directamente la construccion masiva de 125 millones de viviendas sociales.', 'X', -1, 'activa', 'Vivienda y Saneamiento'),
(44, 'Las empresas de agua (EPS) deben ser privatizadas o manejadas por operadores globales técnicos.', 'X', 1, 'inactiva', 'Vivienda y Saneamiento'),
(45, 'El acceso al agua potable debe ser un derecho humano que prime sobre el uso minero o industrial.', 'X', -1, 'activa', 'Vivienda y Saneamiento'),
(46, 'Se debe fomentar el mercado de alquiler de vivienda formal mediante subsidios estatales para jóvenes.', '', 0, 'inactiva', 'Vivienda y Saneamiento'),
(47, 'El canon minero debe usarse obligatoriamente para financiar bonos de vivienda en zonas rurales.', 'X', -1, 'activa', 'Vivienda y Saneamiento'),
(48, 'Los títulos de propiedad urbana deben entregarse de forma masiva y digital para dar seguridad jurídica.', 'X', 1, 'activa', 'Vivienda y Saneamiento'),
(49, 'Se debe crear un \"Seguro Laboral Solidario\" para los trabajadores informales.', 'X', -1, 'activa', 'Empleo e Inclusión'),
(50, 'El Estado debe dar un \"Capital Semilla\" a cada recién nacido para garantizar su futura pensión.', 'X', -1, 'activa', 'Empleo e Inclusión'),
(51, '', '', 0, 'inactiva', NULL),
(52, 'Las compras estatales deben priorizar en un 40% a las micro y pequeñas empresas locales.', 'X', -1, 'activa', 'Empleo e Inclusión'),
(53, '', '', 0, 'inactiva', NULL),
(54, 'La formalización se logra mejor con incentivos tributarios que con fiscalización punitiva de la Sunat.', 'X', 1, 'activa', 'Empleo e Inclusión'),
(55, 'Se deben integrar los comedores populares en unidades productivas con visión empresarial.', 'X', 1, 'inactiva', 'Empleo e Inclusión'),
(56, 'Los sitios arqueológicos (huacas) deben ser gestionados por empresas privadas mediante Alianzas Público-Privadas.', 'X', 1, 'activa', 'Cultura'),
(57, 'El Estado debe subsidiar misiones comerciales para la exportación de cine, música y moda peruana.', 'X', -1, 'activa', 'Cultura'),
(58, 'Se debe crear el sello \"Sabores con Origen\" para proteger la gastronomía vinculada a pequeños agricultores.', 'X', -1, 'activa', 'Cultura'),
(59, 'Las lenguas originarias deben ser obligatorias en los trámites públicos de sus respectivas regiones.', 'Y', -1, 'activa', 'Cultura'),
(60, 'Las Fuerzas Armadas deben patrullar las calles permanentemente en apoyo a la Policía Nacional.', 'Y', 1, 'activa', 'Seguridad Ciudadana'),
(61, '', '', 0, 'inactiva', NULL),
(62, 'La investigación preliminar de los delitos debe volver a ser tarea exclusiva de la Policía, quitándole esa facultad a la Fiscalía.', 'Y', 1, 'activa', 'Seguridad Ciudadana'),
(63, 'Los altos mandos policiales y del INPE deben someterse obligatoriamente a la prueba del polígrafo.', 'Y', -1, 'activa', 'Seguridad Ciudadana'),
(64, '', '', 0, 'inactiva', NULL),
(65, 'Los extranjeros que cometan cualquier delito deben ser expulsados del país de forma inmediata.', 'Y', 1, 'activa', 'Seguridad Ciudadana'),
(66, 'El Perú debe acatar estrictamente todas las sentencias de la Corte Interamericana de Derechos Humanos.', 'Y', -1, 'activa', 'Justicia y Derechos Humanos'),
(67, 'Se debe eliminar la ratificación periódica de jueces para evitar el clientelismo político.', 'Y', -1, 'activa', 'Justicia y Derechos Humanos'),
(68, '', '', 0, 'inactiva', NULL),
(69, 'La Inteligencia Artificial debe reemplazar a los jueces en la resolución de delitos comunes menores.', 'Y', -1, 'activa', 'Justicia y Derechos Humanos'),
(70, 'El hacinamiento penal se soluciona otorgando beneficios penitenciarios y medidas alternativas a la prisión.', 'Y', -1, 'activa', 'Justicia y Derechos Humanos'),
(71, 'El Perú debe priorizar su ingreso a la OCDE por encima de la integración latinoamericana.', 'X', 1, 'activa', 'Relaciones Exteriores y Defensa'),
(72, 'Se debe permitir que extranjeros posean tierras y propiedades en zonas de frontera (antes de los 50 km).', 'X', 1, 'inactiva', 'Relaciones Exteriores y Defensa'),
(73, 'La diplomacia peruana debe priorizar las relaciones con el Sur Global (BRICS) sobre los bloques tradicionales.', 'X', -1, 'activa', 'Relaciones Exteriores y Defensa'),
(74, 'El Servicio Militar debe ser \"dignificado\" pagando un Sueldo Mínimo Vital a los reclutas.', 'X', -1, 'activa', 'Relaciones Exteriores y Defensa'),
(75, 'La ingeniería militar debe encargarse de las grandes obras de infraestructura en la Amazonía.', 'X', -1, 'activa', 'Relaciones Exteriores y Defensa'),
(76, 'El número de ministerios debe reducirse drásticamente (de 19 a 10) para evitar burocracia.', 'X', 1, 'activa', 'Economía'),
(77, 'El Congreso debe tener prohibido por ley crear cualquier tipo de iniciativa de gasto.', 'X', 1, 'activa', 'Economía'),
(78, '', '', 0, 'inactiva', NULL),
(79, 'Se debe crear un \"Fondo Soberano de Riqueza\" con los excedentes de la minería para financiar inversión pública.', 'X', -1, 'activa', 'Economía'),
(80, 'Los impuestos para nuevas empresas deben ser cero durante sus primeros dos años de vida.', 'X', 1, 'activa', 'Economía'),
(81, '', '', 0, 'inactiva', NULL),
(82, 'El Estado debe liderar la creación de un Polo Petroquímico nacional en el sur del país.', 'X', -1, 'activa', 'Industrialización y Transporte'),
(83, 'Se debe priorizar la construcción del Tren de la Costa (Barranca-Lima-Ica) sobre más carreteras.', 'X', -1, 'activa', 'Industrialización y Transporte'),
(84, 'El transporte masivo eléctrico es más importante que facilitar la compuerta de autos privados.', 'X', -1, 'activa', 'Industrialización y Transporte'),
(85, '', '', 0, 'inactiva', NULL),
(86, 'Se debe permitir la creación de Zonas Económicas Especiales (ZEE) con exoneración total de impuestos.', 'X', 1, 'activa', 'Industrialización y Transporte'),
(87, 'Se debe entregar el \"Cheque Minero\": dinero directo del canon a las familias en zonas de influencia.', 'X', -1, 'activa', 'Agricultura, Energía y Minas'),
(88, '', '', 0, 'inactiva', NULL),
(89, 'El Estado no debe inyectar ni un sol más de presupuesto a Petroperú y debe permitir inversión privada en ella.', 'X', 1, 'activa', 'Agricultura, Energía y Minas'),
(90, '', '', 0, 'inactiva', NULL),
(91, 'Se debe prohibir toda actividad extractiva en cabeceras de cuenca para proteger el agua.', 'Y', -1, 'activa', 'Agricultura, Energía y Minas'),
(92, 'El gas natural debe ser el combustible obligatorio para todo el transporte público nacional.', 'X', -1, 'activa', 'Agricultura, Energía y Minas'),
(93, '', '', 0, 'inactiva', NULL),
(94, '', '', 0, 'inactiva', NULL),
(95, 'El Estado debe pagar un sueldo a las comunidades que conserven sus bosques (Servicios Ecosistémicos).', 'X', -1, 'activa', 'Medio Ambiente'),
(96, 'Se deben aplicar impuestos elevados a las empresas con alta huella de carbono.', 'X', -1, 'activa', 'Medio Ambiente'),
(97, 'La Amazonía solo se salvará si se otorgan títulos de propiedad masivos a las comunidades nativas.', 'Y', -1, 'activa', 'Medio Ambiente'),
(98, '', '', 0, 'inactiva', NULL),
(99, 'El 30% de la energía del país debe provenir de fuentes renovables (solar/eólica) para el 2031.', 'X', -1, 'activa', 'Medio Ambiente'),
(100, 'Los ciudadanos deben poder evaluar la calidad de atención de cada comisaría o posta médica mediante una app oficial.', 'Y', -1, 'activa', 'Rendición de Cuentas'),
(101, 'Todas las agendas y reuniones de altos funcionarios deben publicarse en tiempo real en internet.', 'Y', -1, 'activa', 'Rendición de Cuentas'),
(102, '', '', 0, 'inactiva', NULL),
(103, 'Las compras del Estado deben ser monitoreadas por Inteligencia Artificial para detectar fraudes automáticamente.', 'Y', -1, 'activa', 'Rendición de Cuentas'),
(104, '', '', 0, 'inactiva', NULL),
(105, 'El control gubernamental debe enfocarse en los resultados logrados y no solo en el papeleo burocrático.', 'X', 1, 'activa', 'Rendición de Cuentas'),
(106, '', '', 0, 'inactiva', NULL),
(107, '¿Cree que los subsidios a los pobres deben ser temporales y condicionados al trabajo?', 'X', 1, 'activa', 'Política Social'),
(108, '', '', 0, 'inactiva', NULL),
(109, '', '', 0, 'inactiva', NULL),
(110, '', '', 0, 'inactiva', NULL),
(111, '', '', 0, 'inactiva', NULL),
(112, '', '', 0, 'inactiva', NULL),
(113, '', '', 0, 'inactiva', NULL),
(114, '', '', 0, 'inactiva', NULL),
(115, '', '', 0, 'inactiva', NULL),
(116, '', '', 0, 'inactiva', NULL),
(117, '', '', 0, 'inactiva', NULL),
(118, '¿El Estado debe garantizar un \"Ingreso Mínimo Vital\" a todos los ciudadanos desempleados?', 'X', -1, 'activa', 'Política Social'),
(119, '¿Se debe permitir el matrimonio entre personas del mismo sexo en el Perú?', 'Y', -1, 'activa', 'Política Social'),
(120, '¿Cree que el sistema de AFP debe desaparecer y pasar a un sistema nacional público único?', 'X', -1, 'activa', 'Política Social'),
(121, '', '', 0, 'inactiva', NULL),
(122, '', '', 0, 'inactiva', NULL),
(123, '', '', 0, 'inactiva', NULL);

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
(1, 'admin@decide.pe', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'admin', '2024-01-10 13:30:00', 'Miguel Hilario'),
(2, 'supervisor@decide.pe', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'admin', '2024-01-15 15:20:00', 'Juan Mejia'),
(4, 'moderador@decide.pe', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'admin', '2024-02-10 16:30:00', 'Usuario'),
(5, 'juan.perez@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-01-20 19:15:00', 'Usuario'),
(6, 'maria.gonzalez@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-01-25 21:40:00', 'Usuario'),
(7, 'carlos.rodriguez@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-02-05 14:20:00', 'Carlos Rodriguez'),
(8, 'ana.lopez@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-02-08 18:10:00', 'Usuario'),
(9, 'luis.martinez@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-02-12 16:55:00', 'Usuario'),
(10, 'sofia.garcia@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-02-14 20:30:00', 'Usuario'),
(11, 'pedro.sanchez@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-02-18 15:25:00', 'Usuario'),
(12, 'laura.fernandez@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-02-22 19:50:00', 'Usuario'),
(13, 'javier.diaz@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-02-25 13:15:00', 'Usuario'),
(14, 'elena.romero@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-02-28 22:20:00', 'Usuario'),
(15, 'miguel.torres@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-03-02 17:40:00', 'Usuario'),
(16, 'isabel.ortiz@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-03-05 14:35:00', 'Usuario'),
(17, 'daniel.vargas@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-03-08 21:10:00', 'Usuario'),
(18, 'patricia.castro@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-03-10 12:45:00', 'Usuario'),
(19, 'sergio.navarro@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-03-12 19:05:00', 'Usuario'),
(20, 'beatriz.molina@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-03-15 16:25:00', 'Usuario'),
(21, 'nuevo1@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2026-01-14 22:53:48', 'Nuevo Usuario 1'),
(22, 'nuevo2@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'admin', '2026-01-14 22:53:48', 'Nuevo Usuario 2'),
(23, 'nuevo3@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2026-01-14 22:53:48', 'Nuevo Usuario 3'),
(24, 'renzo@decide.pe', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'admin', '2026-01-15 22:19:03', 'Renzo Soto'),
(25, 'miguel@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2026-01-15 22:25:04', 'Miguel Villalobos'),
(26, 'soto@email.com', '123456789012AAbb++!!', 'user', '2026-01-16 00:25:58', 'Renzo Sotoo'),
(27, 'jorge@email.com', '123456789012AAaa**!!', 'user', '2026-01-16 00:28:32', 'Miguel Hilario'),
(28, 'hilario@email.com', 'abAB123++!!qwe', 'user', '2026-01-16 01:01:50', 'Miguel Hilario'),
(29, 'jacobo@zegel.com', 'aBBa12++!!12', 'user', '2026-01-16 02:47:07', 'Jacobo'),
(30, 'pepepecas@email.com', '$argon2id$v=19$m=65536,t=2,p=1$cn8qXblaAFaqfd+h0EsKHE80qGKLlNveI1GzHWUCz4g$Dx/cKn+3+wzDb12qerw+FOp4/uXQieLKp3WYts877PU', 'user', '2026-01-22 22:06:36', 'Pepe Pecas'),
(31, 'admin@tubrujula.pe', '$argon2id$v=19$m=65536,t=2,p=1$7yag2hvze7/fXBEdnNAE07rJMp+cHWFbC0ZtTdVHpB8$792ls4jug00Am/0Z8dv1LX0vIU5QVF1rG5cyQlIG4Xc', 'admin', '2026-01-22 22:10:37', 'Miguel Hilario'),
(32, 'coyote@brujulae.com', '$argon2id$v=19$m=65536,t=2,p=1$4yvq28IRTPIbhWAMzuAbXkJmpphbnXfFRlL4f1UVhPk$vWZrdQZhUnyAuF1cjZlbFx1WPnVjsk+CaqoEL65Ay00', 'user', '2026-01-25 21:20:00', 'Peter Coyote'),
(33, 'cosme.fulanito@email.com', '$argon2id$v=19$m=65536,t=2,p=1$X7lF+l/vHUZ+d7xhUNYBOFXfJIqSgum8fmWImgsHBdg$SOmYQ7Z1mncsQCdD7H2AyGRVNDUGQ7yrzR6pYF2CxEQ', 'user', '2026-01-25 21:24:01', 'Peter Coyote2'),
(35, 'viejosabroso@email.com', '$argon2id$v=19$m=65536,t=2,p=1$v+niOt73lK09FcUyq4/ICzGr26isNOcewmB8bUgnPGE$5CUm16qaYYkHutu/yY1AdayCd9KJgv4Vtcsk/5KU61A', 'user', '2026-01-25 21:27:36', 'Peter Coyote3'),
(36, 'asdqwe@email.com', '$argon2id$v=19$m=65536,t=2,p=1$JGtkL8Ztwnx13s7a02YVxB9/4qjOH7Ym4P/E7F8B1J8$w95jnRZlM1BSA2idaJygTwMaBJ1G9Max/2ygfyKjXo0', 'user', '2026-01-25 21:32:35', 'Peter Coyote4');

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
) ;

--
-- Volcado de datos para la tabla `usuariorespuesta`
--

INSERT INTO `usuariorespuesta` (`sesion_id`, `pregunta_id`, `valor`, `fecha_respuesta`) VALUES
(1, 22, 1, '2026-01-21 18:52:49'),
(1, 23, -1, '2026-01-21 18:52:49'),
(1, 26, 2, '2026-01-21 18:52:49'),
(1, 27, 0, '2026-01-21 18:52:49'),
(22, 22, 2, '2026-01-21 20:09:37'),
(22, 23, 2, '2026-01-21 20:09:37'),
(22, 26, 2, '2026-01-21 20:09:37'),
(22, 27, 2, '2026-01-21 20:09:37'),
(22, 30, 2, '2026-01-21 20:09:37'),
(22, 31, 2, '2026-01-21 20:09:37'),
(22, 32, 2, '2026-01-21 20:09:37'),
(22, 33, 2, '2026-01-21 20:09:37'),
(22, 36, 2, '2026-01-21 20:09:37'),
(22, 37, 2, '2026-01-21 20:09:37'),
(22, 39, 2, '2026-01-21 20:09:37'),
(22, 42, 2, '2026-01-21 20:09:37'),
(22, 43, 1, '2026-01-21 20:09:37'),
(22, 45, 2, '2026-01-21 20:09:37'),
(22, 47, 1, '2026-01-21 20:09:37'),
(22, 48, 2, '2026-01-21 20:09:37'),
(22, 49, 2, '2026-01-21 20:09:37'),
(22, 50, 2, '2026-01-21 20:09:37'),
(22, 52, 2, '2026-01-21 20:09:37'),
(22, 54, 2, '2026-01-21 20:09:37'),
(22, 56, 2, '2026-01-21 20:09:37'),
(22, 57, 2, '2026-01-21 20:09:37'),
(22, 58, 2, '2026-01-21 20:09:37'),
(22, 59, 2, '2026-01-21 20:09:37'),
(22, 60, 2, '2026-01-21 20:09:37'),
(22, 62, 2, '2026-01-21 20:09:37'),
(22, 63, 2, '2026-01-21 20:09:37'),
(22, 65, 2, '2026-01-21 20:09:37'),
(22, 66, 2, '2026-01-21 20:09:37'),
(22, 67, 2, '2026-01-21 20:09:37'),
(22, 69, 2, '2026-01-21 20:09:37'),
(22, 70, 2, '2026-01-21 20:09:37'),
(22, 71, 2, '2026-01-21 20:09:37'),
(22, 73, 2, '2026-01-21 20:09:37'),
(22, 74, 2, '2026-01-21 20:09:37'),
(22, 75, 2, '2026-01-21 20:09:37'),
(22, 76, 2, '2026-01-21 20:09:37'),
(22, 77, 2, '2026-01-21 20:09:37'),
(22, 79, 2, '2026-01-21 20:09:37'),
(22, 80, 2, '2026-01-21 20:09:37'),
(22, 82, 2, '2026-01-21 20:09:37'),
(22, 83, 2, '2026-01-21 20:09:37'),
(22, 84, 2, '2026-01-21 20:09:37'),
(22, 86, 2, '2026-01-21 20:09:37'),
(22, 87, 2, '2026-01-21 20:09:37'),
(22, 89, 1, '2026-01-21 20:09:37'),
(22, 91, 2, '2026-01-21 20:09:37'),
(22, 92, 2, '2026-01-21 20:09:37'),
(22, 95, 2, '2026-01-21 20:09:37'),
(22, 96, 2, '2026-01-21 20:09:37'),
(22, 97, 2, '2026-01-21 20:09:37'),
(22, 99, 2, '2026-01-21 20:09:37'),
(22, 100, 2, '2026-01-21 20:09:37'),
(22, 101, 2, '2026-01-21 20:09:37'),
(22, 103, 2, '2026-01-21 20:09:37'),
(22, 105, 2, '2026-01-21 20:09:37'),
(22, 107, 2, '2026-01-21 20:09:37'),
(22, 118, 2, '2026-01-21 20:09:37'),
(22, 119, 2, '2026-01-21 20:09:37'),
(22, 120, 2, '2026-01-21 20:09:37'),
(52, 22, 2, '2026-01-25 20:15:16'),
(52, 23, 2, '2026-01-25 20:15:16'),
(52, 26, 1, '2026-01-25 20:15:16'),
(52, 27, 1, '2026-01-25 20:15:16'),
(52, 30, -1, '2026-01-25 20:15:16'),
(52, 31, -1, '2026-01-25 20:15:16'),
(52, 32, 1, '2026-01-25 20:15:16'),
(52, 33, 2, '2026-01-25 20:15:16'),
(52, 36, 2, '2026-01-25 20:15:16'),
(52, 37, 2, '2026-01-25 20:15:16'),
(52, 39, 2, '2026-01-25 20:15:16'),
(52, 42, -1, '2026-01-25 20:15:16'),
(52, 43, 2, '2026-01-25 20:15:16'),
(52, 45, 2, '2026-01-25 20:15:16'),
(52, 47, 2, '2026-01-25 20:15:16'),
(52, 48, 1, '2026-01-25 20:15:16'),
(52, 49, 1, '2026-01-25 20:15:16'),
(52, 50, 2, '2026-01-25 20:15:16'),
(52, 52, 2, '2026-01-25 20:15:16'),
(52, 54, 2, '2026-01-25 20:15:16'),
(52, 56, 2, '2026-01-25 20:15:16'),
(52, 57, -2, '2026-01-25 20:15:16'),
(52, 58, 2, '2026-01-25 20:15:16'),
(52, 59, 2, '2026-01-25 20:15:16'),
(52, 60, 2, '2026-01-25 20:15:16'),
(52, 62, 2, '2026-01-25 20:15:16'),
(52, 63, 1, '2026-01-25 20:15:16'),
(52, 65, 2, '2026-01-25 20:15:16'),
(52, 66, 2, '2026-01-25 20:15:16'),
(52, 67, 2, '2026-01-25 20:15:16'),
(52, 69, 2, '2026-01-25 20:15:16'),
(52, 70, 1, '2026-01-25 20:15:16'),
(52, 71, 1, '2026-01-25 20:15:16'),
(52, 73, 2, '2026-01-25 20:15:16'),
(52, 74, 2, '2026-01-25 20:15:16'),
(52, 75, -1, '2026-01-25 20:15:16'),
(52, 76, 2, '2026-01-25 20:15:16'),
(52, 77, 1, '2026-01-25 20:15:16'),
(52, 79, 2, '2026-01-25 20:15:16'),
(52, 80, 1, '2026-01-25 20:15:16'),
(52, 82, 1, '2026-01-25 20:15:16'),
(52, 83, -1, '2026-01-25 20:15:16'),
(52, 84, -1, '2026-01-25 20:15:16'),
(52, 86, -1, '2026-01-25 20:15:16'),
(52, 87, 1, '2026-01-25 20:15:16'),
(52, 89, 2, '2026-01-25 20:15:16'),
(52, 91, 2, '2026-01-25 20:15:16'),
(52, 92, 1, '2026-01-25 20:15:16'),
(52, 95, 1, '2026-01-25 20:15:16'),
(52, 96, 2, '2026-01-25 20:15:16'),
(52, 97, 1, '2026-01-25 20:15:16'),
(52, 99, 2, '2026-01-25 20:15:16'),
(52, 100, 2, '2026-01-25 20:15:16'),
(52, 101, -1, '2026-01-25 20:15:16'),
(52, 103, 2, '2026-01-25 20:15:16'),
(52, 105, 2, '2026-01-25 20:15:16'),
(52, 107, -2, '2026-01-25 20:15:16'),
(52, 118, -2, '2026-01-25 20:15:16'),
(52, 119, 2, '2026-01-25 20:15:16'),
(52, 120, 1, '2026-01-25 20:15:16'),
(53, 22, 1, '2026-01-25 20:39:13'),
(53, 23, 1, '2026-01-25 20:39:13'),
(53, 26, 1, '2026-01-25 20:39:13'),
(53, 27, 1, '2026-01-25 20:39:13'),
(53, 30, 0, '2026-01-25 20:39:13'),
(53, 31, 2, '2026-01-25 20:39:13'),
(53, 32, 1, '2026-01-25 20:39:13'),
(53, 33, 1, '2026-01-25 20:39:13'),
(53, 36, 2, '2026-01-25 20:39:13'),
(53, 37, 1, '2026-01-25 20:39:13'),
(53, 39, 2, '2026-01-25 20:39:13'),
(53, 42, 2, '2026-01-25 20:39:13'),
(53, 43, 2, '2026-01-25 20:39:13'),
(53, 45, 2, '2026-01-25 20:39:13'),
(53, 47, 2, '2026-01-25 20:39:13'),
(53, 48, 2, '2026-01-25 20:39:13'),
(53, 49, 2, '2026-01-25 20:39:13'),
(53, 50, 1, '2026-01-25 20:39:13'),
(53, 52, 2, '2026-01-25 20:39:13'),
(53, 54, -1, '2026-01-25 20:39:13'),
(53, 56, 1, '2026-01-25 20:39:13'),
(53, 57, -2, '2026-01-25 20:39:13'),
(53, 58, 1, '2026-01-25 20:39:13'),
(53, 59, 1, '2026-01-25 20:39:13'),
(53, 60, 1, '2026-01-25 20:39:13'),
(53, 62, 2, '2026-01-25 20:39:13'),
(53, 63, 2, '2026-01-25 20:39:13'),
(53, 65, 1, '2026-01-25 20:39:13'),
(53, 66, 2, '2026-01-25 20:39:13'),
(53, 67, 1, '2026-01-25 20:39:13'),
(53, 69, 1, '2026-01-25 20:39:13'),
(53, 70, 2, '2026-01-25 20:39:13'),
(53, 71, 2, '2026-01-25 20:39:13'),
(53, 73, 1, '2026-01-25 20:39:13'),
(53, 74, 2, '2026-01-25 20:39:13'),
(53, 75, 1, '2026-01-25 20:39:13'),
(53, 76, 1, '2026-01-25 20:39:13'),
(53, 77, 2, '2026-01-25 20:39:13'),
(53, 79, 2, '2026-01-25 20:39:13'),
(53, 80, -1, '2026-01-25 20:39:13'),
(53, 82, 2, '2026-01-25 20:39:13'),
(53, 83, 1, '2026-01-25 20:39:13'),
(53, 84, 2, '2026-01-25 20:39:13'),
(53, 86, 2, '2026-01-25 20:39:13'),
(53, 87, 2, '2026-01-25 20:39:13'),
(53, 89, 1, '2026-01-25 20:39:13'),
(53, 91, 2, '2026-01-25 20:39:13'),
(53, 92, 2, '2026-01-25 20:39:13'),
(53, 95, 2, '2026-01-25 20:39:13'),
(53, 96, 2, '2026-01-25 20:39:13'),
(53, 97, 1, '2026-01-25 20:39:13'),
(53, 99, 1, '2026-01-25 20:39:13'),
(53, 100, 1, '2026-01-25 20:39:13'),
(53, 101, 2, '2026-01-25 20:39:13'),
(53, 103, 1, '2026-01-25 20:39:13'),
(53, 105, 1, '2026-01-25 20:39:13'),
(53, 107, 1, '2026-01-25 20:39:13'),
(53, 118, -2, '2026-01-25 20:39:13'),
(53, 119, 2, '2026-01-25 20:39:13'),
(53, 120, 2, '2026-01-25 20:39:13'),
(54, 22, 2, '2026-01-25 21:34:47'),
(54, 23, -1, '2026-01-25 21:34:47'),
(54, 26, -1, '2026-01-25 21:34:47'),
(54, 27, -1, '2026-01-25 21:34:47'),
(54, 30, -1, '2026-01-25 21:34:47'),
(54, 31, 2, '2026-01-25 21:34:47'),
(54, 32, 1, '2026-01-25 21:34:47'),
(54, 33, -1, '2026-01-25 21:34:47'),
(54, 36, 1, '2026-01-25 21:34:47'),
(54, 37, 2, '2026-01-25 21:34:47'),
(54, 39, -1, '2026-01-25 21:34:47'),
(54, 42, 2, '2026-01-25 21:34:47'),
(54, 43, 2, '2026-01-25 21:34:47'),
(54, 45, -1, '2026-01-25 21:34:47'),
(54, 47, 1, '2026-01-25 21:34:47'),
(54, 48, 1, '2026-01-25 21:34:47'),
(54, 49, 1, '2026-01-25 21:34:47'),
(54, 50, 2, '2026-01-25 21:34:47'),
(54, 52, 2, '2026-01-25 21:34:47'),
(54, 54, 0, '2026-01-25 21:34:47'),
(54, 56, 2, '2026-01-25 21:34:47'),
(54, 57, -2, '2026-01-25 21:34:47'),
(54, 58, 0, '2026-01-25 21:34:47'),
(54, 59, 1, '2026-01-25 21:34:47'),
(54, 60, 2, '2026-01-25 21:34:47'),
(54, 62, 2, '2026-01-25 21:34:47'),
(54, 63, 1, '2026-01-25 21:34:47'),
(54, 65, 1, '2026-01-25 21:34:47'),
(54, 66, 1, '2026-01-25 21:34:47'),
(54, 67, -2, '2026-01-25 21:34:47'),
(54, 69, 2, '2026-01-25 21:34:47'),
(54, 70, -1, '2026-01-25 21:34:47'),
(54, 71, 2, '2026-01-25 21:34:47'),
(54, 73, -2, '2026-01-25 21:34:47'),
(54, 74, 1, '2026-01-25 21:34:47'),
(54, 75, 2, '2026-01-25 21:34:47'),
(54, 76, 2, '2026-01-25 21:34:47'),
(54, 77, -2, '2026-01-25 21:34:47'),
(54, 79, -1, '2026-01-25 21:34:47'),
(54, 80, 0, '2026-01-25 21:34:47'),
(54, 82, 2, '2026-01-25 21:34:47'),
(54, 83, 1, '2026-01-25 21:34:47'),
(54, 84, 2, '2026-01-25 21:34:47'),
(54, 86, -2, '2026-01-25 21:34:47'),
(54, 87, 0, '2026-01-25 21:34:47'),
(54, 89, 1, '2026-01-25 21:34:47'),
(54, 91, -1, '2026-01-25 21:34:47'),
(54, 92, 1, '2026-01-25 21:34:47'),
(54, 95, 1, '2026-01-25 21:34:47'),
(54, 96, 2, '2026-01-25 21:34:47'),
(54, 97, 1, '2026-01-25 21:34:47'),
(54, 99, 0, '2026-01-25 21:34:47'),
(54, 100, 1, '2026-01-25 21:34:47'),
(54, 101, -1, '2026-01-25 21:34:47'),
(54, 103, 2, '2026-01-25 21:34:47'),
(54, 105, -1, '2026-01-25 21:34:47'),
(54, 107, 2, '2026-01-25 21:34:47'),
(54, 118, -1, '2026-01-25 21:34:47'),
(54, 119, 1, '2026-01-25 21:34:47'),
(54, 120, 2, '2026-01-25 21:34:47');

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
) ;

--
-- Volcado de datos para la tabla `usuariosesion`
--

INSERT INTO `usuariosesion` (`id`, `fecha`, `resultado_x`, `resultado_y`, `completado`, `token`, `usuario_id`) VALUES
(1, '2026-01-21 18:52:49', NULL, NULL, 0, NULL, NULL),
(2, '2026-01-21 19:01:10', NULL, NULL, 0, NULL, NULL),
(3, '2026-01-21 19:13:38', NULL, NULL, 0, NULL, NULL),
(4, '2026-01-21 19:14:37', NULL, NULL, 0, NULL, NULL),
(5, '2026-01-21 19:14:40', NULL, NULL, 0, NULL, NULL),
(6, '2026-01-21 19:14:41', NULL, NULL, 0, NULL, NULL),
(7, '2026-01-21 19:14:42', NULL, NULL, 0, NULL, NULL),
(8, '2026-01-21 19:36:39', NULL, NULL, 0, NULL, NULL),
(9, '2026-01-21 19:37:39', NULL, NULL, 0, NULL, NULL),
(10, '2026-01-21 19:49:05', NULL, NULL, 0, NULL, NULL),
(11, '2026-01-21 19:57:19', NULL, NULL, 0, NULL, NULL),
(12, '2026-01-21 20:01:55', NULL, NULL, 0, NULL, NULL),
(13, '2026-01-21 20:02:24', NULL, NULL, 0, NULL, NULL),
(14, '2026-01-21 20:02:36', NULL, NULL, 0, NULL, NULL),
(15, '2026-01-21 20:02:56', NULL, NULL, 0, NULL, NULL),
(16, '2026-01-21 20:03:22', NULL, NULL, 0, NULL, NULL),
(17, '2026-01-21 20:03:44', NULL, NULL, 0, NULL, NULL),
(18, '2026-01-21 20:05:20', NULL, NULL, 0, NULL, NULL),
(19, '2026-01-21 20:05:30', NULL, NULL, 0, NULL, NULL),
(20, '2026-01-21 20:07:24', NULL, NULL, 0, NULL, NULL),
(21, '2026-01-21 20:07:25', NULL, NULL, 0, NULL, NULL),
(22, '2026-01-21 20:08:05', -26.92, -61.90, 1, NULL, NULL),
(23, '2026-01-21 23:55:00', NULL, NULL, 0, NULL, NULL),
(24, '2026-01-22 00:13:18', NULL, NULL, 0, NULL, NULL),
(25, '2026-01-22 00:13:52', NULL, NULL, 0, NULL, NULL),
(26, '2026-01-22 00:15:02', NULL, NULL, 0, NULL, NULL),
(27, '2026-01-22 00:17:26', NULL, NULL, 0, NULL, NULL),
(28, '2026-01-22 00:17:54', NULL, NULL, 0, NULL, NULL),
(29, '2026-01-22 00:18:04', NULL, NULL, 0, NULL, NULL),
(30, '2026-01-22 00:20:17', NULL, NULL, 0, NULL, NULL),
(31, '2026-01-22 00:22:00', NULL, NULL, 0, NULL, NULL),
(32, '2026-01-22 00:22:11', NULL, NULL, 0, NULL, NULL),
(33, '2026-01-22 00:23:34', NULL, NULL, 0, NULL, NULL),
(34, '2026-01-22 00:24:29', NULL, NULL, 0, NULL, NULL),
(35, '2026-01-22 01:16:40', NULL, NULL, 0, NULL, NULL),
(36, '2026-01-22 01:23:16', NULL, NULL, 0, NULL, NULL),
(37, '2026-01-22 01:32:37', NULL, NULL, 0, NULL, NULL),
(38, '2026-01-22 01:36:57', NULL, NULL, 0, NULL, NULL),
(39, '2026-01-22 01:38:47', NULL, NULL, 0, NULL, NULL),
(40, '2026-01-22 01:38:50', NULL, NULL, 0, NULL, NULL),
(41, '2026-01-22 01:38:51', NULL, NULL, 0, NULL, NULL),
(42, '2026-01-22 01:39:45', NULL, NULL, 0, NULL, NULL),
(43, '2026-01-22 01:40:23', NULL, NULL, 0, NULL, NULL),
(44, '2026-01-22 02:21:41', NULL, NULL, 0, NULL, NULL),
(45, '2026-01-22 21:34:05', NULL, NULL, 0, NULL, NULL),
(46, '2026-01-22 21:35:25', NULL, NULL, 0, NULL, NULL),
(47, '2026-01-22 21:35:35', NULL, NULL, 0, NULL, NULL),
(48, '2026-01-22 21:39:31', NULL, NULL, 0, NULL, NULL),
(49, '2026-01-24 00:02:55', NULL, NULL, 0, NULL, NULL),
(50, '2026-01-24 00:03:01', NULL, NULL, 0, NULL, NULL),
(51, '2026-01-24 00:03:34', NULL, NULL, 0, NULL, NULL),
(52, '2026-01-25 20:11:33', -12.82, -38.10, 1, NULL, NULL),
(53, '2026-01-25 20:37:51', -23.68, -47.62, 1, '3fac4d1496', NULL),
(54, '2026-01-25 21:33:03', -10.29, -7.14, 1, '63d9559e49', NULL);

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
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=37;

--
-- AUTO_INCREMENT de la tabla `usuariosesion`
--
ALTER TABLE `usuariosesion`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- Restricciones para tablas volcadas
--

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
