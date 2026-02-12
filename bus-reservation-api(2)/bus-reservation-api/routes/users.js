const express = require('express');
const router = express.Router();
const db = require('../config/database');
const { authenticateToken, requireAdmin } = require('../middleware/auth');

// GET tous les utilisateurs (Admin uniquement)
router.get('/', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const result = await db.query(`
      SELECT id, email, name, phone, role, wallet_balance, created_at 
      FROM users 
      ORDER BY created_at DESC
    `);
    res.json({ users: result.rows });
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération des utilisateurs' });
  }
});

// GET un utilisateur spécifique
router.get('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;

    // Vérifier les permissions (seulement l'utilisateur lui-même ou admin)
    if (req.user.role !== 'admin' && req.user.id !== parseInt(id)) {
      return res.status(403).json({ error: 'Accès non autorisé' });
    }

    const result = await db.query(
      'SELECT id, email, name, phone, role, wallet_balance, created_at FROM users WHERE id = $1',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    res.json({ user: result.rows[0] });
  } catch (error) {
    console.error('Error fetching user:', error);
    res.status(500).json({ error: 'Erreur lors de la récupération de l\'utilisateur' });
  }
});

// PUT mettre à jour un utilisateur
router.put('/:id', authenticateToken, async (req, res) => {
  try {
    const { id } = req.params;
    const { name, phone, wallet_balance } = req.body;

    // Vérifier les permissions
    if (req.user.role !== 'admin' && req.user.id !== parseInt(id)) {
      return res.status(403).json({ error: 'Accès non autorisé' });
    }

    // Seul l'admin peut modifier le wallet_balance
    let query, params;
    if (req.user.role === 'admin') {
      query = `
        UPDATE users 
        SET name = COALESCE($1, name),
            phone = COALESCE($2, phone),
            wallet_balance = COALESCE($3, wallet_balance)
        WHERE id = $4
        RETURNING id, email, name, phone, role, wallet_balance, created_at
      `;
      params = [name, phone, wallet_balance, id];
    } else {
      query = `
        UPDATE users 
        SET name = COALESCE($1, name),
            phone = COALESCE($2, phone)
        WHERE id = $3
        RETURNING id, email, name, phone, role, wallet_balance, created_at
      `;
      params = [name, phone, id];
    }

    const result = await db.query(query, params);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    res.json({
      message: 'Utilisateur mis à jour avec succès',
      user: result.rows[0]
    });
  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ error: 'Erreur lors de la mise à jour de l\'utilisateur' });
  }
});

// DELETE supprimer un utilisateur (Admin uniquement)
router.delete('/:id', authenticateToken, requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const result = await db.query('DELETE FROM users WHERE id = $1 RETURNING *', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Utilisateur non trouvé' });
    }

    res.json({ message: 'Utilisateur supprimé avec succès' });
  } catch (error) {
    console.error('Error deleting user:', error);
    res.status(500).json({ error: 'Erreur lors de la suppression de l\'utilisateur' });
  }
});

module.exports = router;
