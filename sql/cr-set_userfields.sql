-- DROP FUNCTION rep.set_userfields(text, text, text);

CREATE OR REPLACE FUNCTION rep.set_userfields(arg_templ text, arg_outfile text, arg_sql text)
  RETURNS character varying AS
$BODY$
DECLARE
templ_path varchar;
out_path varchar;
loc_res varchar;
BEGIN

templ_path := arc_const('doc_templ_dir');
IF templ_path IS NULL THEN
    loc_res := 'не задан в arc_constants каталог для шаблонов';
    RAISE NOTICE '%', loc_res;
END IF;

out_path := arc_const('doc_out_dir');
IF out_path IS NULL THEN
    loc_res := 'не задан в arc_constants каталог для документов';
    RAISE NOTICE '%', loc_res;
END IF;

IF loc_res IS NULL THEN -- no problem, go ahead
    templ_path := format('%s/%s', templ_path, arg_templ);
    out_path := format('%s/%s', out_path, arg_outfile);
    loc_res := rep.set_userfields_common(templ_path, out_path, arg_sql);
END IF;

return loc_res;

END;
$BODY$
LANGUAGE plpgsql;

ALTER FUNCTION rep.set_userfields(text, text, text) OWNER TO arc_energo;

