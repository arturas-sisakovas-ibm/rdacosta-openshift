exports.city = (db) => {
    return (req, res) => {
        const cityName = req.query.name;
  
        if (!cityName) {
            return res.status(400).send('Missing city name in query parameters.');
        }

        const sql = 'SELECT * FROM City WHERE LOWER(Name) = LOWER(?)';
        db.query(sql, [cityName], (err, result) => {
            if (err) throw err;
            res.send(result);
        });
    };
};

exports.country = (db) => {
    return (req, res) => {
        const countryName = req.query.name;

        if (!countryName) {
            return res.status(400).send('Missing country name in query parameters.');
        }

        const sql = 'SELECT * FROM Country WHERE LOWER(Name) = LOWER(?)';
        db.query(sql, [countryName], (err, result) => {
            if (err) throw err;
            res.send(result);
        });
    };
};
