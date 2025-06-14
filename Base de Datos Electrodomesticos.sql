CREATE DATABASE Empresa_Electrodomesticos;

USE Empresa_Electrodomesticos;

-- CLIENTES Y PROVEEDORES

CREATE TABLE Localidades (
	ID_Localidad INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    Ciudad VARCHAR(20) NOT NULL,
    Provincia VARCHAR(20) NOT NULL,
    Region VARCHAR(10) NOT NULL);

CREATE TABLE Listado_Contactos (
	ID_Contacto INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    Nombre_Apellido VARCHAR(150) NOT NULL,
    Email VARCHAR (110) NOT NULL,
    Telefono INT,
    Interno INT,
    Celular INT,
    UNIQUE (EMAIL));

CREATE TABLE Proveedores (
	ID_Proveedores INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    Tipo_Proveedor VARCHAR(20) NOT NULL,
	Denominacion_Social VARCHAR(60),
    Razon_Social VARCHAR(60) NOT NULL,
    CUIT CHAR(11) NOT NULL,
    ID_Contacto INT NOT NULL,
    Direccion VARCHAR(130) NOT NULL,
    ID_Localidad INT NOT NULL,
    FOREIGN KEY (ID_Contacto) REFERENCES Listado_Contactos(ID_Contacto),
    FOREIGN KEY (ID_Localidad) REFERENCES Localidades(ID_Localidad),
    UNIQUE(CUIT));

CREATE TABLE Clientes (
	ID_Cliente INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
	Tipo_Cliente VARCHAR(20) NOT NULL,
    Denominacion_Social VARCHAR(60),
    Razon_Social VARCHAR(60) NOT NULL,
    CUIT CHAR(11) NOT NULL,
    ID_Contacto INT NOT NULL,
    Direccion VARCHAR(130) NOT NULL,
    ID_Localidad INT NOT NULL,
    FOREIGN KEY (ID_Contacto) REFERENCES Listado_Contactos(ID_Contacto),
    FOREIGN KEY (ID_Localidad) REFERENCES Localidades(ID_Localidad),
	UNIQUE(CUIT));
    
-- PRODUCTOS

CREATE TABLE SubCategorias (
	ID_SubCategoria INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    SubCategoria VARCHAR(150) NOT NULL
    );
    
CREATE TABLE Categorias (
	ID_Categoria INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    Categoria VARCHAR(150) NOT NULL,
    ID_SubCategoria INT NOT NULL,
    FOREIGN KEY (ID_SubCategoria) REFERENCES SubCategorias(ID_SubCategoria)
    );

CREATE TABLE Productos (
	ID_Producto INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    Producto VARCHAR(50) NOT NULL,
    ID_Categoria INT NOT NULL,
    Fecha_Alta DATE NOT NULL,
    FOREIGN KEY (ID_Categoria) REFERENCES Categorias(ID_Categoria));
    
-- DEPARTAMENTO DE INVENTARIO

CREATE TABLE Stock_Bienes_Finalizados (
	ID_Stock INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
	ID_Producto INT NOT NULL,
    Cantidad INT NOT NULL,
    Precio DECIMAL(10,2) NOT NULL,
    Ultimo_Costo_Fabricado DECIMAL(10,2),
    FOREIGN KEY (ID_Producto) REFERENCES Productos(ID_Producto));

-- Creamos un TRIGGER BEFORE para poder, una vez que fue producida la Parte de Producción, deducir el último costo formulado sobre el Stock

DELIMITER $$

CREATE TRIGGER Insercion_Del_Costo
	BEFORE INSERT ON Stock_Bienes_Finalizados
    FOR EACH ROW
    BEGIN
		SET NEW.Ultimo_Costo_Fabricado = (SELECT Costo_Por_Unidad
										  FROM Partes_De_Produccion
                                          WHERE ID_Producto = NEW.ID_Producto
                                          ORDER BY Fecha_Inicio DESC
                                          LIMIT 1);
    
END$$

DELIMITER ;

-- PRODUCCION

CREATE TABLE Partes_De_Produccion (
	ID_Parte_Produccion INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
	Pedido_De_Produccion INT,
    Estado VARCHAR(20),
    Fecha_Inicio DATE NOT NULL,
	Fecha_Finalizacion DATE,
    ID_Producto INT,
    Cantidad INT,
	Costo_Por_Unidad DECIMAL(10,2),
    Costo_Total DECIMAL(10,2) GENERATED ALWAYS AS (Cantidad*Costo_Por_Unidad),
    FOREIGN KEY (ID_Producto) REFERENCES Productos(ID_Producto),
    UNIQUE(Pedido_De_Produccion));

