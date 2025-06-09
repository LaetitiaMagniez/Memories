const functions = require("firebase-functions");
const admin = require("firebase-admin");
const ffmpeg = require("fluent-ffmpeg");
const ffmpegPath = require("@ffmpeg-installer/ffmpeg").path;
const path = require("path");
const os = require("os");
const fs = require("fs");

admin.initializeApp();
ffmpeg.setFfmpegPath(ffmpegPath);

exports.generateVideoThumbnail = functions.storage
  .object()
  .onFinalize(async (object) => {
    const fileBucket = object.bucket;
    const filePath = object.name;
    const contentType = object.contentType;

    if (!contentType.startsWith("video/")) {
      console.log("Not a video file, skipping.");
      return null;
    }

    const fileName = path.basename(filePath);
    const bucket = admin.storage().bucket(fileBucket);
    const tempVideoPath = path.join(os.tmpdir(), fileName);
    const thumbnailFileName = `${path.parse(fileName).name}_thumb.jpg`;
    const tempThumbnailPath = path.join(os.tmpdir(), thumbnailFileName);
    const thumbnailStoragePath = path.join(path.dirname(filePath), thumbnailFileName);

    // Téléchargement de la vidéo temporairement
    await bucket.file(filePath).download({ destination: tempVideoPath });
    console.log("Video downloaded locally to", tempVideoPath);

    // Générer la miniature avec FFmpeg
    await new Promise((resolve, reject) => {
      ffmpeg(tempVideoPath)
        .screenshots({
          timestamps: ["2"],
          filename: thumbnailFileName,
          folder: os.tmpdir(),
          size: "320x?",
        })
        .on("end", resolve)
        .on("error", reject);
    });

    console.log("Thumbnail created at", tempThumbnailPath);

    // Upload de la miniature
    await bucket.upload(tempThumbnailPath, {
      destination: thumbnailStoragePath,
      metadata: {
        contentType: "image/jpeg",
      },
    });

    console.log("Thumbnail uploaded to", thumbnailStoragePath);

    // Nettoyage
    fs.unlinkSync(tempVideoPath);
    fs.unlinkSync(tempThumbnailPath);

    // Retour optionnel
    return null;
  });
