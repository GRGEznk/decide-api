import type { Request, Response } from 'express';
import { supabase, pgPool } from '../config/supabase';

export const getParties = async (req: Request, res: Response) => {
    try {
        const { data, error } = await supabase
            .from('partido')
            .select(`
                *,
                partido_metadata (
                    candidato_presidencial,
                    lider_partido,
                    color_primario,
                    plan_gobierno,
                    anio_fundacion,
                    anio_inscripcion_jne,
                    tipo_organizacion
                )
            `)
            .order('nombre');

        if (error) throw error;
        res.json(data);
    } catch (error) {
        console.error('Error al obtener partidos:', error);
        res.status(500).json({ error: 'Error al obtener partidos' });
    }
};

export const getPartyBySigla = async (req: Request, res: Response) => {
    try {
        const { sigla } = req.params;
        
        const { data, error } = await supabase
            .from('partido')
            .select(`
                *,
                partido_metadata (
                    candidato_presidencial,
                    lider_partido,
                    color_primario,
                    plan_gobierno,
                    anio_fundacion,
                    anio_inscripcion_jne,
                    tipo_organizacion
                )
            `)
            .eq('sigla', sigla)
            .single();

        if (error) {
            console.error('Error al obtener partido por sigla:', error);
            return res.status(404).json({ error: 'Partido no encontrado' });
        }

        res.json(data);
    } catch (error) {
        console.error('Error detallado al obtener partido por sigla:', error);
        console.error('Sigla recibida:', req.params.sigla);
        res.status(500).json({ 
            error: 'Error al obtener el partido', 
            details: error instanceof Error ? error.message : String(error) 
        });
    }
};

export const getPartyPositions = async (req: Request, res: Response) => {
    try {
        const query = `
            SELECT 
                p.id, 
                p.nombre, 
                p.sigla, 
                ppc.posicion_x, 
                ppc.posicion_y, 
                ppc.fecha_calculo,
                pm.color_primario
            FROM partido p
            LEFT JOIN partidoposicioncache ppc ON p.id = ppc.partido_id
            LEFT JOIN partido_metadata pm ON p.id = pm.partido_id
            ORDER BY p.nombre
        `;
        
        const result = await pgPool.query(query);
        res.json(result.rows);
    } catch (error) {
        console.error('Error al obtener posiciones:', error);
        res.status(500).json({ error: 'Error al obtener posiciones' });
    }
};

export const createParty = async (req: Request, res: Response) => {
    try {
        const {
            nombre, nombre_largo, sigla,
            candidato_presidencial, lider_partido, color_primario, plan_gobierno,
            anio_fundacion, anio_inscripcion_jne, tipo_organizacion
        } = req.body;

        // Validaciones
        if (!nombre || !nombre_largo || !sigla) {
            return res.status(400).json({ 
                error: 'Campos requeridos: nombre, nombre_largo, sigla' 
            });
        }

        // Insertar partido
        const { data: partido, error: errorPartido } = await supabase
            .from('partido')
            .insert({ nombre, nombre_largo, sigla })
            .select()
            .single();

        if (errorPartido) {
            if (errorPartido.code === '23505') { // Unique violation
                return res.status(409).json({ 
                    error: 'Ya existe un partido con ese nombre o sigla' 
                });
            }
            throw errorPartido;
        }

        // Insertar metadatos
        const { error: errorMeta } = await supabase
            .from('partido_metadata')
            .insert({
                partido_id: partido.id,
                candidato_presidencial: candidato_presidencial || null,
                lider_partido: lider_partido || null,
                color_primario: color_primario || '#000000',
                plan_gobierno: plan_gobierno || null,
                anio_fundacion: anio_fundacion || null,
                anio_inscripcion_jne: anio_inscripcion_jne || null,
                tipo_organizacion: tipo_organizacion || 'Partido Político'
            });

        if (errorMeta) throw errorMeta;

        res.status(201).json({
            message: 'Partido y metadatos creados exitosamente',
            id: partido.id,
            nombre,
            sigla
        });

    } catch (error: any) {
        console.error('Error al crear partido:', error);
        res.status(500).json({ error: 'Error al crear el partido' });
    }
};

