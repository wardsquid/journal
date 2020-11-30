const functions = require('firebase-functions');
const parser = require('exif-parser');
const axios = require("axios");


exports.getExif = functions.https.onRequest(async (request, response) => {
  const image = request.body;
  let exifInfo = parser.create(image);
  exifInfo = exifInfo.parse();
  const lat = exifInfo.tags.GPSLatitudeRef === "N" ? String(exifInfo.tags.GPSLatitude) : "-" + exifInfo.tags.GPSLatitude;
  const lon = exifInfo.tags.GPSLongitudeRef === "E" ? String(exifInfo.tags.GPSLongitude) : "-" + exifInfo.tags.GPSLongitude;
  let {data} = await axios.get(`https://maps.googleapis.com/maps/api/geocode/json?latlng=${lat},${lon}&key=${functions.config().google_api.key}`);
  const searchString = encodeURI(data.results[0].formatted_address);
  console.log(searchString);
  const name = await axios.get(`https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=${searchString}&inputtype=textquery&language=en&fields=name,place_id&key=${functions.config().google_api.key}`);
  const bestMatch = name.data.candidates[0].name;
response.send(bestMatch);
});
