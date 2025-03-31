const express = require('express');
const app = express();
const port = process.env.PORT || process.env.NODE_PORT || 3000;

app.use(express.static('public'));

app.get('/', (req, res) => {
  const message = process.env.APP_MSG || "Hello world";
  res.send(`
    <html>
      <head>
        <title>Hello world</title>
        <link rel="stylesheet" type="text/css" href="/style.css">
      </head>
      <body>
        <div class="segment top-segment"></div>
        <div class="segment middle-segment">
          <span>${message}</span>
        </div>
        <div class="segment bottom-segment"></div>
      </body>
    </html>
  `);
});

app.listen(port, () => {
  console.log(`App running on http://localhost:${port}`);
});
