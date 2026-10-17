<?php
declare(strict_types=1);

require_once __DIR__ . '/../db.php';

header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Accept');

function responder(int $status, mixed $data = null): never
{
    http_response_code($status);
    if ($status !== 204) {
        echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }
    exit;
}

function errorApi(int $status, string $mensaje): never
{
    responder($status, ['error' => $mensaje]);
}

function leerJson(): array
{
    $json = file_get_contents('php://input');
    try {
        $datos = json_decode($json === false ? '' : $json, false, 512, JSON_THROW_ON_ERROR);
    } catch (JsonException) {
        errorApi(400, 'El cuerpo debe contener JSON válido.');
    }

    if (!$datos instanceof stdClass) {
        errorApi(400, 'El cuerpo debe ser un objeto JSON.');
    }

    return get_object_vars($datos);
}

function validarValores(array $datos): void
{
    foreach ($datos as $valor) {
        if (!is_scalar($valor) && $valor !== null) {
            errorApi(422, 'Los valores de los campos deben ser escalares o null.');
        }
    }
}

function manejarError(PDOException $error): never
{
    $detalle = $error->getMessage();
    if (str_contains($detalle, 'FOREIGN KEY constraint failed')) {
        errorApi(409, 'La operación viola una relación entre registros.');
    }
    if (str_contains($detalle, 'UNIQUE constraint failed')) {
        errorApi(409, 'Ya existe un registro con uno de los valores únicos enviados.');
    }
    if (str_contains($detalle, 'CHECK constraint failed')
        || str_contains($detalle, 'NOT NULL constraint failed')) {
        errorApi(422, 'Uno o más campos no cumplen las reglas de la base de datos.');
    }

    error_log($detalle);
    errorApi(500, 'Error interno al consultar la base de datos.');
}

$recursos = [
    'roles' => [
        'tabla' => 'roles',
        'columnas' => ['nombre', 'descripcion'],
    ],
    'sucursales' => [
        'tabla' => 'sucursales',
        'columnas' => ['nombre', 'direccion', 'ciudad', 'telefono', 'correo', 'activa'],
    ],
    'usuarios' => [
        'tabla' => 'usuarios',
        'columnas' => ['rol_id', 'sucursal_id', 'nombre', 'apellido', 'correo', 'telefono', 'activo'],
        'lectura' => 'id, rol_id, sucursal_id, nombre, apellido, correo, telefono, activo, creado_en',
        'contrasena' => true,
    ],
    'vehiculos' => [
        'tabla' => 'vehiculos',
        'columnas' => ['sucursal_id', 'vin', 'placa', 'marca', 'modelo', 'anio', 'version', 'color',
            'condicion', 'kilometraje', 'precio', 'estado'],
    ],
    'clientes' => [
        'tabla' => 'clientes',
        'columnas' => ['tipo_documento', 'numero_documento', 'nombre', 'apellido', 'correo', 'telefono',
            'direccion', 'ciudad'],
    ],
    'leads' => [
        'tabla' => 'leads',
        'columnas' => ['cliente_id', 'sucursal_id', 'asesor_id', 'vehiculo_id', 'origen', 'estado', 'notas'],
    ],
    'cotizaciones' => [
        'tabla' => 'cotizaciones',
        'columnas' => ['cliente_id', 'vehiculo_id', 'asesor_id', 'lead_id', 'precio_base', 'descuento',
            'total', 'vigente_hasta', 'estado'],
    ],
    'citas' => [
        'tabla' => 'citas',
        'columnas' => ['cliente_id', 'sucursal_id', 'usuario_id', 'vehiculo_id', 'tipo', 'fecha_hora',
            'estado', 'notas'],
    ],
    'creditos' => [
        'tabla' => 'creditos',
        'columnas' => ['cliente_id', 'cotizacion_id', 'entidad_financiera', 'monto', 'cuota_inicial',
            'plazo_meses', 'tasa_interes', 'estado'],
    ],
    'ventas' => [
        'tabla' => 'ventas',
        'columnas' => ['cliente_id', 'vehiculo_id', 'asesor_id', 'sucursal_id', 'cotizacion_id', 'credito_id',
            'precio_final', 'metodo_pago', 'fecha_venta'],
    ],
    'ordenes-servicio' => [
        'tabla' => 'ordenes_servicio',
        'columnas' => ['cliente_id', 'vehiculo_id', 'sucursal_id', 'tecnico_id', 'cita_id', 'tipo_servicio',
            'descripcion', 'kilometraje', 'estado', 'costo_total', 'fecha_ingreso', 'fecha_entrega'],
    ],
];

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    responder(204);
}

