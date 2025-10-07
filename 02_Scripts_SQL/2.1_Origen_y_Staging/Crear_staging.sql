CREATE DATABASE staging_jardineria;
GO
USE staging_jardineria;
GO
CREATE TABLE stg_oficina (
  ID_oficina INT PRIMARY KEY,
  ciudad VARCHAR(50),
  pais VARCHAR(50),
  codigo_postal VARCHAR(10)
);
CREATE TABLE stg_empleado (
  ID_empleado INT PRIMARY KEY,
  nombre VARCHAR(50),
  apellido1 VARCHAR(50),
  ID_oficina INT,
  puesto VARCHAR(50)
);
CREATE TABLE stg_cliente (
  ID_cliente INT PRIMARY KEY,
  nombre_cliente VARCHAR(50),
  ciudad VARCHAR(50),
  pais VARCHAR(50),
  limite_credito NUMERIC(15,2)
);
CREATE TABLE stg_pedido (
  ID_pedido INT PRIMARY KEY,
  fecha_pedido DATE,
  estado VARCHAR(15),
  ID_cliente INT
);
CREATE TABLE stg_detalle_pedido (
  ID_detalle_pedido INT PRIMARY KEY,
  ID_pedido INT,
  ID_producto INT,
  cantidad INT,
  precio_unidad NUMERIC(15,2)
);
CREATE TABLE stg_producto (
  ID_producto INT PRIMARY KEY,
  CodigoProducto VARCHAR(15),
  nombre VARCHAR(70),
  Categoria INT,
  precio_venta NUMERIC(15,2)
);
CREATE TABLE stg_categoria_producto (
  Id_Categoria INT PRIMARY KEY,
  Desc_Categoria VARCHAR(50)
);
CREATE TABLE stg_pago (
  ID_pago INT PRIMARY KEY,
  ID_cliente INT,
  forma_pago VARCHAR(40),
  fecha_pago DATE,
  total NUMERIC(15,2)
);
GO
