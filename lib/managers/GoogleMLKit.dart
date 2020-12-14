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

List<String> generateText(Map<String, double> labelMap) {
  //the array of strings we will pass to the createAlert function
  List<String> generatedTextList = [];

  List<String> love = List.from(['Kiss', 'Interaction', 'Love']);
  List<String> wedding = List.from(['Bride', 'Veil', 'Marriage', 'Groom']);
  List<String> animals = List.from(['Bird', 'Cat', 'Dog', 'Butterfly', 'Pet']);
  List<String> food = List.from(['Fast food', 'Cuisine', 'Food']);
  List<String> places = List.from([
    'Park',
    'Field',
    'Sky',
    'Mountain',
    'Prarie',
    'Desert',
    'Vacation',
    'Leisure',
    'Beach',
    'Sand',
    'Circus',
    'Ferris wheel'
  ]);

  List<String> animalPrompts = List.from([
    'Tell me about it`s personality',
    'How did spending time with... make you feel?',
    'How did you spend your time with...?',
    'When do you need ... the most?',
    'What memory did you make with...',
  ]);
  List<String> lovePrompts = List.from([
    'How did you two spend time?',
    'Was today a special anniversary?',
    'How did you meet',
    'What memory would you like to share?',
    'How did they meet',
    'What is your couple goal'
  ]);
  List<String> parkPrompts = List.from([
    'How was the park today',
    'When do you come here?',
    'Were there any events',
  ]);
  List<String> weddingPrompts = List.from([
    'Was this your Wedding?',
    'How did you feel today?',
    'Who `s wedding is this?',
  ]);
  List<String> placePrompts = List.from([
    'How does this place make you feel?',
    'Do you visit here often?',
    'Tell me about your best memory here',
    'How was the park today',
    'When do you come here?',
    'Were there any events'
  ]);
  List<String> foodPrompts = List.from([
    'Tell me about this dish!',
    'How did it come out?',
    'What was the occasion?',
    'Did you share with anyone?',
  ]);
  //The original labelMap maybe full of useless tags, so we create a new variable to filter out tags with a confidence less than 80%
  print('Printing the ORIGINAL map $labelMap');
  labelMap.removeWhere((String key, double value) => value < .60);
  print('Printing the FILTERED map: $labelMap');
  labelMap.forEach((key, value) {
    if (animals.contains(key)) {
      animalPrompts.forEach((prompt) {
        generatedTextList.add(prompt);
      });
    }
    if (places.contains(key)) {
      placePrompts.forEach((prompt) {
        generatedTextList.add(prompt);
      });
    }
    if (wedding.contains(key)) {
      weddingPrompts.forEach((prompt) {
        generatedTextList.add(prompt);
      });
    }
    if (love.contains(key)) {
      lovePrompts.forEach((prompt) {
        generatedTextList.add(prompt);
      });
    }
    if (food.contains(key)) {
      foodPrompts.forEach((prompt) {
        generatedTextList.add(prompt);
      });
    }
  });
  generatedTextList = generatedTextList.toSet().toList();
  print('generated text: $generatedTextList');
  return generatedTextList;
}

// if (people.contains(key)) {
//   generatedText +=
//       'Today I spent time with... . \n They were doing... \n Its been.... since I saw them \n I felt... \n';
//   people = List.from([]);
// }
// if (animals.contains(key)) {
//   generatedText +=
//       'Today I took a picture of this $key \n It was so...\n After I felt... \n';
//   animals = List.from([]);
// }
// if (places.contains(key)) {
//   generatedText +=
//       'Today I spent time at... $key. \n I went there by...\n It was nice to get out of the house and...\n';
//   places = List.from([]);
// }
// if (events.contains(key)) {
//   generatedText +=
//       'Today I went to a $key\n It was ...\n I took this picture...\n I hope';
//   events = List.from([]);
// }
// if (food.contains(key)) {
//   generatedText += 'Today I enjoyed eating... $key. \n';
//   food = List.from([]);
// }
// if (bento.contains(key)) {
//   generatedText +=
//       'Today I laid my eyes upon the most beautiful $key. \n It was the finest, most perfect $key \n NEVER in my life did I ever see such fluffy rice, \n most vividly colorful vegetables, \n ...and juciest meat 😍 \n Can you believe it was only 400 yen?!? Its crazy! \n I knew I must eat it so I fought 40 people and 70 more \n just for the chance of trying the worlds most beautiful bento.';
//   bento = List.from([]);
// }
