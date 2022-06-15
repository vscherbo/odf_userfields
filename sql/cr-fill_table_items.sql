-- DROP FUNCTION rep.fill_table_items(integer, varchar, varchar);

CREATE OR REPLACE FUNCTION rep.fill_table_items(
    arg_bill integer DEFAULT NULL,
    arg_dir varchar DEFAULT NULL,
    arg_file varchar DEFAULT NULL
    )
  RETURNS character varying
AS
$BODY$
DECLARE cmd character varying;
  ret_str VARCHAR := '';
  err_str VARCHAR := '';
  wrk_dir text := '/opt/odf';
  org_cmd text := 'python3 %s/fill_table_items.py --pg_host=localhost --pg_user=arc_energo --log_file=%s/fill-bill.log';
BEGIN
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
       err_str := 'fill_table_items: argument(s) missed';
       RAISE '%', err_str ; 
    END IF;

    IF cmd IS NULL THEN 
       err_str := 'fill_table_items cmd IS NULL';
       RAISE '%', err_str ; 
    END IF;

    SELECT * FROM public.exec_shell(cmd) INTO ret_str, err_str ;
    
    IF err_str IS NOT NULL
    THEN 
       RAISE 'fill_table_items cmd=%^err_str=[%]', cmd, err_str; 
    END IF;
    
    return ret_str;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
