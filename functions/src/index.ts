import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

admin.initializeApp();

exports.setCustomUserClaims = functions.auth.user().onCreate((user) => {
  admin.auth().setCustomUserClaims(user.uid, {
    "https://hasura.io/jwt/claims": {
      "x-hasura-default-role": "user",
      "x-hasura-allowed-roles": ["user"],
      "x-hasura-role": "user",
      "x-hasura-user-id": user.uid,
    },
  });
});
