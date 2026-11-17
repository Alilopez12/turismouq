@echo off
set ORACLE_HOME=C:\app\DELL\product\21c\dbhomeXE
set PATH=%ORACLE_HOME%\bin;%PATH%
set NLS_LANG=AMERICAN_AMERICA.AL32UTF8
echo SELECT USER FROM DUAL; | sqlplus -L TURISMO_UQ/"Turismo2026#"@//localhost:1521/XEPDB1
