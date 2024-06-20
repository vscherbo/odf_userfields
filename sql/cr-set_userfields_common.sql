-- DROP FUNCTION rep.set_userfields_common(text, text, text);

CREATE OR REPLACE FUNCTION rep.set_userfields_common(arg_templ_full_filename text, arg_out_full_filename text, arg_sql text)
  RETURNS character varying AS
$BODY$
#-*- coding:utf-8 -*-

import sys
from odf.opendocument import load
from odf.userfield import UserFields
import plpy

loc_res = ''

res = plpy.execute(arg_sql)
if len(res) != 1:
    loc_res = u'для заполнения шаблона {0} запрос должен вернуть ровно одну строку, а не {1}'.format(arg_templ , len(res))
    plpy.warning(loc_res.encode('utf-8'))
    return loc_res
else:
    #plpy.notice('res[0]={0}'.format(res[0]))
    for k,v in res[0].items():
        if v is not None:
            plpy.notice('{0}: {1}'.format(k, v))
        else:
            plpy.notice('{0}: NONE'.format(k))


templ_name = arg_templ_full_filename.decode('utf-8')
plpy.notice('ODT: Template name={0}'.format(templ_name.encode('utf-8')))
try:
    doc = load(templ_name)
except BaseException:
    (e_type, e_text, e_traceback) = sys.exc_info()
    return u'{0}: {1} {2}'.format(templ_name, e_text, e_traceback)

out_name = arg_out_full_filename.decode('utf-8')
try:
    doc.save(out_name)
except BaseException:
    (e_type, e_text, e_traceback) = sys.exc_info()
    #return u'{0}: {1}'.format(out_name, e_text)
    return u'{0}: {1} {2}'.format(templ_name, e_text, e_traceback)

try:
    obj = UserFields(out_name, out_name)
except BaseException:
    (e_type, e_text, e_traceback) = sys.exc_info()
    return u'{0}: {1}'.format(out_name, e_text)

upd_dict={}
loc_warn = []
for (k,v) in res[0].items():
    if not k.startswith('__'):
        if v:
            upd_dict[k] = v.decode('utf-8')
        else:
            #upd_dict[k] = '{0} is EMPTY!!!'.format(k)
            #plpy.warning('{0} is EMPTY'.format(k))
            #loc_warn.append(upd_dict[k])
            upd_dict[k] = ''
            
if loc_warn:
    loc_res = '/'.join(loc_warn)

try:
    obj.update(upd_dict)
except BaseException:
    (e_type, e_text, e_traceback) = sys.exc_info()
    return 'update failed e_type={0}, e_text={1}'.format(e_type, e_text)

return loc_res
$BODY$
LANGUAGE plpython2u;

ALTER FUNCTION rep.set_userfields_common(text, text, text) OWNER TO arc_energo;

