SELECT SYS_CONTEXT('USERENV','SID') FROM dual -- Da variables del entorno del usuario como ip, etc. Opciones del syscontext.
-- tcl comando rollback, comit, safepoint.
/* Transacciones o relacionales: principio acid.  - Base: El resto que no es acid.
ACID
Atocimidad: Son todos los pasos o no pasa ninguno.
Consistencia: Estado de bases de datos sea valido. De valido a valido.
Aislamiento: Cada transaccion se trabajan de forma aislada o independiente.
Durabilidad: Los datos sean persistentes en el tiempo.

Aislamiento es el unico principio que puede controlarse los demas se encarga el motor.

NOTA REGLA: En una trasaccion con scripts DML si se ejecuta un script DDL - genera un comit implicito.
COMMIT - Confirma la trasaccion.
ROLLBACK - Deshace los cambios de todos los procesos de la trasaccion. Demora en ejecutarse mas que la confirmacion de la transaccion.
SAFEPONT - Guarda hasta cierto punto los pasos de la transaccion. Evita deshacer todos los pasos haciendo un ROLLBACK con el SAFEPOINT hasta el punto establecido.

ORACLE tiene papelera de reciclaje. guarda los datos anteriores por poco tiempo.
*/

