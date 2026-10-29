------------1------------------------
 
 

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
        PRINT '>> TUNCATING TABLE: silver.crm_cust_info'
            TRUNCATE TABLE silver.crm_cust_info
        PRINT '>> INSERTING DATA INTO : silver.crm_cust_info'
         INSERT INTO silver.crm_cust_info(
         cst_id,
         cst_key,
         cst_firstname, 
         cst_lastname, 
         cst_marital_status,
         cst_gndr,
         cst_create_date)
 
                SELECT 
	        cst_id
              ,cst_key
              ,TRIM(cst_firstname) AS cst_firstname
              ,TRIM(cst_lastname ) AS cst_lastname
              ,CASE WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'MARRIED'
                   WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'SINGLE'
                   ELSE 'N/A'
               END AS cst_marital_status     
              , CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'FEMALE'
                    WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'MALE'
                ELSE 'N/A'
                END cst_gndr
              ,cst_create_date
        FROM (
		        SELECT * ,
			        ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
			        FROM bronze.crm_cust_info     
		        )t
        WHERE flag_last = 1  


         -------------------------------2----------------------------------

         PRINT '>> TRUNCATE THE TABLE : silver.crm_prd_info'
         TRUNCATE TABLE silver.crm_prd_info
         PRINT '>> INSERTING DATA INTO : silver.crm_prd_info'
        INSERT INTO silver.crm_prd_info (
                      prd_id ,
                      cat_id 
                      ,prd_key 
                      ,prd_nm
                      ,prd_cost 
                      ,prd_line 
                      ,prd_start_dt 
                      ,prd_end_dt 
                       )

        SELECT prd_id
              ,REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id
              ,SUBSTRING(prd_key, 7 , LEN(prd_key)) AS prd_key
              ,prd_nm
              ,ISNULL(prd_cost,0) AS prd_cost
         ,    CASE upper(trim(prd_line)) 
              WHEN    'S' THEN 'Senior'
              WHEN  'M' THEN 'Mountain'
              WHEN   'T' THEN 'Touring'
              WHEN   'R' THEN 'Restore'
              ELSE 'N/A'
              End as prd_line
              ,prd_start_dt
              , DATEADD(DAY, -1,
                LEAD(prd_start_dt) OVER(
                PARTITION BY prd_key
                ORDER BY prd_start_dt
            )
        ) AS prd_end_dt  FROM  bronze.crm_prd_info
 
 
  
         -------------------------------------3-------------------------------
          PRINT '>>TRUNCATE THE TABLE: silver.crm_sales_details'
          TRUNCATE TABLE silver.crm_sales_details
          PRINT'INSERTING THE DATA INTO: silver.crm_sales_details'
        INSERT INTO silver.crm_sales_details(
                    sls_ord_num
                  ,sls_prd_key
                  ,sls_cust_id
                  ,sls_order_dt
                  ,sls_ship_dt
                  ,sls_due_dt
                 , sls_sales
                  ,sls_quantity
                  ,sls_price
        )

        SELECT sls_ord_num
              ,sls_prd_key
              ,sls_cust_id
              ,CASE WHEN sls_order_dt = 0 OR len(sls_order_dt) != 8 THEN NULL
		        ELSE CAST(CAST(sls_order_dt AS VARCHAR)AS DATE) 
	           END AS sls_order_dt,

               CASE WHEN sls_ship_dt = 0 OR len(sls_ship_dt) != 8 THEN NULL
		        ELSE CAST(CAST(sls_ship_dt AS VARCHAR)AS DATE) 
	           END AS sls_ship_dt,

                CASE WHEN sls_due_dt = 0 OR len(sls_due_dt) != 8 THEN NULL
		        ELSE CAST(CAST(sls_due_dt AS VARCHAR)AS DATE) 
	           END AS sls_due_dt


              ,CASE WHEN sls_sales <= 0 OR sls_sales IS NULL OR sls_sales != sls_quantity * ABS(sls_price)
                            THEN sls_quantity * ABS(sls_price)
                            ELSE sls_sales
                END AS sls_sales 
             ,sls_quantity
              , CASE WHEN sls_price IS NULL OR sls_price <= 0
                          THEN sls_sales / NULLIF(sls_quantity, 0)
                          ELSE sls_price
                    END AS sls_price
          FROM bronze.crm_sales_details
 
         ----------------------4-----------------------------------
         PRINT '>>TRUNCATE THE TABLE: silver.erp_cust_az12 '
         TRUNCATE TABLE silver.erp_cust_az12
         PRINT 'INSERTING THE DATA INTO : silver.erp_cust_az12 '
         INSERT INTO silver.erp_cust_az12(
                        CID,
                        BDATE,
                        GEN
                        )
        SELECT  
                CASE WHEN CID LIKE 'NAS%' THEN SUBSTRING(CID, 4, LEN(CID))
                    ELSE CID
                END AS CID 
 
              ,CASE WHEN BDATE > GETDATE() THEN NULL
                    ELSE BDATE
                END AS BDATE
   
              ,CASE WHEN UPPER(TRIM(GEN)) IN ('F', 'FEMALE') THEN 'Female'
                    WHEN UPPER(TRIM(GEN)) IN ('M', 'MALE') THEN 'Male'
                    ELSE 'N/A'
                END AS GEN
          FROM bronze.erp_cust_az12


          -----------------------------5-------------------------
          PRINT '>> TRUNCATE THE TABLE : silver.erp_loc_a101'
          TRUNCATE TABLE silver.erp_loc_a101
          PRINT 'INSERTING THE DATA INTO : silver.erp_loc_a101'
         INSERT INTO silver.erp_loc_a101 (CID, CNTRY)
        SELECT  
                REPLACE(CID, '-', '') AS CID
              , CASE WHEN UPPER(TRIM(CNTRY)) IN ('DE', 'GERMANY') THEN 'Germnay'
                 WHEN UPPER(TRIM(CNTRY)) IN('USA', 'US') THEN 'United States'  
                 WHEN UPPER(TRIM(CNTRY)) = 'AUSTRALIA' THEN 'Australia'
                 WHEN UPPER(TRIM(CNTRY)) = 'CANADA' THEN 'Canada'
                 WHEN UPPER(TRIM(CNTRY)) = 'FRANCE' THEN 'France'
                 ELSE 'N/A'
            END AS CNTRY 
          FROM  bronze.erp_loc_a101

          -------------------------6-----------------------
        PRINT '>> TRUNCATE THE TABLE:silver.erp_px_cat_g1v2'
        TRUNCATE TABLE silver.erp_px_cat_g1v2
        PRINT 'INSERTING THE DATA INTO : silver.erp_px_cat_g1v2'

        INSERT INTO silver.erp_px_cat_g1v2(ID, CAT, SUBCAT, MAINTENANCE)
        SELECT ID
              ,CAT
              ,SUBCAT
              ,MAINTENANCE
          FROM bronze.erp_px_cat_g1v2
    END

 
 
   
 
