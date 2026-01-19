import type { Request, Response } from 'express';
import { pool } from '../config/db';
import type { RowDataPacket } from 'mysql2';

export const getParties = async (req: Request, res: Response) => {
    try {
        const [rows] = await pool.query('SELECT * FROM Partido');
        res.json(rows);
    } catch (error) {
        console.error('Error al obtener partidos:', error);
        res.status(500).json({ error: 'Error al obtener partidos' });
    }
};

export const getPartyPositions = async (req: Request, res: Response) => {
    try {
        const query = `
      SELECT p.id, p.nombre, p.sigla, c.posicion_x, c.posicion_y, c.fecha_calculo 
      FROM Partido p 
      JOIN PartidoPosicionCache c ON p.id = c.partido_id
    `;
        const [rows] = await pool.query(query);
        res.json(rows);
    } catch (error) {
        console.error('Error al obtener posiciones:', error);
        res.status(500).json({ error: 'Error al obtener posiciones' });
    }
};

export const createParty = async (req: Request, res: Response) => {
    try {
        const { nombre, nombre_largo, sigla } = req.body;

        // Validaciones
        if (!nombre || !nombre_largo || !sigla) {
            return res.status(400).json({ error: 'Todos los campos son requeridos' });
        }

        if (nombre.length > 50) {
            return res.status(400).json({ error: 'El nombre no puede exceder 50 caracteres' });
        }

        if (nombre_largo.length > 100) {
            return res.status(400).json({ error: 'El nombre largo no puede exceder 100 caracteres' });
        }

        if (sigla.length > 10) {
            return res.status(400).json({ error: 'La sigla no puede exceder 10 caracteres' });
        }

        // Insertar en la base de datos
        const query = 'INSERT INTO Partido (nombre, nombre_largo, sigla) VALUES (?, ?, ?)';
        const [result]: any = await pool.query(query, [nombre, nombre_largo, sigla]);

        res.status(201).json({
            message: 'Partido creado exitosamente',
            id: result.insertId,
            nombre,
            nombre_largo,
            sigla
        });
    } catch (error: any) {
        console.error('Error al crear partido:', error);

        // Manejar errores de duplicados
        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({ error: 'Ya existe un partido con ese nombre o nombre largo' });
        }

        res.status(500).json({ error: 'Error al crear el partido' });
    }
};

export const updateParty = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const { nombre, nombre_largo, sigla } = req.body;

        // Validaciones
        if (!nombre || !nombre_largo || !sigla) {
            return res.status(400).json({ error: 'Todos los campos son requeridos' });
        }

        if (nombre.length > 50) {
            return res.status(400).json({ error: 'El nombre no puede exceder 50 caracteres' });
        }

        if (nombre_largo.length > 100) {
            return res.status(400).json({ error: 'El nombre largo no puede exceder 100 caracteres' });
        }

        if (sigla.length > 10) {
            return res.status(400).json({ error: 'La sigla no puede exceder 10 caracteres' });
        }

        const query = 'UPDATE Partido SET nombre = ?, nombre_largo = ?, sigla = ? WHERE id = ?';
        await pool.query(query, [nombre, nombre_largo, sigla, id]);

        res.json({
            message: 'Partido actualizado exitosamente',
            id,
            nombre,
            nombre_largo,
            sigla
        });
    } catch (error: any) {
        console.error('Error al actualizar partido:', error);

        if (error.code === 'ER_DUP_ENTRY') {
            return res.status(409).json({ error: 'Ya existe un partido con ese nombre o nombre largo' });
        }

        res.status(500).json({ error: 'Error al actualizar el partido' });
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
