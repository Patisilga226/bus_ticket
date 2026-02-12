# 🔧 CORRECTIONS REQUISES AVANT PRODUCTION

Voici les corrections à apporter à l'API pour la rendre prête pour la production.

---

## 1. 🔴 CRITIQUE - Credentials en dur

### Problème
[config/database.js](config/database.js) contient les credentials en clair!

```javascript
// ❌ DANGEREUX - Actuellement dans le code:
const pool = new Pool({
  connectionString: 'postgresql://neondb_owner:npg_gqOjytYG6Wb2@ep-weathered-unit-aiurrskm-pooler.c-4.us-east-1.aws.neon.tech/neondb?sslmode=require',
});
```

### Solution
Créer un fichier `.env` à la racine du projet:

```env
# .env
DATABASE_URL=postgresql://neondb_owner:npg_gqOjytYG6Wb2@ep-weathered-unit-aiurrskm-pooler.c-4.us-east-1.aws.neon.tech/neondb?sslmode=require
JWT_SECRET=votre_cle_secrete_ultra_securisee_min_32_chars
PORT=3000
NODE_ENV=development
TICKET_DEPOSIT=100
```

Modifier [config/database.js](config/database.js):

```javascript
require('dotenv').config();

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false
  }
});
```

### Ajouter au .gitignore

```
.env
.env.local
.env.*.local
node_modules/
```

---

## 2. 🟠 HAUTE - Validation insuffisante

Le package `express-validator` est installé mais pas utilisé. Ajouter la validation stricte.

### Exemple pour auth.js

```javascript
const { body, validationResult } = require('express-validator');

router.post('/register', [
  // Validation
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 8 }),
  body('name').trim().notEmpty(),
  body('phone').optional().isMobilePhone(),
], async (req, res) => {
  // Erreurs de validation
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  
  // Reste du code...
});
```

### Appliquer à chaque route

- ✅ email format valide
- ✅ password min 8 caractères
- ✅ phone format au bon pays
- ✅ seat_number entre 1 et total_seats
- ✅ bus_id existe en DB

---

## 3. 🟠 HAUTE - Pagination

Les endpoints GET retournent TOUS les enregistrements. À corriger:

```javascript
// Avant: retourne TOUT
router.get('/', async (req, res) => {
  const result = await db.query(`
    SELECT * FROM buses ORDER BY departure_time ASC
  `);
  res.json({ buses: result.rows });
});

// Après: pagination
router.get('/', async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 20;
  const offset = (page - 1) * limit;
  
  const result = await db.query(`
    SELECT * FROM buses 
    WHERE departure_time > NOW() 
    ORDER BY departure_time ASC
    LIMIT $1 OFFSET $2
  `, [limit, offset]);
  
  const countResult = await db.query('SELECT COUNT(*) FROM buses');
  
  res.json({
    buses: result.rows,
    pagination: {
      page,
      limit,
      total: parseInt(countResult.rows[0].count),
      pages: Math.ceil(parseInt(countResult.rows[0].count) / limit)
    }
  });
});
```

---

## 4. 🟡 MOYEN - Rate limiting

Ajouter dans server.js:

```javascript
const rateLimit = require('express-rate-limit');

// Limiter 100 requêtes / 15 minutes
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: 'Trop de requêtes, réessayez plus tard'
});

app.use('/api/', limiter);

// Rate limiting strict pour login
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  skipSuccessfulRequests: true
});

app.post('/api/auth/login', loginLimiter, ...);
```

Ajouter au package.json:
```json
"express-rate-limit": "^7.0.0"
```

---

## 5. 🟡 MOYEN - Logging structuré

Remplacer les console.log par un vrai logger:

```bash
npm install winston
```

Créer [config/logger.js](config/logger.js):

```javascript
const winston = require('winston');

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' }),
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

module.exports = logger;
```

Utiliser:
```javascript
const logger = require('../config/logger');

logger.info('Bus créé', { busId: 1 });
logger.error('Erreur DB', { error: err.message });
```

---

## 6. 🟡 MOYEN - Variables d'environnement par défaut

Vérifier que server.js utilise les env vars:

```javascript
require('dotenv').config();

const PORT = process.env.PORT || 3000;
const NODE_ENV = process.env.NODE_ENV || 'development';

if (!process.env.JWT_SECRET) {
  console.error('ERROR: JWT_SECRET not set in .env');
  process.exit(1);
}

if (!process.env.DATABASE_URL) {
  console.error('ERROR: DATABASE_URL not set in .env');
  process.exit(1);
}
```

---

## 7. ✅ BON (mais à améliorer)

### Transaction Error Handling

Ajouter un timeout pour les transactions:

```javascript
const queryTimeout = setTimeout(() => {
  client.query('ROLLBACK');
  clearTimeout(queryTimeout);
}, 30000); // 30 secondes
```

### CORS - Restreindre par domaine

```javascript
const cors = require('cors');

const corsOptions = {
  origin: process.env.ALLOWED_ORIGINS?.split(',') || ['http://localhost:3000'],
  credentials: true,
  optionsSuccessStatus: 200
};

app.use(cors(corsOptions));
```

---

## 8. 📋 CHECKLIST DE DÉPLOIEMENT

- [ ] File `.env` créé avec credentials sécurisés
- [ ] `.env` ajouté au `.gitignore`
- [ ] Validation ajoutée avec `express-validator`
- [ ] Pagination implémentée sur tous les GET
- [ ] Rate limiting configuré
- [ ] Logger structuré en place
- [ ] CORS restreint aux domaines autorisés
- [ ] JWT_SECRET = min 32 caractères aléatoires
- [ ] Tests avec Postman réussis
- [ ] Tests avec Flutter réussis
- [ ] Base de données de production créée
- [ ] Variables d'environnement production définies
- [ ] HTTPS activé sur le serveur
- [ ] Monitoring/Alertes en place

---

## 9. 🚀 COMMANDES UTILES

```bash
# Générer une clé JWT sécurisée
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Vérifier les variables d'env
node -e "require('dotenv').config(); console.log(process.env.JWT_SECRET ? '✅ JWT_SECRET' : '❌ JWT_SECRET missing')"

# Vérifier la connexion DB
npm run setup-db

# Lancer en développement
npm run dev

# Lancer en production
NODE_ENV=production npm start
```

---

**Une fois ces corrections appliquées, votre API sera prête pour la production et pour l'intégration Flutter! ✅**
