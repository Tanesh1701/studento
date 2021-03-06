import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:numberpicker/numberpicker.dart';
import 'package:flutter_pdf_viewer/flutter_pdf_viewer.dart';

import '../../../UI/studento_app_bar.dart';
import '../../../UI/loading_page.dart';
import '../../../model/subject.dart';


class PaperDetailsSelectionPage extends StatefulWidget {
  final Subject subject;
  PaperDetailsSelectionPage(this.subject);

  @override
  PaperDetailsSelectionPageState createState() =>
      PaperDetailsSelectionPageState();
}

class PaperDetailsSelectionPageState extends State<PaperDetailsSelectionPage> {
  List subjects;
  static int minYear = 2008;
  int selectedYear = ((DateTime.now().year + minYear) / 2).round();
  int selectedComponent;
  final GlobalKey _menuKey = GlobalKey();
  /// This character string is used so we know from which season a paper is.
  /// This can have two values: ["s"] and ["w"] because those are the file
  /// names for our papers. Example, 4024_s14_qp_12.html
  String selectedSeason;
  List componentsList;

  @override
  void initState() {
    super.initState();
    loadComponents();
  }

  /// Loads the components of the selected subjects from json file.
  void loadComponents() {
    rootBundle
      .loadString('assets/json/components.json')
      .then((String fileData) {
        Map _decodedData = json.decode(fileData);
        setState(() {

          componentsList = _decodedData["${widget.subject.subjectCode}"];
          print(componentsList);
        });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (componentsList == null) return loadingPage();
    return Scaffold(
      appBar: StudentoAppBar (
        title: "Past Papers for ${widget.subject.name}",
      ),
      body: Container(child: _buildStepper()),
    );
  }



  void openPaper() {

    int subjectCode =  widget.subject.subjectCode;

    String paperName = "${subjectCode}_$selectedSeason" +
      selectedYear.toString().substring(2) +
      "_qp_" +
      selectedComponent.toString();

    String fileUri = "assets/pdf/$subjectCode/$selectedYear/$paperName.pdf";
    FlutterPdfViewer.loadAsset(fileUri);

    print(
      "User selected year $selectedYear, season $selectedSeason and component $selectedComponent for the subject ${widget.subject.name} with componentcode $subjectCode");
    print("So the filename would be $paperName");

  }

  Stepper _buildStepper() => Stepper(
    steps: buildSteps(),
    currentStep: currentStep,
    type: StepperType.vertical,
    // Update the variable handling the current step value and
    // jump to the tapped step.
    onStepTapped: (int step) => setState(() => currentStep = step),
    // On hitting continue button, change the state.
    onStepContinue: () => handleOnStepContinue(),
    onStepCancel: () {
      // On hitting cancel button, change the state
      setState(() {
        // Update the variable handling the current step value
        // going back one step i.e subtracting 1, until its 0.
        if (currentStep > 0) {
          currentStep = currentStep - 1;
        } else {
          currentStep = 0;
        }
      });
    },
  );

  List<Step> buildSteps() {
    List<Step> steps = [
      _buildYearSelectionStep(),
      _buildSeasonSelectionStep(),
      _buildComponentSelectionStep()
    ];
    return steps;
  }

  void handleOnStepContinue() {
    // Update the variable handling the current step value
    // going back one step i.e adding 1, until its the length of the
    // step.
    if (currentStep < buildSteps().length - 1) {
      setState(() => currentStep++);
    }
    // Check that all steps have been completed. If positive, send
    // the selected values off to WebView generator.
    else if (
      selectedComponent != null &&
      selectedYear != null &&
      selectedSeason != null)
      {
        openPaper();

      } else {
        // Set the current step to the step which was not completed.
        // The uncompleted step has to be either Step 2 or 3 as year
        // already has a default value.
        setState(() => currentStep = (selectedSeason == null) ? 1 : 2);
    }
  }

  // Init the step to 0th position
  int currentStep = 0;

  Step _buildYearSelectionStep() {
    /// Shows a dialog containing a [NumericalPicker] for the user to choose the
    /// year of the desired paper.
    void _showDialogToGetYear() =>
      showDialog<int>(
        context: context,
        builder: (_) => NumberPickerDialog.integer(
          titlePadding: EdgeInsets.all(10.0),
          minValue: minYear,
          maxValue: DateTime.now().year,
          initialIntegerValue: selectedYear,
          title: Text(
            "Select year of the paper:",
            textAlign: TextAlign.center,
          ),
        ),
      ).then( (int pickedYear) {
        if (pickedYear != null) setState(() => selectedYear = pickedYear);
    });

    Widget _content = Center(
      child: Column(
        children: <Widget>[
          Text("Choose the year of the paper you seek."),
          Padding(padding: EdgeInsets.symmetric(vertical: 10.0)),
          Divider(),
          ListTile(
            enabled: true,
            leading: Icon(Icons.date_range),
            onTap: _showDialogToGetYear,
            title: Text("Year"),
            trailing: Text(selectedYear.toString()),
          ),
          Divider(),
        ],
      ),
    );

    return Step(
      title: Text("Year"),
      content: _content,
      isActive: (currentStep == 0) ? true : false,
    );
  }

  Step _buildSeasonSelectionStep() {
    void setSelectedSeason(String value) =>
      setState(() => selectedSeason = value);

    Widget buildSeasonRadioTile({@required String title}) => RadioListTile(
      title: Text(title),
      groupValue: selectedSeason,
      value: title.substring(0,1).toLowerCase(), // the value needs to be 's',
      //  'w', etc because that's how seasons are denoted in the file name of
      //  the papers.
      onChanged: setSelectedSeason,
    );

    return Step(
      title: Text("Season"),
      isActive: (currentStep == 1) ? true : false,
      content: Column(
        children: <Widget>[
          buildSeasonRadioTile(title: "Summer"),
          buildSeasonRadioTile(title: "Winter"),
        ],
      ),
    );
  }

  Step _buildComponentSelectionStep() {
    List<PopupMenuItem> components = [];

    void handlePopUpChanged(value) =>
      setState(() => selectedComponent = value);

    components = componentsList.map(
      (component) =>
        PopupMenuItem(
          child: Text("$component"),
          value: component,
        )
    ).toList();

    return Step(
      title: Text("Component"),
      isActive: (currentStep == 2) ? true : false,
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            "Select the component of the paper you seek.",
            textAlign: TextAlign.start,
          ),
          Padding(padding: EdgeInsets.symmetric(vertical: 10.0)),
          Divider(),
          ListTile(
            leading: Icon(Icons.blur_circular),
            title: Text("Component"),
            onTap: () {
              // When ListTile is tapped, open the popUpMenu!
              dynamic popUpMenustate = _menuKey.currentState;
              popUpMenustate.showButtonMenu();
            },
            trailing: PopupMenuButton(
              key: _menuKey,
              itemBuilder: (_) => components,
              onSelected: handlePopUpChanged,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text((selectedComponent != null) ? "$selectedComponent" : ''),
                  Icon(Icons.arrow_drop_down)
                ],
              ),
            ),
          ),
          Divider(),
        ],
      ),
    );
  }
}
