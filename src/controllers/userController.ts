import type { Request, Response } from 'express';
import { pool } from '../config/db';
import { validatePassword } from '../utils/validation';

export const getUsers = async (req: Request, res: Response) => {
    try {
        const [rows] = await pool.query('SELECT id, nombre, email, rol, fecha_registro FROM Usuario');
        res.json(rows);
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
        const [result] = await pool.query(
            'INSERT INTO Usuario (nombre, email, password_hash, rol) VALUES (?, ?, ?, ?)',
            [nombre, email, hashedPassword, rol]
        );
        const insertId = (result as any).insertId;
        res.status(201).json({ id: insertId, nombre, email, rol });
    } catch (error: any) {
        if (error.code === 'ER_DUP_ENTRY') {
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
        // Si hay password, validar y actualizar
        if (password && password.trim() !== '') {
            const passValid = validatePassword(password);
            if (!passValid.isValid) {
                res.status(400).json({ error: passValid.error });
                return;
            }

            const hashedPassword = await Bun.password.hash(password);
            await pool.query(
                'UPDATE Usuario SET nombre = ?, email = ?, password_hash = ?, rol = ? WHERE id = ?',
                [nombre, email, hashedPassword, rol, id]
            );
        } else {
            await pool.query(
                'UPDATE Usuario SET nombre = ?, email = ?, rol = ? WHERE id = ?',
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
        await pool.query('DELETE FROM Usuario WHERE id = ?', [id]);
        res.json({ message: 'Usuario eliminado' });
    } catch (error) {
        console.error('Error al eliminar usuario:', error);
        res.status(500).json({ error: 'Error al eliminar usuario' });
    }
};
