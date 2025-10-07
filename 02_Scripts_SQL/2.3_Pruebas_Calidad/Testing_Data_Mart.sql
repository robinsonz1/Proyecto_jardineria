-- =====================================================
-- SCRIPT DE VALIDACIÓN Y TESTING DEL DATA MART
-- =====================================================

USE datamart_jardineria;
GO

PRINT '╔══════════════════════════════════════════════════════╗';
PRINT '║   VALIDACIÓN Y TESTING DEL DATA MART                ║';
PRINT '╚══════════════════════════════════════════════════════╝';
PRINT '';

-- =====================================================
-- TEST 1: VERIFICAR EXISTENCIA DE OBJETOS
-- =====================================================

PRINT 'TEST 1: Verificando existencia de objetos...';
PRINT '----------------------------------------------------';

DECLARE @missing_objects INT = 0;

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_tiempo')
BEGIN
    PRINT '✗ ERROR: Tabla dim_tiempo no existe';
    SET @missing_objects = @missing_objects + 1;
END
ELSE
    PRINT '✓ dim_tiempo existe';

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_cliente')
BEGIN
    PRINT '✗ ERROR: Tabla dim_cliente no existe';
    SET @missing_objects = @missing_objects + 1;
END
ELSE
    PRINT '✓ dim_cliente existe';

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_producto')
BEGIN
    PRINT '✗ ERROR: Tabla dim_producto no existe';
    SET @missing_objects = @missing_objects + 1;
END
ELSE
    PRINT '✓ dim_producto existe';

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_empleado')
BEGIN
    PRINT '✗ ERROR: Tabla dim_empleado no existe';
    SET @missing_objects = @missing_objects + 1;
END
ELSE
    PRINT '✓ dim_empleado existe';

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'dim_estado')
BEGIN
    PRINT '✗ ERROR: Tabla dim_estado no existe';
    SET @missing_objects = @missing_objects + 1;
END
ELSE
    PRINT '✓ dim_estado existe';

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'fact_ventas')
BEGIN
    PRINT '✗ ERROR: Tabla fact_ventas no existe';
    SET @missing_objects = @missing_objects + 1;
END
ELSE
    PRINT '✓ fact_ventas existe';

IF @missing_objects > 0
BEGIN
    PRINT '';
    PRINT '✗ FALLÓ: ' + CAST(@missing_objects AS VARCHAR) + ' tablas faltantes';
    PRINT 'Ejecute primero el script de creación del Data Mart';
    RETURN;
END

PRINT '✓ APROBADO: Todas las tablas existen';
PRINT '';

-- =====================================================
-- TEST 2: VERIFICAR DATOS CARGADOS
-- =====================================================

PRINT 'TEST 2: Verificando datos cargados...';
PRINT '----------------------------------------------------';

DECLARE @count_tiempo INT, @count_cliente INT, @count_producto INT;
DECLARE @count_empleado INT, @count_estado INT, @count_ventas INT;
DECLARE @empty_tables INT = 0;

SELECT @count_tiempo = COUNT(*) FROM dim_tiempo;
SELECT @count_cliente = COUNT(*) FROM dim_cliente;
SELECT @count_producto = COUNT(*) FROM dim_producto;
SELECT @count_empleado = COUNT(*) FROM dim_empleado;
SELECT @count_estado = COUNT(*) FROM dim_estado;
SELECT @count_ventas = COUNT(*) FROM fact_ventas;

PRINT 'Registros por tabla:';
PRINT '  dim_tiempo    : ' + CAST(@count_tiempo AS VARCHAR);
PRINT '  dim_cliente   : ' + CAST(@count_cliente AS VARCHAR);
PRINT '  dim_producto  : ' + CAST(@count_producto AS VARCHAR);
PRINT '  dim_empleado  : ' + CAST(@count_empleado AS VARCHAR);
PRINT '  dim_estado    : ' + CAST(@count_estado AS VARCHAR);
PRINT '  fact_ventas   : ' + CAST(@count_ventas AS VARCHAR);

IF @count_tiempo = 0 SET @empty_tables = @empty_tables + 1;
IF @count_cliente = 0 SET @empty_tables = @empty_tables + 1;
IF @count_producto = 0 SET @empty_tables = @empty_tables + 1;
IF @count_empleado = 0 SET @empty_tables = @empty_tables + 1;
IF @count_estado = 0 SET @empty_tables = @empty_tables + 1;
IF @count_ventas = 0 SET @empty_tables = @empty_tables + 1;

IF @empty_tables > 0
BEGIN
    PRINT '';
    PRINT '✗ FALLÓ: ' + CAST(@empty_tables AS VARCHAR) + ' tablas están vacías';
    PRINT 'Ejecute el proceso ETL de carga';
END
ELSE
    PRINT '✓ APROBADO: Todas las tablas tienen datos';