-- VENTAS

CREATE TABLE Tiendas (
	ID_Tienda INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    Tienda VARCHAR(40),
    Cantidad_Vendedores INT,
    Direccion VARCHAR(50),
    ID_Localidad INT NOT NULL,
    FOREIGN KEY (ID_Localidad) REFERENCES Localidades(ID_Localidad));

CREATE TABLE Vendedores (
	ID_Vendedor INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    Legajo INT,
    Vendedor VARCHAR(100) NOT NULL,
    Tipo_Documento VARCHAR(10) NOT NULL,
    DOC_N° INT NOT NULL,
    Fecha_Nacimiento DATE NOT NULL,
    Edad INT, -- Esta formula fue calculada con a partir de información en internet
    Domicilio VARCHAR(140) NOT NULL,
    ID_Localidad INT,
    Especialidad_De_Venta VARCHAR(150),
    Titulo VARCHAR(20),
    UNIQUE(DOC_N°,Legajo),
    FOREIGN KEY (ID_Localidad) REFERENCES Localidades(ID_Localidad));

-- Salvamos las relaciones de muchos a muchos para CLIENTES-VENTAS y PRODUCTOS-VENTAS

CREATE TABLE Ventas (
	ID_Venta INT AUTO_INCREMENT NOT NULL PRIMARY KEY,
    Fecha DATE,
    Factura INT,
    ID_Producto INT NOT NULL,
    ID_Cliente INT NOT NULL,
    ID_Tienda INT NOT NULL,
    ID_Vendedor INT NOT NULL,
    Cantidad INT NOT NULL,
    Precio_Venta DECIMAL(10,2) NOT NULL,
    Precio_Actualizado DECIMAL(10,2),
    Importe DECIMAL(10,2) GENERATED ALWAYS AS (Precio_venta*Cantidad),
    IVA DECIMAL(10,2) GENERATED ALWAYS AS (Importe*0.21),
    Otros_Impuestos DECIMAL(10,2),
    Importe_Final DECIMAL(10,2) GENERATED ALWAYS AS (Importe+IVA+Otros_Impuestos),
    FOREIGN KEY (ID_Tienda) REFERENCES Tiendas(ID_Tienda),
    FOREIGN KEY (ID_Vendedor) REFERENCES Vendedores(ID_Vendedor),
    UNIQUE(Factura));

CREATE TABLE Int_Cliente_Ventas (
	ID_Venta INT,
    ID_Cliente INT,
    FOREIGN KEY (ID_Venta) REFERENCES Ventas(ID_Venta),
    FOREIGN KEY (ID_Cliente) REFERENCES Clientes(ID_Cliente));

CREATE TABLE Int_Producto_Ventas (
	ID_Venta INT,
    ID_Producto INT,
    FOREIGN KEY (ID_Producto) REFERENCES Productos(ID_Producto),
    FOREIGN KEY (ID_Venta) REFERENCES Ventas(ID_Venta));

-- Para el tema del precio de venta tomaremos el último precio actualizado del stock para que este proceso sea automático y no manual
-- De esta manera evitaremos malos manejos y posibles errores en la conformación de la base
-- Para esto utilizaremos un TRIGGER BEFORE en las siguientes sentencias

DELIMITER $$

CREATE TRIGGER inserción_Precio_Venta_Actualizado
BEFORE INSERT ON Ventas
FOR EACH ROW
BEGIN

	DECLARE Precio_Actualizado DECIMAL(10,2);
    
	SELECT Precio INTO Precio_Actualizado
	FROM Stock_Bienes_Finalizados
	WHERE ID_Producto = NEW.ID_Producto
	ORDER BY ID_Stock DESC
	LIMIT 1;

	IF Precio_Actualizado IS NOT NULL THEN
		SET NEW.Precio_Venta = Precio_Actualizado;
	ELSE
		-- Lanzaremos un error si no hay precio disponible
		SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'No es posible realizar esta venta ya que no se incluyo el Precio Disponible';
	END IF;
END$$

DELIMITER ;

