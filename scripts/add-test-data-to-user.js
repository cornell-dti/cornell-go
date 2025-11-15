/**
 * Script to add test data to a user account for profile page testing.
 * 
 * This script:
 * - Completes 2 full events/journeys (all challenges) for the user
 * - Creates/completes 4 achievements for the user
 * - Updates the user's score based on completed challenges
 */

const { PrismaClient } = require('../server/node_modules/@prisma/client');
const path = require('path');

// Load environment variables from server/.env
require('../server/node_modules/dotenv').config({ path: path.join(__dirname, '../server/.env') });

const prisma = new PrismaClient();

async function main() {
  // Replace this with your actual Cornell email
  const userEmail = 'email@cornell.edu'; 
  
  console.log(`Looking for user: ${userEmail}`);
  
  // Find the user by email
  const user = await prisma.user.findFirst({
    where: { email: userEmail },
  });
  
  if (!user) {
    console.error('ERROR: User not found. Have you logged in to the app yet?');
    console.error('       Login first, then run this script.');
    process.exit(1);
  }
  
  console.log(`Found user: ${user.username} (${user.email})`);
  
  // Get user's organizations - events and achievements must be linked to these
  // for them to be visible in the app
  const userWithOrgs = await prisma.user.findUnique({
    where: { id: user.id },
    include: { memberOf: true },
  });
  
  const orgIds = userWithOrgs.memberOf.map(org => org.id);
  console.log(`User's organizations: ${userWithOrgs.memberOf.map(o => o.name).join(', ')}`);
  
  // Fetch 2 events that belong to the user's organizations
  // We'll complete ALL challenges in these events to show them as "completed events"
  const events = await prisma.eventBase.findMany({
    where: {
      usedIn: {
        some: {
          id: { in: orgIds },
        },
      },
    },
    take: 2,
    include: {
      challenges: {
        orderBy: { eventIndex: 'asc' },
      },
    },
  });
  
  if (events.length < 2) {
    console.error(`ERROR: Not enough events in database (found ${events.length}, need 2)`);
    console.error('       Run the seed script first: npm run seed');
    process.exit(1);
  }
  
  const challenges = events.flatMap(event => event.challenges);
  
  if (challenges.length === 0) {
    console.error(`ERROR: Events have no challenges`);
    console.error('       Run the seed script first: npm run seed');
    process.exit(1);
  }
  
  // Get or create 4 achievements that belong to the user's organizations
  let achievements = await prisma.achievement.findMany({
    where: {
      organizations: {
        some: {
          id: { in: orgIds },
        },
      },
    },
    take: 4,
  });
  
  // Create missing achievements if we don't have 4
  if (achievements.length < 4) {
    console.log(`Found only ${achievements.length} achievements, creating ${4 - achievements.length} more...`);
    
    const achievementsToCreate = [
      {
        requiredPoints: 100,
        name: 'Getting Started',
        description: 'Complete your first 100 points',
        imageUrl: 'https://images.unsplash.com/photo-1567446537708-ac4aa75c9c28?w=400',
        locationType: 'ANY',
        achievementType: 'TOTAL_POINTS',
        organizations: {
          connect: orgIds.map(id => ({ id })),
        },
      },
      {
        requiredPoints: 3,
        name: 'Challenge Seeker',
        description: 'Complete 3 challenges',
        imageUrl: 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=400',
        locationType: 'ANY',
        achievementType: 'TOTAL_CHALLENGES',
        organizations: {
          connect: orgIds.map(id => ({ id })),
        },
      },
      {
        requiredPoints: 1,
        name: 'Journey Beginner',
        description: 'Complete your first journey',
        imageUrl: 'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=400',
        locationType: 'ANY',
        achievementType: 'TOTAL_JOURNEYS',
        organizations: {
          connect: orgIds.map(id => ({ id })),
        },
      },
      {
        requiredPoints: 250,
        name: 'Point Master',
        description: 'Achieve 250 total points',
        imageUrl: 'https://images.unsplash.com/photo-1606326608690-4e0281b1e588?w=400',
        locationType: 'ANY',
        achievementType: 'TOTAL_POINTS',
        organizations: {
          connect: orgIds.map(id => ({ id })),
        },
      },
    ];
    
    const neededCount = 4 - achievements.length;
    for (let i = 0; i < neededCount; i++) {
      const newAchievement = await prisma.achievement.create({
        data: achievementsToCreate[i],
      });
      achievements.push(newAchievement);
    }
    
    console.log(`Created ${neededCount} new achievements`);
  }
  
  // Clear any existing test data for this user
  console.log('Clearing existing test data...');
  await prisma.prevChallenge.deleteMany({ where: { userId: user.id } });
  await prisma.achievementTracker.deleteMany({ where: { userId: user.id } });
  
  // Complete all challenges in the selected events
  // For each challenge, we need to create/update an event tracker and a prevChallenge record
  console.log(`Completing ${events.length} full events (${challenges.length} challenges)...`);
  
  for (const challenge of challenges) {
    const challengeWithEvent = await prisma.challenge.findUnique({
      where: { id: challenge.id },
      include: { linkedEvent: true },
    });
    
    if (!challengeWithEvent?.linkedEventId) {
      console.warn(`WARNING: Challenge ${challenge.name} has no linked event, skipping...`);
      continue;
    }
    
    // Get or create event tracker for this user and event
    let tracker = await prisma.eventTracker.findFirst({
      where: {
        userId: user.id,
        eventId: challengeWithEvent.linkedEventId,
      },
    });
    
    if (!tracker) {
      tracker = await prisma.eventTracker.create({
        data: {
          userId: user.id,
          eventId: challengeWithEvent.linkedEventId,
          score: challenge.points,
          hintsUsed: 0,
          isRankedForEvent: true,
        },
      });
    } else {
      // Update tracker score
      await prisma.eventTracker.update({
        where: { id: tracker.id },
        data: { score: tracker.score + challenge.points },
      });
    }
    
    // Create the completed challenge record
    await prisma.prevChallenge.create({
      data: {
        userId: user.id,
        challengeId: challenge.id,
        trackerId: tracker.id,
        hintsUsed: 0,
      },
    });
  }
  
  // Create achievement trackers with completed progress
  console.log('Adding 4 completed achievements...');
  await prisma.achievementTracker.createMany({
    data: achievements.map(achievement => ({
      userId: user.id,
      achievementId: achievement.id,
      progress: achievement.requiredPoints, // Set progress to meet requirement
    })),
  });
  
  // Update user score based on completed challenges
  const totalChallengePoints = challenges.reduce((sum, c) => sum + c.points, 0);
  await prisma.user.update({
    where: { id: user.id },
    data: { score: Math.max(user.score, totalChallengePoints) },
  });
  
  // Print summary
  console.log('');
  console.log('SUCCESS: Test data added!');
  console.log(`  - ${events.length} completed events`);
  console.log(`  - ${challenges.length} completed challenges`);
  console.log(`  - 4 completed achievements`);
  console.log(`  - Updated score: ${Math.max(user.score, totalChallengePoints)}`);
  console.log('');
  console.log('Your profile page should now show:');
  console.log('');
  console.log('Completed Events:');
  events.forEach((e, i) => console.log(`  ${i + 1}. ${e.name} (${e.challenges.length} challenges)`));
  console.log('');
  console.log('Achievements:');
  achievements.forEach((a, i) => console.log(`  ${i + 1}. ${a.name}`));
}

main()
  .catch(e => {
    console.error('ERROR:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
