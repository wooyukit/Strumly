import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// ---------------------------------------------------------------------------
// CORS helper
// ---------------------------------------------------------------------------

function setCorsHeaders(res: functions.Response): void {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
}

function handleCorsPreFlight(
  req: functions.Request,
  res: functions.Response
): boolean {
  setCorsHeaders(res);
  if (req.method === "OPTIONS") {
    res.status(204).send("");
    return true;
  }
  return false;
}

// ---------------------------------------------------------------------------
// 1. searchSongs — GET ?q=<query>
//    Tokenise the query and search the `songs` collection using
//    `searchTerms` array-contains-any (Firestore limit: 30 disjunctions).
// ---------------------------------------------------------------------------

export const searchSongs = functions.https.onRequest(async (req, res) => {
  if (handleCorsPreFlight(req, res)) return;

  try {
    if (req.method !== "GET") {
      res.status(405).json({error: "Method not allowed"});
      return;
    }

    const query = (req.query.q as string || "").trim().toLowerCase();
    if (!query) {
      res.status(400).json({error: "Missing query parameter 'q'"});
      return;
    }

    // Tokenise: split on whitespace, take up to 10 terms (Firestore
    // array-contains-any supports a maximum of 30 disjunction values).
    const tokens = query.split(/\s+/).slice(0, 10);

    const snapshot = await db
      .collection("songs")
      .where("searchTerms", "array-contains-any", tokens)
      .limit(50)
      .get();

    const songs = snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()}));
    res.status(200).json(songs);
  } catch (error) {
    functions.logger.error("searchSongs error", error);
    res.status(500).json({error: "Internal server error"});
  }
});

// ---------------------------------------------------------------------------
// 2. getPopularSongs — GET ?limit=<n>  (default 20, max 50)
// ---------------------------------------------------------------------------

export const getPopularSongs = functions.https.onRequest(async (req, res) => {
  if (handleCorsPreFlight(req, res)) return;

  try {
    if (req.method !== "GET") {
      res.status(405).json({error: "Method not allowed"});
      return;
    }

    let limit = parseInt(req.query.limit as string, 10) || 20;
    if (limit < 1) limit = 1;
    if (limit > 50) limit = 50;

    const snapshot = await db
      .collection("songs")
      .orderBy("playCount", "desc")
      .limit(limit)
      .get();

    const songs = snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()}));
    res.status(200).json(songs);
  } catch (error) {
    functions.logger.error("getPopularSongs error", error);
    res.status(500).json({error: "Internal server error"});
  }
});

// ---------------------------------------------------------------------------
// 3. getSong — GET /<songId>
// ---------------------------------------------------------------------------

export const getSong = functions.https.onRequest(async (req, res) => {
  if (handleCorsPreFlight(req, res)) return;

  try {
    if (req.method !== "GET") {
      res.status(405).json({error: "Method not allowed"});
      return;
    }

    // Extract song ID from the URL path (e.g. /getSong/<songId>)
    const songId = req.path.split("/").filter(Boolean).pop();
    if (!songId) {
      res.status(400).json({error: "Missing song ID"});
      return;
    }

    const doc = await db.collection("songs").doc(songId).get();
    if (!doc.exists) {
      res.status(404).json({error: "Song not found"});
      return;
    }

    res.status(200).json({id: doc.id, ...doc.data()});
  } catch (error) {
    functions.logger.error("getSong error", error);
    res.status(500).json({error: "Internal server error"});
  }
});

// ---------------------------------------------------------------------------
// 4. getPopularArtists — GET ?limit=<n>  (default 20, max 50)
// ---------------------------------------------------------------------------

export const getPopularArtists = functions.https.onRequest(
  async (req, res) => {
    if (handleCorsPreFlight(req, res)) return;

    try {
      if (req.method !== "GET") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      let limit = parseInt(req.query.limit as string, 10) || 20;
      if (limit < 1) limit = 1;
      if (limit > 50) limit = 50;

      const snapshot = await db
        .collection("artists")
        .orderBy("songCount", "desc")
        .limit(limit)
        .get();

      const artists = snapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));
      res.status(200).json(artists);
    } catch (error) {
      functions.logger.error("getPopularArtists error", error);
      res.status(500).json({error: "Internal server error"});
    }
  }
);

// ---------------------------------------------------------------------------
// 5. getArtistSongs — GET /<artistId>
// ---------------------------------------------------------------------------

export const getArtistSongs = functions.https.onRequest(async (req, res) => {
  if (handleCorsPreFlight(req, res)) return;

  try {
    if (req.method !== "GET") {
      res.status(405).json({error: "Method not allowed"});
      return;
    }

    const artistId = req.path.split("/").filter(Boolean).pop();
    if (!artistId) {
      res.status(400).json({error: "Missing artist ID"});
      return;
    }

    const snapshot = await db
      .collection("songs")
      .where("artistId", "==", artistId)
      .get();

    const songs = snapshot.docs.map((doc) => ({id: doc.id, ...doc.data()}));
    res.status(200).json(songs);
  } catch (error) {
    functions.logger.error("getArtistSongs error", error);
    res.status(500).json({error: "Internal server error"});
  }
});

// ---------------------------------------------------------------------------
// 6. recordPlay — POST /<songId>
//    Increments the song's `playCount` field by 1.
// ---------------------------------------------------------------------------

export const recordPlay = functions.https.onRequest(async (req, res) => {
  if (handleCorsPreFlight(req, res)) return;

  try {
    if (req.method !== "POST") {
      res.status(405).json({error: "Method not allowed"});
      return;
    }

    const songId = req.path.split("/").filter(Boolean).pop();
    if (!songId) {
      res.status(400).json({error: "Missing song ID"});
      return;
    }

    const songRef = db.collection("songs").doc(songId);
    const doc = await songRef.get();
    if (!doc.exists) {
      res.status(404).json({error: "Song not found"});
      return;
    }

    await songRef.update({
      playCount: admin.firestore.FieldValue.increment(1),
    });

    res.status(200).json({success: true, songId});
  } catch (error) {
    functions.logger.error("recordPlay error", error);
    res.status(500).json({error: "Internal server error"});
  }
});
