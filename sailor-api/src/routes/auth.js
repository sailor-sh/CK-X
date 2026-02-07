/**
 * Auth: register, login, me. No user identity in CKX; Sailor API owns it.
 */
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { PrismaClient } = require('@prisma/client');
const config = require('../config');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
const prisma = new PrismaClient();

function signToken(user) {
  return jwt.sign(
    { sub: user.id },
    config.jwt.secret,
    { expiresIn: config.jwt.expiresIn }
  );
}

// POST /auth/register
router.post('/register', async (req, res) => {
  const { email, password, name } = req.body || {};
  if (!email || !password) {
    return res.status(400).json({ error: 'email and password required' });
  }
  const existing = await prisma.user.findUnique({ where: { email: email.trim().toLowerCase() } });
  if (existing) {
    return res.status(409).json({ error: 'Email already registered' });
  }
  const passwordHash = await bcrypt.hash(password, 12);
  const user = await prisma.user.create({
    data: {
      email: email.trim().toLowerCase(),
      passwordHash,
      name: name?.trim() || null,
    },
  });
  const token = signToken(user);
  return res.status(201).json({
    user: { id: user.id, email: user.email, name: user.name },
    token,
    expiresIn: config.jwt.expiresIn,
  });
});

// POST /auth/login
router.post('/login', async (req, res) => {
  const { email, password } = req.body || {};
  if (!email || !password) {
    return res.status(400).json({ error: 'email and password required' });
  }
  const user = await prisma.user.findUnique({
    where: { email: email.trim().toLowerCase() },
  });
  if (!user) {
    return res.status(401).json({ error: 'Invalid email or password' });
  }
  const ok = await bcrypt.compare(password, user.passwordHash);
  if (!ok) {
    return res.status(401).json({ error: 'Invalid email or password' });
  }
  const token = signToken(user);
  return res.json({
    user: { id: user.id, email: user.email, name: user.name },
    token,
    expiresIn: config.jwt.expiresIn,
  });
});

// GET /auth/me (requires auth)
router.get('/me', requireAuth, (req, res) => {
  return res.json({
    user: {
      id: req.user.id,
      email: req.user.email,
      name: req.user.name,
    },
  });
});

module.exports = router;
