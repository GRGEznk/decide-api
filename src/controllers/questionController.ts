import type { Request, Response } from 'express';
import { pool } from '../config/db';

export const getQuestions = async (req: Request, res: Response) => {
    try {
        const [rows] = await pool.query('SELECT * FROM Pregunta ORDER BY id DESC');
        res.json(rows);
    } catch (error) {
        console.error('Error al obtener preguntas:', error);
        res.status(500).json({ error: 'Error al obtener preguntas' });
    }
};

export const createQuestion = async (req: Request, res: Response) => {
    const { texto, eje, direccion, estado, categoria } = req.body;
    try {
        const [result] = await pool.query(
            'INSERT INTO Pregunta (texto, eje, direccion, estado, categoria) VALUES (?, ?, ?, ?, ?)',
            [texto, eje, direccion, estado, categoria]
        );
        const insertId = (result as any).insertId;
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
        await pool.query(
            'UPDATE Pregunta SET texto = ?, eje = ?, direccion = ?, estado = ?, categoria = ? WHERE id = ?',
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
        await pool.query('DELETE FROM Pregunta WHERE id = ?', [id]);
        res.json({ message: 'Pregunta eliminada' });
    } catch (error) {
        console.error('Error al eliminar pregunta:', error);
        res.status(500).json({ error: 'Error al eliminar pregunta' });
    }
};
