import { Request, Response } from 'express';
import { pool } from '../config/db';

export const getStats = async (req: Request, res: Response) => {
    try {
        const [usuarios] = await pool.query('SELECT COUNT(*) as total FROM Usuario');
        const [preguntas] = await pool.query('SELECT COUNT(*) as total FROM Pregunta');
        const [partidos] = await pool.query('SELECT COUNT(*) as total FROM Partido');

        res.json({
            usuarios: (usuarios as any)[0].total,
            preguntas: (preguntas as any)[0].total,
            partidos: (partidos as any)[0].total
        });
    } catch (error) {
        console.error('Error al obtener estadísticas:', error);
        res.status(500).json({ error: 'Error al obtener estadísticas' });
    }
};
