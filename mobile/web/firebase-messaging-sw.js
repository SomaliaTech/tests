importScripts(
  "https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js",
);
importScripts(
  "https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js",
);

// Your web app's Firebase configuration
firebase.initializeApp({
  apiKey: "AIzaSyDHYBpr8-C8llMttHsW-Gi_3MAmaUISlfM",
  authDomain: "haldoor-6c091.firebaseapp.com",
  projectId: "haldoor-6c091",
  storageBucket: "haldoor-6c091.firebasestorage.app",
  messagingSenderId: "759730002001",
  appId: "1:759730002001:web:31cf9f4387a21415a80070",
  measurementId: "G-2MHQJ5CERX",
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log("📩 Received background message: ", payload);

  const notificationTitle = payload.notification?.title || "New Message";
  const notificationOptions = {
    body: payload.notification?.body || "",
    icon: "/icons/Icon-192.png",
    badge: "/icons/Icon-192.png",
    vibrate: [200, 100, 200],
    data: payload.data,
  };

  return self.registration.showNotification(
    notificationTitle,
    notificationOptions,
  );
});

// Handle notification clicks
self.addEventListener("notificationclick", (event) => {
  event.notification.close();

  // Open the app when notification is clicked
  event.waitUntil(
    clients.matchAll({ type: "window" }).then((clientList) => {
      // If a window is already open, focus it
      for (const client of clientList) {
        if (client.url && "focus" in client) {
          return client.focus();
        }
      }
      // Otherwise, open a new window
      if (clients.openWindow) {
        return clients.openWindow("/");
      }
    }),
  );
});
