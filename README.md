# API Concesionario — PHP + SQLite

Backend en **PHP + SQLite** para la app móvil. `index.php` en la raíz pública es el punto de entrada para Apache; delega la API a `api/index.php`. La base de datos es un único archivo (`data/app.db`).

Incluye endpoints REST JSON para consultar, crear, actualizar y eliminar registros de las 11 tablas. Los endpoints no tienen autenticación y están pensados únicamente para desarrollo local.

## Requisitos

- PHP 8.1 o superior con la extensión `pdo_sqlite` activa.
  En Windows, descomentar en `php.ini`: `extension=pdo_sqlite`
  (o ejecutar los comandos con `php -d extension=pdo_sqlite ...`).
- Apache con `mod_rewrite` habilitado para que funcionen las rutas limpias.

## Crear la base de datos

```bash
php database/setup.php           # solo crea las tablas
php database/setup.php --seed    # crea las tablas y carga los datos de prueba
```

El script borra y recrea las tablas, así que todo el equipo parte de la misma estructura.

## Verificar los criterios de aceptación

```bash
php database/test_criterios.php
```

Usa una base temporal (no toca `data/app.db`) y comprueba:

1. El script crea las 11 tablas sin errores.
2. Sobre una base vacía, los datos de prueba crean usuarios, vehículos, clientes y sucursales.
3. Se rechaza guardar un registro cuya relación no existe (llaves foráneas).
4. Reglas: correos únicos (sin distinguir mayúsculas) y contraseñas guardadas solo como hash bcrypt.

## Ejecutar la API localmente

Primero crea la base de datos con datos de prueba:

```bash
php database/setup.php --seed
```

Luego inicia el servidor PHP desde la raíz del proyecto:

```bash
php -S 127.0.0.1:8000 -t . api/router.php
```

La API queda disponible en `http://127.0.0.1:8000/api`. Debe habilitarse `pdo_sqlite` en PHP.

## Desplegar en InfinityFree

1. Confirma primero que tu cuenta de InfinityFree tenga habilitada la extensión PHP `pdo_sqlite`/SQLite. Este proyecto guarda los datos en SQLite y no funcionará allí si el proveedor no habilita esa extensión.
2. Sube el contenido del proyecto a la carpeta pública `htdocs`, conservando la estructura de carpetas. `index.php` y `.htaccess` deben quedar directamente en `htdocs`.
3. No ejecutes `database/setup.php --seed` desde el navegador: ese comando borra y recrea las tablas. Prepara `data/app.db` localmente con los scripts y sube el archivo; conserva también los `.htaccess` que protegen `data/` y `database/`.
4. Abre `https://tu-dominio/api/health`. Si responde `{"status":"ok","database":"connected"}`, la API y la conexión SQLite están disponibles.

El hosting compartido puede no permitir SQLite o escrituras en archivos. Si `/api/health` falla por falta del controlador SQLite o permisos de escritura, habrá que pedir confirmación al proveedor o migrar el almacenamiento a MySQL, si ese motor está disponible en la cuenta.

### Endpoints

| Método | Ruta | Acción |
|--------|------|--------|
| GET | `/api/health` | Comprueba que la API y SQLite respondan |
| GET | `/api/{recurso}` | Lista registros (paginación con `page` y `per_page`, máximo 100) |
| GET | `/api/{recurso}/{id}` | Consulta un registro |
| POST | `/api/{recurso}` | Crea un registro con JSON |
| PUT / PATCH | `/api/{recurso}/{id}` | Actualiza los campos enviados con JSON |
| DELETE | `/api/{recurso}/{id}` | Elimina un registro |

Los recursos disponibles son `roles`, `sucursales`, `usuarios`, `vehiculos`, `clientes`, `leads`, `cotizaciones`, `citas`, `creditos`, `ventas` y `ordenes-servicio`.

Ejemplos:

```bash
curl http://127.0.0.1:8000/api/vehiculos
curl http://127.0.0.1:8000/api/clientes/1
curl -X POST http://127.0.0.1:8000/api/clientes \
  -H "Content-Type: application/json" \
  -d "{\"tipo_documento\":\"CC\",\"numero_documento\":\"123456789\",\"nombre\":\"Ana\",\"correo\":\"ana@example.test\"}"
```

Las respuestas de colección incluyen `data` y `pagination`. Si se crea un usuario, el JSON debe incluir `contrasena`; se guarda como bcrypt y nunca se devuelve el hash. Las restricciones de la base de datos protegen las relaciones, valores permitidos y correos/documentos únicos. Los errores responden en JSON con códigos HTTP `400`, `404`, `409` o `422`, según el caso.

**Importante:** esta API no autentica usuarios ni restringe operaciones por rol; no se debe exponer a Internet ni utilizar con datos reales hasta implementar autenticación y autorización.

## Usuarios de prueba

Todos tienen la contraseña `Clave123*`.

| Correo                              | Rol           | Sucursal     |
|-------------------------------------|---------------|--------------|
| admin@concesionario.test            | administrador | —            |
| gerente@concesionario.test          | gerente       | Sede Poblado |
| laura.mejia@concesionario.test      | asesor        | Sede Poblado |
| andres.pardo@concesionario.test     | asesor        | Sede Norte   |
| jorge.salazar@concesionario.test    | técnico       | Sede Poblado |

## Estructura

```
api-movil/
├── index.php                 # punto de entrada Apache en la raíz pública
├── .htaccess                 # reescritura de rutas REST
├── db.php                    # conexión PDO (activa las llaves foráneas)
├── api/
│   ├── index.php             # endpoints REST JSON para las 11 tablas
│   ├── router.php            # router del servidor PHP local
│   └── .htaccess             # rutas limpias en Apache
├── data/app.db               # base de datos (se genera con setup.php)
├── database/
│   ├── schema.sql            # tablas, relaciones, restricciones e índices
│   ├── seed.sql              # datos de prueba
│   ├── setup.php             # crea la base
│   └── test_criterios.php    # verifica los criterios de aceptación
└── docs/diagrama-er.md       # diagrama entidad-relación (Mermaid)
```

## Notas para el equipo

- **Llaves foráneas:** SQLite solo las valida si se ejecuta `PRAGMA foreign_keys = ON` en cada conexión. `db.php` ya lo hace, así que toda conexión debe pasar por `db()`.
- **Contraseñas:** guardarlas siempre con `password_hash($clave, PASSWORD_BCRYPT)` y validarlas con `password_verify()`. La tabla rechaza valores que no sean un hash bcrypt.
- **Despliegue:** las carpetas `data/` y `database/` tienen un `.htaccess` que bloquea el acceso desde el navegador. En Nginx hay que bloquearlas en la configuración del servidor.
