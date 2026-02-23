import 'package:flutter/material.dart';
import 'package:game/journeys/journeys_page.dart';
import 'package:game/challenges/challenges_page.dart';
import 'package:game/model/onboarding_model.dart';
import 'package:game/widgets/bear_mascot_message.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

/**
 * `HomeNavBar` Widget - Tab navigation system for Challenges and Journeys.
 * 
 * @remarks
 * This widget implements a tab controller to switch between Challenges and
 * Journeys views. It receives filter states from SearchFilterBar and passes
 * them to the appropriate tab content.
 * 
 * @param props - Contains:
 *   - `myDifficulty`: Selected difficulty filter
 *   - `myLocations`: List of selected location filters
 *   - `myCategories`: List of selected category filters
 *   - `mySearchText`: Current search query text
 */
class HomeNavBar extends StatefulWidget {
  String? myDifficulty;
  List<String>? myLocations;
  List<String>? myCategories;
  String? mySearchText;
  HomeNavBar({
    Key? key,
    String? difficulty,
    List<String>? locations,
    List<String>? categories,
    String? searchText,
  }) : super(key: key) {
    myDifficulty = difficulty;
    myLocations = locations;
    myCategories = categories;
    mySearchText = searchText;
  }

  @override
  State<HomeNavBar> createState() => _HomeNavbarState();
}

class _HomeNavbarState extends State<HomeNavBar> with TickerProviderStateMixin {
  late TabController _tabController;
  // Onboarding: overlay entry for bear mascot message prompting user to switch to Journeys tab
  OverlayEntry? _bearOverlayEntry;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Onboarding: Register showcase scope for highlighting Journeys tab (step 2)
    // Hot restart fix: unregister old instance if exists
    try {
      ShowcaseView.getNamed("home_navbar").unregister();
    } catch (e) {
      // Not registered yet, that's fine
    }

    // Register this page's showcase
    ShowcaseView.register(
      scope: "home_navbar",
      onFinish: () {
        Provider.of<OnboardingModel>(context, listen: false).completeStep2();
      },
    );
  }

  @override
  void dispose() {
    _removeBearOverlay();
    _tabController.dispose();
    super.dispose();
  }

  void _showBearOverlay() {
    _removeBearOverlay(); // Remove existing if any

    _bearOverlayEntry = OverlayEntry(
      builder: (context) => BearMascotMessage(
        message: 'Click on the Journeys tab to go to the Journeys page.',
        showBear: true,
        bearAsset: 'standing',
        bearLeftPercent: -0.02,
        bearBottomPercent: 0.12,
        messageLeftPercent: 0.6,
        messageBottomPercent: 0.35,
        onTap: () {
          print("Tapped anywhere on step 2");
          _removeBearOverlay();
          ShowcaseView.getNamed("home_navbar").dismiss();
          Provider.of<OnboardingModel>(context, listen: false).completeStep2();
          // Onboarding: Switch to Journeys tab (index 1) to trigger step 3 explanation overlay
          _tabController.animateTo(1);
        },
      ),
    );

    Overlay.of(context).insert(_bearOverlayEntry!);
  }

  void _removeBearOverlay() {
    _bearOverlayEntry?.remove();
    _bearOverlayEntry = null;
  }

  /// Build Journeys tab with optional onboarding showcase
  /// Onboarding step 2: Highlights Journeys tab to guide user to switch from Challenges view
  Widget _buildJourneysTab(
    OnboardingModel onboarding,
    double screenWidth,
    double screenHeight,
  ) {
    final journeysTab = Tab(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.sizeOf(context).height * 0.02,
        ),
        child: Text(
          'Journeys',
          style: TextStyle(
            fontSize: MediaQuery.sizeOf(context).height * 0.02,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    // Show showcase if step1 complete and step2 not complete
    if (onboarding.step1ChallengesComplete &&
        !onboarding.step2JourneysComplete) {
      return Showcase(
        key: onboarding.step2JourneysTabKey,
        title: '',
        description: '',
        tooltipBackgroundColor: Colors.transparent,
        disableMovingAnimation: true,
        targetShapeBorder: CircleBorder(),
        targetPadding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.076, // ~30px on 393px screen
          vertical: screenHeight * 0.059, // ~50px on 852px screen
        ),
        child: journeysTab,
      );
    }

    return journeysTab;
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = Provider.of<OnboardingModel>(context, listen: true);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Onboarding: Step 2 - Show showcase for Journeys tab after first challenge card is viewed
    if (onboarding.step1ChallengesComplete &&
        !onboarding.step2JourneysComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ShowcaseView.getNamed(
            "home_navbar",
          ).startShowCase([onboarding.step2JourneysTabKey]);
          // Show bear overlay on top of showcase
          _showBearOverlay();
        }
      });
    }

    return Scaffold(
      backgroundColor: Color(0xFFED5656),
      resizeToAvoidBottomInset: false,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(
          MediaQuery.sizeOf(context).height * 0.08,
        ),
        child: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0.0,
          backgroundColor: Color(0xFFED5656),
          titleTextStyle: TextStyle(
            fontSize: MediaQuery.sizeOf(context).height * 0.03,
            fontWeight: FontWeight.w500,
          ),
          bottom: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFFFAA5B), width: 2.0),
              ),
            ),
            overlayColor: MaterialStateProperty.resolveWith<Color?>(
              //transparent when clicked -- double check with designers
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.pressed)) {
                  return Colors.transparent;
                }
                return null;
              },
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black.withOpacity(0.5),
            tabs: <Widget>[
              Tab(
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.sizeOf(context).height * 0.02,
                  ),
                  child: Text(
                    'Challenges',
                    style: TextStyle(
                      fontSize: MediaQuery.sizeOf(context).height * 0.02,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              _buildJourneysTab(onboarding, screenWidth, screenHeight),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          Center(
            child: ChallengesPage(
              difficulty: widget.myDifficulty,
              categories: widget.myCategories,
              locations: widget.myLocations,
              searchText: widget.mySearchText,
            ),
          ),
          Center(
            child: JourneysPage(
              difficulty: widget.myDifficulty,
              categories: widget.myCategories,
              locations: widget.myLocations,
              searchText: widget.mySearchText,
            ),
          ),
        ],
      ),
    );
  }
}
