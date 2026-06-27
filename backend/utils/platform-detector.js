const platforms = [
  { id: 'youtube', patterns: ['youtube.com', 'youtu.be', 'youtube-nocookie.com'], name: 'YouTube' },
  { id: 'instagram', patterns: ['instagram.com', 'instagr.am'], name: 'Instagram' },
  { id: 'tiktok', patterns: ['tiktok.com', 'vm.tiktok.com'], name: 'TikTok' },
  { id: 'twitter', patterns: ['x.com', 'twitter.com'], name: 'X (Twitter)' },
  { id: 'facebook', patterns: ['facebook.com', 'fb.watch', 'fb.com'], name: 'Facebook' },
  { id: 'snapchat', patterns: ['snapchat.com'], name: 'Snapchat' },
  { id: 'pinterest', patterns: ['pinterest.com', 'pin.it'], name: 'Pinterest' },
  { id: 'linkedin', patterns: ['linkedin.com'], name: 'LinkedIn' },
  { id: 'reddit', patterns: ['reddit.com'], name: 'Reddit' },
  { id: 'tumblr', patterns: ['tumblr.com'], name: 'Tumblr' },
  { id: 'vimeo', patterns: ['vimeo.com'], name: 'Vimeo' },
  { id: 'dailymotion', patterns: ['dailymotion.com', 'dai.ly'], name: 'Dailymotion' },
];

function detectPlatform(url) {
  if (!url) return null;
  try {
    const hostname = new URL(url).hostname.toLowerCase();
    for (const platform of platforms) {
      for (const pattern of platform.patterns) {
        if (hostname === pattern || hostname.endsWith('.' + pattern)) {
          return platform;
        }
      }
    }
  } catch {}
  return null;
}

function isValidUrl(url) {
  try {
    const parsed = new URL(url);
    return parsed.protocol === 'http:' || parsed.protocol === 'https:';
  } catch {
    return false;
  }
}

module.exports = { detectPlatform, isValidUrl, platforms };