CREATE SCHEMA `zomato_database`;
use zomato_database;
CREATE TABLE golduser_signup(
user_id int,
golduser_signup_date date
);
INSERT INTO golduser_signup 
VALUES(1, "2017-09-22"),
(3, "2017-04-21");

CREATE TABLE users(
user_id integer,
signup_date date
);

INSERT INTO users
VALUES(1, "2014-09-02"),
(2, "2015-01-15"),
(3, "2014-04-11");

CREATE TABLE product(
product_id integer,
product_name varchar(20),
price integer
);

INSERT INTO product
VALUES(1, 'p1', 980),
(2, 'p2', 870),
(3, 'p3', 330);

CREATE TABLE sales(
user_id integer,
created_date date,
product_id integer
);

INSERT INTO sales
VALUES(1, "2017-04-19", 2),
(3, "2019-12-18", 1),
(2, "2020-07-20", 3),
(1, "2019-10-23", 2),
(1, "2018-03-19", 3),
(3, "2016-12-20", 2),
(1, "2016-11-09", 1),
(1, "2016-05-20", 3),
(2, "2017-09-24", 1),
(1, "2017-03-11", 2),
(1, "2016-03-11", 1),
(3, "2016-11-10", 1),
(3, "2017-12-07", 2),
(2, "2017-11-08", 2),
(2, "2018-09-10", 3);

Q1. What is the total amount spent by each customer on zomato?;

SELECT a.user_id, a.product_id, b.price FROM sales a INNER JOIN product b ON a.product_id = b.product_id;
SELECT a.user_id, SUM(b.price) FROM sales a INNER JOIN product b ON a.product_id = b.product_id GROUP BY a.user_id;

Q2. How many times each customer visited zomato website?;

SELECT a.user_id, count(distinct a.created_date) FROM sales a GROUP BY a.user_id; 

Q3. what was the first product purchased by each customer?; 

SELECT *, RANK() over(partition by user_id order by created_date) rnk FROM sales;
SELECT * FROM (SELECT *, RANK() over(partition by user_id order by created_date) rnk FROM sales) a where rnk = 1;

Q4. what is the most purchased item on the menu and how many times was it purchased by all customers?;

SELECT product_id, count(product_id) cnt FROM sales group by product_id order by cnt desc limit 1;
SELECT user_id, count(product_id) cnt FROM sales where product_id = (SELECT product_id FROM sales group by product_id order by count(product_id) desc limit 1)
group by user_id order by user_id;

Q5. which item was the most popular for each customer?;

SELECT user_id, product_id, count(product_id) cnt FROM sales group by user_id, product_id;

SELECT *, rank() over(partition by user_id order by cnt desc) rnk FROM 
(SELECT user_id, product_id, count(product_id) cnt FROM sales group by user_id, product_id)a;

select * from (SELECT *, rank() over(partition by user_id order by cnt desc) rnk FROM 
(SELECT user_id, product_id, count(product_id) cnt FROM sales group by user_id, product_id)a)b
where rnk = 1;

Q6. which item was purchased first by the customer after they became a member?;

SELECT a.user_id, a.created_date, a.product_id, b.golduser_signup_date FROM sales a INNER JOIN golduser_signup b ON a.user_id = b.user_id
WHERE a.created_date >= b.golduser_signup_date;

SELECT *, rank() over(partition by user_id order by created_date) rnk FROM (
SELECT a.user_id, a.created_date, a.product_id, b.golduser_signup_date FROM sales a INNER JOIN golduser_signup b ON a.user_id = b.user_id
WHERE a.created_date >= b.golduser_signup_date) c;

SELECT * FROM (
SELECT *, rank() over(partition by user_id order by created_date) rnk FROM (
SELECT a.user_id, a.created_date, a.product_id, b.golduser_signup_date FROM sales a INNER JOIN golduser_signup b ON a.user_id = b.user_id
WHERE a.created_date >= b.golduser_signup_date) c) d WHERE rnk = 1;

Q7. which item was purchased just before the customer became a member?;

SELECT * FROM 
(SELECT *, rank() over(partition by user_id order by created_date desc) rnk FROM (
SELECT a.user_id, a.created_date, a.product_id, b.golduser_signup_date FROM sales a INNER JOIN golduser_signup b ON a.user_id = b.user_id
WHERE a.created_date < b.golduser_signup_date) c) d where rnk = 1;

SELECT a.user_id, a.created_date, a.product_id, b.golduser_signup_date, c.price FROM sales a INNER JOIN golduser_signup b INNER JOIN product c 
ON a.user_id = b.user_id AND a.product_id = c.product_id WHERE a.created_date < b.golduser_signup_date;

Q8. what is the total orders and amount spent for each member before they became a member?;

SELECT d.user_id, count(created_date) totalorder_beforesignup, sum(price) totalamount_beforesignup FROM 
(SELECT a.user_id, a.created_date, a.product_id, b.golduser_signup_date, c.price FROM sales a INNER JOIN golduser_signup b INNER JOIN product c 
ON a.user_id = b.user_id AND  a.product_id = c.product_id WHERE a.created_date < b.golduser_signup_date) d group by user_id ;

