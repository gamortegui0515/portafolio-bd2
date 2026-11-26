-- cursor. 

-- dias de diferencias de dos fechas fn_dias_entre_fechas
-- PARAMETROS PARAM_NOMBRE FECHA INICIAL FECHA FINAL

CREATE FUNCTION fn_dias_entre_fechas (
    param_fecha_inicial IN DATE,
    param_fecha_final IN DATE)
RETURN NUMBER 
IS
    vn_dias NUMBER;
BEGIN
    vn_dias := TRUNC(param_fecha_final) - TRUNC(param_fecha_inicial);
     DBMS_OUTPUT.PUT_LINE('La diferencia exacta es de: ' || vn_dias || ' días.');
    RETURN vn_dias;
END;

SELECT *
FROM fn_dias_entre_fechas;