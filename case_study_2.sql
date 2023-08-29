/*
A. Pizza Metrics

1. How many pizzas were ordered?
2. How many unique customer orders were made?
3. How many successful orders were delivered by each runner?
4. How many of each type of pizza was delivered?
5. How many Vegetarian and Meatlovers were ordered by each customer?
6. What was the maximum number of pizzas delivered in a single order?
7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
8. How many pizzas were delivered that had both exclusions and extras?
9. What was the total volume of pizzas ordered for each hour of the day?
10. What was the volume of orders for each day of the week?


--1. How many pizzas were ordered?
SELECT COUNT(pizza_id) AS no_of_pizzas
FROM pizza_runner.customer_orders
--2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id)
FROM pizza_runner.customer_orders
--3. How many successful orders were delivered by each runner?
WITH cleaned_orders AS (
 SELECT order_id, runner_id, pickup_time, distance, duration, CASE WHEN cancellation IN ('','null') OR
cancellation IS NULL THEN 0 ELSE 1 END AS cancellation
FROM pizza_runner.runner_orders
)
SELECT COUNT(*) AS delivered_orders
FROM cleaned_orders
WHERE cancellation = 0
--4. How many of each type of pizza was delivered?
WITH cleaned_orders AS (
SELECT order_id, runner_id, pickup_time, distance, duration,
 CASE WHEN cancellation = 'null' THEN 0
 WHEN cancellation IS NULL THEN 0
 WHEN cancellation = '' THEN 0
 ELSE 1 END AS cancellation
 FROM pizza_runner.runner_orders),
orderS AS (
 SELECT c.*,o.cancellation
 FROM pizza_runner.customer_orders c
 LEFT JOIN cleaned_orders o USING(order_id)
 )
 SELECT pizza_id, COUNT(*) AS no_of_pizzas
 FROM orderS
 WHERE cancellation = 0
 GROUP BY 1
OR
-WITH cleaned_orders AS (
 SELECT order_id, runner_id, pickup_time, distance, duration, pizza_id, CASE WHEN cancellation IN
('','null') OR cancellation IS NULL THEN 0 ELSE 1 END AS cancellation
FROM pizza_runner.runner_orders
LEFT JOIN pizza_runner.customer_orders USING(order_id)
)
SELECT pizza_id,COUNT(*) AS delivered_orders
FROM cleaned_orders
WHERE cancellation = 0
GROUP BY 1 )

--5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_id,
coalescE(SUM(CASE WHEN pizza_id = 1 THEN 1 ELSE 0 END),0) AS meatlovers,
COALESCE(SUM(CASE WHEN pizza_id = 2 then 1 ELSE 0 END),0) AS vegetarian
FROM pizza_runner.customer_orders
GROUP BY 1

--6
WITH runner_orders AS (

SELECT order_id, runner_id, pickup_time, distance, duration, CASE WHEN cancellation IN ('null', '') OR
cancellation IS NULL THEN 0
ELSE 1 END AS cancellation
FROM pizza_runner.runner_orders
), unique_orders AS (
SELECT DISTINCT order_id, r.cancellation
FROM runner_orders r
WHERE cancellation = 0
)
SELECT order_id, COUNT(*) as pizzas_delivered
FROM unique_orders
LEFT JOIN pizza_runner.customer_orders
USING (order_id)
GROUP BY order_id
ORDER BY pizzas_delivered DESc

--7
WITH cleaned_orders AS (
 SELECT order_id, customer_id, pizza_id,
 CASE WHEN exclusions IN ('null','') THEN null ELSE exclusions END AS exclusions,
 CASE WHEN extras IN ('null','') THEN null ELSE extras END AS extras,
 order_time
 FROM pizza_runner.customer_orders
),
runner_orders AS (
 SELECT order_id, runner_id, pickup_time, distance, duration,
 CASE WHEN cancellation IN ('null', '') OR cancellation IS NULL THEN 0
 ELSE 1 END AS cancellation
 FROM pizza_runner.runner_orders
),
pizzas AS (
SELECT c.*,r.*, CASE WHEN exclusions IS NULL AND extras IS NULL THEN 0 ELSE 1 END AS change
FROM cleaned_orders c
LEFT JOIN runner_orders r
USING(order_id)
WHERE cancellation = 0
)
SELECT customer_id,
COUNT(CASE WHEN change = 0 THEN 0 END) AS pizza_no_change,
COUNT(CASE WHEN change = 1 THEN 1 END) AS pizza_with_change
FROM pizzas
GROUP BY customer_id

--8
WITH cleaned_orders AS (
 SELECT order_id, customer_id, pizza_id,
 CASE WHEN exclusions IN ('null','') THEN null ELSE exclusions END AS exclusions,
 CASE WHEN extras IN ('null','') THEN null ELSE extras END AS extras,
 order_time
 FROM pizza_runner.customer_orders
),
runner_orders AS (
 SELECT order_id, runner_id, pickup_time, distance, duration,
 CASE WHEN cancellation IN ('null', '') OR cancellation IS NULL THEN 0
 ELSE 1 END AS cancellation
 FROM pizza_runner.runner_orders
),pizzas AS (
SELECT c.*,r.*, CASE WHEN exclusions IS NOT NULL AND extras IS NOT NULL THEN 1 ELSE 0 END AS
both_ex
FROM cleaned_orders c
LEFT JOIN runner_orders r
USING(order_id)
WHERE cancellation = 0
)
SELECT COUNT(*) AS pizza_delivered
FROM pizzas
WHERE both_ex = 1

--9.
SELECT EXTRACT(hour FROM order_time) AS hod, COUNT(*) as pizza_ordered
FROM pizza_runner.customer_orders
GROUP BY hod
ORDER BY pizza_ordered desc

--10.
SELECT TO_CHAR(order_time, 'Day') AS dow,EXTRACT(dow FROM order_time) AS dow2, COUNT(*) as
pizza_ordered
FROM pizza_runner.customer_orders
GROUP BY 1,2
ORDER BY pizza_ordered desc
--TO_CHAR function converts a number or date to a string.
--TO_TIMESTAMP converts char to a value of TIMESTAMP data type.



--B. Runner and Customer Experience
--1.
SELECT CONCAT('Week', to_char(registration_date, 'WW')) AS registration_week, COUNT(runner_id) AS
runners_registered
FROM pizza_runner.runners
GROUP BY 1
ORDER BY 1
--2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to
pickup the order?
WITH runner_orders AS (
 SELECT order_id, runner_id, CASE WHEN pickup_time IN ('null','') THEN NULL ELSE
TO_TIMESTAMP(pickup_time, 'YYYY-MM-DD HH24:MI:SS') END AS pickup_time,distance, duration, CASE
WHEN cancellation IN ('null','') OR cancellation IS NULL THEN 0 ELSE 1 END AS cancellation
 FROM pizza_runner.runner_orders
),
customer_orders AS (
 SELECT DISTINCT order_id, order_time
 FROM pizza_runner.customer_orders
),
time_difference AS (
 SELECT r.*,c.*, EXTRACT(epoch FROM (pickup_time-order_time)) AS time_taken_seconds
 FROM customer_orders c
 LEFT JOIN runner_orders r
 USING(order_id)
)
SELECT runner_id, ROUND(AVG(time_taken_seconds/60.0)) AS avg_minutes
FROM time_difference
GROUP BY 1


--3.Is there any relationship between the number of pizzas and how long the order takes to prepare?
-- There exists a positive relationship b/w no of pizzas ordered and the time taken to prepare
WITH runner_orders AS (
 SELECT order_id, runner_id, CASE WHEN pickup_time IN ('null','') THEN NULL ELSE
TO_TIMESTAMP(pickup_time,'YYYY-MM-DD HH24:MI:SS') END AS pickup_time, distance, duration, CASE
WHEN cancellation IN ('null','') OR cancellation IS NULL THEN 0 ELSE 1 END AS cancellation
 FROM pizza_runner.runner_orders
),
pizza_details AS (
 SELECT order_id, COUNT(*) AS pizza_ordered, MIN(order_time) AS order_time
 FROM pizza_runner.customer_orders
 GROUP BY 1
),
time_difference AS (
 SELECT r.*,p.*, EXTRACT(epoch FROM (pickup_time-order_time)) AS time_taken_seconds
 FROM runner_orders r
 LEFT JOIN pizza_details p
 USING(order_id)
)
SELECT pizza_ordered, AVG(time_taken_seconds) AS avg_seconds
FROM time_difference
GROUP BY 1
ORDER BY 1

--4.
WITH runner_orders AS (
 SELECT order_id, runner_id, CASE WHEN pickup_time IN ('null','') THEN NULL ELSE
TO_TIMESTAMP(pickup_time, 'YYYY-MM-DD HH24:MI:SS') END AS pickup_time,
 CASE WHEN distance IN ('null','') THEN NULL ELSE TRIM(SPLIT_PART(distance,'km',1)) END AS distance,
duration, CASE WHEN cancellation IN ('null','') OR cancellation IS NULL THEN 0 ELSE 1
 END AS cancellation
 FROM pizza_runner.runner_orders
),
customer_orders AS (
 SELECT order_id, customer_id, COUNT(*) AS pizza_ordered, MIN(order_time) AS order_time
 FROM pizza_runner.customer_orders
 GROUP BY 1 ,2
),
time_differences AS (
 SELECT r.*, c.*, EXTRACT(epoch FROM(pickup_time-order_time)) AS time_taken_seconds
 FROM runner_orders r
 LEFT JOIN customer_orders c
 USING(order_id)
)
SELECT customer_id, AVG(distance::FLOAT) AS avg_km
FROM time_differences
GROUP BY 1


--5.What was the difference between the longest and shortest delivery times for all orders?
WITH runner_orders AS (
 SELECT order_id, runner_id,
 CASE WHEN pickup_time IN ('null','') THEN NULL ELSE TO_TIMESTAMP(pickup_time, 'YYYY-MM-DD
HH24:MI:SS') END AS pickup_time,
 CASE WHEN distance IN ('null','') THEN NULL ELSE TRIM(SPLIT_PART(distance,'km',1)) END AS
distance_km,
 CASE WHEN duration IN ('null','') THEN NULL ELSE TRIM(SPLIT_PART(duration,'min',1))::INTEGER END
AS duration_min,
 CASE WHEN cancellation IN ('null','') OR cancellation IS NULL THEN 0 ELSE 1 END AS cancellation
FROM pizza_runner.runner_orders
)
SELECT MAX(duration_min) AS longest_delivery,
 MIN(duration_min) AS shortest_delivery,
 MAX(duration_min) - MIN(duration_min) AS difference
 FROM runner_orders


--6.What was the average speed for each runner for each delivery and do you notice any trend for these
values?
WITH runner_orders AS (
 SELECT order_id, runner_id,
 CASE WHEN pickup_time IN ('null','') THEN NULL ELSE TO_TIMESTAMP(pickup_time, 'YYYY-MM-DD
HH24:MI:SS') END AS pickup_time,
 CASE WHEN distance IN ('null','') THEN NULL ELSE TRIM(SPLIT_PART(distance,'km',1)) END AS
distance_km,
 CASE WHEN duration IN ('null','') THEN NULL ELSE TRIM(SPLIT_PART(duration,'min',1))::INTEGER END
AS duration_min,
 CASE WHEN cancellation IN ('null','') OR cancellation IS NULL THEN 0 ELSE 1 END AS cancellation
FROM pizza_runner.runner_orders
)
SELECT order_id,
runner_id,
distance_km::FLOAT/(duration_min/60.0) AS km_per_hour
FROM runner_orders
WHERE cancellation = 0
ORDER BY runner_id


--7.
--What is the successful delivery percentage for each runner?
WITH runner_orders AS (
 SELECT order_id, runner_id,
 CASE WHEN pickup_time IN ('null','') THEN NULL ELSE TO_TIMESTAMP(pickup_time, 'YYYY-MM-DD
HH24:MI:SS') END AS pickup_time,
 CASE WHEN distance IN ('null','') THEN NULL ELSE TRIM(SPLIT_PART(distance,'km',1)) END AS
distance_km,
 CASE WHEN duration IN ('null','') THEN NULL ELSE TRIM(SPLIT_PART(duration,'min',1))::INTEGER END
AS duration_min,
 CASE WHEN cancellation IN ('null','') OR cancellation IS NULL THEN 0 ELSE 1 END AS cancellation
FROM pizza_runner.runner_orders
)
SELECT runner_id,
COUNT(CASE WHEN cancellation = 0 THEN cancellation END ) AS successful,
COUNT(*) AS orders,
COUNT(CASE WHEN cancellation = 0 then cancellation END)/COUNT(*)::FLOAT AS percent_successful
FROM runner_orders
GROUP BY 1

--Ingredients Optimization
/* UNNEST(STRING_TO_ARRAY(array, ', ')) function--expand the array into rows
 ( ----- ) array
-row
-row
-row*/
--STRING_AGG( ',') --Combines words using a separator parameter that allows separating the expressions
to be concatenated
::INTEGER -- Converts values to integer
EXTRACT(EPOCH FROM time_taken) ---- extracts seconds
SPLIT_PART(distance, 'km' , 1) ---- splits distance and km apart
(SPLIT_PART(duration,'min',1))::INTEGER --- Splits duration then converts to integer