Q9. if buying each product generates points for eg: 5rs = 2 zomato point and each product has different purchasing points for p1 5rs = 1 zomato
   points for p2 10rs = 5 zomato point and for p3 5rs = 1 zomato point, calculate points collected by each customers and which product 
   most points have been given till now?;

SELECT a.user_id, a.product_id, b.product_name, b.price FROM sales a INNER JOIN product b ON a.product_id = b.product_id;

SELECT *, CASE when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end as points FROM 
(SELECT a.user_id, a.product_id, b.product_name, b.price FROM sales a INNER JOIN product b ON a.product_id = b.product_id) c; 

SELECT *, round(price/points) as zomato_points FROM 
(SELECT *, CASE when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end as points FROM 
(SELECT a.user_id, a.product_id, b.product_name, b.price FROM sales a INNER JOIN product b ON a.product_id = b.product_id) c) d;

SELECT user_id, sum(zomato_points) as total_points FROM 
(SELECT *, round(price/points) as zomato_points FROM 
(SELECT *, CASE when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end as points FROM 
(SELECT a.user_id, a.product_id, b.product_name, b.price FROM sales a INNER JOIN product b ON a.product_id = b.product_id) c) d) e 
group by user_id order by user_id;

SELECT * FROM 
(SELECT *, RANK() OVER(order by product_id) rnk FROM 
(SELECT product_id, sum(total_points) total_zomato_points FROM 
(SELECT *, round(price/points) as total_points FROM 
(SELECT *, CASE when product_id = 1 then 5 when product_id = 2 then 2 when product_id = 3 then 5 else 0 end as points FROM 
(SELECT a.user_id, a.product_id, b.product_name, b.price FROM sales a INNER JOIN product b ON a.product_id = b.product_id) c) d) e 
group by product_id) f)g where rnk = 1;

Q10. In the first one year after a customer joins the gold program (including their joining date) irrespective of what the customer has purchased
 they earn 5 zomato points for every 10rs spent , who earned more either 1 or 3 and what was their points earned in their first year?;

SELECT a.user_id, a.created_date, a.product_id, b.golduser_signup_date FROM sales a INNER JOIN golduser_signup b ON a.user_id = b.user_id
where a.created_date >= b.golduser_signup_date and created_date <= DATE_ADD(golduser_signup_date, INTERVAL 1 YEAR);

SELECT c.*, d.price FROM 
(SELECT a.user_id, a.created_date, a.product_id, b.golduser_signup_date FROM sales a INNER JOIN golduser_signup b ON a.user_id = b.user_id
where a.created_date >= b.golduser_signup_date and created_date <= DATE_ADD(golduser_signup_date, INTERVAL 1 YEAR)) C INNER JOIN product d 
ON c.product_id = d.product_id;

Select e.*, round(price/2) as points from 
(SELECT c.*, d.price FROM 
(SELECT a.user_id, a.created_date, a.product_id, b.golduser_signup_date FROM sales a INNER JOIN golduser_signup b ON a.user_id = b.user_id
where a.created_date >= b.golduser_signup_date and created_date <= DATE_ADD(golduser_signup_date, INTERVAL 1 YEAR)) C INNER JOIN product d 
ON c.product_id = d.product_id) e;

select f.*, rank() over(order by user_id) rnk from 
(Select e.*, round(price/2) as points from 
(SELECT c.*, d.price FROM 
(SELECT a.user_id, a.created_date, a.product_id, b.golduser_signup_date FROM sales a INNER JOIN golduser_signup b ON a.user_id = b.user_id
where a.created_date >= b.golduser_signup_date and created_date <= DATE_ADD(golduser_signup_date, INTERVAL 1 YEAR)) C INNER JOIN product d 
ON c.product_id = d.product_id) e) f;

select * from 
(select f.*, rank() over(order by user_id) rnk from 
(Select e.*, round(price/2) as points from 
(SELECT c.*, d.price FROM 
(SELECT a.user_id, a.created_date, a.product_id, b.golduser_signup_date FROM sales a INNER JOIN golduser_signup b ON a.user_id = b.user_id
where a.created_date >= b.golduser_signup_date and created_date <= DATE_ADD(golduser_signup_date, INTERVAL 1 YEAR)) C INNER JOIN product d 
ON c.product_id = d.product_id) e) f) g where rnk = 1;

Q11. rank all the transaction of the customer?;
select *, rank() over(partition by user_id order by created_date) rnk from sales;

Q12. Rank all the transaction for each member whenever they are a zomato gold member for every non- gold member transaction marked as NA.;

select a.user_id, a.product_id, a.created_date, b.golduser_signup_date from sales a left join golduser_signup b on a.user_id = b.user_id
and created_date >= golduser_signup_date;

select *, case when golduser_signup_date then rank() over(partition by user_id order by created_date desc) else 'NA' end rnk from 
(select a.user_id, a.product_id, a.created_date, b.golduser_signup_date from sales a left join golduser_signup b on a.user_id = b.user_id
and created_date >= golduser_signup_date) c;
















