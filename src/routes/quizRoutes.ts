import { Router } from 'express';
import { startSession, saveAnswers, getSession, getAllSessions, linkSessionWithUser } from '../controllers/quizController';
import { getMatches } from '../controllers/resultsController';

const router = Router();

router.post('/start', startSession);
router.post('/answers', saveAnswers);
router.post('/link-session', linkSessionWithUser);
router.get('/session/:id', getSession);
router.get('/session/:id/matches', getMatches);
router.get('/sessions', getAllSessions);

export default router;
