CREATE OR REPLACE FUNCTION rep.fill_bill_table(
    arg_bill integer DEFAULT NULL,
    arg_dir varchar DEFAULT NULL
    )
  RETURNS character varying
AS
$BODY$
DECLARE cmd character varying;
  ret_str VARCHAR := '';
  err_str VARCHAR := '';
  wrk_dir text := '/opt/odf';
  org_cmd text := 'python3 %s/fill_bill.py --pg_host=localhost --pg_user=arc_energo --log_file=%s/fill-bill.log';
BEGIN
    cmd := format(org_cmd,
        wrk_dir, -- script dir
        format('%s/logs', wrk_dir) -- logfile dir
    );

    IF arg_bill IS NOT NULL THEN
        cmd := format('%s --bill_no=%s', cmd, arg_bill);
    END IF;                                                                      

    IF arg_dir IS NOT NULL THEN
        cmd := format('%s --out_dir=%s', cmd, arg_dir);
    END IF;                                                                      

    IF cmd = org_cmd THEN 
       err_str := 'fill_bill_table: argument(s) missed';
       RAISE '%', err_str ; 
    END IF;

    IF cmd IS NULL THEN 
       err_str := 'fill_bill_table cmd IS NULL';
       RAISE '%', err_str ; 
    END IF;

    SELECT * FROM public.exec_shell(cmd) INTO ret_str, err_str ;
    
    IF err_str IS NOT NULL
    THEN 
       RAISE 'fill_bill_table cmd=%^err_str=[%]', cmd, err_str; 
    END IF;
    
    return ret_str;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
