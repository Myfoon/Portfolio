#1.Submit films shorter than 90. Use the film table

select title
from film
where length < 90;

#2.Provide the titles of the films, the rental rate, the duration when the rental price is 3.99 or the duration is 130. Use the table film.

select title, rental_rate, length
from film
where rental_rate = 3.99 or length = 130;

#3.Find the average amount for each vendor (staff_id). Use the payment table.
 
select staff_id, avg(amount)
from payment
group by staff_id;

#4.Calculate the total amount spent on the lease by the customer with ID 15. Report the amount spent on the lease in the new column. Use the payment table

select customer_id, sum(amount) 
from payment
where customer_id = 15;

#5.Find customers (customer_id) who have rented three or more times. Use the rental table.

select customer_id, count(customer_id)
from rental
group by customer_id
having count(customer_id) >= 3;


#6.Provide customers (customer_id) who have spent a total of 100 or more on rent. Provide the amount spent on rent in the "Is_viso" column, sort the results in descending order by customer_id.
#Use the payment table.

select customer_id, sum(amount) as Is_viso
from payment
group by customer_id
having sum(amount) >= 100
order by customer_id desc;

#7.Provide a customer list (customer_id) with the highest payment for each customer, but only those customers with the highest payment 
# equal to 10.99 and 11.99. Use the payment table.

select customer_id,  Highest_payment
from(
	select customer_id, max(amount) as Highest_payment
	from payment
	group by customer_id
    ) as A
where Highest_payment in (10.99, 11.99);

#8.Write an SQL query that provides client names as follows: If the name starts with the letter "M", then in the result give the name in lower case,
# Otherwise - in large ones. Provide the result in the "Name" column. Use the customer table.

SELECT
CASE
	WHEN first_name LIKE "M%" THEN LOWER(first_name)
	ELSE UPPER(first_name)
END AS "Name"
FROM customer;

#9.Write an SQL query that would divide the clients by their first letter into the following
#categories:
#If the first letter of the surname is A or B, then category "A-B"
#If the first letter of the surname is C or D, then the category "C-D"
#Assign all other names to the "Not applicable" category.
#Display surnames in the "Last Name" column and categories in the "First_LastNames_letter" column.
#Use the customer table. 

SELECT Last_name,
CASE
	WHEN Last_name LIKE "A%" OR Last_name LIKE "B%" THEN "A-B"
    WHEN Last_name LIKE "C%" OR Last_name LIKE "D%" THEN "C-D"
	ELSE "Not applicable"
END AS First_LastNames_letter
FROM customer;

# 10.In what city does client Michelle Clark live? 
# Perform using subqueries. If the task is done correctly without subqueries, the task is evaluated with 2 points. Use tables: city, address, customer.

select city
from city 
where city_id = (
				select city_id 
				from address
				where address_id = (
									select address_id
									from customer 
									where first_name ='Michelle' and last_name ='Clark'
									)
				);         
