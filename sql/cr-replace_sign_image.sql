-- DROP FUNCTION rep.replace_sign_image(text, text, text);

CREATE OR REPLACE FUNCTION rep.replace_sign_image(arg_doc_file text, arg_img_file text, arg_img_name text)
  RETURNS character varying AS
$BODY$
DECLARE
loc_res varchar;
out_path varchar;
img_path varchar;
BEGIN

img_path := arc_const('doc_templ_dir');
IF img_path IS NULL THEN
    loc_res := 'не задан в arc_constants каталог для шаблонов';
    RAISE NOTICE '%', loc_res;
END IF;

out_path := arc_const('doc_out_dir');
IF out_path IS NULL THEN
    loc_res := 'не задан в arc_constants каталог для документов';
    RAISE NOTICE '%', loc_res;
END IF;

IF loc_res IS NULL THEN -- no problem, go ahead
    img_path := format('%s/%s', img_path, arg_img_file);
    out_path := format('%s/%s', out_path, arg_doc_file);
    loc_res := rep.replace_image_common(out_path, img_path, arg_img_name);
END IF;

return loc_res;
END;
$BODY$
LANGUAGE plpgsql;

ALTER FUNCTION rep.replace_sign_image(text, text, text) OWNER TO arc_energo;
