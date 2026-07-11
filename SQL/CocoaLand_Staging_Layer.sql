-- Create a dedicated staging schema
CREATE SCHEMA staging;
GO

-- One table per CSV, column names match CSV headers exactly
-- Use NVARCHAR for everything — don't enforce types yet
CREATE TABLE staging.stg_09_CocoaLand_Orders_Cleaned_v1 (
    Sales_Order_ID    NVARCHAR(20),
    Customer_ID       NVARCHAR(20),
    Region            NVARCHAR(50),
    Product_ID        NVARCHAR(10),
    Order_Qty         NVARCHAR(20),   -- keep as string, cast later
    Unit_Price_USD    NVARCHAR(20),
    Total_Value_USD   NVARCHAR(20),
    Order_Date        NVARCHAR(30),   -- dates as strings — parse in warehouse layer
    Warehouse_ID      NVARCHAR(10),
    Shipment_ID       NVARCHAR(20),
    Fulfillment_Status NVARCHAR(30),
    Status_Date       NVARCHAR(30),
    Loaded_At         DATETIME DEFAULT GETDATE()  -- audit column
);

SELECT COUNT(*) FROM staging.stg_09_CocoaLand_Orders_Cleaned_v1

-- One table per CSV, column names match CSV headers exactly
-- Use NVARCHAR for everything — don't enforce types yet
CREATE TABLE staging.stg_08_CocoaLand_Warehouse_Inventory_Products_Cleaned_v1 (
    Product_ID    NVARCHAR(20),
    Warehouse_ID       NVARCHAR(20),
    Current_Stock_Prod  NVARCHAR(50),
    Last_Updated        NVARCHAR(20),
    Stock_Status         NVARCHAR(20),   -- keep as string, cast later
    Loaded_At         DATETIME DEFAULT GETDATE()  -- audit column
);

-- One table per CSV, column names match CSV headers exactly
-- Use NVARCHAR for everything — don't enforce types yet
CREATE TABLE staging.stg_07_CocoaLand_Warehouse_Inventory_RawMaterials_Cleaned_v1 (
    Material_ID    NVARCHAR(20),
    Warehouse_ID       NVARCHAR(20),
    Current_Stock_RM  NVARCHAR(50),
    Last_Updated        NVARCHAR(20),
    RM_Reorder_Level         NVARCHAR(20),   -- keep as string, cast later
    Stock_Status      NVARCHAR(20),
    Loaded_At         DATETIME DEFAULT GETDATE()  -- audit column
);

-- One table per CSV, column names match CSV headers exactly
-- Use NVARCHAR for everything — don't enforce types yet
CREATE TABLE staging.stg_06_CocoaLand_Stock_Movements_Cleaned_v1 (
    Movement_ID    NVARCHAR(20),
    Material_ID       NVARCHAR(20),
    Quantity_RM    NVARCHAR(50),
    Product_ID        NVARCHAR(20),
    Quantity_Prod     NVARCHAR(20),   -- keep as string, cast later
    Warehouse_ID      NVARCHAR(20),
    Movement_Type     NVARCHAR(20),
    Movement_Date     NVARCHAR(20),
    Reference         NVARCHAR(50),
    Loaded_At         DATETIME DEFAULT GETDATE()  -- audit column
);

SELECT COUNT(*) FROM staging.stg_06_CocoaLand_Stock_Movements_Cleaned_v1


-- One table per CSV, column names match CSV headers exactly
-- Use NVARCHAR for everything — don't enforce types yet
CREATE TABLE staging.stg_05_CocoaLand_Purchase_Orders_Cleaned_v1 (
    PO_Line_ID    NVARCHAR(20),
    PO_ID       NVARCHAR(20),
    Supplier_ID    NVARCHAR(50),
    Order_Date        NVARCHAR(20),
    Expected_Delivery_Date     NVARCHAR(20),   -- keep as string, cast later
    PO_Status       NVARCHAR(20),
    Material_ID     NVARCHAR(20),
    Quantity        NVARCHAR(20),
    Unit_Cost_USD         NVARCHAR(50),
    Line_Total_USD         NVARCHAR(50),
    Total_PO_USD         NVARCHAR(50),[Line_Total_USD][Line_Total_USD]
    Loaded_At         DATETIME DEFAULT GETDATE()  -- audit column
);

-- One table per CSV, column names match CSV headers exactly
-- Use NVARCHAR for everything — don't enforce types yet
CREATE TABLE staging.stg_04_CocoaLand_Suppliers_Cleaned_v1 (
    Supplier_ID    NVARCHAR(20),
    Category       NVARCHAR(20),
    Country    NVARCHAR(50),
    Avg_Lead_Time_Days        NVARCHAR(20),
    On_Time_Rate     NVARCHAR(20),   -- keep as string, cast later
    Defect_Rate_pct       NVARCHAR(20),
    Quality_Score_Out_of_5     NVARCHAR(20),
    Last_Audit_Date        NVARCHAR(20),
    Certification_Status         NVARCHAR(50),
    Loaded_At         DATETIME DEFAULT GETDATE()  -- audit column
);

-- One table per CSV, column names match CSV headers exactly
-- Use NVARCHAR for everything — don't enforce types yet
CREATE TABLE staging.stg_03_CocoaLand_Raw_Materials_Master_Cleaned_v1 (
    Material_ID    NVARCHAR(20),
    Material_Name       NVARCHAR(20),
    Category    NVARCHAR(50),
    Unit_Cost_USD        NVARCHAR(20),
    Unit_of_Measure     NVARCHAR(20),   -- keep as string, cast later
    Loaded_At         DATETIME DEFAULT GETDATE()  -- audit column
);

-- One table per CSV, column names match CSV headers exactly
-- Use NVARCHAR for everything — don't enforce types yet
CREATE TABLE staging.stg_02_CocoaLand_Warehouse_Master_Cleaned_v1 (
    Warehouse_ID    NVARCHAR(20),
    Warehouse_Name       NVARCHAR(20),
    Country    NVARCHAR(50),
    Region        NVARCHAR(20),
    Capacity_MT    NVARCHAR(20),   -- keep as string, cast later
    Is_Active      NVARCHAR(20),
    Loaded_At         DATETIME DEFAULT GETDATE()  -- audit column
);

-- One table per CSV, column names match CSV headers exactly
-- Use NVARCHAR for everything — don't enforce types yet
CREATE TABLE staging.stg_01_CocoaLand_Products_Master_Cleaned_v1 (
    Product_ID    NVARCHAR(20),
    Product_Name       NVARCHAR(20),
    Cocoa_Content_pct    NVARCHAR(50),
    Unit_Price_USD        NVARCHAR(20),
    Weight_g            NVARCHAR(20),   -- keep as string, cast later
    Primary_Materials      NVARCHAR(50),
    Launch_Date     NVARCHAR(20),
    Is_Active     NVARCHAR(20),
    Loaded_At         DATETIME DEFAULT GETDATE()  -- audit column
);


