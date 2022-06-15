CREATE OR REPLACE FUNCTION rep.bill_fax_odf(arg_bill_no integer)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$                                                                           
DECLARE
res varchar := '';
loc_res varchar;
out_dir varchar;
templ_dir varchar;
out_file varchar;
bill_logo_file varchar;
our_firm varchar;
stamp_sign_file varchar;
-- res_stamp varchar := 'initial';
res_stamp varchar;
BEGIN
    out_dir := format('%s/bill-fax', arc_const('doc_out_dir'));
    templ_dir := arc_const('doc_templ_dir');
    out_file := format(E'%s-%s-Счет-факс.odt', substring(arg_bill_no::varchar,1,4), substring(arg_bill_no::varchar,5,4));

    loc_res := rep.set_userfields_common(format('%s/bill_fax_template.odt', templ_dir),
                                         format(E'%s/%s', out_dir, out_file), 
                                         format('select * from bill_fax_data (%s)
AS (
pg_firm TEXT
, pg_signature text
, pg_proxy_doc text
, pg_firm_full_name text
, pg_post_address text
, pg_fact_address text
, pg_city_phone text
, pg_prefix text
, pg_inn text
, pg_kpp text
, pg_account text
, pg_bank text
, pg_corresp text
, pg_bik text
, pg_total text 
, pg_order text
, pg_order_date text
, pg_vat text 
, pg_add text
, pg_carrier text
, pg_email text
, pg_phone text
, pg_mob_label text
, pg_mob_phone text
, pg_firm_phone text
, pg_mgr_name text 
, pg_firm_buyer text 
, pg_fax TEXT
, pg_firm_key text
, pg_legal_address text 
, pg_buyer_address text
, pg_buyer_inn text
, pg_buyer_kpp text
, pg_bill_lifetime text
, pg_total_pos text
, pg_sum_in_words text
, pg_message text
, pg_vat_str text
, pg_logo text
, pg_firm_big text
);'
, arg_bill_no));
    RAISE NOTICE 'set_userfields loc_res=%', loc_res;
    if loc_res <> '' then res := concat_ws(E'/', res, loc_res); end if;

    -- table
    loc_res := rep.fill_table_items(arg_bill_no, out_dir, out_file);
    RAISE NOTICE 'fill_table_items loc_res=%', loc_res;
    if loc_res <> '' then res := concat_ws(E'/', res, loc_res); end if;

    -- our firm
    SELECT b."фирма" INTO our_firm
    FROM "Счета" b
    WHERE b."№ счета" = arg_bill_no;
    RAISE NOTICE 'our_firm=%', our_firm;

    -- logo
    -- rep.replace_image_common('/opt/DogUF/Docs/bill-fax-41260884.odt', '/var/lib/pgsql/fill-forms/signs-replica/kipenergoservis4.png', 'bill_logo')
    SELECT f.bill_logo_file INTO bill_logo_file
    FROM "Фирма" f
    WHERE f."КлючФирмы" = our_firm;
    RAISE NOTICE 'bill_logo_file=%', bill_logo_file;

    if bill_logo_file IS NOT NULL then
        loc_res := rep.replace_image_common(format('%s/%s', out_dir, out_file), 
                                                  format('%s/%s', templ_dir, bill_logo_file), 'bill_logo');
        RAISE NOTICE 'LOGO replace_image_common loc_res=%', loc_res;
        if loc_res <> '' then res := concat_ws(E'/', res, loc_res); end if;
    end if;                                    

    -- stamp & sign
    -- rep.replace_image_common('/opt/DogUF/Docs/bill-fax-41260884.odt', '/var/lib/pgsql/fill-forms/signs-replica/imgStampКЭСББыков2.gif', 'img_stamp_sign');
    SELECT stamp_n_sign INTO stamp_sign_file
    FROM "Подписи"                                                               
    WHERE "КодОтчета" = 'СчетФакс'                                               
          AND "НомерСотрудника" = 0                                              
          AND "КлючФирмы" = our_firm
    ORDER BY "ДатаСтартаПодписи" DESC LIMIT 1;
    RAISE NOTICE 'stamp_sign_file=%', stamp_sign_file;

    if stamp_sign_file IS NOT NULL then
        loc_res := rep.replace_image_common(format('%s/%s', out_dir, out_file), 
                                                   format('%s/%s', templ_dir, stamp_sign_file), 'img_stamp_sign');
        RAISE NOTICE 'SIGN replace_image_common loc_res=%', loc_res;
        if loc_res <> '' then res := concat_ws(E'/', res, loc_res); end if;
    end if;                                    

/**
odt2pdf_query = "SELECT odt2pdf('" + outfile + "');"                             
odt2pdf_query = odt2pdf_query.encode('utf8')                                     
res = plpy.execute(odt2pdf_query)                                                
#return outfile                                                                  
return res[0]["odt2pdf"]                                                         
**/
    loc_res := odt2pdf(out_file, out_dir, out_dir);
    RAISE NOTICE 'odt2pdf loc_res=%', loc_res;

    return res;
END;
$function$
;

