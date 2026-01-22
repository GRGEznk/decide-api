import express from 'express';
import cors from 'cors';
import authRoutes from './src/routes/authRoutes';
import userRoutes from './src/routes/userRoutes';
import questionRoutes from './src/routes/questionRoutes';
import partyRoutes from './src/routes/partyRoutes';
import statsRoutes from './src/routes/statsRoutes';
import quizRoutes from './src/routes/quizRoutes';

const app = express();
const port = 3001;

// CORS para permitir peticiones del frontend
app.use(cors());
app.use(express.json());

// Rutas
app.use('/api', authRoutes);
app.use('/api/usuarios', userRoutes);
app.use('/api/preguntas', questionRoutes);
app.use('/api', partyRoutes);
app.use('/api/stats', statsRoutes);
app.use('/api/quiz', quizRoutes);

// prueba
app.get('/', (req, res) => {
  res.send('<h1>API de Decide.pe está operativa</h1>');
});

// Iniciar servidor
app.listen(port, () => {
  console.log(` Servidor corriendo en: http://localhost:${port}`);
});