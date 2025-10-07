PRINT 'PUNTAJE DE CALIDAD GENERAL: ' + CAST(@ScoreCalidad AS VARCHAR) + '%';
PRINT '';

-- Clasificación de calidad
IF @ScoreCalidad >= 95
    PRINT '🏆 CLASIFICACIÓN: EXCELENTE - Datos de muy alta calidad';
ELSE IF @ScoreCalidad >= 85
    PRINT '✓ CLASIFICACIÓN: BUENO - Calidad aceptable con mejoras menores';
ELSE IF @ScoreCalidad >= 70
    PRINT '⚠ CLASIFICACIÓN: REGULAR - Se requieren mejoras';
ELSE
    PRINT '✗ CLASIFICACIÓN: DEFICIENTE - Requiere acción correctiva inmediata';

PRINT '';
PRINT '═══════════════════════════════════════════════════════════';
PRINT 'Fin de pruebas - ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '═══════════════════════════════════════════════════════════';
PRINT '';

-- =====================================================
-- EXPORTAR RESULTADOS A TABLA DE AUDITORÍA
-- =====================================================

-- Crear tabla de auditoría si no existe
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'audit_calidad_datos')
BEGIN
    CREATE TABLE audit_calidad_datos (
        id_auditoria INT IDENTITY(1,1) PRIMARY KEY,
        fecha_ejecucion DATETIME DEFAULT GETDATE(),
        total_pruebas INT,
        pruebas_aprobadas INT,
        pruebas_advertencia INT,
        pruebas_fallidas INT,
        score_calidad DECIMAL(5,2),
        clasificacion VARCHAR(50)
    );
END

-- Insertar resultados
INSERT INTO audit_calidad_datos (
    total_pruebas, pruebas_aprobadas, pruebas_advertencia, 
    pruebas_fallidas, score_calidad, clasificacion
)
VALUES (
    @TotalTests, @PassedTests, @WarningTests, @FailedTests, @ScoreCalidad,
    CASE 
        WHEN @ScoreCalidad >= 95 THEN 'EXCELENTE'
        WHEN @ScoreCalidad >= 85 THEN 'BUENO'
        WHEN @ScoreCalidad >= 70 THEN 'REGULAR'
        ELSE 'DEFICIENTE'
    END
);

PRINT 'Resultados guardados en tabla audit_calidad_datos';
PRINT '';

-- Mostrar historial de auditorías
PRINT 'HISTORIAL DE AUDITORÍAS:';
SELECT 
    id_auditoria,
    fecha_ejecucion,
    score_calidad,
    clasificacion
FROM audit_calidad_datos
ORDER BY fecha_ejecucion DESC;

GO

-- =====================================================
-- VISTAS DE MÉTRICAS DE CALIDAD
-- =====================================================

-- Vista de resumen de calidad por dimensión
IF EXISTS (SELECT 1 FROM sys.views WHERE name = 'v_metricas_calidad')
    DROP VIEW v_metricas_calidad;
GO

CREATE VIEW v_metricas_calidad AS
SELECT 
    'Completitud' AS dimension,
    CAST(
        (SELECT COUNT(*) FROM dim_cliente WHERE nombre_cliente IS NOT NULL) * 100.0 / 
        NULLIF(COUNT(*), 0) 
        FROM dim_cliente
    AS DECIMAL(5,2)) AS porcentaje
UNION ALL
SELECT 
    'Consistencia',
    CAST(
        (SELECT COUNT(*) FROM fact_ventas 
         WHERE ABS(monto_linea - (cantidad * precio_unitario)) <= 0.01) * 100.0 / 
        NULLIF(COUNT(*), 0)
        FROM fact_ventas
    AS DECIMAL(5,2))
UNION ALL
SELECT 
    'Integridad Referencial',
    CAST(
        (SELECT COUNT(*) FROM fact_ventas fv 
         WHERE EXISTS (SELECT 1 FROM dim_tiempo dt WHERE fv.sk_tiempo = dt.sk_tiempo)) * 100.0 / 
        NULLIF(COUNT(*), 0)
        FROM fact_ventas
    AS DECIMAL(5,2))
