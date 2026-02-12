const express = require('express');
const cors = require('cors');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, 'public')));

// Routes
const authRoutes = require('./routes/auth');
const userRoutes = require('./routes/users');
const busRoutes = require('./routes/buses');
const employeeRoutes = require('./routes/employees');
const reservationRoutes = require('./routes/reservations');
const scanQrRoutes = require('./routes/scan-qr');
const paymentRoutes = require('./routes/payments');
const debugRoutes = require('./routes/debug');

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/buses', busRoutes);
app.use('/api/employees', employeeRoutes);
app.use('/api/reservations', reservationRoutes);
app.use('/api/scan-qr', scanQrRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/debug', debugRoutes);

// Route de base
app.get('/', (req, res) => {
  res.json({
    message: '🚌 API de Réservation de Bus',
    version: '1.0.0',
    endpoints: {
      auth: '/api/auth (register, login)',
      users: '/api/users',
      buses: '/api/buses',
      employees: '/api/employees',
      reservations: '/api/reservations',
      scanQr: '/api/scan-qr',
      payments: '/api/payments'
    },
    documentation: 'Voir README.md pour les détails'
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route non trouvée' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({ 
    error: 'Erreur serveur interne',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Démarrer le serveur
app.listen(PORT, () => {
  console.log(`
╔═══════════════════════════════════════════════╗
║   🚌 API de Réservation de Bus                ║
║   Port: ${PORT}                                  ║
║   Environment: ${process.env.NODE_ENV || 'development'}              ║
║   Base URL: http://localhost:${PORT}            ║
╚═══════════════════════════════════════════════╝
  `);
});

module.exports = app;
