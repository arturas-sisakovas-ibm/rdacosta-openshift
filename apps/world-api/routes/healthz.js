module.exports = (db) => {
    return (req, res) => {
        const sql = 'SELECT * FROM City WHERE LOWER(Name) = LOWER(?)';
        db.query(sql, ['London'], (err, result) => {
            if (err || !result || !result.length) {
                console.error('Error connecting to database!', err);
                return res.status(503).send('Cannot connect to database');
            }

            console.log('Connected to database!');
            res.status(200).send('OK');
        });
    };
};