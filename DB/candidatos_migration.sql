-- Migración de Candidatos: MySQL a PostgreSQL (Supabase)
-- Fecha: 14-02-2026

BEGIN;

-- 1. Limpiar datos existentes (Opcional, pero recomendado si quieres datos frescos)
-- TRUNCATE TABLE candidato CASCADE;

-- 2. Insertar candidatos con el formato de PostgreSQL
INSERT INTO candidato (id, nombres, apellidos, cargo, numero, id_region, foto, hojavida, id_partido) VALUES
(1, 'PABLO ALFONSO', 'LOPEZ CHAU NAVA', 'presidente', NULL, 1, 'https://mpesije.jne.gob.pe/apidocs/ddfa74eb-cae3-401c-a34c-35543ae83c57.jpg', 'https://mpesije.jne.gob.pe/apidocs/4ba2cdce-703e-421b-8b75-746b4dd21439.pdf', 2),
(2, 'Keiko', 'Fujimori', 'presidente', NULL, 1, NULL, NULL, 9),
(3, 'RAFAEL JORGE', 'BELAUNDE LLOSA', 'presidente', NULL, 1, 'https://mpesije.jne.gob.pe/apidocs/3302e45b-55c8-4979-a60b-2b11097abf1d.jpg', 'https://mpesije.jne.gob.pe/apidocs/74eadffc-2e05-4054-b113-a010d3c4de6c.pdf', 12),
(4, 'Ronald', 'Atencio', 'presidente', NULL, 1, 'https://mpesije.jne.gob.pe/apidocs/bac0288d-3b21-45ac-8849-39f9177fb020.jpg', 'https://mpesije.jne.gob.pe/apidocs/f589c135-2e56-4b5c-8359-a3749190c8ab.pdf', 34),
(5, 'Marisol', 'Pérez Tello', 'presidente', NULL, 1, 'https://mpesije.jne.gob.pe/apidocs/073703ca-c427-44f0-94b1-a782223a5e10.jpg', 'https://mpesije.jne.gob.pe/apidocs/8f27eca5-63d1-4c5f-bd71-fbb5d544891e.pdf', 41),
(6, 'Rafael', 'López Aliaga', 'presidente', NULL, 1, 'https://mpesije.jne.gob.pe/apidocs/b2e00ae2-1e50-4ad3-a103-71fc7e4e8255.jpg', 'https://mpesije.jne.gob.pe/apidocs/3d7498fe-7a54-4f7d-882e-c5cdfd2ba26b.pdf', 43),
(7, 'LUIS ALBERTO', 'VILLANUEVA CARBAJAL', '1er vicepresidente', NULL, 1, 'https://mpesije.jne.gob.pe/apidocs/41377696-3376-4806-b0eb-87145ffa0bac.jpg', 'https://mpesije.jne.gob.pe/apidocs/91e58256-60be-485f-b75b-0f3c99472b2a.pdf', 2),
(8, 'RUTH ZENAIDA', 'BUENDIA MESTOQUIARI', '2do vicepresidente', NULL, 1, 'https://mpesije.jne.gob.pe/apidocs/bb54fed8-ee8d-4557-93cf-c3da557f4766.jpg', 'https://mpesije.jne.gob.pe/apidocs/98d47d3f-0bb8-49f9-a872-600adc55306c.pdf', 2),
(9, 'LUIS FERNANDO', 'GALARRETA VELARDE', '1er vicepresidente', NULL, 1, NULL, 'https://mpesije.jne.gob.pe/apidocs/ba40250f-5762-4f4f-a156-747e54440e5b.pdf', 9),
(10, 'MIGUEL ANGEL', 'TORRES MORALES', '2do vicepresidente', NULL, 1, NULL, 'https://mpesije.jne.gob.pe/apidocs/99872797-b3bf-452e-939b-06d1cdeaa917.pdf', 9),
(11, 'PEDRO ALVARO', 'CATERIANO BELLIDO', '1er vicepresidente', NULL, 1, 'https://mpesije.jne.gob.pe/apidocs/8c2fed85-3a83-4227-80b8-6df2ae5627c9.jpg', 'https://mpesije.jne.gob.pe/apidocs/af2bf963-af2a-40dd-b7be-0c3f49072158.pdf', 12),
(12, 'TANIA ULRIKA', 'PORLES BAZALAR', '2do vicepresidente', NULL, 1, 'https://mpesije.jne.gob.pe/apidocs/0e26188d-ad29-40db-8472-b744e6868485.jpg', 'https://mpesije.jne.gob.pe/apidocs/6290b676-2758-462e-9eff-6511b6532f00.pdf', 12),
(13, 'HARVEY JULIO', 'COLCHADO HUAMANI', 'diputado', 1, 2, 'https://mpesije.jne.gob.pe/apidocs/aaf42d15-51c4-42da-970a-27fc9722d258.jpg', 'https://mpesije.jne.gob.pe/apidocs/c385533c-6800-49cc-a5dd-bc890f9e6f0e.pdf', 2),
(14, 'INDIRA ISABEL', 'HUILCA FLORES', 'diputado', 2, 2, 'https://mpesije.jne.gob.pe/apidocs/00a34212-f067-4014-be90-c9a48610b7d1.jpg', 'https://mpesije.jne.gob.pe/apidocs/df68e47e-04af-4dfe-b08d-ce5fa2659ae8.pdf', 2),
(15, 'JOSEPH ELIAS', 'DAGER ALVA', 'diputado', 23, 2, 'https://mpesije.jne.gob.pe/apidocs/61a51f93-7501-485c-afe1-6a0325129b3a.jpg', 'https://mpesije.jne.gob.pe/apidocs/33359c37-3017-453d-bceb-395a11697924.pdf', 2),
(16, 'ANITA MILEIDI', 'ABANTO VILLEGAS', 'diputado', 18, 2, 'https://mpesije.jne.gob.pe/apidocs/56f0e603-5a74-4730-bb7d-bdb19b3b4b9a.jpg', 'https://mpesije.jne.gob.pe/apidocs/c9949abb-c15f-4dda-9854-1df867564c03.pdf', 2),
(17, 'PABLO ALFONSO', 'LOPEZ CHAU NAVA', 'senador nacional', 1, 1, 'https://mpesije.jne.gob.pe/apidocs/ddfa74eb-cae3-401c-a34c-35543ae83c57.jpg', 'https://mpesije.jne.gob.pe/apidocs/4ba2cdce-703e-421b-8b75-746b4dd21439.pdf', 2),
(18, 'CARMEN PATRICIA', 'CORREA ARANGOITIA', 'senador nacional', 2, 1, 'https://mpesije.jne.gob.pe/apidocs/9e7eb87d-dc10-40c3-86d9-3531eb44bc2e.jpg', 'https://mpesije.jne.gob.pe/apidocs/e110561f-e2cc-4b2b-94db-d6c7e8544059.pdf', 2),
(19, 'LUIS ALBERTO', 'VILLANUEVA CARBAJAL', 'senador nacional', 3, 1, 'https://mpesije.jne.gob.pe/apidocs/41377696-3376-4806-b0eb-87145ffa0bac.jpg', 'https://mpesije.jne.gob.pe/apidocs/91e58256-60be-485f-b75b-0f3c99472b2a.pdf', 2),
(20, 'MIRTHA ESTHER', 'VASQUEZ CHUQUILIN', 'senador nacional', 4, 1, 'https://mpesije.jne.gob.pe/apidocs/83aa4be4-54a0-4f96-874a-96ec34678843.jpg', 'https://mpesije.jne.gob.pe/apidocs/26df0361-db17-47af-85bf-fc1e8ae1329b.pdf', 2),
(21, 'JAIME RICARDO', 'DELGADO ZEGARRA', 'senador nacional', 5, 1, 'https://mpesije.jne.gob.pe/apidocs/9aee4b33-103e-4327-9038-3618515d950d.jpg', 'https://mpesije.jne.gob.pe/apidocs/52cef747-829f-4b40-947f-dffb8bc9fcce.pdf', 2),
(22, 'RUTH ', 'LUQUE IBARRA', 'senador nacional', 8, 1, 'https://mpesije.jne.gob.pe/apidocs/428c14a1-1be6-477e-b02a-f0dec2dc8e65.jpg', 'https://mpesije.jne.gob.pe/apidocs/ed569772-6440-41f6-a1ad-b62d373d92ef.pdf', 2),
(23, 'JOSE GUILLERMO', 'RAMOS', 'parlamento andino', 1, 1, 'https://mpesije.jne.gob.pe/apidocs/9dde8342-7644-4720-be40-5ec40f313c16.jpg', 'https://mpesije.jne.gob.pe/apidocs/debd813a-2ced-4211-ad32-5e1357aac48c.pdf', 2),
(24, 'YESENIA ANGELITA', 'MAMANI ZAPATA', 'parlamento andino', 2, 1, 'https://mpesije.jne.gob.pe/apidocs/892b3d3b-f56b-4b95-a053-f3ea54685e5f.jpg', 'https://mpesije.jne.gob.pe/apidocs/8304ffd6-6363-4601-88b3-ee6b138bfdd1.pdf', 2),
(25, 'MARIA CECILIA GEORGINA ESPERANZA', 'ISRAEL LA ROSA', 'senador regional', 1, 2, 'https://mpesije.jne.gob.pe/apidocs/1ddf4b44-4de4-48b8-911c-1242c4fb34cd.jpg', 'https://mpesije.jne.gob.pe/apidocs/65ce131e-b3ad-4a54-ab9a-e7a138741ed3.pdf', 2),
(26, 'LUIS ALBERTO', 'ZULOAGA ROTTA', 'senador regional', 2, 2, 'https://mpesije.jne.gob.pe/apidocs/37f9c120-d838-4534-8a1b-8d44611c6837.jpg', 'https://mpesije.jne.gob.pe/apidocs/f7861ea6-b770-4a7b-a9c5-313accf4e068.pdf', 2)
ON CONFLICT (id) DO UPDATE SET
    nombres = EXCLUDED.nombres,
    apellidos = EXCLUDED.apellidos,
    cargo = EXCLUDED.cargo,
    numero = EXCLUDED.numero,
    id_region = EXCLUDED.id_region,
    foto = EXCLUDED.foto,
    hojavida = EXCLUDED.hojavida,
    id_partido = EXCLUDED.id_partido;


-- 3. Sincronizar la secuencia del ID (para evitar errores en inserts manuales futuros)
SELECT setval(pg_get_serial_sequence('candidato', 'id'), COALESCE(MAX(id), 1)) FROM candidato;

COMMIT;