-- Se busco en internet como modificar el campo edad (ya que no se pudo realizar directo el calculo en la generación de la tabla.
-- https://stackoverflow.com/questions/11448068/mysql-error-code-1175-during-update-in-mysql-workbench
SET SQL_SAFE_UPDATES = 0;

UPDATE Vendedores
SET Edad = TIMESTAMPDIFF(YEAR, Fecha_Nacimiento, CURDATE());

SET SQL_SAFE_UPDATES = 1;

-- Insersión de datos a las tablas

INSERT INTO Localidades (Ciudad, Provincia, Region) VALUES
('Madrid', 'Madrid', 'Centro'),
('Barcelona', 'Cataluña', 'Noreste'),
('Sevilla', 'Andalucía', 'Sur'),
('Bilbao', 'País Vasco', 'Norte'),
('Valencia', 'Valencia', 'Este');

INSERT INTO Listado_Contactos (Nombre_Apellido, Email, Telefono, Interno, Celular) VALUES
('Juan Pérez', 'jperez@correo.com', 914567123, 101, 699874521),
('Ana López', 'alopez@correo.com', 932143567, 102, 655321478),
('Carlos García', 'cgarcia@correo.com', 955327894, 103, 611234567),
('Lucía Martínez', 'lmartinez@correo.com', 944128745, 104, 671234567),
('Miguel Torres', 'mtorres@correo.com', 961324756, 105, 681234567);

INSERT INTO Proveedores (Tipo_Proveedor, Denominacion_Social, Razon_Social, CUIT, ID_Contacto, Direccion, ID_Localidad) VALUES
('Electrónica', 'ElectroSpain SA', 'ElectroSpain SA', '30567891234', 1, 'Calle Mayor 1', 1),
('Muebles', 'Muebles Europa', 'Muebles Europa SRL', '30785678912', 2, 'Calle de las Flores 22', 2),
('Electrodomésticos', 'HomeAppliances', 'HomeAppliances Corp', '30891234567', 3, 'Avenida del Parque 14', 3),
('Electrónica', 'Tecnología Global', 'Tecnología Global SL', '30567854321', 4, 'Calle Nueva 9', 4),
('Muebles', 'Interiores Modernos', 'Interiores Modernos SL', '30678901234', 5, 'Plaza Central 5', 5);

INSERT INTO Clientes (Tipo_Cliente, Denominacion_Social, Razon_Social, CUIT, ID_Contacto, Direccion, ID_Localidad) VALUES
('Minorista', 'Distribuciones X', 'Distribuciones X SA', '30512345678', 1, 'Gran Vía 30', 1),
('Mayorista', 'Comercial Z', 'Comercial Z SL', '30678912345', 2, 'Avenida del Sol 5', 2),
('Minorista', 'Electro Market', 'Electro Market SRL', '30765432198', 3, 'Calle Luna 12', 3),
('Mayorista', 'MegaCompras', 'MegaCompras SRL', '30876543219', 4, 'Plaza Mayor 8', 4),
('Minorista', 'VentaDirecta', 'VentaDirecta SL', '30987654321', 5, 'Calle Estrella 7', 5);

INSERT INTO SubCategorias (SubCategoria) VALUES
('Televisores'),
('Refrigeradores'),
('Lavadoras'),
('Hornos'),
('Microondas');

INSERT INTO Categorias (Categoria, ID_SubCategoria) VALUES
('TV LCD', 1),
('Frigorífico Doble', 2),
('Lavadora Automática', 3),
('Horno Eléctrico', 4),
('Microondas Digital', 5);

INSERT INTO Productos (Producto, ID_Categoria, Fecha_Alta) VALUES
('Samsung 32 pulgadas', 1, '2025-01-01'),
('LG Frigorífico', 2, '2025-01-02'),
('Whirlpool Lavadora', 3, '2025-01-03'),
('Teka Horno Eléctrico', 4, '2025-01-04'),
('Panasonic Microondas', 5, '2025-01-05');

INSERT INTO Partes_De_Produccion (Pedido_De_Produccion, Estado, Fecha_Inicio, Fecha_Finalizacion, ID_Producto, Cantidad, Costo_Por_Unidad) VALUES
(101, 'Finalizado', '2025-01-01', '2025-01-02', 1, 100, 250.00),
(102, 'En proceso', '2025-01-03', NULL, 2, 50, 1000.00),
(103, 'Finalizado', '2025-01-02', '2025-01-04', 3, 75, 450.00),
(104, 'Finalizado', '2025-01-01', '2025-01-03', 4, 40, 320.00),
(105, 'En proceso', '2025-01-04', NULL, 5, 90, 85.00);

INSERT INTO Stock_Bienes_Finalizados (ID_Producto, Cantidad, Precio, Ultimo_Costo_Fabricado) VALUES
(1, 100, 300.00, 250.00),
(2, 50, 1200.00, 1000.00),
(3, 75, 500.00, 450.00),
(4, 40, 350.00, 320.00),
(5, 90, 100.00, 85.00);

INSERT INTO Tiendas (Tienda, Cantidad_Vendedores, Direccion, ID_Localidad) VALUES
('Electro Store', 5, 'Calle Comercio 15', 1),
('Home Store', 3, 'Avenida Centro 45', 2),
('Tech Shop', 4, 'Plaza del Mercado 3', 3),
('E-Shop', 6, 'Calle Mayor 19', 4),
('MegaElectro', 7, 'Calle Sol 22', 5);

INSERT INTO Vendedores (Legajo, Vendedor, Tipo_Documento, DOC_N°, Fecha_Nacimiento, Edad, Domicilio, ID_Localidad, Especialidad_De_Venta, Titulo) VALUES
(101, 'Pedro González', 'DNI', 12345678, '1990-01-01', 35, 'Calle Prado 2', 1, 'Electrónica', 'Licenciado'),
(102, 'Marta Ruiz', 'DNI', 87654321, '1985-05-15', 40, 'Avenida Flores 10', 2, 'Muebles', 'Ingeniera'),
(103, 'Carlos Díaz', 'DNI', 13579246, '1992-02-20', 33, 'Calle Verde 7', 3, 'Electrodomésticos', 'Licenciado'),
(104, 'Ana Torres', 'DNI', 24681357, '1988-11-10', 37, 'Calle Azul 9', 4, 'Electrónica', 'Técnica'),
(105, 'Luis Pérez', 'DNI', 97531248, '1990-12-25', 35, 'Calle Blanca 15', 5, 'Muebles', 'Licenciado');

INSERT INTO Ventas (Fecha, Factura, ID_Producto, ID_Cliente, ID_Tienda, ID_Vendedor, Cantidad, Precio_Venta, Precio_Actualizado, Otros_Impuestos) VALUES
('2025-01-10', 1001, 1, 1, 1, 1, 10, 300.00, 300.00, 15.00),
('2025-01-12', 1002, 2, 2, 2, 2, 5, 1200.00, 1200.00, 20.00),
('2025-01-14', 1003, 3, 3, 3, 3, 7, 500.00, 500.00, 25.00),
('2025-01-15', 1004, 4, 4, 4, 4, 3, 350.00, 350.00, 10.00),
('2025-01-16', 1005, 5, 5, 5, 5, 12, 100.00, 100.00, 8.00);

INSERT INTO Int_Cliente_Ventas (ID_Venta, ID_Cliente) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5);

