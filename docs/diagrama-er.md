# Diagrama entidad-relación

Se visualiza directamente en GitHub, GitLab o VS Code (extensión *Markdown Preview Mermaid Support*).
También se puede pegar en https://mermaid.live para exportarlo como PNG/SVG.

```mermaid
erDiagram
    ROLES ||--o{ USUARIOS : "asigna"
    SUCURSALES |o--o{ USUARIOS : "emplea"
    SUCURSALES ||--o{ VEHICULOS : "tiene en inventario"

    CLIENTES ||--o{ LEADS : "genera"
    SUCURSALES ||--o{ LEADS : "recibe"
    USUARIOS |o--o{ LEADS : "atiende (asesor)"
    VEHICULOS |o--o{ LEADS : "interesa"

    CLIENTES ||--o{ COTIZACIONES : "solicita"
    VEHICULOS ||--o{ COTIZACIONES : "se cotiza"
    USUARIOS ||--o{ COTIZACIONES : "elabora (asesor)"
    LEADS |o--o{ COTIZACIONES : "origina"

    CLIENTES ||--o{ CITAS : "agenda"
    SUCURSALES ||--o{ CITAS : "se realiza en"
    USUARIOS |o--o{ CITAS : "atiende"
    VEHICULOS |o--o{ CITAS : "involucra"

    CLIENTES ||--o{ CREDITOS : "solicita"
    COTIZACIONES ||--o{ CREDITOS : "financia"

    CLIENTES ||--o{ VENTAS : "compra"
    VEHICULOS ||--o| VENTAS : "se vende una vez"
    USUARIOS ||--o{ VENTAS : "cierra (asesor)"
    SUCURSALES ||--o{ VENTAS : "registra"
    COTIZACIONES |o--o{ VENTAS : "se concreta en"
    CREDITOS |o--o{ VENTAS : "paga"

    CLIENTES ||--o{ ORDENES_SERVICIO : "solicita"
    VEHICULOS ||--o{ ORDENES_SERVICIO : "recibe servicio"
    SUCURSALES ||--o{ ORDENES_SERVICIO : "taller"
    USUARIOS |o--o{ ORDENES_SERVICIO : "ejecuta (técnico)"
    CITAS |o--o{ ORDENES_SERVICIO : "origina"

    ROLES {
        int id PK
        text nombre UK
        text descripcion
    }
    SUCURSALES {
        int id PK
        text nombre
        text direccion
        text ciudad
        text telefono
        text correo UK
        int activa
    }
    USUARIOS {
        int id PK
        int rol_id FK
        int sucursal_id FK
        text nombre
        text apellido
        text correo UK
        text contrasena_hash "bcrypt"
        text telefono
        int activo
    }
    VEHICULOS {
        int id PK
        int sucursal_id FK
        text vin UK
        text placa UK
        text marca
        text modelo
        int anio
        text condicion "nuevo | usado"
        int kilometraje
        real precio
        text estado "disponible | reservado | vendido"
    }
    CLIENTES {
        int id PK
        text tipo_documento
        text numero_documento
        text nombre
        text apellido
        text correo UK
        text telefono
        text ciudad
    }
    LEADS {
        int id PK
        int cliente_id FK
        int sucursal_id FK
        int asesor_id FK
        int vehiculo_id FK
        text origen
        text estado
        text notas
    }
    COTIZACIONES {
        int id PK
        int cliente_id FK
        int vehiculo_id FK
        int asesor_id FK
        int lead_id FK
        real precio_base
        real descuento
        real total
        text vigente_hasta
        text estado
    }
    CITAS {
        int id PK
        int cliente_id FK
        int sucursal_id FK
        int usuario_id FK
        int vehiculo_id FK
        text tipo
        text fecha_hora
        text estado
    }
    CREDITOS {
        int id PK
        int cliente_id FK
        int cotizacion_id FK
        text entidad_financiera
        real monto
        real cuota_inicial
        int plazo_meses
        real tasa_interes
        text estado
    }
    VENTAS {
        int id PK
        int cliente_id FK
        int vehiculo_id FK,UK
        int asesor_id FK
        int sucursal_id FK
        int cotizacion_id FK
        int credito_id FK
        real precio_final
        text metodo_pago
        text fecha_venta
    }
    ORDENES_SERVICIO {
        int id PK
        int cliente_id FK
        int vehiculo_id FK
        int sucursal_id FK
        int tecnico_id FK
        int cita_id FK
        text tipo_servicio
        text descripcion
        int kilometraje
        text estado
        real costo_total
    }
```
