#1. Display the titles of all films in the Sakila database where the length of the title is greater than 10 characters and the title contains the word 'Happy'. 
# Use the LENGTH and LOCATE functions together in your query.

SELECT title
FROM film
WHERE title LIKE "%Happy%" AND length(title) > 10;

#2. Find the average rental duration for films in each rating category (G, PG, etc.) 
# where the average length of the film titles is greater than 5 characters. Use AVG, LENGTH, and GROUP BY functions in combination.

SELECT AVG(rental_duration) as Avg_rent_duration, rating, AVG(length(title))
FROM film
GROUP BY rating
HAVING AVG(length(title)) > 5;

#3. Update the actor table, changing the first names to uppercase and last names to lowercase. Use the UPPER and LOWER functions.

#Here I decided to create a new table (copy of actor) in order not to change the original actor table
create table actorSlava as 
select * from actor;

update actorSlava
set first_name = UPPER(first_name), last_name = LOWER(last_name);


#4. Using the payment table write a SQL query to round the amount to the nearest whole number and count how many payments
# were made for each rounded amount. Use the ROUND function and GROUP BY clause.

select round(amount, 0) as Rounded_amount, count(*) as Number_of_payments
from payment
group by Rounded_amount;

#5. Extract the first 5 characters from the titles of all films in the Sakila database and calculate the length of these substrings. Use the SUBSTR and LENGTH functions.

select title, substring(title, 1, 5) as Subst, length(substring(title, 1, 5)) as Substring_length
from film;
