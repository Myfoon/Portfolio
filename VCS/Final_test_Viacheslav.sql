#1. Provide the payment amount from payment table where the payment amount is greater than 2

SELECT amount AS Payment_amount
FROM payment
WHERE amount > 2;

#2.  Provide film titles and the replacement_cost where the rating is PG and the replacement cost is less than 10

SELECT title, replacement_cost
FROM film
WHERE rating ='PG' AND replacement_cost < 10;

#3. Calculate the average rental price (rental_rate) for the movies in each rating, provide the answer with only 1 decimal place. Use table film. 

SELECT TRUNCATE(AVG(rental_rate), 1) AS Average_rental_price , rating
FROM film
GROUP BY rating;

#4. Print the names of all the customers (first_name) and count the length of each name (how many letters there are in the name) next to the names column. Use the customer table.
 
SELECT first_name, LENGTH(first_name) AS Length_of_name
FROM customer;

#5. Locate the position of the first "e" in the description of each movie. Use table film.
 
SELECT DESCRIPTION, LOCATE('e', DESCRIPTION) AS First_e_position
FROM film;

#6. Add up the total length of the films for each rating. Print only ratings with a total movie length longer than 22000. Use the film table.

SELECT SUM(length) AS Total_length, rating
FROM film
GROUP BY rating
HAVING Total_length > 22000;

#7. Print the descriptions of all the movies, a second column with the length of the description, and then a third column where its the description again but replacing all the letters "a" with "OO".
 
SELECT DESCRIPTION, LENGTH(DESCRIPTION), REPLACE(DESCRIPTION, 'a','OO')
FROM film;

#8. Write an SQL query that would classify movies according to their ratings into the following categories: 

#MY COMMENT: I add "Number_of_movies" column here to prove that my classification works

SELECT  count(*) as Number_of_movies,
CASE
	WHEN rating = "PG" or rating = "G" THEN "PG_G"
    WHEN rating = "NC-17" or rating = "PG-13" THEN "NC-17-PG-13"
	ELSE "Not important"
END AS Rating_Group
FROM film
GROUP BY Rating_Group;

#9. Add up the rental duration (rental_duration) for each movie category (use the category name, not just the category id). 
# Print only those categories with a rental_duration greater than 300. Use the tables film, film_category, category. 

SELECT c.name, sum(rental_duration) as Total_rent_duration
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name
HAVING sum(rental_duration) > 300;

#MY COMMENT: There is an option where i try to use WHERE instead of HAVING, but i don't understand why it doesn't work: 

SELECT c.name, sum(rental_duration) as Total_rent_duration
FROM film f
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
WHERE sum(rental_duration) > 300
GROUP BY c.name;
 

#10. Provide the names (first_name) and surnames (last_name) of the customers who rented the movie "AGENT TRUMAN". Use tables for customer, rental, inventory, film.

SELECT c.first_name as Name, c.last_name as Surname
FROM film f
JOIN inventory i ON f.film_id = i.film_id
JOIN rental r ON i.inventory_id = r.inventory_id
JOIN customer c ON r.customer_id = c.customer_id
WHERE f.title = "AGENT TRUMAN";

#11. Use `JOIN` to display the first and last names, as well as the address, of each staff member. Use the tables `staff` and ‘address'

SELECT s.first_name, s.last_name, address
FROM staff s
JOIN address a ON s.address_id = a.address_id;

#12. Use `JOIN` to display the total amount rung up by each staff member in August of 2005. Use tables `staff` and `payment`.
 
SELECT s.first_name, s.last_name, SUM(p.amount) AS "Total amount"
FROM staff s
JOIN payment p ON s.staff_id = p.staff_id
WHERE p.payment_date BETWEEN "2005-08-01" AND "2005-08-31"  
GROUP BY s.staff_id;

#Или вот так (предпочтительнее для работы с датой)
#WHERE p.payment_date >= "2005-08-01" and payment_date < "2005-09-01"

#13. List each film and the number of actors who are listed for that film. Use tables `film_actor` and `film`. Use inner join.

# MY COMMENT: INNER JOIN and JOIN are functionally equivalent

SELECT f.title, COUNT(actor_id) AS Number_of_actors
FROM film f
JOIN film_actor fa ON f.film_id = fa.film_id
GROUP BY f.title;

# На самом деле, у нас есть фильмы, в которых нет актеров
SELECT f.title, COUNT(actor_id) AS Number_of_actors
FROM film f
LEFT JOIN film_actor fa ON f.film_id = fa.film_id
GROUP BY f.title;

#14. How many copies of the film `Hunchback Impossible` exist in the inventory system?

SELECT f.title AS "Film", count(i.inventory_id) AS "Inventory count"
FROM film f
JOIN inventory i ON f.film_id = i.film_id
WHERE f.title = "Hunchback Impossible" 
GROUP BY f.film_id;

#15. Using the tables ‘payment’ and ‘customer’ and the JOIN command, list the total paid by each customer. List the customers alphabetically by last name.

SELECT c.first_name, c.last_name, SUM(amount) AS "Total_paid"
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id
ORDER BY c.last_name ASC;

#16. You want to run an email marketing campaign in Canada, for which you will need the names and email addresses of all Canadian customers. Use joins to retrieve this information.

SELECT CONCAT(c.first_name, ' ', c.last_name) AS "Name", c.email AS "E-mail"
FROM customer c
JOIN address a ON c.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
JOIN country co ON co.country_id = ci.country_id
WHERE co.country = "Canada";

#17. Write a query to display how much business, in dollars, each store brought in (store table).

SELECT sr.store_id, SUM(amount) AS Total_amount
FROM store sr
JOIN staff sf ON sr.store_id = sf.store_id
JOIN payment p ON sf.staff_id = p.staff_id
GROUP BY sr.store_id;

 
