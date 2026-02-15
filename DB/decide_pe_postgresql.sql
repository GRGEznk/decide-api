-- PostgreSQL Schema para Supabase
-- Convertido desde MySQL (decide_pe)
-- Compatible con PostgreSQL 14+

-- ============================================
-- TABLAS PRINCIPALES
-- ============================================

-- Tabla: region
CREATE TABLE IF NOT EXISTS region (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL
);

-- Tabla: partido
CREATE TABLE IF NOT EXISTS partido (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(50) NOT NULL UNIQUE,
  nombre_largo VARCHAR(100) NOT NULL UNIQUE,
  sigla VARCHAR(10)
);

CREATE INDEX idx_nombre_partido ON partido(nombre);


-- Tabla: partido_metadata
CREATE TABLE IF NOT EXISTS partido_metadata (
  id SERIAL PRIMARY KEY,
  partido_id INTEGER NOT NULL UNIQUE,
  candidato_presidencial VARCHAR(100),
  lider_partido VARCHAR(100),
  color_primario VARCHAR(7) DEFAULT '#000000',
  plan_gobierno VARCHAR(500),
  anio_fundacion INTEGER,
  anio_inscripcion_jne INTEGER,
  tipo_organizacion VARCHAR(50) DEFAULT 'Partido Político',
  CONSTRAINT fk_partido_metadata_partido FOREIGN KEY (partido_id) 
    REFERENCES partido(id) ON DELETE CASCADE
);


-- Tabla: candidato
CREATE TABLE IF NOT EXISTS candidato (
  id SERIAL PRIMARY KEY,
  nombres VARCHAR(100) NOT NULL,
  apellidos VARCHAR(100) NOT NULL,
  cargo VARCHAR(50) NOT NULL CHECK (cargo IN (
    'presidente',
    '1er vicepresidente',
    '2do vicepresidente',
    'diputado',
    'senador nacional',
    'senador regional',
    'parlamento andino'
  )),
  numero SMALLINT,
  id_region INTEGER DEFAULT 1,
  region VARCHAR(100),
  foto VARCHAR(500),
  hojavida VARCHAR(500),
  id_partido INTEGER NOT NULL,
  CONSTRAINT fk_candidato_partido FOREIGN KEY (id_partido) 
    REFERENCES partido(id) ON DELETE CASCADE
);

CREATE INDEX idx_cargo ON candidato(cargo);
CREATE INDEX idx_partido_candidato ON candidato(id_partido);

-- Tabla: pregunta
CREATE TABLE IF NOT EXISTS pregunta (
  id SERIAL PRIMARY KEY,
  texto TEXT NOT NULL,
  eje VARCHAR(1) NOT NULL CHECK (eje IN ('X', 'Y')),
  direccion SMALLINT NOT NULL CHECK (direccion IN (-1, 1)),
  estado VARCHAR(10) DEFAULT 'activa' CHECK (estado IN ('activa', 'inactiva')),
  categoria VARCHAR(50)
);

CREATE INDEX idx_eje ON pregunta(eje);
CREATE INDEX idx_estado ON pregunta(estado);
CREATE INDEX idx_categoria ON pregunta(categoria);

-- Tabla: partidorespuesta
CREATE TABLE IF NOT EXISTS partidorespuesta (
  partido_id INTEGER NOT NULL,
  pregunta_id INTEGER NOT NULL,
  valor SMALLINT NOT NULL CHECK (valor IN (-2, -1, 0, 1, 2)),
  fuente VARCHAR(500),
  PRIMARY KEY (partido_id, pregunta_id),
  CONSTRAINT fk_partidoresp_partido FOREIGN KEY (partido_id) 
    REFERENCES partido(id) ON DELETE CASCADE,
  CONSTRAINT fk_partidoresp_pregunta FOREIGN KEY (pregunta_id) 
    REFERENCES pregunta(id) ON DELETE CASCADE
);

CREATE INDEX idx_pregunta_partidoresp ON partidorespuesta(pregunta_id);

-- Tabla: partidoposicioncache
CREATE TABLE IF NOT EXISTS partidoposicioncache (
  partido_id INTEGER PRIMARY KEY,
  posicion_x NUMERIC(5,2),
  posicion_y NUMERIC(5,2),
  fecha_calculo TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT fk_posicion_partido FOREIGN KEY (partido_id) 
    REFERENCES partido(id) ON DELETE CASCADE
);

CREATE INDEX idx_posicion_x ON partidoposicioncache(posicion_x);
CREATE INDEX idx_posicion_y ON partidoposicioncache(posicion_y);

