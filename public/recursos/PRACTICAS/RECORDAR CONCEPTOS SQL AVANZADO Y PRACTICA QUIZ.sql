SELECT DEPARTMENT_ID AS "ID DEPARTAMENTOS", 
        COUNT(*) AS EMPLEADOS
FROM HR.EMPLOYEES
GROUP BY DEPARTMENT_ID
HAVING COUNT(*) > 5;
-- ************************NULL EN LOS JOIN**********************
/*Un NULL no es igual a otro NULL, por lo que normalmente no se une.*/
SELECT  ID_DEPARTMENT
        FIRST_NAME, 
        DEPARTMENT_NAME
FROM HR.EMPLOYEES E
JOIN HR.DEPARTMENTS D
  ON E.DEPARTMENT_ID = D.DEPARTMENT_ID;

-- CON UN JOIN DONDE SE COMPARA UNA COLUMNA CON LAS DOS TABLAS NO MUESTRA EL QUE TENGA NULL
SELECT  EMPLOYEE_ID
        FIRST_NAME, 
        DEPARTMENT_NAME
FROM HR.EMPLOYEES E
JOIN HR.DEPARTMENTS D
  ON E.DEPARTMENT_ID = D.DEPARTMENT_ID
WHERE E.DEPARTMENT_ID IS NULL;

--EN ESTE CASO ES EL ID QUE NO SE MUETRA EN LA PRIMERA CONSULTA 178
SELECT  EMPLOYEE_ID
        FIRST_NAME, 
        DEPARTMENT_NAME
FROM HR.EMPLOYEES E
LEFT JOIN HR.DEPARTMENTS D
  ON E.DEPARTMENT_ID = D.DEPARTMENT_ID
WHERE E.DEPARTMENT_ID IS NULL;

// EN LA MAYORIA DE TODAS LA FUNCIONES IGNORAN LOS NULL EXCEPTO  COUNT QUE CUENTA TODAS LAS FILAS


---OPERADORES DE COMPARACION PARA SUBCONSULTAS IN, EXISTS, ANY, ALL

-- DEVUELVE LOS DEPARTAMENTOS DONDE ALMENOS EXISTA UN EMPLEADO
SELECT DEPARTMENT_ID, 
       DEPARTMENT_NAME
FROM HR.DEPARTMENTS D
WHERE EXISTS (
    SELECT *
    FROM HR.EMPLOYEES E
    WHERE E.DEPARTMENT_ID = D.DEPARTMENT_ID
);
/*
ANY - ALMENOS UNO: COMPARA UN VALOR CON TODOS LOS RESULTADOS DE UNA SUBCONSULTA
Y SI LA CONDICION SE CUMPLE ES VERDADERA PARA CUALQUIERA DE ELLOS
ANY se utiliza para comparar un valor con los resultados que devuelve una subconsulta.
Muestra los empleados cuyo salario es mayor que al menos uno de los salarios de los empleados del departamento 50.
*/

-- NO MUESTRA EL EMPLEDO CON ID 132 
SELECT FIRST_NAME AS NOMBRE,
       LAST_NAME AS APELLIDO,
       SALARY AS SALARIO,
       EMPLOYEE_ID
FROM HR.EMPLOYEES
WHERE SALARY > ANY (
      SELECT SALARY
      FROM HR.EMPLOYEES
      WHERE DEPARTMENT_ID = 50
)
ORDER BY EMPLOYEE_ID ASC;

SELECT EMPLOYEE_ID,
       FIRST_NAME,
       SALARY
FROM HR.EMPLOYEES
WHERE DEPARTMENT_ID = 50
ORDER BY SALARY ASC;

/*
ALL → COMPARACION TIENE QUE CUMPLIR CON TODOS.
La subconsulta obtiene todos los salarios del departamento 50. Luego salary > ALL significa:
El salario debe ser mayor que todos los salarios de ese departamento.
*/
SELECT FIRST_NAME AS NOMBRE,
       LAST_NAME AS APELLIDO,
       SALARY AS SALARIO
