--Part 1
--Task 1_1. All animation movies released between 2017 and 2019 with rate more than 1, alphabetical

SELECT title
FROM film f
INNER JOIN film_category fc ON f.film_id = fc.film_id
INNER JOIN category c ON c.category_id = fc.category_id
WHERE UPPER(c.name) = 'ANIMATION' AND f.release_year >= 2017 AND f.release_year <= 2019 AND f.rental_rate > 1
ORDER BY title ASC;

--The same result can be provided with subqueries:

SELECT title
FROM film f
WHERE film_id IN (SELECT film_id
                  FROM film_category
                  WHERE category_id = (SELECT category_id
                                       FROM category
                                       WHERE UPPER(name) = 'ANIMATION'
                                       )
                  )
      AND release_year >= 2017 AND release_year <= 2019 AND rental_rate > 1;



--Task 1_2. The revenue earned by each rental store after March 2017 (columns: address and address2 – as one column, revenue)
      

SELECT CONCAT(a.address,' ', a.address2) AS store_address,      --I use CONCAT() (not string concatenation operator ||) here because it ignores NULL (and we have NULL values in address2) 
       SUM(amount) AS revenue    
FROM store sr
INNER JOIN inventory i ON i.store_id = sr.store_id
INNER JOIN rental r ON r.inventory_id = i.inventory_id
INNER JOIN payment p ON p.rental_id = r.rental_id
INNER JOIN address a ON a.address_id = sr.address_id
WHERE p.payment_date >= '2017-04-01'
GROUP BY sr.store_id, store_address




--Task 1_3. Top-5 actors by number of movies (released after 2015) they took part in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)

SELECT first_name, 
       last_name, 
       COUNT(fa.film_id) AS number_of_movies
FROM actor a
INNER JOIN film_actor fa ON a.actor_id = fa.actor_id
INNER JOIN film f ON f.film_id = fa.film_id 
WHERE f.release_year > 2015
GROUP BY a.actor_id
ORDER BY COUNT(fa.film_id) DESC, first_name, last_name
LIMIT 5;      
/*Here we just cut 5 results by force, but probably this solution can be improved. It seems more logical to provide more than 5 results sometimes. 
 For example, in our case we have one actor with 11 movies and 5 actors with 9 movies, so it is reasonable to provide 6 results. At the moment i don't realize how to do it for an arbitrary number.*/  


/*Task 1_4. *Number of Drama, Travel, Documentary per year (columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies), sorted by release year in descending order.
Dealing with NULL values is encouraged)*/

--Solution with subqueries

SELECT f.release_year, 
       COALESCE(drama.number_of_films, 0) AS number_of_drama_movies, 
       COALESCE(travel.number_of_films, 0) AS number_of_travel_movies, 
       COALESCE(documentary.number_of_films, 0) AS number_of_documentary_movies    
FROM film f
LEFT JOIN (SELECT f.release_year, 
                  COUNT(f.film_id) AS number_of_films 
           FROM film_category fc
           INNER JOIN film f ON f.film_id = fc.film_id
           WHERE category_id = (SELECT category_id
                                FROM category
                                WHERE UPPER(name) = 'DRAMA')
           GROUP BY f.release_year
            ) drama ON drama.release_year = f.release_year
LEFT JOIN (SELECT f.release_year,
                  COUNT(f.film_id) AS number_of_films  
           FROM film_category fc
           INNER JOIN film f ON f.film_id = fc.film_id
           WHERE category_id = (SELECT category_id
                                FROM category
                                WHERE UPPER(name) = 'DOCUMENTARY')
           GROUP BY f.release_year
            ) documentary ON f.release_year = documentary.release_year
LEFT JOIN (SELECT f.release_year, 
                  COUNT(f.film_id) AS number_of_films 
           FROM film_category fc
           INNER JOIN film f ON f.film_id = fc.film_id
           WHERE category_id = (SELECT category_id
                                FROM category
                                WHERE UPPER(name) = 'TRAVEL')
           GROUP BY f.release_year
            ) travel ON f.release_year = travel.release_year
GROUP BY f.release_year, drama.number_of_films, documentary.number_of_films, travel.number_of_films
ORDER BY f.release_year DESC;


--The same soulution, but with CTEs. I think they don't influence calculation time here (as far every CTE is calculated only once), but at least readability of our main SELECT statement becomes better. 

WITH drama_by_years AS (
    SELECT f.release_year, 
           COUNT(f.film_id) AS number_of_films
    FROM film_category fc
    INNER JOIN film f ON f.film_id = fc.film_id
    WHERE category_id = (SELECT category_id
                         FROM category
                         WHERE UPPER(name) = 'DRAMA')
    GROUP BY f.release_year),
             
