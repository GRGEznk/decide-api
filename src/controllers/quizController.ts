import type { Request, Response } from 'express';
import { pool } from '../config/db';
import type { RowDataPacket, ResultSetHeader } from 'mysql2';

export const startSession = async (req: Request, res: Response) => {
    try {
        const { usuario_id } = req.body; // null si es anónimo

        const [result] = await pool.query(
            'INSERT INTO UsuarioSesion (usuario_id) VALUES (?)',
            [usuario_id || null]
        );
        const insertId = (result as ResultSetHeader).insertId;

        res.status(201).json({
            session_id: insertId,
            message: 'Sesión iniciada correctamente'
        });
    } catch (error) {
        console.error('Error al iniciar sesión de quiz:', error);
        res.status(500).json({ error: 'Error al iniciar sesión' });
    }
};

export const saveAnswers = async (req: Request, res: Response) => {
    try {
        const { session_id, answers } = req.body; // answers: [{ pregunta_id, valor }]

        if (!session_id || !Array.isArray(answers)) {
            return res.status(400).json({ error: 'Datos inválidos' });
        }

        const connection = await pool.getConnection();

        try {
            await connection.beginTransaction();

            for (const ans of answers) {
                const { pregunta_id, valor } = ans;

                // validar rango de valores -2 a +2
                if (valor < -2 || valor > 2) {
                    throw new Error(`Valore inváildo para pregunta ${pregunta_id}: ${valor}`);
                }

                await connection.query(
                    'INSERT INTO UsuarioRespuesta (sesion_id, pregunta_id, valor) VALUES (?, ?, ?)',
                    [session_id, pregunta_id, valor]
                );
            }

            // el trigger 'actualizar_posicion_usuario' calculará automáticamente los resultados
            // si se proporcionan suficientes respuestas.

            await connection.commit();
            res.json({ message: 'Respuestas guardadas' });

        } catch (error: any) {
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

export const getSession = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;

        const [rows] = await pool.query<RowDataPacket[]>(
            'SELECT * FROM UsuarioSesion WHERE id = ?',
            [id]
        );

        if (rows.length === 0) {
            return res.status(404).json({ error: 'Sesión no encontrada' });
        }

        res.json(rows[0]);
    } catch (error) {
        console.error('Error al obtener sesión:', error);
        res.status(500).json({ error: 'Error al obtener sesión' });
    }
};

export const getAllSessions = async (req: Request, res: Response) => {
    try {
        const { completado, fecha_inicio, fecha_fin, usuario_id } = req.query;

        let query = `
            SELECT 
                us.*, 
                u.nombre as usuario_nombre,
                u.email as usuario_email
            FROM UsuarioSesion us
            LEFT JOIN usuario u ON us.usuario_id = u.id
            WHERE 1=1
        `;
        const params: any[] = [];

        if (completado !== undefined && completado !== '') {
            query += ' AND us.completado = ?';
            params.push(completado === '1' ? 1 : 0);
        }

        if (fecha_inicio) {
            query += ' AND us.fecha >= ?';
            params.push(fecha_inicio);
        }

        if (fecha_fin) {
            query += ' AND us.fecha <= ?';
            params.push(`${fecha_fin} 23:59:59`);
        }

        if (usuario_id) {
            if (usuario_id === 'null') {
                query += ' AND us.usuario_id IS NULL';
            } else {
                query += ' AND us.usuario_id = ?';
                params.push(usuario_id);
            }
        }

        query += ' ORDER BY us.fecha DESC';

        const [rows] = await pool.query<RowDataPacket[]>(query, params);
        res.json(rows);
    } catch (error) {
        console.error('Error al obtener sesiones:', error);
        res.status(500).json({ error: 'Error al obtener sesiones' });
    }
};
