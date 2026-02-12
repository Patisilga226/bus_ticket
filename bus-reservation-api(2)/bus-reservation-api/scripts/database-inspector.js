#!/usr/bin/env node

const axios = require('axios');

const API_BASE = 'http://localhost:3000/api/debug';

async function fetchData(endpoint) {
    try {
        const response = await axios.get(`${API_BASE}${endpoint}`);
        return response.data;
    } catch (error) {
        console.error('❌ Error connecting to database API:', error.message);
        process.exit(1);
    }
}

function printHeader(title) {
    console.log('\n' + '='.repeat(60));
    console.log(`📊 ${title}`);
    console.log('='.repeat(60));
}

function printTable(title, data, columns) {
    if (!data || data.length === 0) {
        console.log(`\n📝 ${title}: No data found`);
        return;
    }
    
    console.log(`\n📋 ${title} (${data.length} records):`);
    console.log('-'.repeat(80));
    
    // Print headers
    const headers = columns.map(col => col.title.padEnd(col.width)).join(' | ');
    console.log(headers);
    console.log('-'.repeat(80));
    
    // Print data rows
    data.forEach(row => {
        const values = columns.map(col => {
            let value = row[col.field];
            if (col.format) {
                value = col.format(value);
            }
            return String(value).substring(0, col.width).padEnd(col.width);
        }).join(' | ');
        console.log(values);
    });
}

async function showDatabaseState() {
    printHeader('BUS RESERVATION SYSTEM - DATABASE INSPECTOR');
    
    const data = await fetchData('/database-state');
    
    if (!data.success) {
        console.error('❌ Failed to fetch database state');
        return;
    }
    
    // Summary
    console.log(`\n📈 DATABASE SUMMARY:`);
    console.log(`   Users: ${data.summary.total_users}`);
    console.log(`   Buses: ${data.summary.total_buses}`);
    console.log(`   Employees: ${data.summary.total_employees}`);
    console.log(`   Reservations: ${data.summary.total_reservations}`);
    console.log(`   Payments: ${data.summary.total_payments}`);
    console.log(`   Last Updated: ${new Date(data.timestamp).toLocaleString()}`);
    
    // Users Table
    printTable('USERS TABLE', data.database.users.data, [
        { title: 'ID', field: 'id', width: 4 },
        { title: 'Name', field: 'name', width: 20 },
        { title: 'Email', field: 'email', width: 25 },
        { title: 'Role', field: 'role', width: 8 },
        { title: 'Balance', field: 'wallet_balance', width: 12, format: val => `${parseFloat(val).toFixed(2)} FCFA` }
    ]);
    
    // Buses Table
    printTable('BUSES TABLE', data.database.buses.data, [
        { title: 'ID', field: 'id', width: 4 },
        { title: 'Bus Number', field: 'bus_number', width: 15 },
        { title: 'Route', field: 'route', width: 20 },
        { title: 'Total Seats', field: 'total_seats', width: 12 },
        { title: 'Available', field: 'available_seats', width: 10 },
        { title: 'Price', field: 'price', width: 12, format: val => `${parseFloat(val).toFixed(2)} FCFA` }
    ]);
    
    // Reservations Table
    printTable('RESERVATIONS TABLE', data.database.reservations.data, [
        { title: 'ID', field: 'id', width: 4 },
        { title: 'User ID', field: 'user_id', width: 10 },
        { title: 'Bus ID', field: 'bus_id', width: 10 },
        { title: 'Seat', field: 'seat_number', width: 6 },
        { title: 'Status', field: 'status', width: 12 },
        { title: 'Created', field: 'created_at', width: 20, format: val => new Date(val).toLocaleDateString() }
    ]);
    
    // Payments Table
    printTable('PAYMENTS TABLE', data.database.payments.data, [
        { title: 'ID', field: 'id', width: 4 },
        { title: 'Res ID', field: 'reservation_id', width: 8 },
        { title: 'User ID', field: 'user_id', width: 10 },
        { title: 'Amount', field: 'amount', width: 12, format: val => `${parseFloat(val).toFixed(2)} FCFA` },
        { title: 'Deposit', field: 'deposit', width: 12, format: val => `${parseFloat(val).toFixed(2)} FCFA` },
        { title: 'Status', field: 'status', width: 12 },
        { title: 'Created', field: 'created_at', width: 20, format: val => new Date(val).toLocaleDateString() }
    ]);
}

