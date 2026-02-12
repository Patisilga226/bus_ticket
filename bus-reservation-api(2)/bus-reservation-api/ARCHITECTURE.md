# 🏗️ Architecture de l'API

## Vue d'ensemble

Cette API suit une architecture **MVC simplifiée** adaptée pour un prototype fonctionnel.

```
┌─────────────────────────────────────────────────────────┐
│                    CLIENT (Postman/Frontend)            │
└────────────────────────┬────────────────────────────────┘
                         │ HTTP/JSON
                         ▼
┌─────────────────────────────────────────────────────────┐
│                    EXPRESS SERVER                        │
│  ┌──────────────────────────────────────────────────┐  │
│  │              Middleware Layer                    │  │
│  │  • CORS                                          │  │
│  │  • JSON Parser                                   │  │
│  │  • JWT Authentication                            │  │
│  │  • Role-based Authorization                      │  │
│  └──────────────────────────────────────────────────┘  │
│                         │                                │
│  ┌──────────────────────────────────────────────────┐  │
│  │              Routes Layer                        │  │
│  │  • /api/auth        (Public)                     │  │
│  │  • /api/buses       (Public + Admin)             │  │
│  │  • /api/users       (Protected)                  │  │
│  │  • /api/employees   (Admin)                      │  │
│  │  • /api/reservations (Protected)                 │  │
│  │  • /api/scan-qr     (Employee)                   │  │
│  │  • /api/payments    (Protected)                  │  │
│  └──────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────┘
                         │ SQL Queries
                         ▼
┌─────────────────────────────────────────────────────────┐
│              NEON POSTGRESQL DATABASE                    │
│  ┌──────────┬──────────┬──────────┬──────────────────┐ │
│  │  users   │  buses   │employees │  reservations    │ │
│  └──────────┴──────────┴──────────┴──────────────────┘ │
│  ┌──────────┐                                          │ │
│  │ payments │                                          │ │
│  └──────────┘                                          │ │
└─────────────────────────────────────────────────────────┘
```

## 🔐 Flux d'authentification

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       │ POST /api/auth/login
       │ { email, password }
       ▼
┌─────────────────────────────┐
│   Auth Route Handler        │
│  1. Valider les données     │
│  2. Chercher l'utilisateur  │
│  3. Vérifier le password    │
│  4. Générer JWT token       │
└──────┬──────────────────────┘
       │
       │ { token, user }
       ▼
┌─────────────┐
│   Client    │
│ Stocke token│
└─────────────┘

Requêtes suivantes :
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       │ GET /api/reservations
       │ Header: Authorization: Bearer <token>
       ▼
┌─────────────────────────────┐
│ authenticateToken Middleware│
│  1. Extraire le token       │
│  2. Vérifier signature JWT  │
│  3. Décoder payload         │
│  4. Attacher user à req     │
└──────┬──────────────────────┘
       │
       │ req.user = { id, email, role }
       ▼
┌─────────────────────────────┐
│   Reservation Route Handler │
│  Accès aux données user     │
└─────────────────────────────┘
```

## 🎫 Flux de réservation

```
┌──────────────────────────────────────────────────────────┐
│                  CRÉATION DE RÉSERVATION                  │
└──────────────────────────────────────────────────────────┘

1. Utilisateur fait une requête
   ↓
   POST /api/reservations
   { bus_id: 1, seat_number: 15 }

2. Validation
   ├─ Bus existe ?
   ├─ Places disponibles ?
   ├─ Siège libre ?
   └─ Bus pas encore parti ?

3. Transaction DB (BEGIN)
   ├─ Créer la réservation
   │  • Générer QR code unique
   │  • Calculer qr_valid_until (départ - 1h)
   │  • Status: pending
   │
   ├─ Créer le paiement
   │  • Amount: prix_ticket + 100 FCFA
   │  • Type: payment
   │  • Status: completed
   │
   └─ Décrémenter available_seats
      UPDATE buses SET available_seats = available_seats - 1

4. COMMIT Transaction

5. Retour à l'utilisateur
   {
     reservation: {...},
     qr_code: "data:image/png;base64,...",
     total_amount: 2600,
     qr_valid_until: "2026-02-15T07:00:00Z"
   }
```

## 📱 Flux de scan QR

```
┌──────────────────────────────────────────────────────────┐
│                     SCAN QR CODE                          │
└──────────────────────────────────────────────────────────┘

1. Employé scanne le QR
   ↓
   POST /api/scan-qr
   { qr_code: "data:image/png;base64,..." }

2. Validation
   ├─ QR code existe ?
   ├─ Réservation pas déjà scannée ?
   └─ Réservation pas annulée ?

3. Calcul du timing
   NOW = Date actuelle
   QR_VALID_UNTIL = Réservation.qr_valid_until
   DEPARTURE_TIME = Bus.departure_time

   ┌─────────────────────────────────────────────────┐
   │                                                 │
   │    ◄─── À l'heure ───►│◄── En retard ──►│      │
   │                        │                 │      │
   │                   QR_VALID_UNTIL    DEPARTURE   │
   │                                                 │
   └─────────────────────────────────────────────────┘

4. Logique de remboursement

   IF NOW <= QR_VALID_UNTIL:
      ✅ Passager à l'heure
      • Rembourser: 100 FCFA (caution)
      • Message: "Caution remboursée"

   ELSE IF NOW > QR_VALID_UNTIL AND NOW < DEPARTURE_TIME:
      ⚠️ Passager en retard
      • Rembourser: 2500 FCFA (prix ticket)
      • Dédommagement: 100 FCFA (retenu)
      • Message: "Prix du ticket remboursé, dédommagement retenu"

   ELSE:
      ❌ Bus déjà parti
      • Erreur: "QR code expiré"

