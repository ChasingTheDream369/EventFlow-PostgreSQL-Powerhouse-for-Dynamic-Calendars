-- COMP3311 20T3 Assignment 1
-- Calendar schema
-- Written by SHUBHAM JOHAR

-- Types and Domains
create type AccessibilityType as enum ('read-write','read-only','none');
create type InviteStatus as enum ('invited','accepted','declined');
create type visibility as enum('public', 'private');

-- Tables

create table Users (
	id          serial,
	email       text not null unique check (email like '%@%'),
    name        text not null,
    passwd      text not null,
    is_admin    boolean not null, -- The user can or cannot be an admin so it has a boolean type with non-nullity constraint
	primary key (id)
);

create table Groups (
	id          serial,
	name        text not null,
	Owner       integer not null, --Covers the 1:N realtionship of Owner between Users and Groups
	primary key (id),
	foreign key (Owner) references Users(id),
	unique (name, Owner) -- Since a user would be confued having two groups
						-- with the same name so making the tuple of Group and 
						-- Owner as unique. 
);

--N:M realtion covering memebers between Calenders and Users
create table Member (
	Groups_id       integer not null,
	Users_id        integer not null,
	foreign key(Groups_id) references Groups(id),
	foreign key(Users_id)  references Users(id),
	primary key (Groups_id, Users_id)
);

create table Calendars (
	id          serial,
	name        text not null,
	colour      text not null,
	default_access  AccessibilityType not null,
	owner 		integer not null, -- 1:N realtionship between calenders and users
	primary key (id),
	foreign key (owner) references Users(id),
	Unique (name, Owner)           -- Since a user would be confued having two Calendars
								   -- with the same name so making the tuple of Calendars and 
								   -- Owner as unique.
);

create table accessibility (
	Calendars_id integer not null, 
	Users_id	 integer not null,
	access 		AccessibilityType not null,
	Foreign key (Calendars_id) references Calendars(id),
	Foreign key (Users_id) references Users(id),
	primary key (Calendars_id, Users_id, access) -- also adding access as the attribute for the primary key
												 -- although only having Calenders_id and Users_id tuple would also 
												 -- work fine as it defines the realtion uniquely but since the relationship
												 -- is accessibility of the users on calenders and the value of access is never 
												 -- a null value and it is always something in ('read-write','read-only','none')
												 -- so apart from the Calenders_id nad Users_id the access attribute can also
												 -- be used to completely uniquely identify the relationship. Alternatively, the primary key
												 -- can also only be (Calendars_id, Users_id) but adding access makes it more unique.
);

--N:M realtionship between Calenders and Users
create table subscribed (
	Calendars_id integer not null,
	Users_id	integer not null,
	colour 		text,
	foreign key (Calendars_id) references Calendars(id),
	foreign key (Users_id) references Users(id),
	primary key (Calendars_id, Users_id)
);

create table Events (
	id 			serial,
	end_time    time,
	start_time  time, -- No constraint checking on time since if it is a spanning event
					  -- and goes for two days and the starting time is 14:00 but ending time is 2:00, then
					  -- the constraint end_time < start_time would fail. 
	title       text not null default 'Busy', -- Default value set to busy since if 
											 --the user does not have any permissions then the title appears to be busy.
	location    text,
	Created_By  integer not null, -- Covering the 1:N relationship between User and Events.
	Part_Of     integer not null, -- Covering the 1:N realtionship between Calenders and Events.
	visibility	visibility not null,
	primary key (id),
	Foreign key (Created_By) references Users(id),
	Foreign key (Part_Of) references Calendars(id)
);

--Table to cover the multi-valued attribute alarms
create table alarms (
	Events_id	integer,
	alarm       integer not null,-- alarm is integer as it covers both + and - value of the triggered alarm time from the current time.
	Foreign key (Events_id) references Events(id),
	primary key (Events_id, alarm) 
);

-- All the subclasses of events are mapped by ER- mapping of 
-- sublasses as written in the spec, but since it is an disjoint total
-- participation so there is no way of mapping the disjointedness and the
-- total participation of events in its subclasses, the only solution 
-- would depend for that on the use case and the possible solution  
-- would most likely be some design strategy at the front-end, but in sql DDL/
-- schema design we don't have any ways of mapping this.

--The sub-class of Events that has the date for it's event
create table One_Day_Events (
	Events_id 	integer,
	date 		date not null,
	primary key (Events_id),
	Foreign key (Events_id) references Events(id)
);

create table Spanning_Events (
	Events_id	integer,
	start_date 	date not null,
	end_date    date not null check (end_date > start_date),
	primary key (Events_id),
	Foreign key (Events_id) references Events(id)
);

create table Recurring_Events (
	Events_id 	integer,
	end_date    date,
	start_date 	date not null check (start_date < end_date),
	ntimes      integer check (ntimes > 0),
	primary key (Events_id),
	Foreign key (Events_id) references Events(id)
);

-- Now all the events which are sublasses of Recurring Events 
-- are mapped according to E-R mapping but there is no way of 
-- mapping the total participation of Recurring Event and the disjointedness
-- of the various subclasses using the E-R design, so it does'nt include this
-- using a single table and adding constraints to it would work fine, but the spec
-- asks to use the E-R mapping.

create table Weekly_Events (
	Recurring_Events_id integer,
	day_Of_Week  char(3) not null check (day_Of_Week in ('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')),
	frequency   integer not null check (frequency >= 1),
	primary key (Recurring_Events_id),
	Foreign key (Recurring_Events_id) references Recurring_Events(Events_id)
);

create table MonthlyByDayEvents (
	Recurring_Events_id integer,
	day_Of_Week  char(3) not null check (day_Of_Week in ('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun')),
	week_In_Month integer not null check (week_In_Month >= 1 AND week_In_Month <= 5),
	primary key (Recurring_Events_id),
	Foreign key (Recurring_Events_id) references Recurring_Events(Events_id)
);

create table MonthlyByDateEvents (
	Recurring_Events_id integer,
	date_In_month integer not null check (date_In_month >= 1 AND date_In_month <= 31),
	primary key (Recurring_Events_id),
	Foreign key (Recurring_Events_id) references Recurring_Events(Events_id)
	
);

create table AnnualEvent (
	Recurring_Events_id integer,
	date 		date not null, -- although only day needs to stored in this attribute but there is no 
							   -- corresponding type in postgres which helps in storing only the day, so 
							   -- i am using the date type, although text can be used but in running the 
							   -- testing script the data type fails so i am using date.
	primary key (Recurring_Events_id),
	Foreign key (Recurring_Events_id) references Recurring_Events(Events_id)
);

--N:M relationship between Events and Users
create table Invited (
	Events_id 	integer,
	Users_id	integer,
	status      InviteStatus not null,
	primary key (Events_id, Users_id, status), 	 -- also adding status as the attribute for the primary key
												 -- although only having Events_id and Users_id tuple would also 
												 -- work fine as it defines the realtion uniquely but since the relationship
												 -- is whether the user is invited to an Event and the value of status is never 
												 -- a null value and it is always something in ('invited','accepted','declined')
												 -- so apart from the Events_id and Users_id the status attribute can also
												 -- be used to completely uniquely identify the relationship. Alternatively, the primary key
												 -- can also be (Events_id, Users_id) but adding status makes it more unique.
	Foreign key (Events_id) references Events(id),
	Foreign key (Users_id) references Users(id)
);

