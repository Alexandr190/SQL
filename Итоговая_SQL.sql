--1. � ����� ������� ������ ������ ���������?

select city, count(airport_name)   -- ������� ������ � ������� ���������� ���������� �� ������� airports
from airports 
group by city 						-- ���������� �� ������, �.�. ������������ ���������� �������
having count(airport_name) >1		-- ��������� ������� ������ 1 ���������


--2. � ����� ���������� ���� �����, ����������� ��������� � ������������ ���������� ��������?

select a.airport_name  												-- �������� ���������� �� ������� airports
from airports a 																
join flights f on a.airport_code = f.arrival_airport 				-- ������������ ������� flights �� ���� ���������, ����� ����� ������ �� ������� � ����������
join (																-- ������������ ������� ��������� ���������
	select aircraft_code 											-- ������� ��� �������� �� ������� aircrafts
	from aircrafts 
	order by "range" desc											-- ��������� �� ��������� ������ (range) �� �������� � ��������
	limit 1)	q on q.aircraft_code = f.aircraft_code				-- ������� � ������� 'limit 1' ������� � ����� ������� ����������, � ��������� �� ���� ��������
group by a.airport_name 											-- ����������� ���������� ������ �� �������� ���������							


-- 3. ������� 10 ������ � ������������ �������� �������� ������

select flight_no, actual_departure - scheduled_departure as rr			-- ������� ����� �����, �������: ����������� ����� ������ - ����� ������ �� ���������� = ����� �� ������� ������� ����������
from flights 															-- �� ������� flights
where actual_departure - scheduled_departure is not null				-- ������� null, �.�. ���� �������� � ��
order by rr desc limit 10												-- ��������� �� �������� � ��������, ������� ������ ������ 10 �������


-- 4. ���� �� �����, �� ������� �� ���� �������� ���������� ������?

select distinct book_ref 											-- ������� ���������� ����� ������������
from tickets t 														-- �� ������� tickets, �.�. � ��� ���� ��� ������ ����� � �������
left join boarding_passes bp on t.ticket_no = bp.ticket_no			-- ���������� left join, ������ ��� ����� ��� ������ �� ������� tickets. ������������ ������� boarding_passes �� ������ (ticket_no)
where bp.boarding_no is null										-- ��������� ������. ��������� ������ ��, � ������� ��� ������ � ���������� ������


-- 5. ������� ���������� ��������� ���� ��� ������� �����, �� % ��������� � ������ ���������� ���� � ��������.
-- �������� ������� � ������������� ������ - ��������� ���������� ���������� ���������� ���������� �� ������� ��������� �� ������ ����. 
-- �.�. � ���� ������� ������ ���������� ������������� ����� - ������� ������� ��� �������� �� ������� ��������� �� ���� ��� ����� ������ ������ � ������� ���.

with ste_1 as (																									-- ������ ste_1, ��� ��������� ����� ���������� ���� �� ������ ����
	select flight_id , count(s.seat_no) obshee																	-- ������� ����� ����� � ������� ����� ���������� ��������� ���� � ��������
	from flights f 																								-- �� ������� � �������
	join seats s on s.aircraft_code = f.aircraft_code 															-- ������������ ������� seats �� ���� ��������, ����� ����� ��������� ���������� ���� � ��������
	group by flight_id ),																						-- ���������� �� ������ �����
ste_2 as (																										-- ������ ste_2, ��� ��������� ���������� ������� ���� �� ������ ����
	select flight_id , count(seat_no) zanyato																	-- ������� ����� ����� � ������� ���������� ������� ����
	from boarding_passes bp 																					-- �� ������� boarding_passes, �.�. ��� ���� �������� ���� ����������
	group by flight_id 																							-- ���������� �� ������ �����
)
select  st1.flight_id,																							-- ������� ����� �����
	obshee - zanyato svobodno, 																					-- �������: ����� ���������� ���� - ������� = ��������� �����
	round( 100 - (zanyato::float/obshee)*100) || '%'  percent_svobodno,											-- �������: 100% - (������� �����/���������)*100 = ������� ��������� ����, �������� � ���� ������ float � ��������� �� ������ �����. ��������� ���� '%'
	departure_airport , f.scheduled_departure,					          																-- ������� �������� � ����� ������ 
	sum (zanyato) over (partition by departure_airport, f.scheduled_departure::date order by f.scheduled_departure) nakopleniye			-- ������� ������� � �����������. ��������� ���������� ���������� (������� ����) ���������� �� ������� ��������� � ������� ��� ������ (�������� ����� ������ � ���� date), ��������� �� ������� ������
from ste_1 st1																															-- ������ �� ste_1
join ste_2 st2 on st1.flight_id = st2.flight_id																	-- ��������� � ste_2 �� id �����
join flights f on st1.flight_id = f.flight_id 																	-- ��������� � flights �� id �����, ��� ���������� �� ��������� � ������� ������


-- 6.������� ���������� ����������� ��������� �� ����� ��������� �� ������ ����������.

