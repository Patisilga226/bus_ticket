const db = require('../config/database');

const createTables = async () => {
  try {
    console.log('🔧 Creating database tables...');

    // Table Users (utilisateurs, admins, employés)
    await db.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        name VARCHAR(255) NOT NULL,
        phone VARCHAR(20),
        role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('admin', 'employee', 'user')),
        wallet_balance DECIMAL(10, 2) DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Table users created');

    // Table Buses
    await db.query(`
      CREATE TABLE IF NOT EXISTS buses (
        id SERIAL PRIMARY KEY,
        bus_number VARCHAR(50) UNIQUE NOT NULL,
        route VARCHAR(255) NOT NULL,
        departure_time TIMESTAMP NOT NULL,
        arrival_time TIMESTAMP NOT NULL,
        total_seats INTEGER NOT NULL,
        available_seats INTEGER NOT NULL,
        price DECIMAL(10, 2) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Table buses created');

    // Table Employees (assignation employé-bus)
    await db.query(`
      CREATE TABLE IF NOT EXISTS employees (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        bus_id INTEGER REFERENCES buses(id) ON DELETE CASCADE,
        assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, bus_id)
      )
    `);
    console.log('✅ Table employees created');

    // Table Reservations
    await db.query(`
      CREATE TABLE IF NOT EXISTS reservations (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        bus_id INTEGER REFERENCES buses(id) ON DELETE CASCADE,
        passenger_name VARCHAR(255),
        route_override VARCHAR(255),
        seat_number INTEGER NOT NULL,
        qr_code TEXT UNIQUE NOT NULL,
        status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'scanned', 'cancelled')),
        departure_time TIMESTAMP NOT NULL,
        qr_valid_until TIMESTAMP NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Table reservations created');

    // Ensure new optional columns exist for custom passenger/route values
    await db.query(`
      ALTER TABLE reservations
      ADD COLUMN IF NOT EXISTS passenger_name VARCHAR(255)
    `);
    await db.query(`
      ALTER TABLE reservations
      ADD COLUMN IF NOT EXISTS route_override VARCHAR(255)
    `);
    console.log('✅ Reservation custom fields ensured');

    // Table Payments
    await db.query(`
      CREATE TABLE IF NOT EXISTS payments (
        id SERIAL PRIMARY KEY,
        reservation_id INTEGER REFERENCES reservations(id) ON DELETE CASCADE,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        amount DECIMAL(10, 2) NOT NULL,
        deposit DECIMAL(10, 2) DEFAULT 100,
        type VARCHAR(20) DEFAULT 'payment' CHECK (type IN ('payment', 'refund', 'compensation')),
        status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Table payments created');

    // Créer un admin par défaut
    const bcrypt = require('bcryptjs');
    const hashedPassword = await bcrypt.hash('admin123', 10);
    
    await db.query(`
      INSERT INTO users (email, password, name, role)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (email) DO NOTHING
    `, ['admin@busapp.com', hashedPassword, 'Admin Principal', 'admin']);
    
    console.log('✅ Admin par défaut créé (email: admin@busapp.com, password: admin123)');

    console.log('\n🎉 Database setup completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error creating tables:', error);
    process.exit(1);
  }
};

createTables();
