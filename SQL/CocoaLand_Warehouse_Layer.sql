CREATE SCHEMA warehouse;

---------------------------------------------------------
----- Creating dim tables for the warehouse schema ------
---------------------------------------------------------




----------------------------
------- dim_Products -------
----------------------------

CREATE TABLE warehouse.dim_Products (
    Product_Key     INT IDENTITY(1,1) PRIMARY KEY,
    Product_ID      NVARCHAR(10)  NOT NULL UNIQUE,
    Product_Name    NVARCHAR(30),
    Cocoa_Content_Pct DECIMAL(5,2),
    Unit_Price_USD  DECIMAL(10,2),
    Weight_g        INT,
    Primary_Materials NVARCHAR(30),
    Launch_Date     NVARCHAR(10),
    Is_Active       NVARCHAR(5)
);


INSERT INTO warehouse.dim_Products 
(Product_ID, Product_Name,Cocoa_Content_Pct, Unit_Price_USD, Weight_g, Primary_Materials, Launch_Date, Is_Active)

SELECT
    TRIM(Product_ID),
    TRIM(Product_Name),
    TRY_CAST(Cocoa_Content_Pct  AS DECIMAL(5,2)),
    TRY_CAST(Unit_Price_USD     AS DECIMAL(10,2)),
    TRY_CAST(Weight_g AS INT),
    TRY_CAST(Primary_Materials AS NVARCHAR(30)),
    -- Standardise to dd/mm/yyyy regardless of source format
    FORMAT(TRY_CAST(Launch_Date AS DATE), 'dd/MM/yyyy'),
    TRIM(Is_Active)
FROM staging.stg_01_CocoaLand_Products_Master_Cleaned_v1;


DROP TABLE warehouse.dim_Products
SELECT* FROM warehouse.dim_Products;


----------------------------
--- dim_Warehouse_Master ---
----------------------------


CREATE TABLE warehouse.dim_Warehouse_Master (
    Warehouse_Key INT IDENTITY(1,1) PRIMARY KEY,
    Warehouse_ID NVARCHAR(10)  NOT NULL UNIQUE,
    Warehouse_Name NVARCHAR(30),
    Country NVARCHAR(20),
    Region NVARCHAR(30),
    Capacity_MT DECIMAL(12,2),
    Is_Active NVARCHAR(5),
);


INSERT INTO warehouse.dim_Warehouse_Master 
(Warehouse_ID, Warehouse_Name, Country, Region, Capacity_MT, Is_Active)

SELECT
    TRIM(Warehouse_ID),
    TRIM(Warehouse_Name),
    TRY_CAST(Country  AS NVARCHAR(20)),
    TRY_CAST(Region AS NVARCHAR(30)),
    TRY_CAST(Capacity_MT AS DECIMAL(12,2)),
    TRIM(Is_Active)
FROM staging.stg_02_CocoaLand_Warehouse_Master_Cleaned_v1;


SELECT* FROM warehouse.dim_Warehouse_Master;


----------------------------
----- dim_Raw_Materials ----
----------------------------

CREATE TABLE warehouse.dim_Raw_Materials (
    Material_Key INT IDENTITY(1,1) PRIMARY KEY,
    Material_ID  NVARCHAR(10)  NOT NULL UNIQUE,
    Material_Name NVARCHAR(20),
    Category      NVARCHAR(30),
    Unit_Cost_USD DECIMAL(12,2),
    Unit_of_Measure NVARCHAR(10),
);


INSERT INTO warehouse.dim_Raw_Materials
(Material_ID, Material_Name, Category, Unit_Cost_USD, Unit_of_Measure)

SELECT
    TRIM(Material_ID),
    TRIM(Material_Name),
    TRY_CAST(Category  AS NVARCHAR(30)),
    TRY_CAST(Unit_Cost_USD AS DECIMAL(12,2)),
    TRY_CAST(Unit_of_Measure AS NVARCHAR(10))
FROM staging.stg_03_CocoaLand_Raw_Materials_Master_Cleaned_v1;


SELECT* FROM warehouse.dim_Raw_Materials;
DROP TABLE warehouse.dim_Raw_Materials;


----------------------------
------ dim_Suppliers -------
----------------------------

