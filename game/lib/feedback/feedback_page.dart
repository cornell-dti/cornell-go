import 'package:flutter/material.dart';
import 'package:game/api/game_api.dart';
import 'package:game/api/game_client_dto.dart';
import 'package:game/details_page/dropdown_widget.dart';
import 'package:game/utils/utility_functions.dart';
import 'package:provider/provider.dart';

import 'package:game/constants/constants.dart';

class FeedbackPage extends StatefulWidget {
  final String? challengeId;
  final bool? rating;

  const FeedbackPage({Key? key, this.challengeId, this.rating})
      : super(key: key);

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  String? selectedCategory;
  String feedbackText = '';
  bool isSubmitting = false;

  final _categories = ['Bug Report', 'Suggestion', 'General'];

  final _categoryMap = {
    'Bug Report': FeedbackCategoryDto.BUG_REPORT,
    'Suggestion': FeedbackCategoryDto.SUGGESTION,
    'General': FeedbackCategoryDto.GENERAL,
  };

  var headingStyle = TextStyle(
    color: Colors.black.withOpacity(0.8),
    fontSize: 18,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w600,
    height: 0,
  );

  var buttonStyle = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontFamily: 'Poppins',
    fontWeight: FontWeight.w600,
    height: 0,
  );

  var fieldDecoration = InputDecoration(
    contentPadding: EdgeInsets.only(
      left: 20.0,
      right: 20.0,
      top: 15,
      bottom: 15,
    ),
    hintText: 'Tell us what you think...',
    hintStyle: TextStyle(
      color: Colors.black.withOpacity(0.2),
      fontWeight: FontWeight.w400,
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.black.withOpacity(0.2), width: 1.5),
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      borderSide: BorderSide(
        color: AppColors.orange,
        width: 1.5,
      ),
    ),
    fillColor: Colors.white,
    filled: true,
  );

  bool get canSubmit =>
      selectedCategory != null &&
      feedbackText.trim().isNotEmpty &&
      !isSubmitting;

  Future<void> _submitFeedback() async {
    if (!canSubmit) return;

    setState(() => isSubmitting = true);

    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final result = await apiClient.serverApi?.submitFeedback(
      SubmitFeedbackDto(
        category: _categoryMap[selectedCategory]!,
        text: feedbackText.trim(),
        rating: widget.rating,
        challengeId: widget.challengeId,
      ),
    );

    setState(() => isSubmitting = false);

    if (result == true) {
      displayToast('Feedback submitted, thank you!', Status.success);
      Navigator.pop(context);
    } else {
      displayToast('Failed to submit feedback', Status.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    var headerStyle = TextStyle(
      color: AppColors.warmWhite,
      fontSize: 20,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      backgroundColor: AppColors.warmWhite,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: AppColors.primaryRed,
        leading: IconButton(
          icon: const Icon(Icons.navigate_before),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).size.height * 0.01,
          ),
          child: Text('Feedback', style: headerStyle),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: constraints.maxWidth * 0.85,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 30),
                    Text('Category', style: headingStyle),
                    SizedBox(height: 5),
                    DropdownWidget(
                      selectedCategory,
                      _categories,
                      notifyParent: (val) {
                        setState(() => selectedCategory = val);
                      },
                    ),
                    SizedBox(height: 20),
                    Text('Your Feedback', style: headingStyle),
                    SizedBox(height: 5),
                    TextFormField(
                      decoration: fieldDecoration,
                      maxLines: 6,
                      minLines: 4,
                      onChanged: (value) {
                        setState(() => feedbackText = value);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 30, bottom: 60),
                      child: SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: canSubmit ? _submitFeedback : null,
                          style: TextButton.styleFrom(
                            backgroundColor: AppColors.accentRed,
                            disabledBackgroundColor: Color(0xFFB9B9B9),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isSubmitting
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text('Submit', style: buttonStyle),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
