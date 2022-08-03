--1. В каких городах больше одного аэропорта?

select city, count(airport_name)   -- выводим города и считаем количество аэропортов из таблицы airports
from airports 
group by city 						-- группируем по городу, т.к. использовали агрегатную функцию
having count(airport_name) >1		-- добавляем условие больше 1 аэропорта


--2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?

select a.airport_name  												-- названия аэропортов из таблицы airports
from airports a 																
join flights f on a.airport_code = f.arrival_airport 				-- присоединяем таблицу flights по коду аэропорта, чтобы иметь данные по полетам в аэропортах
join (																-- присоединяем таблицу используя подзапрос
	select aircraft_code 											-- выводим код самолета из таблицы aircrafts
	from aircrafts 
	order by "range" desc											-- сортируем по дальности полета (range) от большего к меньшему
	limit 1)	q on q.aircraft_code = f.aircraft_code				-- выводим с помощью 'limit 1' самолет с самой большой дальностью, и соединяем по коду самолета
group by a.airport_name 											-- сгруппируем полученные данные по названию аэропорта							


-- 3. Вывести 10 рейсов с максимальным временем задержки вылета

select flight_no, actual_departure - scheduled_departure as rr			-- выводим номер рейса, считаем: Фактическое время вылета - Время вылета по расписанию = время на которое самолет задержался
from flights 															-- из таблицы flights
where actual_departure - scheduled_departure is not null				-- убираем null, т.к. есть пропуски в БД
order by rr desc limit 10												-- сортируем от большего к меньшему, выводим только первые 10 строчек


-- 4. Были ли брони, по которым не были получены посадочные талоны?

select distinct book_ref 											-- выводим уникальный номер бронирования
from tickets t 														-- из таблицы tickets, т.к. в ней есть все номера брони и билетов
left join boarding_passes bp on t.ticket_no = bp.ticket_no			-- используем left join, потому что нужны все данные из таблицы tickets. Присоедяняем таблицу boarding_passes по билету (ticket_no)
where bp.boarding_no is null										-- фильтруем данные. Оставляем только те, в которых нет данных о посадочном талоне


-- 5. Найдите количество свободных мест для каждого рейса, их % отношение к общему количеству мест в самолете.
-- Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. 
-- Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах в течении дня.

with ste_1 as (																									-- создаём ste_1, где посчитаем общее количество мест на каждый рейс
	select flight_id , count(s.seat_no) obshee																	-- выводим номер рейса и считаем общее количество доступных мест в самолете
	from flights f 																								-- из таблицы с рейсами
	join seats s on s.aircraft_code = f.aircraft_code 															-- присоединяем таблицу seats по коду самолета, чтобы могли посчитать количество мест в самолете
	group by flight_id ),																						-- группируем по номеру рейса
ste_2 as (																										-- создаём ste_2, где посчитаем количество занятых мест на каждый рейс
	select flight_id , count(seat_no) zanyato																	-- выводим номер рейса и считаем количество занятых мест
	from boarding_passes bp 																					-- из таблицы boarding_passes, т.к. там есть указание мест пассажиров
	group by flight_id 																							-- группируем по номеру рейса
)
select  st1.flight_id,																							-- выводим номер рейса
	obshee - zanyato svobodno, 																					-- считаем: общее количество мест - занятые = свободные места
	round( 100 - (zanyato::float/obshee)*100) || '%'  percent_svobodno,											-- считаем: 100% - (занятые места/свободные)*100 = процент свободных мест, проводим к типу данных float и округляем до целого числа. Добавляем знак '%'
	departure_airport , f.scheduled_departure,					          																-- выводим аэропорт и время вылета 
	sum (zanyato) over (partition by departure_airport, f.scheduled_departure::date order by f.scheduled_departure) nakopleniye			-- оконная функция с накоплением. Суммируем количество вылетевших (занятых мест) пассажиров по каждому аэропорту и каждому дню вылета (приводим время вылета к типу date), сортируем по времени вылета
from ste_1 st1																															-- данные из ste_1
join ste_2 st2 on st1.flight_id = st2.flight_id																	-- соединяем с ste_2 по id рейса
join flights f on st1.flight_id = f.flight_id 																	-- соединяем с flights по id рейса, для информации по аэропорту и времени вылета


-- 6.Найдите процентное соотношение перелетов по типам самолетов от общего количества.

select aircraft_code,																					
	round (100*count (aircraft_code)/sum (count (aircraft_code)) over (), 1) || '%' "percent"			-- оконной функцией считаем: 100*количество полетов каждой модели самолета / сумму полета всех моделей самолета, округляем до 1 знака после запятой