select aircraft_code,																					
	round (100*count (aircraft_code)/sum (count (aircraft_code)) over (), 1) || '%' "percent"			-- ������� �������� �������: 100*���������� ������� ������ ������ �������� / ����� ������ ���� ������� ��������, ��������� �� 1 ����� ����� �������
from flights f 
group by aircraft_code 	 																				-- ���������� �� ���� ��������


--7.���� �� ������, � ������� �����  ��������� ������ - ������� �������, ��� ������-������� � ������ ��������?
 
with cte_b as (																-- ������� cte_b � ������� ������� ����������� ��������� ����� � ������ ������, � ������ �����
	select flight_id , fare_conditions , min(amount) mini 
	from ticket_flights 													-- �� ������� ticket_flights, �.�. ���� ������ �� ������ � ���� �� �����
	group by flight_id, fare_conditions										-- ���������� ������ �� �����, ������
	having fare_conditions = 'Business'										-- ������� ������ ������ �����
),
cte_e as (																	-- ������� cte_e � ������� ������� ������������ ��������� ����� � ������ ������, � ������ �����
	select flight_id , fare_conditions , max(amount) maxi 					
	from ticket_flights 													-- ����� �� ������ ��� � � cte_b
	group by flight_id, fare_conditions
	having fare_conditions = 'Economy'
)
select b.flight_id, b.fare_conditions, b.mini,								-- ������� ����������� ��������
	e.fare_conditions, e.maxi, c.city
from cte_b b
join cte_e e on b.flight_id = e.flight_id									-- ��������� cte �� ������ �����. �������� ������� � ����������� ����� ������ ������ � ������������ ����� ������ ������, � ������ �����
join (  
	select flight_id, city													-- ������������ ���������. � ������� ������� ����� ����� � �����, � ������� �� �����������
	from flights f 
	join airports a on a.airport_code = f.arrival_airport 
) c on c.flight_id = e.flight_id											-- ��������� �� ������ �����
where maxi > mini															-- ��������� ������, ��� ������������ ��������� ������ �� ������ ����� ������ ����������� ��������� ������ ������

-- ����� ����������� ���. 


-- 8. ����� ������ �������� ��� ������ ������?

select distinct a.city,  a2.city											-- �������� ���������� ���� ������� �� ��������� ������������
from airports a , airports a2 												-- ������� ��������� ������������ � from 
where a.city != a2.city 													-- ��������� ������, ����� ����� �� ����������� � ����� �����
except																		-- ������� �� ��������� ������������ ��� ������������ ��������
select distinct a.city , a2.city 											-- �������� ���������� ���� ������� � ������� ���� ������ �����
from flights f 																-- �� ������� flights
join airports a on f.departure_airport = a.airport_code 					-- ������������ ������� airports, �� ������� �������� ������ = ���� ���������
join airports a2 on f.arrival_airport = a2.airport_code 					-- ��� ��� ������������ ������� airports, �� ������� �������� ������� = ���� ���������


create view goroda as (														-- ������� ����������������� �������������
	select distinct a.city city1,  a2.city	city2										
	from airports a , airports a2 												
	where a.city != a2.city 													
	except																		
	select distinct a.city , a2.city 											
	from flights f 																
	join airports a on f.departure_airport = a.airport_code 					
	join airports a2 on f.arrival_airport = a2.airport_code)


-- 9. ��������� ���������� ����� �����������, ���������� ������� �������, 
-- �������� � ���������� ������������ ���������� ���������  � ���������, ������������� ��� ����� 

with cte as (																																	-- ������ cte, ����� ��������� ������
	select distinct a.airport_name as a_name , a.longitude as a_longitude, a.latitude as a_latitude, 											-- � cte ������� ������� � ������� ������ � ��� ������������, ������� �������� � ��� ������������, ������ �������� ������������ ����
			b.airport_name as b_name, b.longitude as b_longitude, b.latitude as  b_latitude,
			f.aircraft_code as code
	from flights f 																																-- �� ������� flights � ������� ���� �������� ������ � ��������
	join airports a on f.departure_airport = a.airport_code 																					-- �������� ������� ������� �� �������� �������� � ��� ������������
	join airports b on f.arrival_airport = b.airport_code )																						-- �������� ������� ������� � ������� ��������� � ��� ������������
select a_name, b_name,																																
	round (acos(sind(a_latitude)*sind(b_latitude) + cosd(a_latitude)*cosd(b_latitude)*cosd(a_longitude - b_longitude)) * 6371)  as rasstoyaniye,   -- ���������� ������� ��� ������� ����������
	a2.model,
	 case 
	 	when a2."range" > acos(sind(a_latitude)*sind(b_latitude) + cosd(a_latitude)*cosd(b_latitude)*cosd(a_longitude - b_longitude)) * 6371 then '�������'		-- �������� �������: ���� ��������� ������ ������ ���������� ����� ��������, �� '�������'
	 	else '�� �������'																																		-- ����� '�� �������'
	 end
from cte c
join aircrafts a2 on a2.aircraft_code = c.code																									-- ����������� ������� � �������� �������� � �� ���������� ������
