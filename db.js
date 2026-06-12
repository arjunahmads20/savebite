// Memanggil alat pg (PostgreSQL)
const { Pool } = require('pg');

// Memanggil dotenv agar bisa membaca file .env yang berisi password rahasia
require('dotenv').config();

// Membuat koneksi ke database menggunakan data dari .env
const pool = new Pool({
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    database: process.env.DB_NAME,
});

// Tes apakah koneksi berhasil saat aplikasi dinyalakan
pool.connect((err) => {
    if (err) {
        console.error('Gagal menyambung ke Database!', err.stack);
    } else {
        console.log('Berhasil menyambung ke Database PostgreSQL!');
    }
});

// Mengekspor koneksi ini agar bisa dipakai di index.js
module.exports = pool;