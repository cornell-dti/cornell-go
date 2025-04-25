import 'package:flutter/material.dart';

class QuizPage extends StatefulWidget {
  const QuizPage({Key? key}) : super(key: key);

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int? selectedAnswerIndex;
  List<String> answers = ['Book', 'Torch', 'Sword', 'Pen'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF9F5F1),
      appBar: AppBar(
        backgroundColor: Color(0xFFE95755),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Quiz', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // 16 margin all sides
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question Category + Points
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Physical',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.monetization_on,
                        color: Color(0xFFC17E19), size: 18),
                    SizedBox(width: 4),
                    Text('10 PTS',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFC17E19))),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),

            // Question Container
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What is the item the statue is holding in his right hand?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      setState(() {
                        answers.shuffle();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFFE95755)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Shuffle (${answers.length})',
                        style: TextStyle(color: Color(0xFFE95755))),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Answer Choices
            ...List.generate(answers.length, (index) {
              bool isSelected = selectedAnswerIndex == index;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedAnswerIndex = index;
                  });
                },
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.only(bottom: 16),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color(0xFFE95755).withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isSelected ? Color(0xFFE95755) : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      answers[index],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Color(0xFFE95755) : Colors.black,
                      ),
                    ),
                  ),
                ),
              );
            }),

            Spacer(),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedAnswerIndex == null
                    ? null
                    : () {
                        // You can handle submit logic here
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedAnswerIndex == null
                      ? Color(0xFFE95755).withOpacity(0.6)
                      : Color(0xFFE95755),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text('Submit',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