5. Transaction DB (BEGIN)
   ├─ UPDATE reservations SET status = 'scanned'
   │
   ├─ CREATE payment (type: refund)
   │  INSERT INTO payments (type='refund', amount=refund_amount)
   │
   ├─ CREATE payment (type: compensation) si applicable
   │  INSERT INTO payments (type='compensation', amount=100)
   │
   └─ UPDATE users SET wallet_balance += refund_amount

6. COMMIT Transaction

7. Retour à l'employé
   {
     success: true,
     message: "...",
     scan_details: {
       is_on_time: true/false,
       refund_amount: ...,
       compensation_amount: ...
     }
   }
```

## 🔒 Sécurité et permissions

### Matrice de permissions

| Route                  | Public | User | Employee | Admin |
|------------------------|--------|------|----------|-------|
| POST /auth/register    | ✅     | ✅   | ✅       | ✅    |
| POST /auth/login       | ✅     | ✅   | ✅       | ✅    |
| GET /buses             | ✅     | ✅   | ✅       | ✅    |
| POST /buses            | ❌     | ❌   | ❌       | ✅    |
| PUT /buses/:id         | ❌     | ❌   | ❌       | ✅    |
| DELETE /buses/:id      | ❌     | ❌   | ❌       | ✅    |
| GET /users             | ❌     | ❌   | ❌       | ✅    |
| GET /users/:id         | ❌     | 👤   | ❌       | ✅    |
| PUT /users/:id         | ❌     | 👤   | ❌       | ✅    |
| DELETE /users/:id      | ❌     | ❌   | ❌       | ✅    |
| POST /employees        | ❌     | ❌   | ❌       | ✅    |
| DELETE /employees/:id  | ❌     | ❌   | ❌       | ✅    |
| POST /reservations     | ❌     | ✅   | ✅       | ✅    |
| GET /reservations      | ❌     | 👤   | ❌       | ✅    |
| DELETE /reservations/:id| ❌    | 👤   | ❌       | ✅    |
| POST /scan-qr          | ❌     | ❌   | ✅       | ✅    |
| GET /payments          | ❌     | 👤   | ❌       | ✅    |
| GET /payments/stats    | ❌     | ❌   | ❌       | ✅    |

Légende:
- ✅ = Accès complet
- ❌ = Pas d'accès
- 👤 = Accès uniquement à ses propres données

## 💾 Modèle de données

### Relations entre tables

```
users (1) ──────────────────> (N) reservations
  │                               │
  │                               │
  │                               ▼
  │                           (1) buses
  │
  ├──> (N) payments
  │
  └──> (N) employees
            │
            └──> (1) buses
```

### Détails des contraintes

1. **users.email** : UNIQUE
2. **buses.bus_number** : UNIQUE
3. **reservations.qr_code** : UNIQUE
4. **employees** : UNIQUE(user_id, bus_id) - Un employé ne peut être assigné qu'une fois au même bus

### Index recommandés (pour optimisation future)

```sql
-- Index sur les colonnes fréquemment recherchées
CREATE INDEX idx_reservations_user_id ON reservations(user_id);
CREATE INDEX idx_reservations_bus_id ON reservations(bus_id);
CREATE INDEX idx_reservations_qr_code ON reservations(qr_code);
CREATE INDEX idx_payments_user_id ON payments(user_id);
CREATE INDEX idx_payments_reservation_id ON payments(reservation_id);
CREATE INDEX idx_buses_departure_time ON buses(departure_time);
```

## 🔄 Gestion des transactions

Les opérations critiques utilisent des transactions PostgreSQL :

### Exemple : Création de réservation

```javascript
const client = await db.pool.connect();
try {
  await client.query('BEGIN');
  
  // Opération 1 : Créer réservation
  const reservation = await client.query('INSERT INTO...');
  
  // Opération 2 : Créer paiement
  const payment = await client.query('INSERT INTO...');
  
  // Opération 3 : Mettre à jour places disponibles
  await client.query('UPDATE buses SET...');
  
  await client.query('COMMIT');
} catch (error) {
  await client.query('ROLLBACK');
  throw error;
} finally {
  client.release();
}
```

Avantages :
- **Atomicité** : Tout ou rien
- **Cohérence** : Les données restent valides
- **Isolation** : Pas d'interférences entre transactions
- **Durabilité** : Les changements sont permanents

## 🚀 Scalabilité future

### Options d'amélioration

1. **Caching** (Redis)
   - Cache des bus disponibles
   - Sessions utilisateur
   - QR codes générés

2. **Queue de traitement** (Bull/RabbitMQ)
   - Génération asynchrone de QR codes
   - Envoi de notifications
   - Traitements de paiements

3. **Microservices**
   - Service Auth
   - Service Reservations
   - Service Payments
   - Service Notifications

4. **Database Sharding**
   - Partition par région géographique
   - Partition par date

## 📊 Monitoring (à venir)

Points à monitorer :
- Temps de réponse API
- Taux d'erreur
- Utilisation de la base de données
- Nombre de réservations/heure
- Taux de scan QR

Outils recommandés :
- **APM** : New Relic, Datadog
- **Logs** : Winston + Logtail
- **Metrics** : Prometheus + Grafana

---

**Cette architecture est conçue pour être simple, fonctionnelle et évolutive.**
