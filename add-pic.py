#!/usr/bin/env python
#-*- coding:utf-8 -*-

from configparser import ConfigParser
from odf.opendocument import load
from odf.text import P, H
from odf.userfield import UserFields
from odf.table import Table, TableColumn, TableRow, TableCell
from odf.draw import Frame, Image

SIGNATURE_FRAME = 'Frame1'
SIGNATURE_TABLE = 'stamps_signs'

config = ConfigParser()
config.read('contract.conf')

upd_dict={}
for (k,v) in config['data'].items():
    #print(k, v)
    upd_dict[k] = v  #.decode('utf-8')

#print(upd_dict)

templ_dir = u'/mnt/storage/tmp'
templ_filename = u"{0}/{1}".format(templ_dir, 'DogTemp-full.odt')

out_dir = templ_dir
out_filename = u"{0}/{1}".format(out_dir, 'DogOutput.odt').decode('utf-8')

#print('t={0}, o={1}'.format(templ_filename, out_filename))

doc = load(templ_filename)


img_path = '/smb/it/tmp/imgStampКИПСПБ.jpg'
href = doc.addPicture(img_path)
img_sign = Image(href=href, type="simple", show="embed", actuate="onLoad")
for f in doc.getElementsByType(Frame):
    if f.getAttribute('name') == 'img_stamp_sign':
        for chld in f.childNodes:
            if u'image' in chld.qname:
                for img in chld.getElementsByType(Image):
                    print('--- img ---')
                    #print(img.getAttribute('href'))
                    img.setAttribute('href', href)
                    #print(img.getAttribute('href'))
"""        
for tbl in doc.getElementsByType(Table):
    if tbl.getAttribute('name') == SIGNATURE_TABLE:
        for cell in tbl.getElementsByType(TableCell):
            print('cell')
            print(cell.allowed_attributes())
            break

        cells = tbl.getElementsByType(TableCell)
        p = P()
        cells[1].addElement(p)
        img_path = '/smb/it/tmp/imgStampКИПСПБ.jpg'
        href = doc.addPicture(img_path)
        f = Frame(name="graphics1", anchortype="paragraph", width="5.61cm", height="3.78cm", 
        zindex="0")
        p.addElement(f)
        img = Image(href=href, type="simple", show="embed", actuate="onLoad")
        f.addElement(img)
"""        


doc.save(out_filename)
#? obj = UserFields(templ_filename, out_filename)
obj = UserFields(out_filename, out_filename)

"""
input_keys = config['data'].keys()
print('input_keys={0}'.format(input_keys))
output_keys = obj.list_fields()
print('output_keys={0}'.format(output_keys))

# get intersection

diff = list(set(output_keys) - set(input_keys))
print('diff={0}'.format(diff))

# diff input_keys with intersection
# diff output_keys with intersection
"""

obj.update(upd_dict)


