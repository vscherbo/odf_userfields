-- DROP FUNCTION rep.replace_sign_image_common(text, text, text);

CREATE OR REPLACE FUNCTION rep.replace_sign_image_common(arg_out_full_filename text, arg_img_full_filename text, arg_img_name text)
  RETURNS character varying AS
$BODY$
#-*- coding:utf-8 -*-

import sys
from odf.opendocument import load
#from odf.text import P, H
from odf.draw import Frame, Image

#yum install python-imaging
from PIL import Image as PImage

loc_res = ''

try:
    doc = load(arg_out_full_filename)
except BaseException:
    (e_type, e_text, e_traceback) = sys.exc_info()
    return u'{0}: {1}'.format(arg_out_full_filename, e_text)


try:
    im = PImage.open(arg_img_full_filename)
except IOError:    
    (e_type, e_text, e_traceback) = sys.exc_info()
    return u'{0}: {1}'.format(arg_img_file.decode('utf-8'), str(e_text))

(width, height) = im.size
plpy.notice('image W={0} H={1}'.format(width, height))

try:
    href = doc.addPicture(arg_img_full_filename)
except BaseException:
    (e_type, e_text, e_traceback) = sys.exc_info()
    return u'{0}: {1}'.format(arg_img_full_filename, e_text)

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
    doc.save(arg_out_full_filename)
except BaseException:
    (e_type, e_text, e_traceback) = sys.exc_info()
    return u'saving file error: {0}'.format(e_text)

return loc_res
$BODY$
LANGUAGE plpython2u;

ALTER FUNCTION rep.replace_sign_image_common(text, text, text) OWNER TO arc_energo;