-- Tabla: usuario
CREATE TABLE IF NOT EXISTS usuario (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  rol VARCHAR(10) DEFAULT 'user' CHECK (rol IN ('user', 'admin')),
  fecha_registro TIMESTAMPTZ NOT NULL DEFAULT now(),
  nombre VARCHAR(100) NOT NULL DEFAULT 'Usuario'
);

CREATE INDEX idx_email ON usuario(email);
CREATE INDEX idx_rol ON usuario(rol);

-- Tabla: usuariosesion
CREATE TABLE IF NOT EXISTS usuariosesion (
  id SERIAL PRIMARY KEY,
  fecha TIMESTAMPTZ NOT NULL DEFAULT now(),
  resultado_x NUMERIC(5,2),
  resultado_y NUMERIC(5,2),
  completado BOOLEAN DEFAULT false,
  token VARCHAR(12) UNIQUE,
  usuario_id INTEGER,
  CONSTRAINT fk_sesion_usuario FOREIGN KEY (usuario_id) 
    REFERENCES usuario(id) ON DELETE SET NULL
);

CREATE INDEX idx_usuario_sesion ON usuariosesion(usuario_id);
CREATE INDEX idx_fecha_sesion ON usuariosesion(fecha);
CREATE INDEX idx_completado ON usuariosesion(completado);

-- Tabla: usuariorespuesta
CREATE TABLE IF NOT EXISTS usuariorespuesta (
  sesion_id INTEGER NOT NULL,
  pregunta_id INTEGER NOT NULL,
  valor SMALLINT NOT NULL CHECK (valor IN (-2, -1, 0, 1, 2)),
  fecha_respuesta TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (sesion_id, pregunta_id),
  CONSTRAINT fk_usuarioresp_sesion FOREIGN KEY (sesion_id) 
    REFERENCES usuariosesion(id) ON DELETE CASCADE,
  CONSTRAINT fk_usuarioresp_pregunta FOREIGN KEY (pregunta_id) 
    REFERENCES pregunta(id) ON DELETE CASCADE
);

CREATE INDEX idx_sesion ON usuariorespuesta(sesion_id);
CREATE INDEX idx_pregunta_usuarioresp ON usuariorespuesta(pregunta_id);
CREATE INDEX idx_fecha_respuesta ON usuariorespuesta(fecha_respuesta);

-- ============================================
-- DATOS INICIALES
-- ============================================

-- Datos: region
INSERT INTO region (id, nombre) VALUES
(1, 'No Aplica'),
(2, 'Lima Metropolitana'),
(3, 'Callao');

-- Datos: partido
INSERT INTO partido (id, nombre, nombre_largo, sigla) VALUES
(2, 'AHORA NACION', 'Ahora Nación', 'AN'),
(9, 'FUERZA POPULAR', 'Fuerza Popular', 'FP'),
(12, 'LIBERTAD POPULAR', 'Libertad Popular', 'LP'),
(34, 'VOCES DEL PUEBLO', 'Partido Político Voces del Pueblo', 'VP'),
(41, 'PRIMERO LA GENTE', 'Primero la Gente - Comunidad, Ecología, Libertad y Progreso', 'PLG'),
(43, 'RENOVACION POPULAR', 'Renovación Popular', 'RP');

-- Datos: partido_metadata (sin logo_key ni candidato_key, con plan_gobierno)
INSERT INTO partido_metadata (id, partido_id, candidato_presidencial, lider_partido, color_primario, plan_gobierno, anio_fundacion, anio_inscripcion_jne, tipo_organizacion) VALUES
(2, 2, 'Alfonso Lopez Chau', 'Alfonso Lopez Chau', '#eb0206', NULL, NULL, NULL, 'Partido Político'),
(9, 9, 'Keiko Fujimori', 'Keiko Fujimori', '#eb6d00', NULL, NULL, NULL, 'Partido Político'),
(12, 12, 'Rafael Belaúnde Llosa', 'Rafael Belaúnde Llosa', '#ffff01', NULL, NULL, NULL, 'Partido Político'),
(34, 34, 'Ronald Atencio', 'Guillermo Bermejo', '#d90736', NULL, NULL, NULL, 'Partido Político'),
(41, 41, 'Marisol Pérez Tello', 'Manuel Ato Carrera', '#2252a7', NULL, NULL, NULL, 'Partido Político'),
(43, 43, 'Rafael López Aliaga', 'Rafael López Aliaga', '#049ad7', NULL, NULL, NULL, 'Partido Político');

