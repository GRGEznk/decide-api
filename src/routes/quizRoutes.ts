import { Router } from 'express';
import { startSession, saveAnswers, getSession, getAllSessions } from '../controllers/quizController';
import { getMatches } from '../controllers/resultsController';

const router = Router();

router.post('/start', startSession);
router.post('/answers', saveAnswers);
router.get('/session/:id', getSession);
router.get('/session/:id/matches', getMatches);
router.get('/sessions', getAllSessions);

export default router;