UNION ALL
SELECT 
    'Unicidad',
    CAST(
        (SELECT COUNT(DISTINCT id_cliente) FROM dim_cliente) * 100.0 / 
        NULLIF(COUNT(*), 0)
        FROM dim_cliente
    AS DECIMAL(5,2));
GO

PRINT '';
PRINT 'Vista v_metricas_calidad creada exitosamente';
PRINT 'Consulte con: SELECT * FROM v_metricas_calidad';
PRINT '';

-- =====================================================
-- PROCEDIMIENTO ALMACENADO PARA MONITOREO CONTINUO
-- =====================================================

IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = 'sp_monitor_calidad')
    DROP PROCEDURE sp_monitor_calidad;
GO

CREATE PROCEDURE sp_monitor_calidad
AS
BEGIN
    SET NOCOUNT ON;
    
    PRINT '=== MONITOREO RÁPIDO DE CALIDAD ===';
    PRINT '';
    
    -- Mostrar métricas clave
    SELECT * FROM v_metricas_calidad;
    
    -- Último score de calidad
    SELECT TOP 1
        fecha_ejecucion,
        score_calidad,
        clasificacion
    FROM audit_calidad_datos
    ORDER BY fecha_ejecucion DESC;
    
    -- Alertas si hay problemas
    IF EXISTS (SELECT 1 FROM fact_ventas WHERE cantidad IS NULL)
        PRINT '⚠ ALERTA: Hay registros con cantidad NULL';
    
    IF EXISTS (SELECT 1 FROM fact_ventas WHERE ABS(monto_linea - (cantidad * precio_unitario)) > 0.01)
        PRINT '⚠ ALERTA: Inconsistencias en cálculo de montos';
    
    PRINT '';
    PRINT 'Monitoreo completado';
END;
GO

PRINT 'Procedimiento sp_monitor_calidad creado exitosamente';
PRINT 'Ejecute con: EXEC sp_monitor_calidad';
PRINT '';
PRINT '════════════════════════════════════════════════════════════';
PRINT 'SUITE DE CALIDAD DE DATOS COMPLETADA';
PRINT '════════════════════════════════════════════════════════════';
GO-- =====================================================
-- SUITE COMPLETA DE PRUEBAS DE CALIDAD DE DATOS
-- Data Mart Jardinería
-- Versión 1.0
-- =====================================================

SET NOCOUNT ON;
GO

PRINT '╔════════════════════════════════════════════════════════════╗';
PRINT '║       PRUEBAS DE CALIDAD DE DATOS - DATA MART             ║';
PRINT '║              Base de Datos: Jardinería                     ║';
PRINT '╚════════════════════════════════════════════════════════════╝';
PRINT '';
PRINT 'Fecha de ejecución: ' + CONVERT(VARCHAR, GETDATE(), 120);
PRINT '';

USE datamart_jardineria;
GO

-- Variables para tracking de resultados
DECLARE @TotalTests INT = 0;
DECLARE @PassedTests INT = 0;
DECLARE @FailedTests INT = 0;
DECLARE @WarningTests INT = 0;

-- =====================================================
-- DIMENSIÓN DE CALIDAD 1: COMPLETITUD
-- Verifica que los campos requeridos no tengan valores nulos
-- =====================================================

PRINT '';
PRINT '═══════════════════════════════════════════════════════════';
PRINT '1. PRUEBAS DE COMPLETITUD';
PRINT '═══════════════════════════════════════════════════════════';
PRINT '';

-- TEST 1.1: Verificar campos obligatorios en dim_cliente
PRINT 'TEST 1.1: Completitud de campos en dim_cliente';
DECLARE @nullClientes INT;
SELECT @nullClientes = COUNT(*)
FROM dim_cliente
WHERE nombre_cliente IS NULL 
   OR ciudad IS NULL 
   OR pais IS NULL;

