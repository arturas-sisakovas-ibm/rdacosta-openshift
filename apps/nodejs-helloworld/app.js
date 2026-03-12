var express = require('express');
app = express();

const app_ver = process.env.app_ver || "unknown";

app.get('/', function (req, res) {
  res.send(`Hello World! I am version ${app_ver}`);
});

app.listen(8080, function () {
  console.log(`Example app listening on port 8080! Version ${app_ver}`);
});
