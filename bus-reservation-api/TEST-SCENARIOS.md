# 🧪 Scénarios de Test

## Scénario 1 : Réservation réussie avec passager à l'heure

### Étapes

1. **Login admin**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@busapp.com","password":"admin123"}'
```
→ Copier le `token`

2. **Créer un bus (départ dans 3 heures)**
```bash
curl -X POST http://localhost:3000/api/buses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "bus_number": "BUS-TEST-001",
    "route": "Ouagadougou - Bobo-Dioulasso",
    "departure_time": "2026-02-08T23:00:00Z",
    "arrival_time": "2026-02-09T03:00:00Z",
    "total_seats": 50,
    "price": 2500
  }'
```
→ Noter le `id` du bus

3. **Créer un utilisateur**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "passager@test.com",
    "password": "pass123",
    "name": "Jean Test",
    "phone": "+226 70123456"
  }'
```

4. **Login utilisateur**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"passager@test.com","password":"pass123"}'
```
→ Copier le `token` utilisateur

5. **Créer une réservation**
```bash
curl -X POST http://localhost:3000/api/reservations \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer USER_TOKEN" \
  -d '{
    "bus_id": 1,
    "seat_number": 15
  }'
```
→ Copier le `qr_code`

**Résultat attendu :**
```json
{
  "message": "Réservation créée avec succès",
  "reservation": { ... },
  "qr_code": "data:image/png;base64,...",
  "total_amount": 2600,
  "qr_valid_until": "2026-02-08T22:00:00Z"
}
```

6. **Créer un employé**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "employee@test.com",
    "password": "emp123",
    "name": "Employé Test",
    "role": "employee"
  }'
```

7. **Assigner l'employé au bus (avec token admin)**
```bash
curl -X POST http://localhost:3000/api/employees \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ADMIN_TOKEN" \
  -d '{
    "user_id": 3,
    "bus_id": 1
  }'
```

8. **Login employé**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"employee@test.com","password":"emp123"}'
```

9. **Scanner le QR code (AVANT l'heure limite)**
```bash
curl -X POST http://localhost:3000/api/scan-qr \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer EMPLOYEE_TOKEN" \
  -d '{
    "qr_code": "LE_QR_CODE_COPIE_ETAPE_5"
  }'
```

**Résultat attendu :**
```json
{
  "success": true,
  "message": "Passager à l'heure ! Caution de 100 FCFA remboursée.",
  "scan_details": {
    "is_on_time": true,
    "refund_amount": 100,
    "compensation_amount": 0,
    ...
  }
}
```

---

## Scénario 2 : Passager en retard

### Différence avec Scénario 1

**Étape 2 :** Créer un bus avec départ dans 30 minutes
```json
{
  "departure_time": "2026-02-08T20:30:00Z"  // Proche de maintenant
}
```

Le QR sera valable jusqu'à 19:30 (1h avant départ).

**Étape 9 :** Scanner APRÈS l'heure limite mais AVANT le départ

**Résultat attendu :**
```json
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

---

## Scénario 3 : QR code expiré (bus déjà parti)

**Étape 2 :** Créer un bus avec départ dans le passé
```json
{
  "departure_time": "2026-02-08T19:00:00Z"  // Dans le passé
}
```

**Étape 9 :** Tenter de scanner

**Résultat attendu :**
```json
{
  "error": "Le bus est déjà parti. QR code expiré."
}
```

---

## Scénario 4 : Annulation de réservation

Après avoir créé une réservation (Scénario 1, étape 5) :

```bash
curl -X DELETE http://localhost:3000/api/reservations/1 \
  -H "Authorization: Bearer USER_TOKEN"
```

**Résultat attendu :**
```json
{
  "message": "Réservation annulée avec succès"
}
```

Vérifier que le siège est de nouveau disponible :
```bash
curl -X GET http://localhost:3000/api/buses/1
```

Le `available_seats` devrait avoir augmenté de 1.

---

## Scénario 5 : Dashboard Admin - Statistiques

1. **Créer plusieurs réservations** (répéter Scénario 1)
2. **Scanner quelques QR codes** avec différents résultats
3. **Consulter les statistiques**

