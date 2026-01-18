import { Router } from 'express';
import { getParties, getPartyPositions, createParty, updateParty, deleteParty, getPartyAnswers, savePartyAnswers } from '../controllers/partyController';

const router = Router();

router.get('/partidos', getParties);
router.get('/posiciones-partidos', getPartyPositions);
router.post('/partidos', createParty);
router.put('/partidos/:id', updateParty);
router.delete('/partidos/:id', deleteParty);
router.get('/partidos/:id/respuestas', getPartyAnswers);
router.post('/partidos/:id/respuestas', savePartyAnswers);

export default router;
