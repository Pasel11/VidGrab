const { spawn, exec } = require('child_process');
const path = require('path');
const fs = require('fs');
const os = require('os');
const { v4: uuidv4 } = require('uuid');

const YtDlpWrap = require('yt-dlp-wrap');
let ytdlp;

// Download yt-dlp binary on first use
async function getYtdlp() {
  if (!ytdlp) {
    const ytDlpPath = path.join(os.tmpdir(), 'yt-dlp');
    if (!fs.existsSync(ytDlpPath)) {
      console.log('[YTDLP] Downloading yt-dlp binary...');
      ytdlp = await YtDlpWrap.downloadFromGithub(ytDlpPath);
    } else {
      ytdlp = new YtDlpWrap(ytDlpPath);
    }
  }
  return ytdlp;
}

class YtdlpService {
  /**
   * Get video metadata and available formats
   */
  static async getVideoInfo(url) {
    const ytDlp = await getYtdlp();
    const output = await ytDlp.execute([
      '--dump-json',
      '--no-playlist',
      '--no-warnings',
      url,
    ]);

    try {
      return JSON.parse(output);
    } catch {
      throw new Error('Failed to parse video info');
    }
  }

  /**
   * Download video with specific quality/format
   */
  static async downloadVideo(url, options = {}) {
    const ytDlp = await getYtdlp();
    const outputDir = path.join(os.tmpdir(), 'vidgrab-downloads');
    if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });

    const outputFile = path.join(outputDir, `${uuidv4()}.%(ext)s`);
    const args = [
      '--no-playlist',
      '--no-warnings',
      '-o', outputFile,
    ];

    if (options.formatId) {
      args.unshift('-f', options.formatId);
    } else if (options.quality) {
      const formatMap = {
        '4K': 'bestvideo[height<=2160]+bestaudio/best[height<=2160]',
        '1440p': 'bestvideo[height<=1440]+bestaudio/best[height<=1440]',
        '1080p': 'bestvideo[height<=1080]+bestaudio/best[height<=1080]',
        '720p': 'bestvideo[height<=720]+bestaudio/best[height<=720]',
        '480p': 'bestvideo[height<=480]+bestaudio/best[height<=480]',
        '360p': 'bestvideo[height<=360]+bestaudio/best[height<=360]',
      };
      if (formatMap[options.quality]) {
        args.unshift('-f', formatMap[options.quality]);
      }
    }

    args.push(url);
    await ytDlp.execute(args);

    // Find the downloaded file
    const files = fs.readdirSync(outputDir).filter(f => f.startsWith(uuidv4()));
    if (files.length === 0) throw new Error('Download completed but file not found');
    return path.join(outputDir, files[0]);
  }

  /**
   * Extract audio from video
   */
  static async extractAudio(url, options = {}) {
    const ytDlp = await getYtdlp();
    const outputDir = path.join(os.tmpdir(), 'vidgrab-audio');
    if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir, { recursive: true });

    const outputFile = path.join(outputDir, `${uuidv4()}.%(ext)s`);
    await ytDlp.execute([
      '--no-playlist',
      '--no-warnings',
      '-x',
      '--audio-format', options.format || 'mp3',
      '--audio-quality', options.bitrate ? (10 - Math.log2(options.bitrate / 1000)).toString() : '0',
      '-o', outputFile,
      url,
    ]);

    const files = fs.readdirSync(outputDir);
    const audioFile = files.find(f => f.startsWith(uuidv4()));
    if (!audioFile) throw new Error('Audio extraction failed');
    return path.join(outputDir, audioFile);
  }

  /**
   * Get available subtitles
   */
  static async getSubtitles(url) {
    const ytDlp = await getYtdlp();
    const output = await ytDlp.execute([
      '--list-subs',
      '--no-playlist',
      url,
    ]);
    return output;
  }

  /**
   * Get video thumbnail
   */
  static async getThumbnail(url) {
    const info = await this.getVideoInfo(url);
    return info.thumbnail;
  }

  /**
   * Get playlist info
   */
  static async getPlaylistInfo(url) {
    const ytDlp = await getYtdlp();
    const output = await ytDlp.execute([
      '--dump-json',
      '--flat-playlist',
      url,
    ]);

    try {
      return JSON.parse(output);
    } catch {
      throw new Error('Failed to parse playlist info');
    }
  }
}

module.exports = YtdlpService;