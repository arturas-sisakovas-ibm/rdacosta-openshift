const mysql = require('mysql');
const express = require('express');
const cityCountryRoutes = require('./routes/cityCountry');
const healthzRoute = require('./routes/healthz');

const app = express();
const port = process.env.NODE_PORT || 8080;

const pool = mysql.createPool({
  host: process.env.WORLD_HOST,
  user: process.env.WORLD_USER,
  password: process.env.WORLD_PASSWORD,
  database: process.env.WORLD_DATABASE,
  connectionLimit: 10
});

app.get('/city', cityCountryRoutes.city(pool));
app.get('/country', cityCountryRoutes.country(pool));
app.get('/healthz', healthzRoute(pool));

app.listen(port, () => {
  console.log(`App listening at http://localhost:${port}`);
});