from flights f 
group by aircraft_code 	 																				-- группируем по коду самолета


--7.Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?
 
with cte_b as (																-- создаем cte_b в котором считаем минимальную стоимость места в бизнес классе, в каждом рейсе
	select flight_id , fare_conditions , min(amount) mini 
	from ticket_flights 													-- из таблицы ticket_flights, т.к. есть данные по рейсам и цене за место
	group by flight_id, fare_conditions										-- группируем данные по рейсу, классу
	having fare_conditions = 'Business'										-- выводим только бизнес класс
),
cte_e as (																	-- создаем cte_e в котором считаем максимальную стоимость места в эконом классе, в каждом рейсе
	select flight_id , fare_conditions , max(amount) maxi 					
	from ticket_flights 													-- такая же логика что и в cte_b
	group by flight_id, fare_conditions
	having fare_conditions = 'Economy'
)
select b.flight_id, b.fare_conditions, b.mini,								-- выводим необходимые атрибуты
	e.fare_conditions, e.maxi, c.city
from cte_b b
join cte_e e on b.flight_id = e.flight_id									-- соединяем cte по номеру рейса. Получаем таблицу с минимальной ценой бизнес класса и максимальной ценой эконом класса, в каждом рейсе
join (  
	select flight_id, city													-- присоединяем подзапрос. В котором находим номер рейса и город, в который он направлялся
	from flights f 
	join airports a on a.airport_code = f.arrival_airport 
) c on c.flight_id = e.flight_id											-- соединяем по номеру рейса
where maxi > mini															-- фильтруем данные, где максимальная стоимость билета за эконом класс больше минимальной стоимости бизнес класса

-- Таких направлений нет. 


-- 8. Между какими городами нет прямых рейсов?

select distinct a.city,  a2.city											-- выбираем уникальные пары городов из декартово произведения
from airports a , airports a2 												-- создаем декартово произведение в from 
where a.city != a2.city 													-- фильтруем города, чтобы город не соотносился с самим собой
except																		-- удаляем из декартово произведения уже существующие маршруты
select distinct a.city , a2.city 											-- выбираем уникальные пары городов у которых есть прямые рейсы
from flights f 																-- из таблицы flights
join airports a on f.departure_airport = a.airport_code 					-- присоединяем таблицу airports, по условию аэропорт вылета = коду аэропорта
join airports a2 on f.arrival_airport = a2.airport_code 					-- еще раз присоединяем таблицу airports, по условию аэропорт прилета = коду аэропорта


create view goroda as (														-- создаем материализованное представление
	select distinct a.city city1,  a2.city	city2										
	from airports a , airports a2 												
	where a.city != a2.city 													
	except																		
	select distinct a.city , a2.city 											
	from flights f 																
	join airports a on f.departure_airport = a.airport_code 					
	join airports a2 on f.arrival_airport = a2.airport_code)


-- 9. Вычислите расстояние между аэропортами, связанными прямыми рейсами, 
-- сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы 

with cte as (																																	-- создал cte, чтобы разделить логику
	select distinct a.airport_name as a_name , a.longitude as a_longitude, a.latitude as a_latitude, 											-- в cte получим таблицу с городом вылета и его координатами, городом прибытия и его координатами, модель самолета выполняющего рейс
			b.airport_name as b_name, b.longitude as b_longitude, b.latitude as  b_latitude,
			f.aircraft_code as code
	from flights f 																																-- из таблицы flights в которой есть аэропорт вылета и прибытия
	join airports a on f.departure_airport = a.airport_code 																					-- дополним таблицу городом из которого вылетают и его координатами
	join airports b on f.arrival_airport = b.airport_code )																						-- дополним таблицу городом в который прилетают и его координатами
select a_name, b_name,																																
	round (acos(sind(a_latitude)*sind(b_latitude) + cosd(a_latitude)*cosd(b_latitude)*cosd(a_longitude - b_longitude)) * 6371)  as rasstoyaniye,   -- используем формулу для расчета расстояния
	a2.model,
	 case 
	 	when a2."range" > acos(sind(a_latitude)*sind(b_latitude) + cosd(a_latitude)*cosd(b_latitude)*cosd(a_longitude - b_longitude)) * 6371 then 'долетит'		-- создадим условие: если дальность полета больше расстояния между городами, то 'долетит'
	 	else 'не долетит'																																		-- иначе 'не долетит'
	 end
from cte c
join aircrafts a2 on a2.aircraft_code = c.code																									-- присоединим таблицу с моделями самолета и их дальностью полета
