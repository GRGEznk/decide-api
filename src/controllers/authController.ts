import type { Request, Response } from 'express';
import { pool } from '../config/db';
import { validatePassword } from '../utils/validation';

const loginAttempts = new Map<string, { count: number, lockUntil: number }>();

export const login = async (req: Request, res: Response): Promise<void> => {
    const { email, password } = req.body;

    // verificar bloqueo previo
    if (loginAttempts.has(email)) {
        const attempt = loginAttempts.get(email)!;
        if (attempt.lockUntil > Date.now()) {
            const remainingSeconds = Math.ceil((attempt.lockUntil - Date.now()) / 1000);
            res.status(429).json({ error: `Demasiados intentos. Intente nuevamente en ${remainingSeconds} segundos.` });
            return;
        } else if (attempt.lockUntil !== 0 && attempt.lockUntil < Date.now()) {
            // reiniciar al expirar el bloqueo
            loginAttempts.delete(email);
        }
    }

    try {
        const [rows] = await pool.query('SELECT * FROM Usuario WHERE email = ?', [email]);
        const users = rows as any[];

        if (users.length === 0) {
            res.status(401).json({ error: 'Usuario no encontrado' });
            return;
        }

        const user = users[0];

        if (user.password_hash === password) {
            // limpiar intentos si logro loguearse
            loginAttempts.delete(email);

            const { password_hash, ...userSafe } = user;
            res.json(userSafe);
        } else {
            // Registrar intento si falla login
            const now = Date.now();
            const current = loginAttempts.get(email) || { count: 0, lockUntil: 0 };
            current.count += 1;

            if (current.count >= 3) {
                current.lockUntil = now + 60000; // Bloquear 1 minuto
                loginAttempts.set(email, current);
                res.status(429).json({ error: 'Demasiados intentos fallidos. Bloqueado por 1 minuto.' });
            } else {
                loginAttempts.set(email, current);
                console.log(`Intento fallido ${current.count}/3 para ${email}`);
                res.status(401).json({ error: 'Contraseña incorrecta' });
            }
        }
    } catch (error) {
        console.error('Error en login:', error);
        res.status(500).json({ error: 'Error interno de servidor' });
    }
};

export const register = async (req: Request, res: Response): Promise<void> => {
    const { nombre, email, password } = req.body;

    if (!nombre || !email || !password) {
        res.status(400).json({ error: 'Faltan campos requeridos' });
        return;
    }

    const passValid = validatePassword(password);
    if (!passValid.isValid) {
        res.status(400).json({ error: passValid.error });
        return;
    }

    try {
        const [result] = await pool.query(
            'INSERT INTO Usuario (nombre, email, password_hash, rol) VALUES (?, ?, ?, ?)',
            [nombre, email, password, 'user']
        );
        const insertId = (result as any).insertId;
        res.status(201).json({ id: insertId, nombre, email, rol: 'user' });
    } catch (error: any) {
        if (error.code === 'ER_DUP_ENTRY') {
            res.status(409).json({ error: 'El email ya está registrado' });
        } else {
            console.error('Error al registrar usuario:', error);
            res.status(500).json({ error: 'Error al registrar usuario' });
        }
    }
};
