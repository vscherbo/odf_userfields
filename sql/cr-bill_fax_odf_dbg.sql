CREATE OR REPLACE FUNCTION rep.bill_fax_odf_dbg(arg_bill_no integer, arg_templ character varying DEFAULT 'СчетФакс'::character varying)
 RETURNS character varying
 LANGUAGE plpgsql
/**
arg_templ 'СчетФакс'
arg_templ 'Счет', без подписи-печати
arg_templ 'Счет-QR' для физлиц с QR-кодом
**/
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
qr_file varchar ;
-- res_stamp varchar := 'initial';
res_stamp varchar;
loc_templ_file varchar;
qr_dir varchar;
loc_url varchar;
loc_qr_enabled boolean; 
BEGIN
    if arg_templ NOT IN ('СчетФакс', 'Счет', 'Счет-QR') then
        res := format('недопустимое значение arg_templ={%s}', arg_templ);
        RAISE NOTICE '%', res;
        return res;
    end if;


    out_dir := format('%s/bill-fax', arc_const('doc_out_dir'));
    qr_dir := format('%s/qr', out_dir);
    templ_dir := arc_const('doc_templ_dir');
    out_file := format(E'%s-%s.odt', _billno_fmt(arg_bill_no), arg_templ);

    if arg_templ IN ('СчетФакс', 'Счет') then
        loc_templ_file := format('%s/bill_fax_template.odt', templ_dir);
    else -- Счет-QR
        loc_templ_file := format('%s/bill_qr_template.odt', templ_dir);
    end if;

    -- loc_res := rep.set_userfields_common(format('%s/bill_fax_template.odt', templ_dir),
    loc_res := rep.set_userfields_common(loc_templ_file,
                                         format(E'%s/%s', out_dir, out_file), 
                                         format('select * from bill_fax_data (%s, %s)
AS (
pg_firm TEXT
, pg_position text
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
, pg_assembly text
, pg_vat_str text
, pg_logo text
, pg_firm_big text
);'
, arg_bill_no, quote_literal(arg_templ)));
    if loc_res <> '' then
        res := concat_ws(E'/', res, loc_res);
        RAISE NOTICE 'set_userfields_common loc_res=%', loc_res;
    end if;

    -- table
    RAISE NOTICE 'start fill_table_items arg_bill_no=%', arg_bill_no;
    loc_res := rep.fill_table_items(arg_bill_no, out_dir, out_file);
    if loc_res <> '' then 
        res := concat_ws(E'/', res, loc_res); 
        RAISE NOTICE 'fill_table_items loc_res=%', loc_res;
    end if;

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
        if loc_res <> '' then
            res := concat_ws(E'/', res, loc_res);
            RAISE NOTICE 'LOGO replace_image_common loc_res=%', loc_res;
        end if;
    end if;                                    

    -- stamp & sign
    if arg_templ <> 'Счет' then  -- TODO оформить функцией с принятием решения
        -- rep.replace_image_common('/opt/DogUF/Docs/bill-fax-41260884.odt', '/var/lib/pgsql/fill-forms/signs-replica/imgStampКЭСББыков2.gif', 'img_stamp_sign');
        SELECT stamp_n_sign INTO stamp_sign_file
        FROM "Подписи"
        -- WHERE "КодОтчета" = arg_templ -- 'СчетФакс'
        WHERE "КодОтчета" = 'СчетФакс'
              AND "НомерСотрудника" = 0
              AND "КлючФирмы" = our_firm
        ORDER BY "ДатаСтартаПодписи" DESC LIMIT 1;
        RAISE NOTICE 'stamp_sign_file=%', stamp_sign_file;

        if stamp_sign_file IS NOT NULL then
            loc_res := rep.replace_image_common(format('%s/%s', out_dir, out_file), 
                                                       format('%s/%s', templ_dir, stamp_sign_file), 'img_stamp_sign');
            if loc_res <> '' then
                res := concat_ws(E'/', res, loc_res);
                RAISE NOTICE 'SIGN replace_image_common loc_res=%', loc_res;
            end if;
        else
            RAISE NOTICE 'stamp_sign_file is NULL for billno=%', arg_bill_no;
        end if;
    end if; -- не 'Счет'

    -- stamp & sign
    -- if arg_templ == 'Счет-QR'::varchar then
    if arg_templ = 'Счет-QR' then
        -- generate QR
        loc_qr_enabled := rep.is_qr_enabled(arg_bill_no);
        RAISE NOTICE 'loc_qr_enabled=%', loc_qr_enabled;
        if loc_qr_enabled then
            -- DEBUG function
            loc_url := cash.vtb_pay_r(arg_bill_no);
            if strpos(loc_url, 'https://qr.nspk.ru') > 0 then
                -- RAISE NOTICE 'Ok: loc_url=[%] for billno=%', loc_url, arg_bill_no;
                qr_file := format('%s/qr_%s.png', qr_dir, arg_bill_no);
            else -- сбой QR
                loc_res := loc_url;
                RAISE 'qr_url не сформирован. ERR=% for billno=%', loc_url, arg_bill_no;
            end if;
        else
            qr_file := format('%s/qr_blank.png', qr_dir);
        end if;

        if qr_file is not NULL then
            RAISE NOTICE 'qr_file=% for billno=%', qr_file, arg_bill_no;
            loc_res := rep.replace_image_common(format('%s/%s', out_dir, out_file), 
                                                       qr_file, 'img_qr');
            if loc_res <> '' then
                res := concat_ws(E'/', res, loc_res);
                RAISE NOTICE 'QR-код replace_image_common loc_res=%', loc_res;
            end if;
        end if; -- qr_file
    end if; -- 'Счет-QR'

    -- A technical consultant's contacts
    loc_res := rep.set_userfields_common(format(E'%s/%s', out_dir, out_file),
                                         format(E'%s/%s', out_dir, out_file),
                                         format('select * from arc_energo.bill_fax_tech_consultant (%s)
AS (
pg_tech_mgr TEXT
, pg_tech_mgr_name TEXT
, pg_tech_mgr_phone TEXT
, pg_tech_mgr_phone_num TEXT
, pg_tech_mgr_email TEXT
, pg_tech_mgr_email_addr TEXT
, pg_tech_mgr_msngr TEXT
, pg_tech_mgr_msngr_num TEXT
);'
, arg_bill_no));
    if loc_res <> '' then
        res := concat_ws(E'/', res, loc_res);
        RAISE NOTICE 'set_userfields_common tech consultant loc_res=%', loc_res;
    end if;

    if res = '' then -- не было ошибок
        loc_res := odt2pdf(out_file, out_dir, out_dir);
        RAISE NOTICE 'odt2pdf loc_res=%', loc_res;
        res := loc_res;
    end if;

    return res;
END;
$function$
;
