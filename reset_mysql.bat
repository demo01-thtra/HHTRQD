@echo off
net stop MySQL96
timeout /t 3
"C:\Program Files\MySQL\MySQL Server 9.6\bin\mysqld.exe" --defaults-file="C:\ProgramData\MySQL\MySQL Server 9.6\my.ini" --skip-grant-tables --init-file="C:\BAITAP\CayQuyetDinh\ck\mysql_init.sql"
