create database Polyclinic;

create table Risk_group
(
	Id int identity(1,1) primary key,
	[Name] varchar(100),
	[Count1] int,
	[Status] int
);

create table Patient
(
	Id int identity(1,1) primary key,
	Risk_Group_id int foreign key references Risk_group(Id),
	Date_of_first datetime,
	Surname varchar(20),
	[Name] varchar(20),
	[Middle_Name] varchar(20),
	[Birthdate] datetime,
	[Health_status] int,
	[Phone] varchar(20),
	[Address] varchar(20)
);

create table Journal
(
	Id int identity(1, 1) primary key,
	Procedure_id int foreign key references [Procedure](Id),
	Patient_id int foreign key references Patient(Id),
	[Date] datetime,
	Mark int,
	Comment varchar(100)
);

create table [Procedure]
(
	Id int identity(1, 1) primary key,
	Medic_id int foreign key references Medic(Id),
	[Name] varchar(50),
	[Hours] int
);

create table [Medic]
(
	Id int identity(1, 1) primary key,
	Date_of_start datetime,
	Surname varchar(20),
	[Name] varchar(20),
	Coefficient float,
	Salary int
);

create table Users
(
	[Right] int, -- 0 Ч пациент, 1 Ч врач, 2 Ч администраци€ поликлиники
	[Login] varchar(50),
	[Password] varchar(50),
)

drop table Users;

select * from Users;