PRINT '';

-- =====================================================
-- TEST 3: INTEGRIDAD REFERENCIAL
-- =====================================================

PRINT 'TEST 3: Verificando integridad referencial...';
PRINT '----------------------------------------------------';

DECLARE @orphan_records INT = 0;
DECLARE @orphan_tiempo INT, @orphan_cliente INT, @orphan_producto INT;
DECLARE @orphan_empleado INT, @orphan_estado INT;

-- Verificar FK a dim_tiempo
SELECT @orphan_tiempo = COUNT(*)
FROM fact_ventas fv
WHERE NOT EXISTS (SELECT 1 FROM dim_tiempo dt WHERE fv.sk_tiempo = dt.sk_tiempo);

IF @orphan_tiempo > 0
BEGIN
    PRINT '✗ ERROR: ' + CAST(@orphan_tiempo AS VARCHAR) + ' registros sin referencia a dim_tiempo';
    SET @orphan_records = @orphan_records + @orphan_tiempo;
END
ELSE
    PRINT '✓ Integridad con dim_tiempo OK';

-- Verificar FK a dim_cliente
SELECT @orphan_cliente = COUNT(*)
FROM fact_ventas fv
WHERE NOT EXISTS (SELECT 1 FROM dim_cliente dc WHERE fv.sk_cliente = dc.sk_cliente);

IF @orphan_cliente > 0
BEGIN
    PRINT '✗ ERROR: ' + CAST(@orphan_cliente AS VARCHAR) + ' registros sin referencia a dim_cliente';
    SET @orphan_records = @orphan_records + @orphan_cliente;
END
ELSE
    PRINT '✓ Integridad con dim_cliente OK';

-- Verificar FK a dim_producto
SELECT @orphan_producto = COUNT(*)
FROM fact_ventas fv
WHERE NOT EXISTS (SELECT 1 FROM dim_producto dp WHERE fv.sk_producto = dp.sk_producto);

IF @orphan_producto > 0
BEGIN
    PRINT '✗ ERROR: ' + CAST(@orphan_producto AS VARCHAR) + ' registros sin referencia a dim_producto';
    SET @orphan_records = @orphan_records + @orphan_producto;
END
ELSE
    PRINT '✓ Integridad con dim_producto OK';

-- Verificar FK a dim_estado
SELECT @orphan_estado = COUNT(*)
FROM fact_ventas fv
WHERE NOT EXISTS (SELECT 1 FROM dim_estado de WHERE fv.sk_estado = de.sk_estado);

IF @orphan_estado > 0
BEGIN
    PRINT '✗ ERROR: ' + CAST(@orphan_estado AS VARCHAR) + ' registros sin referencia a dim_estado';
    SET @orphan_records = @orphan_records + @orphan_estado;
END
ELSE
    PRINT '✓ Integridad con dim_estado OK';

IF @orphan_records > 0
    PRINT '✗ FALLÓ: ' + CAST(@orphan_records AS VARCHAR) + ' registros huérfanos encontrados';
ELSE
    PRINT '✓ APROBADO: Integridad referencial correcta';

PRINT '';

-- =====================================================
-- TEST 4: CONSISTENCIA DE DATOS
-- =====================================================

PRINT 'TEST 4: Verificando consistencia de datos...';
PRINT '----------------------------------------------------';

DECLARE @inconsistent_records INT = 0;

-- Verificar que monto_linea = cantidad * precio_unitario
SELECT @inconsistent_records = COUNT(*)
FROM fact_ventas
WHERE ABS(monto_linea - (cantidad * precio_unitario)) > 0.01;

IF @inconsistent_records > 0
    PRINT '✗ ERROR: ' + CAST(@inconsistent_records AS VARCHAR) + ' registros con cálculo incorrecto de monto_linea';
ELSE
    PRINT '✓ Cálculo de monto_linea correcto';

-- Verificar valores negativos
DECLARE @negative_values INT;
SELECT @negative_values = COUNT(*)
FROM fact_ventas
WHERE cantidad < 0 OR precio_unitario < 0 OR monto_linea < 0;

IF @negative_values > 0
BEGIN
    PRINT '✗ ERROR: ' + CAST(@negative_values AS VARCHAR) + ' registros con valores negativos';
    SET @inconsistent_records = @inconsistent_records + @negative_values;
END
ELSE
    PRINT '✓ No hay valores negativos';

-- Verificar fechas válidas
DECLARE @invalid_dates INT;
SELECT @invalid_dates = COUNT(*)
FROM dim_tiempo
WHERE fecha < '2000-01-01' OR fecha > GETDATE();

IF @invalid_dates > 0
BEGIN
    PRINT '✗ ERROR: ' + CAST(@invalid_dates AS VARCHAR) + ' fechas inválidas';
    SET @inconsistent_records = @inconsistent_records + @invalid_dates;
