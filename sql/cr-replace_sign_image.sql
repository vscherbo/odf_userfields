-- DROP FUNCTION rep.replace_sign_image(text, text, text);

CREATE OR REPLACE FUNCTION rep.replace_sign_image(arg_doc_file text, arg_img_file text, arg_img_name text)
  RETURNS character varying AS
$BODY$
#-*- coding:utf-8 -*-

import sys
from odf.opendocument import load
#from odf.text import P, H
from odf.draw import Frame, Image


import plpy

#===== const
templ_path = u'/opt/autobill/templates'
out_path = u'/opt/autobill/contracts'
#=====
loc_res = ''

out_name = u'{0}/{1}'.format(out_path, arg_doc_file.decode('utf-8'))
try:
    doc = load(out_name)
except BaseException:
    (e_type, e_text, e_traceback) = sys.exc_info()
    return '{0}: {1}'.format(out_name, e_text)


stamp_name = u'{0}/{1}'.format(templ_path, arg_img_file.decode('utf-8'))
try:
    href = doc.addPicture(stamp_name)
except BaseException:
    (e_type, e_text, e_traceback) = sys.exc_info()
    return '{0}: {1}'.format(stamp_name, e_text)

img_sign = Image(href=href, type="simple", show="embed", actuate="onLoad")
for f in doc.getElementsByType(Frame):
    if f.getAttribute('name') == arg_img_name:
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
    return '{0}: {1}'.format('saving file error', e_text)

return loc_res
$BODY$
LANGUAGE plpython2u;

ALTER FUNCTION rep.replace_sign_image(text, text, text) OWNER TO arc_energo;
