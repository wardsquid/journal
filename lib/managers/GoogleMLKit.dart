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

/*
{
  food: .90000,
  pizza: .97773
}
*/
// food 0.9634792384,
// tyre 0.574532432
String generateText(Map<String, double> labelMap) {
  //create string variable to house all concatenations
  String generatedText = "";
  List<String> people = List.from(
      ['Team', 'Superman', 'Person', 'Superhero', 'Baby', 'Bride', 'Crowd']);
  List<String> animals = List.from([
    'Bird',
    'Shetland sheepdog',
    'Gerbil',
    'Bear',
    'Cat',
    'Penguin',
    'Duck',
    'Turtle',
    'Crocodile',
    'Dog',
    'Butterfly',
    'Pet'
  ]);
  List<String> places = List.from([
    'Park',
    'Aquarium',
    'Circus',
    'Bridge',
    'Ferris wheel',
    'Stadium',
    'Tower',
    'Skyline'
  ]);
  List<String> food = List.from([
    'Cheeseburger',
    'Fast food',
    'Hot dog',
    'Meal',
    'Lunch',
    'Sushi',
    'Supper',
    'Vegetable',
    'Cappuccino',
    'Fruit',
    'Pizza',
    'Coffee',
    'Pie',
    'Wine',
    'Bread',
    'Food',
    'Pho',
    'Cake',
    'Alcohol',
    'Gelato'
  ]);
  List<String> events = List.from([
    'Event',
    'Graduation',
    'Competition',
    'Camping',
    'Picnic',
    'Nightclub',
    'Vacation',
    'Musical',
    'Concert',
    'Casino',
    'Cycling',
    'Dance',
    'Scuba diving',
    'Fishing',
    'Swimming',
    'Running',
    'Sports',
    'Eating',
    'Racing',
    'Sunset',
    'Fireworks',
  ]);
  List<String> bento = List.from(['bento']);
  //The original labelMap maybe full of useless tags, so we create a new variable to filter out tags with a confidence less than 80%
  labelMap.removeWhere((String key, double value) => value < .80);
  print('Printing the filtered map: $labelMap');
  labelMap.forEach((key, value) {
    if (people.contains(key)) {
      generatedText += 'Today I spent time with... $key. \n';
      people = List.from([]);
    }
    if (animals.contains(key)) {
      generatedText += 'Today I saw a $key it was... \n';
      animals = List.from([]);
    }
    if (places.contains(key)) {
      generatedText += 'Today I spent time at... $key. \n';
      places = List.from([]);
    }
    if (events.contains(key)) {
      generatedText += 'Today I went to a $key it was ...  \n';
      events = List.from([]);
    }
    if (food.contains(key)) {
      generatedText += 'Today I enjoyed eating... $key. \n';
      food = List.from([]);
    }
    // if (bento.contains(key)) {
    //   generatedText +=
    //       'Today I laid my eyes upon the most beautiful $key. \n It was the finest, most perfect $key \n NEVER in my life did I ever see such fluffy rice, \n most vividly colorful vegetables, \n ...and juciest meat 😍 \n Can you believe it was only 400 yen?!? Its crazy! \n I knew I must eat it so I fought 40 people and 70 more \n just for the chance of trying the worlds most beautiful bento.';
    //   bento = List.from([]);
    // }
  });
  print('generated text: $generatedText');
  return generatedText;
}
