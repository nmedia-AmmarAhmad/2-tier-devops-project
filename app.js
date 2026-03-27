const express = require('express');
const mysql = require('mysql2');
const bodyParser = require('body-parser'); // To read form data
const app = express();

app.use(bodyParser.urlencoded({ extended: true }));

// Database Connection
const db = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: 'admin',
    password: 'ComplexPass123!',
    database: 'ammar_db'
});

// 1. The Frontend Form (HTML)
app.get('/', (req, res) => {
    res.send(`
        <h1>Ammar's Support Portal</h1>
        <form action="/submit" method="POST">
            <input type="text" name="username" placeholder="Your Name" required><br><br>
            <input type="text" name="issue" placeholder="Describe Tech Issue" required><br><br>
            <button type="submit">Submit to Database</button>
        </form>
    `);
});

// 2. The Backend Action (Saving to DB)
app.post('/submit', (req, res) => {
    const { username, issue } = req.body;
    const sql = "INSERT INTO tickets (username, issue) VALUES (?, ?)";
    
    db.query(sql, [username, issue], (err, result) => {
        if (err) return res.status(500).send("Database Error: " + err.message);
        res.send(`<h2>Success! Ticket saved for ${username}.</h2><a href="/">Go Back</a>`);
    });
});

// 3. Health Check
app.get('/health', (req, res) => res.sendStatus(200));

app.listen(3000, () => console.log('App running on 3000'));