select
count(*)
from film_actor;

select
count(*)
from film;

select count(*)
from film f
join film_actor fa on fa.film_id = f.film_id;

select *
from film f
left join film_actor fa on fa.film_id = f.film_id;

select f.title, a.first_name
from film f
left join film_actor fa on fa.film_id = f.film_id
left join actor a on a.actor_id=fa.actor_id
where a.first_name is NULL;
#Здесь получаем не нуль, т.к. не каждый фильм привязан к актеру

select f.title, a.first_name
from actor a
right join film_actor fa on a.actor_id = fa.actor_id
right join film f on f.film_id = fa.film_id
where a.first_name is NULL;
#То же в обратном порядке. Здесь снова получаем не нуль, т.к. не каждый фильм привязан к актеру


select f.title, a.first_name
from actor a
left join film_actor fa on a.actor_id = fa.actor_id
left join film f on f.film_id = fa.film_id
where a.first_name is NULL;
#Здесь получаем нуль, т.к. каждый актер привязан к фильму
