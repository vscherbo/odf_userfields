--DROP FUNCTION rep.set_uf(text, text, text);

CREATE OR REPLACE FUNCTION rep.set_userfields(arg_templ text, arg_outfile text, arg_sql text)
  RETURNS character varying AS
$BODY$
#-*- coding:utf-8 -*-

import sys
from odf.opendocument import load
from odf.userfield import UserFields
import plpy

#===== const
templ_path = u'/opt/autobill/templates'
out_path = u'/opt/autobill/contracts'
#=====
loc_res = ''

res = plpy.execute(arg_sql)
if len(res) != 1:
    loc_res = 'для заполнения шаблона {0} запрос должен вернуть ровно одну строку, а не {1}'.format(arg_templ , len(res))
    plpy.warning(loc_res)
    return loc_res
else:
    plpy.notice('res[0]={0}'.format(res[0]))

templ_name = u'{0}/{1}'.format(templ_path, arg_templ)
plpy.notice('ODT: Template name={0}'.format(templ_name))
try:
    doc = load(templ_name)
except BaseException:
    (e_type, err_text, e_traceback) = sys.exc_info()
    return '{0}: {1}#{2}#{3}'.format(templ_name, e_type, err_text, e_traceback)

out_name = u'{0}/{1}'.format(out_path, arg_outfile)
try:
    doc.save(out_name)
except BaseException:
    (e_type, err_text, e_traceback) = sys.exc_info()
    return '{0}: {1}#{2}#{3}'.format(templ_name, e_type, err_text, e_traceback)

try:
    obj = UserFields(out_name.decode('utf-8'), out_name.decode('utf-8'))
except BaseException:
    (e_type, err_text, e_traceback) = sys.exc_info()
    return '{0}: {1}#{2}#{3}'.format(templ_name, e_type, err_text, e_traceback)

upd_dict={}
loc_warn = []
for (k,v) in res[0].items():
    if not k.startswith('__'):
        if v:
            upd_dict[k] = v.decode('utf-8')
        else:
            upd_dict[k] = '{0} is EMPTY!!!'.format(k)
            plpy.warning(upd_dict[k])
            loc_warn.append(upd_dict[k])
            
if loc_warn:
    loc_res = '/'.join(loc_warn)

plpy.notice('upd_dict={0}'.format(upd_dict))

try:
    obj.update(upd_dict)
except Exception as e:
    err_code, err_text = e.args
    return 'update failed code={0}, err={1}'.format(err_code, err_text)


return loc_res
$BODY$
LANGUAGE plpython2u;

ALTER FUNCTION rep.set_userfields(text, text, text) OWNER TO arc_energo;

