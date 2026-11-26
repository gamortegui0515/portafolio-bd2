SET SERVEROUTPUT ON;

BEGIN --EJECUTURÁ COMO UN SOLO PROCESO
DBMS_OUTPUT.PUT_LINE('Hola mundo');
--PAQUETE--|---PROCEDIMIENTO ALMACENADO O FUNCION PS----| () --->PARAMETRO
END;

-- CONSULTAR LOS PAQUETES PL SQL.

DECLARE
    fecha timestamp;
BEGIN
    SELECT sysdate INTO fecha FROM dual;
    DBMS_OUTPUT.PUT_LINE('La fecha es.' || fecha);
END;

DECLARE
    primerNombre VARCHAR2(20);
    segundoNombre VARCHAR(20);
    primerApellido VARCHAR2(20);
    segundoApellido VARCHAR2(20);
BEGIN
    SELECT 'Gabriel', 'Santiago', 'Amortegui', 'Hernandez'
    INTO primerNombre, segundoNombre, primerApellido, segundoApellido
    FROM DUAL;
    
    DBMS_OUTPUT.PUT_LINE('Mi nombre es: ' || primerNombre ||' '|| segundoNombre ||' '|| primerApellido ||' '|| segundoApellido);
END;

DECLARE
    vvPrimerNombre VARCHAR2(50);
    vvApellido VARCHAR2(50);
    vnSalario NUMBER;
    vdFechaContratacion DATE;
BEGIN
SELECT FIRST_NAME,
       LAST_NAME,
       SALARY,
       HIRE_DATE
    INTO vvPrimerNombre,
         vvApellido,
         vnSalario,
         vdFechaContratacion
FROM HR.EMPLOYEES
WHERE EMPLOYEE_ID = 100;

 DBMS_OUTPUT.PUT_LINE('Los datos del Empleado son: Nombre: ' || vvPrimerNombre || ', Apellido: ' || vvApellido || ', su Salario es: ' 
 || vnSalario || ' y su Fecha de contratación es: ' || TO_CHAR(vdFechaContratacion, 'DD/MM/YYYY'));
END;

-- %TYPE RECOMENDADO PARA POCAS COLUMNAS
DECLARE
    vvPrimerNombre HR.EMPLOYEES.FIRST_NAME%TYPE;
    vvApellido HR.EMPLOYEES.LAST_NAME%TYPE;
    vnSalario HR.EMPLOYEES.SALARY%TYPE;
    vdFechaContratacion HR.EMPLOYEES.HIRE_DATE%TYPE;
BEGIN
SELECT FIRST_NAME,
       LAST_NAME,
       SALARY,
       HIRE_DATE
    INTO vvPrimerNombre,
         vvApellido,
         vnSalario,
         vdFechaContratacion
FROM HR.EMPLOYEES
WHERE EMPLOYEE_ID = 100;

 DBMS_OUTPUT.PUT_LINE('Los datos del Empleado son: Nombre: ' || vvPrimerNombre || ', Apellido: ' || vvApellido || ', su Salario es: ' 
 || vnSalario || ' y su Fecha de contratación es: ' || TO_CHAR(vdFechaContratacion, 'DD/MM/YYYY'));
END;

-- %ROWTYPE LEE TODAS EL TIPO DE LAS COLUMNAS DE LA FILA -- mirar porque el script de abajo no funciona.
DECLARE
vtEmpleado HR.EMPLOYEES%ROWTYPE;
BEGIN
SELECT FIRST_NAME,
       LAST_NAME,
       SALARY,
       HIRE_DATE
    INTO vtEmpleado 
FROM HR.EMPLOYEES
WHERE EMPLOYEE_ID = 100;

   DBMS_OUTPUT.PUT_LINE('Los datos del Empleado son: Nombre: ' || vrEmpleado.FIRST_NAME || ', Apellido: ' || vrEmpleado.LAST_NAME || ', su Salario es: ' || vrEmpleado.SALARY || ' y su Fecha de contratación es: '
   || TO_CHAR(vrEmpleado.HIRE_DATE, 'DD/MM/YYYY'));
END;

/*
Autor: Gabriel Santiago Amortegui
Fecha: 21/09/2026
Descripción: Este script funciona para x y y.

20260922 - Se ajustó el script para y y x.

*/
