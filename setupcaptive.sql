create user captive with password '?fakingthecaptive?'; 
create database captive; 
\connect captive; 
create table pass (id SERIAL, ipv4 varchar(16), ipv6 varchar(40), created timestamp DEFAULT current_timestamp); 
grant all privileges on database captive to captive; 
grant all privileges on table pass to captive; 
grant all privileges on sequence pass_id_seq to captive;