END
ELSE
    PRINT '✓ Todas las fechas son válidas';

IF @inconsistent_records > 0
    PRINT '✗ FALLÓ: ' + CAST(@inconsistent_records AS VARCHAR) + ' inconsistencias encontradas';
ELSE
    PRINT '✓ APROBADO: Datos consistentes';

PRINT '';

-- =====================================================
-- TEST 5: COMPARACIÓN CON ORIGEN
-- =====================================================

PRINT 'TEST 5: Comparando con base de datos origen...';
PRINT '----------------------------------------------------';

DECLARE @origen_detalles INT, @datamart_ventas INT, @diferencia INT;

SELECT @origen_detalles = COUNT(*) FROM jardineria.dbo.detalle_pedido;
SELECT @datamart_ventas = COUNT(*) FROM fact_ventas;
SET @diferencia = @origen_detalles - @datamart_ventas;

PRINT 'Registros en origen     : ' + CAST(@origen_detalles AS VARCHAR);
PRINT 'Registros en Data Mart  : ' + CAST(@datamart_ventas AS VARCHAR);
PRINT 'Diferencia              : ' + CAST(@diferencia AS VARCHAR);

IF @diferencia = 0
    PRINT '✓ APROBADO: Migración completa';
ELSE IF @diferencia > 0
    PRINT '⚠ ADVERTENCIA: Faltan ' + CAST(@diferencia AS VARCHAR) + ' registros';
ELSE
    PRINT '⚠ ADVERTENCIA: Hay ' + CAST(ABS(@diferencia) AS VARCHAR) + ' registros extras';

PRINT '';

-- =====================================================
-- TEST 6: VERIFICAR ÍNDICES
-- =====================================================

PRINT 'TEST 6: Verificando índices...';
PRINT '----------------------------------------------------';

SELECT 
    t.name AS Tabla,
    i.name AS Indice,
    i.type_desc AS Tipo
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
WHERE t.name IN ('fact_ventas', 'dim_tiempo', 'dim_cliente', 'dim_producto', 'dim_empleado', 'dim_estado')
  AND i.name IS NOT NULL
ORDER BY t.name, i.name;

PRINT '✓ Índices listados arriba';
PRINT '';

-- =====================================================
-- TEST 7: QUERIES DE PRUEBA
-- =====================================================

PRINT 'TEST 7: Ejecutando queries de prueba...';
PRINT '----------------------------------------------------';

-- Query 1: Top 5 productos más vendidos
PRINT 'Query 1: Top 5 productos más vendidos';
SELECT TOP 5
    p.nombre_producto,
    SUM(f.cantidad) AS total_vendido
FROM fact_ventas f
INNER JOIN dim_producto p ON f.sk_producto = p.sk_producto
GROUP BY p.nombre_producto
ORDER BY total_vendido DESC;

PRINT '';

-- Query 2: Ventas por mes
PRINT 'Query 2: Total ventas por mes (últimos 3 meses)';
SELECT TOP 3
    t.anio,
    t.mes,
    t.nombre_mes,
    SUM(f.monto_linea) AS ventas_totales
FROM fact_ventas f
INNER JOIN dim_tiempo t ON f.sk_tiempo = t.sk_tiempo
GROUP BY t.anio, t.mes, t.nombre_mes
ORDER BY t.anio DESC, t.mes DESC;

PRINT '';

-- Query 3: Top 3 clientes
PRINT 'Query 3: Top 3 clientes por volumen';
SELECT TOP 3
    c.nombre_cliente,
    SUM(f.monto_linea) AS gasto_total
FROM fact_ventas f
INNER JOIN dim_cliente c ON f.sk_cliente = c.sk_cliente
GROUP BY c.nombre_cliente
ORDER BY gasto_total DESC;

PRINT '';
PRINT '✓ APROBADO: Queries ejecutadas exitosamente';
PRINT '';

-- =====================================================
-- RESUMEN FINAL
-- =====================================================

PRINT '╔══════════════════════════════════════════════════════╗';
PRINT '║              RESUMEN DE VALIDACIÓN                   ║';
PRINT '╚══════════════════════════════════════════════════════╝';
PRINT '';

IF @missing_objects = 0 AND @empty_tables = 0 AND @orphan_records = 0 AND @inconsistent_records = 0
BEGIN
    PRINT '✓✓✓ TODOS LOS TESTS APROBADOS ✓✓✓';
    PRINT '';
    PRINT 'El Data Mart está correctamente implementado y listo para uso.';
END
ELSE
BEGIN
    PRINT '✗✗✗ SE ENCONTRARON ERRORES ✗✗✗';
    PRINT '';
    PRINT 'Por favor revise los mensajes de error arriba y corrija los problemas.';
END

PRINT '';
PRINT 'Fin de validación - ' + CONVERT(VARCHAR, GETDATE(), 120);
GO