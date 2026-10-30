--THIS IS FIRST QUERY FOR CREATE IN GOLD LAYER DIMENSION OF CUSTOMER
CREATE VIEW gold.dim_customers AS
SELECT     
        ROW_NUMBER() OVER(ORDER BY cst_id ) AS customer_key,
        ci.cst_id AS customer_id
      , ci.cst_key AS customer_number
      , ci.cst_firstname AS first_name
      , ci.cst_lastname AS last_name
      , la.CNTRY AS country
      , ci.cst_marital_status  AS marital_status
      , CASE WHEN ci.cst_gndr != 'N/A' THEN ci.cst_gndr --crm IS THE MASTER TABLE IN OUR TABLES
            ELSE COALESCE( ca.GEN, 'N/A')
        END AS gender 
           , ca.BDATE AS birthdate   
      , ci.cst_create_date AS create_date
     
  FROM  silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key = ca.CID
LEFT JOIN silver.erp_loc_a101 la
ON ca.CID = la.CID

--THIS IS SECOND QUERY FOR CREATE IN GOLD LAYER DIMENSION OF PRODUCT

CREATE VIEW gold.dim_products AS
 SELECT  
        ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt,pn.prd_key  ) AS product_key,
       pn.prd_id AS product_id
      ,pn.prd_key AS product_number
      ,pn.prd_nm AS product_name
      ,pn.cat_id AS category_id
      ,pc.CAT AS category
      ,pc.SUBCAT AS sub_category
      ,pc.MAINTENANCE AS maintenance
      ,pn.prd_cost AS cost
      ,pn.prd_line AS product_line
      ,pn.prd_start_dt start_date
      
  FROM  silver.crm_prd_info pn
  LEFT JOIN silver.erp_px_cat_g1v2 pc
  ON pn.cat_id = pc.ID 
  WHERE prd_end_dt IS NULL


  --THIS QUERY CREATE FACT TABLE
 CREATE OR ALTER VIEW gold.fact_sales AS
SELECT 
        sd.sls_ord_num AS order_number
      ,pd.product_key
      ,cd.customer_key
      ,sd.sls_order_dt AS order_date
      ,sd.sls_ship_dt AS shipping_date
      ,sd.sls_due_dt AS due_date
      ,sd.sls_sales AS sales_amount
      ,sd.sls_quantity AS quantity
      ,sd.sls_price price
  FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pd
ON sd.sls_prd_key = pd.product_number
LEFT JOIN gold.dim_customers cd
ON sd.sls_cust_id = cd.customer_id
  
