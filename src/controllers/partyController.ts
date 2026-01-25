import type { Request, Response } from 'express';
import { pool } from '../config/db';
import type { RowDataPacket } from 'mysql2';

export const getParties = async (req: Request, res: Response) => {
    try {
        const query = `
            SELECT 
                p.*,
                pm.candidato_presidencial,
                pm.lider_partido,
                pm.color_primario,
                pm.logo_key,
                pm.candidato_key,
                pm.anio_fundacion,
                pm.anio_inscripcion_jne,
                pm.tipo_organizacion
            FROM Partido p
            LEFT JOIN partido_metadata pm ON p.id = pm.partido_id
        `;
        const [rows] = await pool.query(query);
        res.json(rows);
    } catch (error) {
        console.error('Error al obtener partidos:', error);
        res.status(500).json({ error: 'Error al obtener partidos' });
    }
};

export const getPartyPositions = async (req: Request, res: Response) => {
    try {
        const query = `
      SELECT 
        p.id, 
        p.nombre, 
        p.sigla, 
        c.posicion_x, 
        c.posicion_y, 
        c.fecha_calculo,
        pm.logo_key,
        pm.color_primario
      FROM Partido p 
      JOIN PartidoPosicionCache c ON p.id = c.partido_id
      LEFT JOIN partido_metadata pm ON p.id = pm.partido_id
    `;
        const [rows] = await pool.query(query);
        res.json(rows);
    } catch (error) {
        console.error('Error al obtener posiciones:', error);
        res.status(500).json({ error: 'Error al obtener posiciones' });
    }
};

export const createParty = async (req: Request, res: Response) => {
    const connection = await pool.getConnection();
    try {
        const { 
            nombre, nombre_largo, sigla, // Campos tabla Partido
            candidato_presidencial, lider_partido, color_primario, logo_key, candidato_key, anio_fundacion, anio_inscripcion_jne, tipo_organizacion // Campos Metadata
        } = req.body;

        // Validaciones básicas
        if (!nombre || !nombre_largo || !sigla || !logo_key) {
            return res.status(400).json({ error: 'Campos requeridos: nombre, nombre_largo, sigla, logo_key' });
        }

        await connection.beginTransaction();

        // 1. Insertar Partido base
        const queryPartido = 'INSERT INTO Partido (nombre, nombre_largo, sigla) VALUES (?, ?, ?)';
        const [resultPartido]: any = await connection.query(queryPartido, [nombre, nombre_largo, sigla]);
        const partidoId = resultPartido.insertId;

        // 2. Insertar Metadatos
        const queryMeta = `
            INSERT INTO partido_metadata 
            (partido_id, candidato_presidencial, lider_partido, color_primario, logo_key, candidato_key, anio_fundacion, anio_inscripcion_jne, tipo_organizacion)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        `;
        
        await connection.query(queryMeta, [
            partidoId,
            candidato_presidencial || null,
            lider_partido || null,
            color_primario || '#000000',
            logo_key,
            candidato_key || 'DEFAULT_CANDIDATE',
            anio_fundacion || null,
            anio_inscripcion_jne || null,
            tipo_organizacion || 'Partido Político'
        ]);

        await connection.commit();

        res.status(201).json({
            message: 'Partido y metadatos creados exitosamente',
            id: partidoId,
            nombre,
            logo_key
        });

    } catch (error: any) {
        await connection.rollback();
        console.error('Error al crear partido:', error);
        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({ error: 'Ya existe un partido con ese nombre o identificador' });
        }
        res.status(500).json({ error: 'Error al crear el partido' });
    } finally {
        connection.release();
    }
};

