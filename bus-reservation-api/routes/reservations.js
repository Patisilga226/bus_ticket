const express = require('express');
const router = express.Router();
const QRCode = require('qrcode');
const db = require('../config/database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// GET toutes les réservations (utilisateur voit les siennes, admin voit tout)
router.get('/', authenticateToken, async (req, res) => {
  try {
    let query, params;

    if (req.user.role === 'admin') {
      query = `
        SELECT r.*, u.name as user_name, u.email as user_email,
               b.bus_number, b.route, b.price
        FROM reservations r
        JOIN users u ON r.user_id = u.id
        JOIN buses b ON r.bus_id = b.id
        ORDER BY r.created_at DESC
      `;
      params = [];
    } else {
      query = `
        SELECT r.*, b.bus_number, b.route, b.price
        FROM reservations r
        JOIN buses b ON r.bus_id = b.id
        WHERE r.user_id = $1
        ORDER BY r.created_at DESC
      `;
      params = [req.user.id];
    }

    const result = await db.query(query, params);
    res.json({ reservations: result.rows });
  } catch (error) {
    console.error('Error fetching reservations:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des réservations' });
  }
});

// GET une réservation spécifique
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    
    const result = await db.query(`
      SELECT r.*, u.name as user_name, u.email as user_email,
             b.bus_number, b.route, b.price, b.departure_time as bus_departure
      FROM reservations r
      JOIN users u ON r.user_id = u.id
      JOIN buses b ON r.bus_id = b.id
      WHERE r.id = $1
    `, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Réservation non trouvée' });
    }

    const reservation = result.rows[0];

    // Vérifier les permissions
    if (req.user.role !== 'admin' && reservation.user_id !== req.user.id) {
      return res.status(403).json({ error: 'Accès non autorisé' });
    }

    res.json({ reservation });
  } catch (error) {
    console.error('Error fetching reservation:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération de la réservation' });
  }
});

// GET QR code d'une réservation (uniquement pour le propriétaire ou admin)
router.get('/:id/qrcode', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    const result = await db.query(
      'SELECT id, user_id, qr_code, qr_valid_until, status FROM reservations WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Réservation non trouvée' });
    }

    const reservation = result.rows[0];

    // Vérifier les permissions
    if (req.user.role !== 'admin' && reservation.user_id !== req.user.id) {
      return res.status(403).json({ error: 'Accès non autorisé' });
    }

    // Vérifier la validité du QR
    const now = new Date();
    const qrValidUntil = reservation.qr_valid_until ? new Date(reservation.qr_valid_until) : null;

    if (!qrValidUntil || now > qrValidUntil) {
      return res.status(400).json({ error: 'QR code expiré ou non disponible' });
    }

    return res.json({ qr_code: reservation.qr_code, qr_valid_until: qrValidUntil });
  } catch (error) {
    console.error('Error fetching reservation QR code:', error);
    return res.status(500).json({ error: 'Erreur lors de la récupération du QR code' });
  }
});

