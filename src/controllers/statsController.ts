import type { Request, Response } from 'express';
import { pgPool } from '../config/supabase';

export const getStats = async (req: Request, res: Response) => {
    try {
        // Ejecutar todas las consultas independientes en paralelo
        const [
            usuariosRes,
            preguntasRes,
            partidosRes,
            quizStatsRes,
            activityDataRes,
            scatterDataRes,
            topQuestionsRes,
            partiesDataRes,
            sessionsDataRes
        ] = await Promise.all([
            pgPool.query('SELECT COUNT(*) as total FROM usuario'),
            pgPool.query("SELECT COUNT(*) as total FROM pregunta WHERE estado = 'activa'"),
            pgPool.query('SELECT COUNT(*) as total FROM partido'),
            pgPool.query(`
                SELECT 
                    SUM(completadas) as total_completados, 
                    SUM(total_sesiones) as total_iniciados,
                    AVG(promedio_x) as prom_x,
                    AVG(promedio_y) as prom_y
                FROM vistaestadisticasquiz
            `),
            pgPool.query(`
                SELECT fecha, total_sesiones, completadas 
                FROM vistaestadisticasquiz 
                ORDER BY fecha DESC 
                LIMIT 30
            `),
            pgPool.query(`
                SELECT resultado_x as x, resultado_y as y 
                FROM usuariosesion 
                WHERE completado = true 
                ORDER BY fecha DESC 
                LIMIT 500
            `),
            pgPool.query(`
                SELECT texto, total_respuestas 
                FROM vistapreguntasestadisticas 
                ORDER BY total_respuestas DESC 
                LIMIT 5
            `),
            pgPool.query(`
                SELECT p.id, p.nombre_largo, ppc.posicion_x, ppc.posicion_y 
                FROM partidoposicioncache ppc
                JOIN partido p ON ppc.partido_id = p.id
            `),
            pgPool.query(`
                SELECT resultado_x, resultado_y 
                FROM usuariosesion 
                WHERE completado = true
            `)
        ]);

        // algoritmo cercania
        const partyCounts: Record<string, number> = {};
        const parties = partiesDataRes.rows;
        const sessions = sessionsDataRes.rows;

        sessions.forEach(session => {
            let minDist = Infinity;
            let closestParty = null;

            parties.forEach(party => {
                // distancia euclidiana
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
                usuarios: usuariosRes.rows[0].total,
                preguntas_activas: preguntasRes.rows[0].total,
                partidos: partidosRes.rows[0].total,
                tests_completados: quizStatsRes.rows[0].total_completados || 0,
                tests_iniciados: quizStatsRes.rows[0].total_iniciados || 0,
                promedio_eje_x: quizStatsRes.rows[0].prom_x || 0,
                promedio_eje_y: quizStatsRes.rows[0].prom_y || 0
            },
            charts: {
                activity: activityDataRes.rows,
                scatter: scatterDataRes.rows,
                top_questions: topQuestionsRes.rows,
                top_parties: topParties
            }
        });
    } catch (error) {
        console.error('Error al obtener estadísticas:', error);
        res.status(500).json({ error: 'Error al obtener estadísticas' });
    }
};
