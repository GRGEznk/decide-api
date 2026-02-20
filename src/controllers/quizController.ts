import type { Request, Response } from 'express';
import { pgPool } from '../config/supabase';

export const startSession = async (req: Request, res: Response) => {
    try {
        const { usuario_id } = req.body;
        let validUserId = null;

        // Validar si el usuario existe antes de insertar (evita error de FK)
        if (usuario_id) {
            const user = await pgPool.query(
                'SELECT id FROM usuario WHERE id = $1',
                [usuario_id]
            );
            if (user.rows.length > 0) {
                validUserId = usuario_id;
            } else {
                console.warn(`Intento de inicio de sesión con usuario_id inexistente: ${usuario_id}. Se procede como anónimo.`);
            }
        }

        const result = await pgPool.query(
            'INSERT INTO usuariosesion (usuario_id) VALUES ($1) RETURNING id',
            [validUserId]
        );
        const insertId = result.rows[0].id;

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
        let query = 'SELECT usuario_id FROM usuariosesion WHERE ';
        query += isNumeric ? 'id = $1' : 'token = $1';

        const sessionResult = await pgPool.query(query, [idStr]);
        const sessionRows = sessionResult.rows;

        if (sessionRows.length === 0) {
            return res.status(404).json({ error: 'Sesión no encontrada' });
        }

        if (sessionRows[0] && sessionRows[0].usuario_id !== null) {
            return res.status(400).json({ error: 'La sesión ya está vinculada a un usuario' });
        }

        // 2. Vincular (usamos la misma lógica de búsqueda para el UPDATE)
        let updateQuery = 'UPDATE usuariosesion SET usuario_id = $1 WHERE ';
        updateQuery += isNumeric ? 'id = $2' : 'token = $2';
        
        await pgPool.query(updateQuery, [usuario_id, idStr]);

        res.json({ message: 'Sesión vinculada correctamente' });

    } catch (error: any) {
        console.error('Error al vincular sesión:', error);
        res.status(500).json({ error: 'Error al vincular sesión' });
    }
};

export const saveAnswers = async (req: Request, res: Response) => {
    const client = await pgPool.connect();
    try {
        const { session_id, answers } = req.body;

        if (!session_id || !Array.isArray(answers)) {
            return res.status(400).json({ error: 'Datos inválidos' });
        }

        await client.query('BEGIN');

        for (const ans of answers) {
            const { pregunta_id, valor } = ans;

            // validar rango
            if (valor < -2 || valor > 2) {
                throw new Error(`Valor inválido para pregunta ${pregunta_id}: ${valor}`);
            }

            await client.query(
                `INSERT INTO usuariorespuesta (sesion_id, pregunta_id, valor) 
                 VALUES ($1, $2, $3) 
                 ON CONFLICT (sesion_id, pregunta_id) 
                 DO UPDATE SET valor = EXCLUDED.valor`,
                [session_id, pregunta_id, valor]
            );
        }

        // El cálculo de resultados ya lo hace el trigger 'actualizar_posicion_usuario'
        // en PostgreSQL después de insertar todas las respuestas.
        // Solo llamar manualmente si es estrictamente necesario o para asegurar.
        await client.query('SELECT calcular_posicion_usuario($1::integer)', [session_id]);

        await client.query('COMMIT');
        res.json({ message: 'Respuestas guardadas y resultados calculados' });

    } catch (error: any) {
        await client.query('ROLLBACK');
        console.error('Error detallado al guardar respuestas:', error);
        res.status(500).json({ 
            error: 'Error al guardar respuestas', 
            details: error.message,
            hint: 'Verifica que la función calcular_posicion_usuario existe en Postgres'
        });
    } finally {
        client.release();
    }
};

export const getSession = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;

        if (!id) return res.status(400).json({ error: 'ID no proporcionado' });

        const idStr = String(id);
        const isNumeric = /^\d+$/.test(idStr);

        let query = 'SELECT * FROM usuariosesion WHERE ';
        query += isNumeric ? 'id = $1' : 'token = $1';

        const result = await pgPool.query(query, [idStr]);
        const rows = result.rows;

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
            FROM usuariosesion us
            LEFT JOIN usuario u ON us.usuario_id = u.id
            WHERE 1=1
        `;
        const params: any[] = [];
        let paramCount = 1;

        if (completado !== undefined && completado !== '') {
            query += ` AND us.completado = $${paramCount++}`;
            params.push(completado === '1' ? 1 : 0);
        }

        if (fecha_inicio) {
            query += ` AND us.fecha >= $${paramCount++}`;
            params.push(fecha_inicio);
        }

        if (fecha_fin) {
            query += ` AND us.fecha <= $${paramCount++}`;
            params.push(`${fecha_fin} 23:59:59`);
        }

        if (usuario_id) {
            if (usuario_id === 'null') {
                query += ' AND us.usuario_id IS NULL';
            } else {
                query += ` AND us.usuario_id = $${paramCount++}`;
                params.push(usuario_id);
            }
        }

        query += ' ORDER BY us.fecha DESC';

        const result = await pgPool.query(query, params);
        res.json(result.rows);
    } catch (error) {
        console.error('Error al obtener sesiones:', error);
        res.status(500).json({ error: 'Error al obtener sesiones' });
    }
};