async function showStatistics() {
    printHeader('DATABASE STATISTICS');
    
    const stats = await fetchData('/statistics');
    
    if (!stats.success) {
        console.error('❌ Failed to fetch statistics');
        return;
    }
    
    const s = stats.statistics;
    
    console.log('\n👥 USER STATISTICS:');
    console.log(`   Total Users: ${s.users.total_users}`);
    console.log(`   Admin Accounts: ${s.users.admin_count}`);
    console.log(`   Regular Users: ${s.users.regular_users}`);
    console.log(`   Average Wallet Balance: ${parseFloat(s.users.avg_wallet_balance || 0).toFixed(2)} FCFA`);
    
    console.log('\n🚌 BUS STATISTICS:');
    console.log(`   Total Buses: ${s.buses.total_buses}`);
    console.log(`   Total Seating Capacity: ${s.buses.total_capacity} seats`);
    console.log(`   Available Seats: ${s.buses.total_available_seats}`);
    console.log(`   Average Ticket Price: ${parseFloat(s.buses.avg_ticket_price || 0).toFixed(2)} FCFA`);
    
    console.log('\n🎫 RESERVATION STATISTICS:');
    console.log(`   Total Reservations: ${s.reservations.total_reservations}`);
    console.log(`   Completed: ${s.reservations.completed_reservations}`);
    console.log(`   Pending: ${s.reservations.pending_reservations}`);
    console.log(`   Cancelled: ${s.reservations.cancelled_reservations}`);
    
    console.log('\n💰 PAYMENT STATISTICS:');
    console.log(`   Total Payments: ${s.payments.total_payments}`);
    console.log(`   Completed Payments: ${s.payments.completed_payments}`);
    console.log(`   Pending Payments: ${s.payments.pending_payments}`);
    console.log(`   Total Revenue: ${parseFloat(s.payments.total_revenue || 0).toFixed(2)} FCFA`);
    console.log(`   Average Payment Amount: ${parseFloat(s.payments.avg_payment_amount || 0).toFixed(2)} FCFA`);
    
    console.log(`\n🕒 Generated at: ${new Date(stats.generated_at).toLocaleString()}`);
}

async function showQuickSummary() {
    const data = await fetchData('/database-state');
    
    if (!data.success) return;
    
    console.log('\n🚀 QUICK DATABASE SUMMARY:');
    console.log('┌─────────────┬──────────┐');
    console.log('│ Table       │ Count    │');
    console.log('├─────────────┼──────────┤');
    console.log(`│ Users       │ ${String(data.summary.total_users).padStart(8)} │`);
    console.log(`│ Buses       │ ${String(data.summary.total_buses).padStart(8)} │`);
    console.log(`│ Employees   │ ${String(data.summary.total_employees).padStart(8)} │`);
    console.log(`│ Reservations│ ${String(data.summary.total_reservations).padStart(8)} │`);
    console.log(`│ Payments    │ ${String(data.summary.total_payments).padStart(8)} │`);
    console.log('└─────────────┴──────────┘');
    console.log(`Last updated: ${new Date(data.timestamp).toLocaleString()}`);
}

// Command line argument handling
const args = process.argv.slice(2);

if (args.includes('--help') || args.includes('-h')) {
    console.log(`
🚌 Bus Reservation Database Inspector

USAGE:
  node database-inspector.js [OPTIONS]

OPTIONS:
  --summary, -s    Show quick summary only
  --stats, -t      Show detailed statistics
  --full, -f       Show complete database view (default)
  --help, -h       Show this help message

EXAMPLES:
  node database-inspector.js           # Full database view
  node database-inspector.js --summary # Quick summary
  node database-inspector.js --stats   # Detailed statistics
    `);
    process.exit(0);
}

if (args.includes('--summary') || args.includes('-s')) {
    showQuickSummary();
} else if (args.includes('--stats') || args.includes('-t')) {
    showStatistics();
} else {
    showDatabaseState();
}