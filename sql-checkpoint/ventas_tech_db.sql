/* =====================================================================
   Pre-entrega M3 - Data Analytics
   Base de datos: Ventas_Tech_DB
   Descripción : Base de una distribuidora de tecnología con 4 tablas
                 relacionadas: categorias, clientes, productos y ventas.
   Motor       : SQL Server 2025 Express (ejecutar completo con F5)
   ===================================================================== */

/* ---------------------------------------------------------------------
   1. CREACIÓN DE LA BASE DE DATOS
   Si la base ya existe se elimina y se vuelve a crear, para que el
   script pueda ejecutarse varias veces sin errores.
   --------------------------------------------------------------------- */
USE master;
GO

IF DB_ID(N'Ventas_Tech_DB') IS NOT NULL
BEGIN
    ALTER DATABASE Ventas_Tech_DB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Ventas_Tech_DB;
END;
GO

CREATE DATABASE Ventas_Tech_DB;
GO

USE Ventas_Tech_DB;
GO

/* ---------------------------------------------------------------------
   2. CREACIÓN DE TABLAS
   Orden: primero las tablas maestras (sin dependencias) y después
   las que tienen claves foráneas.
   --------------------------------------------------------------------- */

-- 2.1 Categorías de productos
CREATE TABLE categorias (
    id_categoria      INT            NOT NULL,
    nombre_categoria  NVARCHAR(50)   NOT NULL,
    descripcion       NVARCHAR(200)  NULL,
    CONSTRAINT PK_categorias PRIMARY KEY (id_categoria),
    CONSTRAINT UQ_categorias_nombre UNIQUE (nombre_categoria)
);
GO

-- 2.2 Clientes
CREATE TABLE clientes (
    id_cliente      INT            NOT NULL,
    nombre_cliente  NVARCHAR(100)  NOT NULL,
    segmento        NVARCHAR(30)   NOT NULL,
    email           NVARCHAR(100)  NOT NULL,
    provincia       NVARCHAR(50)   NOT NULL,
    region          NVARCHAR(30)   NOT NULL,
    fecha_alta      DATE           NOT NULL,
    CONSTRAINT PK_clientes PRIMARY KEY (id_cliente),
    CONSTRAINT UQ_clientes_email UNIQUE (email),
    CONSTRAINT CK_clientes_segmento CHECK (segmento IN (N'Corporativo', N'Pyme', N'Consumidor final'))
);
GO

-- 2.3 Productos (cada producto pertenece a una categoría)
CREATE TABLE productos (
    id_producto      INT             NOT NULL,
    nombre_producto  NVARCHAR(100)   NOT NULL,
    id_categoria     INT             NOT NULL,
    marca            NVARCHAR(50)    NOT NULL,
    precio_lista     DECIMAL(12,2)   NOT NULL,
    activo           BIT             NOT NULL CONSTRAINT DF_productos_activo DEFAULT (1),
    CONSTRAINT PK_productos PRIMARY KEY (id_producto),
    CONSTRAINT FK_productos_categorias FOREIGN KEY (id_categoria)
        REFERENCES categorias (id_categoria),
    CONSTRAINT CK_productos_precio CHECK (precio_lista > 0)
);
GO

-- 2.4 Ventas (cada fila es una venta de un producto a un cliente)
--     total_venta se calcula automáticamente: cantidad x precio - descuento
CREATE TABLE ventas (
    id_venta           INT             NOT NULL,
    fecha              DATE            NOT NULL,
    id_cliente         INT             NOT NULL,
    id_producto        INT             NOT NULL,
    cantidad           INT             NOT NULL,
    precio_unitario    DECIMAL(12,2)   NOT NULL,
    descuento_importe  DECIMAL(12,2)   NOT NULL CONSTRAINT DF_ventas_descuento DEFAULT (0),
    total_venta        AS (cantidad * precio_unitario - descuento_importe) PERSISTED,
    estado             NVARCHAR(15)    NOT NULL CONSTRAINT DF_ventas_estado DEFAULT (N'Completada'),
    CONSTRAINT PK_ventas PRIMARY KEY (id_venta),
    CONSTRAINT FK_ventas_clientes FOREIGN KEY (id_cliente)
        REFERENCES clientes (id_cliente),
    CONSTRAINT FK_ventas_productos FOREIGN KEY (id_producto)
        REFERENCES productos (id_producto),
    CONSTRAINT CK_ventas_cantidad CHECK (cantidad > 0),
    CONSTRAINT CK_ventas_precio CHECK (precio_unitario > 0),
    CONSTRAINT CK_ventas_descuento CHECK (descuento_importe >= 0),
    CONSTRAINT CK_ventas_estado CHECK (estado IN (N'Completada', N'Anulada'))
);
GO

