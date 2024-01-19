#1.Use JOIN to display the first and last names, as well as the address, of each staff member. Use the tables staff and address
SELECT first_name, last_name, s.address_id, address 
FROM staff s
JOIN address a ON s.address_id = a.address_id;

#2. Use JOIN to display the total amount processed by each staff member in August of 2005. Use tables staff and payment.
SELECT CONCAT(s.first_name, ' ', s.last_name) AS "Staff member", sum(p.amount) AS "Total amount"
FROM staff s
JOIN payment p ON s.staff_id = p.staff_id
WHERE payment_date BETWEEN "2005-08-01" AND "2005-08-31"  
GROUP BY s.staff_id;


#3.List each film and the number of actors who are listed for that film. Use tables film_actor and film. Use inner join

SELECT title, count(actor_id) AS "actors"
FROM film f
INNER JOIN film_actor fa ON f.film_id = fa.film_id
GROUP BY f.film_id, title;

#4. How many copies of the film Hunchback Impossible exist in the inventory system?
select *
from inventory;

SELECT f.title as "Film", count(i.inventory_id) as "Inventory count"
FROM film f
JOIN inventory i ON f.film_id = i.film_id
WHERE f.title = "Hunchback Impossible" 
GROUP BY f.film_id;

#5. Using the tables payment and customer and the JOIN command, list the total amount paid by each customer.
# Sort the customers based on the payment in descending order:
SELECT CONCAT(c.first_name, ' ', c.last_name) AS "Customer Name", sum(amount) AS "Total_paid"
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
GROUP BY c.customer_id
ORDER BY Total_paid DESC;

#6. The music of Queen and Kris Kristofferson have seen an unlikely resurgence. As an unintended consequence, 
# films starting with the letters K and Q have also soared in popularity. Use Join to display the titles of movies starting with the letters K and Q whose language is English.
SELECT title 
FROM film f
JOIN language l ON f.language_id = l.language_id
WHERE (f.title LIKE "K%" OR f.title LIKE "Q%") AND l.name = "English";


#7.You want to run an email marketing campaign in Canada, for which you will need the names and email addresses of all Canadian customers. 
# Use joins to retrieve this information.
SELECT CONCAT(c.first_name, ' ', c.last_name) AS "Name", c.email AS "E-mail"
FROM customer c
JOIN address a ON c.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
JOIN country co ON co.country_id = ci.country_id
WHERE co.country = "Canada";

#8 Write a query to display for each store its store ID, city, and country.
SELECT s.store_id AS "Store ID", ci.city AS "City", co.country AS "Country"
from store s
JOIN address a ON s.address_id = a.address_id
JOIN city ci ON a.city_id = ci.city_id
JOIN country co ON ci.country_id = co.country_id

