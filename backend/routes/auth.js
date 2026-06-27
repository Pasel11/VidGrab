const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'vidgrab-secret-key-2024';

// In-memory store (replace with database in production)
const users = new Map();

/**
 * POST /api/auth/register
 */
router.post('/register', async (req, res) => {
  try {
    const { email, password, name } = req.body;
    if (!email || !password) return res.status(400).json({ error: 'Email and password required' });

    if (users.has(email)) return res.status(409).json({ error: 'Email already registered' });

    const hashedPassword = await bcrypt.hash(password, 12);
    const user = {
      id: uuidv4(),
      email, name: name || email.split('@')[0],
      password: hashedPassword,
      isPro: false,
      proExpiry: null,
      referralCode: uuidv4().substring(0, 8).toUpperCase(),
      referralCount: 0,
      createdAt: new Date().toISOString(),
    };

    users.set(email, user);
    const token = jwt.sign({ userId: user.id, email }, JWT_SECRET, { expiresIn: '30d' });

    res.json({ success: true, data: { token, user: { id: user.id, email: user.email, name: user.name, referralCode: user.referralCode } } });
  } catch (error) {
    res.status(500).json({ error: 'Registration failed' });
  }
});

/**
 * POST /api/auth/login
 */
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = users.get(email);
    if (!user) return res.status(401).json({ error: 'Invalid credentials' });

    const isValid = await bcrypt.compare(password, user.password);
    if (!isValid) return res.status(401).json({ error: 'Invalid credentials' });

    const token = jwt.sign({ userId: user.id, email }, JWT_SECRET, { expiresIn: '30d' });
    res.json({ success: true, data: { token, user: { id: user.id, email: user.email, name: user.name, isPro: user.isPro } } });
  } catch (error) {
    res.status(500).json({ error: 'Login failed' });
  }
});

/**
 * GET /api/auth/me
 */
router.get('/me', (req, res) => {
  // Verify token from Authorization header
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) return res.status(401).json({ error: 'No token provided' });

  try {
    const decoded = jwt.verify(authHeader.split(' ')[1], JWT_SECRET);
    res.json({ success: true, data: { userId: decoded.userId, email: decoded.email } });
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
});

module.exports = router;