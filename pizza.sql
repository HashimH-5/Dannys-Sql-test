-- 10. In the first week after a customer joins the program (including their join date) they earn
2x points on all items, not just sushi - how many points do customer A and B have at the end of
January?
WITH members AS (

SELECT s.customer_id, s.product_id, order_date, join_date
 FROM dannys_diner.sales s
 INNER JOIN dannys_diner.members m
 ON s.customer_id = m.customer_id
 AND s.order_date >= m.join_date
)
SELECT customer_id,
SUM(CASE
WHEN order_date < join_date+INTERVAL '7 day' THEN price*20
 WHEN product_id = 1 THEN price*20
 ELSE price*10
 END) AS points
FROM members
INNER JOIN dannys_diner.menu USING(product_id)
WHERE order_date<='2021-01-31'
GROUP BY 1


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many
points would each customer have?
WITH first_orders AS (
SELECT s.customer_id, m.product_name,price, CASE WHEN m.product_name= 'sushi' THEN
m.price*20 ELSE m.price*10 END AS points
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m
USING(product_id)
ORDER BY customer_id
 )
SELECT customer_id,product_name,SUM(points) total_points
FROM first_orders
GROUP BY 1,2
or
WITH points AS (
 SELECT customer_id, s.product_id, price,
 CASE WHEN product_id = 1 THEN price*20 ELSE price*10
 END AS points
 FROM dannys_diner.sales s
 INNER JOIN dannys_diner.menu m USING (product_id)
)
SELECT customer_id, SUM(points) AS total_points
FROM points
GROUP BY customer_id
ORDER BY total_points DESC;


-- 8. What is the total items and amount spent for each member before they became a
member?
WITH first_orders AS (
SELECT s.customer_id, m.product_name,SUM(m.price) total_amount,COUNT(*) total_items
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m
USING(product_id)
INNER JOIN dannys_diner.members mb
ON s.customer_id = mb.customer_id
AND s.order_date < mb.join_date
GROUP BY 1,2
ORDER BY customer_id
 )
SELECT customer_id, product_name, total_amount, total_items
FROM first_orders

-- 7. Which item was purchased just before the customer became a member?
WITH first_orders AS (
SELECT s.customer_id, m.product_name,s.order_date,mb.join_date,
ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) order_rank
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m
USING(product_id)
INNER JOIN dannys_diner.members mb
ON s.customer_id = mb.customer_id
AND s.order_date < mb.join_date
ORDER BY customer_id
 )
SELECT customer_id, product_name
FROM first_orders
WHERE order_rank = 1

-- 6. Which item was purchased first by the customer after they became a member?
WITH first_order AS (
SELECT s.customer_id, m.product_name,s.order_date,mb.join_date,
ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) order_rank
FROM dannys_diner.sales s
INNER JOIN dannys_diner.menu m
USING(product_id)
INNER JOIN dannys_diner.members mb
ON s.customer_id = mb.customer_id
AND s.order_date > mb.join_date
ORDER BY customer_id
)
SELECT customer_id, product_name
FROM first_order
WHERE order_rank = 1


-- 5. Which item was the most popular for each customer?
WITH products_purchased AS (
 SELECT customer_id, product_name, COUNT(*) AS no_of_times_purchased
 FROM dannys_diner.sales
 INNER JOIN dannys_diner.menu USING (product_id)
 GROUP BY customer_id, product_name
 ORDER BY customer_id, no_of_times_purchased DESC),
 t2 AS (
 SELECT p.*, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY
no_of_times_purchased DESC) rank_item
 FROM products_purchased p )
 SELECT customer_id, product_name
 FROM t2
 WHERE rank_item = 1


--4. What is the most purchased item on the menu and how many times was it purchased by all
customers?
 SELECT product_name, COUNT(*) most_popular
 FROM dannys_diner.sales s
 INNER JOIN dannys_diner.menu m
 USING(product_id)
 GROUP BY product_name
 ORDER BY most_popular DESC

--3. What was the first item from the menu purchased by each customer?
WITH first_sales AS (
SELECT customer_id, product_name, order_date, ROW_NUMBER() OVER (PARTITION BY
customer_id ORDER BY order_date ) AS sales_rank
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
USING(product_id)
ORDER BY customer_id)
SELECT customer_id, product_name
FROM first_sales
WHERE sales_rank = 1

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date)
FROM dannys_diner.sales
GROUP BY 1

-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price)
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu
USING(product_id)
GROUP BY 1