FROM HR.EMPLOYEES
WHERE SALARY > ALL (
    SELECT SALARY
    FROM HR.EMPLOYEES
    WHERE DEPARTMENT_ID = 50
);


/*
Las subconsultas son consultas dentro de otra consulta. Se clasifican según la cantidad de datos que devuelven: un valor, una lista de valores o una tabla completa.
*/
-- Subconsulta escalar (devuelve un solo valor)
SELECT FIRST_NAME,
       SALARY
FROM HR.EMPLOYEES
WHERE SALARY > (
    SELECT AVG(SALARY)
    FROM HR.EMPLOYEES
);
--Subconsulta de lista (devuelve varios valores)

SELECT first_name
FROM employees
WHERE department_id IN (
    SELECT department_id
    FROM HR.departments
    WHERE location_id = 1700
);

-- Tabla derivada (devuelve una tabla)
SELECT departamento, promedio
FROM (
    SELECT department_id AS departamento,
           ROUND(AVG(salary), 0) AS promedio
    FROM HR.employees
    GROUP BY department_id
) T
WHERE promedio > 8000;

/* PROBLEMA CON EL NULL EN EL NOT IN 
SELECT first_name
FROM employees
WHERE department_id NOT IN (
    SELECT department_id
    FROM departments
);

Si la subconsulta devuelve un null ejemplo o en escencia: department_id NOT IN (10, 20, NULL)
NULL significa "desconocido", SQL no puede asegurar que un valor sea distinto de NULL
la comparación resulta desconocida y no devuelve filas.

solucion
SELECT first_name
FROM employees
WHERE department_id NOT IN (
    SELECT department_id
    FROM departments
    WHERE department_id IS NOT NULL
);
*/

--Operaciones de conjuntos combinar o comparar los resultados de dos consultas SELECT.

--UNION Une resultados y elimina duplicados
SELECT first_name FROM HR.employees WHERE department_id = 10
UNION
SELECT first_name FROM HR.employees WHERE department_id = 20;

-- UNION ALL no elimina duplicados
SELECT first_name FROM HR.employees WHERE department_id = 10
UNION ALL
SELECT first_name FROM HR.employees WHERE department_id = 20;

--INTERSECT Muestra únicamente los datos que aparecen en ambas consultas.
SELECT employee_id FROM HR.job_history
INTERSECT
SELECT employee_id FROM HR.employees;

--MINUS Muestra los registros de la primera consulta que no aparecen en la segunda.
SELECT employee_id FROM HR.employees
MINUS
SELECT employee_id FROM HR.job_history;

--CTE TABLA TEMPORAL CON NOMBRE QUE EXITE DURANTE UNA CONSULTA
-- SIN CTE
SELECT department_id, promedio
FROM (
    SELECT department_id,
           AVG(salary) AS promedio
    FROM HR.employees
    GROUP BY department_id
)
WHERE promedio > 8000;
-- CON CTE ES MAS LEGIBLE 
WITH PROMEDIO_DEPARTAMENTOS AS (
    SELECT DEPARTMENT_ID,
           AVG(SALARY) AS PROMEDIO
    FROM HR.EMPLOYEES
    GROUP BY DEPARTMENT_ID
)
SELECT DEPARTMENT_ID, PROMEDIO
FROM PROMEDIO_DEPARTAMENTOS
WHERE PROMEDIO > 8000;

--CTE para reutilización - usar la misma CTE varias veces sin repetir la consulta.
WITH SALARIOS AS (
    SELECT DEPARTMENT_ID,
           AVG(SALARY) AS PROMEDIO
    FROM HR.EMPLOYEES
    GROUP BY DEPARTMENT_ID
)
SELECT *
FROM SALARIOS
WHERE PROMEDIO > 6000;

