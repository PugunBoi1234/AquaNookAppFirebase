# Moving AquaNook to Firebase — setup steps

The custom Node/Express server (`server.js`) is gone. The app now talks
directly to **Firebase Authentication**, **Cloud Firestore**, and
**Firebase Storage**. Follow these steps in order — most of this only
needs doing once.

## 1. Create the Firebase project
1. Go to https://console.firebase.google.com → **Add project** (or reuse
   an existing one).
2. You don't need Google Analytics for this — you can turn it off.

## 2. Turn on the three services you need
In the left sidebar, under **Build**:
- **Authentication** → Get started → **Sign-in method** tab → enable
  **Email/Password**.
- **Firestore Database** → Create database → start in **production
  mode** (we ship proper security rules below) → pick any region close
  to you.
- **Storage** → Get started → keep the default bucket → production mode.

## 3. Install the tooling (once per machine)
```bash
npm install -g firebase-tools
firebase login

dart pub global activate flutterfire_cli
```
(If `flutterfire` isn't found afterward, make sure Dart's global bin
folder is on your PATH — the CLI prints the exact path if it's missing.)

## 4. Connect this Flutter project to your Firebase project
From the project root:
```bash
flutterfire configure
```
- Pick the Firebase project you created in step 1.
- Select the platform(s) you build for (this project currently ships a
  `web/` folder — select **web**, plus any others you plan to add).

This **overwrites** `lib/firebase_options.dart` with your project's real
keys. The placeholder file in this delivery is intentionally fake and
won't connect to anything until you run this.

## 5. Add the Firebase packages
Already added to `pubspec.yaml` (`firebase_core`, `firebase_auth`,
`cloud_firestore`, `firebase_storage`). Just run:
```bash
flutter pub get
```

## 6. Deploy the security rules
Two options — pick whichever's easier:

**Option A — Firebase CLI** (recommended, keeps rules in version control):
```bash
firebase init firestore storage   # point it at this project, reuse the
                                   # firestore.rules / storage.rules files
                                   # already in this folder when asked
firebase deploy --only firestore:rules,storage:rules
```

**Option B — paste manually in the Console:**
- Firestore Database → **Rules** tab → paste the contents of
  `firestore.rules` → Publish.
- Storage → **Rules** tab → paste the contents of `storage.rules` →
  Publish.

## 7. Seed the product catalogue
Firestore starts empty — the 78 products / 8 sellers that used to live
in `server.js` need to be loaded in once.

1. Firebase Console → ⚙️ **Project settings** → **Service accounts** →
   **Generate new private key** → save the downloaded file as
   `scripts/serviceAccountKey.json` (same folder as `seed_firestore.js`).
   **Do not commit this file to git** — it's a real credential.
2. ```bash
   cd scripts
   npm install firebase-admin
   cd ..
   node scripts/seed_firestore.js
   ```
3. You should see `Seeding 8 sellers... Seeding 78 products... Done!`.
   Check Firestore Database in the Console — you should now see
   `products`, `sellers`, and `counters` collections.

## 8. Run the app
```bash
flutter pub get
flutter run
```
No more `node server.js` — that's retired. Register a new account,
log in, and everything (browsing, favorites, cart, selling your own
product, changing your profile photo) now runs entirely on Firebase.

---

## What changed, if you're curious
- **Auth**: `FirebaseAuth` handles register/login/logout — no more
  hand-rolled password checks.
- **Data**: products & sellers are Firestore collections, kept live with
  `.snapshots()` streams — add a product from any device and it appears
  everywhere instantly, no refresh needed.
- **Photos**: profile pictures and product photos you upload go to
  Firebase Storage (not base64-in-JSON anymore); Storage hands back a
  normal `https://` URL that the existing image widgets already know how
  to display.
- **IDs**: user ids are now Firebase's own string `uid`s. Seller ids are
  strings too (`"1"`–`"8"` for the 8 built-in shops, and a user's own
  `uid` when they list something themselves) — simpler than the old
  `1000 + userId` trick since there's no more integer user id to offset.
- **Cart & favorites** are still just in-memory app state (not saved to
  Firestore) — same as before the migration. Say the word if you'd like
  those persisted per-account too; it's a natural next step now that
  everyone has a real account.
