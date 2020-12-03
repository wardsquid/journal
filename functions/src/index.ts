import * as functions from 'firebase-functions';
import axios from "axios";
import * as admin from 'firebase-admin';
admin.initializeApp();

exports.getLocation = functions.https.onCall(async (data, context) => {
  const lat: string = (data.lat);
  const lon: string = (data.lon);

  const reverseGeoCoding = await axios.get(`https://maps.googleapis.com/maps/api/geocode/json?latlng=${lat},${lon}&key=${functions.config().google_api.key}`);
  const searchString: string = encodeURI(reverseGeoCoding.data.results[0].formatted_address);
  const name = await axios.get(`https://maps.googleapis.com/maps/api/place/findplacefromtext/json?input=${searchString}&inputtype=textquery&language=en&fields=name,place_id&key=${functions.config().google_api.key}`);
  const bestMatch: string = name.data.candidates[0].name;
return bestMatch;
});


exports.checkFriendEmail = functions.https.onCall(async (data, context) => {

  try{
  const userRecord = await admin.auth().getUserByEmail(data.email);
  console.log(`Successfully fetched user data: ${userRecord.toJSON()}`);
  return true;
  } catch (error) {
    console.log(error);
    return false;
  }
});