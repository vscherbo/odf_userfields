-- DROP FUNCTION rep.is_qr_enabled(int4);

CREATE OR REPLACE FUNCTION rep.is_qr_enabled(arg_bill_no integer)
 RETURNS boolean
 LANGUAGE plpgsql
AS $function$
DECLARE
loc_manual_qr boolean;
loc_bx_qr boolean;
BEGIN
PERFORM 1
FROM bx_order bo
JOIN bx_order_feature bof ON bo."Номер" = bof."bx_order_Номер" AND bof.fname = 'Метод оплаты' AND bof.fvalue = 'Оплата через СБП'
WHERE bo.Счет = arg_bill_no;

loc_bx_qr := FOUND;
RAISE NOTICE 'is_qr_enabled: Оплата через СБП loc_bx_qr=%', loc_bx_qr;

PERFORM 1 FROM "Счета" b
WHERE b."№ счета" = arg_bill_no AND ps_id=7 ;
loc_manual_qr := FOUND;
RAISE NOTICE 'is_qr_enabled: loc_manual_qr=%', loc_manual_qr;

RETURN (loc_bx_qr OR loc_manual_qr) AND (arc_const('qr_enabled') = 'Y');
END;
$function$
;

-- Permissions

ALTER FUNCTION rep.is_qr_enabled(int4) OWNER TO arc_energo;
GRANT ALL ON FUNCTION rep.is_qr_enabled(int4) TO public;
GRANT ALL ON FUNCTION rep.is_qr_enabled(int4) TO arc_energo;