documentary_by_years AS (
    SELECT f.release_year, 
           COUNT(f.film_id) AS number_of_films
	FROM film_category fc
	INNER JOIN film f ON f.film_id = fc.film_id
	WHERE category_id = (SELECT category_id
	                     FROM category
	                     WHERE UPPER(name) = 'DOCUMENTARY')
	GROUP BY f.release_year),
	             
travel_by_years AS (
    SELECT f.release_year, 
           COUNT(f.film_id) as number_of_films
    FROM film_category fc
	INNER JOIN film f ON f.film_id = fc.film_id
    WHERE category_id = (SELECT category_id
		                 FROM category
		                 WHERE UPPER(name) = 'TRAVEL')
    GROUP BY f.release_year)
	             
SELECT f.release_year, 
       COALESCE(drama_by_years.number_of_films, 0) AS number_of_drama_movies, 
       COALESCE(travel_by_years.number_of_films, 0) AS number_of_travel_movies, 
       COALESCE(documentary_by_years.number_of_films, 0) AS number_of_documentary_movies    
FROM film f
LEFT JOIN drama_by_years ON f.release_year = drama_by_years.release_year 
LEFT JOIN documentary_by_years ON f.release_year = documentary_by_years.release_year
LEFT JOIN travel_by_years ON f.release_year = travel_by_years.release_year
GROUP BY f.release_year, drama_by_years.number_of_films, documentary_by_years.number_of_films, travel_by_years.number_of_films
ORDER BY f.release_year DESC;


--Part 2
/*Task 2_1. Who were the top revenue-generating staff members in 2017? They should be rewarded with a bonus for their performance. 
Please indicate which store the employee worked in. If he changed stores during 2017, indicate the last one*/


/* We made an assumption that payment should be processed in the same store where rental has been made. As far as there are one staff member can have more than one identical last payment dates, we 
 use maximum payment_id - it allows us to unambiguously determine store where last payment in 2017 for each staff member has been done. */

WITH staff_store_revenue AS               /*This CTE provides us total revenue for every staff member in both stores, and also last payment id 
                                           which we will use to indicate last store in 2017 for every staff member.*/
(
SELECT                                                   
	p.staff_id,
	s.store_id,
	SUM(p.amount) AS revenue,
	MAX (p.payment_id) AS last_payment_id
FROM
	payment p
INNER JOIN rental r ON
	r.rental_id = p.rental_id
INNER JOIN inventory i ON
	i.inventory_id = r.inventory_id
INNER JOIN store s ON
	s.store_id = i.store_id
WHERE
	p.payment_date > '20161231'::TIMESTAMPTZ
	AND p.payment_date < '20180101'::TIMESTAMPTZ
GROUP BY
	p.staff_id,
	s.store_id
),

staff_store AS                        --This CTE provides the same output as previous one, but only for the last store in which every staff member worked in 2017
(
SELECT
	t.staff_id,
	t.revenue,
	t.store_id
FROM
	staff_store_revenue t
WHERE
	t.last_payment_id = 
       (
	SELECT
		MAX(p.payment_id)
	FROM
		payment p
	WHERE
		p.staff_id = t.staff_id
		AND p.payment_date > '20161231'::TIMESTAMPTZ
		AND p.payment_date < '20180101'::TIMESTAMPTZ           
       )
),

max_revenue_stores AS                 --Here we provide max revenue for every store
(
SELECT
    staff_store.store_id,
	MAX(staff_store.revenue) AS max_revenue
FROM
	staff_store
GROUP BY
	staff_store.store_id
)


SELECT                                 --And finally we provide staff member, store and maximum revenue 
	staff_store.staff_id,
	staff_store.store_id,
	max_revenue_stores.max_revenue
	
FROM
	max_revenue_stores
	INNER JOIN staff_store ON max_revenue_stores.max_revenue = staff_store.revenue;       
             



/*Task 2_2. Which 5 movies were rented more than others, and what's the expected age of the audience for these movies? 
To determine expected age please use 'Motion Picture Association film rating system'*/

SELECT f.title,
       COUNT(r.rental_id) AS number_of_rents, 
       CASE
	       WHEN f.rating = 'G' THEN 'All ages'
           WHEN f.rating = 'PG' THEN 'Some material may not be suitable for children'
           WHEN f.rating = 'PG-13' THEN 'Some material may be inappropriate for children under 13'
           WHEN f.rating = 'R' THEN 'All ages and children under 17 with guidance'
	       ELSE 'Adults only'
       END AS expected_age 