CREATE TABLE warehouse.dim_Suppliers (
    Supplier_Key INT IDENTITY(1,1) PRIMARY KEY,
    Supplier_ID  NVARCHAR(10)  NOT NULL UNIQUE,
    Category NVARCHAR(20),
    Country      NVARCHAR(30),
    Avg_Lead_Time_Days      DECIMAL(5,1),
    On_Time_Rate      DECIMAL(5,2),
    Defect_Rate_pct      DECIMAL(5,2),
    Quality_Score_Out_of_5      DECIMAL(5,2),
    Last_Audit_Date      NVARCHAR(20),
    Certification_Status      NVARCHAR(20),
);


INSERT INTO warehouse.dim_Suppliers
(Supplier_ID, Category, Country, Avg_Lead_Time_Days, 
On_Time_Rate, Defect_Rate_pct, Quality_Score_Out_of_5, Last_Audit_Date, Certification_Status)

SELECT
    TRIM(Supplier_ID),
    TRIM(Category),
    TRIM(Country),
    TRY_CAST(Avg_Lead_Time_Days AS DECIMAL(5,1)),
    TRY_CAST(On_Time_Rate          AS DECIMAL(5,2)),
    TRY_CAST(Defect_Rate_pct       AS DECIMAL(5,2)),
    TRY_CAST(Quality_Score_Out_of_5 AS DECIMAL(5,2)),
    TRIM(Last_Audit_Date),
    TRIM(Certification_Status)
FROM staging.stg_04_CocoaLand_Suppliers_Cleaned_v1;

DROP TABLE warehouse.dim_Suppliers;
SELECT* FROM warehouse.dim_Suppliers;


----------------------------
------ dim_Customers -------
----------------------------

CREATE TABLE warehouse.dim_Customers (
    Customer_Key INT IDENTITY(1,1) PRIMARY KEY,
    Customer_ID NVARCHAR(10) NOT NULL UNIQUE,
    Region NVARCHAR(30),
);


INSERT INTO warehouse.dim_Customers
(Customer_ID, Region)

SELECT DISTINCT
    TRIM(Customer_ID),
    TRIM(Region)
FROM staging.stg_09_CocoaLand_Orders_Cleaned_v1;

DROP TABLE warehouse.dim_Customers;
SELECT* FROM warehouse.dim_Customers;


----------------------------
--------- dim_Date ---------
----------------------------

CREATE TABLE warehouse.dim_Date (

    Date_Key INT PRIMARY KEY,
    Full_Date DATE NOT NULL,
    Day_Name NVARCHAR(20),
    Month_Name NVARCHAR(20),
    Month_Number TINYINT,
    Quarter TINYINT,
    Year SMALLINT,
    Week_Number TINYINT
);


WITH dates AS (

    SELECT CAST('2025-01-01' AS DATE) AS d

    UNION ALL

    SELECT DATEADD(DAY, 1, d)
    FROM dates
    WHERE d < '2026-02-28'
)

INSERT INTO warehouse.dim_Date (

    Date_Key,
    Full_Date,
    Day_Name,
    Month_Name,
    Month_Number,
    Quarter,
    Year,
    Week_Number
)

SELECT

    CAST(FORMAT(d, 'yyyyMMdd') AS INT) AS Date_Key,

    d AS Full_Date,

    DATENAME(WEEKDAY, d) AS Day_Name,

    DATENAME(MONTH, d) AS Month_Name,

    MONTH(d) AS Month_Number,

    DATEPART(QUARTER, d) AS Quarter,

    YEAR(d) AS Year,

    DATEPART(WEEK, d) AS Week_Number

FROM dates

OPTION (MAXRECURSION 1000);



DROP TABLE warehouse.dim_Date;
SELECT* FROM warehouse.dim_Date;



---------------------------------------------------------
----- Creating fact tables for the warehouse schema -----
---------------------------------------------------------



----------------------------
-------- fact_Sales --------
----------------------------

