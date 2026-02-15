import type { Request, Response } from 'express';
import { pgPool } from '../config/supabase';

export const getMatches = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        if (!id) return res.status(400).json({ error: 'ID no proporcionado' });

        const idStr = String(id);
        const isNumeric = /^\d+$/.test(idStr);

        // obtener resultados
        let query = 'SELECT resultado_x, resultado_y, completado FROM usuariosesion WHERE ';
        query += isNumeric ? 'id = $1' : 'token = $1';

        const result = await pgPool.query(query, [idStr]);
        const userRows = result.rows;

        if (userRows.length === 0) {
            return res.status(404).json({ error: 'Sesión no encontrada' });
        }

        const user = userRows[0];

        if (!user || !user.completado || user.resultado_x === null || user.resultado_y === null) {
            return res.status(400).json({ error: 'La sesión no ha sido completada o faltan resultados' });
        }

        // obtener posiciones
        const partyResult = await pgPool.query(`
            SELECT 
                p.id, 
                p.nombre, 
                p.sigla, 
                c.posicion_x, 
                c.posicion_y,
                pm.color_primario,
                pm.candidato_presidencial,
                pm.plan_gobierno
            FROM partido p 
            JOIN partidoposicioncache c ON p.id = c.partido_id
            LEFT JOIN partido_metadata pm ON p.id = pm.partido_id
        `);
        const partyRows = partyResult.rows;

        // calcular afinidad
        const MAX_DISTANCE = Math.sqrt(Math.pow(200, 2) + Math.pow(200, 2)); // distancia maxima

        const matches = partyRows.map(party => {
            // distancia euclidiana
            const distance = Math.sqrt(
                Math.pow(party.posicion_x - user.resultado_x, 2) +
                Math.pow(party.posicion_y - user.resultado_y, 2)
            );

            // porcentaje de afinidad
            const matchPercentage = Math.max(0, 100 * (1 - (distance / MAX_DISTANCE)));

            return {
                ...party,
                match_percentage: Number(matchPercentage.toFixed(2)), // redondear
                distance: distance
            };
        });

        // ordenar afinidad
        matches.sort((a, b) => b.match_percentage - a.match_percentage);

        res.json(matches);

    } catch (error) {
        console.error('Error al calcular matches:', error);
        res.status(500).json({ error: 'Error al calcular los resultados' });
    }
};