--1. What are the standard ingredients for each pizza?
WITH topping_unnest AS (
 SELECT pizza_id, UNNEST(STRING_TO_ARRAY(toppings, ', '))::INTEGER AS topping_id
 FROM pizza_runner.pizza_recipes
),
toppings AS (
 SELECT t.*, topping_name
 FROM topping_unnest t
 LEFT JOIN pizza_runner.pizza_toppings USING(topping_id)
)
SELECT pizza_id, STRING_AGG(topping_name,', ') AS ingredients
FROM toppings
GROUP BY pizza_id
ORDER BY 1


--2. What was the most commonly added extra?
WITH orders_extras AS (
SELECT order_id, UNNEST(STRING_TO_ARRAY(extras, ', ')) AS extras
FROM pizza_runner.customer_orders
),
cleaned_extra AS (
 SELECT order_id, CASE WHEN extras='null' THEN NULL else extras END as extras
 FROM orders_extras
)
SELECT topping_name, COUNT(*) AS no_of_times
FROM cleaned_extra c
INNER JOIN pizza_runner.pizza_toppings p
ON c.extras::INTEGER = p.topping_id
WHERE extras IS NOT NULL
GROUP BY topping_name
ORDER BY no_of_times DESC
LIMIT 1


--3.What was the most common exclusion?
WITH orders_exclusions AS (
 SELECT order_id, UNNEST(STRING_TO_ARRAY(exclusions, ', ')) AS exclusions
 FROM pizza_runner.customer_orders
),
cleaned_exclusions AS (
 SELECT order_id, CASE WHEN exclusions = 'null' THEN NULL ELSE exclusions END AS exclusions
 FROM orders_exclusions
)
SELECT topping_name, COUNT(*) AS no_of_times
FROM cleaned_exclusions c
INNER JOIN pizza_runner.pizza_toppings t
ON c.exclusions::INTEGER = t.topping_id
WHERE exclusions IS NOT NULL
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1