CREATE TABLE warehouse.fact_Sales (
    Sales_Key BIGINT IDENTITY(1,1) PRIMARY KEY,
    Sales_Order_ID NVARCHAR(20) NOT NULL,
    Shipment_ID NVARCHAR(20) NOT NULL,
    Product_Key INT NOT NULL,
    Customer_Key INT NOT NULL,
    Warehouse_Key INT NOT NULL,
    Order_Date_Key INT NOT NULL,
    Status_Date_Key INT NOT NULL,
    Order_Qty INT,
    Unit_Price_USD DECIMAL(10,2),
    Total_Value_USD DECIMAL(12,2),
    Fulfillment_Status NVARCHAR(30),
    Fulfillment_Days INT
);



INSERT INTO warehouse.fact_Sales (
    Sales_Order_ID,
    Shipment_ID,
    Product_Key,
    Customer_Key,
    Warehouse_Key,
    Order_Date_Key,
    Status_Date_Key,
    Order_Qty,
    Unit_Price_USD,
    Total_Value_USD,
    Fulfillment_Status,
    Fulfillment_Days
)

SELECT
    TRIM(so.Sales_Order_ID),
    TRIM(so.Shipment_ID),
    p.Product_Key,
    c.Customer_Key,
    w.Warehouse_Key,
    od.Date_Key,
    sd.Date_Key,
    TRY_CAST(so.Order_Qty AS INT),
    TRY_CAST(so.Unit_Price_USD AS DECIMAL(10,2)),
    TRY_CAST(so.Total_Value_USD AS DECIMAL(12,2)),
    TRIM(so.Fulfillment_Status),
    DATEDIFF(
        DAY,
        TRY_CAST(so.Order_Date AS DATE),
        TRY_CAST(so.Status_Date AS DATE)
    )

FROM staging.stg_09_CocoaLand_Orders_Cleaned_v1 so


JOIN warehouse.dim_Products p
    ON TRIM(so.Product_ID) = TRIM(p.Product_ID)

JOIN warehouse.dim_Customers c
    ON TRIM(so.Customer_ID) = TRIM(c.Customer_ID)

JOIN warehouse.dim_Warehouse_Master w
    ON TRIM(so.Warehouse_ID) = TRIM(w.Warehouse_ID)

JOIN warehouse.dim_Date od
    ON od.Full_Date = TRY_CAST(so.Order_Date AS DATE)

JOIN warehouse.dim_Date sd
    ON sd.Full_Date = TRY_CAST(so.Status_Date AS DATE);


DROP TABLE warehouse.fact_Sales;
SELECT * FROM warehouse.fact_Sales;




---------------------------------
-- fact_RawMaterials_Inventory --
---------------------------------


CREATE TABLE warehouse.fact_RawMaterials_Inventory (
Stock_Key INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
Material_Key INT NOT NULL,
Warehouse_Key INT NOT NULL,
Current_Stock_RM INT NOT NULL,
Last_Updated_Key INT NOT NULL,
RM_Order_Level INT NOT NULL,
Stock_Status NVARCHAR(20)
)

INSERT INTO warehouse.fact_RawMaterials_Inventory 
(Material_Key, Warehouse_Key, Current_Stock_RM, Last_Updated_Key, RM_Order_Level, Stock_Status)

SELECT 
rm.Material_Key,
w.Warehouse_Key,
TRY_CAST(Current_Stock_RM AS INT),
od.Date_Key AS Last_Updated_Key,
TRY_CAST(RM_Reorder_Level AS INT),
TRIM(Stock_Status)


FROM staging.stg_07_CocoaLand_Warehouse_Inventory_RawMaterials_Cleaned_v1 AS sm

JOIN warehouse.dim_Raw_Materials AS rm
ON TRIM(sm.Material_ID) = TRIM(rm.Material_ID)
JOIN warehouse.dim_Warehouse_Master AS w
ON TRIM(sm.Warehouse_ID) = TRIM(w.Warehouse_ID)
JOIN warehouse.dim_Date od
ON od.Full_Date = TRY_CAST(sm.Last_Updated AS DATE);


DROP TABLE warehouse.fact_RawMaterials_Inventory;
SELECT* FROM warehouse.fact_RawMaterials_Inventory;



---------------------------------
-- fact_Products_Inventory --
---------------------------------


CREATE TABLE warehouse.fact_Products_Inventory (
Stock_Key INT IDENTITY(1,1) PRIMARY KEY,
Product_Key INT NOT NULL,
Warehouse_Key INT NOT NULL,
Current_Stock_Prod INT NOT NULL,
Last_Updated_Key INT NOT NULL,
Stock_Status NVARCHAR(20)
)

