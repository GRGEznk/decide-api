-- ========================================================
-- VISTAS PARA EL DASHBOARD DE ADMINISTRACIÓN (POSTGRESQL)
-- Proyecto: Brújula Electoral PE
-- ========================================================

-- 1. Vista: Estadísticas resumidas por día (para gráfico de actividad)
CREATE OR REPLACE VIEW vistaestadisticasquiz AS
SELECT 
  DATE(fecha) AS fecha,
  COUNT(*) AS total_sesiones,
  SUM(CASE WHEN completado = true THEN 1 ELSE 0 END) AS completadas,
  SUM(CASE WHEN usuario_id IS NULL THEN 1 ELSE 0 END) AS anonimas,
  SUM(CASE WHEN usuario_id IS NOT NULL THEN 1 ELSE 0 END) AS registradas,
  AVG(resultado_x) AS promedio_x,
  AVG(resultado_y) AS promedio_y
FROM usuariosesion
GROUP BY DATE(fecha);

-- 2. Vista: Estadísticas por pregunta (para ranking de interés)
CREATE OR REPLACE VIEW vistapreguntasestadisticas AS
SELECT 
  p.id,
  p.texto,
  p.eje,
  p.direccion,
  p.categoria,
  COUNT(ur.valor) AS total_respuestas,
  AVG(ur.valor) AS promedio_respuesta
FROM pregunta p
LEFT JOIN usuariorespuesta ur ON p.id = ur.pregunta_id
GROUP BY p.id, p.texto, p.eje, p.direccion, p.categoria;

-- 3. Vista: Actividad de usuarios registrados
CREATE OR REPLACE VIEW vistausuariosactividad AS
SELECT 
  u.id,
  u.email,
  u.rol,
  u.fecha_registro,
  COUNT(us.id) AS total_sesiones,
  MAX(us.fecha) AS ultima_sesion,
  SUM(CASE WHEN us.completado = true THEN 1 ELSE 0 END) AS sesiones_completadas
FROM usuario u
LEFT JOIN usuariosesion us ON u.id = us.usuario_id
GROUP BY u.id, u.email, u.rol, u.fecha_registro;

-- ========================================================
-- DATOS DE EJEMPLO PARA PRUEBAS DEL DASHBOARD
-- ========================================================

-- Solo insertar si no hay datos de sesiones para no duplicar
INSERT INTO usuariosesion (fecha, resultado_x, resultado_y, completado, token)
SELECT NOW() - INTERVAL '1 day' * i, 
       (RANDOM() * 200 - 100)::NUMERIC(5,2), 
       (RANDOM() * 200 - 100)::NUMERIC(5,2), 
       true, 
       SUBSTRING(MD5(RANDOM()::TEXT), 1, 10)
FROM generate_series(1, 10) s(i)
WHERE NOT EXISTS (SELECT 1 FROM usuariosesion LIMIT 1)
ON CONFLICT DO NOTHING;
