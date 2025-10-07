USE staging_jardineria;
GO
INSERT INTO stg_oficina
SELECT ID_oficina, ciudad, pais, codigo_postal
FROM jardineria.dbo.oficina;
INSERT INTO stg_empleado
SELECT ID_empleado, nombre, apellido1, ID_oficina, puesto
FROM jardineria.dbo.empleado;
INSERT INTO stg_cliente
SELECT ID_cliente, nombre_cliente, ciudad, pais, limite_credito
FROM jardineria.dbo.cliente;
INSERT INTO stg_pedido
SELECT ID_pedido, fecha_pedido, estado, ID_cliente
FROM jardineria.dbo.pedido;
INSERT INTO stg_detalle_pedido
SELECT ID_detalle_pedido, ID_pedido, ID_producto, cantidad, precio_unidad
FROM jardineria.dbo.detalle_pedido;
INSERT INTO stg_producto
SELECT ID_producto, CodigoProducto, nombre, Categoria, precio_venta
FROM jardineria.dbo.producto;
INSERT INTO stg_categoria_producto
SELECT Id_Categoria, Desc_Categoria
FROM jardineria.dbo.Categoria_producto;
INSERT INTO stg_pago
SELECT ID_pago, ID_cliente, forma_pago, fecha_pago, total
FROM jardineria.dbo.pago;
GO