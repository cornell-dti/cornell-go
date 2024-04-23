import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';

class EditProfile extends StatelessWidget {
  const EditProfile({super.key});

  @override
  Widget build(BuildContext context) {
    var headingStyle = TextStyle(
      color: Colors.black.withOpacity(0.800000011920929),
      fontSize: 18,
      fontFamily: 'Poppins',
      fontWeight: FontWeight.w600,
      height: 0,
    );

    return Scaffold(
        backgroundColor: Color.fromARGB(255, 255, 248, 241),
        appBar: AppBar(
          toolbarHeight: 70,
          backgroundColor: Color.fromARGB(255, 237, 86, 86),
          // Set widget before appBar title
          leading: IconButton(
            icon: const Icon(Icons.navigate_before),
            color: Colors.white,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold),
          ),
          actions: [],
        ),
        body: Center(child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
          return SizedBox(
              width: constraints.maxWidth * 0.9,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: SvgPicture.asset("assets/images/bear_prof.svg",
                          height: 100, width: 100),
                    ),
                    Container(
                        padding: EdgeInsets.only(top: 30),
                        alignment: Alignment.centerLeft,
                        width: double.infinity,
                        height: 80,
                        child: Column(
                          children: [
                            Text('Username', style: headingStyle),
                          ],
                        ))
               4   ]));
        })));
  }
}
