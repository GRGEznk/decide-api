import type { Request, Response } from 'express';
import { pool } from '../config/db';

export const getStats = async (req: Request, res: Response) => {
    try {
        // 1. Basic Counters
        const [usuarios] = await pool.query('SELECT COUNT(*) as total FROM Usuario');
        const [preguntas] = await pool.query('SELECT COUNT(*) as total FROM Pregunta WHERE estado = "activa"');
        const [partidos] = await pool.query('SELECT COUNT(*) as total FROM Partido');

        // 2. Quiz Statistics (Conversion Rate & Totals)
        const [quizStats] = await pool.query(`
            SELECT 
                SUM(completadas) as total_completados, 
                SUM(total_sesiones) as total_iniciados,
                AVG(promedio_x) as prom_x,
                AVG(promedio_y) as prom_y
            FROM vistaestadisticasquiz
        `);

        // 3. Activity Chart Data (Last 30 days)
        const [activityData] = await pool.query(`
            SELECT fecha, total_sesiones, completadas 
            FROM vistaestadisticasquiz 
            ORDER BY fecha DESC 
            LIMIT 30
        `);

        // 4. Political Compass Scatter Data (Completed Sessions)
        const [scatterData] = await pool.query(`
            SELECT resultado_x as x, resultado_y as y 
            FROM UsuarioSesion 
            WHERE completado = 1 
            ORDER BY fecha DESC 
            LIMIT 500
        `);

        // 5. Top Questions by Engagement
        const [topQuestions] = await pool.query(`
            SELECT texto, total_respuestas 
            FROM vistapreguntasestadisticas 
            ORDER BY total_respuestas DESC 
            LIMIT 5
        `);

        res.json({
            kpi: {
                usuarios: (usuarios as any)[0].total,
                preguntas_activas: (preguntas as any)[0].total,
                partidos: (partidos as any)[0].total,
                tests_completados: (quizStats as any)[0].total_completados || 0,
                tests_iniciados: (quizStats as any)[0].total_iniciados || 0,
                promedio_eje_x: (quizStats as any)[0].prom_x || 0,
                promedio_eje_y: (quizStats as any)[0].prom_y || 0
            },
            charts: {
                activity: activityData,
                scatter: scatterData,
                top_questions: topQuestions
            }
        });
    } catch (error) {
        console.error('Error al obtener estadísticas:', error);
        res.status(500).json({ error: 'Error al obtener estadísticas' });
    }
};
