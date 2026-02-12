# 🚌 API de Réservation de Tickets de Bus

API REST complète pour la gestion de réservations de bus avec système de QR code, paiements et dashboard admin.

## 📋 Table des matières

- [Fonctionnalités](#fonctionnalités)
- [Technologies](#technologies)
- [Installation](#installation)
- [Configuration](#configuration)
- [Utilisation](#utilisation)
- [API Endpoints](#api-endpoints)
- [Logique métier](#logique-métier)
- [Tests avec Postman](#tests-avec-postman)

## ✨ Fonctionnalités

### Pour les utilisateurs
- ✅ Réserver une place dans un bus
- ✅ Payer le ticket + caution de 100 FCFA
- ✅ Recevoir un QR code valable jusqu'à 1h avant le départ
- ✅ Remboursement automatique selon l'heure d'arrivée

### Pour les employés
- ✅ Scanner les QR codes des passagers
- ✅ Validation automatique avec gestion des remboursements

### Pour les admins
- ✅ Gestion complète des bus (CRUD)
- ✅ Gestion des employés et assignations
- ✅ Suivi des utilisateurs
- ✅ Dashboard des paiements et statistiques

## 🛠️ Technologies

- **Backend**: Node.js + Express
- **Base de données**: PostgreSQL (Neon Cloud)
- **QR Codes**: qrcode library
- **Authentification**: JWT (JSON Web Tokens)
- **Hashing**: bcryptjs

## 📦 Installation

### 1. Cloner le projet

```bash
cd bus-reservation-api
```

### 2. Installer les dépendances

```bash
npm install
```

### 3. Configurer la base de données

Créez un compte sur [Neon](https://neon.tech) et créez une base de données PostgreSQL.

### 4. Configuration de l'environnement

Créez un fichier `.env` à la racine du projet :

```env
DATABASE_URL=postgresql://user:password@host.neon.tech/dbname?sslmode=require
JWT_SECRET=votre_cle_secrete_super_securisee
PORT=3000
NODE_ENV=development
TICKET_DEPOSIT=100
```

### 5. Initialiser la base de données

```bash
npm run setup-db
```

Cela créera toutes les tables nécessaires et un compte admin par défaut :
- **Email**: admin@busapp.com
- **Mot de passe**: admin123

### 6. Démarrer le serveur

```bash
# Mode développement avec auto-reload
npm run dev

# Mode production
npm start
```

Le serveur démarre sur `http://localhost:3000`

## 🗂️ Structure du projet

```
bus-reservation-api/
├── config/
│   └── database.js          # Configuration PostgreSQL
├── middleware/
│   └── auth.js              # Middlewares d'authentification
├── routes/
│   ├── auth.js              # Routes d'authentification
│   ├── users.js             # Gestion des utilisateurs
│   ├── buses.js             # Gestion des bus
│   ├── employees.js         # Gestion des employés
│   ├── reservations.js      # Gestion des réservations
│   ├── scan-qr.js           # Scan des QR codes
│   └── payments.js          # Gestion des paiements
├── scripts/
│   └── setup-database.js    # Script d'initialisation DB
├── .env.example
├── package.json
├── server.js
└── README.md
```

## 📚 API Endpoints

### 🔐 Authentification

#### Inscription
```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "name": "Jean Dupont",
  "phone": "+226 70 12 34 56",
  "role": "user"  // user | employee | admin
}
```

#### Connexion
```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}

Response:
{
  "message": "Connexion réussie",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "name": "Jean Dupont",
    "role": "user",
    "wallet_balance": 0
  }
}
```

### 🚌 Bus

#### Lister tous les bus disponibles (public)
```http
GET /api/buses
```

#### Créer un bus (Admin)
```http
POST /api/buses
Authorization: Bearer {token}
Content-Type: application/json

{
  "bus_number": "BUS-001",
  "route": "Ouagadougou - Bobo-Dioulasso",
  "departure_time": "2026-02-10T08:00:00Z",
  "arrival_time": "2026-02-10T12:00:00Z",
  "total_seats": 50,
  "price": 2500
}
```

#### Modifier un bus (Admin)
```http
PUT /api/buses/:id
Authorization: Bearer {token}
Content-Type: application/json

{
  "price": 3000,
  "available_seats": 45
}
```

#### Supprimer un bus (Admin)
```http
DELETE /api/buses/:id
Authorization: Bearer {token}
```

### 👥 Utilisateurs

#### Lister tous les utilisateurs (Admin)
```http
GET /api/users
Authorization: Bearer {token}
```

#### Voir un utilisateur
```http
GET /api/users/:id
Authorization: Bearer {token}
```

#### Modifier un utilisateur
```http
PUT /api/users/:id
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "Nouveau Nom",
  "phone": "+226 70 00 00 00"
}
```

### 👔 Employés

#### Lister les employés (Admin)
```http
GET /api/employees
Authorization: Bearer {token}
```

#### Assigner un employé à un bus (Admin)
```http
POST /api/employees
Authorization: Bearer {token}
Content-Type: application/json

{
  "user_id": 3,
  "bus_id": 1
}
```

### 🎫 Réservations

#### Créer une réservation
```http
POST /api/reservations
Authorization: Bearer {token}
Content-Type: application/json

{
  "bus_id": 1,
  "seat_number": 15  // Optionnel, auto-assigné si non fourni
}

Response:
{
  "message": "Réservation créée avec succès",
  "reservation": {
    "id": 1,
    "user_id": 2,
    "bus_id": 1,
    "seat_number": 15,
    "status": "pending",
    "departure_time": "2026-02-10T08:00:00Z",
    "qr_valid_until": "2026-02-10T07:00:00Z"
  },
  "payment": {...},
  "qr_code": "data:image/png;base64,iVBORw0KGgo...",
  "total_amount": 2600,
  "qr_valid_until": "2026-02-10T07:00:00Z"
}
```

#### Lister mes réservations
```http
GET /api/reservations
Authorization: Bearer {token}
```

#### Annuler une réservation
```http
DELETE /api/reservations/:id
Authorization: Bearer {token}
```

### 📱 Scan QR Code

#### Scanner un QR code (Employé)
```http
POST /api/scan-qr
Authorization: Bearer {token}
Content-Type: application/json

{
  "qr_code": "data:image/png;base64,iVBORw0KGgo..."
}

Response (À l'heure):
{
  "success": true,
  "message": "Passager à l'heure ! Caution de 100 FCFA remboursée.",
  "scan_details": {
    "reservation_id": 1,
    "user_name": "Jean Dupont",
    "bus_number": "BUS-001",
    "route": "Ouagadougou - Bobo-Dioulasso",
    "seat_number": 15,
    "is_on_time": true,
    "refund_amount": 100,
    "compensation_amount": 0,
    "scanned_at": "2026-02-10T06:30:00Z"
  }
}

Response (En retard):
{
  "success": true,
  "message": "Passager en retard. Prix du ticket (2500 FCFA) remboursé. Dédommagement de 100 FCFA retenu.",
  "scan_details": {
    "is_on_time": false,
    "refund_amount": 2500,
    "compensation_amount": 100,
    ...
  }
}
```

#### Historique des scans (Employé)
```http
GET /api/scan-qr/history
Authorization: Bearer {token}
```

### 💰 Paiements

#### Lister les paiements
```http
GET /api/payments
Authorization: Bearer {token}
```

#### Statistiques des paiements (Admin)
```http
GET /api/payments/stats/summary
Authorization: Bearer {token}

Response:
{
  "revenue": {
    "total": 52000,
    "refunds": 3500,
    "compensation": 200,
    "net": 48500
  },
  "transactions": {
    "total_payments": 20,
    "total_refunds": 3,
    "total_compensations": 2
  }
}
```

## 🔄 Logique métier

### Système de réservation

1. **Création de réservation**
   - Vérification de la disponibilité du bus
   - Attribution automatique ou manuelle du siège
   - Calcul du montant total : Prix du ticket + 100 FCFA (caution)
   - Génération d'un QR code unique
   - Le QR code est valable jusqu'à 1 heure avant le départ

2. **Scan du QR code**
   - **Cas 1 : Passager à l'heure** (avant QR_valid_until)
     - Remboursement de la caution : 100 FCFA
     - Montant retenu : Prix du ticket
   
   - **Cas 2 : Passager en retard** (après QR_valid_until mais avant départ)
     - Remboursement du prix du ticket : 2500 FCFA
     - Dédommagement retenu : 100 FCFA
   
   - **Cas 3 : Après le départ du bus**
     - QR code expiré, aucun remboursement

### Rôles et permissions

- **Admin** : Accès complet (CRUD sur tout)
- **Employee** : Scan de QR codes, voir l'historique
- **User** : Réservations, voir ses propres données

## 🧪 Tests avec Postman

### Collection Postman

1. **Créer une collection** "Bus Reservation API"

2. **Configuration de l'environnement**
   - URL : `http://localhost:3000`
   - Token : `{{token}}`

3. **Workflow de test complet**

```
1. POST /api/auth/login
   → Sauvegarder le token dans l'environnement

2. GET /api/buses
   → Voir les bus disponibles

3. POST /api/buses (Admin)
   → Créer un nouveau bus

4. POST /api/reservations
   → Réserver une place
   → Sauvegarder le qr_code

5. POST /api/scan-qr (Employee)
   → Scanner le QR code sauvegardé

6. GET /api/payments/stats/summary (Admin)
   → Voir les statistiques
```

### Exemple de script Postman pour extraire le token

```javascript
// Dans l'onglet "Tests" de la requête login
pm.test("Login successful", function () {
    var jsonData = pm.response.json();
    pm.environment.set("token", jsonData.token);
});
```

## 📊 Schéma de base de données

```sql
users
├── id (PK)
├── email (unique)
├── password
├── name
├── phone
├── role (admin|employee|user)
├── wallet_balance
└── created_at

buses
├── id (PK)
├── bus_number (unique)
├── route
├── departure_time
├── arrival_time
├── total_seats
├── available_seats
├── price
└── created_at

employees
├── id (PK)
├── user_id (FK → users)
├── bus_id (FK → buses)
└── assigned_at

reservations
├── id (PK)
├── user_id (FK → users)
├── bus_id (FK → buses)
├── seat_number
├── qr_code (unique)
├── status (pending|confirmed|scanned|cancelled)
├── departure_time
├── qr_valid_until
└── created_at

payments
├── id (PK)
├── reservation_id (FK → reservations)
├── user_id (FK → users)
├── amount
├── deposit
├── type (payment|refund|compensation)
├── status (pending|completed|failed)
└── created_at
```

## 🚀 Prochaines étapes (Roadmap)

### Version 1.1 (Améliorations rapides)
- [ ] Intégration Orange Money / Mobile Money
- [ ] Notifications par SMS/Email
- [ ] Export PDF des tickets
- [ ] Recherche avancée de bus

### Version 2.0 (Fonctionnalités avancées)
- [ ] Application mobile (React Native)
- [ ] Dashboard admin avec graphiques
- [ ] Système de fidélité
- [ ] Gestion des sièges en temps réel (WebSocket)

## 🤝 Contribution

1. Fork le projet
2. Créer une branche (`git checkout -b feature/nouvelle-fonctionnalite`)
3. Commit (`git commit -m 'Ajout nouvelle fonctionnalité'`)
4. Push (`git push origin feature/nouvelle-fonctionnalite`)
5. Ouvrir une Pull Request

## 📝 Licence

MIT License - Libre d'utilisation pour prototypes et projets

## 👨‍💻 Support

Pour toute question ou problème :
- Créer une issue sur GitHub
- Email : support@busapp.com

---

**Développé avec ❤️ pour simplifier la réservation de bus en Afrique de l'Ouest**
