/* ============================================================
   LABORATORIO: HISTOGRAMAS EN ORACLE 19c
   OBJETIVO: ejecutar y observar. El estudiante NO necesita
   modificar este script.

   Basado en las diapositivas del laboratorio:
   - Creacion automatica con SIZE AUTO
   - Frequency
   - Top-Frequency
   - Height-Balanced (legacy)
   - Hybrid
   - Verificacion en USER_TAB_COL_STATISTICS y USER_HISTOGRAMS
   - Lectura de ENDPOINT_NUMBER / ENDPOINT_VALUE /
     ENDPOINT_REPEAT_COUNT
   ============================================================ */

SET LINESIZE 180
SET PAGESIZE 100
SET VERIFY OFF
SET FEEDBACK ON

COLUMN table_name              FORMAT A14
COLUMN column_name             FORMAT A24
COLUMN histogram               FORMAT A16
COLUMN endpoint_value          FORMAT 999999
COLUMN endpoint_number         FORMAT 999999
COLUMN endpoint_repeat_count  FORMAT 999999
COLUMN frecuencia              FORMAT 999999
COLUMN porcentaje              FORMAT 990.00

PROMPT ============================================================
PROMPT PARTE 0 - PREPARACION
PROMPT ============================================================


BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE lab_countries PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE lab_products PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE lab_countries (
  country_subregion_id NUMBER NOT NULL
);

INSERT INTO lab_countries SELECT 52792 FROM dual CONNECT BY LEVEL <= 1;
INSERT INTO lab_countries SELECT 52793 FROM dual CONNECT BY LEVEL <= 5;
INSERT INTO lab_countries SELECT 52794 FROM dual CONNECT BY LEVEL <= 2;
INSERT INTO lab_countries SELECT 52795 FROM dual CONNECT BY LEVEL <= 1;
INSERT INTO lab_countries SELECT 52796 FROM dual CONNECT BY LEVEL <= 1;
INSERT INTO lab_countries SELECT 52797 FROM dual CONNECT BY LEVEL <= 2;
INSERT INTO lab_countries SELECT 52798 FROM dual CONNECT BY LEVEL <= 2;
INSERT INTO lab_countries SELECT 52799 FROM dual CONNECT BY LEVEL <= 9;
COMMIT;

CREATE TABLE lab_products (
  prod_subcategory_id NUMBER NOT NULL
);

INSERT INTO lab_products SELECT 2011 FROM dual CONNECT BY LEVEL <= 1;
INSERT INTO lab_products SELECT 2012 FROM dual CONNECT BY LEVEL <= 2;
INSERT INTO lab_products SELECT 2013 FROM dual CONNECT BY LEVEL <= 2;
INSERT INTO lab_products SELECT 2014 FROM dual CONNECT BY LEVEL <= 8;
INSERT INTO lab_products SELECT 2021 FROM dual CONNECT BY LEVEL <= 1;
INSERT INTO lab_products SELECT 2022 FROM dual CONNECT BY LEVEL <= 1;
INSERT INTO lab_products SELECT 2031 FROM dual CONNECT BY LEVEL <= 5;
INSERT INTO lab_products SELECT 2032 FROM dual CONNECT BY LEVEL <= 6;
INSERT INTO lab_products SELECT 2033 FROM dual CONNECT BY LEVEL <= 2;
INSERT INTO lab_products SELECT 2034 FROM dual CONNECT BY LEVEL <= 2;
INSERT INTO lab_products SELECT 2035 FROM dual CONNECT BY LEVEL <= 2;
INSERT INTO lab_products SELECT 2036 FROM dual CONNECT BY LEVEL <= 4;
INSERT INTO lab_products SELECT 2041 FROM dual CONNECT BY LEVEL <= 1;
INSERT INTO lab_products SELECT 2042 FROM dual CONNECT BY LEVEL <= 5;
INSERT INTO lab_products SELECT 2043 FROM dual CONNECT BY LEVEL <= 3;
INSERT INTO lab_products SELECT 2044 FROM dual CONNECT BY LEVEL <= 1;
INSERT INTO lab_products SELECT 2051 FROM dual CONNECT BY LEVEL <= 5;
INSERT INTO lab_products SELECT 2052 FROM dual CONNECT BY LEVEL <= 1;
INSERT INTO lab_products SELECT 2053 FROM dual CONNECT BY LEVEL <= 2;
INSERT INTO lab_products SELECT 2054 FROM dual CONNECT BY LEVEL <= 6;
INSERT INTO lab_products SELECT 2055 FROM dual CONNECT BY LEVEL <= 7;
INSERT INTO lab_products SELECT 2056 FROM dual CONNECT BY LEVEL <= 5;
COMMIT;

