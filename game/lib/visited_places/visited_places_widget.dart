import '../flutter_flow/flutter_flow_theme.dart';
import '../flutter_flow/flutter_flow_util.dart';
import '../flutter_flow/flutter_flow_widgets.dart';
import '../home_page/home_page_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VisitedPlacesWidget extends StatefulWidget {
  VisitedPlacesWidget({Key key}) : super(key: key);

  @override
  _VisitedPlacesWidgetState createState() => _VisitedPlacesWidgetState();
}

class _VisitedPlacesWidgetState extends State<VisitedPlacesWidget> {
  TextEditingController textController;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      body: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Container(
                    width: 100,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Color(0xFFEEEEEE),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Align(
                          alignment: AlignmentDirectional(0, 0),
                          child: FFButtonWidget(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => HomePageWidget(),
                                ),
                              );
                            },
                            text: '< Play',
                            options: FFButtonOptions(
                              width: 69,
                              height: 50,
                              color: Colors.transparent,
                              textStyle: FlutterFlowTheme.title3.override(
                                fontFamily: 'Poppins',
                                color: Color(0xFFFF0000),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                              borderSide: BorderSide(
                                color: Colors.transparent,
                                width: 1,
                              ),
                              borderRadius: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional(-0.35, 0),
                            child: Text(
                              'Visited Places',
                              style: FlutterFlowTheme.title3.override(
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(10, 0, 30, 0),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Color(0xFF9E9E9E),
                        borderRadius: BorderRadius.circular(10),
                        shape: BoxShape.rectangle,
                      ),
                      child: TextFormField(
                        controller: textController,
                        obscureText: false,
                        decoration: InputDecoration(
                          hintText: '         Search',
                          hintStyle: FlutterFlowTheme.bodyText1.override(
                            fontFamily: 'Poppins',
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0x00000000),
                              width: 1,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4.0),
                              topRight: Radius.circular(4.0),
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0x00000000),
                              width: 1,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4.0),
                              topRight: Radius.circular(4.0),
                            ),
                          ),
                        ),
                        style: FlutterFlowTheme.bodyText1.override(
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(50, 20, 20, 0),
                    child: Card(
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                )
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(50, 0, 20, 0),
                    child: Card(
                      clipBehavior: Clip.antiAliasWithSaveLayer,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
