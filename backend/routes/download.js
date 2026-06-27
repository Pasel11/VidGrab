const express = require('express');
const router = express.Router();
const YtdlpService = require('../services/ytdlp-service');
const { detectPlatform } = require('../utils/platform-detector');

/**
 * POST /api/download/info
 * Fetch video information without downloading
 * Body: { url: string }
 */
router.post('/info', async (req, res) => {
  try {
    const { url } = req.body;
    if (!url) return res.status(400).json({ error: 'URL is required', code: 400 });

    const platform = detectPlatform(url);
    if (!platform) return res.status(400).json({ error: 'Unsupported platform', code: 400 });

    const info = await YtdlpService.getVideoInfo(url);
    res.json({
      success: true,
      data: {
        url,
        platform: platform.name,
        platformId: platform.id,
        title: info.title,
        thumbnail: info.thumbnail,
        author: info.uploader || info.channel,
        duration: info.duration,
        durationFormatted: formatDuration(info.duration),
        description: info.description?.substring(0, 500),
        qualities: info.formats
          ?.filter(f => f.vcodec !== 'none' || f.acodec !== 'none')
          .map(f => ({
            label: formatQualityLabel(f),
            resolution: f.resolution || 'audio',
            format: f.ext?.toUpperCase() || 'MP4',
            fileSize: f.filesize ? formatFileSize(f.filesize) : 'N/A',
            fileSizeBytes: f.filesize || 0,
            downloadUrl: f.url || '',
            formatId: f.format_id,
            isAudio: f.vcodec === 'none',
          }))
          .filter((v, i, a) => a.findIndex(t => t.resolution === v.resolution) === i)
          .sort((a, b) => {
            const aH = parseInt(a.resolution) || 0;
            const bH = parseInt(b.resolution) || 0;
            return bH - aH;
          }) || [],
      },
    });
  } catch (error) {
    console.error('[DOWNLOAD INFO ERROR]', error.message);
    res.status(500).json({ error: 'Failed to fetch video info', code: 500, details: error.message });
  }
});

/**
 * POST /api/download/stream
 * Stream/download video file
 * Body: { url: string, formatId: string, quality: string }
 */
router.post('/stream', async (req, res) => {
  try {
    const { url, formatId, quality } = req.body;
    if (!url) return res.status(400).json({ error: 'URL is required', code: 400 });

    const outputPath = await YtdlpService.downloadVideo(url, { formatId, quality });
    const fileName = path.basename(outputPath);

    res.download(outputPath, fileName, (err) => {
      if (!err) {
        // Clean up file after download
        setTimeout(() => {
          fs.unlink(outputPath, () => {});
        }, 60000);
      }
    });
  } catch (error) {
    console.error('[DOWNLOAD STREAM ERROR]', error.message);
    res.status(500).json({ error: 'Download failed', code: 500, details: error.message });
  }
});

/**
 * POST /api/download/audio
 * Extract audio from video
 * Body: { url: string, format: 'mp3'|'wav'|'aac', bitrate: number }
 */
router.post('/audio', async (req, res) => {
  try {
    const { url, format = 'mp3', bitrate = 320 } = req.body;
    if (!url) return res.status(400).json({ error: 'URL is required', code: 400 });

    const outputPath = await YtdlpService.extractAudio(url, { format, bitrate });
    res.download(outputPath, (err) => {
      if (!err) setTimeout(() => fs.unlink(outputPath, () => {}), 60000);
    });
  } catch (error) {
    res.status(500).json({ error: 'Audio extraction failed', code: 500 });
  }
});

// === HELPERS ===
function formatDuration(seconds) {
  if (!seconds) return '0:00';
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  const s = Math.floor(seconds % 60);
  return h > 0 ? `${h}:${m.toString().padStart(2,'0')}:${s.toString().padStart(2,'0')}` : `${m}:${s.toString().padStart(2,'0')}`;
}

function formatFileSize(bytes) {
  if (!bytes) return 'N/A';
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1048576) return (bytes/1024).toFixed(1) + ' KB';
  if (bytes < 1073741824) return (bytes/1048576).toFixed(1) + ' MB';
  return (bytes/1073741824).toFixed(2) + ' GB';
}

function formatQualityLabel(format) {
  if (format.vcodec === 'none') return `Audio ${format.abr || ''}kbps`;
  const res = format.resolution || 'unknown';
  return format.isdash ? `DASH ${res}` : res;
}

const path = require('path');
const fs = require('fs');

module.exports = router;