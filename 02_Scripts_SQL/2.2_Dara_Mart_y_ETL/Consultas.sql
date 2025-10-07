-- =====================================================
-- CONSULTAS ANALÍTICAS DEL DATA MART
-- =====================================================

USE datamart_jardineria;
GO

-- =====================================================
-- PRODUCTO MÁS VENDIDO (Por cantidad)
-- =====================================================

PRINT '=== PRODUCTO MÁS VENDIDO POR CANTIDAD ===';
GO

SELECT TOP 10
    dp.codigo_producto,
    dp.nombre_producto,
    dp.categoria,
    dp.rango_precio,
    SUM(fv.cantidad) AS total_unidades_vendidas,
    COUNT(DISTINCT fv.id_pedido) AS numero_pedidos,
    SUM(fv.monto_linea) AS ingresos_totales,
    AVG(fv.precio_unitario) AS precio_promedio
FROM fact_ventas fv
INNER JOIN dim_producto dp ON fv.sk_producto = dp.sk_producto
INNER JOIN dim_estado de ON fv.sk_estado = de.sk_estado
WHERE de.tipo_estado = 'Exitoso' -- Solo pedidos entregados
GROUP BY 
    dp.codigo_producto,
    dp.nombre_producto,
    dp.categoria,
    dp.rango_precio
ORDER BY total_unidades_vendidas DESC;
GO

-- =====================================================
-- PRODUCTO MÁS RENTABLE (Por monto de ventas)
-- =====================================================

PRINT '=== PRODUCTOS MÁS RENTABLES ===';
GO

SELECT TOP 10
    dp.codigo_producto,
    dp.nombre_producto,
    dp.categoria,
    SUM(fv.monto_linea) AS ingresos_totales,
    SUM(fv.cantidad) AS unidades_vendidas,
    AVG(fv.precio_unitario) AS precio_promedio,
    COUNT(DISTINCT fv.sk_cliente) AS clientes_unicos
FROM fact_ventas fv
INNER JOIN dim_producto dp ON fv.sk_producto = dp.sk_producto
INNER JOIN dim_estado de ON fv.sk_estado = de.sk_estado
WHERE de.tipo_estado = 'Exitoso'
GROUP BY 
    dp.codigo_producto,
    dp.nombre_producto,
    dp.categoria
ORDER BY ingresos_totales DESC;
GO

-- =====================================================
-- ANÁLISIS DE VENTAS POR CATEGORÍA
-- =====================================================

PRINT '=== VENTAS POR CATEGORÍA DE PRODUCTO ===';
GO

SELECT 
    dp.categoria,
    COUNT(DISTINCT dp.sk_producto) AS productos_diferentes,
    SUM(fv.cantidad) AS unidades_vendidas,
    SUM(fv.monto_linea) AS ingresos_totales,
    AVG(fv.monto_linea) AS ticket_promedio,
    COUNT(DISTINCT fv.id_pedido) AS total_pedidos
FROM fact_ventas fv
INNER JOIN dim_producto dp ON fv.sk_producto = dp.sk_producto
INNER JOIN dim_estado de ON fv.sk_estado = de.sk_estado
WHERE de.tipo_estado = 'Exitoso'
GROUP BY dp.categoria
ORDER BY ingresos_totales DESC;
GO

-- =====================================================
-- ANÁLISIS TEMPORAL - VENTAS POR MES Y AÑO
-- =====================================================

PRINT '=== EVOLUCIÓN DE VENTAS POR MES Y AÑO ===';
GO

SELECT 
    dt.anio,
    dt.mes,
    dt.nombre_mes,
    COUNT(DISTINCT fv.id_pedido) AS total_pedidos,
    SUM(fv.cantidad) AS unidades_vendidas,
    SUM(fv.monto_linea) AS ingresos_totales,
    AVG(fv.monto_linea) AS ticket_promedio
