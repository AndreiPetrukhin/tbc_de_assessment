
INSERT INTO dds.dm_countries (country) VALUES
('United States'),
('Canada'),
('United Kingdom'),
('Australia'),
('Germany');

INSERT INTO dds.dm_cities (city) VALUES
('New York'),
('Toronto'),
('London'),
('Sydney'),
('Berlin');

INSERT INTO dds.dm_streets (street) VALUES
('Fifth Avenue'),
('Queen Street'),
('Baker Street'),
('George Street'),
('Unter den Linden');

INSERT INTO dds.dm_buildings (building) VALUES
('Building 1'),
('Building 2'),
('Building 3'),
('Building 4'),
('Building 5');

INSERT INTO dds.dm_customers (customer_name, email_address) VALUES
('John Doe', 'john.doe@example.com'),
('Jane Smith', 'jane.smith@example.com'),
('Alice Johnson', 'alice.johnson@example.com'),
('Chris Lee', 'chris.lee@example.com'),
('Patricia Brown', 'patricia.brown@example.com');

INSERT INTO dds.dm_products (product_name, model) VALUES
('Laptop', 'LX-123'),
('Smartphone', 'GX-987'),
('Tablet', 'T-456'),
('Monitor', 'M-789'),
('Headphones', 'H-321');

INSERT INTO dds.dm_product_categories (category_name, description) VALUES
('Electronics', 'Devices that involve electrical circuits'),
('Home Appliances', 'Electrical machines which help in household functions'),
('Books', 'Collection of printed, written, illustrated sheets'),
('Clothing', 'Items worn to cover the body'),
('Outdoor', 'Items used outside homes, for leisure or work');

INSERT INTO dds.dm_product_category_links (product_id, product_category_id, price, active_from, active_to) VALUES
(1, 1, 999.99, '2024-01-01 00:00:00', NULL),
(2, 1, 499.99, '2024-01-01 00:00:00', NULL),
(3, 3, 15.99, '2024-01-01 00:00:00', NULL),
(4, 4, 39.99, '2024-01-01 00:00:00', NULL),
(5, 5, 299.99, '2024-01-01 00:00:00', NULL);

INSERT INTO dds.fct_sales_transactions (customer_id, product_id, purchase_datetime, quantity_purchased) VALUES
(1, 1, '2024-01-01 12:00:00', 2),
(2, 2, '2024-01-02 12:00:00', 1),
(3, 3, '2024-01-03 12:00:00', 5),
(4, 4, '2024-01-04 12:00:00', 1),
(5, 5, '2024-01-05 12:00:00', 3);

INSERT INTO dds.fct_shipping_details (transaction_id, shipping_datetime, country_id, city_id, street_id, building_id) VALUES
(1, '2024-01-02 08:00:00', 1, 1, 1, 1),
(2, '2024-01-03 08:00:00', 2, 2, 2, 2),
(3, '2024-01-04 08:00:00', 3, 3, 3, 3),
(4, '2024-01-05 08:00:00', 4, 4, 4, 4),
(5, '2024-01-06 08:00:00', 5, 5, 5, 5);

-- Check data distribution
WITH distribution AS (
    SELECT 
        COUNT(*) as count
    FROM 
        dds.dm_countries
    GROUP BY 
        id
)
-- Select from the CTE 'distribution'
SELECT
    AVG(count) AS mean_count,  -- Calculate the average count, which shows the average number of entries per 'id'
    STDDEV(count) AS stddev_count  -- Calculate the standard deviation of the counts to measure the dispersion around the mean
FROM 
    distribution;  -- Use the aggregated data from the 'distribution' CTE