SET @TotalTests = @TotalTests + 1;
IF @nullClientes = 0
BEGIN
    PRINT '  ✓ APROBADO: Todos los campos obligatorios están completos';
    SET @PassedTests = @PassedTests + 1;
END
ELSE
BEGIN
    PRINT '  ✗ FALLÓ: ' + CAST(@nullClientes AS VARCHAR) + ' registros con campos nulos';
    SET @FailedTests = @FailedTests + 1;
END
PRINT '';

-- TEST 1.2: Verificar campos obligatorios en dim_producto
PRINT 'TEST 1.2: Completitud de campos en dim_producto';
DECLARE @nullProductos INT;
SELECT @nullProductos = COUNT(*)
FROM dim_producto
WHERE nombre_producto IS NULL 
   OR categoria IS NULL;

SET @TotalTests = @TotalTests + 1;
IF @nullProductos = 0
BEGIN
    PRINT '  ✓ APROBADO: Todos los productos tienen información completa';
    SET @PassedTests = @PassedTests + 1;
END
ELSE
BEGIN
    PRINT '  ✗ FALLÓ: ' + CAST(@nullProductos AS VARCHAR) + ' productos con campos nulos';
    SET @FailedTests = @FailedTests + 1;
END
PRINT '';

-- TEST 1.3: Verificar métricas en fact_ventas
PRINT 'TEST 1.3: Completitud de métricas en fact_ventas';
DECLARE @nullVentas INT;
SELECT @nullVentas = COUNT(*)
FROM fact_ventas
WHERE cantidad IS NULL 
   OR precio_unitario IS NULL 
   OR monto_linea IS NULL;

SET @TotalTests = @TotalTests + 1;
IF @nullVentas = 0
BEGIN
    PRINT '  ✓ APROBADO: Todas las métricas están completas';
    SET @PassedTests = @PassedTests + 1;
END
ELSE
BEGIN
    PRINT '  ✗ FALLÓ: ' + CAST(@nullVentas AS VARCHAR) + ' registros con métricas nulas';
    SET @FailedTests = @FailedTests + 1;
END
PRINT '';

-- TEST 1.4: Porcentaje de completitud general
PRINT 'TEST 1.4: Porcentaje de completitud general';
DECLARE @totalCampos INT;
DECLARE @camposCompletos INT;
DECLARE @porcentajeCompletitud DECIMAL(5,2);

SELECT 
    @totalCampos = SUM(TotalCampos),
    @camposCompletos = SUM(CamposCompletos)
FROM (
    SELECT 
        COUNT(*) * 7 AS TotalCampos,
        COUNT(*) * 7 - 
        SUM(CASE WHEN nombre_cliente IS NULL THEN 1 ELSE 0 END +
            CASE WHEN ciudad IS NULL THEN 1 ELSE 0 END) AS CamposCompletos
    FROM dim_cliente
    UNION ALL
    SELECT 
        COUNT(*) * 5,
        COUNT(*) * 5 - 
        SUM(CASE WHEN nombre_producto IS NULL THEN 1 ELSE 0 END) 
    FROM dim_producto
) AS Completitud;

SET @porcentajeCompletitud = (@camposCompletos * 100.0) / @totalCampos;

SET @TotalTests = @TotalTests + 1;
PRINT '  Completitud general: ' + CAST(@porcentajeCompletitud AS VARCHAR) + '%';
IF @porcentajeCompletitud >= 95
BEGIN
    PRINT '  ✓ APROBADO: Completitud superior al 95%';
    SET @PassedTests = @PassedTests + 1;
END
ELSE IF @porcentajeCompletitud >= 90
BEGIN
    PRINT '  ⚠ ADVERTENCIA: Completitud entre 90-95%';
    SET @WarningTests = @WarningTests + 1;
END
ELSE
BEGIN
    PRINT '  ✗ FALLÓ: Completitud inferior al 90%';
    SET @FailedTests = @FailedTests + 1;
END
PRINT '';

-- =====================================================
-- DIMENSIÓN DE CALIDAD 2: CONSISTENCIA
-- Verifica que los datos sean coherentes y lógicos
-- =====================================================

