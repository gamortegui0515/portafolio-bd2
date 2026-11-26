
SET SERVEROUTPUT ON;
DECLARE
    CURSOR cur_empleados (p_id_departamento NUMBER) IS
    SELECT E.FIRST_NAME AS nombre_emp, 
           M.FIRST_NAME AS nombre_jefe,
           E.SALARY     AS salario,
           E.COMMISSION_PCT AS comision,
           (E.SALARY + (E.SALARY * NVL(E.COMMISSION_PCT, 0))) AS salario_con_comision
    FROM HR.EMPLOYEES E
    INNER JOIN HR.EMPLOYEES M ON E.MANAGER_ID = M.EMPLOYEE_ID 
    WHERE E.DEPARTMENT_ID = p_id_departamento; 
    
    vn_emp cur_empleados%ROWTYPE;
BEGIN 
    OPEN cur_empleados(80);
    
    LOOP 
        FETCH cur_empleados INTO vn_emp;
        EXIT WHEN cur_empleados%NOTFOUND; 
        
       
        DBMS_OUTPUT.PUT_LINE(
            'Empleado: '   || vn_emp.nombre_emp || ' | ' ||
            'Jefe: '       || NVL(vn_emp.nombre_jefe, 'Sin jefe') || ' | ' ||
            'Salario: '    || vn_emp.salario || ' | ' ||
            'Comisión: '   || NVL(TO_CHAR(vn_emp.comision), '0') || ' | ' ||
            'Total: '      || vn_emp.salario_con_comision
        );
    
    END LOOP;
    
    CLOSE cur_empleados; 
END;
/
