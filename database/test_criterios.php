<?php
// Verifica los criterios de aceptación de la historia de base de datos.
// Usa una base temporal, así que no toca data/app.db.
//   php database/test_criterios.php

$archivo = sys_get_temp_dir() . '/test_concesionario_' . getmypid() . '.db';
$pdo = new PDO('sqlite:' . $archivo, null, null, [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]);
$pdo->exec('PRAGMA foreign_keys = ON');

$fallos = 0;
function verificar(string $descripcion, bool $ok): void
{
    global $fallos;
    echo ($ok ? '  [OK]    ' : '  [FALLA] ') . $descripcion . PHP_EOL;
    if (!$ok) $fallos++;
}
function rechaza(PDO $pdo, string $sql): bool
{
    try { $pdo->exec($sql); return false; } catch (PDOException) { return true; }
}

echo 'Criterio 1: el script crea todas las tablas sin errores' . PHP_EOL;
$esperadas = ['usuarios', 'roles', 'sucursales', 'vehiculos', 'clientes', 'leads',
              'cotizaciones', 'citas', 'creditos', 'ventas', 'ordenes_servicio'];
try {
    $pdo->exec(file_get_contents(__DIR__ . '/schema.sql'));
    verificar('schema.sql se ejecuta sin errores', true);
} catch (PDOException $e) {
    verificar('schema.sql se ejecuta sin errores: ' . $e->getMessage(), false);
}
$creadas = $pdo->query("SELECT name FROM sqlite_master WHERE type = 'table'")->fetchAll(PDO::FETCH_COLUMN);
foreach ($esperadas as $tabla) {
    verificar("existe la tabla $tabla", in_array($tabla, $creadas, true));
}

echo PHP_EOL . 'Criterio 2: con la base vacía, los datos de prueba se cargan' . PHP_EOL;
verificar('la base empieza vacía', (int) $pdo->query('SELECT COUNT(*) FROM usuarios')->fetchColumn() === 0);
$pdo->exec(file_get_contents(__DIR__ . '/seed.sql'));
foreach (['usuarios', 'vehiculos', 'clientes', 'sucursales'] as $tabla) {
    $n = (int) $pdo->query("SELECT COUNT(*) FROM $tabla")->fetchColumn();
    verificar("hay $n registros de ejemplo en $tabla", $n > 0);
}

echo PHP_EOL . 'Criterio 3: no se puede guardar un dato sin su registro relacionado' . PHP_EOL;
verificar('rechaza usuario con rol inexistente',
    rechaza($pdo, "INSERT INTO usuarios (rol_id, nombre, apellido, correo, contrasena_hash)
                   VALUES (999, 'X', 'Y', 'x@y.test', '\$2y\$12\$abc')"));
verificar('rechaza vehículo con sucursal inexistente',
    rechaza($pdo, "INSERT INTO vehiculos (sucursal_id, vin, marca, modelo, anio, precio)
                   VALUES (999, 'VINFALSO123', 'Kia', 'Picanto', 2026, 1)"));
verificar('rechaza venta con cliente inexistente',
    rechaza($pdo, "INSERT INTO ventas (cliente_id, vehiculo_id, asesor_id, sucursal_id, precio_final, metodo_pago)
                   VALUES (999, 1, 3, 1, 1, 'contado')"));
verificar('rechaza borrar una sucursal que tiene vehículos',
    rechaza($pdo, 'DELETE FROM sucursales WHERE id = 1'));

echo PHP_EOL . 'Reglas' . PHP_EOL;
verificar('rechaza correo de usuario repetido (sin importar mayúsculas)',
    rechaza($pdo, "INSERT INTO usuarios (rol_id, nombre, apellido, correo, contrasena_hash)
                   VALUES (3, 'X', 'Y', 'ADMIN@concesionario.test', '\$2y\$12\$abc')"));
verificar('rechaza correo de cliente repetido',
    rechaza($pdo, "INSERT INTO clientes (tipo_documento, numero_documento, nombre, correo)
                   VALUES ('CC', '1', 'X', 'maria.lopez@correo.test')"));
verificar('rechaza contraseña en texto plano',
    rechaza($pdo, "INSERT INTO usuarios (rol_id, nombre, apellido, correo, contrasena_hash)
                   VALUES (3, 'X', 'Y', 'nuevo@concesionario.test', 'Clave123*')"));
$hashes = $pdo->query('SELECT contrasena_hash FROM usuarios')->fetchAll(PDO::FETCH_COLUMN);
verificar('todas las contraseñas guardadas son hash bcrypt válidos de "Clave123*"',
    array_reduce($hashes, fn ($ok, $h) => $ok && password_verify('Clave123*', $h), true));

$pdo = null;
@unlink($archivo);

echo PHP_EOL . ($fallos === 0 ? 'Todos los criterios se cumplen.' : "$fallos verificaciones fallaron.") . PHP_EOL;
exit($fallos === 0 ? 0 : 1);
