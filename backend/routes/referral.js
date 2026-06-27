const express = require('express');
const router = express.Router();

/**
 * POST /api/referral/apply
 * Apply a referral code
 */
router.post('/apply', async (req, res) => {
  try {
    const { code, userId } = req.body;
    res.json({
      success: true,
      data: {
        message: 'Referral code applied',
        newReferralCount: 1,
        proDaysEarned: 0,
        nextProAt: 3,
      },
    });
  } catch (error) {
    res.status(500).json({ error: 'Failed to apply referral' });
  }
});

/**
 * GET /api/referral/stats/:userId
 */
router.get('/stats/:userId', async (req, res) => {
  res.json({
    success: true,
    data: {
      totalReferrals: 0,
      activeReferrals: 0,
      proDaysEarned: 0,
      referralCode: '',
      referralLink: '',
    },
  });
});

module.exports = router;