--4.
/*Generate an order item for each record in the customers_orders table in the format of one of the
following:
Meat Lovers
Meat Lovers - Exclude Beef
Meat Lovers - Extra Bacon
Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers*/
WITH orders AS (
 SELECT *, ROW_NUMBER() OVER() AS row_index
 FROM pizza_runner.customer_orders
),
exclusions_1 AS (
 SELECT order_id, pizza_id, row_index, UNNEST(STRING_TO_ARRAY(exclusions,', ')) AS exclusions
 FROM orders
),
exclusions_2 AS (
 SELECT order_id, pizza_id, row_index, topping_name
 FROM exclusions_1 e
 LEFT JOIN pizza_runner.pizza_toppings p
 ON e.exclusions::INTEGER = p.topping_id
 WHERE exclusions NOT IN ('null', '')
),
extras AS (
 SELECT order_id,pizza_id, row_index, UNNEST(STRING_TO_ARRAY(extras,', ')) AS extras
 FROM orders
),
extras_2 AS (
 SELECT order_id, pizza_id, row_index, topping_name
 FROM extras x
 LEFT JOIN pizza_runner.pizza_toppings p
 ON x.extras::INTEGER = p.topping_id
 WHERE extras NOT IN ('null','')
),
exclusions_toppings AS (
 SELECT row_index, STRING_AGG(topping_name,', ') AS exclusions
 FROM exclusions_2
 GROUP BY 1
),
extras_toppings AS (
 SELECT row_index, STRING_AGG(topping_name,', ') AS extras
 FROM extras_2
 GROUP BY 1
)
SELECT CONCAT(pizza_name,
 CASE WHEN t.exclusions IS NULL THEN '' ELSE ' - Exlude ' END, t.exclusions,
 CASE WHEN e.extras IS NULL THEN '' ELSE ' - Extra ' END, e.extras
 ) AS pizza_ordered
 FROM orders o
 LEFT JOIN exclusions_toppings t USING(row_index)
 LEFT JOIN extras_toppings e USING(row_index)
 LEFT JOIN pizza_runner.pizza_names p USING(pizza_id)
