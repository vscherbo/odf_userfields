CREATE FUNCTION arc_energo.bill_total_pos(arc_energo."Счета") RETURNS bigint
    LANGUAGE sql
    AS $_$
    SELECT count(1) FROM "Содержание счета" WHERE $1."№ счета" = "Содержание счета"."№ счета";
$_$;