-- Datos: candidato
INSERT INTO candidato (id, nombres, apellidos, cargo, numero, id_region, region, foto, hojavida, id_partido) VALUES
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

-- Datos: pregunta
INSERT INTO pregunta (id, texto, eje, direccion, estado, categoria) VALUES
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

-- Datos: partidorespuesta (respuestas de partidos a preguntas)
INSERT INTO partidorespuesta (partido_id, pregunta_id, valor, fuente) VALUES
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
(43, 8, 2, 'Eso es ser blando con criminales, necesitamos cárceles de máxima seguridad y cadena perpetua'),
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

-- Datos: partidoposicioncache (posiciones calculadas)
INSERT INTO partidoposicioncache (partido_id, posicion_x, posicion_y, fecha_calculo) VALUES
(2, -30.00, -52.78, '2026-02-04 00:00:00'),
(9, 37.50, 0.00, '2026-02-04 02:38:57'),
(12, 60.00, 50.00, '2026-02-04 00:00:00'),
(34, 0.00, 0.00, '2026-02-04 00:00:00'),
(41, -10.00, -40.00, '2026-02-04 00:00:00'),
(43, 77.78, -36.36, '2026-02-04 02:47:03');


-- ============================================
-- FUNCIONES Y PROCEDIMIENTOS
-- ============================================

-- Función: Calcular Posición de Partido
CREATE OR REPLACE FUNCTION calcular_posicion_partido(p_partido_id INTEGER)
RETURNS void AS $$
DECLARE
  total_x NUMERIC(10,2);
  total_y NUMERIC(10,2);
  count_x INTEGER;
  count_y INTEGER;
  pos_x NUMERIC(5,2);
  pos_y NUMERIC(5,2);
BEGIN
  -- Calcular sumas y conteos por eje (EXCLUYENDO valor 0)
  SELECT 
    SUM(CASE WHEN p.eje = 'X' THEN pr.valor * p.direccion ELSE 0 END),
    SUM(CASE WHEN p.eje = 'Y' THEN pr.valor * p.direccion ELSE 0 END),
    SUM(CASE WHEN p.eje = 'X' AND pr.valor != 0 THEN 1 ELSE 0 END),
    SUM(CASE WHEN p.eje = 'Y' AND pr.valor != 0 THEN 1 ELSE 0 END)
  INTO total_x, total_y, count_x, count_y
  FROM partidorespuesta pr
  JOIN pregunta p ON pr.pregunta_id = p.id
  WHERE pr.partido_id = p_partido_id AND p.estado = 'activa';
  
  -- Factor 2: (Valor_Max / 2) * 100 = 100
  pos_x := (COALESCE(total_x, 0) / (GREATEST(1, COALESCE(count_x, 0)) * 2)) * 100;
  pos_y := (COALESCE(total_y, 0) / (GREATEST(1, COALESCE(count_y, 0)) * 2)) * 100;
  
  -- Asegurar límites -100 a +100
  pos_x := GREATEST(-100, LEAST(100, pos_x));
  pos_y := GREATEST(-100, LEAST(100, pos_y));
  
  -- Insertar o actualizar
  INSERT INTO partidoposicioncache (partido_id, posicion_x, posicion_y, fecha_calculo)
  VALUES (p_partido_id, pos_x, pos_y, now())
  ON CONFLICT (partido_id) 
  DO UPDATE SET 
    posicion_x = EXCLUDED.posicion_x,
    posicion_y = EXCLUDED.posicion_y,
    fecha_calculo = now();
END;
$$ LANGUAGE plpgsql;

-- Función: Calcular Posición de Usuario
CREATE OR REPLACE FUNCTION calcular_posicion_usuario(p_sesion_id INTEGER)
RETURNS void AS $$
DECLARE
  total_x NUMERIC(10,2);
  total_y NUMERIC(10,2);
  count_x INTEGER;
  count_y INTEGER;
  pos_x NUMERIC(5,2);
  pos_y NUMERIC(5,2);
  v_token VARCHAR(12);
  v_exists INTEGER;
