#Task 1. Pull the length of the shortest film from table  film.
select length
from film
order by length asc
limit 1;

#Another option
select min(length)
from film;

#Task 2. Extract all the information about the films with a rental period of 5, order the results by the price of the film (rental_rate) in ascending order from table film.
select *
from film
where rental_duration = 5
order by rental_rate asc;

#Task 3. Write a query where you would sum rental_rate grouped by film rating.  Show only when the rental_rate amount is greater than 600  hint: “having”
select sum(rental_rate) as Sum_rate, rating
from film
group by rating
having Sum_rate > 600;

#Task 4. Pull the films ACE GOLDFINGER, ADAPTATION HOLES, AFFAIR PREJUDICE and their length
select title, length
from film
where  title = "ACE GOLDFINGER" 
	or title = "ADAPTATION HOLES" 
    or title = "AFFAIR PREJUDICE";
    
#Task 5. Calculate the number of films that have trailers in the special features and the price (rental_rate) is 2.99 
select count(*)
from film
where special_features like "%trailers%" and  rental_rate = 2.99;
