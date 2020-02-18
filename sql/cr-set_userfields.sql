-- DROP FUNCTION rep.set_userfields(text, text, text);

CREATE OR REPLACE FUNCTION rep.set_userfields(arg_templ text, arg_outfile text, arg_sql text)
  RETURNS character varying AS
$BODY$
#-*- coding:utf-8 -*-

import sys
from odf.opendocument import load
from odf.userfield import UserFields
import plpy

#===== const
#templ_path = u'/opt/autobill/templates'
#out_path = u'/opt/autobill/contracts'
templ_path = u''
out_path = u''
path_sql = "select const_name, const_value from arc_constants where const_name in ('doc_templ_dir', 'doc_out_dir');"
res = plpy.execute(path_sql)
if len(res) != 2:
    loc_res = 'не определены в arc_constants каталоги для шаблонов/документов:{0}'.format(res)
    plpy.warning(loc_res)
    return loc_res
else:
    for i in range(0, len(res)):
        pass
        if res[i]["const_name"] == 'doc_templ_dir':
            templ_path += res[i]["const_value"]
        elif res[i]["const_name"] == 'doc_out_dir':
            out_path += res[i]["const_value"]
    plpy.notice('templ_path={0}, out_path={1}'.format(templ_path, out_path))

#=====
loc_res = ''

res = plpy.execute(arg_sql)
if len(res) != 1:
    loc_res = u'для заполнения шаблона {0} запрос должен вернуть ровно одну строку, а не {1}'.format(arg_templ , len(res))
    plpy.warning(loc_res.encode('utf-8'))
    return loc_res
else:
    plpy.notice('res[0]={0}'.format(res[0]))

templ_name = u'{0}/{1}'.format(templ_path, arg_templ.decode('utf-8'))
plpy.notice('ODT: Template name={0}'.format(templ_name.encode('utf-8')))
try:
    doc = load(templ_name)
except BaseException:
    (e_type, e_text, e_traceback) = sys.exc_info()
    return u'{0}: {1}'.format(templ_name, e_text)

out_name = u'{0}/{1}'.format(out_path, arg_outfile.decode('utf-8'))
try:
    doc.save(out_name)
except BaseException:
    (e_type, e_text, e_traceback) = sys.exc_info()
    return u'{0}: {1}'.format(out_name, e_text)

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

plpy.notice(u'upd_dict={0}'.format(upd_dict))

try:
    obj.update(upd_dict)
except BaseException:
    (e_type, e_text, e_traceback) = sys.exc_info()
    return 'update failed e_type={0}, e_text={1}'.format(e_type, e_text)

return loc_res
$BODY$
LANGUAGE plpython2u;

ALTER FUNCTION rep.set_userfields(text, text, text) OWNER TO arc_energo;

