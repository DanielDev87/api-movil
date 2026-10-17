<?php
// Router para el servidor de desarrollo integrado de PHP.
$ruta = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
$archivo = __DIR__ . '/../' . ltrim($ruta, '/');
if (is_file($archivo)) {
    return false;
}

require __DIR__ . '/../index.php';
