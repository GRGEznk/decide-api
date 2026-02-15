import type { Request, Response } from 'express';
import { pgPool } from '../config/supabase';

// Obtener todos los candidatos (usando la vista)
export const getAllCandidatos = async (req: Request, res: Response) => {
    try {
        const query = 'SELECT * FROM vista_candidatos ORDER BY id_partido, cargo, numero';
        const result = await pgPool.query(query);
        res.json(result.rows);
    } catch (error) {
        console.error('Error al obtener candidatos:', error);
        res.status(500).json({ error: 'Error al obtener candidatos' });
    }
};

// Obtener todas las regiones
export const getAllRegiones = async (req: Request, res: Response) => {
    try {
        const query = 'SELECT * FROM region ORDER BY nombre ASC';
        const result = await pgPool.query(query);
        res.json(result.rows);
    } catch (error) {
        console.error('Error al obtener regiones:', error);
        res.status(500).json({ error: 'Error al obtener regiones' });
    }
};

// Obtener candidato por ID
export const getCandidatoById = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const query = 'SELECT * FROM vista_candidatos WHERE candidato_id = $1';
        const result = await pgPool.query(query, [id]);

        if (result.rows.length === 0) {
            return res.status(404).json({ error: 'Candidato no encontrado' });
        }

        res.json(result.rows[0]);
    } catch (error) {
        console.error('Error al obtener candidato:', error);
        res.status(500).json({ error: 'Error al obtener candidato' });
    }
};

// Obtener candidatos por Partido ID
export const getCandidatosByPartidoId = async (req: Request, res: Response) => {
    try {
        const { id_partido } = req.params;
        const query = 'SELECT * FROM vista_candidatos WHERE id_partido = $1';
        const result = await pgPool.query(query, [id_partido]);
        res.json(result.rows);
    } catch (error) {
        console.error('Error al obtener candidatos del partido:', error);
        res.status(500).json({ error: 'Error al obtener candidatos del partido' });
    }
};

// Crear nuevo candidato
export const createCandidato = async (req: Request, res: Response) => {
    try {
        const { nombres, apellidos, cargo, numero, id_region, foto, hojavida, id_partido } = req.body;

        if (!nombres || !apellidos || !cargo || !id_partido) {
            return res.status(400).json({ error: 'Campos requeridos: nombres, apellidos, cargo, id_partido' });
        }

        const query = `
            INSERT INTO candidato (nombres, apellidos, cargo, numero, id_region, foto, hojavida, id_partido)
            VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
            RETURNING id
        `;

        const result = await pgPool.query(query, [
            nombres,
            apellidos,
            cargo,
            numero || null,
            id_region || 1, // Default a 'No Aplica'
            foto || null,
            hojavida || null,
            id_partido
        ]);

        res.status(201).json({
            message: 'Candidato creado exitosamente',
            id: result.rows[0].id,
            nombres,
            apellidos
        });

    } catch (error) {
        console.error('Error al crear candidato:', error);
        res.status(500).json({ error: 'Error al crear el candidato' });
    }
};

// Actualizar candidato
export const updateCandidato = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const { nombres, apellidos, cargo, numero, id_region, foto, hojavida, id_partido } = req.body;

        if (!nombres || !apellidos || !cargo || !id_partido) {
            return res.status(400).json({ error: 'Campos requeridos faltantes' });
        }

        const query = `
            UPDATE candidato 
            SET nombres = $1, apellidos = $2, cargo = $3, numero = $4, id_region = $5, foto = $6, hojavida = $7, id_partido = $8
            WHERE id = $9
        `;

        const result = await pgPool.query(query, [
            nombres,
            apellidos,
            cargo,
            numero || null,
            id_region || 1,
            foto || null,
            hojavida || null,
            id_partido,
            id
        ]);

        if (result.rowCount === 0) {
            return res.status(404).json({ error: 'Candidato no encontrado' });
        }

        res.json({ message: 'Candidato actualizado exitosamente', id });

    } catch (error) {
        console.error('Error al actualizar candidato:', error);
        res.status(500).json({ error: 'Error al actualizar candidato' });
    }
};

// Eliminar candidato
export const deleteCandidato = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const query = 'DELETE FROM candidato WHERE id = $1';
        const result = await pgPool.query(query, [id]);

        if (result.rowCount === 0) {
            return res.status(404).json({ error: 'Candidato no encontrado' });
        }

        res.json({ message: 'Candidato eliminado exitosamente' });
    } catch (error) {
        console.error('Error al eliminar candidato:', error);
        res.status(500).json({ error: 'Error al eliminar candidato' });
    }
};
