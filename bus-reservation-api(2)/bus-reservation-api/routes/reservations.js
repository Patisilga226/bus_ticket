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
        SELECT r.*,
               COALESCE(NULLIF(r.passenger_name, ''), u.name) as user_name,
               u.email as user_email,
               b.bus_number,
               COALESCE(NULLIF(r.route_override, ''), b.route) as route,
               COALESCE((
                 SELECT p.amount - p.deposit
                 FROM payments p
                 WHERE p.reservation_id = r.id
                 ORDER BY p.created_at DESC
                 LIMIT 1
               ), b.price) as price
        FROM reservations r
        JOIN users u ON r.user_id = u.id
        JOIN buses b ON r.bus_id = b.id
        ORDER BY r.created_at DESC
      `;
      params = [];
    } else {
      query = `
        SELECT r.*,
               COALESCE(NULLIF(r.passenger_name, ''), u.name) as user_name,
               u.email as user_email,
               b.bus_number,
               COALESCE(NULLIF(r.route_override, ''), b.route) as route,
               COALESCE((
                 SELECT p.amount - p.deposit
                 FROM payments p
                 WHERE p.reservation_id = r.id
                 ORDER BY p.created_at DESC
                 LIMIT 1
               ), b.price) as price
        FROM reservations r
        JOIN users u ON r.user_id = u.id
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
      SELECT r.*,
             COALESCE(NULLIF(r.passenger_name, ''), u.name) as user_name,
             u.email as user_email,
             b.bus_number,
             COALESCE(NULLIF(r.route_override, ''), b.route) as route,
             COALESCE((
               SELECT p.amount - p.deposit
               FROM payments p
               WHERE p.reservation_id = r.id
               ORDER BY p.created_at DESC
               LIMIT 1
             ), b.price) as price,
             b.departure_time as bus_departure
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

// POST créer une nouvelle réservation
router.post('/', authenticateToken, async (req, res) => {
  const client = await db.pool.connect();
  
  try {
    await client.query('BEGIN');

    const { bus_id, seat_number, amount } = req.body;
    const passengerNameInput = (
      req.body.passenger_name ??
      req.body.passengerName ??
      req.body.user_name ??
      ''
    ).toString().trim();
    const routeOverrideInput = (
      req.body.route_override ??
      req.body.route ??
      req.body.custom_route ??
      ''
    ).toString().trim();
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
      INSERT INTO reservations (user_id, bus_id, passenger_name, route_override, seat_number, qr_code, departure_time, qr_valid_until, status)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
      RETURNING *
    `, [
      user_id,
      bus_id,
      passengerNameInput || null,
      routeOverrideInput || null,
      finalSeatNumber,
      qrCode,
      bus.departure_time,
      qrValidUntil,
      'pending',
    ]);

    const reservation = reservationResult.rows[0];

    // Mettre à jour le nombre de places disponibles
    await client.query(
      'UPDATE buses SET available_seats = available_seats - 1 WHERE id = $1',
      [bus_id]
    );

    // Montant ticket: priorité à la saisie client, sinon prix du bus
    const requestedAmount = parseFloat(amount);
    const ticketPrice = Number.isFinite(requestedAmount) && requestedAmount > 0
      ? requestedAmount
      : parseFloat(bus.price);

    // Créer le paiement (ticket + caution)
    const totalAmount = ticketPrice + deposit;
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
        user_name: reservation.passenger_name || req.user.name || 'Passager',
        bus_number: bus.bus_number,
        route: reservation.route_override || bus.route,
        price: ticketPrice
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