INSERT INTO Int_Producto_Ventas (ID_Venta, ID_Producto) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5);

-- Armado de las Vistas

-- Vista 1: Conjunto de los Proveedores con las Localidades

CREATE VIEW V_Proveedores_Localidades AS
SELECT p.ID_Proveedores,
	   p.Razon_Social,
       p.Direccion,
       l.Ciudad,
       l.Provincia,
       l.Region
FROM Proveedores p
JOIN Localidades l ON p.ID_Localidad = l.ID_Localidad;

-- Prueba de la Vista 1 SELECT * FROM V_Proveedores_Localidades;

CREATE VIEW Ganancia_Por_Categoria AS
SELECT 
    c.Categoria,
    SUM(v.Importe_Final) AS Total_Venta,
    SUM(s.Ultimo_Costo_Fabricado * v.Cantidad) AS Total_Costo,
    SUM(v.Importe_Final) - SUM(s.Ultimo_Costo_Fabricado * v.Cantidad) AS Ganancia_Bruta
FROM 
    Ventas v
JOIN 
    Productos p ON v.ID_Producto = p.ID_Producto
JOIN 
    Categorias c ON p.ID_Categoria = c.ID_Categoria
JOIN 
    Stock_Bienes_Finalizados s ON p.ID_Producto = s.ID_Producto
GROUP BY 
    c.Categoria;

-- Prueba de la Vista 2 SELECT * FROM Ganancia_Por_Categoria;

-- Armado de las Funciones

-- Función 1: Calculo de la Ganancia de las Ventas

DELIMITER $$

CREATE FUNCTION Calcular_Ganancia_Bruta() 
RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    DECLARE Total_Costo DECIMAL(10, 2);
    DECLARE Total_Venta DECIMAL(10, 2);
    DECLARE Ganancia_Bruta DECIMAL(10, 2);
    
    SELECT SUM(s.Ultimo_Costo_Fabricado * v.Cantidad)
    INTO Total_Costo
    FROM Ventas v
    JOIN Stock_Bienes_Finalizados s ON v.ID_Producto = s.ID_Producto;

    SELECT SUM(v.Importe_Final)
    INTO Total_Venta
    FROM Ventas v;

    SET Ganancia_Bruta = Total_Venta - Total_Costo;
    RETURN Ganancia_Bruta;