INSERT INTO warehouse.fact_Products_Inventory 
(Product_Key, Warehouse_Key, Current_Stock_Prod, Last_Updated_Key, Stock_Status)

SELECT 
p.Product_Key,
w.warehouse_Key,
TRY_CAST(Current_Stock_Prod AS INT),
od.Date_Key AS Last_Updated_Key,
TRIM(Stock_Status)


FROM staging.stg_08_CocoaLand_Warehouse_Inventory_Products_Cleaned_v1 AS sp

JOIN warehouse.dim_Warehouse_Master AS w
ON TRIM(sp.Warehouse_ID) = TRIM(w.Warehouse_ID)
JOIN warehouse.dim_Products AS p
ON TRIM(sp.Product_ID) = TRIM(p.Product_ID)
JOIN warehouse.dim_Date od
ON od.Full_Date = TRY_CAST(sp.Last_Updated AS DATE);


DROP TABLE warehouse.fact_Products_Inventory;
SELECT* FROM warehouse.fact_Products_Inventory;



---------------------------------
--------- fact_Movements --------
---------------------------------


CREATE TABLE warehouse.fact_Movements (
Movement_Key BIGINT IDENTITY(1,1) PRIMARY KEY,
Movement_ID NVARCHAR(20) NOT NULL,
Material_Key INT NOT NULL,
Quantity_RM INT NOT NULL,
Product_Key INT NOT NULL,
Quantity_Prod INT NOT NULL,
Warehouse_Key INT NOT NULL,
Movement_Type NVARCHAR(5) NOT NULL,
Movement_Date_Key INT NOT NULL,
Reference NVARCHAR(20) NOT NULL
)

INSERT INTO warehouse.fact_Movements 
(Movement_ID, Material_Key, Quantity_RM, Product_Key, Quantity_Prod, Warehouse_Key, Movement_Type, Movement_Date_Key, Reference)

SELECT 
TRIM(m.Movement_ID) AS  Movement_ID,
rm.Material_Key,
TRY_CAST(m.Quantity_RM AS INT) AS Quantity_RM,
pd.Product_Key,
TRY_CAST(m.Quantity_Prod AS INT) AS Quantity_Prod,
w.Warehouse_Key,
TRIM(m.Movement_Type) Movement_Type,
md.Date_Key AS Movement_Date_Key,
TRIM(m.Reference) AS Reference


FROM staging.stg_06_CocoaLand_Stock_Movements_Cleaned_v1 AS m

JOIN warehouse.dim_Products AS pd
ON TRIM(m.Product_ID) = pd.Product_ID
JOIN warehouse.dim_Raw_Materials AS rm
ON TRIM(m.Material_ID) = rm.Material_ID
JOIN warehouse.dim_Warehouse_Master AS w
ON TRIM(m.Warehouse_ID) = w.Warehouse_ID
JOIN warehouse.dim_Date md
ON md.Full_Date = TRY_CAST(m.Movement_Date AS DATE);



DROP TABLE warehouse.fact_Movements;
SELECT COUNT(*) FROM warehouse.fact_Movements;



---------------------------------
--------- fact_Purchase --------
---------------------------------


CREATE TABLE warehouse.fact_Purchase (
Purchase_Key BIGINT IDENTITY(1,1) PRIMARY KEY,
PO_ID NVARCHAR(20) NOT NULL,
PO_Line_ID NVARCHAR(20) NOT NULL,
Supplier_Key INT NOT NULL,
Order_Date_Key INT NOT NULL,
Expected_Delivery_Date_Key INT NOT NULL,
PO_Status NVARCHAR(30) NOT NULL,
Material_Key INT NOT NULL,
Quantity INT NOT NULL,
Unit_Cost_USD DECIMAL(10,2) NOT NULL,
Line_Total_USD DECIMAL(10,2) NOT NULL,
Total_PO_USD DECIMAL(10,2) NOT NULL,
)


INSERT INTO warehouse.fact_Purchase 
(PO_ID, PO_Line_ID, Supplier_Key, Order_Date_Key, Expected_Delivery_Date_Key, PO_Status, Material_Key,
Quantity, Unit_Cost_USD, Line_Total_USD, Total_PO_USD)

