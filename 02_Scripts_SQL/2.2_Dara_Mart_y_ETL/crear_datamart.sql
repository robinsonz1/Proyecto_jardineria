-- CREACIÓN DEL DATA MART - MODELO ESTRELLA


CREATE DATABASE datamart_jardineria;
GO
USE datamart_jardineria;
GO

-- TABLAS DE DIMENSIONES


-- Dimensión Tiempo
CREATE TABLE dim_tiempo (
    sk_tiempo INT IDENTITY(1,1) PRIMARY KEY,
    fecha DATE NOT NULL UNIQUE,
    anio INT NOT NULL,
    mes INT NOT NULL,
    nombre_mes VARCHAR(20) NOT NULL,
    trimestre INT NOT NULL,
    dia INT NOT NULL,
    dia_semana INT NOT NULL,
    nombre_dia VARCHAR(20) NOT NULL,
    semana_anio INT NOT NULL
);

-- Dimensión Cliente
CREATE TABLE dim_cliente (
    sk_cliente INT IDENTITY(1,1) PRIMARY KEY,
    id_cliente INT NOT NULL,
    nombre_cliente VARCHAR(50) NOT NULL,
    ciudad VARCHAR(50),
    pais VARCHAR(50),
    limite_credito NUMERIC(15,2),
    segmento_credito VARCHAR(20), -- clasificación por límite
    fecha_carga DATETIME DEFAULT GETDATE(),
    CONSTRAINT uq_dim_cliente UNIQUE (id_cliente)
);

-- Dimensión Producto
CREATE TABLE dim_producto (
    sk_producto INT IDENTITY(1,1) PRIMARY KEY,
    id_producto INT NOT NULL,
    codigo_producto VARCHAR(15) NOT NULL,
    nombre_producto VARCHAR(70) NOT NULL,
    categoria VARCHAR(50),
    rango_precio VARCHAR(20), -- clasificación por precio
    fecha_carga DATETIME DEFAULT GETDATE(),
    CONSTRAINT uq_dim_producto UNIQUE (id_producto)
);

-- Dimensión Empleado
CREATE TABLE dim_empleado (
    sk_empleado INT IDENTITY(1,1) PRIMARY KEY,
    id_empleado INT NOT NULL,
    nombre_completo VARCHAR(150) NOT NULL,
    puesto VARCHAR(50),
    ciudad_oficina VARCHAR(50),
    pais_oficina VARCHAR(50),
    fecha_carga DATETIME DEFAULT GETDATE(),
    CONSTRAINT uq_dim_empleado UNIQUE (id_empleado)
);

-- Dimensión Estado Pedido
CREATE TABLE dim_estado (
    sk_estado INT IDENTITY(1,1) PRIMARY KEY,
    estado VARCHAR(15) NOT NULL UNIQUE,
    descripcion VARCHAR(100),
    tipo_estado VARCHAR(20) -- Exitoso, Fallido, En Proceso
);

-- =====================================================
-- TABLA DE HECHOS
-- =====================================================

CREATE TABLE fact_ventas (
    sk_venta INT IDENTITY(1,1) PRIMARY KEY,
    
    -- Claves foráneas a dimensiones
    sk_tiempo INT NOT NULL,
    sk_cliente INT NOT NULL,
    sk_producto INT NOT NULL,
    sk_empleado INT,
    sk_estado INT NOT NULL,
    
    -- Claves de negocio 
    id_pedido INT NOT NULL,
    id_detalle_pedido INT NOT NULL,
    
    -- Métricas aditivas
    cantidad INT NOT NULL,
    precio_unitario NUMERIC(15,2) NOT NULL,
    monto_linea NUMERIC(15,2) NOT NULL, -- cantidad * precio_unitario
    
    -- Métricas derivadas )
    descuento_aplicado NUMERIC(15,2) DEFAULT 0,
    costo_producto NUMERIC(15,2), -- Si está disponible
    margen_bruto NUMERIC(15,2), -- monto_linea - costo
    
    -- Auditoría
    fecha_carga DATETIME DEFAULT GETDATE(),
    
    -- Relaciones
    CONSTRAINT fk_fact_tiempo FOREIGN KEY (sk_tiempo) 
        REFERENCES dim_tiempo(sk_tiempo),
    CONSTRAINT fk_fact_cliente FOREIGN KEY (sk_cliente) 
        REFERENCES dim_cliente(sk_cliente),
    CONSTRAINT fk_fact_producto FOREIGN KEY (sk_producto) 
        REFERENCES dim_producto(sk_producto),
    CONSTRAINT fk_fact_empleado FOREIGN KEY (sk_empleado) 
        REFERENCES dim_empleado(sk_empleado),
    CONSTRAINT fk_fact_estado FOREIGN KEY (sk_estado) 
        REFERENCES dim_estado(sk_estado)
);

-- =====================================================
-- ÍNDICES PARA OPTIMIZACIÓN DE CONSULTAS
-- =====================================================

-- Índices en dimensiones
CREATE INDEX idx_dim_tiempo_fecha ON dim_tiempo(fecha);
CREATE INDEX idx_dim_tiempo_anio_mes ON dim_tiempo(anio, mes);
CREATE INDEX idx_dim_cliente_pais ON dim_cliente(pais);
CREATE INDEX idx_dim_producto_categoria ON dim_producto(categoria);
CREATE INDEX idx_dim_empleado_puesto ON dim_empleado(puesto);

-- Índices en hechos (para consultas frecuentes)
CREATE INDEX idx_fact_tiempo ON fact_ventas(sk_tiempo);
CREATE INDEX idx_fact_cliente ON fact_ventas(sk_cliente);
CREATE INDEX idx_fact_producto ON fact_ventas(sk_producto);
CREATE INDEX idx_fact_pedido ON fact_ventas(id_pedido);
CREATE INDEX idx_fact_fecha_carga ON fact_ventas(fecha_carga);

-- Índice compuesto para análisis temporal por producto
CREATE INDEX idx_fact_tiempo_producto ON fact_ventas(sk_tiempo, sk_producto);

GO

PRINT 'Data Mart creado exitosamente con modelo estrella';
PRINT 'Dimensiones: Tiempo, Cliente, Producto, Empleado, Estado';
PRINT 'Hechos: Ventas con métricas aditivas y derivadas';
GO