const express = require('express');
const router = express.Router();
const db = require('../config/database');

// Debug endpoint to view current database state
router.get('/database-state', async (req, res) => {
  try {
    // Get all tables data
    const usersResult = await db.query('SELECT * FROM users');
    const busesResult = await db.query('SELECT * FROM buses');
    const employeesResult = await db.query('SELECT * FROM employees');
    const reservationsResult = await db.query('SELECT * FROM reservations');
    const paymentsResult = await db.query('SELECT * FROM payments');
    
    res.json({
      success: true,
      timestamp: new Date().toISOString(),
      database: {
        users: {
          count: usersResult.rowCount,
          data: usersResult.rows.map(user => ({
            id: user.id,
            email: user.email,
            name: user.name,
            role: user.role,
            wallet_balance: user.wallet_balance,
            created_at: user.created_at
            // Note: password is excluded for security
          }))
        },
        buses: {
          count: busesResult.rowCount,
          data: busesResult.rows
        },
        employees: {
          count: employeesResult.rowCount,
          data: employeesResult.rows
        },
        reservations: {
          count: reservationsResult.rowCount,
          data: reservationsResult.rows
        },
        payments: {
          count: paymentsResult.rowCount,
          data: paymentsResult.rows
        }
      },
      summary: {
        total_users: usersResult.rowCount,
        total_buses: busesResult.rowCount,
        total_employees: employeesResult.rowCount,
        total_reservations: reservationsResult.rowCount,
        total_payments: paymentsResult.rowCount
      }
    });
  } catch (error) {
    console.error('Database debug error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Debug endpoint to test database connectivity
router.get('/database-test', async (req, res) => {
  try {
    const result = await db.query('SELECT NOW() as current_time');
    res.json({
      success: true,
      message: 'Database connection successful',
      current_time: result.rows[0].current_time
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Advanced database query endpoint
router.get('/query', async (req, res) => {
  const { table, limit = 10, offset = 0, search, sort } = req.query;
  
  try {
    let query = '';
    let params = [];
    
    switch(table) {
      case 'users':
        query = 'SELECT * FROM users';
        if (search) {
          query += ' WHERE email ILIKE $1 OR name ILIKE $1';
          params.push(`%${search}%`);
        }
        break;
      case 'buses':
        query = 'SELECT * FROM buses';
        if (search) {
          query += ' WHERE bus_number ILIKE $1 OR route ILIKE $1';
          params.push(`%${search}%`);
        }
        break;
      case 'reservations':
        query = `SELECT r.*, u.name as user_name, u.email as user_email, b.bus_number 
                 FROM reservations r 
                 LEFT JOIN users u ON r.user_id = u.id 
                 LEFT JOIN buses b ON r.bus_id = b.id`;
        if (search) {
          query += ' WHERE u.name ILIKE $1 OR u.email ILIKE $1 OR b.bus_number ILIKE $1';
          params.push(`%${search}%`);
        }
        break;
      case 'payments':
        query = `SELECT p.*, u.name as user_name, u.email as user_email, r.seat_number
                 FROM payments p
                 LEFT JOIN users u ON p.user_id = u.id
                 LEFT JOIN reservations r ON p.reservation_id = r.id`;
        if (search) {
          query += ' WHERE u.name ILIKE $1 OR u.email ILIKE $1';
          params.push(`%${search}%`);
        }
        break;
      default:
        return res.status(400).json({ error: 'Invalid table name' });
    }
    
    // Add sorting
    if (sort) {
      query += ` ORDER BY ${sort}`;
    } else {
      query += ' ORDER BY id DESC';
    }
    
    // Add pagination
    query += ` LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(parseInt(limit), parseInt(offset));
    
    const result = await db.query(query, params);
    
    res.json({
      success: true,
      table: table,
      data: result.rows,
      count: result.rowCount,
      limit: parseInt(limit),
      offset: parseInt(offset)
    });
  } catch (error) {
    console.error('Database query error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Database statistics endpoint
router.get('/statistics', async (req, res) => {
  try {
    // Get various statistics
    const stats = {};
    
    // User statistics
    const userStats = await db.query(`
      SELECT 
        COUNT(*) as total_users,
        COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_count,
        COUNT(CASE WHEN role = 'user' THEN 1 END) as regular_users,
        AVG(wallet_balance::numeric) as avg_wallet_balance
      FROM users
    `);
    stats.users = userStats.rows[0];
    
    // Bus statistics
    const busStats = await db.query(`
      SELECT 
        COUNT(*) as total_buses,
        SUM(total_seats) as total_capacity,
        SUM(available_seats) as total_available_seats,
        AVG(price::numeric) as avg_ticket_price
      FROM buses
    `);
    stats.buses = busStats.rows[0];
    
    // Reservation statistics
    const reservationStats = await db.query(`
      SELECT 
        COUNT(*) as total_reservations,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_reservations,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_reservations,
        COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_reservations
      FROM reservations
    `);
    stats.reservations = reservationStats.rows[0];
    
    // Payment statistics
    const paymentStats = await db.query(`
      SELECT 
        COUNT(*) as total_payments,
        COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_payments,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_payments,
        SUM(amount::numeric) as total_revenue,
        AVG(amount::numeric) as avg_payment_amount
      FROM payments
    `);
    stats.payments = paymentStats.rows[0];
    
    res.json({
      success: true,
      statistics: stats,
      generated_at: new Date().toISOString()
    });
  } catch (error) {
    console.error('Statistics error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

module.exports = router;