const express = require('express');
const router = express.Router();
const db = require('../config/database');
const bcrypt = require('bcryptjs');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// GET tous les employés (Admin uniquement)
router.get('/', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const result = await db.query(`
      SELECT e.id, e.user_id, e.bus_id, e.assigned_at,
             u.name as employee_name, u.email as employee_email,
             b.bus_number, b.route
      FROM employees e
      JOIN users u ON e.user_id = u.id
      LEFT JOIN buses b ON e.bus_id = b.id
      ORDER BY e.assigned_at DESC
    `);
    res.json({ employees: result.rows });
  } catch (error) {
    console.error('Error fetching employees:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des employés' });
  }
});

// POST créer/assigner un employé (Admin uniquement)
router.post('/', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { user_id, bus_id, employee_name, employee_email } = req.body;
    let employeeUserId = user_id ? parseInt(user_id, 10) : null;
    let employeeName = employee_name || null;
    let employeeEmail = employee_email || null;

    // Si user_id n'est pas fourni: créer/trouver via email
    if (!employeeUserId) {
      if (!employeeName || !employeeEmail) {
        return res.status(400).json({ error: 'user_id ou (employee_name + employee_email) requis' });
      }

      const existingUserResult = await db.query('SELECT * FROM users WHERE email = $1', [employeeEmail]);
      if (existingUserResult.rows.length > 0) {
        const existingUser = existingUserResult.rows[0];
        if (existingUser.role !== 'employee') {
          return res.status(400).json({ error: 'Cet email existe déjà avec un rôle non employé' });
        }
        employeeUserId = existingUser.id;
        employeeName = existingUser.name;
      } else {
        const generatedPassword = Math.random().toString(36).slice(2) + Date.now().toString(36);
        const hashedPassword = await bcrypt.hash(generatedPassword, 10);
        const createdUserResult = await db.query(
          `INSERT INTO users (email, password, name, role)
           VALUES ($1, $2, $3, 'employee')
           RETURNING id, name, email`,
          [employeeEmail, hashedPassword, employeeName]
        );
        employeeUserId = createdUserResult.rows[0].id;
      }
    } else {
      // user_id fourni: valider rôle employé
      const userResult = await db.query('SELECT * FROM users WHERE id = $1', [employeeUserId]);
      if (userResult.rows.length === 0) {
        return res.status(404).json({ error: 'Utilisateur non trouvé' });
      }

      const user = userResult.rows[0];
      if (user.role !== 'employee') {
        return res.status(400).json({ error: 'Cet utilisateur n\'est pas un employé' });
      }
      employeeName = user.name;
      employeeEmail = user.email;
    }

    // bus_id requis: on veut toujours une route non nulle
    if (bus_id === null || bus_id === undefined || bus_id === '') {
      return res.status(400).json({ error: 'bus_id requis' });
    }
    const parsedBusId = parseInt(bus_id, 10);
    if (Number.isNaN(parsedBusId)) {
      return res.status(400).json({ error: 'bus_id invalide' });
    }
    const busResult = await db.query('SELECT * FROM buses WHERE id = $1', [parsedBusId]);
    if (busResult.rows.length === 0) {
      return res.status(404).json({ error: 'Bus non trouvé' });
    }

    // Créer l'assignation
    const result = await db.query(
      'INSERT INTO employees (user_id, bus_id) VALUES ($1, $2) RETURNING *',
      [employeeUserId, parsedBusId]
    );

    const joined = await db.query(`
      SELECT e.id, e.user_id, e.bus_id, e.assigned_at,
             u.name as employee_name, u.email as employee_email,
             b.bus_number, b.route
      FROM employees e
      JOIN users u ON e.user_id = u.id
      LEFT JOIN buses b ON e.bus_id = b.id
      WHERE e.id = $1
    `, [result.rows[0].id]);

    const employee = joined.rows[0] || {
      ...result.rows[0],
      employee_name: employeeName,
      employee_email: employeeEmail,
      bus_number: null,
      route: null,
    };

    res.status(201).json({
      message: 'Chauffeur créé/assigné avec succès',
      employee,
      assignment: result.rows[0],
    });
  } catch (error) {
    console.error('Error assigning employee:', error);
    if (error.code === '23505') {
      return res.status(400).json({ error: 'Cet employé est déjà assigné à ce bus' });
    }
    res.status(500).json({ error: 'Erreur lors de l\'assignation de l\'employé' });
  }
});

// DELETE supprimer une assignation (Admin uniquement)
router.delete('/:id', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const result = await db.query('DELETE FROM employees WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Assignation non trouvée' });
    }

    res.json({ message: 'Assignation supprimée avec succès' });
  } catch (error) {
    console.error('Error deleting assignment:', error);
    res.status(500).json({ error: 'Erreur lors de la suppression de l\'assignation' });
  }
});

module.exports = router;