export const updateParty = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const {
            nombre, nombre_largo, sigla,
            candidato_presidencial, lider_partido, color_primario, plan_gobierno,
            anio_fundacion, anio_inscripcion_jne, tipo_organizacion
        } = req.body;

        if (!nombre || !nombre_largo || !sigla) {
            return res.status(400).json({ error: 'Campos requeridos faltantes' });
        }

        // Actualizar partido
        const { error: errorPartido } = await supabase
            .from('partido')
            .update({ nombre, nombre_largo, sigla })
            .eq('id', id);

        if (errorPartido) {
            if (errorPartido.code === '23505') {
                return res.status(409).json({ 
                    error: 'Conflicto de duplicados en nombre o sigla' 
                });
            }
            throw errorPartido;
        }

        // Actualizar o insertar metadatos (upsert)
        const { error: errorMeta } = await supabase
            .from('partido_metadata')
            .upsert({
                partido_id: parseInt(id as string),
                candidato_presidencial: candidato_presidencial || null,
                lider_partido: lider_partido || null,
                color_primario: color_primario || '#000000',
                plan_gobierno: plan_gobierno || null,
                anio_fundacion: anio_fundacion || null,
                anio_inscripcion_jne: anio_inscripcion_jne || null,
                tipo_organizacion: tipo_organizacion || 'Partido Político'
            }, {
                onConflict: 'partido_id'
            });

        if (errorMeta) throw errorMeta;

        res.json({
            message: 'Partido y metadatos actualizados exitosamente',
            id
        });

    } catch (error: any) {
        console.error('Error al actualizar partido:', error);
        res.status(500).json({ error: 'Error al actualizar el partido' });
    }
};

export const deleteParty = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        
        const { error } = await supabase
            .from('partido')
            .delete()
            .eq('id', id);

        if (error) throw error;
        
        res.json({ message: 'Partido eliminado exitosamente' });
    } catch (error) {
        console.error('Error al eliminar partido:', error);
        res.status(500).json({ error: 'Error al eliminar el partido' });
    }
};

export const getPartyAnswers = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        
        const { data, error } = await supabase
            .from('partidorespuesta')
            .select('pregunta_id, valor, fuente')
            .eq('partido_id', id);

        if (error) throw error;
        res.json(data);
    } catch (error) {
        console.error('Error al obtener respuestas del partido:', error);
        res.status(500).json({ error: 'Error al obtener respuestas' });
    }
};

export const savePartyAnswers = async (req: Request, res: Response) => {
    try {
        const { id } = req.params;
        const { respuestas } = req.body;

        if (!Array.isArray(respuestas)) {
            return res.status(400).json({ error: 'El formato de respuestas es inválido' });
        }

        const partyId = parseInt(id as string);

        // Validar valores
        for (const resp of respuestas) {
            const { valor, pregunta_id } = resp;
            if (valor < -2 || valor > 2) {
                return res.status(400).json({ 
                    error: `Valor inválido para pregunta ${pregunta_id}: ${valor}` 
                });
            }
        }

        // Preparar datos para upsert
        const dataToInsert = respuestas.map(resp => ({
            partido_id: partyId,
            pregunta_id: resp.pregunta_id,
            valor: resp.valor,
            fuente: resp.fuente || null
        }));

        // Upsert todas las respuestas
        const { error } = await supabase
            .from('partidorespuesta')
            .upsert(dataToInsert, {
                onConflict: 'partido_id,pregunta_id'
            });

        if (error) throw error;

        res.json({ message: 'Respuestas guardadas exitosamente' });

    } catch (error: any) {
        console.error('Error al guardar respuestas:', error);
        res.status(500).json({ 
            error: error.message || 'Error al guardar respuestas' 
        });
    }
};
