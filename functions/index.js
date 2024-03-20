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
exports.sendDailyNotification = functions.pubsub.schedule("* * * * *") // Runs every minute, for testing
    .onRun(async (context) => {
        try {
            const currentDate = new Date();
            const hours = currentDate.getHours() + 3;
            const minutes = currentDate.getMinutes();
            const ampm = hours >= 12 ? 'PM' : 'AM';
            const formattedHours = hours % 12 === 0 ? 12 : hours % 12;
            const formattedMinutes = minutes < 10 ? '0' + minutes : minutes;
            const time = formattedHours + ':' + formattedMinutes + ' ' + ampm;
            console.log("time ==> " + time);
            console.log(" Starting  notification:",);
            // Get current date and time
            // const currentDate = new Date();

            console.log("current date", currentDate.getDate() + "/" + (currentDate.getMonth() + 1) + "/" + currentDate.getFullYear());

            // Query Firestore for documents where the stored date and time match the current date and time
            const querySnapshot = await database.collection("FcmTokens").where("date", "==", currentDate.getDate() + "/" + (currentDate.getMonth() + 1) + "/" + currentDate.getFullYear()).get();
            console.log("querySnapshot");
            console.log("Query Snapshot:", querySnapshot.docs.length);

            // Loop through the documents
            querySnapshot.forEach(doc => {
                const docData = doc.data();
                // const docTime = new Date(docData.timestamp).getTime(); // Convert stored time to milliseconds
                console.log("doc time", docData.timestamp);
                console.log("current time", time);


                if (docData.timestamp == time) {
                    console.log(" sending daily notification:");

                    // Send notification
                    sendNotification(docData.fcmT, "electech", "it is been 3 hours open");
                }
            });


        } catch (error) {
            console.error("Error sending daily notification:", error);
        }
    });


// Function to send notification
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
            const currentDate = new Date();
            console.log(`Notification Sent at: ${currentDate.toLocaleString()}`);
            console.log("Successful Notification Sent");
        })
        .catch(error => {
            console.error("Error Sending Notification:", error);
        });
}