FROM film f
INNER JOIN inventory i ON f.film_id = i.film_id
INNER JOIN rental r ON r.inventory_id = i.inventory_id
GROUP BY f.film_id
ORDER BY COUNT(r.rental_id) DESC, title ASC    --Here I added ordering by title. Now at least I know what to expect after cutting top 5 results. 
LIMIT 5;
/*Quite similar problem as I had in Task 1_3. Not clear what the criterion is for discarding some of the movies which have the same number of rents. I decided to do it by sorting alphabetically on title.
  It is also worth to notice that if the question was "Which N movies were rented less than others", usage of LEFT JOIN instead of INNER JOIN would help us to consider films which are presented in "film" table,
  but are not presented in "inventory" table and naturally have zero rents */  

--Part 3
/* Which actors/actresses didn't act for a longer period of time than the others? 
V1: gap between the latest release_year and current year per each actor*/

SELECT a.first_name || ' ' || a.last_name AS full_name,
       MIN(EXTRACT('Year' FROM CURRENT_DATE) - release_year) AS minimal_gap
FROM actor a
INNER JOIN film_actor fa ON fa.actor_id = a.actor_id
INNER JOIN film f ON f.film_id = fa.film_id
GROUP BY full_name
HAVING MIN(EXTRACT('Year' FROM CURRENT_DATE) - release_year) > 6  --That's the criterion I've randomly chosen to provide top actors having the biggest gap between the latest release_year and current year
ORDER BY minimal_gap DESC


--V2: gaps between sequential films per each actor

--Solution_1

WITH actor_release_year AS
(
SELECT	DISTINCT 
    fa.actor_id,
	f.release_year
FROM
	film_actor fa
JOIN film f ON
	f.film_id = fa.film_id
ORDER BY
	fa.actor_id,
	f.release_year
)
SELECT
a.first_name || ' ' || a.last_name AS actor_full_name,
	SUM(                                                                 /*Here we use SUM assuming that it will be the criterion of non-acting (bigger sum of gaps --> longer period of non-acting), 
	                                                                      but maybe it also makes sense to use MAX to get maximum sequential gap for every actor and use it as criterion.*/ 
    (
    SELECT COALESCE(MIN(t.release_year), EXTRACT(YEAR FROM current_date)) /*When we reach the year of most recent film for a certain actor, the next one will be NULL. COALESCE helps us 
                                                                            to get current year instead, so the last gap will be calculated between current year and last film year.*/     
    FROM actor_release_year t 
    WHERE t.actor_id = q.actor_id AND t.release_year > q.release_year  --This filtering (basically, comparing the table with itself) allows us to move through release years 
    ) - q.release_year-1) AS gaps                                    --For every release year we get gap between this year and following one. For consecutive years (e.g. 2013,2014) gap is assumed to be zero.  
FROM
	actor_release_year q
JOIN actor a ON
	a.actor_id = q.actor_id
GROUP BY
	a.first_name || ' ' || a.last_name,
	a.actor_id
ORDER BY
	gaps DESC;
/*So, the tricky moment here is about using subquery inside aggregation function*/




--Solution_2

WITH actor_release_year AS
(
SELECT	DISTINCT 
    fa.actor_id,
	f.release_year
FROM
	film_actor fa
JOIN film f ON
	f.film_id = fa.film_id
ORDER BY
	fa.actor_id,
	f.release_year
)

SELECT
	a.first_name || ' ' || a.last_name as full_name,
	MAX(release_year-prev_release_year) AS max_years_without_film
FROM
	(
	SELECT
		MAX(a2.release_year) AS prev_release_year,
		a1.release_year,
		a1.actor_id
	FROM
		actor_release_year a1
	INNER JOIN actor_release_year a2 ON
		a1.actor_id = a2.actor_id
	WHERE
		a1.release_year > a2.release_year
	GROUP BY
		a1.actor_id,
		a1.release_year
) AS q
JOIN actor a ON
	a.actor_id = q.actor_id
GROUP BY
	a.actor_id
ORDER BY
	MAX(release_year-prev_release_year) DESC;




--V3:gap between the release of their first and last film

SELECT a.first_name || ' ' || a.last_name AS full_name,
       MAX(release_year) - MIN(release_year) AS maximal_gap
FROM actor a
INNER JOIN film_actor fa ON fa.actor_id = a.actor_id
INNER JOIN film f ON f.film_id = fa.film_id
GROUP BY full_name
ORDER BY maximal_gap DESC, full_name ASC;
/*The problem here is that I don't understand how gap between the release of actor's first and last film is really connected with not performing for a longer period of time. 
 For example, this gap can be 30 years, but at the same time the gap between last and penultimate films can be 2 years, which means this actor is really active (this question has also been raised in Teams)*/

