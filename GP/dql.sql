WITH MonthlySales AS (
    -- Calculate the total sales amount and number of transactions for each month
    SELECT
        DATE_TRUNC('month', f.purchase_datetime) AS sales_month, -- Group data by month
        SUM(d.price * f.quantity_purchased) AS total_sales_amount, -- Calculate total sales by multiplying price by quantity purchased
        COUNT(*) AS total_transactions -- Count the number of transactions per month
    FROM
        dds.fct_sales_transactions f
    JOIN
        dds.dm_product_category_links d
    ON
        f.product_id = d.product_id
    WHERE
        d.active_from <= f.purchase_datetime
        AND (d.active_to IS NULL OR d.active_to > f.purchase_datetime) -- Ensure pricing is applicable for the transaction date
    GROUP BY
        sales_month
),
MovingAverages AS (
    -- Calculate the 3-month moving average of sales amount
    SELECT
        sales_month,
        total_sales_amount,
        total_transactions,
        AVG(total_sales_amount) OVER (ORDER BY sales_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS three_month_moving_avg
        -- Use a window function to compute the moving average over the current and previous two months
    FROM
        MonthlySales
)
-- Select final results, ordered by month for chronological understanding
SELECT
    sales_month,
    total_sales_amount,
    total_transactions,
    three_month_moving_avg
FROM
    MovingAverages
ORDER BY
    sales_month;
