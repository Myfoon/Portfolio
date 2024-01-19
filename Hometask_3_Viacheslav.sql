#Task 1. When was the last time inventory id = 367 was rented? (rental table)

select rental_date
from rental
where inventory_id = 367
order by rental_date desc
Limit 1;

#Task 2.
#This piece of code actually provides me answers for "How many movies are restricted?" and "How many need parental guidance?"

SELECT  count(*) AS Total_amount_of_films_in_category,
CASE
	WHEN rating = "PG" or rating = "PG-13" THEN "Parental Guidance"
    WHEN rating = "G" THEN "Kids"
    WHEN rating = "NC-17" THEN "Adults Only"
	WHEN rating = "R" THEN "Restricted"
END AS rating_description
FROM film
GROUP BY rating_description;

#Решение Шона
SELECT
COUNT(CASE WHEN sub.rating_description = 'Restricted' THEN 1 END) AS Restricted_Movies,
COUNT(CASE WHEN sub.rating_description = 'Parental Guidance' THEN 1 END) AS Parental_Guidance_Movies,
MAX(CASE WHEN sub.rating_description = 'Parental Guidance' THEN sub.length ELSE NULL END) AS Longest_PG_Movie_Length
FROM
(SELECT *,
(CASE
WHEN rating = 'PG' THEN 'Parental Guidance'
WHEN rating = 'G' THEN 'Kids'
WHEN rating = 'NC-17' THEN 'Adults Only'
WHEN rating = 'PG-13' THEN 'Parental Guidance'
WHEN rating = 'R' THEN 'Restricted'
END) AS rating_description
FROM film) AS sub;



#Task 3. For Store ID = 2, find the address ID with maximum number of customers


#Task 4. From the Payment table, categorize the customers into three categories: High paying, low paying, medium paying customers. 
#High paying customers are the ones who paid more than 100 dollars, medium paying are between 50 to 100 and low paying are below 50 dollars. 
#Find the total amount paid by each category. 

select Paying_category, sum(Total_payment) as Total_amount
from
	(
    select customer_id, sum(amount) as Total_payment,
	CASE
		WHEN sum(amount) > 100 THEN "High paying"
		WHEN sum(amount) between 50 and 100 THEN "Medium paying"
		WHEN sum(amount) < 50 THEN "Low paying"
	END AS Paying_category
	FROM payment
	group by customer_id
    ) as A
group by Paying_category;

#Task 5. In what city is there a store with ID 2? (city, address, store).

select city
from city 
where city_id = (
				select city_id 
				from address
				where address_id = (
									select address_id
									from store 
									where store_id = 2
									)
				);
