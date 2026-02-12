# 🚌 Bus Reservation System - Database Inspection Guide

## 📋 Overview
This document provides comprehensive methods to inspect and verify your bus reservation database content after launching the application.

## 🚀 Available Inspection Methods

### 1. **Web-Based Database Dashboard** (Recommended)
**URL:** http://localhost:3000/advanced-database-inspector.html

**Features:**
- Interactive tabbed interface for all database tables
- Real-time data visualization with search capabilities
- Advanced filtering and sorting options
- Statistical overview and analytics
- Auto-refresh functionality (every 30 seconds)
- Mobile-responsive design

**Access Methods:**
- Click the preview browser button in your IDE
- Direct browser access: `http://localhost:3000/advanced-database-inspector.html`
- Alternative simpler dashboard: `http://localhost:3000/database-dashboard.html`

### 2. **Command-Line Database Inspector**
**Location:** `scripts/database-inspector.js`

**Usage:**
```bash
# Full database view (default)
node scripts/database-inspector.js

# Quick summary only
node scripts/database-inspector.js --summary

# Detailed statistics
node scripts/database-inspector.js --stats

# Help menu
node scripts/database-inspector.js --help
```

**Sample Output:**
```
🚀 QUICK DATABASE SUMMARY:
┌─────────────┬──────────┐
│ Table       │ Count    │
├─────────────┼──────────┤
│ Users       │        2 │
│ Buses       │        1 │
│ Employees   │        0 │
│ Reservations│        1 │
│ Payments    │        1 │
└─────────────┴──────────┘
```

### 3. **Direct API Endpoints**
**Base URL:** http://localhost:3000/api/debug/

#### Core Endpoints:
- `GET /api/debug/database-state` - Complete database snapshot
- `GET /api/debug/database-test` - Database connectivity test
- `GET /api/debug/statistics` - Detailed statistical analysis
- `GET /api/debug/query?table={table}&search={term}` - Advanced querying

#### Query Parameters for `/api/debug/query`:
- `table`: users, buses, reservations, payments
- `limit`: Number of records (default: 10)
- `offset`: Pagination offset (default: 0)
- `search`: Search term across relevant fields
- `sort`: Sort by field name

## 📊 Current Database Status

### Table Summary:
| Table | Records | Description |
|-------|---------|-------------|
| Users | 2 | Admin + Regular user accounts |
| Buses | 1 | Operational bus with route information |
| Employees | 0 | Staff assignments (currently empty) |
| Reservations | 1 | Pending ticket booking |
| Payments | 1 | Completed transaction |

### Sample Data Structure:

**Users Table:**
- Admin user: admin@busapp.com (admin role)
- Regular user: testuser@example.com (user role)

**Buses Table:**
- BUS-TEST-001: City A → City B route
- 40 total seats, 39 available
- Price: 2500.00 FCFA per ticket

**Reservations Table:**
- Seat #1 reserved on BUS-TEST-001
- Status: pending
- Associated QR code generated

**Payments Table:**
- Payment of 2600.00 FCFA (2500 ticket + 100 deposit)
- Status: completed

## 🔧 Troubleshooting Commands

### Check Server Status:
```bash
curl http://localhost:3000/health
```

### Verify Database Connectivity:
```bash
curl http://localhost:3000/api/debug/database-test
```

### Get Complete Database State:
```bash
curl http://localhost:3000/api/debug/database-state | jq '.'
```

### Check Specific Table:
```bash
# Users
curl http://localhost:3000/api/users

# Buses  
curl http://localhost:3000/api/buses

# Reservations
curl http://localhost:3000/api/reservations

# Payments
curl http://localhost:3000/api/payments
```

## 🛠️ Development Tips

### Adding Test Data:
You can register new users via:
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"newuser@example.com","password":"password123","name":"New User","phone":"+1234567890"}'
```

### Making Reservations:
First login to get token, then:
```bash
curl -X POST http://localhost:3000/api/reservations \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"bus_id":1,"seat_number":5}'
```

## ⚠️ Important Notes

1. **In-Memory Database:** Data is lost when server restarts
2. **Development Mode:** Currently using in-memory storage for quick iteration
3. **Security:** All passwords are properly hashed with bcrypt
4. **Currency:** All monetary values are in FCFA (West African CFA Franc)
5. **Timezone:** All timestamps are in UTC

## 🔄 Auto-Refresh Schedule

- Web dashboards: Every 30 seconds
- Command-line tools: Manual refresh only
- API endpoints: Real-time data on each request

## 📞 Support

If you encounter any issues:
1. Ensure server is running: `npm start`
2. Check server logs: `tail -f server.log`
3. Verify port availability: `lsof -i :3000`
4. Test basic connectivity: `curl http://localhost:3000/health`

---
*Last Updated: February 11, 2026*