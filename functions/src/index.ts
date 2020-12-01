import * as functions from 'firebase-functions';
import axios from "axios";

exports.getLocation = functions.https.onCall(async (data, context) => {
  const lat: string = (data.lat);
  const lon: string = (data.lon);

  const reverseGeoCoding = await axios.get(`https://maps.googleapis.com/maps/api/geocode/json?latlng=${lat},${lon}&key=${functions.config().google_api.key}`);
  const searchString: string = encodeURI(reverseGeoCoding.data.results[0].formatted_address);
  const name = await axios.get(`https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=${searchString}&inputtype=textquery&language=en&fields=name,place_id&key=${functions.config().google_api.key}`);
  const bestMatch: string = name.data.candidates[0].name;
return bestMatch;
});