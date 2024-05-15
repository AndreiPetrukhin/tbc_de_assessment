-- Create schema if it does not already exist
CREATE SCHEMA IF NOT EXISTS dds;

-- Table to store country information, distributed by the unique identifier to balance load across segments
CREATE TABLE IF NOT EXISTS dds.dm_countries (
    id SERIAL PRIMARY KEY,            -- Automatically generated unique identifier for each country
    country VARCHAR(100) NOT NULL     -- Name of the country
) 
DISTRIBUTED BY (id);

-- Table to store city information
CREATE TABLE IF NOT EXISTS dds.dm_cities (
    id SERIAL PRIMARY KEY,            -- Automatically generated unique identifier for each city
    city VARCHAR(100) NOT NULL        -- Name of the city
)
DISTRIBUTED BY (id);

-- Table to store street information
CREATE TABLE IF NOT EXISTS dds.dm_streets (
    id SERIAL PRIMARY KEY,            -- Automatically generated unique identifier for each street
    street VARCHAR(100) NOT NULL      -- Name of the street
)
DISTRIBUTED BY (id);

-- Table to store building information
CREATE TABLE IF NOT EXISTS dds.dm_buildings (
    id SERIAL PRIMARY KEY,            -- Automatically generated unique identifier for each building
    building VARCHAR(100) NOT NULL    -- Name or identifier of the building
)
DISTRIBUTED BY (id);

-- Table to store customer information, ensuring unique email addresses and distributed by the customer id
CREATE TABLE IF NOT EXISTS dds.dm_customers (
    id SERIAL PRIMARY KEY,            			-- Automatically generated unique identifier for each customer
    customer_name VARCHAR(255) NOT NULL,  		-- Name of the customer
    email_address VARCHAR(255) NOT NULL 		-- Email address of the customer (check email uniqueness at UI stage)
) 
DISTRIBUTED BY (id);

-- Connection table to associate customers with addresses across different geographical levels (one to many)
-- Partitioned by active_from date to optimize queries based on activation time
CREATE table IF NOT EXISTS dds.dm_customer_addresses (
    customer_id INTEGER REFERENCES dds.dm_customers(id),   -- Links to the customer table
    country_id INTEGER REFERENCES dds.dm_countries(id),   -- Links to the country table
    city_id INTEGER REFERENCES dds.dm_cities(id),         -- Links to the city table
    street_id INTEGER REFERENCES dds.dm_streets(id),      -- Links to the street table
    building_id INTEGER REFERENCES dds.dm_buildings(id),  -- Links to the building table
    active_from TIMESTAMP WITHOUT TIME ZONE NOT NULL,     -- Timestamp when the address becomes active
    active_to TIMESTAMP WITHOUT TIME ZONE,                -- Timestamp when the address is no longer active
    PRIMARY KEY (customer_id, country_id, city_id, street_id, building_id, active_from)
) 
DISTRIBUTED BY (customer_id, country_id, city_id, street_id, building_id, active_from)
PARTITION BY RANGE (active_from)  -- Partitions data daily for more manageable segments and better query performance
    (START ('2024-01-01') INCLUSIVE
     END ('2030-01-01') EXCLUSIVE
     EVERY (INTERVAL '1 day'));

-- Table to store product information
CREATE TABLE IF NOT EXISTS dds.dm_products (
    id SERIAL PRIMARY KEY,            		-- Automatically generated unique identifier for each product
    product_name VARCHAR(255) NOT NULL,     -- Name of the product
    model VARCHAR(100) NOT NULL             -- Model identifier of the product
) 
DISTRIBUTED BY (id);

-- Table to store product category information
CREATE TABLE IF NOT EXISTS dds.dm_product_categories (
    id SERIAL PRIMARY KEY,            		-- Automatically generated unique identifier for each product category
    category_name VARCHAR(255) NOT NULL,    -- Name of the product category
    description VARCHAR(255)                -- Description of the product category
) 
DISTRIBUTED BY (id);

-- Table to link products and product categories with pricing and availability information
CREATE TABLE IF NOT EXISTS dds.dm_product_category_links (
    product_id INTEGER NOT NULL REFERENCES dds.dm_products(id), 					-- Foreign key that references the products table
    product_category_id INTEGER NOT NULL REFERENCES dds.dm_product_categories(id), -- Foreign key that references the product categories table
    price NUMERIC(10, 2) NOT NULL CHECK (price > 0),          					-- Price of the product in the given category
    active_from TIMESTAMP WITHOUT TIME ZONE NOT NULL,  							-- Timestamp when the price becomes active
    active_to TIMESTAMP WITHOUT TIME ZONE,  									-- Timestamp when the price is no longer active
    PRIMARY KEY (product_id, active_from)                                       -- Setting primary key as product_id and active_from
)
DISTRIBUTED BY (product_id, active_from)                                         -- Distributes the table based on the product_id and active_from
PARTITION BY RANGE (active_from)  												-- Partitions data daily for more manageable segments and better query performance
    (START ('2024-01-01') INCLUSIVE
     END ('2030-01-01') EXCLUSIVE
     EVERY (INTERVAL '1 day'));
    
     
-- Table to track fatcs of purchases     
CREATE TABLE dds.fct_sales_transactions (
    id SERIAL NOT NULL,
    customer_id INT NOT NULL REFERENCES dds.dm_customers(id), -- References a customer
    product_id INT NOT NULL REFERENCES dds.dm_products(id),   -- References a product
    purchase_datetime TIMESTAMP WITHOUT TIME ZONE NOT NULL,  -- Date and time of purchase
    quantity_purchased INT NOT NULL,                         -- Quantity of product purchased
    CHECK (purchase_datetime <= current_timestamp),          -- Ensures purchase date is not in the future
    CHECK (quantity_purchased > 0)                           -- Ensures at least one item is purchased
)
DISTRIBUTED BY (id)                                         -- Distribute table by id
PARTITION BY RANGE (purchase_datetime)                      -- Partitioning by purchase date
    (START ('2024-01-01') INCLUSIVE                          
     END ('2030-01-01') EXCLUSIVE                           
     EVERY (INTERVAL '1 day'));
    
CREATE UNIQUE INDEX idx_unique_id_datetime ON dds.fct_sales_transactions (id);


-- Table to track shipping details for purchases
CREATE TABLE dds.fct_shipping_details (
    id SERIAL,  -- Automatically generated unique identifier for each shipping detail
    transaction_id INT NOT NULL REFERENCES dds.fct_sales_transactions(id), -- References a transaction
    shipping_datetime TIMESTAMP WITHOUT TIME ZONE NOT NULL,  -- Date and time of shipping
    country_id INTEGER REFERENCES dds.dm_countries(id),   -- Links to the country table
    city_id INTEGER REFERENCES dds.dm_cities(id),         -- Links to the city table
    street_id INTEGER REFERENCES dds.dm_streets(id),      -- Links to the street table
    building_id INTEGER REFERENCES dds.dm_buildings(id)  -- Links to the building table
)
DISTRIBUTED BY (id)  -- Distribute the table by id
PARTITION BY RANGE (shipping_datetime)  -- Partitioning by shipping date for efficient data management
    (START ('2024-01-01') INCLUSIVE  -- Starting point of the first partition
     END ('2030-01-01') EXCLUSIVE    -- End point of the last partition
     EVERY (INTERVAL '1 day'));  -- Daily partitions for detailed segmentation and performance

CREATE UNIQUE INDEX idx_unique_fct_sd_id ON dds.fct_shipping_details (id);