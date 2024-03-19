/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

//const {onRequest} = require("firebase-functions/v2/https");
//const logger = require("firebase-functions/logger");
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();
const database = admin.firestore();

// Function to send notification on content creation
exports.sendDailyNotification = functions.pubsub.schedule('0 18 * * *') // Runs everyday at 11:00 AM
    .timeZone('Asia/Karachi') // Set your timezone here
    .onRun(async (context) => {
        try {
            // Get current date
            const currentDate = new Date();
            const month = currentDate.getMonth() + 1; // Months are 0-indexed, so adding 1
            const day = currentDate.getDate();
            const year = currentDate.getFullYear();

            const currentDateString = `${month}/${day}/${year}`;
            // Get all documents from the "RootreMessage" collection
            const rootreMessageSnapshot = await database.collection("RootreMessage").get();
            const messages = rootreMessageSnapshot.docs.map(doc => doc.data());

            // Filter messages for today's date
            const todaysMessages = messages.filter(message => message.date === currentDateString);
            console.log("todaysMessages", todaysMessages);

            if (todaysMessages.length === 0) {
                console.log("No messages found for today's date:", currentDateString);
                return null;
            }

            // Fetch tokens from FcmTokens collection
            const tokensSnapshot = await database.collection("FcmTokens").get();

            if (!tokensSnapshot.empty) {
                const tokens = tokensSnapshot.docs.map(doc => doc.data().fcmT);

                // Send notification for each message of today
                todaysMessages.forEach(message => {
                    tokens.forEach(token => {
                        sendNotification(token, message.title, message.subtitle);
                    });
                });

                console.log("Notifications sent for today's messages");
            } else {
                console.log("No tokens found to send notifications");
            }
        } catch (error) {
            console.error("Error sending daily notification:", error);
        }
    });


// Function to send notification
function sendNotification(androidNotificationToken, title, body) {
    const payload = {
        notification: { title, body },
        token: androidNotificationToken,
    };

    admin
        .messaging()
        .send(payload)
        .then(response => {
            console.log("Successful Notification Sent");
        })
        .catch(error => {
            console.error("Error Sending Notification:", error);
        });
}
// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
