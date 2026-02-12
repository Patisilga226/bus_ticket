const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
require('dotenv').config();

// Simple in-memory database for development/testing purposes
class InMemoryDB {
  constructor() {
    this.data = {
      users: [],
      buses: [],
      employees: [],
      reservations: [],
      payments: []
    };
    
    // Add default admin user with properly hashed password
    this.initDefaultUsers();
  }

  async initDefaultUsers() {
    // Hash the default admin password
    const hashedPassword = await bcrypt.hash('admin123', 10);
    
    this.data.users.push({
      id: 1,
      email: 'admin@busapp.com',
      password: hashedPassword,
      name: 'Admin Principal',
      role: 'admin',
      wallet_balance: 0,
      created_at: new Date().toISOString()
    });
  }

  async query(text, params) {
    // Parse SQL-like commands for in-memory operations
    text = text.trim();
    
    if (text.toUpperCase().startsWith('SELECT')) {
      // Handle SELECT queries
      if (text.includes('FROM users')) {
        // Check if it's looking for the specific admin user
        if (params && params[0] === 'admin@busapp.com') {
          const filteredUsers = this.data.users.filter(user => user.email === params[0]);
          return { rows: filteredUsers, rowCount: filteredUsers.length };
        }
        return { rows: this.data.users, rowCount: this.data.users.length };
      } else if (text.includes('FROM buses')) {
        return { rows: this.data.buses, rowCount: this.data.buses.length };
      } else if (text.includes('FROM employees')) {
        return { rows: this.data.employees, rowCount: this.data.employees.length };
      } else if (text.includes('FROM reservations')) {
        return { rows: this.data.reservations, rowCount: this.data.reservations.length };
      } else if (text.includes('FROM payments')) {
        return { rows: this.data.payments, rowCount: this.data.payments.length };
      }
    } else if (text.toUpperCase().startsWith('INSERT')) {
      // Handle INSERT queries
      if (text.includes('INTO users')) {
        const hashedPassword = await bcrypt.hash(params[1], 10); // params[1] is the password
        const newUser = {
          id: this.data.users.length + 1,
          email: params[0],
          password: hashedPassword,
          name: params[2],
          phone: params[3],
          role: params[4] || 'user',
          wallet_balance: 0,
          created_at: new Date().toISOString()
        };
        this.data.users.push(newUser);
        return { rows: [newUser], rowCount: 1 };
      } else if (text.includes('INTO buses')) {
        const newBus = {
          id: this.data.buses.length + 1,
          bus_number: params[0],
          route: params[1],
          departure_time: params[2],
          arrival_time: params[3],
          total_seats: params[4],
          available_seats: params[5],
          price: params[6],
          created_at: new Date().toISOString()
        };
        this.data.buses.push(newBus);
        return { rows: [newBus], rowCount: 1 };
      } else if (text.includes('INTO employees')) {
        const newEmployee = {
          id: this.data.employees.length + 1,
          user_id: params[0],
          bus_id: params[1],
          assigned_at: new Date().toISOString()
        };
        this.data.employees.push(newEmployee);
        return { rows: [newEmployee], rowCount: 1 };
      } else if (text.includes('INTO reservations')) {
        const newReservation = {
          id: this.data.reservations.length + 1,
          user_id: params[0],
          bus_id: params[1],
          seat_number: params[2],
          qr_code: params[3],
          status: params[4] || 'pending',
          departure_time: params[5],
          qr_valid_until: params[6],
          created_at: new Date().toISOString()
        };
        this.data.reservations.push(newReservation);
        return { rows: [newReservation], rowCount: 1 };
      } else if (text.includes('INTO payments')) {
        const newPayment = {
          id: this.data.payments.length + 1,
          reservation_id: params[0],
          user_id: params[1],
          amount: params[2],
          deposit: params[3],
          type: params[4] || 'payment',
          status: params[5] || 'pending',
          created_at: new Date().toISOString()
        };
        this.data.payments.push(newPayment);
        return { rows: [newPayment], rowCount: 1 };
      }
    } else if (text.toUpperCase().startsWith('UPDATE')) {
      // Handle UPDATE queries
      if (text.includes('users SET')) {
        const setIndex = text.indexOf('SET ') + 4;
        const whereIndex = text.indexOf('WHERE ');
        const setClause = text.substring(setIndex, whereIndex - 1);
        
        // Extract the ID from WHERE clause
        const whereClause = text.substring(whereIndex);
        const idMatch = whereClause.match(/id = \$1|id = (\d+)/);
        const id = params ? params[0] : parseInt(idMatch[1]);
        
        const userIndex = this.data.users.findIndex(u => u.id === id);
        if (userIndex !== -1) {
          // Simple update based on params
          if (params.length >= 3) { // name, phone, wallet_balance
            this.data.users[userIndex].name = params[0] || this.data.users[userIndex].name;
            this.data.users[userIndex].phone = params[1] || this.data.users[userIndex].phone;
            this.data.users[userIndex].wallet_balance = params[2] || this.data.users[userIndex].wallet_balance;
          } else if (params.length === 2) { // name, phone
            this.data.users[userIndex].name = params[0] || this.data.users[userIndex].name;
            this.data.users[userIndex].phone = params[1] || this.data.users[userIndex].phone;
          }
          return { rowCount: 1 };
        }
      }
    } else if (text.toUpperCase().startsWith('DELETE')) {
      // Handle DELETE queries
      if (text.includes('FROM users')) {
        const whereClause = text.substring(text.indexOf('WHERE'));
        const idMatch = whereClause.match(/id = \$1|id = (\d+)/);
        const id = params ? params[0] : parseInt(idMatch[1]);
        
        const index = this.data.users.findIndex(u => u.id === id);
        if (index !== -1) {
          this.data.users.splice(index, 1);
          return { rowCount: 1 };
        }
      }
    }
    
    return { rows: [], rowCount: 0 };
  }
}

// Use in-memory DB if DATABASE_URL is not set to PostgreSQL
if (process.env.DATABASE_URL && process.env.DATABASE_URL.startsWith('postgresql')) {
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: {
      rejectUnauthorized: false
    }
  });

  // Test connection
  pool.on('connect', () => {
    console.log('✅ Connected to PostgreSQL database');
  });

  pool.on('error', (err) => {
    console.error('❌ Unexpected database error:', err);
    process.exit(-1);
  });

  module.exports = {
    query: (text, params) => pool.query(text, params),
    pool
  };
} else {
  // Use in-memory database for development
  console.log('⚠️  Using in-memory database for development');
  const inMemoryDB = new InMemoryDB();
  
  module.exports = {
    query: (text, params) => inMemoryDB.query(text, params),
    pool: null
  };
}