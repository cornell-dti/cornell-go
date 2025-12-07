import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import { AppModule } from '../app.module';
import { QuizService } from './quiz.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuthType, EnrollmentType } from '@prisma/client';

describe('Quiz Module E2E', () => {
  let app: INestApplication;
  let moduleRef: TestingModule;
  let quizService: QuizService;
  let prisma: PrismaService;

  // Test data IDs
  let testUserId: string;
  let testChallengeId: string;
  let testQuestionId: string;
  let correctAnswerId: string;
  let incorrectAnswerId: string;
  let testGroupId: string;

  beforeAll(async () => {
    // Setup: Create test environment
    moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();

    quizService = moduleRef.get<QuizService>(QuizService);
    prisma = moduleRef.get<PrismaService>(PrismaService);

    // Create test data
    await setupTestData();
  });

  afterAll(async () => {
    // Cleanup: Delete test data and close connections
    await cleanupTestData();
    await app.close();
  });

  // Test for Quiz Service

  describe('QuizService', () => {
    it('should get a random question for a challenge', async () => {
      const question = await quizService.getRandomQuestion(
        testChallengeId,
        testUserId,
      );

      expect(question).toBeDefined();
      expect(question.id).toBeDefined();
      expect(question.questionText).toBeDefined();
      expect(question.answers).toHaveLength(4);
      expect(question.pointValue).toBeGreaterThan(0);
      expect(question.challengeId).toBe(testChallengeId);
    });

    it('should shuffle answers for each question request', async () => {
      const question1 = await quizService.getRandomQuestion(
        testChallengeId,
        testUserId,
      );
      const question2 = await quizService.getRandomQuestion(
        testChallengeId,
        testUserId,
      );

      // Answers should be in different order (statistically likely)
      const order1 = question1.answers.map(a => a.id).join(',');
      const order2 = question2.answers.map(a => a.id).join(',');

      // This might occasionally fail due to randomness, but very unlikely
      expect(order1).not.toBe(order2);
    });

    it('should shuffle to a different question', async () => {
      const newQuestion = await quizService.shuffleQuestion(
        testChallengeId,
        testUserId,
        testQuestionId,
      );

      expect(newQuestion).toBeDefined();
      expect(newQuestion.id).not.toBe(testQuestionId);
    });

    it('should correctly validate and record an incorrect answer', async () => {
      // Create a new user for this test
      const newUser = await prisma.user.create({
        data: {
          username: `test-user-${Date.now()}`,
          email: `test-${Date.now()}@test.com`,
          authToken: `test-auth-token-${Date.now()}`,
          authType: AuthType.NONE,
          year: '2024',
          college: 'Test College',
          major: 'Test Major',
          interests: ['testing', 'quiz'],
          hashedRefreshToken: 'test-refresh-token',
          administrator: false,
          enrollmentType: EnrollmentType.UNDERGRADUATE,
          score: 0,
          groupId: testGroupId,
        },
      });

      const result = await quizService.submitAnswer(
        newUser.id,
        testQuestionId,
        incorrectAnswerId,
      );

      expect(result.isCorrect).toBe(false);
      expect(result.pointsEarned).toBe(0);
      expect(result.correctAnswerText).toBeDefined();

      await prisma.user.delete({ where: { id: newUser.id } });
    });

    it('should prevent answering the same question twice', async () => {
      const newUser = await prisma.user.create({
        data: {
          username: `test-user-${Date.now()}`,
          email: `test-${Date.now()}@test.com`,
          authToken: `test-auth-token-${Date.now()}`,
          authType: AuthType.NONE,
          year: '2024',
          college: 'Test College',
          major: 'Test Major',
          interests: ['testing', 'quiz'],
          hashedRefreshToken: 'test-refresh-token',
          administrator: false,
          enrollmentType: EnrollmentType.UNDERGRADUATE,
          score: 0,
          groupId: testGroupId,
        },
      });

      await quizService.submitAnswer(
        newUser.id,
        testQuestionId,
        correctAnswerId,
      );

      await expect(
        quizService.submitAnswer(newUser.id, testQuestionId, correctAnswerId),
      ).rejects.toThrow('already answered');

      await prisma.user.delete({ where: { id: newUser.id } });
    });

    it('should track quiz progress correctly', async () => {
      const newUser = await prisma.user.create({
        data: {
          username: `test-user-${Date.now()}`,
          email: `test-${Date.now()}@test.com`,
          authToken: `test-auth-token-${Date.now()}`,
          authType: AuthType.NONE,
          year: '2024',
          college: 'Test College',
          major: 'Test Major',
          interests: ['testing', 'quiz'],
          hashedRefreshToken: 'test-refresh-token',
          administrator: false,
          enrollmentType: EnrollmentType.UNDERGRADUATE,
          score: 0,
          groupId: testGroupId,
        },
      });

      const progress = await quizService.getQuizProgress(
        testChallengeId,
        newUser.id,
      );

      expect(progress.challengeId).toBe(testChallengeId);
      expect(progress.totalQuestions).toBeGreaterThan(0);
      expect(progress.answeredQuestions).toBe(0);
      expect(progress.remainingQuestions).toBe(progress.totalQuestions);
      expect(progress.isComplete).toBe(false);
      expect(progress.totalPointsEarned).toBe(0);

      await prisma.user.delete({ where: { id: newUser.id } });
    });

    it('should get available question count', async () => {
      const count = await quizService.getAvailableQuestionCount(
        testChallengeId,
        testUserId,
      );

      expect(count).toBeGreaterThanOrEqual(0);
    });
  });

  // Helper Functions

  async function setupTestData() {
    const event = await prisma.eventBase.create({
      data: {
        name: 'Test Event',
        description: 'Test event for quiz e2e tests',
        longDescription: 'Long description for test event',
        requiredMembers: 1,
        timeLimitation: 'PERPETUAL',
        indexable: true,
        endTime: new Date('2099-12-31'),
        latitude: 42.4534,
        longitude: -76.4735,
        difficulty: 'EASY',
        category: 'FOOD',
      },
    });
    const group = await prisma.group.create({
      data: {
        friendlyId: `test-group-${Date.now()}`,
        curEventId: event.id,
      },
    });
    testGroupId = group.id;

    // Create test user
    const user = await prisma.user.create({
      data: {
        username: `test-user-${Date.now()}`,
        email: `test-${Date.now()}@test.com`,
        authToken: `test-auth-token-${Date.now()}`,
        authType: AuthType.NONE,
        year: '2024',
        college: 'Test College',
        major: 'Test Major',
        interests: ['testing', 'quiz'],
        hashedRefreshToken: 'test-refresh-token',
        administrator: false,
        enrollmentType: EnrollmentType.UNDERGRADUATE,
        score: 0,
        groupId: testGroupId,
      },
    });
    testUserId = user.id;

    // Create test challenge
    const challenge = await prisma.challenge.create({
      data: {
        name: 'Test Quiz Challenge',
        description: 'Test challenge for quiz e2e tests',
        latitude: 42.4534,
        longitude: -76.4735,
        location: 'CENTRAL_CAMPUS',
        points: 100,
        imageUrl: 'https://example.com/image.jpg',
        awardingRadius: 50,
        closeRadius: 100,
        eventIndex: 0,
      },
    });
    testChallengeId = challenge.id;

    // Create test questions with answers
    const question = await prisma.quizQuestion.create({
      data: {
        challengeId: testChallengeId,
        questionText: 'What is 2 + 2?',
        pointValue: 10,
        explanation: 'Basic math',
        category: 'FOOD',
        answers: {
          create: [
            { answerText: '4', isCorrect: true },
            { answerText: '3', isCorrect: false },
            { answerText: '5', isCorrect: false },
            { answerText: '22', isCorrect: false },
          ],
        },
      },
      include: { answers: true },
    });
    testQuestionId = question.id;
    correctAnswerId = question.answers.find(a => a.isCorrect)!.id;
    incorrectAnswerId = question.answers.find(a => !a.isCorrect)!.id;

    // Create additional questions for shuffle testing
    await prisma.quizQuestion.create({
      data: {
        challengeId: testChallengeId,
        questionText: 'What is 3 + 3?',
        pointValue: 10,
        category: 'FOOD',
        answers: {
          create: [
            { answerText: '6', isCorrect: true },
            { answerText: '5', isCorrect: false },
            { answerText: '7', isCorrect: false },
            { answerText: '33', isCorrect: false },
          ],
        },
      },
    });
  }

  async function cleanupTestData() {
    // Delete in correct order due to foreign key constraints
    await prisma.userQuizAnswer.deleteMany({
      where: { userId: testUserId },
    });
    await prisma.quizAnswer.deleteMany({
      where: { question: { challengeId: testChallengeId } },
    });
    await prisma.quizQuestion.deleteMany({
      where: { challengeId: testChallengeId },
    });
    await prisma.challenge.delete({
      where: { id: testChallengeId },
    });
    await prisma.user.deleteMany({
      where: {
        OR: [{ id: testUserId }, { email: { contains: '@test.com' } }],
      },
    });
  }
});