PRINT '═══════════════════════════════════════════════════════════';
PRINT '2. PRUEBAS DE CONSISTENCIA';
PRINT '═══════════════════════════════════════════════════════════';
PRINT '';

-- TEST 2.1: Verificar cálculo de monto_linea
PRINT 'TEST 2.1: Consistencia en cálculo de monto_linea';
DECLARE @inconsistentCalculations INT;
SELECT @inconsistentCalculations = COUNT(*)
FROM fact_ventas
WHERE ABS(monto_linea - (cantidad * precio_unitario)) > 0.01;

SET @TotalTests = @TotalTests + 1;
IF @inconsistentCalculations = 0
BEGIN
    PRINT '  ✓ APROBADO: Todos los cálculos son consistentes';
    SET @PassedTests = @PassedTests + 1;
END
ELSE
BEGIN
    PRINT '  ✗ FALLÓ: ' + CAST(@inconsistentCalculations AS VARCHAR) + ' registros con cálculos incorrectos';
    SET @FailedTests = @FailedTests + 1;
END
PRINT '';

-- TEST 2.2: Verificar valores negativos
PRINT 'TEST 2.2: Consistencia de valores (sin negativos)';
DECLARE @negativeValues INT;
SELECT @negativeValues = COUNT(*)
FROM fact_ventas
WHERE cantidad < 0 
   OR precio_unitario < 0 
   OR monto_linea < 0;

SET @TotalTests = @TotalTests + 1;
IF @negativeValues = 0
BEGIN
    PRINT '  ✓ APROBADO: No hay valores negativos';
    SET @PassedTests = @PassedTests + 1;
END
ELSE
BEGIN
    PRINT '  ✗ FALLÓ: ' + CAST(@negativeValues AS VARCHAR) + ' registros con valores negativos';
    SET @FailedTests = @FailedTests + 1;
END
PRINT '';

-- TEST 2.3: Verificar rangos de fechas
PRINT 'TEST 2.3: Consistencia de rangos de fechas';
DECLARE @invalidDates INT;
SELECT @invalidDates = COUNT(*)
FROM dim_tiempo
WHERE fecha < '2000-01-01' 
   OR fecha > GETDATE();

SET @TotalTests = @TotalTests + 1;
IF @invalidDates = 0
BEGIN
    PRINT '  ✓ APROBADO: Todas las fechas están en rango válido';
    SET @PassedTests = @PassedTests + 1;
END
ELSE
BEGIN
    PRINT '  ✗ FALLÓ: ' + CAST(@invalidDates AS VARCHAR) + ' fechas fuera de rango';
    SET @FailedTests = @FailedTests + 1;
END
PRINT '';

-- TEST 2.4: Verificar consistencia de categorías
PRINT 'TEST 2.4: Consistencia de valores categóricos';
DECLARE @invalidCategories INT;
SELECT @invalidCategories = COUNT(*)
FROM dim_cliente
WHERE segmento_credito NOT IN ('Sin Crédito', 'Bajo', 'Medio', 'Alto');

SET @TotalTests = @TotalTests + 1;
IF @invalidCategories = 0
BEGIN
    PRINT '  ✓ APROBADO: Todas las categorías son válidas';
    SET @PassedTests = @PassedTests + 1;
END
ELSE
BEGIN
    PRINT '  ✗ FALLÓ: ' + CAST(@invalidCategories AS VARCHAR) + ' categorías inválidas';
    SET @FailedTests = @FailedTests + 1;
END
PRINT '';

-- =====================================================
-- DIMENSIÓN DE CALIDAD 3: INTEGRIDAD REFERENCIAL
-- Verifica que las relaciones entre tablas sean correctas
-- =====================================================

PRINT '═══════════════════════════════════════════════════════════';
PRINT '3. PRUEBAS DE INTEGRIDAD REFERENCIAL';
PRINT '═══════════════════════════════════════════════════════════';
PRINT '';

