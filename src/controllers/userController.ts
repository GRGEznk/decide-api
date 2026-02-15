import type { Request, Response } from 'express';
import { pgPool } from '../config/supabase';
import { validatePassword } from '../utils/validation';

export const getUsers = async (req: Request, res: Response) => {
    try {
        const result = await pgPool.query('SELECT id, nombre, email, rol, fecha_registro FROM usuario');
        res.json(result.rows);
    } catch (error) {
        console.error('Error al obtener usuarios:', error);
        res.status(500).json({ error: 'Error al obtener usuarios' });
    }
};

export const createUser = async (req: Request, res: Response) => {
    const { nombre, email, password, rol } = req.body;

    if (!nombre || !email || !password || !rol) {
        res.status(400).json({ error: 'Faltan campos requeridos' });
        return;
    }

    const passValid = validatePassword(password);
    if (!passValid.isValid) {
        res.status(400).json({ error: passValid.error });
        return;
    }

    try {
        const hashedPassword = await Bun.password.hash(password);
        const result = await pgPool.query(
            'INSERT INTO usuario (nombre, email, password_hash, rol) VALUES ($1, $2, $3, $4) RETURNING id',
            [nombre, email, hashedPassword, rol]
        );
        const insertId = result.rows[0].id;
        res.status(201).json({ id: insertId, nombre, email, rol });
    } catch (error: any) {
        if (error.code === '23505') {
            res.status(409).json({ error: 'El email ya está registrado' });
        } else {
            console.error('Error al crear usuario:', error);
            res.status(500).json({ error: 'Error al crear usuario' });
        }
    }
};

export const updateUser = async (req: Request, res: Response) => {
    const { id } = req.params;
    const { nombre, email, password, rol } = req.body;

    try {
        // validar password
        if (password && password.trim() !== '') {
            const passValid = validatePassword(password);
            if (!passValid.isValid) {
                res.status(400).json({ error: passValid.error });
                return;
            }

            const hashedPassword = await Bun.password.hash(password);
            await pgPool.query(
                'UPDATE usuario SET nombre = $1, email = $2, password_hash = $3, rol = $4 WHERE id = $5',
                [nombre, email, hashedPassword, rol, id]
            );
        } else {
            await pgPool.query(
                'UPDATE usuario SET nombre = $1, email = $2, rol = $3 WHERE id = $4',
                [nombre, email, rol, id]
            );
        }
        res.json({ id, nombre, email, rol });
    } catch (error) {
        console.error('Error al actualizar usuario:', error);
        res.status(500).json({ error: 'Error al actualizar usuario' });
    }
};

export const deleteUser = async (req: Request, res: Response) => {
    const { id } = req.params;
    try {
        await pgPool.query('DELETE FROM usuario WHERE id = $1', [id]);
        res.json({ message: 'Usuario eliminado' });
    } catch (error) {
        console.error('Error al eliminar usuario:', error);
        res.status(500).json({ error: 'Error al eliminar usuario' });
    }
};
