-- =====================================================================
--  Datos de prueba - Concesionario (SQLite)
--  Ejecutar después de schema.sql, sobre una base vacía.
--  Todos los usuarios de prueba tienen la contraseña: Clave123*
--  (se guarda solo el hash bcrypt generado con password_hash()).
-- =====================================================================

PRAGMA foreign_keys = ON;

BEGIN TRANSACTION;

INSERT INTO roles (id, nombre, descripcion) VALUES
    (1, 'administrador', 'Acceso total al sistema'),
    (2, 'gerente',       'Gestiona una sucursal y sus reportes'),
    (3, 'asesor',        'Atiende leads, cotizaciones y ventas'),
    (4, 'tecnico',       'Gestiona órdenes de servicio del taller');

INSERT INTO sucursales (id, nombre, direccion, ciudad, telefono, correo) VALUES
    (1, 'Sede Poblado',  'Cra 43A # 10-50',     'Medellín', '6044441010', 'poblado@concesionario.test'),
    (2, 'Sede Norte',    'Autopista Norte # 120-30', 'Bogotá', '6017452020', 'norte@concesionario.test'),
    (3, 'Sede Sur',      'Calle 5 # 66-12',     'Cali',     '6023303030', 'sur@concesionario.test');

INSERT INTO usuarios (id, rol_id, sucursal_id, nombre, apellido, correo, contrasena_hash, telefono) VALUES
    (1, 1, NULL, 'Ana',    'Restrepo', 'admin@concesionario.test',   '$2y$12$3m98DD2sjynFAcgFjWCiU.eHdb1mKgvi04GCix.agfnlin3CPccPa', '3001112233'),
    (2, 2, 1,    'Carlos', 'Gómez',    'gerente@concesionario.test', '$2y$12$sTNpidVYVFkQ9CPHtCjOYu8yS5adt8zKT6XT8xDTBu7Hyiki7ROqS', '3002223344'),
    (3, 3, 1,    'Laura',  'Mejía',    'laura.mejia@concesionario.test', '$2y$12$oGSCgRvy1dfSeNpAb1UKDO0eFcBzpcocDNB4dsYhTU9P8/A8IdeFK', '3003334455'),
    (4, 3, 2,    'Andrés', 'Pardo',    'andres.pardo@concesionario.test', '$2y$12$XiMppoeXwu8YcLKsk81lcOdrBoMdaH4QECMJOu1bGu4Mcajgma302', '3004445566'),
    (5, 4, 1,    'Jorge',  'Salazar',  'jorge.salazar@concesionario.test', '$2y$12$q/pfXVE/gdQhNJ..q0YAXOaNJKaixTo.8GcSC7FsCLwhJujMWWjDK', '3005556677');

INSERT INTO vehiculos (id, sucursal_id, vin, placa, marca, modelo, anio, version, color, condicion, kilometraje, precio, estado) VALUES
    (1, 1, '9BWZZZ377VT004251', NULL,     'Mazda',      'CX-30',   2026, 'Grand Touring', 'Rojo',   'nuevo', 0,     128900000, 'disponible'),
    (2, 1, '3MZBPACL5NM300112', NULL,     'Mazda',      '3',       2026, 'Touring',       'Gris',   'nuevo', 0,      98500000, 'reservado'),
    (3, 1, 'JTDBR32E720056781', 'HQK421', 'Toyota',     'Corolla', 2022, 'XEI',           'Blanco', 'usado', 41200,  79900000, 'vendido'),
    (4, 2, 'KMHCT41DAEU512345', NULL,     'Hyundai',    'Tucson',  2026, 'Limited',       'Negro',  'nuevo', 0,     149000000, 'disponible'),
    (5, 2, '1N4AL3AP8JC231456', 'JMN872', 'Nissan',     'Kicks',   2021, 'Advance',       'Azul',   'usado', 58300,  64900000, 'disponible'),
    (6, 2, 'VF1RJA00X65432178', NULL,     'Renault',    'Duster',  2026, 'Intens',        'Plata',  'nuevo', 0,      92900000, 'disponible'),
    (7, 3, '9BGKS48U0LB123987', NULL,     'Chevrolet',  'Tracker', 2026, 'Premier',       'Blanco', 'nuevo', 0,     110500000, 'disponible'),
    (8, 3, 'WVWZZZ1KZBW234561', 'FTR339', 'Volkswagen', 'T-Cross', 2023, 'Highline',      'Gris',   'usado', 27500,  89900000, 'vendido');

