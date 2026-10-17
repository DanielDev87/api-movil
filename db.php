<?php
// Conexión única a la base SQLite. La usan la API y los scripts de /database.

const DB_PATH = __DIR__ . '/data/app.db';

function db(): PDO
{
    static $pdo = null;
    if ($pdo === null) {
        if (!is_dir(dirname(DB_PATH))) {
            mkdir(dirname(DB_PATH), 0775, true);
        }
        $pdo = new PDO('sqlite:' . DB_PATH, null, null, [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ]);
        // SQLite no valida llaves foráneas a menos que se active en cada conexión.
        $pdo->exec('PRAGMA foreign_keys = ON');
    }
    return $pdo;
}
