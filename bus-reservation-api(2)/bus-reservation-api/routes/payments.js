const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// GET tous les paiements (Admin voit tout, utilisateur voit les siens)
router.get('/', authenticateToken, async (req, res) => {
  try {
    let query, params;

    if (req.user.role === 'admin') {
      query = `
        SELECT p.*, u.name as user_name, u.email as user_email,
               r.id as reservation_id, b.bus_number, b.route
        FROM payments p
        JOIN users u ON p.user_id = u.id
        LEFT JOIN reservations r ON p.reservation_id = r.id
        LEFT JOIN buses b ON r.bus_id = b.id
        ORDER BY p.created_at DESC
      `;
      params = [];
    } else {
      query = `
        SELECT p.*, r.id as reservation_id, b.bus_number, b.route
        FROM payments p
        LEFT JOIN reservations r ON p.reservation_id = r.id
        LEFT JOIN buses b ON r.bus_id = b.id
        WHERE p.user_id = $1
        ORDER BY p.created_at DESC
      `;
      params = [req.user.id];
    }

    const result = await db.query(query, params);
    res.json({ payments: result.rows });
  } catch (error) {
    console.error('Error fetching payments:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des paiements' });
  }
});

// GET un paiement spécifique
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await db.query(`
      SELECT p.*, u.name as user_name, u.email as user_email,
             r.id as reservation_id, r.seat_number,
             b.bus_number, b.route
      FROM payments p
      JOIN users u ON p.user_id = u.id
      LEFT JOIN reservations r ON p.reservation_id = r.id
      LEFT JOIN buses b ON r.bus_id = b.id
      WHERE p.id = $1
    `, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Paiement non trouvé' });
    }

    const payment = result.rows[0];

    // Vérifier les permissions
    if (req.user.role !== 'admin' && payment.user_id !== req.user.id) {
      return res.status(403).json({ error: 'Accès non autorisé' });
    }

    res.json({ payment });
  } catch (error) {
    console.error('Error fetching payment:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération du paiement' });
  }
});

// GET statistiques des paiements (Admin uniquement)
router.get('/stats/summary', authenticateToken, requireAdmin, async (req, res) => {
  try {
    // Total des revenus
    const revenueResult = await db.query(`
      SELECT SUM(amount) as total_revenue
      FROM payments
      WHERE type = 'payment' AND status = 'completed'
    `);

    // Total des remboursements
    const refundResult = await db.query(`
      SELECT SUM(amount) as total_refunds
      FROM payments
      WHERE type = 'refund' AND status = 'completed'
    `);

    // Total des dédommagements (compensations)
    const compensationResult = await db.query(`
      SELECT SUM(amount) as total_compensation
      FROM payments
      WHERE type = 'compensation' AND status = 'completed'
    `);

    // Nombre de transactions
    const countResult = await db.query(`
      SELECT 
        COUNT(*) FILTER (WHERE type = 'payment') as total_payments,
        COUNT(*) FILTER (WHERE type = 'refund') as total_refunds,
        COUNT(*) FILTER (WHERE type = 'compensation') as total_compensations
      FROM payments
      WHERE status = 'completed'
    `);

    res.json({
      revenue: {
        total: parseFloat(revenueResult.rows[0].total_revenue) || 0,
        refunds: parseFloat(refundResult.rows[0].total_refunds) || 0,
        compensation: parseFloat(compensationResult.rows[0].total_compensation) || 0,
        net: (parseFloat(revenueResult.rows[0].total_revenue) || 0) - 
             (parseFloat(refundResult.rows[0].total_refunds) || 0)
      },
      transactions: countResult.rows[0]
    });
  } catch (error) {
    console.error('Error fetching payment stats:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des statistiques' });
  }
});

module.exports = router;