INSERT INTO clientes (id, tipo_documento, numero_documento, nombre, apellido, correo, telefono, direccion, ciudad) VALUES
    (1, 'CC',  '1037612345', 'María',    'López',   'maria.lopez@correo.test',    '3101234567', 'Calle 10 # 35-20',  'Medellín'),
    (2, 'CC',  '79845123',   'Juan',     'Martínez','juan.martinez@correo.test',  '3112345678', 'Cra 15 # 85-40',    'Bogotá'),
    (3, 'CE',  '654321',     'Sofía',    'Rossi',   'sofia.rossi@correo.test',    '3123456789', 'Av. Roosevelt # 30-11', 'Cali'),
    (4, 'CC',  '1144098765', 'Pedro',    'Ramírez', 'pedro.ramirez@correo.test',  '3134567890', 'Calle 50 # 70-15',  'Medellín'),
    (5, 'NIT', '900123456',  'Transportes Andinos SAS', NULL, 'compras@transandinos.test', '6045556677', 'Zona Industrial Bodega 8', 'Bogotá');

INSERT INTO leads (id, cliente_id, sucursal_id, asesor_id, vehiculo_id, origen, estado, notas) VALUES
    (1, 1, 1, 3, 1,    'app',        'calificado', 'Interesada en CX-30, pregunta por financiación'),
    (2, 2, 2, 4, 4,    'web',        'contactado', 'Solicita test drive de la Tucson'),
    (3, 3, 3, NULL, 7, 'redes',      'nuevo',      'Escribió por Instagram'),
    (4, 4, 1, 3, 3,    'presencial', 'convertido', 'Compró el Corolla usado'),
    (5, 5, 2, 4, 6,    'telefono',   'calificado', 'Flota de 3 Duster para la empresa');

INSERT INTO cotizaciones (id, cliente_id, vehiculo_id, asesor_id, lead_id, precio_base, descuento, total, vigente_hasta, estado) VALUES
    (1, 1, 1, 3, 1, 128900000, 3000000, 125900000, '2026-11-15', 'enviada'),
    (2, 2, 4, 4, 2, 149000000,       0, 149000000, '2026-11-10', 'borrador'),
    (3, 4, 3, 3, 4,  79900000, 1900000,  78000000, '2026-09-30', 'aceptada'),
    (4, 5, 6, 4, 5,  92900000, 4500000,  88400000, '2026-11-20', 'enviada');

INSERT INTO citas (id, cliente_id, sucursal_id, usuario_id, vehiculo_id, tipo, fecha_hora, estado, notas) VALUES
    (1, 2, 2, 4, 4,    'test_drive', '2026-10-18 10:00:00', 'confirmada', 'Traer licencia de conducción'),
    (2, 1, 1, 3, 1,    'asesoria',   '2026-10-16 15:30:00', 'programada', 'Revisar opciones de crédito'),
    (3, 4, 1, 5, 3,    'servicio',   '2026-10-14 08:00:00', 'cumplida',   'Primer mantenimiento post-venta'),
    (4, 3, 3, NULL, 7, 'test_drive', '2026-10-20 11:00:00', 'programada', NULL);

INSERT INTO creditos (id, cliente_id, cotizacion_id, entidad_financiera, monto, cuota_inicial, plazo_meses, tasa_interes, estado) VALUES
    (1, 1, 1, 'Banco de Bogotá',  95900000, 30000000, 60, 1.35, 'en_estudio'),
    (2, 4, 3, 'Bancolombia',      48000000, 30000000, 48, 1.42, 'desembolsado');

INSERT INTO ventas (id, cliente_id, vehiculo_id, asesor_id, sucursal_id, cotizacion_id, credito_id, precio_final, metodo_pago, fecha_venta) VALUES
    (1, 4, 3, 3, 1, 3,    2,    78000000, 'mixto',   '2026-09-25 16:20:00'),
    (2, 3, 8, 4, 3, NULL, NULL, 89900000, 'contado', '2026-08-12 11:45:00');

INSERT INTO ordenes_servicio (id, cliente_id, vehiculo_id, sucursal_id, tecnico_id, cita_id, tipo_servicio, descripcion, kilometraje, estado, costo_total, fecha_ingreso, fecha_entrega) VALUES
    (1, 4, 3, 1, 5, 3,    'mantenimiento', 'Cambio de aceite y filtros, revisión de frenos', 43500, 'terminada',  450000, '2026-10-14 08:15:00', NULL),
    (2, 3, 8, 3, NULL, NULL, 'garantia',   'Ruido en suspensión delantera',               29800, 'abierta',         0, '2026-10-10 09:00:00', NULL),
    (3, 5, 6, 2, NULL, NULL, 'alistamiento', 'Alistamiento previo a entrega de flota',        0, 'en_proceso',      0, '2026-10-12 14:00:00', NULL);

COMMIT;
