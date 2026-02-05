import type { Request, Response } from 'express';
import { pool } from '../config/db';
import type { RowDataPacket, ResultSetHeader } from 'mysql2';

// Obtener todos los candidatos (usando la vista)
export const getAllCandidatos = async (req: Request, res: Response) => {
    try {
        const query = 'SELECT * FROM vista_candidatos';
        const [rows] = await pool.query(query);
        res.json(rows);
    } catch (error) {
        console.error('Error al obtener candidatos:', error);
        res.status(500).json({ error: 'Error al obtener candidatos' });
    }
};

// Obtener candidato por ID
export const getCandidatoById = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const query = 'SELECT * FROM vista_candidatos WHERE candidato_id = ?';
        const [rows] = await pool.query<RowDataPacket[]>(query, [id]);

        if (rows.length === 0) {
            return res.status(404).json({ error: 'Candidato no encontrado' });
        }

        res.json(rows[0]);
    } catch (error) {
        console.error('Error al obtener candidato:', error);
        res.status(500).json({ error: 'Error al obtener candidato' });
    }
};

// Obtener candidatos por Partido ID
export const getCandidatosByPartidoId = async (req: Request, res: Response) => {
    try {
        const { id_partido } = req.params;
        const query = 'SELECT * FROM vista_candidatos WHERE id_partido = ?';
        const [rows] = await pool.query(query, [id_partido]);
        res.json(rows);
    } catch (error) {
        console.error('Error al obtener candidatos del partido:', error);
        res.status(500).json({ error: 'Error al obtener candidatos del partido' });
    }
};

// Crear nuevo candidato
export const createCandidato = async (req: Request, res: Response) => {
    try {
        const { nombres, apellidos, cargo, region, foto, hojavida, id_partido } = req.body;

        if (!nombres || !apellidos || !cargo || !id_partido) {
            return res.status(400).json({ error: 'Campos requeridos: nombres, apellidos, cargo, id_partido' });
        }

        const query = `
            INSERT INTO candidato (nombres, apellidos, cargo, region, foto, hojavida, id_partido)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        `;

        const [result] = await pool.query<ResultSetHeader>(query, [
            nombres,
            apellidos,
            cargo,
            region || null,
            foto || null,
            hojavida || null,
            id_partido
        ]);

        res.status(201).json({
            message: 'Candidato creado exitosamente',
            id: result.insertId,
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
        const { nombres, apellidos, cargo, region, foto, hojavida, id_partido } = req.body;

        if (!nombres || !apellidos || !cargo || !id_partido) {
            return res.status(400).json({ error: 'Campos requeridos faltantes' });
        }

        const query = `
            UPDATE candidato 
            SET nombres = ?, apellidos = ?, cargo = ?, region = ?, foto = ?, hojavida = ?, id_partido = ?
            WHERE id = ?
        `;

        const [result] = await pool.query<ResultSetHeader>(query, [
            nombres,
            apellidos,
            cargo,
            region || null,
            foto || null,
            hojavida || null,
            id_partido,
            id
        ]);

        if (result.affectedRows === 0) {
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
        const query = 'DELETE FROM candidato WHERE id = ?';
        const [result] = await pool.query<ResultSetHeader>(query, [id]);

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Candidato no encontrado' });
        }

        res.json({ message: 'Candidato eliminado exitosamente' });
    } catch (error) {
        console.error('Error al eliminar candidato:', error);
        res.status(500).json({ error: 'Error al eliminar candidato' });
    }
};
