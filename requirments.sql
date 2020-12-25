-- Представления

-- Связи между преподавателями и предметами


--1
alter view [Medic_view] as
	select concat(T.Surname, ' ', T.Name) as 'Врач', S.Name as 'Процедура' from
		Medic T inner join [Procedure] S on S.Medic_id = T.Id;

select * from Medic_view;

select * from [Procedure];

delete from Medic
	where Id = 10

--2
create view [Patient_fio] as
	select T.Id, concat(T.Surname, ' ', T.Name, ' ', T.Middle_Name) as 'Пациент' from Patient T;

select * from Patient_fio;


--3
create view [Medic_fi] as
	select Id, Name + ' ' + Surname as 'Врач' from Medic;

select * from Medic_fi;


--4
create view work_with_journal as
	select C.Name as 'Группа риска', Proce.Name as 'Процедура', S.Surname + ' ' + S.Name as 'Пациент', J.Date as 'Дата', J.Mark as 'Оценка пациента', J.Comment as 'Комментарий врача'
		from Journal J inner join Patient S on J.Patient_id = S.Id inner join Risk_group C on C.Id = S.Risk_Group_id inner join [Procedure] Proce on J.Procedure_id = Proce.Id
			order by C.Name offset 0 rows

select * from work_with_journal;


-- Процедуры

	-- Пациенты с оценкой здоровья выше чем
create procedure Health_status_Check
	@health_param int = 0
as
begin
	select C.Name 'Группа риска', S.Name + ' ' + S.Surname + ' ' + S.Middle_name as 'Пациент', S.Health_status as 'Оценка здоровья' from Patient S, Risk_group C
		where S.Health_status > @health_param and C.Id = S.Risk_Group_id
end

exec Health_status_Check 4;

--

	-- Увеличение зарплаты врачу
create procedure increase_salary
	@increase_param int = 0,
	@medic_id int = 0
as
begin
	update Medic
		set Salary = (1 + @increase_param/100.) * Salary
		where Id = @medic_id
end;

exec increase_salary 20, 4;

-- Табличная функция, возвращающая все процедуры для пациента
alter function All_procedures_for_patient
(
	@Surname varchar(50),
	@Name varchar(50)
)
returns table
as
return
(
	select Proce.Name as 'Процедура',
	J.Date as 'Дата',
	J.Mark as 'Оценка пациента',
	J.Comment as 'Комментарий врача'
	from Journal J inner join [Procedure] Proce on J.Procedure_id = Proce.Id
	where J.Patient_id = (select Id from Patient where Name = @Name and Surname = @Surname)
	
);


select * from dbo.All_procedures_for_patient('Морозов', 'Антон');
	

 -- Функция для использования в триггере
create function count_average_for_patient
(
	@Patient_id int
)
returns real
as
begin
	declare @res real
	
	select @res = (select avg(cast(Mark as float)) from Journal where Patient_id = @Patient_id)

	return @res
end;
	
select dbo.count_average_for_patient(5);

create function count_average_for_patient2
(
	@Medic_id int
)
returns real
as
begin
	declare @res real
	
	select @res = (select avg(cast(Mark as float)) from Journal where Procedure_id in (select Id from [Procedure] where Medic_id = @Medic_id))

	return @res*2
end;

select dbo.count_average_for_patient2(5);

-- Табличная ф-я

alter function patient_types()
returns @resTable table
(
	Пациент varchar(100),
	[Оценка здоровья] float,
	[Группа риска] varchar(100)
)
as
begin
insert @resTable
	select Surname + ' ' + Name + ' ' + Middle_Name, Health_status, 'Отличное здоровье' from Patient
		where Health_status = 5
	union
	select Surname + ' ' + Name + ' ' + Middle_Name, Health_status, 'Есть серьезные проблемы со здоровьем' from Patient
		where Health_status < 4
	union
	select Surname + ' ' + Name + ' ' + Middle_Name, Health_status, 'Есть некоторые проблемы' from Patient
		where Health_status >= 4 and Health_status < 5
return
end;

drop function patient_types;

select * from dbo.patient_types();


-- 3 триггера

-- 1
create trigger [update_avg1]
	on Journal
	after insert 
as
begin
	declare @id int
	set @id = (select Patient_id from inserted)
	update Patient
		set Health_status = (select dbo.count_average_for_patient(@id))
		where Patient.Id = @id
end;

drop trigger update_avg;

-- 2
create trigger update_avg2
	on Journal
	after update 
as
begin
	declare @id int
	set @id = (select Patient_id from inserted)
	update Patient
		set Health_status = (select dbo.count_average_for_patient(@id))
		where Patient.Id = @id
end;

-- 3
create trigger delete_Medic
	on Medic
	instead of delete
as
begin
	update [Procedure]
		set Medic_id = NULL
		where Medic_id = (select Id from deleted)
	delete from Medic where Id = (select Id from deleted)
end;


alter trigger check_insert
	on Patient
	instead of insert
as
begin
	declare @aux int
	set @aux = (select Count1 from Risk_group where Id = (select Risk_Group_id from inserted))
	if @aux <> 30
	begin
		update Risk_group
			set Count1 = Count1 + 1
			where Id = (select Risk_Group_id from inserted)
		insert into Patient select Risk_Group_id, Date_of_first, Surname, Name, Birthdate, Health_status, Address, Phone, Middle_Name from inserted
	end
end;


alter trigger check_delete
	on Patient
	after delete
as
begin
	declare @aux int
	set @aux = (select Count1 from Risk_group where Id = (select Risk_Group_id from deleted))
	update Risk_group
		set Count1 = Count1 - 1
		where Id = (select Risk_Group_id from deleted)
end;


create trigger update_Coef
	on Journal
	after insert, update
as
begin
	declare @id int
	set @id = (select Medic_id from [Procedure] where Id = (select Procedure_id from inserted))
	update Medic
		set Coefficient = (select dbo.count_average_for_patient2(@id))
		where Medic.Id = @id
end;
		
