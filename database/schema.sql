-- =====================================================================
--  Esquema de base de datos - Concesionario (SQLite)
--  Ejecutar sobre una base vacía o existente: borra y recrea las tablas.
-- =====================================================================

PRAGMA foreign_keys = OFF;

DROP TABLE IF EXISTS ordenes_servicio;
DROP TABLE IF EXISTS ventas;
DROP TABLE IF EXISTS creditos;
DROP TABLE IF EXISTS citas;
DROP TABLE IF EXISTS cotizaciones;
DROP TABLE IF EXISTS leads;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS vehiculos;
DROP TABLE IF EXISTS usuarios;
DROP TABLE IF EXISTS sucursales;
DROP TABLE IF EXISTS roles;

-- Las llaves foráneas en SQLite deben activarse en cada conexión.
PRAGMA foreign_keys = ON;

-- ---------------------------------------------------------------------
-- Roles del sistema (administrador, gerente, asesor, técnico...)
-- ---------------------------------------------------------------------
CREATE TABLE roles (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre       TEXT    NOT NULL UNIQUE COLLATE NOCASE,
    descripcion  TEXT
);

-- ---------------------------------------------------------------------
-- Sucursales del concesionario
-- ---------------------------------------------------------------------
CREATE TABLE sucursales (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre     TEXT    NOT NULL,
    direccion  TEXT    NOT NULL,
    ciudad     TEXT    NOT NULL,
    telefono   TEXT,
    correo     TEXT    UNIQUE COLLATE NOCASE,
    activa     INTEGER NOT NULL DEFAULT 1 CHECK (activa IN (0, 1)),
    creado_en  TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------
-- Usuarios internos (empleados). La contraseña se guarda como hash
-- bcrypt generado con password_hash(); nunca en texto plano.
-- ---------------------------------------------------------------------
CREATE TABLE usuarios (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    rol_id           INTEGER NOT NULL REFERENCES roles(id),
    sucursal_id      INTEGER REFERENCES sucursales(id),
    nombre           TEXT    NOT NULL,
    apellido         TEXT    NOT NULL,
    correo           TEXT    NOT NULL UNIQUE COLLATE NOCASE,
    contrasena_hash  TEXT    NOT NULL CHECK (contrasena_hash LIKE '$2y$%'),
    telefono         TEXT,
    activo           INTEGER NOT NULL DEFAULT 1 CHECK (activo IN (0, 1)),
    creado_en        TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------
-- Inventario de vehículos
-- ---------------------------------------------------------------------
CREATE TABLE vehiculos (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    sucursal_id  INTEGER NOT NULL REFERENCES sucursales(id),
    vin          TEXT    NOT NULL UNIQUE COLLATE NOCASE,
    placa        TEXT    UNIQUE COLLATE NOCASE,
    marca        TEXT    NOT NULL,
    modelo       TEXT    NOT NULL,
    anio         INTEGER NOT NULL CHECK (anio BETWEEN 1950 AND 2100),
    version      TEXT,
    color        TEXT,
    condicion    TEXT    NOT NULL DEFAULT 'nuevo'
                         CHECK (condicion IN ('nuevo', 'usado')),
    kilometraje  INTEGER NOT NULL DEFAULT 0 CHECK (kilometraje >= 0),
    precio       REAL    NOT NULL CHECK (precio >= 0),
    estado       TEXT    NOT NULL DEFAULT 'disponible'
                         CHECK (estado IN ('disponible', 'reservado', 'vendido')),
    creado_en    TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------
-- Clientes
-- ---------------------------------------------------------------------
CREATE TABLE clientes (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo_documento    TEXT    NOT NULL CHECK (tipo_documento IN ('CC', 'CE', 'NIT', 'PASAPORTE')),
    numero_documento  TEXT    NOT NULL,
    nombre            TEXT    NOT NULL,
    apellido          TEXT,
    correo            TEXT    NOT NULL UNIQUE COLLATE NOCASE,
    telefono          TEXT,
    direccion         TEXT,
    ciudad            TEXT,
    creado_en         TEXT    NOT NULL DEFAULT (datetime('now')),
    UNIQUE (tipo_documento, numero_documento)
);

-- ---------------------------------------------------------------------
-- Leads (prospectos / oportunidades de venta)
-- ---------------------------------------------------------------------
CREATE TABLE leads (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    cliente_id   INTEGER NOT NULL REFERENCES clientes(id),
    sucursal_id  INTEGER NOT NULL REFERENCES sucursales(id),
    asesor_id    INTEGER REFERENCES usuarios(id),
    vehiculo_id  INTEGER REFERENCES vehiculos(id),
    origen       TEXT    NOT NULL CHECK (origen IN ('app', 'web', 'presencial', 'telefono', 'referido', 'redes')),
    estado       TEXT    NOT NULL DEFAULT 'nuevo'
                         CHECK (estado IN ('nuevo', 'contactado', 'calificado', 'convertido', 'perdido')),
    notas        TEXT,
    creado_en    TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------
-- Cotizaciones
-- ---------------------------------------------------------------------
CREATE TABLE cotizaciones (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    cliente_id      INTEGER NOT NULL REFERENCES clientes(id),
    vehiculo_id     INTEGER NOT NULL REFERENCES vehiculos(id),
    asesor_id       INTEGER NOT NULL REFERENCES usuarios(id),
    lead_id         INTEGER REFERENCES leads(id),
    precio_base     REAL    NOT NULL CHECK (precio_base >= 0),
    descuento       REAL    NOT NULL DEFAULT 0 CHECK (descuento >= 0),
    total           REAL    NOT NULL CHECK (total >= 0),
    vigente_hasta   TEXT    NOT NULL,
    estado          TEXT    NOT NULL DEFAULT 'enviada'
                            CHECK (estado IN ('borrador', 'enviada', 'aceptada', 'rechazada', 'vencida')),
    creado_en       TEXT    NOT NULL DEFAULT (datetime('now')),
    CHECK (descuento <= precio_base)
);

-- ---------------------------------------------------------------------
-- Citas (test drive, asesoría, servicio)
-- ---------------------------------------------------------------------
CREATE TABLE citas (
    id           INTEGER PRIMARY KEY AUTOINCREMENT,
    cliente_id   INTEGER NOT NULL REFERENCES clientes(id),
    sucursal_id  INTEGER NOT NULL REFERENCES sucursales(id),
    usuario_id   INTEGER REFERENCES usuarios(id),
    vehiculo_id  INTEGER REFERENCES vehiculos(id),
    tipo         TEXT    NOT NULL CHECK (tipo IN ('test_drive', 'asesoria', 'servicio', 'entrega')),
    fecha_hora   TEXT    NOT NULL,
    estado       TEXT    NOT NULL DEFAULT 'programada'
                         CHECK (estado IN ('programada', 'confirmada', 'cumplida', 'cancelada', 'no_asistio')),
    notas        TEXT,
    creado_en    TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------
-- Créditos / financiación
-- ---------------------------------------------------------------------
CREATE TABLE creditos (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    cliente_id          INTEGER NOT NULL REFERENCES clientes(id),
    cotizacion_id       INTEGER NOT NULL REFERENCES cotizaciones(id),
    entidad_financiera  TEXT    NOT NULL,
    monto               REAL    NOT NULL CHECK (monto > 0),
    cuota_inicial       REAL    NOT NULL DEFAULT 0 CHECK (cuota_inicial >= 0),
    plazo_meses         INTEGER NOT NULL CHECK (plazo_meses > 0),
    tasa_interes        REAL    NOT NULL CHECK (tasa_interes >= 0),
    estado              TEXT    NOT NULL DEFAULT 'solicitado'
                                CHECK (estado IN ('solicitado', 'en_estudio', 'aprobado', 'rechazado', 'desembolsado')),
    creado_en           TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------
-- Ventas. Un vehículo solo puede venderse una vez.
-- ---------------------------------------------------------------------
CREATE TABLE ventas (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    cliente_id     INTEGER NOT NULL REFERENCES clientes(id),
    vehiculo_id    INTEGER NOT NULL UNIQUE REFERENCES vehiculos(id),
    asesor_id      INTEGER NOT NULL REFERENCES usuarios(id),
    sucursal_id    INTEGER NOT NULL REFERENCES sucursales(id),
    cotizacion_id  INTEGER REFERENCES cotizaciones(id),
    credito_id     INTEGER REFERENCES creditos(id),
    precio_final   REAL    NOT NULL CHECK (precio_final >= 0),
    metodo_pago    TEXT    NOT NULL CHECK (metodo_pago IN ('contado', 'credito', 'mixto')),
    fecha_venta    TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ---------------------------------------------------------------------
-- Órdenes de servicio (taller)
-- ---------------------------------------------------------------------
CREATE TABLE ordenes_servicio (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    cliente_id        INTEGER NOT NULL REFERENCES clientes(id),
    vehiculo_id       INTEGER NOT NULL REFERENCES vehiculos(id),
    sucursal_id       INTEGER NOT NULL REFERENCES sucursales(id),
    tecnico_id        INTEGER REFERENCES usuarios(id),
    cita_id           INTEGER REFERENCES citas(id),
    tipo_servicio     TEXT    NOT NULL CHECK (tipo_servicio IN ('mantenimiento', 'reparacion', 'garantia', 'alistamiento')),
    descripcion       TEXT    NOT NULL,
    kilometraje       INTEGER CHECK (kilometraje >= 0),
    estado            TEXT    NOT NULL DEFAULT 'abierta'
                              CHECK (estado IN ('abierta', 'en_proceso', 'terminada', 'entregada', 'cancelada')),
    costo_total       REAL    NOT NULL DEFAULT 0 CHECK (costo_total >= 0),
    fecha_ingreso     TEXT    NOT NULL DEFAULT (datetime('now')),
    fecha_entrega     TEXT
);

-- ---------------------------------------------------------------------
-- Índices sobre llaves foráneas (SQLite no los crea automáticamente)
-- ---------------------------------------------------------------------
CREATE INDEX idx_usuarios_rol            ON usuarios(rol_id);
CREATE INDEX idx_usuarios_sucursal       ON usuarios(sucursal_id);
CREATE INDEX idx_vehiculos_sucursal      ON vehiculos(sucursal_id);
CREATE INDEX idx_leads_cliente           ON leads(cliente_id);
CREATE INDEX idx_leads_asesor            ON leads(asesor_id);
CREATE INDEX idx_cotizaciones_cliente    ON cotizaciones(cliente_id);
CREATE INDEX idx_cotizaciones_vehiculo   ON cotizaciones(vehiculo_id);
CREATE INDEX idx_citas_cliente           ON citas(cliente_id);
CREATE INDEX idx_citas_fecha             ON citas(fecha_hora);
CREATE INDEX idx_creditos_cliente        ON creditos(cliente_id);
CREATE INDEX idx_ventas_cliente          ON ventas(cliente_id);
CREATE INDEX idx_ordenes_cliente         ON ordenes_servicio(cliente_id);
CREATE INDEX idx_ordenes_vehiculo        ON ordenes_servicio(vehiculo_id);
