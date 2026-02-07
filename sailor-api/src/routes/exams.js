/**
 * Exam definitions. Sailor API owns exam rules; CKX only executes by sessionId.
 */
const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { requireAuth, optionalAuth } = require('../middleware/auth');

const router = express.Router();
const prisma = new PrismaClient();

// GET /exams — list exams (public or filtered by entitlement)
router.get('/', optionalAuth, async (req, res) => {
  const exams = await prisma.exam.findMany({
    orderBy: { slug: 'asc' },
    include: {
      product: { select: { id: true, name: true, type: true, priceCents: true } },
      _count: { select: { questions: true } },
    },
  });
  const list = exams.map((e) => ({
    id: e.id,
    slug: e.slug,
    name: e.name,
    description: e.description,
    durationMinutes: e.durationMinutes,
    maxAttempts: e.maxAttempts,
    productId: e.product?.id,
    product: e.product,
    questionCount: e._count.questions,
  }));
  return res.json({ exams: list });
});

// GET /exams/:id — get one exam (metadata only; questions when starting session)
router.get('/:id', optionalAuth, async (req, res) => {
  const exam = await prisma.exam.findUnique({
    where: { id: req.params.id },
    include: {
      product: true,
      _count: { select: { questions: true } },
    },
  });
  if (!exam) {
    return res.status(404).json({ error: 'Exam not found' });
  }
  return res.json({
    id: exam.id,
    slug: exam.slug,
    name: exam.name,
    description: exam.description,
    durationMinutes: exam.durationMinutes,
    maxAttempts: exam.maxAttempts,
    product: exam.product,
    questionCount: exam._count.questions,
  });
});

// GET /exams/:id/questions — questions for an exam (only when user has active session or admin)
// In full flow, questions are often delivered via session start response or CKX; this is optional.
router.get('/:id/questions', requireAuth, async (req, res) => {
  const exam = await prisma.exam.findUnique({
    where: { id: req.params.id },
    include: { questions: { orderBy: { order: 'asc' } } },
  });
  if (!exam) {
    return res.status(404).json({ error: 'Exam not found' });
  }
  const questions = exam.questions.map((q) => ({
    id: q.id,
    order: q.order,
    body: q.body,
    type: q.type,
    options: q.options,
    // answer excluded for client (scoring server-side)
  }));
  return res.json({ examId: exam.id, questions });
});

module.exports = router;
