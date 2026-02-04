/**
 * Payments & entitlements. Sailor API owns payments; CKX never sees them.
 */
const express = require('express');
const { PrismaClient } = require('@prisma/client');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();
const prisma = new PrismaClient();

// GET /payments/products — list products (e.g. for checkout)
router.get('/products', async (req, res) => {
  const products = await prisma.product.findMany({
    orderBy: { createdAt: 'desc' },
    include: { exam: { select: { id: true, slug: true, name: true } } },
  });
  return res.json({
    products: products.map((p) => ({
      id: p.id,
      name: p.name,
      type: p.type,
      priceCents: p.priceCents,
      currency: p.currency,
      examId: p.examId,
      exam: p.exam,
    })),
  });
});

// GET /payments/entitlements — current user's entitlements
router.get('/entitlements', requireAuth, async (req, res) => {
  const now = new Date();
  const list = await prisma.entitlement.findMany({
    where: {
      userId: req.user.id,
      status: 'ACTIVE',
      validFrom: { lte: now },
      validUntil: { gte: now },
    },
    include: { product: { include: { exam: true } } },
  });
  return res.json({
    entitlements: list.map((e) => ({
      id: e.id,
      productId: e.productId,
      product: e.product,
      validFrom: e.validFrom,
      validUntil: e.validUntil,
    })),
  });
});

// POST /payments/entitlements — grant entitlement (e.g. after payment or admin)
// In production this would be called by payment webhook or internal admin.
router.post('/entitlements', requireAuth, async (req, res) => {
  const { productId, validDays } = req.body || {};
  if (!productId) {
    return res.status(400).json({ error: 'productId required' });
  }
  const product = await prisma.product.findUnique({ where: { id: productId } });
  if (!product) {
    return res.status(404).json({ error: 'Product not found' });
  }
  const now = new Date();
  const validUntil = new Date(now);
  validUntil.setDate(validUntil.getDate() + (validDays || 365));
  const entitlement = await prisma.entitlement.create({
    data: {
      userId: req.user.id,
      productId,
      validFrom: now,
      validUntil,
    },
    include: { product: true },
  });
  return res.status(201).json({ entitlement });
});

// POST /payments/checkout — create payment record (stub; integrate Stripe etc. in production)
router.post('/checkout', requireAuth, async (req, res) => {
  const { productId } = req.body || {};
  if (!productId) {
    return res.status(400).json({ error: 'productId required' });
  }
  const product = await prisma.product.findUnique({ where: { id: productId } });
  if (!product) {
    return res.status(404).json({ error: 'Product not found' });
  }
  const payment = await prisma.payment.create({
    data: {
      userId: req.user.id,
      productId,
      amountCents: product.priceCents,
      currency: product.currency,
      status: 'PENDING',
    },
    include: { product: true },
  });
  // Stub: in production, create Stripe session and return clientSecret/url
  return res.status(201).json({
    paymentId: payment.id,
    amountCents: payment.amountCents,
    currency: payment.currency,
    product: payment.product,
    clientSecret: null,
    message: 'Integrate Stripe/payment provider; on success call POST /payments/:id/complete',
  });
});

// POST /payments/:id/complete — mark payment completed and grant entitlement (e.g. webhook)
router.post('/:id/complete', requireAuth, async (req, res) => {
  const payment = await prisma.payment.findFirst({
    where: { id: req.params.id, userId: req.user.id },
    include: { product: true },
  });
  if (!payment) {
    return res.status(404).json({ error: 'Payment not found' });
  }
  if (payment.status === 'COMPLETED') {
    return res.json({ payment, message: 'Already completed' });
  }
  await prisma.$transaction([
    prisma.payment.update({
      where: { id: payment.id },
      data: { status: 'COMPLETED' },
    }),
    prisma.entitlement.create({
      data: {
        userId: payment.userId,
        productId: payment.productId,
        validFrom: new Date(),
        validUntil: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
      },
    }),
  ]);
  const updated = await prisma.payment.findUnique({
    where: { id: payment.id },
    include: { product: true },
  });
  return res.json({ payment: updated, entitlementGranted: true });
});

module.exports = router;
