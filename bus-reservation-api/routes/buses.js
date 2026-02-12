const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// GET tous les bus (public)
router.get('/', async (req, res) => {
  try {
    const result = await db.query(`
      SELECT * FROM buses 
      WHERE departure_time > NOW() 
      ORDER BY departure_time ASC
    `);
    res.json({ buses: result.rows });
  } catch (error) {
    console.error('Error fetching buses:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des bus' });
  }
});

// GET un bus spécifique
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await db.query('SELECT * FROM buses WHERE id = $1', [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Bus non trouvé' });
    }

    res.json({ bus: result.rows[0] });
  } catch (error) {
    console.error('Error fetching bus:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération du bus' });
  }
});

// POST créer un nouveau bus (Admin uniquement)
router.post('/', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { bus_number, route, departure_time, arrival_time, total_seats, price } = req.body;

    // Validation
    if (!bus_number || !route || !departure_time || !arrival_time || !total_seats || !price) {
      return res.status(400).json({ error: 'Tous les champs sont requis' });
    }

    const result = await db.query(`
      INSERT INTO buses (bus_number, route, departure_time, arrival_time, total_seats, available_seats, price)
      VALUES ($1, $2, $3, $4, $5, $5, $6)
      RETURNING *
    `, [bus_number, route, departure_time, arrival_time, total_seats, price]);

    res.status(201).json({
      message: 'Bus créé avec succès',
      bus: result.rows[0]
    });
  } catch (error) {
    console.error('Error creating bus:', error);
    if (error.code === '23505') { // Duplicate key
      return res.status(400).json({ error: 'Ce numéro de bus existe déjà' });
    }
    res.status(500).json({ error: 'Erreur lors de la création du bus' });
  }
});

// PUT mettre à jour un bus (Admin uniquement)
router.put('/:id', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { bus_number, route, departure_time, arrival_time, total_seats, available_seats, price } = req.body;

    const result = await db.query(`
      UPDATE buses 
      SET bus_number = COALESCE($1, bus_number),
          route = COALESCE($2, route),
          departure_time = COALESCE($3, departure_time),
          arrival_time = COALESCE($4, arrival_time),
          total_seats = COALESCE($5, total_seats),
          available_seats = COALESCE($6, available_seats),
          price = COALESCE($7, price)
      WHERE id = $8
      RETURNING *
    `, [bus_number, route, departure_time, arrival_time, total_seats, available_seats, price, id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Bus non trouvé' });
    }

    res.json({
      message: 'Bus mis à jour avec succès',
      bus: result.rows[0]
    });
  } catch (error) {
    console.error('Error updating bus:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour du bus' });
  }
});

// DELETE supprimer un bus (Admin uniquement)
router.delete('/:id', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const result = await db.query('DELETE FROM buses WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Bus non trouvé' });
    }

    res.json({ message: 'Bus supprimé avec succès' });
  } catch (error) {
    console.error('Error deleting bus:', error);
    res.status(500).json({ error: 'Erreur lors de la suppression du bus' });
  }
});

module.exports = router;
