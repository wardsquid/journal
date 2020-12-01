import 'dart:io';
import 'dart:core';
import 'dart:typed_data';
import 'package:exif/exif.dart';

Future<List<double>> getExifFromFile(File selectedPhoto) async {
    print("called");
    if (selectedPhoto == null) {
      print('none found');
      return null;
    }
    Uint8List bytes = await selectedPhoto.readAsBytes();
    Map<String, IfdTag> exifTags = await readExifFromBytes(bytes);
    // print(exifTags.keys.toString());
    // exifTags.forEach((k, v) {
    //   print("$k: $v \n");
    // });
    if (exifTags.containsKey('GPS GPSLongitude') &&
        exifTags.containsKey('GPS GPSLongitudeRef') &&
        exifTags.containsKey('GPS GPSLatitude') &&
        exifTags.containsKey('GPS GPSLatitudeRef')) {
      final latitudeValue = exifTags['GPS GPSLatitude']
          .values
          .map<double>((item) =>
              (item.numerator.toDouble() / item.denominator.toDouble()))
          .toList();
      final latitudeSignal = exifTags['GPS GPSLatitudeRef'].printable;

      final longitudeValue = exifTags['GPS GPSLongitude']
          .values
          .map<double>((item) =>
              (item.numerator.toDouble() / item.denominator.toDouble()))
          .toList();
      final longitudeSignal = exifTags['GPS GPSLongitudeRef'].printable;

      double latitude = latitudeValue[0] +
          (latitudeValue[1] / 60) +
          (latitudeValue[2] / 3600);

      double longitude = longitudeValue[0] +
          (longitudeValue[1] / 60) +
          (longitudeValue[2] / 3600);

      if (latitudeSignal == 'S') latitude = -latitude;
      if (longitudeSignal == 'W') longitude = -longitude;

      List<double> coordinatesSet = List.from([latitude, longitude]);
      return coordinatesSet;
    } else {
      List<double> coordinatesSet = List.from([]);
      return coordinatesSet;
    }
  }

  