```bash
curl -X GET http://localhost:3000/api/payments/stats/summary \
  -H "Authorization: Bearer ADMIN_TOKEN"
```

**Résultat attendu :**
```json
{
  "revenue": {
    "total": 10400,      // 4 réservations × 2600 FCFA
    "refunds": 2600,     // 2 passagers à l'heure × 100 + 1 en retard × 2500
    "compensation": 100, // 1 passager en retard
    "net": 7800
  },
  "transactions": {
    "total_payments": 4,
    "total_refunds": 3,
    "total_compensations": 1
  }
}
```

---

## Scénario 6 : Gestion d'erreurs courantes

### Tenter de réserver un siège déjà pris
```bash
# Première réservation
curl -X POST http://localhost:3000/api/reservations \
  -H "Authorization: Bearer USER_TOKEN" \
  -d '{"bus_id": 1, "seat_number": 10}'

# Deuxième réservation sur le même siège
curl -X POST http://localhost:3000/api/reservations \
  -H "Authorization: Bearer USER_TOKEN" \
  -d '{"bus_id": 1, "seat_number": 10}'
```

**Résultat attendu :**
```json
{
  "error": "Ce siège est déjà réservé"
}
```

### Tenter de scanner un QR déjà scanné
```bash
# Scanner une première fois
curl -X POST http://localhost:3000/api/scan-qr \
  -H "Authorization: Bearer EMPLOYEE_TOKEN" \
  -d '{"qr_code": "..."}'

# Scanner une deuxième fois
curl -X POST http://localhost:3000/api/scan-qr \
  -H "Authorization: Bearer EMPLOYEE_TOKEN" \
  -d '{"qr_code": "..."}'
```

**Résultat attendu :**
```json
{
  "error": "Ce QR code a déjà été scanné"
}
```

### Tenter d'accéder à une route admin sans être admin
```bash
curl -X GET http://localhost:3000/api/users \
  -H "Authorization: Bearer USER_TOKEN"
```

**Résultat attendu :**
```json
{
  "error": "Accès réservé aux administrateurs"
}
```

---

## Checklist de test complet

- [ ] ✅ Inscription utilisateur
- [ ] ✅ Login utilisateur
- [ ] ✅ Création de bus (admin)
- [ ] ✅ Liste des bus (public)
- [ ] ✅ Création de réservation
- [ ] ✅ Génération de QR code
- [ ] ✅ Scan QR - passager à l'heure
- [ ] ✅ Scan QR - passager en retard
- [ ] ✅ Scan QR - bus déjà parti
- [ ] ✅ Scan QR - déjà scanné (erreur)
- [ ] ✅ Annulation de réservation
- [ ] ✅ Siège déjà réservé (erreur)
- [ ] ✅ Assignation employé à bus
- [ ] ✅ Statistiques paiements (admin)
- [ ] ✅ Accès non autorisé (erreur 403)
- [ ] ✅ Token invalide (erreur 401)

---

## Automatisation des tests

Pour automatiser ces tests, créer un fichier `tests/test-scenarios.sh` :

```bash
#!/bin/bash

BASE_URL="http://localhost:3000"

echo "🧪 Test Scénario 1: Réservation complète"

# Login admin
ADMIN_TOKEN=$(curl -s -X POST $BASE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@busapp.com","password":"admin123"}' \
  | jq -r '.token')

echo "✅ Admin logged in"

# Créer un bus
BUS_ID=$(curl -s -X POST $BASE_URL/api/buses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "bus_number": "AUTO-TEST-001",
    "route": "Test Route",
    "departure_time": "2026-02-09T08:00:00Z",
    "arrival_time": "2026-02-09T12:00:00Z",
    "total_seats": 50,
    "price": 2500
  }' | jq -r '.bus.id')

echo "✅ Bus created with ID: $BUS_ID"

# ... continuer avec les autres tests
```

Rendre exécutable :
```bash
chmod +x tests/test-scenarios.sh
./tests/test-scenarios.sh
```

---

**Bons tests ! 🚀**