--CTE encadenadas rear varias CTE, donde una utiliza la anterior.
WITH PROMEDIOS AS (
    SELECT DEPARTMENT_ID,
           AVG(SALARY) AS PROMEDIO
    FROM HR.EMPLOYEES
    GROUP BY DEPARTMENT_ID
),
DEPARTAMENTOS_ALTOS AS (
    SELECT *
    FROM PROMEDIOS
    WHERE PROMEDIO > 8000
)
SELECT *
FROM DEPARTAMENTOS_ALTOS;

--CTE RECURSIVAS
/*
Empieza por un empleado y después busca sus subordinados, luego los subordinados de esos subordinados, etc.
para este tipo de jerarquías normalmente se utiliza la sintaxis propia de Oracle con CONNECT BY, que es la forma clásica de recorrer jerarquías.
*/
SELECT EMPLOYEE_ID,
       FIRST_NAME,
       MANAGER_ID,
       LEVEL
FROM HR.EMPLOYEES
START WITH MANAGER_ID IS NULL
CONNECT BY PRIOR EMPLOYEE_ID = MANAGER_ID;

--START WITH MANAGER_ID IS NULL --- Empieza por los empleados que no tienen jefe
--CONNECT BY PRIOR EMPLOYEE_ID = MANAGER_ID --- Busca empleados cuyo MANAGER_ID sea el EMPLOYEE_ID del empleado anterior.

--********************Funciones analíticas o de ventana***************************************
/*
Las funciones de ventana calculan algo sobre un grupo de filas, pero SIN eliminar las filas originales.
*/
-- OVER  convierte una función en una función de ventana.
SELECT FIRST_NAME,
       SALARY,
       AVG(SALARY) OVER() AS PROMEDIO_GENERAL
FROM HR.EMPLOYEES;

--PARTITION BY permite dividir las filas en grupos, pero sin eliminar las filas.
SELECT FIRST_NAME,
       DEPARTMENT_ID,
       SALARY,
       AVG(SALARY) OVER(
           PARTITION BY DEPARTMENT_ID
       ) AS PROMEDIO_DEPARTAMENTO
FROM HR.EMPLOYEES;

--ORDER BY Dentro de OVER() puedes utilizar ORDER BY para establecer un orden.

SELECT FIRST_NAME,
       SALARY,
       RANK() OVER(
           ORDER BY SALARY DESC
       ) AS POSICION
FROM HR.EMPLOYEES;
--ROW_NUMBER() Da un número único a cada fila.
SELECT FIRST_NAME,
       SALARY,
       ROW_NUMBER() OVER (ORDER BY SALARY DESC) AS POSICION
FROM HR.EMPLOYEES;

-- RANK()hay empate, es da la misma posición, pero deja un salto.

SELECT FIRST_NAME,
       SALARY,
       RANK() OVER (ORDER BY SALARY DESC) AS POSICION
FROM HR.EMPLOYEES;

--DENSE_RANK() También pone la misma posición en los empates, pero no deja saltos.
SELECT FIRST_NAME,
       SALARY,
       DENSE_RANK() OVER (ORDER BY SALARY DESC) AS POSICION
FROM HR.EMPLOYEES;

--LAG()permite mirar una fila anterior.
SELECT FIRST_NAME,
       SALARY,
       LAG(SALARY) OVER (ORDER BY SALARY) AS SALARIO_ANTERIOR
FROM HR.EMPLOYEES;

--LEAD()mira una fila siguiente.
SELECT FIRST_NAME,
       SALARY,
       LEAD(SALARY) OVER (ORDER BY SALARY) AS SALARIO_SIGUIENTE
FROM HR.EMPLOYEES;

--SUM()OVER() podemos hacer una suma acumulada:
SELECT FIRST_NAME,
       SALARY,
       SUM(SALARY) OVER (ORDER BY SALARY) AS SUMA_ACUMULADA
FROM HR.EMPLOYEES;