SELECT 
TRIM(p.PO_ID) AS  PO_ID,
TRIM(p.PO_Line_ID) AS  PO_Line_ID,
s.Supplier_Key AS Supplier_Key,
od.Date_Key AS Order_Date_Key,
ed.Date_Key AS Expected_Delivery_Date_Key,
TRIM(PO_Status),
rm.Material_Key AS Material_Key,
TRY_CAST(p.Quantity AS INT) AS Quantity,
TRY_CAST(p.Unit_Cost_USD AS DECIMAL(10,2)) AS Unit_Cost_USD,
TRY_CAST(p.Line_Total_USD AS DECIMAL(10,2)) AS Line_Total_USD,
TRY_CAST(p.Total_PO_USD AS DECIMAL(10,2)) AS Total_PO_USD

FROM staging.stg_05_CocoaLand_Purchase_Orders_Cleaned_v1 AS p


JOIN warehouse.dim_Suppliers AS s
ON TRIM(p.Supplier_ID) = TRIM(s.Supplier_ID)
JOIN warehouse.dim_Raw_Materials AS rm
ON TRIM(p.Material_ID) = TRIM(rm.Material_ID)
JOIN warehouse.dim_Date od
    ON od.Full_Date = COALESCE(TRY_CONVERT(DATE, p.Order_Date, 103), 
    TRY_CONVERT(DATE, p.Order_Date, 101))
JOIN warehouse.dim_Date ed
    ON ed.Full_Date =
       TRY_CONVERT(DATE, p.Expected_Delivery_Date, 103);



DROP TABLE warehouse.fact_Purchase;
SELECT * FROM warehouse.fact_Purchase;



------------------------------------------
---- INDEXES FOR warehouse.fact_Sales ----
------------------------------------------


CREATE INDEX idx_factSales_ProductKey
ON warehouse.fact_Sales(Product_Key);


CREATE INDEX idx_factSales_CustomerKey
ON warehouse.fact_Sales(Customer_Key);


CREATE INDEX idx_factSales_WarehouseKey
ON warehouse.fact_Sales(Warehouse_Key);


CREATE INDEX idx_factSales_OrderDateKey
ON warehouse.fact_Sales(Order_Date_Key);


CREATE INDEX idx_factSales_StatusDateKey
ON warehouse.fact_Sales(Status_Date_Key);




------------------------------------------
-- INDEXES FOR warehouse.fact_Purchase ---
------------------------------------------


CREATE INDEX idx_factPurchase_SupplierKey
ON warehouse.fact_Purchase(Supplier_Key);


CREATE INDEX idx_factPurchase_MaterialKey
ON warehouse.fact_Purchase(Material_Key);


CREATE INDEX idx_factPurchase_OrderDateKey
ON warehouse.fact_Purchase(Order_Date_Key);


CREATE INDEX idx_factPurchase_ExpectedDeliveryDateKey
ON warehouse.fact_Purchase(Expected_Delivery_Date_Key);




------------------------------------------
-- INDEXES FOR warehouse.fact_Movements --
------------------------------------------


CREATE INDEX idx_factMovements_MaterialKey
ON warehouse.fact_Movements(Material_Key);


CREATE INDEX idx_factMovements_ProductKey
ON warehouse.fact_Movements(Product_Key);


CREATE INDEX idx_factMovements_WarehouseKey
ON warehouse.fact_Movements(Warehouse_Key);


CREATE INDEX idx_factMovements_MovementDateKey
ON warehouse.fact_Movements(Movement_Date_Key);







-------------------------------------
----- FOREIGN KEYS — fact_Sales -----
-------------------------------------



ALTER TABLE warehouse.fact_Sales
ADD CONSTRAINT FK_factSales_Product
FOREIGN KEY (Product_Key)
REFERENCES warehouse.dim_Products(Product_Key);


ALTER TABLE warehouse.fact_Sales
ADD CONSTRAINT FK_factSales_Customer
FOREIGN KEY (Customer_Key)
REFERENCES warehouse.dim_Customers(Customer_Key);


ALTER TABLE warehouse.fact_Sales
ADD CONSTRAINT FK_factSales_Warehouse
FOREIGN KEY (Warehouse_Key)
REFERENCES warehouse.dim_Warehouse_Master(Warehouse_Key);


