import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Starting database seed...');

  // Safety check: prevent accidental seeding of production database
  const databaseUrl = process.env.DATABASE_URL || '';
  if (
    databaseUrl.includes('amazonaws') ||
    databaseUrl.includes('heroku') ||
    databaseUrl.includes('prod')
  ) {
    console.error('❌ ABORT: This appears to be a production database URL!');
    console.error('   Seeding would DELETE ALL PRODUCTION DATA.');
    console.error(
      '   Update DATABASE_URL in .env to point to a local/dev database.',
    );
    process.exit(1);
  }

  console.log(`📍 Database: ${databaseUrl.split('@')[1] || 'localhost'}`);

  // Clear existing data (order matters due to foreign keys)
  console.log('🗑️  Clearing existing data...');
  await prisma.achievementTracker.deleteMany();
  await prisma.achievement.deleteMany();
  await prisma.sessionLogEntry.deleteMany();
  await prisma.prevChallenge.deleteMany();
  await prisma.eventTracker.deleteMany();
  await prisma.challenge.deleteMany();
  await prisma.userBearEquipped.deleteMany();
  await prisma.userBearInventory.deleteMany();
  await prisma.user.deleteMany(); // Users before groups (User has groupId FK)
  await prisma.group.deleteMany();
  await prisma.eventBase.deleteMany();
  await prisma.organization.deleteMany();
  await prisma.bearItem.deleteMany();

  // Create Organizations
  console.log('🏛️  Creating organizations...');
  const cornellOrg = await prisma.organization.create({
    data: {
      name: 'Cornell University',
      accessCode: 'CORNELL2024',
      specialUsage: 'CORNELL_LOGIN',
    },
  });

  const engineeringOrg = await prisma.organization.create({
    data: {
      name: 'Cornell Engineering',
      accessCode: 'ENGQUAD2024',
      specialUsage: 'NONE',
    },
  });

  const artsOrg = await prisma.organization.create({
    data: {
      name: 'College of Arts & Sciences',
      accessCode: 'ARTS2024',
      specialUsage: 'NONE',
    },
  });

  // Create Events
  console.log('🎯 Creating events...');
  const campusTourEvent = await prisma.eventBase.create({
    data: {
      requiredMembers: 1,
      name: 'Cornell Campus Classics',
      description:
        "Explore the most iconic spots on Cornell's beautiful campus.",
      longDescription:
        'Join us for the Cornell Campus Classics tour, where you will visit the most iconic and picturesque locations on campus. Start at the Engineering Quad, marvel at the architecture of Uris Library, and take in the serene beauty of Libe Slope. Along the way, learn fascinating facts about Cornell history and traditions. Do not forget to snap some photos at these must-see spots!',
      timeLimitation: 'PERPETUAL',
      indexable: true,
      endTime: new Date('2030-12-31'),
      latitude: 42.4534,
      longitude: -76.4735,
      difficulty: 'EASY',
      category: 'HISTORICAL',
      usedIn: {
        connect: [{ id: cornellOrg.id }],
      },
    },
  });

  const foodieEvent = await prisma.eventBase.create({
    data: {
      requiredMembers: 1,
      name: 'Ithaca Foodie Adventure',
      description:
        'Discover the best eats around Cornell and Ithaca!',
      longDescription:
        'Embark on the Ithaca Foodie Adventure and savor the diverse culinary delights that Cornell and the surrounding Ithaca area have to offer. Start your journey at one of Cornell\'s renowned dining halls, where you can sample a variety of dishes made with fresh, local ingredients. Then, venture into downtown Ithaca to explore charming cafes, food trucks, and restaurants that showcase the region\'s vibrant food scene. Whether you\'re craving farm-to-table fare or international cuisine, this adventure promises a feast for your taste buds!',
      timeLimitation: 'PERPETUAL',
      indexable: true,
      endTime: new Date('2030-12-31'),
      latitude: 42.4534,
      longitude: -76.4735,
      difficulty: 'NORMAL',
      category: 'FOOD',
      usedIn: {
        connect: [{ id: cornellOrg.id }],
      },
    },
  });

  const natureEvent = await prisma.eventBase.create({
    data: {
      requiredMembers: 1,
      name: 'Gorges Nature Trail',
      description:
        'Ithaca is Gorges! Explore the stunning natural beauty surrounding Cornell, from waterfalls to hiking trails.',
      longDescription:
        'Experience the breathtaking natural beauty of Ithaca with the Gorges Nature Trail tour. Known for its stunning waterfalls, lush forests, and scenic hiking trails, Ithaca offers a perfect escape into nature. Begin your adventure at one of the many gorges near Cornell University, where you can take in the sights and sounds of cascading water and vibrant wildlife. As you hike through the trails, enjoy panoramic views of the surrounding landscape and discover hidden gems along the way. Whether you are an avid hiker or simply looking to unwind in nature, this tour is sure to leave you refreshed and inspired.',
      timeLimitation: 'PERPETUAL',
      indexable: true,
      endTime: new Date('2030-12-31'),
      latitude: 42.4534,
      longitude: -76.4735,
      difficulty: 'HARD',
      category: 'NATURE',
      usedIn: {
        connect: [{ id: cornellOrg.id }],
      },
    },
  });

  // Create Users
  console.log('👥 Creating users...');
  const hashedRefreshToken = 'hashed_refresh_token_placeholder';

  const users = await Promise.all([
    // Student users
    prisma.user.create({
      data: {
        authToken: 'google_auth_token_1',
        authType: 'GOOGLE',
        username: 'big_red_explorer',
        year: '2025',
        college: 'College of Engineering',
        major: 'Computer Science',
        interests: ['Technology', 'Hiking', 'Photography'],
        email: 'explorer@cornell.edu',
        hashedRefreshToken,
        administrator: false,
        enrollmentType: 'UNDERGRADUATE',
        score: 285,
        coins: 100,
        hasCompletedOnboarding: false,
        group: {
          create: {
            friendlyId: 'GROUP001',
            curEventId: campusTourEvent.id,
          },
        },
        memberOf: {
          connect: [{ id: cornellOrg.id }, { id: engineeringOrg.id }],
        },
      },
    }),
    prisma.user.create({
      data: {
        authToken: 'google_auth_token_2',
        authType: 'GOOGLE',
        username: 'ezra_cornell_fan',
        year: '2026',
        college: 'College of Arts & Sciences',
        major: 'Biology',
        interests: ['Nature', 'History', 'Coffee'],
        email: 'ezrafan@cornell.edu',
        hashedRefreshToken,
        administrator: false,
        enrollmentType: 'UNDERGRADUATE',
        score: 420,
        coins: 150,
        hasCompletedOnboarding: false,
        group: {
          create: {
            friendlyId: 'GROUP002',
            curEventId: campusTourEvent.id,
          },
        },
        memberOf: {
          connect: [{ id: cornellOrg.id }, { id: artsOrg.id }],
        },
      },
    }),
    prisma.user.create({
      data: {
        authToken: 'apple_auth_token_3',
        authType: 'APPLE',
        username: 'clocktower_climber',
        year: '2025',
        college: 'College of Agriculture and Life Sciences',
        major: 'Animal Science',
        interests: ['Animals', 'Food', 'Campus Tours'],
        email: 'climber@cornell.edu',
        hashedRefreshToken,
        administrator: false,
        enrollmentType: 'UNDERGRADUATE',
        score: 155,
        coins: 50,
        hasCompletedOnboarding: false,
        group: {
          create: {
            friendlyId: 'GROUP003',
            curEventId: foodieEvent.id,
          },
        },
        memberOf: {
          connect: [{ id: cornellOrg.id }],
        },
      },
    }),
    prisma.user.create({
      data: {
        authToken: 'google_auth_token_4',
        authType: 'GOOGLE',
        username: 'gorge_wanderer',
        year: '2027',
        college: 'College of Engineering',
        major: 'Mechanical Engineering',
        interests: ['Hiking', 'Nature', 'Engineering'],
        email: 'wanderer@cornell.edu',
        hashedRefreshToken,
        administrator: false,
        enrollmentType: 'UNDERGRADUATE',
        score: 340,
        coins: 125,
        hasCompletedOnboarding: false,
        group: {
          create: {
            friendlyId: 'GROUP004',
            curEventId: natureEvent.id,
          },
        },
        memberOf: {
          connect: [{ id: cornellOrg.id }, { id: engineeringOrg.id }],
        },
      },
    }),
    prisma.user.create({
      data: {
        authToken: 'google_auth_token_5',
        authType: 'GOOGLE',
        username: 'slope_day_enthusiast',
        year: '2026',
        college: 'School of Hotel Administration',
        major: 'Hotel Management',
        interests: ['Events', 'Food', 'Music'],
        email: 'slope@cornell.edu',
        hashedRefreshToken,
        administrator: false,
        enrollmentType: 'UNDERGRADUATE',
        score: 90,
        coins: 25,
        hasCompletedOnboarding: false,
        group: {
          create: {
            friendlyId: 'GROUP005',
            curEventId: foodieEvent.id,
          },
        },
        memberOf: {
          connect: [{ id: cornellOrg.id }],
        },
      },
    }),
    prisma.user.create({
      data: {
        authToken: 'google_auth_token_6',
        authType: 'GOOGLE',
        username: 'dragon_day_champion',
        year: '2025',
        college: 'College of Architecture, Art, and Planning',
        major: 'Architecture',
        interests: ['Design', 'Art', 'Campus Culture'],
        email: 'dragon@cornell.edu',
        hashedRefreshToken,
        administrator: false,
        enrollmentType: 'UNDERGRADUATE',
        score: 215,
        coins: 75,
        hasCompletedOnboarding: false,
        group: {
          create: {
            friendlyId: 'GROUP006',
            curEventId: campusTourEvent.id,
          },
        },
        memberOf: {
          connect: [{ id: cornellOrg.id }],
        },
      },
    }),
    prisma.user.create({
      data: {
        authToken: 'google_auth_token_7',
        authType: 'GOOGLE',
        username: 'lynah_faithful',
        year: '2026',
        college: 'College of Engineering',
        major: 'Electrical Engineering',
        interests: ['Hockey', 'Sports', 'Technology'],
        email: 'lynah@cornell.edu',
        hashedRefreshToken,
        administrator: false,
        enrollmentType: 'UNDERGRADUATE',
        score: 175,
        coins: 60,
        hasCompletedOnboarding: false,
        group: {
          create: {
            friendlyId: 'GROUP007',
            curEventId: natureEvent.id,
          },
        },
        memberOf: {
          connect: [{ id: cornellOrg.id }, { id: engineeringOrg.id }],
        },
      },
    }),
    // Graduate student
    prisma.user.create({
      data: {
        authToken: 'google_auth_token_8',
        authType: 'GOOGLE',
        username: 'grad_student_extraordinaire',
        year: '2025',
        college: 'Graduate School',
        major: 'Computer Science PhD',
        interests: ['Research', 'AI', 'Teaching'],
        email: 'gradstudent@cornell.edu',
        hashedRefreshToken,
        administrator: false,
        enrollmentType: 'GRADUATE',
        score: 260,
        coins: 90,
        hasCompletedOnboarding: false,
        group: {
          create: {
            friendlyId: 'GROUP008',
            curEventId: campusTourEvent.id,
          },
        },
        memberOf: {
          connect: [{ id: cornellOrg.id }],
        },
      },
    }),
    // Alumni
    prisma.user.create({
      data: {
        authToken: 'google_auth_token_9',
        authType: 'GOOGLE',
        username: 'proud_alum_2020',
        year: '2020',
        college: 'College of Arts & Sciences',
        major: 'Economics',
        interests: ['Nostalgia', 'Networking', 'Homecoming'],
        email: 'alum@cornell.edu',
        hashedRefreshToken,
        administrator: false,
        enrollmentType: 'ALUMNI',
        score: 50,
        coins: 15,
        hasCompletedOnboarding: false,
        group: {
          create: {
            friendlyId: 'GROUP009',
            curEventId: foodieEvent.id,
          },
        },
        memberOf: {
          connect: [{ id: cornellOrg.id }],
        },
      },
    }),
    // Admin user
    prisma.user.create({
      data: {
        authToken: 'google_auth_token_admin',
        authType: 'GOOGLE',
        username: 'admin_big_red',
        year: '2024',
        college: 'College of Engineering',
        major: 'Information Science',
        interests: ['Administration', 'Event Planning', 'Community'],
        email: 'admin@cornell.edu',
        hashedRefreshToken,
        administrator: true,
        enrollmentType: 'UNDERGRADUATE',
        score: 385,
        coins: 200,
        hasCompletedOnboarding: false,
        group: {
          create: {
            friendlyId: 'GROUP010',
            curEventId: campusTourEvent.id,
          },
        },
        memberOf: {
          connect: [{ id: cornellOrg.id }],
        },
        managerOf: {
          connect: [{ id: cornellOrg.id }, { id: engineeringOrg.id }],
        },
      },
    }),
  ]);

  // Create Challenges for Campus Tour Event
  console.log('🎮 Creating challenges...');
  await prisma.challenge.createMany({
    data: [
      {
        linkedEventId: campusTourEvent.id,
        eventIndex: 0,
        name: 'McGraw Tower Clock',
        location: 'CENTRAL_CAMPUS',
        description:
          'Visit the iconic McGraw Tower and its famous chimes. Listen for the daily concerts that echo across campus!',
        points: 100,
        imageUrl:
          'https://advocacy.ou.org/content/uploads/AdobeStock_491923441_Editorial_Use_Only-scaled.jpeg?w=800',
        latitude: 42.4476,
        longitude: -76.4847,
        awardingRadius: 50,
        closeRadius: 100,
      },
      {
        linkedEventId: campusTourEvent.id,
        eventIndex: 1,
        name: 'A.D. White Reading Room',
        location: 'CENTRAL_CAMPUS',
        description:
          'Step into the stunning A.D. White Reading Room in Uris Library, one of the most beautiful study spaces on campus.',
        points: 75,
        imageUrl:
          'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800',
        latitude: 42.4478,
        longitude: -76.4839,
        awardingRadius: 40,
        closeRadius: 80,
      },
      {
        linkedEventId: campusTourEvent.id,
        eventIndex: 2,
        name: 'Engineering Quad Fountain',
        location: 'ENG_QUAD',
        description:
          'Find the fountain at the heart of the Engineering Quad, a popular gathering spot for engineers.',
        points: 100,
        imageUrl:
          'https://images.unsplash.com/photo-1562774053-701939374585?w=800',
        latitude: 42.4446,
        longitude: -76.4832,
        awardingRadius: 50,
        closeRadius: 100,
      },
      {
        linkedEventId: campusTourEvent.id,
        eventIndex: 3,
        name: 'Sage Chapel',
        location: 'CENTRAL_CAMPUS',
        description:
          "Visit the beautiful Sage Chapel, Cornell's spiritual center and a stunning example of Gothic architecture.",
        points: 60,
        imageUrl:
          'https://images.unsplash.com/photo-1548625149-fc4a29cf7092?w=800',
        latitude: 42.4484,
        longitude: -76.4854,
        awardingRadius: 45,
        closeRadius: 90,
      },
      {
        linkedEventId: campusTourEvent.id,
        eventIndex: 4,
        name: 'Ezra Cornell Statue',
        location: 'ARTS_QUAD',
        description:
          'Pay respects to our founder! Find the statue of Ezra Cornell on the Arts Quad.',
        points: 100,
        imageUrl:
          'https://giving.cornell.edu/wp-content/uploads/2023/06/ezra-cornell-statue-bw.jpg?w=800',
        latitude: 42.4489,
        longitude: -76.4843,
        awardingRadius: 30,
        closeRadius: 60,
      },
    ],
  });

  // Create Challenges for Foodie Event
  await prisma.challenge.createMany({
    data: [
      {
        linkedEventId: foodieEvent.id,
        eventIndex: 0,
        name: 'Okenshields Dining Hall',
        location: 'CENTRAL_CAMPUS',
        description:
          "Visit Okenshields, one of Cornell's largest dining halls, known for its diverse food stations.",
        points: 80,
        imageUrl:
          'https://media.thetab.com/blogs.dir/105/files/2017/03/okenshields-e1490725164257.jpg?w=800',
        latitude: 42.4491,
        longitude: -76.4856,
        awardingRadius: 50,
        closeRadius: 100,
      },
      {
        linkedEventId: foodieEvent.id,
        eventIndex: 1,
        name: 'Collegetown Bagels',
        location: 'COLLEGETOWN',
        description:
          'Grab a classic CTB bagel sandwich, a Cornell student staple!',
        points: 70,
        imageUrl:
          'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=800',
        latitude: 42.4406,
        longitude: -76.4844,
        awardingRadius: 40,
        closeRadius: 80,
      },
      {
        linkedEventId: foodieEvent.id,
        eventIndex: 2,
        name: 'Libe Café',
        location: 'CENTRAL_CAMPUS',
        description:
          'Stop by Libe Café for a coffee or snack while studying in the library.',
        points: 55,
        imageUrl:
          'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800',
        latitude: 42.4478,
        longitude: -76.4839,
        awardingRadius: 35,
        closeRadius: 70,
      },
      {
        linkedEventId: foodieEvent.id,
        eventIndex: 3,
        name: 'Cornell Dairy Bar',
        location: 'AG_QUAD',
        description:
          'Treat yourself to the famous Cornell ice cream made right on campus!',
        points: 65,
        imageUrl:
          'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=800',
        latitude: 42.4494,
        longitude: -76.4777,
        awardingRadius: 45,
        closeRadius: 90,
      },
    ],
  });

  // Create Challenges for Nature Event
  await prisma.challenge.createMany({
    data: [
      {
        linkedEventId: natureEvent.id,
        eventIndex: 0,
        name: 'Fall Creek Gorge Trail',
        location: 'ANY',
        description:
          'Hike along the stunning Fall Creek Gorge and take in the natural beauty of Ithaca.',
        points: 90,
        imageUrl:
          'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800',
        latitude: 42.4564,
        longitude: -76.4658,
        awardingRadius: 100,
        closeRadius: 200,
      },
      {
        linkedEventId: natureEvent.id,
        eventIndex: 1,
        name: 'Beebe Lake',
        location: 'NORTH_CAMPUS',
        description:
          'Discover the peaceful Beebe Lake, perfect for a quiet walk or run.',
        points: 85,
        imageUrl:
          'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
        latitude: 42.4548,
        longitude: -76.4794,
        awardingRadius: 80,
        closeRadius: 160,
      },
      {
        linkedEventId: natureEvent.id,
        eventIndex: 2,
        name: 'Trillium Trail',
        location: 'ANY',
        description:
          'Walk the scenic Trillium Trail in the Cornell Plantations.',
        points: 95,
        imageUrl:
          'https://images.unsplash.com/photo-1511497584788-876760111969?w=800',
        latitude: 42.4551,
        longitude: -76.4699,
        awardingRadius: 70,
        closeRadius: 140,
      },
    ],
  });

  // Create Achievements (must be created individually to link to organizations)
  console.log('🏆 Creating achievements...');

  const achievement1 = await prisma.achievement.create({
    data: {
      requiredPoints: 200,
      name: 'Campus Explorer',
      description: 'Complete 200 points worth of challenges',
      imageUrl:
        'https://images.unsplash.com/photo-1567446537708-ac4aa75c9c28?w=400',
      linkedEventId: campusTourEvent.id,
      locationType: 'ANY',
      achievementType: 'TOTAL_POINTS',
      organizations: {
        connect: [{ id: cornellOrg.id }],
      },
    },
  });

  const achievement2 = await prisma.achievement.create({
    data: {
      requiredPoints: 5,
      name: 'Challenge Champion',
      description: 'Complete 5 challenges',
      imageUrl:
        'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=400',
      locationType: 'ANY',
      achievementType: 'TOTAL_CHALLENGES',
      organizations: {
        connect: [{ id: cornellOrg.id }],
      },
    },
  });

  const achievement3 = await prisma.achievement.create({
    data: {
      requiredPoints: 2,
      name: 'Journey Master',
      description: 'Complete 2 full journeys',
      imageUrl:
        'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=400',
      locationType: 'ANY',
      achievementType: 'TOTAL_JOURNEYS',
      organizations: {
        connect: [{ id: cornellOrg.id }],
      },
    },
  });

  const achievement4 = await prisma.achievement.create({
    data: {
      requiredPoints: 400,
      name: 'Big Red Legend',
      description: 'Achieve 400 total points',
      imageUrl:
        'https://images.unsplash.com/photo-1606326608690-4e0281b1e588?w=400',
      locationType: 'ANY',
      achievementType: 'TOTAL_POINTS',
      organizations: {
        connect: [{ id: cornellOrg.id }],
      },
    },
  });

  // Create achievement trackers for all existing users
  console.log('📊 Creating achievement trackers for users...');
  for (const user of users) {
    await prisma.achievementTracker.createMany({
      data: [
        {
          userId: user.id,
          progress: 0,
          achievementId: achievement1.id,
        },
        {
          userId: user.id,
          progress: 0,
          achievementId: achievement2.id,
        },
        {
          userId: user.id,
          progress: 0,
          achievementId: achievement3.id,
        },
        {
          userId: user.id,
          progress: 0,
          achievementId: achievement4.id,
        },
      ],
    });
  }

  // Update groups to set hosts
  console.log('👫 Updating groups with hosts...');
  const allGroups = await prisma.group.findMany();

  for (let i = 0; i < allGroups.length; i++) {
    await prisma.group.update({
      where: { id: allGroups[i].id },
      data: {
        hostId: users[i].id,
      },
    });
  }

  // Create BearItems for build-a-bear (COLOR slot)
  console.log('🐻 Creating bear color items...');
  await prisma.bearItem.createMany({
    data: [
      {
        name: 'Red Bear',
        slot: 'COLOR',
        cost: 0,
        assetKey: 'buildabear/color/redbear',
        mimeType: 'image/png',
        isDefault: true,
      },
      {
        name: 'Black Bear',
        slot: 'COLOR',
        cost: 25,
        assetKey: 'buildabear/color/blackbear',
        mimeType: 'image/png',
      },
      {
        name: 'Brown Bear',
        slot: 'COLOR',
        cost: 25,
        assetKey: 'buildabear/color/brownbear',
        mimeType: 'image/png',
      },
      {
        name: 'Grizzly Bear',
        slot: 'COLOR',
        cost: 25,
        assetKey: 'buildabear/color/grizzlybear',
        mimeType: 'image/png',
      },
      {
        name: 'Inverse Panda',
        slot: 'COLOR',
        cost: 25,
        assetKey: 'buildabear/color/inversepanda',
        mimeType: 'image/png',
      },
      {
        name: 'Panda Bear',
        slot: 'COLOR',
        cost: 25,
        assetKey: 'buildabear/color/pandabear',
        mimeType: 'image/png',
      },
      {
        name: 'Polar Bear',
        slot: 'COLOR',
        cost: 25,
        assetKey: 'buildabear/color/polarbear',
        mimeType: 'image/png',
      },
      {
        name: 'Shiba Bear',
        slot: 'COLOR',
        cost: 25,
        assetKey: 'buildabear/color/shibabear',
        mimeType: 'image/png',
      },
      {
        name: 'Sun Bear',
        slot: 'COLOR',
        cost: 25,
        assetKey: 'buildabear/color/sunbear',
        mimeType: 'image/png',
      },
    ],
  });

  // Create BearItems for build-a-bear (EYES slot)
  console.log('👀 Creating bear eyes items...');
  await prisma.bearItem.createMany({
    data: [
      {
        name: 'Default Eyes',
        slot: 'EYES',
        cost: 0,
        assetKey: 'buildabear/eyes/eyes',
        mimeType: 'image/png',
        isDefault: true,
      },
      {
        name: 'Content',
        slot: 'EYES',
        cost: 25,
        assetKey: 'buildabear/eyes/content',
        mimeType: 'image/png',
      },
      {
        name: 'Blush',
        slot: 'EYES',
        cost: 25,
        assetKey: 'buildabear/eyes/blush',
        mimeType: 'image/png',
      },
      {
        name: 'Cry',
        slot: 'EYES',
        cost: 25,
        assetKey: 'buildabear/eyes/cry',
        mimeType: 'image/png',
      },
      {
        name: 'Embarrassed',
        slot: 'EYES',
        cost: 25,
        assetKey: 'buildabear/eyes/embarrassed',
        mimeType: 'image/png',
      },
      {
        name: 'Evil',
        slot: 'EYES',
        cost: 25,
        assetKey: 'buildabear/eyes/evil',
        mimeType: 'image/png',
      },
      {
        name: 'Eyebrows',
        slot: 'EYES',
        cost: 25,
        assetKey: 'buildabear/eyes/eyebrows',
        mimeType: 'image/png',
      },
      {
        name: 'XX Eyes',
        slot: 'EYES',
        cost: 25,
        assetKey: 'buildabear/eyes/xx',
        mimeType: 'image/png',
      },
      {
        name: 'Angled Eyes',
        slot: 'EYES',
        cost: 25,
        assetKey: 'buildabear/eyes/><',
        mimeType: 'image/png',
      },
    ],
  });

  // Create BearItems for build-a-bear (MOUTH slot)
  console.log('👄 Creating bear mouth items...');
  await prisma.bearItem.createMany({
    data: [
      {
        name: 'Default Mouth',
        slot: 'MOUTH',
        cost: 0,
        assetKey: 'buildabear/mouth/mouth',
        mimeType: 'image/png',
        isDefault: true,
      },
      {
        name: 'Cheeks',
        slot: 'MOUTH',
        cost: 25,
        assetKey: 'buildabear/mouth/cheeks',
        mimeType: 'image/png',
      },
      {
        name: 'Frown',
        slot: 'MOUTH',
        cost: 25,
        assetKey: 'buildabear/mouth/frown',
        mimeType: 'image/png',
      },
      {
        name: 'Grin',
        slot: 'MOUTH',
        cost: 25,
        assetKey: 'buildabear/mouth/grin',
        mimeType: 'image/png',
      },
      {
        name: 'Nervous',
        slot: 'MOUTH',
        cost: 25,
        assetKey: 'buildabear/mouth/nervous',
        mimeType: 'image/png',
      },
      {
        name: 'Serious',
        slot: 'MOUTH',
        cost: 25,
        assetKey: 'buildabear/mouth/serious',
        mimeType: 'image/png',
      },
      {
        name: 'Smirk',
        slot: 'MOUTH',
        cost: 25,
        assetKey: 'buildabear/mouth/smirk',
        mimeType: 'image/png',
      },
      {
        name: 'Tongue',
        slot: 'MOUTH',
        cost: 25,
        assetKey: 'buildabear/mouth/tongue',
        mimeType: 'image/png',
      },
      {
        name: 'UwU',
        slot: 'MOUTH',
        cost: 25,
        assetKey: 'buildabear/mouth/uwu',
        mimeType: 'image/png',
      },
    ],
  });

  // Create BearItems for build-a-bear (ACCESSORY slot)
  console.log('🎀 Creating bear accessory items...');
  await prisma.bearItem.createMany({
    data: [
      {
        name: 'Bow',
        slot: 'ACCESSORY',
        cost: 25,
        assetKey: 'buildabear/accessories/bow',
        mimeType: 'image/png',
      },
      {
        name: 'Bowtie',
        slot: 'ACCESSORY',
        cost: 25,
        assetKey: 'buildabear/accessories/bowtie',
        mimeType: 'image/png',
      },
      {
        name: 'Flower',
        slot: 'ACCESSORY',
        cost: 25,
        assetKey: 'buildabear/accessories/flower',
        mimeType: 'image/png',
      },
      {
        name: 'Glasses',
        slot: 'ACCESSORY',
        cost: 25,
        assetKey: 'buildabear/accessories/glasses',
        mimeType: 'image/png',
      },
      {
        name: 'Goatee',
        slot: 'ACCESSORY',
        cost: 25,
        assetKey: 'buildabear/accessories/goatee',
        mimeType: 'image/png',
      },
      {
        name: 'Necktie',
        slot: 'ACCESSORY',
        cost: 25,
        assetKey: 'buildabear/accessories/necktie',
        mimeType: 'image/png',
      },
      {
        name: 'Purse',
        slot: 'ACCESSORY',
        cost: 25,
        assetKey: 'buildabear/accessories/purse',
        mimeType: 'image/png',
      },
      {
        name: 'Scarf',
        slot: 'ACCESSORY',
        cost: 25,
        assetKey: 'buildabear/accessories/scarf',
        mimeType: 'image/png',
      },
      {
        name: 'Top Hat',
        slot: 'ACCESSORY',
        cost: 25,
        assetKey: 'buildabear/accessories/tophat',
        mimeType: 'image/png',
      },
    ],
  });

  // Seed default bear items into each user's inventory and equipped loadout
  console.log('🐻 Seeding default bear inventory & equipped for users...');
  const defaultBearItems = await prisma.bearItem.findMany({
    where: { isDefault: true },
  });

  for (const user of users) {
    for (const item of defaultBearItems) {
      // Add to inventory
      await prisma.userBearInventory.create({
        data: {
          userId: user.id,
          bearItemId: item.id,
        },
      });

      // Equip the default item for its slot
      await prisma.userBearEquipped.create({
        data: {
          userId: user.id,
          bearItemId: item.id,
          slot: item.slot,
        },
      });
    }
  }

  console.log('✅ Database seeded successfully!');
  console.log(`   📊 Created ${users.length} users`);
  console.log(`   🏛️  Created 3 organizations`);
  console.log(`   🎯 Created 3 events`);
  console.log(`   🎮 Created 12 challenges`);
  console.log(`   🏆 Created 4 achievements`);
  console.log(`   👫 Created ${users.length} groups`);
  console.log(`   🐻 Created 9 bear color items`);
  console.log(`   👀 Created 9 bear eyes items`);
  console.log(`   👄 Created 9 bear mouth items`);
  console.log(`   🎀 Created 9 bear accessory items`);
  console.log(`   🧸 Seeded ${defaultBearItems.length} default items x ${users.length} users = ${defaultBearItems.length * users.length} inventory + equipped entries`);
}

main()
  .catch(e => {
    console.error('❌ Error seeding database:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
