const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { authenticateToken, requireEmployee } = require('../middleware/auth');

const resolveEmployeeBusId = async (user) => {
  if (user.role === 'admin') {
    return null;
  }

  if (user.role !== 'employee') {
    return null;
  }

  // 1) Token employee-login: bus_id et employee_assignment_id
  if (user.bus_id) {
    const assignmentByUserAndBus = await db.query(
      'SELECT id, bus_id FROM employees WHERE user_id = $1 AND bus_id = $2 LIMIT 1',
      [user.id, user.bus_id]
    );

    if (assignmentByUserAndBus.rows.length > 0) {
      return assignmentByUserAndBus.rows[0].bus_id;
    }

    if (user.employee_assignment_id) {
      const assignmentById = await db.query(
        'SELECT id, bus_id FROM employees WHERE id = $1 AND user_id = $2 LIMIT 1',
        [user.employee_assignment_id, user.id]
      );

      if (assignmentById.rows.length > 0) {
        return assignmentById.rows[0].bus_id;
      }
    }
  }

  // 2) Compatibilite login email/password: utiliser la derniere assignation
  const fallbackAssignment = await db.query(
    `
    SELECT id, bus_id
    FROM employees
    WHERE user_id = $1
    ORDER BY assigned_at DESC
    LIMIT 1
    `,
    [user.id]
  );

  if (fallbackAssignment.rows.length > 0) {
    return fallbackAssignment.rows[0].bus_id;
  }

  return null;
};

// GET clients/passagers pour le bus assigne
router.get('/clients', authenticateToken, requireEmployee, async (req, res) => {
  try {
    const { status = 'all', bus_id } = req.query;
    const isAdmin = req.user.role === 'admin';

    let targetBusId = null;
    if (isAdmin) {
      targetBusId = bus_id ? parseInt(bus_id, 10) : null;
    } else {
      targetBusId = await resolveEmployeeBusId(req.user);
      if (!targetBusId) {
        return res.status(403).json({ error: 'Aucune assignation de bus trouvee pour cet employe' });
      }
    }

    const params = [];
    const whereParts = [];

    if (targetBusId) {
      params.push(targetBusId);
      whereParts.push(`r.bus_id = $${params.length}`);
    }

    if (status !== 'all') {
      params.push(status);
      whereParts.push(`r.status = $${params.length}`);
    }

    const whereClause = whereParts.length > 0 ? `WHERE ${whereParts.join(' AND ')}` : '';

    const query = `
      SELECT r.id as reservation_id, r.bus_id, r.seat_number, r.status,
             r.departure_time, r.qr_valid_until, r.created_at,
             u.id as client_id, u.name as client_name, u.email as client_email, u.phone as client_phone,
             b.bus_number, b.route, b.price
      FROM reservations r
      JOIN users u ON r.user_id = u.id
      JOIN buses b ON r.bus_id = b.id
      ${whereClause}
      ORDER BY r.departure_time ASC, r.seat_number ASC
    `;

    const result = await db.query(query, params);

    return res.json({
      clients: result.rows,
      filters: {
        status,
        bus_id: targetBusId
      }
    });
  } catch (error) {
    console.error('Error fetching clients:', error);
    return res.status(500).json({ error: 'Erreur lors de la recuperation des clients' });
  }
});

