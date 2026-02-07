import type { Request, Response } from 'express';
import { pool } from '../config/db';
import type { RowDataPacket, ResultSetHeader } from 'mysql2';

export const startSession = async (req: Request, res: Response) => {
    try {
        const { usuario_id } = req.body;
        let validUserId = null;

        // Validar si el usuario existe antes de insertar (evita error de FK)
        if (usuario_id) {
            const [user] = await pool.query<RowDataPacket[]>(
                'SELECT id FROM usuario WHERE id = ?',
                [usuario_id]
            );
            if (user.length > 0) {
                validUserId = usuario_id;
            } else {
                console.warn(`Intento de inicio de sesión con usuario_id inexistente: ${usuario_id}. Se procede como anónimo.`);
            }
        }

        const [result] = await pool.query(
            'INSERT INTO UsuarioSesion (usuario_id) VALUES (?)',
            [validUserId]
        );
        const insertId = (result as ResultSetHeader).insertId;

        res.status(201).json({
            session_id: insertId,
            message: 'Sesión iniciada correctamente'
        });
    } catch (error: any) {
        console.error('Error al iniciar sesión de quiz:', error);
        res.status(500).json({
            error: 'Error al iniciar sesión',
            details: error.message
        });
    }
};

export const linkSessionWithUser = async (req: Request, res: Response) => {
    try {
        const { session_id, usuario_id } = req.body;

        if (!session_id || !usuario_id) {
            return res.status(400).json({ error: 'Faltan parámetros' });
        }

        // Determinar si session_id es un ID numérico o un token
        const idStr = String(session_id);
        const isNumeric = /^\d+$/.test(idStr);

        // 1. Verificar si la sesión existe y es anónima
        let query = 'SELECT usuario_id FROM UsuarioSesion WHERE ';
        query += isNumeric ? 'id = ?' : 'token = ?';

        const [sessionRows] = await pool.query<RowDataPacket[]>(query, [idStr]);

        if (sessionRows.length === 0) {
            return res.status(404).json({ error: 'Sesión no encontrada' });
        }

        if (sessionRows[0] && sessionRows[0].usuario_id !== null) {
            return res.status(400).json({ error: 'La sesión ya está vinculada a un usuario' });
        }

        // 2. Vincular (usamos la misma lógica de búsqueda para el UPDATE)
        let updateQuery = 'UPDATE UsuarioSesion SET usuario_id = ? WHERE ';
        updateQuery += isNumeric ? 'id = ?' : 'token = ?';
        
        await pool.query(updateQuery, [usuario_id, idStr]);

        res.json({ message: 'Sesión vinculada correctamente' });

    } catch (error: any) {
        console.error('Error al vincular sesión:', error);
        res.status(500).json({ error: 'Error al vincular sesión' });
    }
};

export const saveAnswers = async (req: Request, res: Response) => {
    try {
        const { session_id, answers } = req.body; // respuesta

        if (!session_id || !Array.isArray(answers)) {
            return res.status(400).json({ error: 'Datos inválidos' });
        }

        const connection = await pool.getConnection();

        try {
            await connection.beginTransaction();

            for (const ans of answers) {
                const { pregunta_id, valor } = ans;

                // validar rango
                if (valor < -2 || valor > 2) {
                    throw new Error(`Valor inválido para pregunta ${pregunta_id}: ${valor}`);
                }

                await connection.query(
                    'INSERT INTO UsuarioRespuesta (sesion_id, pregunta_id, valor) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE valor = VALUES(valor)',
                    [session_id, pregunta_id, valor]
                );
            }

            // Forzar cálculo de resultados
            await connection.query('CALL CalcularPosicionUsuario(?)', [session_id]);

            await connection.commit();
            res.json({ message: 'Respuestas guardadas y resultados calculados' });

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

        if (!id) return res.status(400).json({ error: 'ID no proporcionado' });

        const idStr = String(id);
        const isNumeric = /^\d+$/.test(idStr);

        let query = 'SELECT * FROM UsuarioSesion WHERE ';
        query += isNumeric ? 'id = ?' : 'token = ?';

        const [rows] = await pool.query<RowDataPacket[]>(query, [idStr]);

        if (rows.length === 0 || !rows[0]) {
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