-- TEST 3.1: Integridad FK con dim_tiempo
PRINT 'TEST 3.1: Integridad referencial con dim_tiempo';
DECLARE @orphanTiempo INT;
SELECT @orphanTiempo = COUNT(*)
FROM fact_ventas fv
WHERE NOT EXISTS (
    SELECT 1 FROM dim_tiempo dt 
    WHERE fv.sk_tiempo = dt.sk_tiempo
);

SET @TotalTests = @TotalTests + 1;
IF @orphanTiempo = 0
BEGIN
    PRINT '  ✓ APROBADO: Integridad con dim_tiempo OK';
    SET @PassedTests = @PassedTests + 1;
END
ELSE
BEGIN
    PRINT '  ✗ FALLÓ: ' + CAST(@orphanTiempo AS VARCHAR) + ' registros huérfanos';
    SET @FailedTests = @FailedTests + 1;
END
PRINT '';

-- TEST 3.2: Integridad FK con dim_cliente
PRINT 'TEST 3.2: Integridad referencial con dim_cliente';
DECLARE @orphanCliente INT;
SELECT @orphanCliente = COUNT(*)
FROM fact_ventas fv
WHERE NOT EXISTS (
    SELECT 1 FROM dim_cliente dc 
    WHERE fv.sk_cliente = dc.sk_cliente
);

SET @TotalTests = @TotalTests + 1;
IF @orphanCliente = 0
BEGIN
    PRINT '  ✓ APROBADO: Integridad con dim_cliente OK';
    SET @PassedTests = @PassedTests + 1;
END
ELSE
BEGIN
    PRINT '  ✗ FALLÓ: ' + CAST(@orphanCliente AS VARCHAR) + ' registros huérfanos';
    SET @FailedTests = @FailedTests + 1;
END
PRINT '';

-- TEST 3.3: Integridad FK con dim_producto
PRINT 'TEST 3.3: Integridad referencial con dim_producto';
DECLARE @orphanProducto INT;
SELECT @orphanProducto = COUNT(*)
FROM fact_ventas fv
WHERE NOT EXISTS (
    SELECT 1 FROM dim_producto dp 
    WHERE fv.sk_producto = dp.sk_producto
);

SET @TotalTests = @TotalTests + 1;
IF @orphanProducto = 0
BEGIN
    PRINT '  ✓ APROBADO: Integridad con dim_producto OK';
    SET @PassedTests = @PassedTests + 1;
END
ELSE
BEGIN
    PRINT '  ✗ FALLÓ: ' + CAST(@orphanProducto AS VARCHAR) + ' registros huérfanos';
    SET @FailedTests = @FailedTests + 1;
END
PRINT '';

-- TEST 3.4: Integridad FK con dim_estado
PRINT 'TEST 3.4: Integridad referencial con dim_estado';
DECLARE @orphanEstado INT;
SELECT @orphanEstado = COUNT(*)
FROM fact_ventas fv
WHERE NOT EXISTS (
    SELECT 1 FROM dim_estado de 
    WHERE fv.sk_estado = de.sk_estado
);

SET @TotalTests = @TotalTests + 1;
IF @orphanEstado = 0
BEGIN
    PRINT '  ✓ APROBADO: Integridad con dim_estado OK';
    SET @PassedTests = @PassedTests + 1;
END
ELSE
BEGIN
    PRINT '  ✗ FALLÓ: ' + CAST(@orphanEstado AS VARCHAR) + ' registros huérfanos';
    SET @FailedTests = @FailedTests + 1;
END
PRINT '';

-- =====================================================
-- DIMENSIÓN DE CALIDAD 4: VALIDEZ
-- Verifica que los valores estén dentro de rangos esperados
-- =====================================================

PRINT '═══════════════════════════════════════════════════════════';
PRINT '4. PRUEBAS DE VALIDEZ';
PRINT '═══════════════════════════════════════════════════════════';
PRINT '';

