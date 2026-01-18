-- ============================================================
-- MIGRACIÓN V2: Actualización fórmula cálculo posiciones
-- ============================================================

USE decide_pe;

-- 1. Eliminar los triggers y procedimientos antiguos para evitar conflictos
DROP TRIGGER IF EXISTS actualizar_posicion_partido_insert;
DROP TRIGGER IF EXISTS actualizar_posicion_partido_update;
DROP TRIGGER IF EXISTS actualizar_posicion_partido_delete;
DROP PROCEDURE IF EXISTS CalcularPosicionPartido;

-- ------------------------------------------------------------
-- 2. Crear el nuevo procedimiento para PARTIDOS
-- ------------------------------------------------------------
DELIMITER //

CREATE PROCEDURE CalcularPosicionPartido(IN p_partido_id INT)
BEGIN
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
END//

-- ------------------------------------------------------------
-- 3. Procedimiento para cálculo de USUARIOS (Sesión)
-- ------------------------------------------------------------
DROP PROCEDURE IF EXISTS CalcularPosicionUsuario//
CREATE PROCEDURE CalcularPosicionUsuario(IN p_sesion_id INT)
BEGIN
    DECLARE total_x, total_y DECIMAL(10,2);
    DECLARE count_x, count_y INT;
    DECLARE pos_x, pos_y DECIMAL(5,2);
    
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
    
    UPDATE UsuarioSesion 
    SET resultado_x = GREATEST(-100, LEAST(100, pos_x)), 
        resultado_y = GREATEST(-100, LEAST(100, pos_y)),
        completado = TRUE
    WHERE id = p_sesion_id;
END//

DELIMITER ;

-- 4. Crear los nuevos triggers (Partidos)
DELIMITER //
DROP TRIGGER IF EXISTS actualizar_posicion_partido_insert//
CREATE TRIGGER actualizar_posicion_partido_insert AFTER INSERT ON PartidoRespuesta
FOR EACH ROW BEGIN CALL CalcularPosicionPartido(NEW.partido_id); END//

DROP TRIGGER IF EXISTS actualizar_posicion_partido_update//
CREATE TRIGGER actualizar_posicion_partido_update AFTER UPDATE ON PartidoRespuesta
FOR EACH ROW BEGIN CALL CalcularPosicionPartido(NEW.partido_id); END//

DROP TRIGGER IF EXISTS actualizar_posicion_partido_delete//
CREATE TRIGGER actualizar_posicion_partido_delete AFTER DELETE ON PartidoRespuesta
FOR EACH ROW BEGIN CALL CalcularPosicionPartido(OLD.partido_id); END//

-- 5. Trigger para Usuarios (Se activa al completar preguntas)
DROP TRIGGER IF EXISTS actualizar_posicion_usuario//
CREATE TRIGGER actualizar_posicion_usuario AFTER INSERT ON UsuarioRespuesta
FOR EACH ROW
BEGIN
    DECLARE total_resp, total_preg INT;
    SELECT COUNT(*) INTO total_resp FROM UsuarioRespuesta WHERE sesion_id = NEW.sesion_id;
    SELECT COUNT(*) INTO total_preg FROM Pregunta WHERE estado = 'activa';
    IF total_resp >= total_preg THEN CALL CalcularPosicionUsuario(NEW.sesion_id); END IF;
END//
DELIMITER ;

-- 6. Recalcular todo el histórico
TRUNCATE TABLE PartidoPosicionCache;

DELIMITER //
DROP PROCEDURE IF EXISTS RecalcularTodasPosiciones//
CREATE PROCEDURE RecalcularTodasPosiciones()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_id INT;
    DECLARE cur CURSOR FOR SELECT id FROM Partido;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    OPEN cur;
    read_loop: LOOP
        FETCH cur INTO v_id;
        IF done THEN LEAVE read_loop; END IF;
        CALL CalcularPosicionPartido(v_id);
    END LOOP;
    CLOSE cur;
END//
DELIMITER ;

CALL RecalcularTodasPosiciones();
DROP PROCEDURE IF EXISTS RecalcularTodasPosiciones;

-- 7. Verificación final
SELECT p.nombre, ppc.posicion_x, ppc.posicion_y, ppc.fecha_calculo
FROM PartidoPosicionCache ppc JOIN Partido p ON ppc.partido_id = p.id;
