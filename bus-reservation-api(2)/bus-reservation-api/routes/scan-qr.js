const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { authenticateToken, requireEmployee } = require('../middleware/auth');

// POST scanner un QR code (Employé uniquement)
router.post('/', authenticateToken, requireEmployee, async (req, res) => {
  const client = await db.pool.connect();
  
  try {
    await client.query('BEGIN');

    const { qr_code } = req.body;
    const employee_id = req.user.id;

    if (!qr_code) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'QR code requis' });
    }

    // Trouver la réservation correspondante
    const reservationResult = await client.query(`
      SELECT r.*, b.bus_number, b.route, b.price, b.departure_time as bus_departure,
             u.name as user_name, u.email as user_email
      FROM reservations r
      JOIN buses b ON r.bus_id = b.id
      JOIN users u ON r.user_id = u.id
      WHERE r.qr_code = $1
    `, [qr_code]);

    if (reservationResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'QR code invalide' });
    }

    const reservation = reservationResult.rows[0];

    // Vérifier que la réservation n'a pas déjà été scannée
    if (reservation.status === 'scanned') {
      await client.query('ROLLBACK');
      return res.status(400).json({ 
        error: 'Ce QR code a déjà été scanné',
        reservation
      });
    }

    // Vérifier que la réservation n'est pas annulée
    if (reservation.status === 'cancelled') {
      await client.query('ROLLBACK');
      return res.status(400).json({ 
        error: 'Cette réservation a été annulée',
        reservation
      });
    }

    const now = new Date();
    const departureTime = new Date(reservation.bus_departure);
    const qrValidUntil = new Date(reservation.qr_valid_until);
    const deposit = parseFloat(process.env.TICKET_DEPOSIT) || 100;
    const ticketPrice = parseFloat(reservation.price);

    let refundAmount = 0;
    let compensationAmount = 0;
    let message = '';
    let isOnTime = false;

    // Vérifier si l'utilisateur est à l'heure ou en retard
    if (now <= qrValidUntil) {
      // À l'heure : rembourser la caution de 100 FCFA
      isOnTime = true;
      refundAmount = deposit;
      message = `Passager à l'heure ! Caution de ${deposit} FCFA remboursée.`;
    } else if (now > qrValidUntil && now < departureTime) {
      // En retard mais avant le départ : rembourser le prix du ticket, garder 100 FCFA
      isOnTime = false;
      refundAmount = ticketPrice;
      compensationAmount = deposit;
      message = `Passager en retard. Prix du ticket (${ticketPrice} FCFA) remboursé. Dédommagement de ${deposit} FCFA retenu.`;
    } else {
      // Après le départ du bus
      await client.query('ROLLBACK');
      return res.status(400).json({ 
        error: 'Le bus est déjà parti. QR code expiré.',
        reservation
      });
    }

    // Mettre à jour la réservation
    await client.query(
      'UPDATE reservations SET status = $1 WHERE id = $2',
      ['scanned', reservation.id]
    );

    // Créer le paiement de remboursement si nécessaire
    if (refundAmount > 0) {
      await client.query(`
        INSERT INTO payments (reservation_id, user_id, amount, deposit, type, status)
        VALUES ($1, $2, $3, $4, $5, $6)
      `, [reservation.id, reservation.user_id, refundAmount, 0, 'refund', 'completed']);

      // Mettre à jour le wallet de l'utilisateur
      await client.query(
        'UPDATE users SET wallet_balance = wallet_balance + $1 WHERE id = $2',
        [refundAmount, reservation.user_id]
      );
    }

    // Enregistrer le dédommagement si applicable
    if (compensationAmount > 0) {
      await client.query(`
        INSERT INTO payments (reservation_id, user_id, amount, deposit, type, status)
        VALUES ($1, $2, $3, $4, $5, $6)
      `, [reservation.id, reservation.user_id, compensationAmount, 0, 'compensation', 'completed']);
    }

    await client.query('COMMIT');

    res.json({
      success: true,
      message,
      scan_details: {
        reservation_id: reservation.id,
        user_name: reservation.user_name,
        bus_number: reservation.bus_number,
        route: reservation.route,
        seat_number: reservation.seat_number,
        is_on_time: isOnTime,
        refund_amount: refundAmount,
        compensation_amount: compensationAmount,
        scanned_at: now,
        departure_time: departureTime,
        qr_valid_until: qrValidUntil
      }
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error scanning QR code:', error);
    res.status(500).json({ error: 'Erreur lors du scan du QR code' });
  } finally {
    client.release();
  }
});

// GET historique des scans (Employé et Admin)
router.get('/history', authenticateToken, requireEmployee, async (req, res) => {
  try {
    const result = await db.query(`
      SELECT r.id, r.status, r.seat_number, r.created_at as reservation_created,
             u.name as user_name, u.email as user_email,
             b.bus_number, b.route, b.departure_time,
             p.amount as refund_amount, p.type as payment_type
      FROM reservations r
      JOIN users u ON r.user_id = u.id
      JOIN buses b ON r.bus_id = b.id
      LEFT JOIN payments p ON p.reservation_id = r.id AND p.type IN ('refund', 'compensation')
      WHERE r.status = 'scanned'
      ORDER BY r.created_at DESC
      LIMIT 100
    `);

    res.json({ scans: result.rows });
  } catch (error) {
    console.error('Error fetching scan history:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération de l\'historique' });
  }
});

module.exports = router;
