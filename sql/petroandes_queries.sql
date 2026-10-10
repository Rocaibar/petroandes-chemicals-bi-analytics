-- ==========================================================================================
-- PROYECTO: PETROANDES CHEMICALS - MODELO DIMENSIONAL Y ANALÍTICA SQL
-- ==========================================================================================

-- ==========================================================================================
-- 1. CREACIÓN DE LA BASE DE DATOS
-- ==========================================================================================

CREATE DATABASE BD_PetroAndes;
GO

USE BD_PetroAndes;
GO

-- ==========================================================================================
-- 2. CREACIÓN DE TABLAS DIMENSIONALES Y DE HECHOS (DDL)
-- ==========================================================================================

-- TABLA: Dim_Clientes. 
-- Nota: Se establece ID_Cliente como Clave Primaria (Primary Key) para garantizar la 
-- unicidad del catálogo comercial).

CREATE TABLE Dim_Clientes (
    ID_Cliente INT PRIMARY KEY,
    Nombre_Empresa VARCHAR(150) NOT NULL,
    Segmento_Mercado VARCHAR(100),
    Pais_Sede VARCHAR(100)
);
GO

-- TABLA: Dim_Plantas. 
-- Nota: Aísla la infraestructura productiva (Plantas/Complejos),permitiendo evaluar la 
-- capacidad instalada y ubicación geográfica.
CREATE TABLE Dim_Plantas (
    ID_Planta INT PRIMARY KEY,
    Complejo VARCHAR(100) NOT NULL,
    Ubicacion_Complejo VARCHAR(100),
    Capacidad_Nominal_TM_Mes DECIMAL(18,2)
);
GO

-- TABLA: Dim_Productos. 
-- Nota: Catálogo maestro normalizado de productos ofertados por la compañía.
CREATE TABLE Dim_Productos (
    ID_Producto INT PRIMARY KEY,
    Nombre_Producto VARCHAR(150) NOT NULL,
    Tipo_Carga VARCHAR(50),
    Familia VARCHAR(100)
);
GO

-- TABLA: Fact_Ventas. 
-- Nota: Tabla de Hechos (Fact Table). Almacena el núcleo transaccional depurado,
-- vinculándose con las dimensiones mediante Claves Foráneas (Foreign Keys) 
-- y calculando de forma relacional las métricas financieras clave.
CREATE TABLE Fact_Ventas (
    ID_Venta INT PRIMARY KEY,
    Fecha_Venta DATE NOT NULL,
    ID_Cliente INT NOT NULL,
    ID_Producto INT NOT NULL,
    ID_Planta INT NOT NULL,
    Cantidad_TM DECIMAL(18,2) NOT NULL,
    Precio_Venta_TM_USD DECIMAL(18,2) NOT NULL,
    Costo_Produccion_TM_USD DECIMAL(18,2) NOT NULL,
    Total_Venta DECIMAL(18,2),
    Costo_Total DECIMAL(18,2),
    Margen_Bruto DECIMAL(18,2),
    CONSTRAINT FK_Ventas_Clientes FOREIGN KEY (ID_Cliente) REFERENCES Dim_Clientes(ID_Cliente),
    CONSTRAINT FK_Ventas_Productos FOREIGN KEY (ID_Producto) REFERENCES Dim_Productos(ID_Producto),
    CONSTRAINT FK_Ventas_Plantas FOREIGN KEY (ID_Planta) REFERENCES Dim_Plantas(ID_Planta)
);
GO

-- ==========================================================================================
-- 3. NOTAS DE CARGA DE DATOS (ETL DESDE ARCHIVOS CSV)
-- ==========================================================================================
/*
INSTRUCCIONES DE IMPORTACIÓN:
Para poblar las tablas creadas a partir de tus archivos CSV limpios, uso el asistente visual:
1. Hago clic derecho sobre 'PetroAndesDB' > Tareas > Importar Archivo...
2. Selecciono 'Flat File Source' y cargo cada uno de tus archivos limpios:
   - Dim_Clientes.csv  -> Tabla: Dim_Clientes
   - Dim_Plantas.csv   -> Tabla: Dim_Plantas
   - Dim_Productos.csv -> Tabla: Dim_Productos
   - Fact_Ventas.csv   -> Tabla: Fact_Ventas
Asegurándome de que los tipos de datos coincidan (IDs como enteros, métricas como decimales).
*/

-- ==========================================================================================
-- 4. CONSULTA SQL DE VENTAS RECIENTES (ÚLTIMOS 30 DÍAS)
-- ==========================================================================================
-- Descripción: 
-- Esta consulta une la tabla de hechos (Fact_Ventas) con la dimensión de clientes
-- (Dim_Clientes) mediante un INNER JOIN para extraer el nombre del cliente, la fecha de la
-- compra y el total de la venta. Incorpora un filtro dinámico basado en la fecha máxima del
-- dataset y ordena los resultados de manera descendente por fecha.
-- ==========================================================================================

SELECT 
    c.Nombre_Empresa, -- Nombre o razón social del cliente
    f.Fecha_Venta,    -- Fecha en la que se realizó la transacción
    f.Total_Venta     -- Monto total monetario de la venta
FROM Fact_Ventas f
INNER JOIN Dim_Clientes c 
    ON f.ID_Cliente = c.ID_Cliente
WHERE f.Fecha_Venta >= DATEADD(day, -30, (SELECT MAX(Fecha_Venta) FROM Fact_Ventas))
ORDER BY f.Fecha_Venta DESC;
GO

-- ==========================================================================================
-- CONSULTA ANALÍTICA DE RENTABILIDAD (DIAGNÓSTICO DEL MARGEN)
-- ==========================================================================================
SELECT 
    p.Familia,
    p.Nombre_Producto,
    c.Segmento_Mercado,
    pl.Complejo,
    SUM(f.Cantidad_TM) AS Volumen_Total_TM,
    SUM(f.Total_Venta) AS Ingresos_Totales_USD,
    SUM(f.Costo_Total) AS Costos_Totales_USD,
    SUM(f.Margen_Bruto) AS Margen_Bruto_Total_USD,
    CASE 
        WHEN SUM(f.Margen_Bruto) < 0 THEN 'CRÍTICO: Margen Negativo'
        ELSE 'Saludable'
    END AS Estado_Rentabilidad
FROM 
    Fact_Ventas f
INNER JOIN 
    Dim_Productos p ON f.ID_Producto = p.ID_Producto
INNER JOIN 
    Dim_Clientes c ON f.ID_Cliente = c.ID_Cliente
INNER JOIN 
    Dim_Plantas pl ON f.ID_Planta = pl.ID_Planta
GROUP BY 
    p.Familia,
    p.Nombre_Producto,
    c.Segmento_Mercado,
    pl.Complejo
ORDER BY 
    Margen_Bruto_Total_USD ASC;
GO







