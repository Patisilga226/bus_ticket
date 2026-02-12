# 🚀 Guide de Démarrage Rapide

## Configuration en 5 minutes

### 1️⃣ Créer la base de données Neon

1. Aller sur https://neon.tech
2. Créer un compte gratuit
3. Créer un nouveau projet
4. Copier la connection string (ressemble à : `postgresql://user:pass@host.neon.tech/dbname`)

### 2️⃣ Installation

```bash
# Installer les dépendances
npm install

# Créer le fichier .env
cp .env.example .env
```

### 3️⃣ Configurer .env

Éditer le fichier `.env` :

```env
DATABASE_URL=votre_connection_string_neon
JWT_SECRET=mon_secret_super_securise_123
PORT=3000
NODE_ENV=development
TICKET_DEPOSIT=100
```

### 4️⃣ Initialiser la base de données

```bash
npm run setup-db
```

✅ **Admin créé** : `admin@busapp.com` / `admin123`

### 5️⃣ Démarrer le serveur

```bash
npm run dev
```

Le serveur démarre sur **http://localhost:3000**

---

## 🧪 Tester l'API rapidement

### Option 1 : cURL

```bash
# 1. Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@busapp.com","password":"admin123"}'

# Copier le token retourné

# 2. Créer un bus
curl -X POST http://localhost:3000/api/buses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer VOTRE_TOKEN" \
  -d '{
    "bus_number": "BUS-001",
    "route": "Ouagadougou - Bobo-Dioulasso",
    "departure_time": "2026-02-15T08:00:00Z",
    "arrival_time": "2026-02-15T12:00:00Z",
    "total_seats": 50,
    "price": 2500
  }'

# 3. Créer un utilisateur
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@test.com",
    "password": "password123",
    "name": "Test User",
    "phone": "+226 70123456"
  }'

# 4. Login utilisateur et créer réservation
# ... (voir README.md pour plus d'exemples)
```

### Option 2 : Postman

1. Importer `postman-collection.json`
2. Configurer l'environnement avec `base_url = http://localhost:3000`
3. Exécuter les requêtes dans l'ordre

---

## 📋 Workflow complet de test

### Scénario : Réservation et scan

```
1. Admin crée un bus
   ↓
2. Utilisateur s'inscrit
   ↓
3. Utilisateur réserve une place
   ↓
4. Utilisateur reçoit un QR code
   ↓
5. Employé scanne le QR code
   ↓
6. Système calcule le remboursement selon l'heure
```

### Commandes rapides

```bash
# Créer un employé (en tant qu'admin)
POST /api/auth/register
{
  "email": "employee@busapp.com",
  "password": "employee123",
  "name": "Employé Test",
  "role": "employee"
}

# Assigner l'employé au bus
POST /api/employees
{
  "user_id": 2,  # ID de l'employé créé
  "bus_id": 1    # ID du bus
}
```

---

## 🐛 Dépannage rapide

### Erreur de connexion à la base de données
- Vérifier que `DATABASE_URL` est correcte dans `.env`
- Vérifier que la base de données Neon est active
- Tester la connexion : `psql DATABASE_URL`

### Token invalide
- Le token expire après 24h
- Se reconnecter avec `/api/auth/login`

### QR code invalide
- Vérifier que la réservation n'est pas déjà scannée
- Vérifier que le bus n'est pas déjà parti

### Port déjà utilisé
```bash
# Changer le port dans .env
PORT=3001
```

---

## 📊 Données de test

### Créer des données de test automatiquement

Créer un fichier `scripts/seed-data.js` :

```javascript
const db = require('../config/database');

const seedData = async () => {
  // Créer plusieurs bus
  const buses = [
    { bus_number: 'BUS-001', route: 'Ouaga - Bobo', departure: '2026-02-15T08:00:00Z', arrival: '2026-02-15T12:00:00Z', seats: 50, price: 2500 },
    { bus_number: 'BUS-002', route: 'Ouaga - Koudougou', departure: '2026-02-15T10:00:00Z', arrival: '2026-02-15T13:00:00Z', seats: 40, price: 1500 },
    { bus_number: 'BUS-003', route: 'Bobo - Banfora', departure: '2026-02-15T14:00:00Z', arrival: '2026-02-15T17:00:00Z', seats: 35, price: 1800 }
  ];

  for (let bus of buses) {
    await db.query(`
      INSERT INTO buses (bus_number, route, departure_time, arrival_time, total_seats, available_seats, price)
      VALUES ($1, $2, $3, $4, $5, $5, $6)
      ON CONFLICT (bus_number) DO NOTHING
    `, [bus.bus_number, bus.route, bus.departure, bus.arrival, bus.seats, bus.price]);
  }

  console.log('✅ Données de test créées');
  process.exit(0);
};

seedData();
```

Exécuter : `node scripts/seed-data.js`

---

## 🔥 Astuces de développement

### Logs détaillés
```javascript
// Dans server.js, ajouter :
app.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`);
  next();
});
```

### Réinitialiser la base de données
```bash
# Supprimer toutes les tables et recréer
npm run setup-db
```

### Variables d'environnement rapides
```bash
# Lancer avec un port différent sans modifier .env
PORT=4000 npm run dev
```

---

## 🎯 Next Steps

Une fois que tout fonctionne :

1. **Sécurité** : Ajouter rate limiting, validation avancée
2. **Frontend** : Créer une interface React/Vue
3. **Paiements** : Intégrer Orange Money API
4. **Notifications** : Ajouter Twilio pour SMS
5. **Deploy** : Héberger sur Render, Railway ou Heroku

---

**Bon développement ! 🚀**
