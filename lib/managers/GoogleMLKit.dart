import 'dart:io';
import 'dart:async';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

Future<Map<String, double>> readLabel(File pickedImage) async {
  Map<String, double> labelMap = {};
  print('begin analysis');
  FirebaseVisionImage myImage = FirebaseVisionImage.fromFile(pickedImage);
  ImageLabeler labeler = FirebaseVision.instance.imageLabeler();
  List labels = await labeler.processImage(myImage);
  // adds the label to the labelMap
  if (labels.length > 1) {
    for (ImageLabel label in labels) {
      final String text = label.text;
      final double confidence = label.confidence;
      labelMap[text] = confidence;
    }
    return labelMap;
  } else {
    return labelMap;
  }
}

// food 0.9634792384,
// tyre 0.574532432
// String functiongeneratingtext(Map<String, double> labelMap){
//   //code
// }
