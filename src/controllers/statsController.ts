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

        // 6. Top Parties (Calculated via distance)
        const [partiesData] = await pool.query(`
            SELECT p.id, p.nombre_largo, ppc.posicion_x, ppc.posicion_y 
            FROM PartidoPosicionCache ppc
            JOIN Partido p ON ppc.partido_id = p.id
        `);

        const [sessionsData] = await pool.query(`
            SELECT resultado_x, resultado_y 
            FROM UsuarioSesion 
            WHERE completado = 1
        `);

        // Algorithm: Find nearest party for each session
        const partyCounts: Record<string, number> = {};
        const parties = partiesData as any[];
        const sessions = sessionsData as any[];

        sessions.forEach(session => {
            let minDist = Infinity;
            let closestParty = null;

            parties.forEach(party => {
                // Euclidean distance
                const dist = Math.sqrt(
                    Math.pow(session.resultado_x - party.posicion_x, 2) +
                    Math.pow(session.resultado_y - party.posicion_y, 2)
                );
                if (dist < minDist) {
                    minDist = dist;
                    closestParty = party.nombre_largo;
                }
            });

            if (closestParty) {
                partyCounts[closestParty] = (partyCounts[closestParty] || 0) + 1;
            }
        });

        const topParties = Object.entries(partyCounts)
            .map(([name, count]) => ({ name, count }))
            .sort((a, b) => b.count - a.count)
            .slice(0, 5);

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
                top_questions: topQuestions,
                top_parties: topParties
            }
        });
    } catch (error) {
        console.error('Error al obtener estadísticas:', error);
        res.status(500).json({ error: 'Error al obtener estadísticas' });
    }
};
