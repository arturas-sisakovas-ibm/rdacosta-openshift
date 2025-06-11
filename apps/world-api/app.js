'use strict';

const express           = require('express');
const cors              = require('cors');
const mysql             = require('mysql2/promise');
const cityCountryRoutes = require('./routes/cityCountry');
const healthzRoute      = require('./routes/healthz');

const app   = express();
const port  = process.env.NODE_PORT || 8080;

const pool = mysql.createPool({
  host               : process.env.DB_HOST,
  port               : process.env.DB_PORT || 3306,
  user               : process.env.MYSQL_USER,
  password           : process.env.MYSQL_PASSWORD,
  database           : process.env.MYSQL_DATABASE || 'world',
  waitForConnections : true,
  connectionLimit    : 10,
  queueLimit         : 0
});

app.use(cors());
app.use(express.json());

app.get('/healthz', healthzRoute(pool));
app.get('/city',    cityCountryRoutes.city(pool));
app.get('/country', cityCountryRoutes.country(pool));

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ message: 'Internal server error' });
});

app.listen(port, () => {
  console.log(`App listening on port ${port}`);
});