// POST scanner un QR code (Employe uniquement)
router.post('/', authenticateToken, requireEmployee, async (req, res) => {
  const client = await db.pool.connect();

  try {
    await client.query('BEGIN');

    const { qr_code } = req.body;

    if (!qr_code) {
      await client.query('ROLLBACK');
      return res.status(400).json({ error: 'QR code requis' });
    }

    const employeeBusId = req.user.role === 'admin' ? null : await resolveEmployeeBusId(req.user);

    if (req.user.role === 'employee' && !employeeBusId) {
      await client.query('ROLLBACK');
      return res.status(403).json({ error: 'Aucune assignation de bus trouvee pour cet employe' });
    }

    // Trouver la reservation correspondante
    const reservationResult = await client.query(
      `
      SELECT r.*, b.bus_number, b.route, b.price, b.departure_time as bus_departure,
             u.name as user_name, u.email as user_email
      FROM reservations r
      JOIN buses b ON r.bus_id = b.id
      JOIN users u ON r.user_id = u.id
      WHERE r.qr_code = $1
      `,
      [qr_code]
    );

    if (reservationResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ error: 'QR code invalide' });
    }

    const reservation = reservationResult.rows[0];

    // Verifier l'autorisation sur le bus assigne pour les employes
    if (req.user.role === 'employee' && reservation.bus_id !== employeeBusId) {
      await client.query('ROLLBACK');
      return res.status(403).json({ error: 'Ce QR code appartient a un autre bus' });
    }

    if (reservation.status === 'scanned') {
      await client.query('ROLLBACK');
      return res.status(400).json({
        error: 'Ce QR code a deja ete scanne',
        reservation
      });
    }

    if (reservation.status === 'cancelled') {
      await client.query('ROLLBACK');
      return res.status(400).json({
        error: 'Cette reservation a ete annulee',
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

    if (now <= qrValidUntil) {
      isOnTime = true;
      refundAmount = deposit;
      message = `Passager a l'heure. Caution de ${deposit} FCFA remboursee.`;
    } else if (now > qrValidUntil && now < departureTime) {
      isOnTime = false;
      refundAmount = ticketPrice;
      compensationAmount = deposit;
      message = `Passager en retard. Ticket (${ticketPrice} FCFA) rembourse. Dedommagement de ${deposit} FCFA retenu.`;
    } else {
      await client.query('ROLLBACK');
      return res.status(400).json({
        error: 'Le bus est deja parti. QR code expire.',
        reservation
      });
    }

    await client.query(
      'UPDATE reservations SET status = $1 WHERE id = $2',
      ['scanned', reservation.id]
    );

    if (refundAmount > 0) {
      await client.query(
        `
        INSERT INTO payments (reservation_id, user_id, amount, deposit, type, status)
        VALUES ($1, $2, $3, $4, $5, $6)
        `,
        [reservation.id, reservation.user_id, refundAmount, 0, 'refund', 'completed']
      );

      await client.query(
        'UPDATE users SET wallet_balance = wallet_balance + $1 WHERE id = $2',
        [refundAmount, reservation.user_id]
      );
    }

    if (compensationAmount > 0) {
      await client.query(
        `
        INSERT INTO payments (reservation_id, user_id, amount, deposit, type, status)
        VALUES ($1, $2, $3, $4, $5, $6)
        `,
        [reservation.id, reservation.user_id, compensationAmount, 0, 'compensation', 'completed']
      );
    }

    await client.query('COMMIT');

    return res.json({
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
    return res.status(500).json({ error: 'Erreur lors du scan du QR code' });
  } finally {
    client.release();
  }
});

// GET historique des scans (Employe/Admin)
router.get('/history', authenticateToken, requireEmployee, async (req, res) => {
  try {
    const isAdmin = req.user.role === 'admin';
    const employeeBusId = isAdmin ? null : await resolveEmployeeBusId(req.user);

    if (!isAdmin && !employeeBusId) {
      return res.status(403).json({ error: 'Aucune assignation de bus trouvee pour cet employe' });
    }

    const params = [];
    let busFilter = '';

    if (!isAdmin) {
      params.push(employeeBusId);
      busFilter = `AND r.bus_id = $${params.length}`;
    }

    const query = `
      SELECT r.id, r.status, r.seat_number, r.created_at as reservation_created,
             u.name as user_name, u.email as user_email,
             b.bus_number, b.route, b.departure_time,
             p.amount as refund_amount, p.type as payment_type
      FROM reservations r
      JOIN users u ON r.user_id = u.id
      JOIN buses b ON r.bus_id = b.id
      LEFT JOIN payments p ON p.reservation_id = r.id AND p.type IN ('refund', 'compensation')
      WHERE r.status = 'scanned'
      ${busFilter}
      ORDER BY r.created_at DESC
      LIMIT 100
    `;

    const result = await db.query(query, params);

    return res.json({ scans: result.rows });
  } catch (error) {
    console.error('Error fetching scan history:', error);
    return res.status(500).json({ error: 'Erreur lors de la recuperation de l\'historique' });
  }
});

module.exports = router;