ALTER TABLE warehouse.fact_Sales
ADD CONSTRAINT FK_factSales_OrderDate
FOREIGN KEY (Order_Date_Key)
REFERENCES warehouse.dim_Date(Date_Key);


ALTER TABLE warehouse.fact_Sales
ADD CONSTRAINT FK_factSales_StatusDate
FOREIGN KEY (Status_Date_Key)
REFERENCES warehouse.dim_Date(Date_Key);




-------------------------------------
--- FOREIGN KEYS — fact_Purchase ----
-------------------------------------



ALTER TABLE warehouse.fact_Purchase
ADD CONSTRAINT FK_factPurchase_Supplier
FOREIGN KEY (Supplier_Key)
REFERENCES warehouse.dim_Suppliers(Supplier_Key);


ALTER TABLE warehouse.fact_Purchase
ADD CONSTRAINT FK_factPurchase_Material
FOREIGN KEY (Material_Key)
REFERENCES warehouse.dim_Raw_Materials(Material_Key);


ALTER TABLE warehouse.fact_Purchase
ADD CONSTRAINT FK_factPurchase_OrderDate
FOREIGN KEY (Order_Date_Key)
REFERENCES warehouse.dim_Date(Date_Key);


ALTER TABLE warehouse.fact_Purchase
ADD CONSTRAINT FK_factPurchase_ExpectedDeliveryDate
FOREIGN KEY (Expected_Delivery_Date_Key)
REFERENCES warehouse.dim_Date(Date_Key);




-------------------------------------
--- FOREIGN KEYS — fact_Movements ---
-------------------------------------



ALTER TABLE warehouse.fact_Movements
ADD CONSTRAINT FK_factMovements_Material
FOREIGN KEY (Material_Key)
REFERENCES warehouse.dim_Raw_Materials(Material_Key);


ALTER TABLE warehouse.fact_Movements
ADD CONSTRAINT FK_factMovements_Product
FOREIGN KEY (Product_Key)
REFERENCES warehouse.dim_Products(Product_Key);


ALTER TABLE warehouse.fact_Movements
ADD CONSTRAINT FK_factMovements_Warehouse
FOREIGN KEY (Warehouse_Key)
REFERENCES warehouse.dim_Warehouse_Master(Warehouse_Key);


ALTER TABLE warehouse.fact_Movements
ADD CONSTRAINT FK_factMovements_Date
FOREIGN KEY (Movement_Date_Key)
REFERENCES warehouse.dim_Date(Date_Key);




--------------------------------------------
-- FOREIGN KEYS — fact_Products_Inventory --
--------------------------------------------



ALTER TABLE warehouse.fact_Products_Inventory
ADD CONSTRAINT FK_factProductsInventory_Product
FOREIGN KEY (Product_Key)
REFERENCES warehouse.dim_Products(Product_Key);


ALTER TABLE warehouse.fact_Products_Inventory
ADD CONSTRAINT FK_factProductsInventory_Warehouse
FOREIGN KEY (Warehouse_Key)
REFERENCES warehouse.dim_Warehouse_Master(Warehouse_Key);


ALTER TABLE warehouse.fact_Products_Inventory
ADD CONSTRAINT FK_factProductsInventory_Date
FOREIGN KEY (Last_Updated_Key)
REFERENCES warehouse.dim_Date(Date_Key);




------------------------------------------------
-- FOREIGN KEYS — fact_RawMaterials_Inventory --
------------------------------------------------



ALTER TABLE warehouse.fact_RawMaterials_Inventory
ADD CONSTRAINT FK_factRMInventory_Material
FOREIGN KEY (Material_Key)
REFERENCES warehouse.dim_Raw_Materials(Material_Key);


ALTER TABLE warehouse.fact_RawMaterials_Inventory
ADD CONSTRAINT FK_factRMInventory_Warehouse
FOREIGN KEY (Warehouse_Key)
REFERENCES warehouse.dim_Warehouse_Master(Warehouse_Key);


ALTER TABLE warehouse.fact_RawMaterials_Inventory
ADD CONSTRAINT FK_factRMInventory_Date
FOREIGN KEY (Last_Updated_Key)
REFERENCES warehouse.dim_Date(Date_Key);