// POST créer une nouvelle réservation
router.post('/', authenticateToken, async (req, res) => {
  const client = await db.pool.connect();
  
  try {
    await client.query('BEGIN');

    const { bus_id, seat_number } = req.body;
    const user_id = req.user.id;
    const deposit = parseFloat(process.env.TICKET_DEPOSIT) || 100;

    // Validation
    if (!bus_id) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'bus_id requis' });
    }

    // Récupérer les informations du bus
    const busResult = await client.query('SELECT * FROM buses WHERE id = $1', [bus_id]);
    if (busResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Bus non trouvé' });
    }

    const bus = busResult.rows[0];

    // Vérifier qu'il reste des places
    if (bus.available_seats <= 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Aucune place disponible dans ce bus' });
    }

    // Vérifier que le bus n'est pas déjà parti
    if (new Date(bus.departure_time) < new Date()) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Ce bus est déjà parti' });
    }

    // Déterminer le numéro de siège
    let finalSeatNumber = seat_number;
    if (!finalSeatNumber) {
      // Assigner automatiquement le prochain siège disponible
      const reservedSeats = await client.query(
        'SELECT seat_number FROM reservations WHERE bus_id = $1 AND status != $2',
        [bus_id, 'cancelled']
      );
      const reserved = reservedSeats.rows.map(r => r.seat_number);
      for (let i = 1; i <= bus.total_seats; i++) {
        if (!reserved.includes(i)) {
          finalSeatNumber = i;
          break;
        }
      }
    } else {
      // Vérifier que le siège n'est pas déjà réservé
      const seatCheck = await client.query(
        'SELECT * FROM reservations WHERE bus_id = $1 AND seat_number = $2 AND status != $3',
        [bus_id, finalSeatNumber, 'cancelled']
      );
      if (seatCheck.rows.length > 0) {
        await client.query('ROLLBACK');
        return res.status(400).json({ error: 'Ce siège est déjà réservé' });
      }
    }

    // Calculer la validité du QR code (1 heure avant le départ)
    const departureTime = new Date(bus.departure_time);
    const qrValidUntil = new Date(departureTime.getTime() - 60 * 60 * 1000); // 1 heure avant

    // Générer un code QR unique
    const qrData = {
      bus_id,
      user_id,
      seat_number: finalSeatNumber,
      timestamp: Date.now(),
      random: Math.random().toString(36).substring(7)
    };
    const qrCode = await QRCode.toDataURL(JSON.stringify(qrData));

    // Créer la réservation
    const reservationResult = await client.query(`
      INSERT INTO reservations (user_id, bus_id, seat_number, qr_code, departure_time, qr_valid_until, status)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
    `, [user_id, bus_id, finalSeatNumber, qrCode, bus.departure_time, qrValidUntil, 'pending']);

    const reservation = reservationResult.rows[0];

    // Mettre à jour le nombre de places disponibles
    await client.query(
      'UPDATE buses SET available_seats = available_seats - 1 WHERE id = $1',
      [bus_id]
    );

    // Créer le paiement
    const totalAmount = parseFloat(bus.price) + deposit;
    const paymentResult = await client.query(`
      INSERT INTO payments (reservation_id, user_id, amount, deposit, type, status)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `, [reservation.id, user_id, totalAmount, deposit, 'payment', 'completed']);

    await client.query('COMMIT');

    res.status(201).json({
      message: 'Réservation créée avec succès',
      reservation: {
        ...reservation,
        bus_number: bus.bus_number,
        route: bus.route,
        price: bus.price
      },
      payment: paymentResult.rows[0],
      qr_code: qrCode,
      total_amount: totalAmount,
      qr_valid_until: qrValidUntil
    });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error creating reservation:', error);
    res.status(500).json({ error: 'Erreur lors de la création de la réservation' });
  } finally {
    client.release();
  }
});

// DELETE annuler une réservation
router.delete('/:id', authenticateToken, async (req, res) => {
  const client = await db.pool.connect();
  
  try {
    await client.query('BEGIN');

    const { id } = req.params;

    // Récupérer la réservation
    const reservationResult = await client.query('SELECT * FROM reservations WHERE id = $1', [id]);
    if (reservationResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'Réservation non trouvée' });
    }

    const reservation = reservationResult.rows[0];

    // Vérifier les permissions
    if (req.user.role !== 'admin' && reservation.user_id !== req.user.id) {
      await client.query('ROLLBACK');
      return res.status(403).json({ error: 'Accès non autorisé' });
    }

    // Vérifier que la réservation n'est pas déjà scannée
    if (reservation.status === 'scanned') {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'Impossible d\'annuler une réservation déjà scannée' });
    }

    // Annuler la réservation
    await client.query('UPDATE reservations SET status = $1 WHERE id = $2', ['cancelled', id]);

    // Libérer le siège
    await client.query(
      'UPDATE buses SET available_seats = available_seats + 1 WHERE id = $1',
      [reservation.bus_id]
    );

    await client.query('COMMIT');

    res.json({ message: 'Réservation annulée avec succès' });
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error cancelling reservation:', error);
    res.status(500).json({ error: 'Erreur lors de l\'annulation de la réservation' });
  } finally {
    client.release();
  }
});

module.exports = router;