export const updateParty = async (req: Request, res: Response) => {
    const connection = await pool.getConnection();
    try {
        const { id } = req.params;
        const { 
            nombre, nombre_largo, sigla,
            candidato_presidencial, lider_partido, color_primario, logo_key, candidato_key, anio_fundacion, anio_inscripcion_jne, tipo_organizacion 
        } = req.body;

        if (!nombre || !nombre_largo || !sigla || !logo_key) {
            return res.status(400).json({ error: 'Campos requeridos faltantes' });
        }

        await connection.beginTransaction();

        // 1. Actualizar tabla base
        const queryPartido = 'UPDATE Partido SET nombre = ?, nombre_largo = ?, sigla = ? WHERE id = ?';
        await connection.query(queryPartido, [nombre, nombre_largo, sigla, id]);

        // 2. Actualizar o Insertar (Upsert) Metadatos
        // Usamos ON DUPLICATE KEY UPDATE por si acaso el metadata no existía (para partidos viejos)
        const queryMeta = `
            INSERT INTO partido_metadata 
            (partido_id, candidato_presidencial, lider_partido, color_primario, logo_key, candidato_key, anio_fundacion, anio_inscripcion_jne, tipo_organizacion)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
            candidato_presidencial = VALUES(candidato_presidencial),
            lider_partido = VALUES(lider_partido),
            color_primario = VALUES(color_primario),
            logo_key = VALUES(logo_key),
            candidato_key = VALUES(candidato_key),
            anio_fundacion = VALUES(anio_fundacion),
            anio_inscripcion_jne = VALUES(anio_inscripcion_jne),
            tipo_organizacion = VALUES(tipo_organizacion)
        `;

        await connection.query(queryMeta, [
            id,
            candidato_presidencial || null,
            lider_partido || null,
            color_primario || '#000000',
            logo_key,
            candidato_key || 'DEFAULT_CANDIDATE',
            anio_fundacion || null,
            anio_inscripcion_jne || null,
            tipo_organizacion || 'Partido Político'
        ]);

        await connection.commit();

        res.json({
            message: 'Partido y metadatos actualizados exitosamente',
            id
        });

    } catch (error: any) {
        await connection.rollback();
        console.error('Error al actualizar partido:', error);
        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({ error: 'Conflicto de duplicados en nombre o sigla' });
        }
        res.status(500).json({ error: 'Error al actualizar el partido' });
    } finally {
        connection.release();
    }
};

export const deleteParty = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        await pool.query('DELETE FROM Partido WHERE id = ?', [id]);
        res.json({ message: 'Partido eliminado exitosamente' });
    } catch (error) {
        console.error('Error al eliminar partido:', error);
        res.status(500).json({ error: 'Error al eliminar el partido' });
    }
};

export const getPartyAnswers = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const query = `
            SELECT pregunta_id, valor, fuente 
            FROM PartidoRespuesta 
            WHERE partido_id = ?
        `;
        const [rows] = await pool.query(query, [id]);
        res.json(rows);
    } catch (error) {
        console.error('Error al obtener respuestas del partido:', error);
        res.status(500).json({ error: 'Error al obtener respuestas' });
    }
};

export const savePartyAnswers = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const { respuestas } = req.body; // Array of { pregunta_id, valor, fuente }

        if (!Array.isArray(respuestas)) {
            return res.status(400).json({ error: 'El formato de respuestas es inválido' });
        }

        const connection = await pool.getConnection();
        const partyId = parseInt(id as string);

        try {
            await connection.beginTransaction();

            for (const resp of respuestas) {
                const { pregunta_id, valor, fuente } = resp;

                // Validar rango -2 a +2
                if (valor < -2 || valor > 2) {
                    throw new Error(`Valor inválido para pregunta ${pregunta_id}: ${valor}`);
                }

                await connection.query(`
                    INSERT INTO PartidoRespuesta (partido_id, pregunta_id, valor, fuente)
                    VALUES (?, ?, ?, ?)
                    ON DUPLICATE KEY UPDATE valor = VALUES(valor), fuente = VALUES(fuente)
                `, [partyId, pregunta_id, valor, fuente || null]);
            }

            await connection.commit();
            res.json({ message: 'Respuestas guardadas exitosamente' });

        } catch (error) {
            await connection.rollback();
            throw error;
        } finally {
            connection.release();
        }

    } catch (error: any) {
        console.error('Error al guardar respuestas:', error);
        res.status(500).json({ error: error.message || 'Error al guardar respuestas' });
    }
};
