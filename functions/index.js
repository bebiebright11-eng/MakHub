const {initializeApp} = require("firebase-admin/app");
const {getAuth} = require("firebase-admin/auth");
const {FieldValue, getFirestore} = require("firebase-admin/firestore");
const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const {HttpsError, onCall} = require("firebase-functions/v2/https");
const {logger} = require("firebase-functions");

initializeApp();
const db = getFirestore();
const auth = getAuth();
const region = "europe-west1";

/**
 * Creates the rule-friendly personnel profile at users/{firebaseUid}.
 * This runs with Admin SDK credentials, so a client can never grant itself a
 * personnel role merely by writing its own users document.
 */
async function syncPersonnelProfile(personnelId, personnel) {
  const uid = String(personnel.firebaseUid || "").trim();
  const hostelId = String(personnel.hostelId || "").trim();
  const email = String(personnel.email || "").trim().toLowerCase();

  if (!uid || !hostelId || !email) {
    return false;
  }

  const profileRef = db.collection("users").doc(uid);
  const profile = await profileRef.get();
  const currentRole = profile.exists ? profile.get("role") : null;

  // Never overwrite an existing account of a different type. That mismatch
  // must be reviewed by an administrator rather than silently granting staff
  // access to an unrelated user.
  if (currentRole && currentRole !== "hostelPersonnel") {
    logger.error("Personnel profile role conflict", {personnelId, uid, currentRole});
    return false;
  }

  await profileRef.set({
    role: "hostelPersonnel",
    hostelId,
    personnelId,
    email,
    fullName: String(personnel.fullName || "").trim(),
    updatedAt: FieldValue.serverTimestamp(),
  }, {merge: true});
  return true;
}

// Future personnel accounts are mapped as soon as their Firebase Auth UID is
// attached to the roster record during first login/activation.
exports.syncPersonnelProfile = onDocumentWritten(
  {document: "personnel/{personnelId}", region},
  async (event) => {
    if (!event.data.after.exists) return;
    await syncPersonnelProfile(event.params.personnelId, event.data.after.data());
  },
);

/** Activates a pre-created personnel record without exposing the roster. */
exports.activatePersonnelAccount = onCall({region}, async (request) => {
  if (request.auth) {
    throw new HttpsError("failed-precondition", "Sign out before activating an account.");
  }

  const email = String(request.data?.email || "").trim().toLowerCase();
  const phoneNumber = String(request.data?.phoneNumber || "").trim();
  const password = String(request.data?.password || "");
  if (!email || !phoneNumber || password.length < 8) {
    throw new HttpsError("invalid-argument", "Enter a valid email, phone number, and password.");
  }

  const roster = await db.collection("personnel")
      .where("email", "==", email)
      .where("phoneNumber", "==", phoneNumber)
      .limit(1)
      .get();
  if (roster.empty) {
    throw new HttpsError("not-found", "No matching personnel account was found.");
  }

  const personnel = roster.docs[0];
  if (personnel.get("activated") === true || personnel.get("firebaseUid")) {
    throw new HttpsError("already-exists", "This account has already been activated.");
  }

  let user;
  try {
    user = await auth.createUser({email, password});
  } catch (error) {
    if (error.code === "auth/email-already-exists") {
      throw new HttpsError("already-exists", "An account already exists for this email.");
    }
    logger.error("Could not create personnel account", {error, personnelId: personnel.id});
    throw new HttpsError("internal", "Could not activate the account. Try again.");
  }

  try {
    await personnel.ref.update({activated: true, firebaseUid: user.uid});
    await syncPersonnelProfile(personnel.id, {
      ...personnel.data(),
      firebaseUid: user.uid,
    });
  } catch (error) {
    await auth.deleteUser(user.uid).catch((deleteError) =>
      logger.error("Could not roll back personnel account", {deleteError, uid: user.uid}),
    );
    logger.error("Could not activate personnel record", {error, personnelId: personnel.id});
    throw new HttpsError("internal", "Could not activate the account. Try again.");
  }

  return {email};
});

// One-time, admin-only migration for existing personnel documents.
exports.backfillPersonnelProfiles = onCall({region}, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in as an administrator first.");
  }

  const caller = await db.collection("users").doc(request.auth.uid).get();
  if (!caller.exists || caller.get("role") !== "admin") {
    throw new HttpsError("permission-denied", "Administrator access is required.");
  }

  const roster = await db.collection("personnel").get();
  let migrated = 0;
  let skipped = 0;
  for (const document of roster.docs) {
    if (await syncPersonnelProfile(document.id, document.data())) {
      migrated += 1;
    } else {
      skipped += 1;
    }
  }

  return {migrated, skipped};
});
