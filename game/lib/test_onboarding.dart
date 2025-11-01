import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

/**
 * MINIMAL TEST: Can bottom_navbar start showcases on child pages?
 * 
 * Test scenario:
 * 1. TestBottomNav registers callbacks and starts showcases
 * 2. TestPage1 has Showcase widgets (doesn't call startShowCase)
 * 3. TestPage2 has Showcase widgets (doesn't call startShowCase)
 * 4. Verify showcases appear on TestPage1 first
 * 5. After completing, navigate to TestPage2 and start its showcases
 */

// Minimal manager - just stores keys
class TestOnboardingManager {
  static int currentPage = 0;
  static bool isComplete = false;

  // Page 1 keys
  static GlobalKey page1Key1 = GlobalKey();
  static GlobalKey page1Key2 = GlobalKey();

  // Page 2 keys
  static GlobalKey page2Key1 = GlobalKey();
  static GlobalKey page2Key2 = GlobalKey();

  static List<GlobalKey> getKeysForPage(int page) {
    if (page == 0) return [page1Key1, page1Key2];
    if (page == 1) return [page2Key1, page2Key2];
    return [];
  }
}

// Main test entry point
class TestOnboardingApp extends StatelessWidget {
  const TestOnboardingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Onboarding Test',
      home: TestBottomNav(),
    );
  }
}

// The "bottom_navbar" - controls everything
class TestBottomNav extends StatefulWidget {
  const TestBottomNav({Key? key}) : super(key: key);

  @override
  State<TestBottomNav> createState() => _TestBottomNavState();
}

class _TestBottomNavState extends State<TestBottomNav> {
  int _currentPageIndex = 0;

  final List<Widget> _pages = [
    TestPage1(),
    TestPage2(),
  ];

  @override
  void initState() {
    super.initState();

    print('TestBottomNav: initState called');

    // Register callbacks ONCE
    ShowcaseView.register(
      onStart: (index, key) {
        print('✅ Showcase started: index=$index, key=$key');
      },
      onComplete: (index, key) {
        print('✅ Showcase completed: index=$index, key=$key');
        _handleShowcaseComplete(key);
      },
      onFinish: () {
        print('✅ All showcases finished!');
        TestOnboardingManager.isComplete = true;
      },
    );

    // Start first page's showcases
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('TestBottomNav: Starting showcases for page 0');
      ShowcaseView.get().startShowCase(TestOnboardingManager.getKeysForPage(0));
    });
  }

  void _handleShowcaseComplete(GlobalKey key) {
    // Check if this is the last key on page 1
    if (key == TestOnboardingManager.page1Key2) {
      print('TestBottomNav: Page 1 done! Navigating to page 2...');

      // Update state
      TestOnboardingManager.currentPage = 1;
      setState(() {
        _currentPageIndex = 1;
      });

      // Start page 2's showcases after navigation
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('TestBottomNav: Starting showcases for page 2');
        ShowcaseView.get()
            .startShowCase(TestOnboardingManager.getKeysForPage(1));
      });
    }
  }

  @override
  void dispose() {
    ShowcaseView.get().unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Onboarding - Page ${_currentPageIndex + 1}'),
        backgroundColor: Colors.blue,
      ),
      body: _pages[_currentPageIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPageIndex,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Page 1'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Page 2'),
        ],
        onTap: (index) {
          // Manual navigation (not during onboarding flow)
          setState(() {
            _currentPageIndex = index;
          });
        },
      ),
    );
  }
}

// Page 1 - just UI, doesn't call startShowCase()
class TestPage1 extends StatelessWidget {
  const TestPage1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('TestPage1: build called');

    return Container(
      color: Colors.amber[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Page 1',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),

            // First showcase widget
            Showcase(
              key: TestOnboardingManager.page1Key1,
              title: 'Page 1 - Step 1',
              description:
                  'This is the first showcase on page 1. Tap "Next" to continue.',
              tooltipBackgroundColor: Colors.blue,
              textColor: Colors.white,
              child: Container(
                padding: EdgeInsets.all(20),
                color: Colors.blue,
                child: Text(
                  'Showcase 1',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),

            SizedBox(height: 40),

            // Second showcase widget
            Showcase(
              key: TestOnboardingManager.page1Key2,
              title: 'Page 1 - Step 2 (LAST)',
              description:
                  'This is the second showcase on page 1. After tapping "Next", we should AUTO-NAVIGATE to page 2!',
              tooltipBackgroundColor: Colors.green,
              textColor: Colors.white,
              child: Container(
                padding: EdgeInsets.all(20),
                color: Colors.green,
                child: Text(
                  'Showcase 2',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Page 2 - just UI, doesn't call startShowCase()
class TestPage2 extends StatelessWidget {
  const TestPage2({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('TestPage2: build called');

    return Container(
      color: Colors.green[50],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Page 2',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),

            // First showcase widget
            Showcase(
              key: TestOnboardingManager.page2Key1,
              title: 'Page 2 - Step 1',
              description: 'This is the first showcase on page 2',
              child: Container(
                padding: EdgeInsets.all(20),
                color: Colors.orange,
                child: Text(
                  'Showcase 3',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),

            SizedBox(height: 40),

            // Second showcase widget
            Showcase(
              key: TestOnboardingManager.page2Key2,
              title: 'Page 2 - Step 2',
              description:
                  'This is the last showcase! After this, onboarding is complete.',
              child: Container(
                padding: EdgeInsets.all(20),
                color: Colors.purple,
                child: Text(
                  'Showcase 4',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
