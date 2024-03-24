--Task 1.Top-3 most selling movie categories of all time and total dvd rental income for each category. Only consider dvd rental customers from the USA.

/*In order to get total dvd rental income for each category, we need the following chain: category--film_category--inventory--rental--payment.
Then, as far as we also need to consider payments received from specific country customers, the chain is: payment--customer--address--city--country*/
SELECT
	cat.name AS category_name,
	SUM(amount) AS total_income
FROM
	category cat
INNER JOIN film_category fc ON
	cat.category_id = fc.category_id
INNER JOIN inventory i ON
	i.film_id = fc.film_id
INNER JOIN rental r ON
	r.inventory_id = i.inventory_id
INNER JOIN payment p ON
	p.rental_id = r.rental_id
INNER JOIN customer cus ON
	cus.customer_id = p.customer_id
INNER JOIN address a ON
	a.address_id = cus.address_id
INNER JOIN city ci ON
	ci.city_id = a.city_id
INNER JOIN country co ON
	co.country_id = ci.country_id
WHERE
	UPPER(co.country) = 'UNITED STATES'
GROUP BY
	cat.category_id
ORDER BY
	SUM(amount) DESC,
	(COUNT(r.rental_id)) DESC   --Here I use additional ordering by number of rents, it may be helpful in case of the same total_income for several film categories 
LIMIT 3;


--The same solution with CTE
WITH income_and_rents_by_category AS (
SELECT
	cat.category_id,
	cat.name,
	SUM(amount) AS income,
	COUNT(r.rental_id) AS number_of_rents,
	r.customer_id
FROM
	category cat
INNER JOIN film_category fc ON
	cat.category_id = fc.category_id
INNER JOIN inventory i ON
	i.film_id = fc.film_id
INNER JOIN rental r ON
	r.inventory_id = i.inventory_id
INNER JOIN payment p ON
	p.rental_id = r.rental_id
GROUP BY
	cat.category_id,
	r.customer_id
)

SELECT
	name AS category_name,
	SUM(income) AS total_income
FROM
	income_and_rents_by_category
INNER JOIN customer cus ON
	cus.customer_id = income_and_rents_by_category.customer_id
INNER JOIN address a ON
	a.address_id = cus.address_id
INNER JOIN city ci ON
	ci.city_id = a.city_id
INNER JOIN country co ON
	co.country_id = ci.country_id
WHERE
	UPPER(co.country) = 'UNITED STATES'
GROUP BY
	category_id,
	name
ORDER BY
	SUM(income) DESC,
	SUM(number_of_rents) DESC
LIMIT 3;
/*To be honest, after implementing the solution with such CTE, I realized that it is does not look any simplier than solution without it. 
I have a feeling that there may be a more elegant solution, but at the moment I don't have better options*/



--Task 2. For each client, display a list of horrors that he had ever rented (in one column, separated by commas), and the amount of money that he paid for it

/*In order to get amount of money each client paid, we need customer--payment link, then we have the chain payment--rental--inventory--film_category--category--film which allows to get  
film titles of specific genre*/
SELECT
	cus.first_name || ' ' || cus.last_name AS full_name,
	SUM(p.amount) AS money,
	STRING_AGG(DISTINCT f.title, ', ') AS list_of_horrors     --As far as one horror film can be rented by certain person several times, I use DISTINCT here  
FROM
	customer cus
INNER JOIN payment p ON
	p.customer_id = cus.customer_id
INNER JOIN rental r ON
	r.rental_id = p.rental_id
INNER JOIN inventory i ON
	i.inventory_id = r.inventory_id
INNER JOIN film_category fc ON
	fc.film_id = i.film_id
INNER JOIN category cat ON
	cat.category_id = fc.category_id
INNER JOIN film f ON
	f.film_id = fc.film_id
WHERE
	UPPER(cat.name) = 'HORROR'
GROUP BY
	cus.customer_id;





