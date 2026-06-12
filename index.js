const express = require('express');
const app = express();
const pool = require('./db.js');
const jwt = require('jsonwebtoken'); // Library JWT
const bcrypt = require('bcrypt');    // Library Enkripsi Password
const PORT = process.env.PORT || 3000;

app.use(express.json());

// Gunakan secret dari .env, atau teks default jika .env belum siap
const JWT_SECRET = process.env.JWT_SECRET || 'token_savebite_ultimate_aman_gitulah_2026';

// MIDDLEWARE JWT
// Mengecek token sebelum mengizinkan masuk ke database
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Mengambil token setelah kata "Bearer"

    if (!token) return res.status(401).json({ error: "Akses Ditolak! Anda belum login (Token tidak ada)." });

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) return res.status(403).json({ error: "Token tidak valid atau sudah kadaluarsa!" });
        
        req.user = user; // Meniitipkan data user ke dalam request
        next(); // mempersilakan untuk masuk
    });
};

// ENDPOINT KHUSUS: REGISTER & LOGIN

// 1. REGISTER (Daftar Akun Baru)
app.post('/api/auth/register', async (req, res) => {
    try {
        const { first_name, last_name, phone_number, email, password } = req.body;

        // Mengecek apakah email sudah dipakai
        const cekUser = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
        if (cekUser.rows.length > 0) return res.status(400).json({ error: "Email sudah terdaftar!" });

        // Mengacak password dengan tingkat kesulitan 10
        const hashedPassword = await bcrypt.hash(password, 10);

        const query = `INSERT INTO users (first_name, last_name, phone_number, email, password) VALUES ($1, $2, $3, $4, $5) RETURNING id, first_name, email`;
        const result = await pool.query(query, [first_name, last_name, phone_number, email, hashedPassword]);

        res.status(201).json({ pesan: "Registrasi Berhasil!", user: result.rows[0] });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// 2. LOGIN (Mendapatkan Tiket JWT)
app.post('/api/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;

        // Cari user berdasarkan email
        const result = await pool.query('SELECT * FROM users WHERE email = $1', [email]);
        if (result.rows.length === 0) return res.status(401).json({ error: "Email atau Password salah!" });

        const user = result.rows[0];

        // Bandingkan password ketikan dengan password acak di database
        const isPasswordValid = await bcrypt.compare(password, user.password);
        if (!isPasswordValid) return res.status(401).json({ error: "Email atau Password salah!" });

        // Buat Kunci JWT (berlaku 24 jam)
        const token = jwt.sign(
            { id: user.id, email: user.email, role: user.role }, 
            JWT_SECRET, 
            { expiresIn: '24h' }
        );

        // Update last login
        await pool.query('UPDATE users SET datetime_last_login = CURRENT_TIMESTAMP WHERE id = $1', [user.id]);

        res.json({ pesan: "Login Berhasil!", token: token });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// PEMBUAT CRUD OTOMATIS
const createCRUDEndpoints = (endpoint, tableName) => {
    
    // Menyisipkan 'authenticateToken' di tengah-tengah jalur API
    
    app.get(`/api/${endpoint}`, authenticateToken, async (req, res) => {
        try {
            const result = await pool.query(`SELECT * FROM ${tableName} ORDER BY id DESC`);
            res.json(result.rows);
        } catch (err) { res.status(500).json({ error: err.message }); }
    });

    app.get(`/api/${endpoint}/:id`, authenticateToken, async (req, res) => {
        try {
            const result = await pool.query(`SELECT * FROM ${tableName} WHERE id = $1`, [req.params.id]);
            if (result.rows.length === 0) return res.status(404).json({ error: "Not found" });
            res.json(result.rows[0]);
        } catch (err) { res.status(500).json({ error: err.message }); }
    });

    app.post(`/api/${endpoint}`, authenticateToken, async (req, res) => {
        try {
            // Pencegahan pembuatan akun melalui CRUD otomatis agar password tidak tersimpan tanpa proses hashing
            if (tableName === 'users') {
                return res.status(403).json({ error: "Gunakan endpoint /api/auth/register untuk menambah user baru." });
            }

            const keys = Object.keys(req.body);
            const values = Object.values(req.body);
            const placeholders = keys.map((_, i) => `$${i + 1}`).join(', '); 
            
            const query = `INSERT INTO ${tableName} (${keys.join(', ')}) VALUES (${placeholders}) RETURNING *`;
            const result = await pool.query(query, values);
            res.status(201).json(result.rows[0]);
        } catch (err) { res.status(500).json({ error: err.message }); }
    });

    app.put(`/api/${endpoint}/:id`, authenticateToken, async (req, res) => {
        try {
            const keys = Object.keys(req.body);
            const values = Object.values(req.body);
            const updates = keys.map((key, i) => `${key}=$${i + 1}`).join(', ');
            
            const query = `UPDATE ${tableName} SET ${updates} WHERE id=$${keys.length + 1} RETURNING *`;
            const result = await pool.query(query, [...values, req.params.id]);
            if (result.rows.length === 0) return res.status(404).json({ error: "Not found" });
            res.json(result.rows[0]);
        } catch (err) { res.status(500).json({ error: err.message }); }
    });

    app.delete(`/api/${endpoint}/:id`, authenticateToken, async (req, res) => {
        try {
            const result = await pool.query(`DELETE FROM ${tableName} WHERE id = $1 RETURNING *`, [req.params.id]);
            if (result.rows.length === 0) return res.status(404).json({ error: "Not found" });
            res.status(204).send();
        } catch (err) { res.status(500).json({ error: err.message }); }
    });
};

// DAFTAR ENDPOINT API SAVEBITE

// 1. Company
createCRUDEndpoints('visions', 'visions');
createCRUDEndpoints('missions', 'missions');
createCRUDEndpoints('partners', 'partners');

// 2. Account
createCRUDEndpoints('users', 'users');
createCRUDEndpoints('otp-verifications', 'otp_verifications');
createCRUDEndpoints('user-inboxes', 'user_inboxes');

// 3. Address System
createCRUDEndpoints('countries', 'countries');
createCRUDEndpoints('provinces', 'provinces');
createCRUDEndpoints('regencies', 'regencies');
createCRUDEndpoints('districts', 'districts');
createCRUDEndpoints('villages', 'villages');
createCRUDEndpoints('streets', 'streets');
createCRUDEndpoints('pick-addresses', 'user_pick_addresses');

// 4. Goods System
createCRUDEndpoints('good-categories', 'good_categories');
createCRUDEndpoints('good-donation-points', 'good_donation_points');
createCRUDEndpoints('user-goods', 'user_goods');
createCRUDEndpoints('user-good-pictures', 'user_good_pictures');
createCRUDEndpoints('good-takens', 'good_takens');
createCRUDEndpoints('good-taken-reviews', 'good_taken_reviews');
createCRUDEndpoints('requests', 'requests');

// 5. Chat System
createCRUDEndpoints('chats', 'chats');

// SERVER RUNNING
app.listen(PORT, () => {
    console.log(`SaveBite API + JWT Security is running on http://localhost:${PORT}`);
});