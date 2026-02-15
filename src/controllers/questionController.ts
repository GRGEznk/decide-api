import type { Request, Response } from 'express';
import { pgPool } from '../config/supabase';

export const getQuestions = async (req: Request, res: Response) => {
    try {
        const result = await pgPool.query('SELECT * FROM pregunta ORDER BY id DESC');
        res.json(result.rows);
    } catch (error) {
        console.error('Error al obtener preguntas:', error);
        res.status(500).json({ error: 'Error al obtener preguntas' });
    }
};

export const createQuestion = async (req: Request, res: Response) => {
    const { texto, eje, direccion, estado, categoria } = req.body;
    try {
        const result = await pgPool.query(
            'INSERT INTO pregunta (texto, eje, direccion, estado, categoria) VALUES ($1, $2, $3, $4, $5) RETURNING id',
            [texto, eje, direccion, estado, categoria]
        );
        const insertId = result.rows[0].id;
        res.status(201).json({ id: insertId, ...req.body });
    } catch (error) {
        console.error('Error al crear pregunta:', error);
        res.status(500).json({ error: 'Error al crear pregunta' });
    }
};

export const updateQuestion = async (req: Request, res: Response) => {
    const { id } = req.params;
    const { texto, eje, direccion, estado, categoria } = req.body;
    try {
        await pgPool.query(
            'UPDATE pregunta SET texto = $1, eje = $2, direccion = $3, estado = $4, categoria = $5 WHERE id = $6',
            [texto, eje, direccion, estado, categoria, id]
        );
        res.json({ id, ...req.body });
    } catch (error) {
        console.error('Error al actualizar pregunta:', error);
        res.status(500).json({ error: 'Error al actualizar pregunta' });
    }
};

export const deleteQuestion = async (req: Request, res: Response) => {
    const { id } = req.params;
    try {
        await pgPool.query('DELETE FROM pregunta WHERE id = $1', [id]);
        res.json({ message: 'Pregunta eliminada' });
    } catch (error) {
        console.error('Error al eliminar pregunta:', error);
        res.status(500).json({ error: 'Error al eliminar pregunta' });
    }
};
