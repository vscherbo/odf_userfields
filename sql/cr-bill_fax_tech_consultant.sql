-- DROP FUNCTION arc_energo.bill_fax_tech_consultant (integer); -- RETURNS record

CREATE OR REPLACE FUNCTION arc_energo.bill_fax_tech_consultant (bill_no integer) RETURNS record
    LANGUAGE plpgsql
    AS $$
DECLARE
res record;
BEGIN
PERFORM 1 FROM "Счета" WHERE "№ счета" = bill_no AND "Хозяин" IN (40, 41); -- c консультантом

IF FOUND THEN
    SELECT
    -- 'Технические консультации:'::TEXT res.pg_tech_mgr
    'Технические консультации:'::TEXT ,e.ФИО::TEXT
    ,'Консультации по тел:'::TEXT ,format('(812)327-327-4, доб. %s'::TEXT, e.telephone)
    ,'E-mail:'::TEXT ,e.email::TEXT
    ,'моб.т./WhatsApp/Telegram:'::TEXT ,e.mob_phone::TEXT
    INTO res
    /**
      res.pg_tech_mgr , res.pg_tech_mgr_name
    , res.pg_tech_mgr_phone , res.pg_tech_mgr_phone_num
    , res.pg_tech_mgr_email , res.pg_tech_mgr_email_addr
    , res.pg_tech_mgr_msngr , res.pg_tech_mgr_msngr_num
**/
    FROM Сотрудники e
    WHERE "Менеджер" = 44;
/**    
ELSE -- без консультанта
    res.pg_tech_mgr := '';
    res.pg_tech_mgr_name := '';
    res.pg_tech_mgr_phone := '';
    res.pg_tech_mgr_phone_num := '';
    res.pg_tech_mgr_email := '';
    res.pg_tech_mgr_email_addr := '';
    res.pg_tech_mgr_msngr := '';
    res.pg_tech_mgr_msngr_num := '';
**/
END IF;
RETURN res;
END;
$$;
/**
SELECT
-- 'Технические консультации:'::TEXT pg_tech_mgr
'Технические консультации:' pg_tech_mgr
,e.Имя pg_tech_mgr_name
,'Консультации по тел:'::TEXT pg_tech_mgr_phone
,format('(812)327-327-4, доб. %s', e.telephone) pg_tech_mgr_phone_num
,'E-mail:'::TEXT pg_tech_mgr_email
,e.email pg_tech_mgr_email_addr
,'моб.т./WhatsApp/Telegram:'::TEXT pg_tech_mgr_msngr
,e.mob_phone pg_tech_mgr_msngr_num

    SELECT -- затираем пробелами
    ''::TEXT pg_tech_mgr
    ,''::TEXT pg_tech_mgr_name
    ,''::TEXT pg_tech_mgr_phone
    ,''::TEXT pg_tech_mgr_phone_num
    ,''::TEXT pg_tech_mgr_email
    ,''::TEXT pg_tech_mgr_email_addr
    ,''::TEXT pg_tech_mgr_msngr
    ,''::TEXT pg_tech_mgr_msngr_num;

**/
