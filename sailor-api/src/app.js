/**
 * Sailor API — business control plane.
 * Responsibilities: user auth, payments, exam definitions, ExamSession lifecycle, CKX session orchestration.
 * CKX never validates users; Sailor enforces access and creates/revokes CKX sessions.
 */
const express = require('express');
const cors = require('cors');
const config = require('./config');
const authRoutes = require('./routes/auth');
const paymentsRoutes = require('./routes/payments');
const examsRoutes = require('./routes/exams');
const examSessionsRoutes = require('./routes/exam-sessions');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'sailor-api' });
});

app.use('/auth', authRoutes);
app.use('/payments', paymentsRoutes);
app.use('/exams', examsRoutes);
app.use('/exam-sessions', examSessionsRoutes);

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(config.port, () => {
  console.log(`Sailor API listening on port ${config.port}`);
});
