-- ------------------------------------------------------------
-- BASE DE DATOS: decide_pe
-- ------------------------------------------------------------

CREATE DATABASE IF NOT EXISTS decide_pe;
USE decide_pe;

-- ------------------------------------------------------------
-- TABLA 1: Usuario
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Usuario (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    rol ENUM('user', 'admin') DEFAULT 'user',
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_email (email),
    INDEX idx_rol (rol)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- TABLA 2: Pregunta
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Pregunta (
    id INT PRIMARY KEY AUTO_INCREMENT,
    texto TEXT NOT NULL,
    eje ENUM('X', 'Y') NOT NULL COMMENT 'X: económico, Y: social',
    direccion TINYINT NOT NULL COMMENT '+1 o -1',
    estado ENUM('activa', 'inactiva') DEFAULT 'activa',
    categoria VARCHAR(50) COMMENT 'economia, derechos, ambiental, social',
    
    INDEX idx_eje (eje),
    INDEX idx_estado (estado),
    INDEX idx_categoria (categoria)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- TABLA 3: Partido
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS Partido (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    nombre_largo VARCHAR(100) UNIQUE NOT NULL,
    sigla VARCHAR(10),
    
    INDEX idx_nombre (nombre)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- TABLA 4: PartidoRespuesta
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS PartidoRespuesta (
    partido_id INT NOT NULL,
    pregunta_id INT NOT NULL,
    valor TINYINT NOT NULL COMMENT '-2, -1, 0, +1, +2',
    fuente VARCHAR(500) COMMENT 'URL o referencia de la posición',
    
    PRIMARY KEY (partido_id, pregunta_id),
    FOREIGN KEY (partido_id) REFERENCES Partido(id) ON DELETE CASCADE,
    FOREIGN KEY (pregunta_id) REFERENCES Pregunta(id) ON DELETE CASCADE,
    
    INDEX idx_pregunta (pregunta_id),
    CONSTRAINT chk_valor CHECK (valor BETWEEN -2 AND 2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- TABLA 5: UsuarioSesion 
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS UsuarioSesion (
    id INT PRIMARY KEY AUTO_INCREMENT,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    resultado_x DECIMAL(5,2) COMMENT '-100.00 a +100.00',
    resultado_y DECIMAL(5,2) COMMENT '-100.00 a +100.00',
    completado BOOLEAN DEFAULT FALSE,
    usuario_id INT NULL COMMENT 'NULL si es anónimo',
    
    FOREIGN KEY (usuario_id) REFERENCES Usuario(id) ON DELETE SET NULL,
    
    INDEX idx_usuario (usuario_id),
    INDEX idx_fecha (fecha),
    INDEX idx_completado (completado),
    CONSTRAINT chk_resultados CHECK (
        resultado_x BETWEEN -100 AND 100 AND 
        resultado_y BETWEEN -100 AND 100
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- TABLA 6: UsuarioRespuesta 
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS UsuarioRespuesta (
    sesion_id INT NOT NULL,
    pregunta_id INT NOT NULL,
    valor TINYINT NOT NULL COMMENT '-2, -1, 0, +1, +2',
    fecha_respuesta TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (sesion_id, pregunta_id),
    FOREIGN KEY (sesion_id) REFERENCES UsuarioSesion(id) ON DELETE CASCADE,
    FOREIGN KEY (pregunta_id) REFERENCES Pregunta(id) ON DELETE CASCADE,
    
    INDEX idx_sesion (sesion_id),
    INDEX idx_pregunta (pregunta_id),
    INDEX idx_fecha (fecha_respuesta),
    CONSTRAINT chk_valor_usuario CHECK (valor BETWEEN -2 AND 2)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- TABLA 7: PartidoPosicionCache 
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS PartidoPosicionCache (
    partido_id INT PRIMARY KEY,
    posicion_x DECIMAL(5,2) COMMENT '-100.00 a +100.00',
    posicion_y DECIMAL(5,2) COMMENT '-100.00 a +100.00',
    fecha_calculo TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (partido_id) REFERENCES Partido(id) ON DELETE CASCADE,
    
    INDEX idx_posicion_x (posicion_x),
    INDEX idx_posicion_y (posicion_y),
    CONSTRAINT chk_posiciones CHECK (
        posicion_x BETWEEN -100 AND 100 AND 
        posicion_y BETWEEN -100 AND 100
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------
-- DATOS INICIALES: Preguntas del Quiz (20 preguntas - 10 por eje)
-- ------------------------------------------------------------

-- Preguntas Eje X (Económico: Izquierda ↔ Derecha)
INSERT INTO Pregunta (texto, eje, direccion, categoria) VALUES
('El estado debe cobrar más impuestos a los ricos', 'X', +1, 'economia'),
('Las empresas públicas son menos eficientes que las privadas', 'X', -1, 'economia'),
('El salario mínimo debe ser determinado por el mercado', 'X', -1, 'laboral'),
('La salud debe ser gratuita y universal', 'X', +1, 'salud'),
('Las pensiones deben manejarse de forma privada', 'X', -1, 'economia'),
('El estado debe subsidiar la educación superior', 'X', +1, 'educacion'),
('La libre competencia beneficia más al consumidor', 'X', -1, 'economia'),
('Los recursos naturales deben ser propiedad del estado', 'X', +1, 'ambiental'),
('Los sindicatos tienen demasiado poder', 'X', -1, 'laboral'),
('La desigualdad económica es el problema principal', 'X', +1, 'economia'),

-- Preguntas Eje Y (Social: Conservador ↔ Liberal)
('El aborto debería ser legal', 'Y', +1, 'derechos'),
('El matrimonio debe ser solo entre hombre y mujer', 'Y', -1, 'derechos'),
('La inmigración debe ser más restrictiva', 'Y', -1, 'social'),
('Las drogas deberían despenalizarse', 'Y', +1, 'derechos'),
('La religión debe influir en las leyes', 'Y', -1, 'social'),
('La eutanasia debería ser legal', 'Y', +1, 'derechos'),
('La ideología de género no debe enseñarse en colegios', 'Y', -1, 'educacion'),
('La diversidad sexual debe celebrarse', 'Y', +1, 'derechos'),
('Las tradiciones son importantes para la sociedad', 'Y', -1, 'social'),
('El estado debe ser laico', 'Y', +1, 'social');

-- ------------------------------------------------------------
-- DATOS INICIALES: Partidos Políticos
-- ------------------------------------------------------------
INSERT INTO Partido (nombre, nombre_largo, sigla) VALUES
('Partido Liberal', 'Partido Liberal Peruano', 'PLP'),
('Frente Conservador', 'Frente Conservador Unido', 'FCU'),
('Acción Popular', 'Acción Popular', 'AP'),
('Movimiento Izquierda', 'Movimiento Izquierdista Revolucionario', 'MIR'),
('Partido Verde', 'Partido Verde Ecologista', 'PVE');

-- ------------------------------------------------------------
-- DATOS INICIALES: Usuarios (4 admin, 16 user)
-- ------------------------------------------------------------
INSERT INTO Usuario (email, password_hash, rol, fecha_registro) VALUES
-- Admins (4)
('admin@decide.pe', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'admin', '2024-01-10 08:30:00'),
('supervisor@decide.pe', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'admin', '2024-01-15 10:20:00'),
('analista@decide.pe', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'admin', '2024-02-01 09:45:00'),
('moderador@decide.pe', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'admin', '2024-02-10 11:30:00'),

-- Users (16)
('juan.perez@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-01-20 14:15:00'),
('maria.gonzalez@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-01-25 16:40:00'),
('carlos.rodriguez@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-02-05 09:20:00'),
('ana.lopez@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-02-08 13:10:00'),
('luis.martinez@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-02-12 11:55:00'),
('sofia.garcia@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-02-14 15:30:00'),
('pedro.sanchez@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-02-18 10:25:00'),
('laura.fernandez@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-02-22 14:50:00'),
('javier.diaz@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-02-25 08:15:00'),
('elena.romero@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-02-28 17:20:00'),
('miguel.torres@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-03-02 12:40:00'),
('isabel.ortiz@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-03-05 09:35:00'),
('daniel.vargas@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-03-08 16:10:00'),
('patricia.castro@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-03-10 07:45:00'),
('sergio.navarro@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-03-12 14:05:00'),
('beatriz.molina@email.com', '$2a$10$N9qo8uLOickgx2ZMRZoMye', 'user', '2024-03-15 11:25:00');

-- ------------------------------------------------------------
-- PROCEDIMIENTO: Calcular posición de un partido
-- ------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE CalcularPosicionPartido(IN p_partido_id INT)
BEGIN
    DECLARE total_x DECIMAL(10,2);
    DECLARE total_y DECIMAL(10,2);
    DECLARE count_x INT;
    DECLARE count_y INT;
    DECLARE pos_x DECIMAL(5,2);
    DECLARE pos_y DECIMAL(5,2);
    
    -- Calcular sumas y conteos por eje
    SELECT 
        SUM(CASE WHEN p.eje = 'X' THEN pr.valor * p.direccion ELSE 0 END),
        SUM(CASE WHEN p.eje = 'Y' THEN pr.valor * p.direccion ELSE 0 END),
        SUM(CASE WHEN p.eje = 'X' THEN 1 ELSE 0 END),
        SUM(CASE WHEN p.eje = 'Y' THEN 1 ELSE 0 END)
    INTO total_x, total_y, count_x, count_y
    FROM PartidoRespuesta pr
    JOIN Pregunta p ON pr.pregunta_id = p.id
    WHERE pr.partido_id = p_partido_id
      AND p.estado = 'activa';
    
    -- Evitar división por cero
    SET total_x = IFNULL(total_x, 0);
    SET total_y = IFNULL(total_y, 0);
    SET count_x = IFNULL(count_x, 1);
    SET count_y = IFNULL(count_y, 1);
    
    -- Normalizar a escala -100..+100
    SET pos_x = (total_x / (count_x * 2)) * 100;
    SET pos_y = (total_y / (count_y * 2)) * 100;
    
    -- Asegurar límites
    SET pos_x = GREATEST(-100, LEAST(100, pos_x));
    SET pos_y = GREATEST(-100, LEAST(100, pos_y));
    
    -- Insertar o actualizar cache
    INSERT INTO PartidoPosicionCache (partido_id, posicion_x, posicion_y, fecha_calculo)
    VALUES (p_partido_id, pos_x, pos_y, NOW())
    ON DUPLICATE KEY UPDATE
        posicion_x = pos_x,
        posicion_y = pos_y,
        fecha_calculo = NOW();
END//

DELIMITER ;

-- ------------------------------------------------------------
-- TRIGGERS: Mantener PartidoPosicionCache actualizado
-- ------------------------------------------------------------
DELIMITER //

CREATE TRIGGER actualizar_posicion_partido_insert 
AFTER INSERT ON PartidoRespuesta
FOR EACH ROW
BEGIN
    CALL CalcularPosicionPartido(NEW.partido_id);
END//

CREATE TRIGGER actualizar_posicion_partido_update 
AFTER UPDATE ON PartidoRespuesta
FOR EACH ROW
BEGIN
    CALL CalcularPosicionPartido(NEW.partido_id);
END//

CREATE TRIGGER actualizar_posicion_partido_delete 
AFTER DELETE ON PartidoRespuesta
FOR EACH ROW
BEGIN
    CALL CalcularPosicionPartido(OLD.partido_id);
END//

DELIMITER ;

-- ------------------------------------------------------------
-- VISTAS ÚTILES
-- ------------------------------------------------------------

-- Vista 1: Estadísticas de uso del quiz
CREATE VIEW VistaEstadisticasQuiz AS
SELECT 
    DATE(us.fecha) as fecha,
    COUNT(*) as total_sesiones,
    SUM(CASE WHEN us.completado = TRUE THEN 1 ELSE 0 END) as completadas,
    SUM(CASE WHEN us.usuario_id IS NULL THEN 1 ELSE 0 END) as anonimas,
    SUM(CASE WHEN us.usuario_id IS NOT NULL THEN 1 ELSE 0 END) as registradas,
    AVG(us.resultado_x) as promedio_x,
    AVG(us.resultado_y) as promedio_y
FROM UsuarioSesion us
GROUP BY DATE(us.fecha);

-- Vista 2: Usuarios con su actividad
CREATE VIEW VistaUsuariosActividad AS
SELECT 
    u.id,
    u.email,
    u.rol,
    u.fecha_registro,
    COUNT(us.id) as total_sesiones,
    MAX(us.fecha) as ultima_sesion,
    SUM(CASE WHEN us.completado = TRUE THEN 1 ELSE 0 END) as sesiones_completadas
FROM Usuario u
LEFT JOIN UsuarioSesion us ON u.id = us.usuario_id
GROUP BY u.id;

-- Vista 3: Preguntas con estadísticas de respuestas
CREATE VIEW VistaPreguntasEstadisticas AS
SELECT 
    p.id,
    p.texto,
    p.eje,
    p.direccion,
    p.categoria,
    COUNT(ur.valor) as total_respuestas,
    AVG(ur.valor) as promedio_respuesta
FROM Pregunta p
LEFT JOIN UsuarioRespuesta ur ON p.id = ur.pregunta_id
GROUP BY p.id;