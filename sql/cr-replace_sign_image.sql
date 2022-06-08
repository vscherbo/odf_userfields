-- DROP FUNCTION rep.replace_sign_image(text, text, text);

CREATE OR REPLACE FUNCTION rep.replace_sign_image(arg_doc_file text, arg_img_file text, arg_img_name text)
  RETURNS character varying AS
$BODY$
#-*- coding:utf-8 -*-

import sys
from odf.opendocument import load
#from odf.text import P, H
from odf.draw import Frame, Image

#yum install python-imaging
from PIL import Image as PImage

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

out_name = u'{0}/{1}'.format(out_path, arg_doc_file.decode('utf-8'))
stamp_name = u'{0}/{1}'.format(templ_path, arg_img_file.decode('utf-8'))
loc_res = replace_sign_image_common(out_name, stamp_name, arg_img_name)

return loc_res
$BODY$
LANGUAGE plpython2u;

ALTER FUNCTION rep.replace_sign_image(text, text, text) OWNER TO arc_energo;
