-- DROP FUNCTION rep.is_qr_enabled(int4);

CREATE OR REPLACE FUNCTION rep.is_qr_enabled(arg_bill_no integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
BEGIN
-- SELECT TRUE ;
PERFORM 1
FROM bx_order bo
JOIN bx_order_feature bof ON bo."Номер" = bof."bx_order_Номер" AND bof.fname = 'Метод оплаты' AND bof.fvalue = 'Оплата через СБП'
WHERE bo.Счет = arg_bill_no;

RAISE NOTICE 'found=%', FOUND;

RETURN FOUND AND (arc_const('qr_enabled') = 'Y');
END;
$function$
;

-- Permissions

ALTER FUNCTION rep.is_qr_enabled(int4) OWNER TO arc_energo;
GRANT ALL ON FUNCTION rep.is_qr_enabled(int4) TO public;
GRANT ALL ON FUNCTION rep.is_qr_enabled(int4) TO arc_energo;
