-- =====================================================
-- PROCESO DE TRANSFORMACIÓN DE DATOS (ETL)
-- Desde Staging hacia Data Mart
-- =====================================================

USE datamart_jardineria;
GO

-- =====================================================
-- CARGA DE DIMENSIÓN TIEMPO
-- =====================================================

PRINT 'Iniciando carga de dim_tiempo...';

INSERT INTO dim_tiempo (fecha, anio, mes, nombre_mes, trimestre, dia, dia_semana, nombre_dia, semana_anio)
SELECT DISTINCT
    fecha_pedido AS fecha,
    YEAR(fecha_pedido) AS anio,
    MONTH(fecha_pedido) AS mes,
    CASE MONTH(fecha_pedido)
        WHEN 1 THEN 'Enero'
        WHEN 2 THEN 'Febrero'
        WHEN 3 THEN 'Marzo'
        WHEN 4 THEN 'Abril'
        WHEN 5 THEN 'Mayo'
        WHEN 6 THEN 'Junio'
        WHEN 7 THEN 'Julio'
        WHEN 8 THEN 'Agosto'
        WHEN 9 THEN 'Septiembre'
        WHEN 10 THEN 'Octubre'
        WHEN 11 THEN 'Noviembre'
        WHEN 12 THEN 'Diciembre'
    END AS nombre_mes,
    DATEPART(QUARTER, fecha_pedido) AS trimestre,
    DAY(fecha_pedido) AS dia,
    DATEPART(WEEKDAY, fecha_pedido) AS dia_semana,
    CASE DATEPART(WEEKDAY, fecha_pedido)
        WHEN 1 THEN 'Domingo'
        WHEN 2 THEN 'Lunes'
        WHEN 3 THEN 'Martes'
        WHEN 4 THEN 'Miércoles'
        WHEN 5 THEN 'Jueves'
        WHEN 6 THEN 'Viernes'
        WHEN 7 THEN 'Sábado'
    END AS nombre_dia,
    DATEPART(WEEK, fecha_pedido) AS semana_anio
FROM staging_jardineria.dbo.stg_pedido
WHERE fecha_pedido IS NOT NULL;

PRINT 'dim_tiempo cargada: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';

-- =====================================================
-- CARGA DE DIMENSIÓN CLIENTE
-- =====================================================

PRINT 'Iniciando carga de dim_cliente...';

INSERT INTO dim_cliente (id_cliente, nombre_cliente, ciudad, pais, limite_credito, segmento_credito)
SELECT 
    ID_cliente,
    nombre_cliente,
    ISNULL(ciudad, 'No Especificado') AS ciudad,
    ISNULL(pais, 'No Especificado') AS pais,
    ISNULL(limite_credito, 0) AS limite_credito,
    -- Segmentación por límite de crédito
    CASE 
        WHEN limite_credito IS NULL OR limite_credito = 0 THEN 'Sin Crédito'
        WHEN limite_credito < 10000 THEN 'Bajo'
        WHEN limite_credito BETWEEN 10000 AND 50000 THEN 'Medio'
        WHEN limite_credito > 50000 THEN 'Alto'
    END AS segmento_credito
FROM staging_jardineria.dbo.stg_cliente;

PRINT 'dim_cliente cargada: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';

-- =====================================================
-- CARGA DE DIMENSIÓN PRODUCTO
-- =====================================================

PRINT 'Iniciando carga de dim_producto...';

INSERT INTO dim_producto (id_producto, codigo_producto, nombre_producto, categoria, rango_precio)
SELECT 
    p.ID_producto,
    p.CodigoProducto,
    p.nombre AS nombre_producto,
    ISNULL(c.Desc_Categoria, 'Sin Categoría') AS categoria,

    CASE 
        WHEN p.precio_venta < 10 THEN 'Económico'
        WHEN p.precio_venta BETWEEN 10 AND 50 THEN 'Medio'
        WHEN p.precio_venta BETWEEN 50 AND 100 THEN 'Premium'
        WHEN p.precio_venta > 100 THEN 'Lujo'
    END AS rango_precio
FROM staging_jardineria.dbo.stg_producto p
LEFT JOIN staging_jardineria.dbo.stg_categoria_producto c 
    ON p.Categoria = c.Id_Categoria;

PRINT 'dim_producto cargada: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';

-- =====================================================
-- CARGA DE DIMENSIÓN EMPLEADO
-- =====================================================

PRINT 'Iniciando carga de dim_empleado...';

