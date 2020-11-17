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
loc_res = ''

out_name = u'{0}/{1}'.format(out_path, arg_doc_file.decode('utf-8'))
try:
    doc = load(out_name)
except BaseException:
    (e_type, e_text, e_traceback) = sys.exc_info()
    return u'{0}: {1}'.format(out_name, e_text)


stamp_name = u'{0}/{1}'.format(templ_path, arg_img_file.decode('utf-8'))
try:
    im = PImage.open(stamp_name)
except IOError:    
    (e_type, e_text, e_traceback) = sys.exc_info()
    return u'{0}: {1}'.format(arg_img_file.decode('utf-8'), str(e_text))

(width, height) = im.size
plpy.notice('image W={0} H={1}'.format(width, height))

try:
    href = doc.addPicture(stamp_name)
except BaseException:
    (e_type, e_text, e_traceback) = sys.exc_info()
    return u'{0}: {1}'.format(stamp_name, e_text)

img_sign = Image(href=href, type="simple", show="embed", actuate="onLoad")
for f in doc.getElementsByType(Frame):
    if f.getAttribute('name') == arg_img_name:
        w_cm = width*2.54/96
        h_cm = height*2.54/96
        f.setAttribute("width", "{0}cm".format(w_cm))
        f.setAttribute("height", "{0}cm".format(h_cm))
        #f.setAttribute("width", "{0}px".format(width))
        #f.setAttribute("height", "{0}px".format(height))
        for chld in f.childNodes:
            if u'image' in chld.qname:
                for img in chld.getElementsByType(Image):
                    #print('--- img ---')
                    #print(img.getAttribute('href'))
                    img.setAttribute('href', href)
                    #print(img.getAttribute('href'))

try:
    doc.save(out_name)
except BaseException:
    (e_type, e_text, e_traceback) = sys.exc_info()
    return u'saving file error: {0}'.format(e_text)

return loc_res
$BODY$
LANGUAGE plpython2u;

ALTER FUNCTION rep.replace_sign_image(text, text, text) OWNER TO arc_energo;
