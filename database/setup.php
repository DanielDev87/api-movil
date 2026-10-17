<?php
// Crea (o recrea) la base de datos.
//   php database/setup.php          -> solo tablas
//   php database/setup.php --seed   -> tablas + datos de prueba

require __DIR__ . '/../db.php';

$conSeed = in_array('--seed', $argv ?? [], true);

try {
    db()->exec(file_get_contents(__DIR__ . '/schema.sql'));
    $tablas = db()->query("SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name")
                  ->fetchAll(PDO::FETCH_COLUMN);
    echo 'Tablas creadas (' . count($tablas) . '): ' . implode(', ', $tablas) . PHP_EOL;

    if ($conSeed) {
        db()->exec(file_get_contents(__DIR__ . '/seed.sql'));
        echo 'Datos de prueba cargados.' . PHP_EOL;
    }
    echo 'Base de datos lista en ' . realpath(DB_PATH) . PHP_EOL;
} catch (PDOException $e) {
    fwrite(STDERR, 'Error: ' . $e->getMessage() . PHP_EOL);
    exit(1);
}
