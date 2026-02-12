const express = require('express');
const router = express.Router();
const db = require('../config/database');
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

// POST assigner un employé à un bus (Admin uniquement)
router.post('/', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { user_id, bus_id } = req.body;

    if (!user_id || !bus_id) {
      return res.status(400).json({ error: 'user_id et bus_id requis' });
    }

    // Vérifier que l'utilisateur existe et est un employé
    const userResult = await db.query('SELECT * FROM users WHERE id = $1', [user_id]);
    if (userResult.rows.length === 0) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    const user = userResult.rows[0];
    if (user.role !== 'employee') {
      return res.status(400).json({ error: 'Cet utilisateur n\'est pas un employé' });
    }

    // Vérifier que le bus existe
    const busResult = await db.query('SELECT * FROM buses WHERE id = $1', [bus_id]);
    if (busResult.rows.length === 0) {
      return res.status(404).json({ error: 'Bus non trouvé' });
    }

    // Créer l'assignation
    const result = await db.query(
      'INSERT INTO employees (user_id, bus_id) VALUES ($1, $2) RETURNING *',
      [user_id, bus_id]
    );

    res.status(201).json({
      message: 'Employé assigné au bus avec succès',
      assignment: result.rows[0]
    });
  } catch (error) {
    console.error('Error assigning employee:', error);
    if (error.code === '23505') { // Duplicate key
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
