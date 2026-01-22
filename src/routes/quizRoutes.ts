import { Router } from 'express';
import { startSession, saveAnswers, getSession } from '../controllers/quizController';

const router = Router();

router.post('/start', startSession);
router.post('/answers', saveAnswers);
router.get('/session/:id', getSession);

export default router;