/* ---------------------------------------------------------------------
   3. CARGA DE DATOS INICIALES
   --------------------------------------------------------------------- */

-- 3.1 Categorías
INSERT INTO categorias (id_categoria, nombre_categoria, descripcion) VALUES
(1, N'Notebooks',  N'Computadoras portátiles para hogar y empresa'),
(2, N'Celulares',  N'Smartphones de gama media y alta'),
(3, N'Monitores',  N'Monitores LED e IPS de distintas pulgadas'),
(4, N'Accesorios', N'Teclados, mouse, cargadores y periféricos'),
(5, N'Audio',      N'Auriculares y parlantes');
GO

-- 3.2 Clientes
INSERT INTO clientes (id_cliente, nombre_cliente, segmento, email, provincia, region, fecha_alta) VALUES
(1,  N'Soluciones Andinas S.A.',   N'Corporativo',      N'compras@solandinas.com.ar',  N'Mendoza',         N'Cuyo',    '2023-02-15'),
(2,  N'Estudio Contable Ríos',     N'Pyme',             N'admin@estudiorios.com.ar',   N'Córdoba',         N'Centro',  '2023-05-10'),
(3,  N'Martina López',             N'Consumidor final', N'martina.lopez@mail.com',     N'CABA',            N'AMBA',    '2024-01-20'),
(4,  N'Logística del Plata SRL',   N'Corporativo',      N'it@logplata.com.ar',         N'Buenos Aires',    N'AMBA',    '2022-11-03'),
(5,  N'Colegio San Martín',        N'Pyme',             N'secretaria@csmartin.edu.ar', N'Santa Fe',        N'Centro',  '2023-08-28'),
(6,  N'Lucas Fernández',           N'Consumidor final', N'lucas.fernandez@mail.com',   N'Tucumán',         N'NOA',     '2024-03-12'),
(7,  N'AgroNorte Cooperativa',     N'Corporativo',      N'sistemas@agronorte.coop',    N'Salta',           N'NOA',     '2023-06-01'),
(8,  N'Clínica Patagonia',         N'Pyme',             N'compras@clinpatagonia.com',  N'Neuquén',         N'Patagonia','2024-02-05'),
(9,  N'Sofía Gómez',               N'Consumidor final', N'sofia.gomez@mail.com',       N'Córdoba',         N'Centro',  '2024-07-18'),
(10, N'Diseño Urbano Studio',      N'Pyme',             N'hola@disenourbano.com.ar',   N'CABA',            N'AMBA',    '2024-09-09');
GO

-- 3.3 Productos (precios en pesos argentinos)
INSERT INTO productos (id_producto, nombre_producto, id_categoria, marca, precio_lista, activo) VALUES
(1,  N'Notebook IdeaPad Slim 3 15"',      1, N'Lenovo',   950000.00, 1),
(2,  N'Notebook Vivobook 15',             1, N'ASUS',     880000.00, 1),
(3,  N'Notebook Inspiron 14',             1, N'Dell',    1150000.00, 1),
(4,  N'Smartphone Galaxy A55',            2, N'Samsung',  720000.00, 1),
(5,  N'Smartphone Moto G85',              2, N'Motorola', 520000.00, 1),
(6,  N'Smartphone Redmi Note 14',         2, N'Xiaomi',   480000.00, 1),
(7,  N'Monitor 24" IPS Full HD',          3, N'LG',       260000.00, 1),
(8,  N'Monitor 27" Curvo',                3, N'Samsung',  390000.00, 1),
(9,  N'Monitor 22" LED',                  3, N'Philips',  185000.00, 0),
(10, N'Teclado y mouse inalámbrico',      4, N'Logitech',  65000.00, 1),
(11, N'Mouse ergonómico',                 4, N'Logitech',  48000.00, 1),
(12, N'Cargador USB-C 65W',               4, N'Genérico',  35000.00, 1),
(13, N'Auriculares Bluetooth',            5, N'JBL',       95000.00, 1),
(14, N'Parlante portátil',                5, N'JBL',      130000.00, 1),
(15, N'Auriculares con micrófono',        5, N'HyperX',   110000.00, 1);
GO

