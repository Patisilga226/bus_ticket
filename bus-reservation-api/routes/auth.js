const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/database');
const { authenticateToken } = require('../middleware/auth');

// Register - Inscription d'un utilisateur
router.post('/register', async (req, res) => {
  try {
    const { email, password, name, phone, role = 'user' } = req.body;

    // Validation basique
    if (!email || !password || !name) {
      return res.status(400).json({ error: 'Email, mot de passe et nom requis' });
    }

    // Verifier si l'email existe deja
    const existingUser = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    if (existingUser.rows.length > 0) {
      return res.status(400).json({ error: 'Cet email est deja utilise' });
    }

    // Hash du mot de passe
    const hashedPassword = await bcrypt.hash(password, 10);

    // Creer l'utilisateur
    const result = await db.query(
      'INSERT INTO users (email, password, name, phone, role) VALUES ($1, $2, $3, $4, $5) RETURNING id, email, name, role, created_at',
      [email, hashedPassword, name, phone, role === 'admin' || role === 'employee' ? role : 'user']
    );

    return res.status(201).json({
      message: 'Utilisateur cree avec succes',
      user: result.rows[0]
    });
  } catch (error) {
    console.error('Error in register:', error);
    return res.status(500).json({ error: 'Erreur lors de l\'inscription' });
  }
});

// Login - Connexion email + mot de passe
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email et mot de passe requis' });
    }

    const result = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    const user = result.rows[0];

    if (!user) {
      return res.status(401).json({ error: 'Email ou mot de passe incorrect' });
    }

    const validPassword = await bcrypt.compare(password, user.password);
    if (!validPassword) {
      return res.status(401).json({ error: 'Email ou mot de passe incorrect' });
    }

    const token = jwt.sign(
      {
        id: user.id,
        email: user.email,
        role: user.role
      },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    return res.json({
      message: 'Connexion reussie',
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        role: user.role,
        wallet_balance: user.wallet_balance,
        created_at: user.created_at
      }
    });
  } catch (error) {
    console.error('Error in login:', error);
    return res.status(500).json({ error: 'Erreur lors de la connexion' });
  }
});

// Login employe - Connexion par employee_id + bus_id
router.post('/employee-login', async (req, res) => {
  try {
    const { employee_id, bus_id } = req.body;

    if (!employee_id || !bus_id) {
      return res.status(400).json({ error: 'employee_id et bus_id requis' });
    }

    const assignmentResult = await db.query(
      `
      SELECT 
        e.id AS assignment_id,
        e.user_id AS user_id,
        e.bus_id AS bus_id,
        e.assigned_at,
        u.id AS uid,
        u.email,
        u.name,
        u.phone,
        u.role,
        u.wallet_balance,
        u.created_at,
        b.bus_number,
        b.route
      FROM employees e
      JOIN users u ON e.user_id = u.id
      JOIN buses b ON e.bus_id = b.id
      -- Accept either the employee assignment id (e.id) or the user id (u.id)
      WHERE (e.id = $1 OR e.user_id = $1) AND e.bus_id = $2
      LIMIT 1
      `,
      [employee_id, bus_id]
    );

    if (assignmentResult.rows.length === 0) {
      return res.status(401).json({ error: 'employee_id ou bus_id invalide' });
    }

    const employee = assignmentResult.rows[0];
    // role comes from users table (u.role)
    if (employee.role !== 'employee') {
      return res.status(403).json({ error: 'Ce compte n\'est pas un employe' });
    }

    const token = jwt.sign(
      {
        // Use the user id for the token `id` claim
        id: employee.user_id || employee.uid,
        email: employee.email,
        role: employee.role,
        bus_id: employee.bus_id,
        employee_assignment_id: employee.assignment_id
      },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    return res.json({
      message: 'Connexion employe reussie',
      token,
      user: {
        id: employee.user_id || employee.uid,
        email: employee.email,
        name: employee.name,
        phone: employee.phone,
        role: employee.role,
        wallet_balance: employee.wallet_balance,
        created_at: employee.created_at
      },
      employee_assignment: {
        id: employee.assignment_id,
        bus_id: employee.bus_id,
        bus_number: employee.bus_number,
        route: employee.route,
        assigned_at: employee.assigned_at
      }
    });
  } catch (error) {
    console.error('Error in employee-login:', error);
    return res.status(500).json({ error: 'Erreur lors de la connexion employe' });
  }
});

// GET profil connecte (validation du token)
router.get('/me', authenticateToken, async (req, res) => {
  try {
    const result = await db.query(
      'SELECT id, email, name, phone, role, wallet_balance, created_at FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Utilisateur non trouve' });
    }

    return res.json({
      authenticated: true,
      user: result.rows[0]
    });
  } catch (error) {
    console.error('Error in me:', error);
    return res.status(500).json({ error: 'Erreur lors de la recuperation du profil' });
  }
});

module.exports = router;