BEGIN
  -- Calcular sumas y conteos por eje
  SELECT 
    SUM(CASE WHEN p.eje = 'X' THEN ur.valor * p.direccion ELSE 0 END),
    SUM(CASE WHEN p.eje = 'Y' THEN ur.valor * p.direccion ELSE 0 END),
    SUM(CASE WHEN p.eje = 'X' AND ur.valor != 0 THEN 1 ELSE 0 END),
    SUM(CASE WHEN p.eje = 'Y' AND ur.valor != 0 THEN 1 ELSE 0 END)
  INTO total_x, total_y, count_x, count_y
  FROM usuariorespuesta ur
  JOIN pregunta p ON ur.pregunta_id = p.id
  WHERE ur.sesion_id = p_sesion_id AND p.estado = 'activa';
  
  pos_x := (COALESCE(total_x, 0) / (GREATEST(1, COALESCE(count_x, 0)) * 2)) * 100;
  pos_y := (COALESCE(total_y, 0) / (GREATEST(1, COALESCE(count_y, 0)) * 2)) * 100;
  
  -- Generar token único de 10 caracteres
  LOOP
    v_token := SUBSTRING(MD5(RANDOM()::TEXT), 1, 10);
    SELECT COUNT(*) INTO v_exists FROM usuariosesion WHERE token = v_token;
    EXIT WHEN v_exists = 0;
  END LOOP;
  
  -- Actualizar sesión
  UPDATE usuariosesion 
  SET 
    resultado_x = GREATEST(-100, LEAST(100, pos_x)),
    resultado_y = GREATEST(-100, LEAST(100, pos_y)),
    completado = true,
    token = v_token
  WHERE id = p_sesion_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger Function: Actualizar posición partido
CREATE OR REPLACE FUNCTION trigger_actualizar_posicion_partido()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM calcular_posicion_partido(OLD.partido_id);
    RETURN OLD;
  ELSE
    PERFORM calcular_posicion_partido(NEW.partido_id);
    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Triggers para partidorespuesta
DROP TRIGGER IF EXISTS actualizar_posicion_partido_insert ON partidorespuesta;
CREATE TRIGGER actualizar_posicion_partido_insert
  AFTER INSERT ON partidorespuesta
  FOR EACH ROW
  EXECUTE FUNCTION trigger_actualizar_posicion_partido();

DROP TRIGGER IF EXISTS actualizar_posicion_partido_update ON partidorespuesta;
CREATE TRIGGER actualizar_posicion_partido_update
  AFTER UPDATE ON partidorespuesta
  FOR EACH ROW
  EXECUTE FUNCTION trigger_actualizar_posicion_partido();

DROP TRIGGER IF EXISTS actualizar_posicion_partido_delete ON partidorespuesta;
CREATE TRIGGER actualizar_posicion_partido_delete
  AFTER DELETE ON partidorespuesta
  FOR EACH ROW
  EXECUTE FUNCTION trigger_actualizar_posicion_partido();

-- Trigger Function: Actualizar posición usuario
CREATE OR REPLACE FUNCTION trigger_actualizar_posicion_usuario()
RETURNS TRIGGER AS $$
DECLARE
  total_resp INTEGER;
  total_preg INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_resp FROM usuariorespuesta WHERE sesion_id = NEW.sesion_id;
  SELECT COUNT(*) INTO total_preg FROM pregunta WHERE estado = 'activa';
  
  IF total_resp >= total_preg THEN
    PERFORM calcular_posicion_usuario(NEW.sesion_id);
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para usuariorespuesta
DROP TRIGGER IF EXISTS actualizar_posicion_usuario ON usuariorespuesta;
CREATE TRIGGER actualizar_posicion_usuario
  AFTER INSERT ON usuariorespuesta
  FOR EACH ROW
  EXECUTE FUNCTION trigger_actualizar_posicion_usuario();

-- ============================================
-- VISTAS
-- ============================================

-- Vista: Estadísticas Quiz
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

-- Vista: Estadísticas Preguntas
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
GROUP BY p.id;

-- Vista: Actividad Usuarios
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
GROUP BY u.id;

-- ============================================
-- COMENTARIOS
-- ============================================

COMMENT ON TABLE candidato IS 'Candidatos de los partidos políticos';
COMMENT ON COLUMN candidato.foto IS 'URL de la foto del candidato';
COMMENT ON COLUMN candidato.hojavida IS 'URL de la hoja de vida';

COMMENT ON TABLE partidoposicioncache IS 'Cache de posiciones calculadas de partidos en el espectro político';
COMMENT ON COLUMN partidoposicioncache.posicion_x IS 'Posición en eje X: -100 (izquierda) a +100 (derecha)';
COMMENT ON COLUMN partidoposicioncache.posicion_y IS 'Posición en eje Y: -100 (libertario) a +100 (autoritario)';

COMMENT ON TABLE usuariosesion IS 'Sesiones de quiz de usuarios (anónimos o registrados)';
COMMENT ON COLUMN usuariosesion.usuario_id IS 'NULL si es sesión anónima';
COMMENT ON COLUMN usuariosesion.token IS 'Token único para compartir resultados';