END$$

DELIMITER ;

-- Prueba de la Función 1 SELECT Calcular_Ganancia_Bruta() AS Ganancia_Bruta;

-- Función 2: Calculo de la Ganancia Neta

DELIMITER $$

CREATE FUNCTION Calcular_Gcia_Neta(CostosFijos DECIMAL(10,2), Impuestos DECIMAL(10,2)) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE GananciaNetaTotal DECIMAL(10,2);

    -- Calculamos la ganancia neta total y la agregamos a la variable
    SELECT SUM(Precio_Venta * Cantidad) - CostosFijos - Impuestos
    INTO GananciaNetaTotal
    FROM Ventas;
    RETURN GananciaNetaTotal;
END $$

DELIMITER ;

-- Prueba de la Función 2 SELECT Calcular_Gcia_Neta(500.00, 200.00);

-- Armado de Store Procedure

-- Store Procedure 1: 

CREATE TABLE Input_DS(
    Fecha DATE,
    Factura INT,
    ID_Producto INT,
    Nombre_Producto VARCHAR(255),
    ID_Categoria INT,
    ID_Tienda INT,
    Nombre_Tienda VARCHAR(255),
    Ubicacion_Tienda VARCHAR(255),
    ID_Vendedor INT,
    Nombre_Vendedor VARCHAR(255),
    Cantidad INT,
    Precio_Venta DECIMAL(10, 2),
    Precio_Actualizado DECIMAL(10, 2),
    Otros_Impuestos DECIMAL(10, 2)
);

DELIMITER $$

CREATE PROCEDURE Data_Science()
BEGIN
    INSERT INTO Input_DS (
        Fecha, Factura, ID_Producto, Nombre_Producto, ID_Categoria, 
        ID_Tienda, Nombre_Tienda, Ubicacion_Tienda, 
        ID_Vendedor, Nombre_Vendedor, Cantidad, Precio_Venta, Precio_Actualizado, Otros_Impuestos
    )
    SELECT DISTINCT
        v.Fecha, v.Factura, v.ID_Producto, p.Producto AS Nombre_Producto, p.ID_Categoria,
        v.ID_Tienda, t.Tienda AS Nombre_Tienda, t.Direccion AS Ubicacion_Tienda,
        v.ID_Vendedor, vd.Vendedor AS Nombre_Vendedor, v.Cantidad, v.Precio_Venta, v.Precio_Actualizado, v.Otros_Impuestos
    FROM Ventas v
    INNER JOIN Productos p ON v.ID_Producto = p.ID_Producto
    INNER JOIN Tiendas t ON v.ID_Tienda = t.ID_Tienda
    INNER JOIN Vendedores vd ON v.ID_Vendedor = vd.ID_Vendedor;
END $$

DELIMITER ;

-- Prueba del Procedimiento Almacenado 1: CALL Data_Science(); SELECT * FROM Input_DS;

-- Armado de Tabla LOG (Bitacora) con el TRIGGER

-- La empresa mantiene la política de NO ELIMINAR ningun dato, por lo cual, lo haremos solo para el caso de MODIFICACIONES.
-- Se hará sobre la tabla producto para este caso en concreto.

CREATE TABLE product_log (
	log_id INT AUTO_INCREMENT PRIMARY KEY,
    ID_Producto INT,
    Producto VARCHAR(50),
    ID_Categoria INT,
    first_date DATE,
    last_date DATE,
    action VARCHAR(20),
    performed_by VARCHAR(100),
    log_date DATETIME
);

DELIMITER $$

CREATE TRIGGER before_update_log
BEFORE UPDATE ON Productos
FOR EACH ROW
BEGIN

	INSERT INTO product_log (ID_Producto, Producto, ID_Categoria, last_date, action, performed_by, log_date)
    VALUES (
		OLD.ID_Producto,
        OLD.Producto,
        OLD.ID_Categoria,
        NOW(),
        'MODIFIED',
        CURRENT_USER,
        NOW()
	);
END$$

DELIMITER ;

-- Prueba del la tabla log (quitar "-" para probar funcionamiento):

-- SELECT * FROM Productos WHERE ID_Producto = 3 AND ID_Categoria = 3;

-- UPDATE Productos 
-- SET Producto = 'Lavarropas High Quality' 
-- WHERE ID_Producto = 3;

-- SELECT * FROM product_log;