INSERT INTO dim_empleado (id_empleado, nombre_completo, puesto, ciudad_oficina, pais_oficina)
SELECT 
    e.ID_empleado,
    CONCAT(e.nombre, ' ', e.apellido1) AS nombre_completo,
    ISNULL(e.puesto, 'No Especificado') AS puesto,
    ISNULL(o.ciudad, 'No Especificado') AS ciudad_oficina,
    ISNULL(o.pais, 'No Especificado') AS pais_oficina
FROM staging_jardineria.dbo.stg_empleado e
LEFT JOIN staging_jardineria.dbo.stg_oficina o 
    ON e.ID_oficina = o.ID_oficina;

PRINT 'dim_empleado cargada: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';

-- =====================================================
-- CARGA DE DIMENSIÓN ESTADO
-- =====================================================

PRINT 'Iniciando carga de dim_estado...';

INSERT INTO dim_estado (estado, descripcion, tipo_estado)
VALUES 
    ('Entregado', 'Pedido entregado exitosamente', 'Exitoso'),
    ('Pendiente', 'Pedido en proceso de entrega', 'En Proceso'),
    ('Rechazado', 'Pedido rechazado o cancelado', 'Fallido');

PRINT 'dim_estado cargada: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';

-- =====================================================
-- CARGA DE TABLA DE HECHOS
-- =====================================================

PRINT 'Iniciando carga de fact_ventas...';

INSERT INTO fact_ventas (
    sk_tiempo, 
    sk_cliente, 
    sk_producto, 
    sk_empleado, 
    sk_estado,
    id_pedido,
    id_detalle_pedido,
    cantidad,
    precio_unitario,
    monto_linea,
    descuento_aplicado,
    costo_producto,
    margen_bruto
)
SELECT 
    dt.sk_tiempo,
    dc.sk_cliente,
    dp.sk_producto,
    de.sk_empleado,
    des.sk_estado,
    ped.ID_pedido,
    det.ID_detalle_pedido,
    det.cantidad,
    det.precio_unidad AS precio_unitario,
    det.cantidad * det.precio_unidad AS monto_linea,
    0 AS descuento_aplicado, 
    NULL AS costo_producto, 
    NULL AS margen_bruto 
FROM staging_jardineria.dbo.stg_detalle_pedido det
INNER JOIN staging_jardineria.dbo.stg_pedido ped 
    ON det.ID_pedido = ped.ID_pedido
INNER JOIN dim_tiempo dt 
    ON ped.fecha_pedido = dt.fecha
INNER JOIN dim_cliente dc 
    ON ped.ID_cliente = dc.id_cliente
INNER JOIN dim_producto dp 
    ON det.ID_producto = dp.id_producto
LEFT JOIN staging_jardineria.dbo.stg_cliente cli 
    ON ped.ID_cliente = cli.ID_cliente
LEFT JOIN dim_empleado de 
    ON cli.ID_cliente = de.id_empleado 
INNER JOIN dim_estado des 
    ON ped.estado = des.estado;

PRINT 'fact_ventas cargada: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';

-- =====================================================
-- VERIFICACIÓN DE CALIDAD DE DATOS
-- =====================================================

PRINT '';
PRINT '=== VERIFICACIÓN DE CALIDAD ===';

-- Contar registros en cada tabla
SELECT 'dim_tiempo' AS tabla, COUNT(*) AS total_registros FROM dim_tiempo
UNION ALL
SELECT 'dim_cliente', COUNT(*) FROM dim_cliente
UNION ALL
SELECT 'dim_producto', COUNT(*) FROM dim_producto
UNION ALL
SELECT 'dim_empleado', COUNT(*) FROM dim_empleado
UNION ALL
SELECT 'dim_estado', COUNT(*) FROM dim_estado
UNION ALL
SELECT 'fact_ventas', COUNT(*) FROM fact_ventas;

-- Verificar integridad referencial
PRINT '';
PRINT '=== VERIFICACIÓN DE INTEGRIDAD REFERENCIAL ===';

SELECT 
    COUNT(*) AS registros_sin_tiempo
FROM fact_ventas fv
WHERE NOT EXISTS (SELECT 1 FROM dim_tiempo dt WHERE fv.sk_tiempo = dt.sk_tiempo);

SELECT 
    COUNT(*) AS registros_sin_cliente
FROM fact_ventas fv
WHERE NOT EXISTS (SELECT 1 FROM dim_cliente dc WHERE fv.sk_cliente = dc.sk_cliente);

PRINT '';
PRINT 'Proceso de transformación y carga completado exitosamente';
GO