PROMPT Distribucion real de LAB_COUNTRIES
SELECT country_subregion_id, COUNT(*) AS frecuencia
FROM lab_countries
GROUP BY country_subregion_id
ORDER BY country_subregion_id;

PROMPT Distribucion real de LAB_PRODUCTS
SELECT prod_subcategory_id, COUNT(*) AS frecuencia
FROM lab_products
GROUP BY prod_subcategory_id
ORDER BY prod_subcategory_id;

PROMPT ============================================================
PROMPT PARTE 1 - PUNTO DE PARTIDA: GATHER SIN USO DE PREDICADO
PROMPT ============================================================

/*
   El objetivo didactico es comprobar el flujo mostrado en las
   diapositivas: primero se recopilan estadisticas sin uso previo
   de la columna y se observa HISTOGRAM = NONE.
*/

BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(
    ownname    => USER,
    tabname    => 'LAB_COUNTRIES',
    method_opt => 'FOR ALL COLUMNS SIZE AUTO'
  );
END;
/

SELECT table_name, column_name, num_distinct, histogram
FROM user_tab_col_statistics
WHERE table_name = 'LAB_COUNTRIES'
  AND column_name = 'COUNTRY_SUBREGION_ID';

PROMPT ============================================================
PROMPT PARTE 2 - CREACION AUTOMATICA CON SIZE AUTO
PROMPT ============================================================

/* Limpiamos la estadistica de la columna para repetir el flujo. */
BEGIN
  DBMS_STATS.DELETE_COLUMN_STATS(
    ownname => USER,
    tabname => 'LAB_COUNTRIES',
    colname => 'COUNTRY_SUBREGION_ID'
  );
END;
/

PROMPT 1) Primer GATHER: la columna aun no ha sido usada en un predicado
BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(
    ownname    => USER,
    tabname    => 'LAB_COUNTRIES',
    method_opt => 'FOR COLUMNS COUNTRY_SUBREGION_ID SIZE AUTO'
  );
END;
/

SELECT column_name, histogram
FROM user_tab_col_statistics
WHERE table_name = 'LAB_COUNTRIES'
  AND column_name = 'COUNTRY_SUBREGION_ID';

PROMPT 2) Consulta que usa la columna en un predicado
SELECT COUNT(*) AS filas_encontradas
FROM lab_countries
WHERE country_subregion_id = 52799;

PROMPT 3) Segundo GATHER: Oracle puede aprovechar el uso registrado
BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(
    ownname    => USER,
    tabname    => 'LAB_COUNTRIES',
    method_opt => 'FOR COLUMNS COUNTRY_SUBREGION_ID SIZE AUTO'
  );
END;
/

SELECT table_name, column_name, num_distinct, histogram
FROM user_tab_col_statistics
WHERE table_name = 'LAB_COUNTRIES'
  AND column_name = 'COUNTRY_SUBREGION_ID';

PROMPT ============================================================
PROMPT PARTE 3 - FREQUENCY HISTOGRAM
PROMPT ============================================================

/*
   8 valores distintos <= 254 buckets.
   ENDPOINT_NUMBER representa frecuencia acumulada.
*/

BEGIN
  DBMS_STATS.DELETE_COLUMN_STATS(
    ownname => USER,
    tabname => 'LAB_COUNTRIES',
    colname => 'COUNTRY_SUBREGION_ID'
  );
END;
/

BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(
    ownname    => USER,
    tabname    => 'LAB_COUNTRIES',
    method_opt => 'FOR COLUMNS COUNTRY_SUBREGION_ID SIZE 254'
  );
END;
/

PROMPT Tipo de histograma creado
SELECT table_name, column_name, num_distinct, histogram
FROM user_tab_col_statistics
WHERE table_name = 'LAB_COUNTRIES'
  AND column_name = 'COUNTRY_SUBREGION_ID';

PROMPT Endpoints almacenados
SELECT endpoint_number, endpoint_value
FROM user_histograms
WHERE table_name = 'LAB_COUNTRIES'
  AND column_name = 'COUNTRY_SUBREGION_ID'
ORDER BY endpoint_number;

PROMPT Distribucion interpretada: diferencia entre endpoints = frecuencia del valor
SELECT endpoint_number,
       endpoint_value,
       endpoint_number -
         LAG(endpoint_number, 1, 0) OVER (ORDER BY endpoint_number) AS frecuencia,
       ROUND(
         100 * (endpoint_number -
                LAG(endpoint_number, 1, 0) OVER (ORDER BY endpoint_number))
         / MAX(endpoint_number) OVER (),
         2
       ) AS porcentaje
FROM user_histograms
WHERE table_name = 'LAB_COUNTRIES'
  AND column_name = 'COUNTRY_SUBREGION_ID'
ORDER BY endpoint_number;

PROMPT Comparacion contra la distribucion real
SELECT country_subregion_id, COUNT(*) AS frecuencia
FROM lab_countries
GROUP BY country_subregion_id
ORDER BY country_subregion_id;

PROMPT ============================================================
PROMPT PARTE 4 - TOP-FREQUENCY HISTOGRAM
PROMPT ============================================================

/*
   8 valores distintos y 7 buckets.
   Con AUTO_SAMPLE_SIZE, el top de valores concentra suficiente
   porcentaje de las filas para que Oracle pueda usar Top-Frequency.
*/

BEGIN
  DBMS_STATS.DELETE_COLUMN_STATS(
    ownname => USER,
    tabname => 'LAB_COUNTRIES',
    colname => 'COUNTRY_SUBREGION_ID'
  );
END;
/

BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(
    ownname    => USER,
    tabname    => 'LAB_COUNTRIES',
    method_opt => 'FOR COLUMNS COUNTRY_SUBREGION_ID SIZE 7',
    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE
  );
END;
/

PROMPT Tipo de histograma creado
SELECT table_name, column_name, num_distinct, histogram
FROM user_tab_col_statistics
WHERE table_name = 'LAB_COUNTRIES'
  AND column_name = 'COUNTRY_SUBREGION_ID';

PROMPT Endpoints almacenados
SELECT endpoint_number, endpoint_value
FROM user_histograms
WHERE table_name = 'LAB_COUNTRIES'
  AND column_name = 'COUNTRY_SUBREGION_ID'
ORDER BY endpoint_number;

PROMPT Distribucion real para identificar el valor excluido
SELECT country_subregion_id, COUNT(*) AS frecuencia
FROM lab_countries
GROUP BY country_subregion_id
ORDER BY frecuencia DESC, country_subregion_id;

PROMPT ============================================================
PROMPT PARTE 5 - HEIGHT-BALANCED HISTOGRAM (LEGACY)
PROMPT ============================================================

/*
   Mismos 7 buckets, pero estimate_percent explicito.
   Esto fuerza el camino legacy mostrado en las diapositivas.
   Aqui ENDPOINT_NUMBER NO debe interpretarse como frecuencia
   acumulada.
*/

BEGIN
  DBMS_STATS.DELETE_COLUMN_STATS(
    ownname => USER,
    tabname => 'LAB_COUNTRIES',
    colname => 'COUNTRY_SUBREGION_ID'
  );
END;
/

BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(
    ownname          => USER,
    tabname          => 'LAB_COUNTRIES',
    method_opt       => 'FOR COLUMNS COUNTRY_SUBREGION_ID SIZE 7',
    estimate_percent => 100
  );
