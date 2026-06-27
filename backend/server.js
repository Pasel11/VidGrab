const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const fs = require('fs');

// Routes
const downloadRoutes = require('./routes/download');
const conversionRoutes = require('./routes/conversion');
const authRoutes = require('./routes/auth');
const referralRoutes = require('./routes/referral');
const analyticsRoutes = require('./routes/analytics');

const app = express();
const PORT = process.env.PORT || 3000;

// === MIDDLEWARE ===
app.use(helmet({ contentSecurityPolicy: false }));
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['*'],
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Device-ID'],
}));
app.use(compression());
app.use(morgan('combined'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Rate limiting
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: process.env.RATE_LIMIT_MAX || 100,
  message: { error: 'Too many requests, please try again later.', code: 429 },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', globalLimiter);

// Strict rate limit for downloads
const downloadLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: process.env.DOWNLOAD_RATE_LIMIT || 10,
  message: { error: 'Download rate limit exceeded.', code: 429 },
});
app.use('/api/download/', downloadLimiter);

// === API ROUTES ===
app.use('/api/download', downloadRoutes);
app.use('/api/convert', conversionRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/referral', referralRoutes);
app.use('/api/analytics', analyticsRoutes);

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    version: '1.0.0',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    services: {
      ytDlp: true,
      ffmpeg: true,
      redis: false, // Update based on actual connection
    },
  });
});

// Supported platforms
app.get('/api/platforms', (req, res) => {
  res.json({
    platforms: [
      { id: 'youtube', name: 'YouTube', maxQuality: '4K', formats: ['MP4', 'MP3', 'WEBM'] },
      { id: 'instagram', name: 'Instagram', maxQuality: '1080p', formats: ['MP4', 'MP3', 'JPG'] },
      { id: 'tiktok', name: 'TikTok', maxQuality: '1080p', formats: ['MP4', 'MP3'] },
      { id: 'twitter', name: 'X (Twitter)', maxQuality: '1080p', formats: ['MP4', 'MP3', 'GIF'] },
      { id: 'facebook', name: 'Facebook', maxQuality: '1080p', formats: ['MP4', 'MP3'] },
      { id: 'snapchat', name: 'Snapchat', maxQuality: '1080p', formats: ['MP4'] },
      { id: 'pinterest', name: 'Pinterest', maxQuality: '1080p', formats: ['MP4', 'GIF', 'JPG'] },
      { id: 'linkedin', name: 'LinkedIn', maxQuality: '1080p', formats: ['MP4'] },
      { id: 'reddit', name: 'Reddit', maxQuality: '1080p', formats: ['MP4', 'GIF'] },
      { id: 'tumblr', name: 'Tumblr', maxQuality: '1080p', formats: ['MP4'] },
      { id: 'vimeo', name: 'Vimeo', maxQuality: '4K', formats: ['MP4', 'MP3', 'WEBM'] },
      { id: 'dailymotion', name: 'Dailymotion', maxQuality: '1080p', formats: ['MP4', 'MP3'] },
    ],
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found', code: 404 });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error(`[ERROR] ${new Date().toISOString()}:`, err.message);
  res.status(err.status || 500).json({
    error: process.env.NODE_ENV === 'production' ? 'Internal server error' : err.message,
    code: err.status || 500,
  });
});

// === START SERVER ===
const server = app.listen(PORT, () => {
  console.log(`
  ╔══════════════════════════════════════╗
  ║       VidGrab API Server            ║
  ║  Running on port ${PORT}              ║
  ║  Environment: ${process.env.NODE_ENV || 'development'}      ║
  ║  Rate Limit: ${process.env.RATE_LIMIT_MAX || 100}/15min    ║
  ╚══════════════════════════════════════╝
  `);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully...');
  server.close(() => process.exit(0));
});

module.exports = app;