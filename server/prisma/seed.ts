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
  await prisma.userQuizAnswer.deleteMany();
  await prisma.quizAnswer.deleteMany();
  await prisma.quizQuestion.deleteMany();
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
      latitude: 42.447449,
      longitude: -76.484807,
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
      description: 'Discover the best eats around Cornell and Ithaca!',
      longDescription:
        "Embark on the Ithaca Foodie Adventure and savor the diverse culinary delights that Cornell and the surrounding Ithaca area have to offer. Start your journey at one of Cornell's renowned dining halls, where you can sample a variety of dishes made with fresh, local ingredients. Then, venture into downtown Ithaca to explore charming cafes, food trucks, and restaurants that showcase the region's vibrant food scene. Whether you're craving farm-to-table fare or international cuisine, this adventure promises a feast for your taste buds!",
      timeLimitation: 'PERPETUAL',
      indexable: true,
      endTime: new Date('2030-12-31'),
      latitude: 42.447449,
      longitude: -76.484807,
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
      latitude: 42.447449,
      longitude: -76.484807,
      difficulty: 'HARD',
      category: 'NATURE',
      usedIn: {
        connect: [{ id: cornellOrg.id }],
      },
    },
  });

  // Create a standalone challenge event (single challenge)
  const standaloneEvent = await prisma.eventBase.create({
    data: {
      requiredMembers: 1,
      name: 'Libe Slope Sunset',
      description:
        'Watch the sunset from Libe Slope, one of the most beautiful views on campus.',
      longDescription:
        "Experience the magic of a Cornell sunset from Libe Slope. This iconic location offers one of the most breathtaking views on campus, especially during golden hour. Whether you're studying, relaxing, or just taking in the scenery, Libe Slope is a must-visit spot that captures the essence of Cornell's natural beauty.",
      timeLimitation: 'PERPETUAL',
      indexable: true,
      endTime: new Date('2030-12-31'),
      latitude: 42.447449,
      longitude: -76.484807,
      difficulty: 'EASY',
      category: 'NATURE',
      usedIn: {
        connect: [{ id: cornellOrg.id }],
      },
    },
  });

  const suspensionBridgeEvent = await prisma.eventBase.create({
    data: {
      requiredMembers: 1,
      name: 'Suspension Bridge Walk',
      description:
        'Cross the iconic Cornell suspension bridge and take in the gorge views.',
      longDescription:
        'The Cornell suspension bridge is one of the most thrilling spots on campus. Spanning the Fall Creek gorge, it offers breathtaking views of the rushing water and rocky walls below. Whether you are crossing to class or simply soaking in the scenery, walking across this bridge is a quintessential Cornell experience.',
      timeLimitation: 'PERPETUAL',
      indexable: true,
      endTime: new Date('2030-12-31'),
      latitude: 42.452,
      longitude: -76.4873,
      difficulty: 'EASY',
      category: 'NATURE',
      usedIn: {
        connect: [{ id: cornellOrg.id }],
      },
    },
  });

  const cornellDairyEvent = await prisma.eventBase.create({
    data: {
      requiredMembers: 1,
      name: 'Cornell Dairy Bar Tasting',
      description: 'Sample the famous Cornell ice cream made fresh on campus.',
      longDescription:
        "Head to Stocking Hall on the Ag Quad and treat yourself to some of the best ice cream you will ever taste. Made on campus from milk produced by Cornell's own dairy herd, Cornell Dairy ice cream is a beloved tradition. Try classic flavors like Big Red Bear Tracks or seasonal specials.",
      timeLimitation: 'PERPETUAL',
      indexable: true,
      endTime: new Date('2030-12-31'),
      latitude: 42.4486,
      longitude: -76.4787,
      difficulty: 'EASY',
      category: 'FOOD',
      usedIn: {
        connect: [{ id: cornellOrg.id }],
      },
    },
  });

  const bellTowerEvent = await prisma.eventBase.create({
    data: {
      requiredMembers: 1,
      name: 'McGraw Tower Chimes Concert',
      description: 'Listen to the Cornell Chimes ring out from McGraw Tower.',
      longDescription:
        "The Cornell Chimes have been a campus tradition since 1868. Played by student chimesmasters, the 21 bells of McGraw Tower ring out three times daily, filling the campus with music. Stand nearby during a concert and experience one of Cornell's oldest and most cherished traditions.",
      timeLimitation: 'PERPETUAL',
      indexable: true,
      endTime: new Date('2030-12-31'),
      latitude: 42.4474,
      longitude: -76.4849,
      difficulty: 'EASY',
      category: 'HISTORICAL',
      usedIn: {
        connect: [{ id: cornellOrg.id }],
      },
    },
  });

  const dragonDayEvent = await prisma.eventBase.create({
    data: {
      requiredMembers: 1,
      name: 'Dragon Day Monument',
      description:
        'Visit the site of the legendary Dragon Day celebration on the Arts Quad.',
      longDescription:
        "Dragon Day is one of Cornell's most unique traditions. Every spring, architecture students build an enormous dragon and parade it across campus to the Arts Quad. Visit the spot where decades of dragons have met their fiery end and learn about this beloved tradition that dates back to 1901.",
      timeLimitation: 'PERPETUAL',
      indexable: true,
      endTime: new Date('2030-12-31'),
      latitude: 42.4509,
      longitude: -76.4836,
      difficulty: 'NORMAL',
      category: 'HISTORICAL',
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
        latitude: 42.447449,
        longitude: -76.484807,
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
        latitude: 42.447449,
        longitude: -76.484807,
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
        latitude: 42.447449,
        longitude: -76.484807,
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
        latitude: 42.447449,
        longitude: -76.484807,
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
        latitude: 42.447449,
        longitude: -76.484807,
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
        latitude: 42.447449,
        longitude: -76.484807,
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
        latitude: 42.447449,
        longitude: -76.484807,
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
        latitude: 42.447449,
        longitude: -76.484807,
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
        latitude: 42.447449,
        longitude: -76.484807,
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
        latitude: 42.447449,
        longitude: -76.484807,
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
        latitude: 42.447449,
        longitude: -76.484807,
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
        latitude: 42.447449,
        longitude: -76.484807,
        awardingRadius: 70,
        closeRadius: 140,
      },
    ],
  });

  // Create standalone challenge (single challenge event)
  const standaloneChallenge = await prisma.challenge.create({
    data: {
      linkedEventId: standaloneEvent.id,
      eventIndex: 0,
      name: 'Libe Slope',
      location: 'CENTRAL_CAMPUS',
      description:
        "Visit Libe Slope and enjoy one of the most iconic views on Cornell's campus, especially beautiful at sunset.",
      points: 85,
      imageUrl:
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
      latitude: 42.447449,
      longitude: -76.484807,
      awardingRadius: 60,
      closeRadius: 120,
    },
  });

  const suspensionBridgeChallenge = await prisma.challenge.create({
    data: {
      linkedEventId: suspensionBridgeEvent.id,
      eventIndex: 0,
      name: 'Suspension Bridge',
      location: 'NORTH_CAMPUS',
      description:
        'Walk across the suspension bridge over Fall Creek gorge and take in the stunning views of the waterfall below.',
      points: 75,
      imageUrl:
        'https://images.unsplash.com/photo-1545893835-abaa50cbe628?w=800',
      latitude: 42.452,
      longitude: -76.4873,
      awardingRadius: 50,
      closeRadius: 100,
    },
  });

  const cornellDairyChallenge = await prisma.challenge.create({
    data: {
      linkedEventId: cornellDairyEvent.id,
      eventIndex: 0,
      name: 'Stocking Hall Dairy Bar',
      location: 'AG_QUAD',
      description:
        'Visit the Cornell Dairy Bar at Stocking Hall and try the famous campus-made ice cream.',
      points: 60,
      imageUrl:
        'https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=800',
      latitude: 42.4486,
      longitude: -76.4787,
      awardingRadius: 40,
      closeRadius: 80,
    },
  });

  const bellTowerChallenge = await prisma.challenge.create({
    data: {
      linkedEventId: bellTowerEvent.id,
      eventIndex: 0,
      name: 'McGraw Tower',
      location: 'CENTRAL_CAMPUS',
      description:
        'Stand near McGraw Tower during a chimes concert and enjoy the music echoing across campus.',
      points: 80,
      imageUrl:
        'https://images.unsplash.com/photo-1548625149-fc4a29cf7092?w=800',
      latitude: 42.4474,
      longitude: -76.4849,
      awardingRadius: 50,
      closeRadius: 100,
    },
  });

  const dragonDayChallenge = await prisma.challenge.create({
    data: {
      linkedEventId: dragonDayEvent.id,
      eventIndex: 0,
      name: 'Arts Quad Dragon Day Site',
      location: 'ARTS_QUAD',
      description:
        'Visit the Arts Quad where the Dragon Day parade culminates each spring.',
      points: 70,
      imageUrl:
        'https://images.unsplash.com/photo-1562774053-701939374585?w=800',
      latitude: 42.4509,
      longitude: -76.4836,
      awardingRadius: 45,
      closeRadius: 90,
    },
  });

  // Create Quiz Questions for Challenges
  console.log('📝 Creating quiz questions...');

  // Get all challenges to add quiz questions
  const allChallenges = await prisma.challenge.findMany({
    orderBy: [{ linkedEventId: 'asc' }, { eventIndex: 'asc' }],
  });

  // Quiz questions for Campus Tour Event challenges
  const campusTourChallenges = allChallenges.filter(
    c => c.linkedEventId === campusTourEvent.id,
  );

  // Quiz for McGraw Tower Clock - Multiple questions for shuffling
  if (campusTourChallenges[0]) {
    await prisma.quizQuestion.create({
      data: {
        challengeId: campusTourChallenges[0].id,
        questionText:
          'What is the item the statue is holding in his right hand?',
        pointValue: 10,
        difficulty: 1,
        category: 'HISTORICAL',
        answers: {
          create: [
            { answerText: 'Book', isCorrect: false },
            { answerText: 'Torch', isCorrect: true },
            { answerText: 'Sword', isCorrect: false },
            { answerText: 'Pen', isCorrect: false },
          ],
        },
      },
    });
    await prisma.quizQuestion.create({
      data: {
        challengeId: campusTourChallenges[0].id,
        questionText: 'How many bells are in McGraw Tower?',
        pointValue: 10,
        difficulty: 1,
        category: 'HISTORICAL',
        explanation:
          'McGraw Tower houses the Cornell Chimes, which consist of 21 bells.',
        answers: {
          create: [
            { answerText: '18', isCorrect: false },
            { answerText: '21', isCorrect: true },
            { answerText: '24', isCorrect: false },
            { answerText: '27', isCorrect: false },
          ],
        },
      },
    });
    await prisma.quizQuestion.create({
      data: {
        challengeId: campusTourChallenges[0].id,
        questionText: 'What time do the Cornell Chimes typically play?',
        pointValue: 10,
        difficulty: 1,
        category: 'HISTORICAL',
        answers: {
          create: [
            { answerText: 'Every hour on the hour', isCorrect: false },
            { answerText: 'Three times daily', isCorrect: true },
            { answerText: 'Once at noon', isCorrect: false },
            { answerText: 'Every 30 minutes', isCorrect: false },
          ],
        },
      },
    });
  }

  // Quiz for A.D. White Reading Room - Multiple questions
  if (campusTourChallenges[1]) {
    await prisma.quizQuestion.create({
      data: {
        challengeId: campusTourChallenges[1].id,
        questionText:
          "What was one of Andrew Dickson White's key contributions to Cornell University?",
        pointValue: 10,
        difficulty: 1,
        category: 'HISTORICAL',
        explanation:
          'Andrew Dickson White co-founded Cornell University with Ezra Cornell in 1865.',
        answers: {
          create: [
            {
              answerText: "Created Cornell's medical school.",
              isCorrect: false,
            },
            { answerText: 'Co-founded the university.', isCorrect: true },
            {
              answerText: 'Designed first graduate programs.',
              isCorrect: false,
            },
            { answerText: 'Funded the library.', isCorrect: false },
          ],
        },
      },
    });
    await prisma.quizQuestion.create({
      data: {
        challengeId: campusTourChallenges[1].id,
        questionText: 'Which library contains the A.D. White Reading Room?',
        pointValue: 10,
        difficulty: 1,
        category: 'HISTORICAL',
        answers: {
          create: [
            { answerText: 'Uris Library', isCorrect: true },
            { answerText: 'Olin Library', isCorrect: false },
            { answerText: 'Mann Library', isCorrect: false },
            { answerText: 'Law Library', isCorrect: false },
          ],
        },
      },
    });
    await prisma.quizQuestion.create({
      data: {
        challengeId: campusTourChallenges[1].id,
        questionText:
          'What architectural style is the A.D. White Reading Room known for?',
        pointValue: 10,
        difficulty: 1,
        category: 'HISTORICAL',
        answers: {
          create: [
            { answerText: 'Gothic Revival', isCorrect: true },
            { answerText: 'Modern', isCorrect: false },
            { answerText: 'Art Deco', isCorrect: false },
            { answerText: 'Brutalist', isCorrect: false },
          ],
        },
      },
    });
  }

  // Quiz for Engineering Quad Fountain - Multiple questions
  if (campusTourChallenges[2]) {
    await prisma.quizQuestion.create({
      data: {
        challengeId: campusTourChallenges[2].id,
        questionText:
          'Which college is primarily located in the Engineering Quad?',
        pointValue: 10,
        difficulty: 1,
        category: 'HISTORICAL',
        answers: {
          create: [
            { answerText: 'College of Arts & Sciences', isCorrect: false },
            { answerText: 'College of Engineering', isCorrect: true },
            {
              answerText: 'College of Agriculture and Life Sciences',
              isCorrect: false,
            },
            { answerText: 'School of Hotel Administration', isCorrect: false },
          ],
        },
      },
    });
    await prisma.quizQuestion.create({
      data: {
        challengeId: campusTourChallenges[2].id,
        questionText:
          'What is the name of the main building in the Engineering Quad?',
        pointValue: 10,
        difficulty: 1,
        category: 'HISTORICAL',
        answers: {
          create: [
            { answerText: 'Hollister Hall', isCorrect: false },
            { answerText: 'Duffield Hall', isCorrect: true },
            { answerText: 'Phillips Hall', isCorrect: false },
            { answerText: 'Carpenter Hall', isCorrect: false },
          ],
        },
      },
    });
    await prisma.quizQuestion.create({
      data: {
        challengeId: campusTourChallenges[2].id,
        questionText:
          'Which famous Cornell engineering program is based in the Engineering Quad?',
        pointValue: 10,
        difficulty: 1,
        category: 'HISTORICAL',
        answers: {
          create: [
            { answerText: 'Computer Science', isCorrect: true },
            { answerText: 'Architecture', isCorrect: false },
            { answerText: 'Hotel Management', isCorrect: false },
            { answerText: 'Business', isCorrect: false },
          ],
        },
      },
    });
  }

  // Quiz for Sage Chapel - NO QUIZ (removed for testing)
  // This challenge will not have quiz questions

  // Quiz for Ezra Cornell Statue - Multiple questions
  if (campusTourChallenges[4]) {
    await prisma.quizQuestion.create({
      data: {
        challengeId: campusTourChallenges[4].id,
        questionText: 'In what year was Cornell University founded?',
        pointValue: 10,
        difficulty: 1,
        category: 'HISTORICAL',
        explanation:
          'Cornell University was founded in 1865 by Ezra Cornell and Andrew Dickson White.',
        answers: {
          create: [
            { answerText: '1865', isCorrect: true },
            { answerText: '1860', isCorrect: false },
            { answerText: '1870', isCorrect: false },
            { answerText: '1855', isCorrect: false },
          ],
        },
      },
    });
    await prisma.quizQuestion.create({
      data: {
        challengeId: campusTourChallenges[4].id,
        questionText:
          "What was Ezra Cornell's primary business before founding the university?",
        pointValue: 10,
        difficulty: 1,
        category: 'HISTORICAL',
        explanation:
          'Ezra Cornell made his fortune in the telegraph industry, particularly with Western Union.',
        answers: {
          create: [
            { answerText: 'Telegraph industry', isCorrect: true },
            { answerText: 'Railroad', isCorrect: false },
            { answerText: 'Banking', isCorrect: false },
            { answerText: 'Agriculture', isCorrect: false },
          ],
        },
      },
    });
    await prisma.quizQuestion.create({
      data: {
        challengeId: campusTourChallenges[4].id,
        questionText: "Which animal is Cornell's unofficial mascot?",
        pointValue: 10,
        difficulty: 1,
        category: 'HISTORICAL',
        answers: {
          create: [
            { answerText: 'Bear', isCorrect: false },
            { answerText: 'Big Red', isCorrect: true },
            { answerText: 'Dragon', isCorrect: false },
            { answerText: 'Panther', isCorrect: false },
          ],
        },
      },
    });
  }

  // Quiz questions for Foodie Event challenges
  const foodieChallenges = allChallenges.filter(
    c => c.linkedEventId === foodieEvent.id,
  );

  // Quiz for Okenshields Dining Hall - Multiple questions
  if (foodieChallenges[0]) {
    await prisma.quizQuestion.create({
      data: {
        challengeId: foodieChallenges[0].id,
        questionText: "What is the name of Cornell's largest dining hall?",
        pointValue: 10,
        difficulty: 1,
        category: 'FOOD',
        answers: {
          create: [
            { answerText: 'Okenshields', isCorrect: true },
            { answerText: 'Risley', isCorrect: false },
            { answerText: 'North Star', isCorrect: false },
            { answerText: 'Bear Necessities', isCorrect: false },
          ],
        },
      },
    });
    await prisma.quizQuestion.create({
      data: {
        challengeId: foodieChallenges[0].id,
        questionText: 'How many food stations does Okenshields typically have?',
        pointValue: 10,
        difficulty: 1,
        category: 'FOOD',
        answers: {
          create: [
            { answerText: '5-7 stations', isCorrect: true },
            { answerText: '2-3 stations', isCorrect: false },
            { answerText: '10+ stations', isCorrect: false },
            { answerText: 'Only one station', isCorrect: false },
          ],
        },
      },
    });
    await prisma.quizQuestion.create({
      data: {
        challengeId: foodieChallenges[0].id,
        questionText: 'What type of cuisine is Okenshields known for?',
        pointValue: 10,
        difficulty: 1,
        category: 'FOOD',
        answers: {
          create: [
            { answerText: 'Diverse international options', isCorrect: true },
            { answerText: 'Only American food', isCorrect: false },
            { answerText: 'Only vegetarian', isCorrect: false },
            { answerText: 'Only fast food', isCorrect: false },
          ],
        },
      },
    });
  }

  // Quiz for Collegetown Bagels - Multiple questions
  if (foodieChallenges[1]) {
    await prisma.quizQuestion.create({
      data: {
        challengeId: foodieChallenges[1].id,
        questionText:
          'What is the popular abbreviation for Collegetown Bagels?',
        pointValue: 10,
        difficulty: 1,
        category: 'FOOD',
        answers: {
          create: [
            { answerText: 'CTB', isCorrect: true },
            { answerText: 'CT', isCorrect: false },
            { answerText: 'CB', isCorrect: false },
            { answerText: 'Bagels', isCorrect: false },
          ],
        },
      },
    });
    await prisma.quizQuestion.create({
      data: {
        challengeId: foodieChallenges[1].id,
        questionText: 'What is Collegetown Bagels famous for?',
        pointValue: 10,
        difficulty: 1,
        category: 'FOOD',
        answers: {
          create: [
            { answerText: 'Bagel sandwiches and coffee', isCorrect: true },
            { answerText: 'Pizza', isCorrect: false },
            { answerText: 'Ice cream', isCorrect: false },
            { answerText: 'Sushi', isCorrect: false },
          ],
        },
      },
    });
    await prisma.quizQuestion.create({
      data: {
        challengeId: foodieChallenges[1].id,
        questionText: 'Where is Collegetown Bagels located?',
        pointValue: 10,
        difficulty: 1,
        category: 'FOOD',
        answers: {
          create: [
            { answerText: 'Collegetown, near campus', isCorrect: true },
            { answerText: 'On the Arts Quad', isCorrect: false },
            { answerText: 'In the library', isCorrect: false },
            { answerText: 'On North Campus', isCorrect: false },
          ],
        },
      },
    });
  }

  // Quiz for Libe Café - NO QUIZ (removed for testing)
  // This challenge will not have quiz questions

  // Quiz for Cornell Dairy Bar - Multiple questions
  if (foodieChallenges[3]) {
    await prisma.quizQuestion.create({
      data: {
        challengeId: foodieChallenges[3].id,
        questionText: 'What makes Cornell ice cream special?',
        pointValue: 10,
        difficulty: 1,
        category: 'FOOD',
        explanation:
          "Cornell ice cream is made fresh on campus using milk from Cornell's own dairy cows.",
        answers: {
          create: [
            {
              answerText: "It's made on campus with Cornell dairy milk",
              isCorrect: true,
            },
            { answerText: "It's imported from Italy", isCorrect: false },
            { answerText: "It's vegan", isCorrect: false },
            { answerText: "It's only available in summer", isCorrect: false },
          ],
        },
      },
    });
    await prisma.quizQuestion.create({
      data: {
        challengeId: foodieChallenges[3].id,
        questionText: 'Where is the Cornell Dairy Bar located?',
        pointValue: 10,
        difficulty: 1,
        category: 'FOOD',
        answers: {
          create: [
            { answerText: 'Stocking Hall, near the Ag Quad', isCorrect: true },
            { answerText: 'In the Engineering Quad', isCorrect: false },
            { answerText: 'On the Arts Quad', isCorrect: false },
            { answerText: 'In Collegetown', isCorrect: false },
          ],
        },
      },
    });
    await prisma.quizQuestion.create({
      data: {
        challengeId: foodieChallenges[3].id,
        questionText: 'What is a popular Cornell ice cream flavor?',
        pointValue: 10,
        difficulty: 1,
        category: 'FOOD',
        answers: {
          create: [
            { answerText: 'Big Red Bear Tracks', isCorrect: true },
            { answerText: 'Cornell Blue', isCorrect: false },
            { answerText: 'Ithaca Sunset', isCorrect: false },
            { answerText: 'Cayuga Lake', isCorrect: false },
          ],
        },
      },
    });
  }

  // Quiz questions for Nature Event challenges
  const natureChallenges = allChallenges.filter(
    c => c.linkedEventId === natureEvent.id,
  );

  // Quiz for Fall Creek Gorge Trail - Multiple questions
  if (natureChallenges[0]) {
    await prisma.quizQuestion.create({
      data: {
        challengeId: natureChallenges[0].id,
        questionText: "What is Ithaca's famous slogan?",
        pointValue: 10,
        difficulty: 1,
        category: 'NATURE',
        answers: {
          create: [
            { answerText: 'Ithaca is Gorges', isCorrect: true },
            { answerText: 'Ithaca is Beautiful', isCorrect: false },
            { answerText: 'Ithaca is Nature', isCorrect: false },
            { answerText: 'Ithaca is Waterfalls', isCorrect: false },
          ],
        },
      },
    });
    await prisma.quizQuestion.create({
      data: {
        challengeId: natureChallenges[0].id,
        questionText: 'How many waterfalls are in the Ithaca area?',
        pointValue: 10,
        difficulty: 1,
        category: 'NATURE',
        explanation:
          'Ithaca and the surrounding Finger Lakes region are home to over 150 waterfalls.',
        answers: {
          create: [
            { answerText: 'Over 150', isCorrect: true },
            { answerText: 'About 10', isCorrect: false },
            { answerText: 'Around 50', isCorrect: false },
            { answerText: 'Just 3', isCorrect: false },
          ],
        },
      },
    });
    await prisma.quizQuestion.create({
      data: {
        challengeId: natureChallenges[0].id,
        questionText: 'What type of geological feature are the gorges?',
        pointValue: 10,
        difficulty: 1,
        category: 'NATURE',
        answers: {
          create: [
            { answerText: 'Glacial formations', isCorrect: true },
            { answerText: 'Volcanic craters', isCorrect: false },
            { answerText: 'Man-made canals', isCorrect: false },
            { answerText: 'River deltas', isCorrect: false },
          ],
        },
      },
    });
  }

  // Quiz for Beebe Lake - NO QUIZ (removed for testing)
  // This challenge will not have quiz questions

  // Quiz for Trillium Trail - Multiple questions
  if (natureChallenges[2]) {
    await prisma.quizQuestion.create({
      data: {
        challengeId: natureChallenges[2].id,
        questionText: "What is the name of Cornell's botanical gardens?",
        pointValue: 10,
        difficulty: 1,
        category: 'NATURE',
        explanation:
          'The Cornell Botanic Gardens (formerly Cornell Plantations) features beautiful trails and gardens.',
        answers: {
          create: [
            { answerText: 'Cornell Botanic Gardens', isCorrect: true },
            { answerText: 'Ithaca Gardens', isCorrect: false },
            { answerText: 'Cayuga Gardens', isCorrect: false },
            { answerText: 'Finger Lakes Gardens', isCorrect: false },
          ],
        },
      },
    });
    await prisma.quizQuestion.create({
      data: {
        challengeId: natureChallenges[2].id,
        questionText: 'What is a trillium?',
        pointValue: 10,
        difficulty: 1,
        category: 'NATURE',
        explanation:
          'Trillium is a genus of flowering plants native to North America, known for their three-petaled flowers.',
        answers: {
          create: [
            { answerText: 'A type of wildflower', isCorrect: true },
            { answerText: 'A bird species', isCorrect: false },
            { answerText: 'A type of tree', isCorrect: false },
            { answerText: 'A rock formation', isCorrect: false },
          ],
        },
      },
    });
    await prisma.quizQuestion.create({
      data: {
        challengeId: natureChallenges[2].id,
        questionText: 'What can you see along the Trillium Trail?',
        pointValue: 10,
        difficulty: 1,
        category: 'NATURE',
        answers: {
          create: [
            {
              answerText: 'Native wildflowers and woodland plants',
              isCorrect: true,
            },
            { answerText: 'Only trees', isCorrect: false },
            { answerText: 'Only water features', isCorrect: false },
            { answerText: 'Only sculptures', isCorrect: false },
          ],
        },
      },
    });
  }

  // Quiz questions for standalone challenge (Libe Slope)
  await prisma.quizQuestion.create({
    data: {
      challengeId: standaloneChallenge.id,
      questionText: 'What is Libe Slope famous for?',
      pointValue: 10,
      difficulty: 1,
      category: 'NATURE',
      answers: {
        create: [
          {
            answerText: 'Stunning sunset views and campus scenery',
            isCorrect: true,
          },
          { answerText: 'Being the highest point on campus', isCorrect: false },
          { answerText: 'Hosting sports events', isCorrect: false },
          { answerText: 'Having the best study spots', isCorrect: false },
        ],
      },
    },
  });
  await prisma.quizQuestion.create({
    data: {
      challengeId: standaloneChallenge.id,
      questionText: 'What does "Libe" refer to in Libe Slope?',
      pointValue: 10,
      difficulty: 1,
      category: 'NATURE',
      explanation:
        '"Libe" is short for "Library" - referring to Uris Library nearby.',
      answers: {
        create: [
          { answerText: 'Library (shortened)', isCorrect: true },
          { answerText: "A person's name", isCorrect: false },
          { answerText: 'A type of plant', isCorrect: false },
          { answerText: 'A building name', isCorrect: false },
        ],
      },
    },
  });
  await prisma.quizQuestion.create({
    data: {
      challengeId: standaloneChallenge.id,
      questionText: 'What is the best time to visit Libe Slope?',
      pointValue: 10,
      difficulty: 1,
      category: 'NATURE',
      answers: {
        create: [
          { answerText: 'During sunset', isCorrect: true },
          { answerText: 'Early morning', isCorrect: false },
          { answerText: 'Midday', isCorrect: false },
          { answerText: 'Late night', isCorrect: false },
        ],
      },
    },
  });

  // Quiz questions for Suspension Bridge standalone challenge
  await prisma.quizQuestion.create({
    data: {
      challengeId: suspensionBridgeChallenge.id,
      questionText: 'What gorge does the Cornell suspension bridge cross?',
      pointValue: 10,
      difficulty: 1,
      category: 'NATURE',
      answers: {
        create: [
          { answerText: 'Fall Creek', isCorrect: true },
          { answerText: 'Cascadilla Creek', isCorrect: false },
          { answerText: 'Six Mile Creek', isCorrect: false },
          { answerText: 'Taughannock Creek', isCorrect: false },
        ],
      },
    },
  });
  await prisma.quizQuestion.create({
    data: {
      challengeId: suspensionBridgeChallenge.id,
      questionText: 'What type of bridge is the Cornell suspension bridge?',
      pointValue: 10,
      difficulty: 1,
      category: 'NATURE',
      answers: {
        create: [
          { answerText: 'A pedestrian suspension bridge', isCorrect: true },
          { answerText: 'A vehicle bridge', isCorrect: false },
          { answerText: 'A covered bridge', isCorrect: false },
          { answerText: 'A drawbridge', isCorrect: false },
        ],
      },
    },
  });
  await prisma.quizQuestion.create({
    data: {
      challengeId: suspensionBridgeChallenge.id,
      questionText: 'What can you see from the suspension bridge?',
      pointValue: 10,
      difficulty: 1,
      category: 'NATURE',
      answers: {
        create: [
          { answerText: 'A waterfall and gorge walls', isCorrect: true },
          { answerText: 'Cayuga Lake', isCorrect: false },
          { answerText: 'The Cornell clock tower', isCorrect: false },
          { answerText: 'Downtown Ithaca', isCorrect: false },
        ],
      },
    },
  });

  // Quiz questions for Cornell Dairy Bar standalone challenge
  await prisma.quizQuestion.create({
    data: {
      challengeId: cornellDairyChallenge.id,
      questionText: 'Where does the milk for Cornell ice cream come from?',
      pointValue: 10,
      difficulty: 1,
      category: 'FOOD',
      answers: {
        create: [
          { answerText: "Cornell's own dairy herd on campus", isCorrect: true },
          { answerText: 'A local Ithaca dairy farm', isCorrect: false },
          { answerText: 'Imported from Vermont', isCorrect: false },
          { answerText: 'A commercial supplier', isCorrect: false },
        ],
      },
    },
  });
  await prisma.quizQuestion.create({
    data: {
      challengeId: cornellDairyChallenge.id,
      questionText: 'In which building is the Cornell Dairy Bar located?',
      pointValue: 10,
      difficulty: 1,
      category: 'FOOD',
      answers: {
        create: [
          { answerText: 'Stocking Hall', isCorrect: true },
          { answerText: 'Warren Hall', isCorrect: false },
          { answerText: 'Mann Library', isCorrect: false },
          { answerText: 'Bailey Hall', isCorrect: false },
        ],
      },
    },
  });
  await prisma.quizQuestion.create({
    data: {
      challengeId: cornellDairyChallenge.id,
      questionText: 'Which college at Cornell runs the Dairy Bar?',
      pointValue: 10,
      difficulty: 1,
      category: 'FOOD',
      explanation:
        'The College of Agriculture and Life Sciences (CALS) operates the dairy program.',
      answers: {
        create: [
          {
            answerText: 'College of Agriculture and Life Sciences',
            isCorrect: true,
          },
          { answerText: 'College of Engineering', isCorrect: false },
          { answerText: 'School of Hotel Administration', isCorrect: false },
          { answerText: 'College of Arts & Sciences', isCorrect: false },
        ],
      },
    },
  });

  // Quiz questions for McGraw Tower Chimes standalone challenge
  await prisma.quizQuestion.create({
    data: {
      challengeId: bellTowerChallenge.id,
      questionText: 'How many bells make up the Cornell Chimes?',
      pointValue: 10,
      difficulty: 1,
      category: 'HISTORICAL',
      answers: {
        create: [
          { answerText: '21', isCorrect: true },
          { answerText: '12', isCorrect: false },
          { answerText: '30', isCorrect: false },
          { answerText: '15', isCorrect: false },
        ],
      },
    },
  });
  await prisma.quizQuestion.create({
    data: {
      challengeId: bellTowerChallenge.id,
      questionText: 'When did the Cornell Chimes tradition begin?',
      pointValue: 10,
      difficulty: 1,
      category: 'HISTORICAL',
      explanation:
        'The Cornell Chimes tradition dates back to 1868, just three years after the university was founded.',
      answers: {
        create: [
          { answerText: '1868', isCorrect: true },
          { answerText: '1900', isCorrect: false },
          { answerText: '1865', isCorrect: false },
          { answerText: '1920', isCorrect: false },
        ],
      },
    },
  });
  await prisma.quizQuestion.create({
    data: {
      challengeId: bellTowerChallenge.id,
      questionText: 'Who plays the Cornell Chimes?',
      pointValue: 10,
      difficulty: 1,
      category: 'HISTORICAL',
      answers: {
        create: [
          { answerText: 'Student chimesmasters', isCorrect: true },
          { answerText: 'Professional musicians', isCorrect: false },
          { answerText: 'An automated system', isCorrect: false },
          { answerText: 'Faculty members', isCorrect: false },
        ],
      },
    },
  });

  // Quiz questions for Dragon Day standalone challenge
  await prisma.quizQuestion.create({
    data: {
      challengeId: dragonDayChallenge.id,
      questionText: 'Which students build the Dragon Day dragon?',
      pointValue: 10,
      difficulty: 1,
      category: 'HISTORICAL',
      answers: {
        create: [
          { answerText: 'Architecture students', isCorrect: true },
          { answerText: 'Engineering students', isCorrect: false },
          { answerText: 'Art students', isCorrect: false },
          { answerText: 'All freshmen', isCorrect: false },
        ],
      },
    },
  });
  await prisma.quizQuestion.create({
    data: {
      challengeId: dragonDayChallenge.id,
      questionText: 'When did the Dragon Day tradition begin?',
      pointValue: 10,
      difficulty: 1,
      category: 'HISTORICAL',
      explanation:
        "Dragon Day dates back to 1901, making it one of Cornell's oldest traditions.",
      answers: {
        create: [
          { answerText: '1901', isCorrect: true },
          { answerText: '1950', isCorrect: false },
          { answerText: '1865', isCorrect: false },
          { answerText: '1975', isCorrect: false },
        ],
      },
    },
  });
  await prisma.quizQuestion.create({
    data: {
      challengeId: dragonDayChallenge.id,
      questionText: 'What happens to the dragon at the end of the parade?',
      pointValue: 10,
      difficulty: 1,
      category: 'HISTORICAL',
      answers: {
        create: [
          { answerText: 'It is traditionally set on fire', isCorrect: true },
          { answerText: 'It is displayed in a museum', isCorrect: false },
          { answerText: 'It is thrown into a gorge', isCorrect: false },
          { answerText: 'It is donated to the city', isCorrect: false },
        ],
      },
    },
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

  const quizQuestionCount = await prisma.quizQuestion.count();
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
  console.log(`   🎯 Created 8 events (3 journeys + 5 standalone challenges)`);
  console.log(`   🎮 Created 17 challenges (12 in journeys + 5 standalone)`);
  console.log(`   📝 Created ${quizQuestionCount} quiz questions`);
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