FROM fact_ventas fv
INNER JOIN dim_tiempo dt ON fv.sk_tiempo = dt.sk_tiempo
INNER JOIN dim_estado de ON fv.sk_estado = de.sk_estado
WHERE de.tipo_estado = 'Exitoso'
GROUP BY 
    dt.anio,
    dt.mes,
    dt.nombre_mes
ORDER BY dt.anio, dt.mes;
GO

-- =====================================================
-- ANÁLISIS POR TRIMESTRE
-- =====================================================

PRINT '=== ANÁLISIS DE VENTAS POR TRIMESTRE ===';
GO

SELECT 
    dt.anio,
    dt.trimestre,
    'Q' + CAST(dt.trimestre AS VARCHAR) AS periodo,
    COUNT(DISTINCT fv.id_pedido) AS total_pedidos,
    SUM(fv.monto_linea) AS ingresos_totales,
    SUM(fv.cantidad) AS unidades_vendidas,
    AVG(fv.monto_linea) AS ticket_promedio
FROM fact_ventas fv
INNER JOIN dim_tiempo dt ON fv.sk_tiempo = dt.sk_tiempo
INNER JOIN dim_estado de ON fv.sk_estado = de.sk_estado
WHERE de.tipo_estado = 'Exitoso'
GROUP BY 
    dt.anio,
    dt.trimestre
ORDER BY dt.anio, dt.trimestre;
GO

-- =====================================================
-- TOP CLIENTES POR VOLUMEN DE COMPRAS
-- =====================================================

PRINT '=== TOP 10 CLIENTES POR VOLUMEN ===';
GO

SELECT TOP 10
    dc.nombre_cliente,
    dc.ciudad,
    dc.pais,
    dc.segmento_credito,
    COUNT(DISTINCT fv.id_pedido) AS total_pedidos,
    SUM(fv.cantidad) AS unidades_compradas,
    SUM(fv.monto_linea) AS gasto_total,
    AVG(fv.monto_linea) AS ticket_promedio,
    MAX(dt.fecha) AS ultima_compra
FROM fact_ventas fv
INNER JOIN dim_cliente dc ON fv.sk_cliente = dc.sk_cliente
INNER JOIN dim_tiempo dt ON fv.sk_tiempo = dt.sk_tiempo
INNER JOIN dim_estado de ON fv.sk_estado = de.sk_estado
WHERE de.tipo_estado = 'Exitoso'
GROUP BY 
    dc.nombre_cliente,
    dc.ciudad,
    dc.pais,
    dc.segmento_credito
ORDER BY gasto_total DESC;
GO

-- =====================================================
-- ANÁLISIS GEOGRÁFICO - VENTAS POR PAÍS
-- =====================================================

PRINT '=== VENTAS POR PAÍS ===';
GO

SELECT 
    dc.pais,
    COUNT(DISTINCT dc.sk_cliente) AS total_clientes,
    COUNT(DISTINCT fv.id_pedido) AS total_pedidos,
    SUM(fv.cantidad) AS unidades_vendidas,
    SUM(fv.monto_linea) AS ingresos_totales,
    AVG(fv.monto_linea) AS ticket_promedio
FROM fact_ventas fv
INNER JOIN dim_cliente dc ON fv.sk_cliente = dc.sk_cliente
INNER JOIN dim_estado de ON fv.sk_estado = de.sk_estado
WHERE de.tipo_estado = 'Exitoso'
GROUP BY dc.pais
ORDER BY ingresos_totales DESC;
GO

-- =====================================================
-- ANÁLISIS DE ESTADOS DE PEDIDOS
-- =====================================================

PRINT '=== DISTRIBUCIÓN DE ESTADOS DE PEDIDOS ===';
GO

SELECT 
    de.estado,
    de.tipo_estado,
    COUNT(DISTINCT fv.id_pedido) AS total_pedidos,
    SUM(fv.cantidad) AS unidades,
    SUM(fv.monto_linea) AS monto_total,
    CAST(COUNT(DISTINCT fv.id_pedido) * 100.0 / 
        (SELECT COUNT(DISTINCT id_pedido) FROM fact_ventas) AS DECIMAL(5,2)) AS porcentaje
