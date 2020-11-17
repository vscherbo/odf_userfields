#!/usr/bin/env python
#-*- coding:utf-8 -*-

""" Demo fill table
"""

from collections import OrderedDict
from odf.opendocument import load
#from odf.text import P, H
from odf.text import P
#from odf.userfield import UserFields
from odf.table import Table, TableRow, TableCell
#from odf.table import Table, TableColumn, TableRow

TABLE_ITEMS = 'table_items'

"""

SELECT "ПозицияСчета", "Наименование", "Ед Изм", "Кол-во", "ЦенаНДС",
round ("Кол-во"*"ЦенаНДС", 2)
FROM arc_energo."Содержание счета" ss
WHERE ss."№ счета" = 82241283
order by "ПозицияСчета"
"""

ROW1 = {
    "ПозицияСчета" : 1,
    "Наименование" : u"Термостат KTO-011, на DIN-рейку, -10...50°С, Вых.=~10А, 250В",
    "Ед Изм" : u"шт",
    "Кол-во" : 20.000,
    "ЦенаНДС" : 315.7500,
    "round" : 6315.00
    }


def main():
    """Just main"""
    out_dir = u'/smb/system/Scripts/odf_userfields/Contracts/Docs/Bil/2020'
    out_filename = u"{0}/{1}".format(out_dir, u'ДС-82241283.odt') #.decode('utf-8')

    #print('t={0}, o={1}'.format(templ_filename, out_filename))

    doc = load(out_filename)

    print(ROW1["round"])
    ord_dict = OrderedDict()
    ord_dict[1] = ROW1["ПозицияСчета"]
    ord_dict[2] = ROW1["Наименование"]
    ord_dict[3] = ROW1["Ед Изм"]
    ord_dict[4] = ROW1["Кол-во"]
    ord_dict[5] = ROW1["ЦенаНДС"]
    ord_dict[6] = ROW1["round"]

    for elem in doc.getElementsByType(Table):
        if elem.getAttribute('name') == TABLE_ITEMS:
            tr1 = TableRow()
            for val in ord_dict.values():  # OrderedDict(ROW1).values():
                tc1 = TableCell()
                tc1.addElement(P(text=str(val)))
                tr1.addElement(tc1)
                #print(key, val)
            elem.addElement(tr1)


    doc.save(out_filename)

if __name__ == '__main__':
    main()
