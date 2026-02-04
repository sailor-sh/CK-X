/**
 * Seed: one exam, one product, demo user. Run after: npx prisma db push
 * npx prisma db seed  OR  node prisma/seed.js
 */
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  let exam = await prisma.exam.findUnique({ where: { slug: 'ckad-practice' } });
  if (!exam) {
    exam = await prisma.exam.create({
      data: {
        slug: 'ckad-practice',
        name: 'CKAD Practice',
        description: 'Certified Kubernetes Application Developer practice exam',
        durationMinutes: 120,
        maxAttempts: 3,
        questions: {
          create: [
            { order: 1, body: 'Create a pod named nginx running the nginx image.', type: 'free_text', options: null },
            { order: 2, body: 'Expose the pod on port 80.', type: 'free_text', options: null },
          ],
        },
      },
      include: { questions: true },
    });
  }

  let product = await prisma.product.findFirst({ where: { examId: exam.id } });
  if (!product) {
    product = await prisma.product.create({
      data: {
        name: 'CKAD Practice Access',
        type: 'one_time',
        priceCents: 2900,
        currency: 'USD',
        examId: exam.id,
      },
    });
  }

  const demoHash = await bcrypt.hash('demo1234', 12);
  await prisma.user.upsert({
    where: { email: 'demo@sailor.dev' },
    update: {},
    create: {
      email: 'demo@sailor.dev',
      passwordHash: demoHash,
      name: 'Demo User',
    },
  });

  console.log('Seed done: exam', exam.slug, 'product', product.name, 'user demo@sailor.dev / demo1234');
}

main()
  .then(() => prisma.$disconnect())
  .catch((e) => {
    console.error(e);
    prisma.$disconnect();
    process.exit(1);
  });