-- TEST 4.1: Validez de cantidades
PRINT 'TEST 4.1: Validez de cantidades vendidas';
DECLARE @invalidQuantities INT;
SELECT @invalidQuantities = COUNT(*)
FROM fact_ventas
WHERE cantidad <= 0 OR cantidad > 10000;

SET @TotalTests = @TotalTests + 1;
IF @invalidQuantities = 0
BEGIN
    PRINT '  ✓ APROBADO: Todas las cantidades son válidas';
    SET @PassedTests = @PassedTests + 1;
END
ELSE
BEGIN
    PRINT '  ⚠ ADVERTENCIA: ' + CAST(@invalidQuantities AS VARCHAR) + ' cantidades sospechosas';
    SET @WarningTests = @WarningTests + 1;
END
PRINT '';

-- TEST 4.2: Validez de precios
PRINT 'TEST 4.2: Validez de precios unitarios';
DECLARE @invalidPrices INT;
SELECT @invalidPrices = COUNT(*)
FROM fact_ventas
WHERE precio_unitario <= 0 OR precio_unitario > 1000;

SET @TotalTests = @TotalTests + 1;
IF @invalidPrices = 0
BEGIN
    PRINT '  ✓ APROBADO: Todos los precios son válidos';
    SET @PassedTests = @PassedTests + 1;
END
ELSE
BEGIN
    PRINT '  ⚠ ADVERTENCIA: ' + CAST(@invalidPrices AS VARCHAR) + ' precios fuera de rango típico';
    SET @WarningTests = @WarningTests + 1;
END
PRINT '';

-- TEST 4.3: Validez de límites de crédito
PRINT 'TEST 4.3: Validez de límites de crédito';
DECLARE @invalidCredits INT;
SELECT @invalidCredits = COUNT(*)
FROM dim_cliente
WHERE limite_credito < 0 OR limite_credito > 1000000;

SET @TotalTests = @TotalTests + 1;
IF @invalidCredits = 0
BEGIN
    PRINT '  ✓ APROBADO: Todos los límites de crédito son razonables';
    SET @PassedTests = @PassedTests + 1;
END
ELSE
BEGIN
    PRINT '  ⚠ ADVERTENCIA: ' + CAST(@invalidCredits AS VARCHAR) + ' límites sospechosos';
    SET @WarningTests = @WarningTests + 1;
END
PRINT '';

-- =====================================================
-- DIMENSIÓN DE CALIDAD 5: UNICIDAD
-- Verifica que no haya duplicados
-- =====================================================

PRINT '═══════════════════════════════════════════════════════════';
PRINT '5. PRUEBAS DE UNICIDAD';
PRINT '═══════════════════════════════════════════════════════════';
PRINT '';

-- TEST 5.1: Unicidad de business keys en dim_cliente
PRINT 'TEST 5.1: Unicidad de clientes';
DECLARE @duplicateClientes INT;
SELECT @duplicateClientes = COUNT(*) - COUNT(DISTINCT id_cliente)
FROM dim_cliente;

SET @TotalTests = @TotalTests + 1;
IF @duplicateClientes = 0
BEGIN
    PRINT '  ✓ APROBADO: No hay clientes duplicados';
    SET @PassedTests = @PassedTests + 1;
END
ELSE
BEGIN
    PRINT '  ✗ FALLÓ: ' + CAST(@duplicateClientes AS VARCHAR) + ' clientes duplicados';
    SET @FailedTests = @FailedTests + 1;
END
PRINT '';

-- TEST 5.2: Unicidad de business keys en dim_producto
PRINT 'TEST 5.2: Unicidad de productos';
DECLARE @duplicateProductos INT;
SELECT @duplicateProductos = COUNT(*) - COUNT(DISTINCT id_producto)
FROM dim_producto;

SET @TotalTests = @TotalTests + 1;
IF @duplicateProductos = 0
BEGIN
    PRINT '  ✓ APROBADO: No hay productos duplicados';
    SET @PassedTests = @PassedTests + 1;
END
ELSE
BEGIN
    PRINT '  ✗ FALLÓ: ' + CAST(@duplicateProductos AS VARCHAR) + ' productos duplicados';
    SET @FailedTests = @FailedTests + 1;