-- 3.4 Ventas (julio 2025 a septiembre 2026)
INSERT INTO ventas (id_venta, fecha, id_cliente, id_producto, cantidad, precio_unitario, descuento_importe, estado) VALUES
(1,  '2025-07-04', 4,  1,  5,  900000.00, 225000.00, N'Completada'),
(2,  '2025-07-11', 3,  6,  1,  450000.00,      0.00, N'Completada'),
(3,  '2025-07-22', 2,  7,  3,  250000.00,  37500.00, N'Completada'),
(4,  '2025-08-05', 1,  3,  4, 1100000.00, 220000.00, N'Completada'),
(5,  '2025-08-14', 9, 13,  2,   90000.00,      0.00, N'Completada'),
(6,  '2025-08-27', 7,  4,  6,  690000.00, 207000.00, N'Completada'),
(7,  '2025-09-03', 5, 10, 20,   60000.00,  60000.00, N'Completada'),
(8,  '2025-09-18', 6,  5,  1,  500000.00,      0.00, N'Anulada'),
(9,  '2025-09-25', 10, 8,  2,  370000.00,      0.00, N'Completada'),
(10, '2025-10-08', 8,  2,  3,  850000.00,  85000.00, N'Completada'),
(11, '2025-10-21', 3, 14,  1,  125000.00,      0.00, N'Completada'),
(12, '2025-11-06', 4, 11, 15,   45000.00,  33750.00, N'Completada'),
(13, '2025-11-19', 1,  7,  6,  250000.00,  75000.00, N'Completada'),
(14, '2025-12-02', 2,  1,  2,  930000.00,      0.00, N'Completada'),
(15, '2025-12-15', 9,  6,  1,  470000.00,      0.00, N'Completada'),
(16, '2026-01-12', 7, 12, 10,   33000.00,      0.00, N'Completada'),
(17, '2026-01-28', 10, 3, 1, 1150000.00,      0.00, N'Completada'),
(18, '2026-02-09', 5,  2,  4,  860000.00, 172000.00, N'Completada'),
(19, '2026-02-23', 6, 15,  1,  110000.00,      0.00, N'Completada'),
(20, '2026-03-10', 8,  8,  2,  385000.00,      0.00, N'Completada'),
(21, '2026-03-26', 4,  4,  8,  700000.00, 280000.00, N'Completada'),
(22, '2026-04-07', 3,  5,  1,  510000.00,      0.00, N'Completada'),
(23, '2026-04-22', 1, 10, 12,   62000.00,      0.00, N'Completada'),
(24, '2026-05-13', 2, 13,  3,   92000.00,      0.00, N'Completada'),
(25, '2026-05-29', 7,  1,  3,  940000.00,  94000.00, N'Completada'),
(26, '2026-06-16', 9,  7,  1,  255000.00,      0.00, N'Anulada'),
(27, '2026-07-02', 4,  2,  2,  870000.00,      0.00, N'Completada'),
(28, '2026-07-20', 10, 14, 2,  128000.00,      0.00, N'Completada'),
(29, '2026-08-11', 5,  7,  2,  258000.00,      0.00, N'Completada'),
(30, '2026-09-04', 1,  4,  3,  710000.00,  71000.00, N'Completada');
GO

/* ---------------------------------------------------------------------
   4. CONSULTAS DE VERIFICACIÓN
   Confirman que las tablas tienen datos y que las relaciones funcionan.
   --------------------------------------------------------------------- */

-- 4.1 Cantidad de registros por tabla
SELECT N'categorias' AS tabla, COUNT(*) AS registros FROM categorias
UNION ALL
SELECT N'clientes',  COUNT(*) FROM clientes
UNION ALL
SELECT N'productos', COUNT(*) FROM productos
UNION ALL
SELECT N'ventas',    COUNT(*) FROM ventas;
GO

-- 4.2 Detalle de ventas uniendo las 4 tablas
SELECT
    v.id_venta,
    v.fecha,
    c.nombre_cliente,
    c.region,
    p.nombre_producto,
    cat.nombre_categoria,
    v.cantidad,
    v.precio_unitario,
    v.descuento_importe,
    v.total_venta,
    v.estado
FROM ventas AS v
INNER JOIN clientes   AS c   ON v.id_cliente   = c.id_cliente
INNER JOIN productos  AS p   ON v.id_producto  = p.id_producto
INNER JOIN categorias AS cat ON p.id_categoria = cat.id_categoria
ORDER BY v.fecha;
GO

-- 4.3 KPIs básicos (solo ventas completadas)
SELECT
    SUM(total_venta)                              AS ventas_netas,
    COUNT(DISTINCT id_venta)                      AS cantidad_pedidos,
    SUM(total_venta) / COUNT(DISTINCT id_venta)   AS ticket_promedio
FROM ventas
WHERE estado = N'Completada';
GO

-- 4.4 Ventas netas por categoría
SELECT
    cat.nombre_categoria,
    SUM(v.total_venta) AS ventas_netas,
    SUM(v.cantidad)    AS unidades
FROM ventas AS v
INNER JOIN productos  AS p   ON v.id_producto  = p.id_producto
INNER JOIN categorias AS cat ON p.id_categoria = cat.id_categoria
WHERE v.estado = N'Completada'
GROUP BY cat.nombre_categoria
ORDER BY ventas_netas DESC;
GO