FROM fact_ventas fv
INNER JOIN dim_estado de ON fv.sk_estado = de.sk_estado
GROUP BY 
    de.estado,
    de.tipo_estado
ORDER BY total_pedidos DESC;
GO

-- =====================================================
-- ANÁLISIS DE DESEMPEÑO POR EMPLEADO
-- =====================================================

PRINT '=== DESEMPEÑO DE EMPLEADOS (TOP 10) ===';
GO

SELECT TOP 10
    de.nombre_completo,
    de.puesto,
    de.ciudad_oficina,
    de.pais_oficina,
    COUNT(DISTINCT fv.sk_cliente) AS clientes_atendidos,
    COUNT(DISTINCT fv.id_pedido) AS pedidos_gestionados,
    SUM(fv.monto_linea) AS ventas_totales,
    AVG(fv.monto_linea) AS ticket_promedio
FROM fact_ventas fv
INNER JOIN dim_empleado de ON fv.sk_empleado = de.sk_empleado
INNER JOIN dim_estado des ON fv.sk_estado = des.sk_estado
WHERE des.tipo_estado = 'Exitoso'
GROUP BY 
    de.nombre_completo,
    de.puesto,
    de.ciudad_oficina,
    de.pais_oficina
ORDER BY ventas_totales DESC;
GO

-- =====================================================
-- ANÁLISIS DE SEGMENTACIÓN DE CLIENTES
-- =====================================================

PRINT '=== ANÁLISIS POR SEGMENTO DE CRÉDITO ===';
GO

SELECT 
    dc.segmento_credito,
    COUNT(DISTINCT dc.sk_cliente) AS total_clientes,
    SUM(fv.monto_linea) AS ingresos_totales,
    AVG(fv.monto_linea) AS ticket_promedio,
    AVG(dc.limite_credito) AS credito_promedio,
    SUM(fv.cantidad) AS unidades_vendidas
FROM fact_ventas fv
INNER JOIN dim_cliente dc ON fv.sk_cliente = dc.sk_cliente
INNER JOIN dim_estado de ON fv.sk_estado = de.sk_estado
WHERE de.tipo_estado = 'Exitoso'
GROUP BY dc.segmento_credito
ORDER BY ingresos_totales DESC;
GO

-- =====================================================
--TENDENCIA DE VENTAS - CRECIMIENTO MENSUAL
-- =====================================================

PRINT '=== CRECIMIENTO MENSUAL DE VENTAS ===';
GO

WITH ventas_mensuales AS (
    SELECT 
        dt.anio,
        dt.mes,
        dt.nombre_mes,
        SUM(fv.monto_linea) AS ingresos
    FROM fact_ventas fv
    INNER JOIN dim_tiempo dt ON fv.sk_tiempo = dt.sk_tiempo
    INNER JOIN dim_estado de ON fv.sk_estado = de.sk_estado
    WHERE de.tipo_estado = 'Exitoso'
    GROUP BY dt.anio, dt.mes, dt.nombre_mes
)
SELECT 
    anio,
    mes,
    nombre_mes,
    ingresos,
    LAG(ingresos) OVER (ORDER BY anio, mes) AS ingresos_mes_anterior,
    ingresos - LAG(ingresos) OVER (ORDER BY anio, mes) AS diferencia,
    CASE 
        WHEN LAG(ingresos) OVER (ORDER BY anio, mes) IS NOT NULL 
        THEN CAST((ingresos - LAG(ingresos) OVER (ORDER BY anio, mes)) * 100.0 / 
                  LAG(ingresos) OVER (ORDER BY anio, mes) AS DECIMAL(10,2))
        ELSE NULL
    END AS porcentaje_crecimiento
FROM ventas_mensuales
ORDER BY anio, mes;
GO

PRINT '';
PRINT 'Todas las consultas analíticas ejecutadas exitosamente';
GO