END
PRINT '';

-- TEST 5.3: Unicidad de fechas en dim_tiempo
PRINT 'TEST 5.3: Unicidad de fechas';
DECLARE @duplicateFechas INT;
SELECT @duplicateFechas = COUNT(*) - COUNT(DISTINCT fecha)
FROM dim_tiempo;

SET @TotalTests = @TotalTests + 1;
IF @duplicateFechas = 0
BEGIN
    PRINT '  ✓ APROBADO: No hay fechas duplicadas';
    SET @PassedTests = @PassedTests + 1;
END
ELSE
BEGIN
    PRINT '  ✗ FALLÓ: ' + CAST(@duplicateFechas AS VARCHAR) + ' fechas duplicadas';
    SET @FailedTests = @FailedTests + 1;
END
PRINT '';

-- =====================================================
-- DIMENSIÓN DE CALIDAD 6: PRECISIÓN
-- Verifica la precisión de los datos comparando con origen
-- =====================================================

PRINT '═══════════════════════════════════════════════════════════';
PRINT '6. PRUEBAS DE PRECISIÓN';
PRINT '═══════════════════════════════════════════════════════════';
PRINT '';

-- TEST 6.1: Comparación de totales con origen
PRINT 'TEST 6.1: Precisión de migración (comparación con origen)';
DECLARE @origenDetalles INT, @datamartVentas INT, @diferencia INT;

SELECT @origenDetalles = COUNT(*) 
FROM jardineria.dbo.detalle_pedido;

SELECT @datamartVentas = COUNT(*) 
FROM fact_ventas;

SET @diferencia = ABS(@origenDetalles - @datamartVentas);

SET @TotalTests = @TotalTests + 1;
PRINT '  Registros en origen: ' + CAST(@origenDetalles AS VARCHAR);
PRINT '  Registros en Data Mart: ' + CAST(@datamartVentas AS VARCHAR);
PRINT '  Diferencia: ' + CAST(@diferencia AS VARCHAR);

IF @diferencia = 0
BEGIN
    PRINT '  ✓ APROBADO: Migración 100% precisa';
    SET @PassedTests = @PassedTests + 1;
END
ELSE IF @diferencia <= 5
BEGIN
    PRINT '  ⚠ ADVERTENCIA: Diferencia mínima aceptable';
    SET @WarningTests = @WarningTests + 1;
END
ELSE
BEGIN
    PRINT '  ✗ FALLÓ: Diferencia significativa en datos';
    SET @FailedTests = @FailedTests + 1;
END
PRINT '';

-- =====================================================
-- RESUMEN FINAL
-- =====================================================

PRINT '';
PRINT '╔════════════════════════════════════════════════════════════╗';
PRINT '║              RESUMEN DE CALIDAD DE DATOS                  ║';
PRINT '╚════════════════════════════════════════════════════════════╝';
PRINT '';
PRINT 'Total de pruebas ejecutadas: ' + CAST(@TotalTests AS VARCHAR);
PRINT 'Pruebas aprobadas: ' + CAST(@PassedTests AS VARCHAR) + ' (' + 
      CAST((@PassedTests * 100.0 / @TotalTests) AS VARCHAR(5)) + '%)';
PRINT 'Pruebas con advertencia: ' + CAST(@WarningTests AS VARCHAR);
PRINT 'Pruebas fallidas: ' + CAST(@FailedTests AS VARCHAR) + ' (' + 
      CAST((@FailedTests * 100.0 / @TotalTests) AS VARCHAR(5)) + '%)';
PRINT '';

-- Calcular puntaje de calidad general
DECLARE @ScoreCalidad DECIMAL(5,2);
SET @ScoreCalidad = ((@PassedTests + (@WarningTests * 0.5)) * 100.0) / @TotalTests;

PRINT 'PUNTAJE DE CALIDAD GENERAL: ' + CAST(@ScoreCalidad AS VARCHAR) + '%';
PRINT '';