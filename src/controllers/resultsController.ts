import type { Request, Response } from 'express';
import { pool } from '../config/db';
import type { RowDataPacket } from 'mysql2';

interface PartyResult extends RowDataPacket {
    id: number;
    nombre: string;
    sigla: string;
    posicion_x: number;
    posicion_y: number;
    logo_key: string;
    color_primario: string;
    candidato_presidencial: string;
    candidato_key: string;
}

interface UserSession extends RowDataPacket {
    resultado_x: number;
    resultado_y: number;
    completado: number;
}

export const getMatches = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        if (!id) return res.status(400).json({ error: 'ID no proporcionado' });

        const idStr = String(id);
        const isNumeric = /^\d+$/.test(idStr);

        // obtener resultados
        let query = 'SELECT resultado_x, resultado_y, completado FROM UsuarioSesion WHERE ';
        query += isNumeric ? 'id = ?' : 'token = ?';

        const [userRows] = await pool.query<UserSession[]>(query, [idStr]);

        if (userRows.length === 0) {
            return res.status(404).json({ error: 'Sesión no encontrada' });
        }

        const user = userRows[0];

        if (!user || !user.completado || user.resultado_x === null || user.resultado_y === null) {
            return res.status(400).json({ error: 'La sesión no ha sido completada o faltan resultados' });
        }

        // obtener posiciones
        const [partyRows] = await pool.query<PartyResult[]>(`
            SELECT 
                p.id, 
                p.nombre, 
                p.sigla, 
                c.posicion_x, 
                c.posicion_y,
                pm.logo_key,
                pm.color_primario,
                pm.candidato_presidencial,
                pm.candidato_key
            FROM Partido p 
            JOIN PartidoPosicionCache c ON p.id = c.partido_id
            LEFT JOIN partido_metadata pm ON p.id = pm.partido_id
        `);

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
