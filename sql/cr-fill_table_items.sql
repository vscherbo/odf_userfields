--
DROP FUNCTION rep.fill_table_items(integer, varchar, varchar);

CREATE OR REPLACE FUNCTION rep.fill_table_items(
    arg_bill integer DEFAULT NULL,
    arg_dir varchar DEFAULT NULL,
    arg_file varchar DEFAULT NULL
    )
  RETURNS character varying
AS
$BODY$
DECLARE cmd character varying;
  loc_res VARCHAR;
  res VARCHAR := '';
  ret_str VARCHAR := '';
  err_str VARCHAR := '';
  wrk_dir text := '/opt/odf';
  org_cmd text := 'python3 %s/fill_table_items.py --pg_host=localhost --pg_user=arc_energo --log_file=%s/fill-bill.log';
  --      org_cmd text := '%s/fill_table_items.py --pg_host=localhost --pg_user=arc_energo --log_file=%s/fill-bill.log';
BEGIN
    RAISE NOTICE 'START rep.fill_table_items billno=%', arg_bill ;
    cmd := format(org_cmd,
        wrk_dir, -- script dir
        format('%s/logs', wrk_dir) -- logfile dir
    );

    IF arg_bill IS NOT NULL THEN
        cmd := format('%s --bill_no=%s --doc_file=%s', cmd, arg_bill, arg_file);
    END IF;                                                                      

    IF arg_dir IS NOT NULL THEN
        cmd := format('%s --out_dir=%s', cmd, arg_dir);
    END IF;                                                                      

    IF cmd = org_cmd THEN
       loc_res := 'fill_table_items: argument(s) missed';
       res := concat_ws(E'/', res, loc_res);
       RAISE NOTICE '%', loc_res ;
    END IF;

    IF cmd IS NULL THEN
       loc_res := 'fill_table_items cmd IS NULL';
       res := concat_ws(E'/', res, loc_res);
       RAISE NOTICE '%', loc_res ;
    END IF;

    if res = '' then -- собранные ошибки
        SELECT * FROM public.exec_shell(cmd) INTO ret_str, err_str ;

        IF err_str IS NOT NULL
        THEN
           res := concat_ws(E'/', res, err_str);
           RAISE NOTICE '%', err_str;
           ret_str := res;
        END IF;
    else
        ret_str := res;
        RAISE NOTICE 'НЕ заполняли таблицу в счёте: res=%', res ;
    end if;

    return ret_str;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