END;
/

PROMPT Tipo de histograma creado
SELECT table_name, column_name, num_distinct, histogram
FROM user_tab_col_statistics
WHERE table_name = 'LAB_COUNTRIES'
  AND column_name = 'COUNTRY_SUBREGION_ID';

PROMPT Endpoints: aqui endpoint_number es numero/posicion del bucket
SELECT endpoint_number, endpoint_value
FROM user_histograms
WHERE table_name = 'LAB_COUNTRIES'
  AND column_name = 'COUNTRY_SUBREGION_ID'
ORDER BY endpoint_number;

PROMPT Distribucion real para interpretar los limites de los buckets
SELECT country_subregion_id, COUNT(*) AS frecuencia
FROM lab_countries
GROUP BY country_subregion_id
ORDER BY country_subregion_id;

PROMPT ============================================================
PROMPT PARTE 6 - HYBRID HISTOGRAM
PROMPT ============================================================

/*
   LAB_PRODUCTS: 72 filas, 22 valores distintos, 10 buckets.
   Con AUTO_SAMPLE_SIZE, el top de valores no alcanza el umbral
   necesario para Top-Frequency; Oracle puede usar Hybrid.
*/

BEGIN
  DBMS_STATS.DELETE_COLUMN_STATS(
    ownname => USER,
    tabname => 'LAB_PRODUCTS',
    colname => 'PROD_SUBCATEGORY_ID'
  );
END;
/

BEGIN
  DBMS_STATS.GATHER_TABLE_STATS(
    ownname          => USER,
    tabname          => 'LAB_PRODUCTS',
    method_opt       => 'FOR COLUMNS PROD_SUBCATEGORY_ID SIZE 10',
    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE
  );
END;
/

PROMPT Tipo de histograma creado
SELECT table_name, column_name, num_distinct, histogram
FROM user_tab_col_statistics
WHERE table_name = 'LAB_PRODUCTS'
  AND column_name = 'PROD_SUBCATEGORY_ID';

PROMPT Endpoints y endpoint_repeat_count
SELECT endpoint_number,
       endpoint_value,
       endpoint_repeat_count
FROM user_histograms
WHERE table_name = 'LAB_PRODUCTS'
  AND column_name = 'PROD_SUBCATEGORY_ID'
ORDER BY endpoint_number;

PROMPT Distribucion real
SELECT prod_subcategory_id, COUNT(*) AS frecuencia
FROM lab_products
GROUP BY prod_subcategory_id
ORDER BY prod_subcategory_id;

PROMPT Valores mas repetidos: comparar con endpoint_repeat_count
SELECT prod_subcategory_id, COUNT(*) AS frecuencia
FROM lab_products
GROUP BY prod_subcategory_id
ORDER BY frecuencia DESC, prod_subcategory_id;

PROMPT ============================================================
PROMPT PARTE 7 - RESUMEN AUTOMATICO DE LOS RESULTADOS
PROMPT ============================================================

/*
   Esta salida final permite al alumno verificar de una sola vez
   el tipo de histograma obtenido en cada escenario.
*/

SELECT table_name,
       column_name,
       num_distinct,
       histogram
FROM user_tab_col_statistics
WHERE (table_name = 'LAB_COUNTRIES' AND column_name = 'COUNTRY_SUBREGION_ID')
   OR (table_name = 'LAB_PRODUCTS'  AND column_name = 'PROD_SUBCATEGORY_ID')
ORDER BY table_name, column_name;

PROMPT ============================================================
PROMPT FIN DEL LABORATORIO
PROMPT ============================================================
PROMPT No es necesario modificar este script para realizar la practica.
PROMPT Ejecute el laboratorio y compare cada resultado con las diapositivas.
PROMPT ============================================================

/* ============================================================
   PARTE 8 - LIMPIEZA OPCIONAL
   Descomentar SOLO si se quiere borrar las tablas al terminar.
   ============================================================

DROP TABLE lab_countries PURGE;
DROP TABLE lab_products PURGE;
*/
