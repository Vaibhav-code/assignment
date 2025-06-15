const express = require('express');
const fs = require('fs');
const dotenv = require('dotenv');
const path = require('path');
const bodyParser = require('body-parser');

// Load current environment variables
dotenv.config();

const app = express();
const port = 3000;

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(bodyParser.urlencoded({ extended: true }));

// GET request - show form and current SECRET_WORD
app.get('/', (req, res) => {
  const secret = process.env.SECRET_WORD || 'not set';
  res.render('index', { secret });
});

// POST request - update SECRET_WORD
app.post('/update-secret', (req, res) => {
  const newSecret = req.body.secret;

  // Write to .env file
  fs.writeFileSync('.env', `SECRET_WORD=${newSecret}\n`);

  // Reload new env variable
  process.env.SECRET_WORD = newSecret;

  res.redirect('/');
});

app.listen(port, () => {
  console.log(`App running at http://localhost:${port}`);
});
