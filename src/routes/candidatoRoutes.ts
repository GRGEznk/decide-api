import { Router } from 'express';
import {
    getAllCandidatos,
    getCandidatoById,
    getCandidatosByPartidoId,
    createCandidato,
    updateCandidato,
    deleteCandidato
} from '../controllers/candidatoController';

const router = Router();

router.get('/candidatos', getAllCandidatos);
router.get('/candidatos/:id', getCandidatoById);
router.get('/partidos/:id_partido/candidatos', getCandidatosByPartidoId);
router.post('/candidatos', createCandidato);
router.put('/candidatos/:id', updateCandidato);
router.delete('/candidatos/:id', deleteCandidato);

export default router;