$ruta = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
$segmentos = array_values(array_filter(explode('/', trim($ruta, '/')), 'strlen'));
if (($segmentos[0] ?? '') === 'api') {
    array_shift($segmentos);
}
if (($segmentos[0] ?? '') === 'index.php') {
    array_shift($segmentos);
}

$metodo = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');

try {
    if (($segmentos[0] ?? '') === 'health' && count($segmentos) === 1 && $metodo === 'GET') {
        db()->query('SELECT 1');
        responder(200, ['status' => 'ok', 'database' => 'connected']);
    }

    $recurso = $segmentos[0] ?? '';
    if (!isset($recursos[$recurso]) || count($segmentos) > 2) {
        errorApi(404, 'Ruta no encontrada.');
    }

    $config = $recursos[$recurso];
    $tabla = $config['tabla'];
    $lectura = $config['lectura'] ?? '*';
    $id = $segmentos[1] ?? null;
    if ($id !== null && !preg_match('/^[1-9][0-9]*$/', $id)) {
        errorApi(400, 'El identificador debe ser un entero positivo.');
    }

    $pdo = db();
    if ($metodo === 'GET') {
        if ($id !== null) {
            $consulta = $pdo->prepare("SELECT $lectura FROM $tabla WHERE id = :id");
            $consulta->execute(['id' => (int) $id]);
            $registro = $consulta->fetch();
            if ($registro === false) {
                errorApi(404, 'Registro no encontrado.');
            }
            responder(200, ['data' => $registro]);
        }

        $pagina = filter_input(INPUT_GET, 'page', FILTER_VALIDATE_INT);
        $porPagina = filter_input(INPUT_GET, 'per_page', FILTER_VALIDATE_INT);
        $pagina = $pagina === false || $pagina === null ? 1 : $pagina;
        $porPagina = $porPagina === false || $porPagina === null ? 50 : $porPagina;
        if ($pagina < 1 || $porPagina < 1 || $porPagina > 100) {
            errorApi(400, 'page debe ser positivo y per_page debe estar entre 1 y 100.');
        }

        $total = (int) $pdo->query("SELECT COUNT(*) FROM $tabla")->fetchColumn();
        $consulta = $pdo->prepare("SELECT $lectura FROM $tabla ORDER BY id LIMIT :limite OFFSET :desplazamiento");
        $consulta->bindValue(':limite', $porPagina, PDO::PARAM_INT);
        $consulta->bindValue(':desplazamiento', ($pagina - 1) * $porPagina, PDO::PARAM_INT);
        $consulta->execute();
        responder(200, [
            'data' => $consulta->fetchAll(),
            'pagination' => ['page' => $pagina, 'per_page' => $porPagina, 'total' => $total],
        ]);
    }

    if ($metodo === 'POST' && $id === null) {
        $datos = leerJson();
        $permitidas = $config['columnas'];
        if (!empty($config['contrasena'])) {
            $permitidas[] = 'contrasena';
        }
        $desconocidas = array_diff(array_keys($datos), $permitidas);
        if ($desconocidas !== []) {
            errorApi(422, 'Campos no permitidos: ' . implode(', ', $desconocidas) . '.');
        }
        if (!empty($config['contrasena'])) {
            if (!isset($datos['contrasena']) || !is_string($datos['contrasena']) || strlen($datos['contrasena']) < 8) {
                errorApi(422, 'contrasena es obligatoria y debe tener al menos 8 caracteres.');
            }
            $datos['contrasena_hash'] = password_hash($datos['contrasena'], PASSWORD_BCRYPT);
            unset($datos['contrasena']);
        }
        validarValores($datos);
        if ($datos === []) {
            errorApi(422, 'Envía al menos un campo para crear el registro.');
        }

        $columnas = array_keys($datos);
        $nombres = implode(', ', $columnas);
        $marcadores = implode(', ', array_map(static fn ($columna) => ':' . $columna, $columnas));
        $consulta = $pdo->prepare("INSERT INTO $tabla ($nombres) VALUES ($marcadores)");
        foreach ($datos as $columna => $valor) {
            $consulta->bindValue(':' . $columna, $valor);
        }
        $consulta->execute();
        $nuevoId = (int) $pdo->lastInsertId();
        $consulta = $pdo->prepare("SELECT $lectura FROM $tabla WHERE id = :id");
        $consulta->execute(['id' => $nuevoId]);
        responder(201, ['data' => $consulta->fetch()]);
    }

    if (in_array($metodo, ['PUT', 'PATCH'], true) && $id !== null) {
        $datos = leerJson();
        $permitidas = $config['columnas'];
        if (!empty($config['contrasena'])) {
            $permitidas[] = 'contrasena';
        }
        $desconocidas = array_diff(array_keys($datos), $permitidas);
        if ($desconocidas !== []) {
            errorApi(422, 'Campos no permitidos: ' . implode(', ', $desconocidas) . '.');
        }
        if (!empty($config['contrasena']) && array_key_exists('contrasena', $datos)) {
            if (!is_string($datos['contrasena']) || strlen($datos['contrasena']) < 8) {
                errorApi(422, 'contrasena debe tener al menos 8 caracteres.');
            }
            $datos['contrasena_hash'] = password_hash($datos['contrasena'], PASSWORD_BCRYPT);
            unset($datos['contrasena']);
        }
        validarValores($datos);
        if ($datos === []) {
            errorApi(422, 'Envía al menos un campo para actualizar el registro.');
        }

        $asignaciones = implode(', ', array_map(static fn ($columna) => "$columna = :$columna", array_keys($datos)));
        $consulta = $pdo->prepare("UPDATE $tabla SET $asignaciones WHERE id = :id");
        foreach ($datos as $columna => $valor) {
            $consulta->bindValue(':' . $columna, $valor);
        }
        $consulta->bindValue(':id', (int) $id, PDO::PARAM_INT);
        $consulta->execute();
        if ($consulta->rowCount() === 0) {
            $existe = $pdo->prepare("SELECT 1 FROM $tabla WHERE id = :id");
            $existe->execute(['id' => (int) $id]);
            if ($existe->fetchColumn() === false) {
                errorApi(404, 'Registro no encontrado.');
            }
        }
        $consulta = $pdo->prepare("SELECT $lectura FROM $tabla WHERE id = :id");
        $consulta->execute(['id' => (int) $id]);
        responder(200, ['data' => $consulta->fetch()]);
    }

    if ($metodo === 'DELETE' && $id !== null) {
        $consulta = $pdo->prepare("DELETE FROM $tabla WHERE id = :id");
        $consulta->execute(['id' => (int) $id]);
        if ($consulta->rowCount() === 0) {
            errorApi(404, 'Registro no encontrado.');
        }
        responder(204);
    }

    $permitidos = match (true) {
        $id === null => ['GET', 'POST'],
        default => ['GET', 'PUT', 'PATCH', 'DELETE'],
    };
    header('Allow: ' . implode(', ', $permitidos));
    errorApi(405, 'Método no permitido para esta ruta.');
} catch (PDOException $error) {
    manejarError($error);
}
