#!/usr/bin/env python
#-*- coding:utf-8 -*-

""" Demo fill table
"""

from collections import OrderedDict
from odf.opendocument import load
from odf.style import Style, TableCellProperties
#from odf.style import Style, TableColumnProperties, TableCellProperties, ParagraphProperties
#from odf.text import P, H
from odf.text import P
#from odf.userfield import UserFields
from odf.table import Table, TableRow, TableCell
#from odf.table import Table, TableColumn, TableRow

import pg_app
import log_app

TABLE_ITEMS = 'table_items'
#BILL_NO = 82241283
SQL_BILL_ITEMS = """
SELECT "ПозицияСчета", "Наименование", "Ед Изм"
, round("Кол-во", 1) "Кол-во"
, round("ЦенаНДС",2) "ЦенаНДС"
, round ("Кол-во"*"ЦенаНДС", 2) total
FROM arc_energo."Содержание счета" ss
WHERE ss."№ счета" = %s
order by "ПозицияСчета"
"""


#OUT_DIR = u'/smb/system/Scripts/odf_userfields/Contracts/Docs/Bil/2020'
#DOC_NAME = u'ДС-82241283.odt'
DOC_NAME = u'ДС-{}.odt'


BILL_ITEMS = [
    {
        "ПозицияСчета" : 1,
        "Наименование" : u"Термостат KTO-011, на DIN-рейку, -10...50°С, Вых.=~10А, 250В",
        "Ед Изм" : u"шт",
        "Кол-во" : 20.000,
        "ЦенаНДС" : 315.7500,
        "total" : 6315.00
    },
    {
        "ПозицияСчета" : 2,
        "Наименование" : u"Прибор, Вых.=~10А, 250В",
        "Ед Изм" : u"шт",
        "Кол-во" : 2.000,
        "ЦенаНДС" : 1000.00,
        "total" : 2000.00
    }
    ]

def get_styles(doc):
    """ get doc styles"""
    styles = {}
    for ast in doc.automaticstyles.childNodes:
        name = ast.getAttribute('name')
        style = {}
        styles[name] = style

        for k in ast.attributes.keys():
            style[k[1]] = ast.attributes[k]
        for nod in ast.childNodes:
            for k in nod.attributes.keys():
                style[nod.qname[1] + "/" + k[1]] = nod.attributes[k]
        return styles


class FillTable(log_app.LogApp):
    """ Fill table class """
    def __init__(self, args):
        super(FillTable, self).__init__(args, description='FillTable app')
        self.bill_items = []
        self.out_dir = args.out_dir
        self.doc_name = DOC_NAME.format(args.bill_no)

    def prep_fill(self):
        """ Prepare data for bill's table """
        # prepare data
        ret_val = False
        self.bill_items = []
        pgapp = pg_app.PGapp(pg_host=self.args.pg_host, pg_user=self.args.pg_user)
        if pgapp.pg_connect(cursor_factory=pg_app.psycopg2.extras.RealDictCursor):
            sql_bill_items = pgapp.curs_dict.mogrify(SQL_BILL_ITEMS, (self.args.bill_no,))
            rcode = pgapp.run_query(sql_bill_items, dict_mode=True)
            if rcode == 0:
                #self.bill_items.append(res)
                for bill_i in pgapp.curs_dict:
                    self.bill_items.append(bill_i)
                    log_app.logging.debug('bill_i=%s', bill_i)
                log_app.logging.debug('bill_items=%s', self.bill_items)
                #bill_items = BILL_ITEMS
                #self.out_dir = OUT_DIR
                #self.doc_name = DOC_NAME.format(bill_no)
                # fill table
                ret_val = True
        return ret_val


    def fill_bill_table(self):
        """Fill a table of a bill's items"""
        #out_dir = u'/smb/system/Scripts/odf_userfields/Contracts/Docs/Bil/2020'
        doc_name = u"{0}/{1}".format(self.out_dir, self.doc_name) #.decode('utf-8')

        #print('t={0}, o={1}'.format(templ_filename, doc_name))

        doc = load(doc_name)
        bill_cell_style = Style(name="bill cell style", family="table-cell")
        #ill_cell_style.addElement(TableCellProperties(border="0.3pt solid #000000"))
        bill_cell_style.addElement(TableCellProperties())

        """
        pstyle = Style(name="paragraph style", family="paragraph")
        pstyle.addElement(ParagraphProperties(textalign="center"))
        money_style = Style(name="money style", family="paragraph")
        money_style.addElement(ParagraphProperties(textalign="right"))
        """

        #money_col_style = Style(name="money col style", family="table-column")
        #money_col_style.addElement(TableColumnProperties(textalign="right"))

        doc.styles.addElement(bill_cell_style)
        #doc.styles.addElement(pstyle)
        #doc.styles.addElement(money_style)
        #doc.styles.addElement(money_col_style)

        for elem in doc.getElementsByType(Table):
            if elem.getAttribute('name') == TABLE_ITEMS:
                #tab = elem
                row1 = elem.getElementsByType(TableRow)[1]
                #row_last = elem.getElementsByType(TableRow)[-1]
                print('row1=', row1)
                cells = row1.getElementsByType(TableCell)
                cell_style = cells[0].getAttribute("stylename")
                for row_bill in self.bill_items:
                    #print('total=', row_bill["total"])
                    ord_dict = OrderedDict()
                    ord_dict[1] = row_bill["ПозицияСчета"]
                    ord_dict[2] = row_bill["Наименование"]
                    ord_dict[3] = row_bill["Ед Изм"]
                    ord_dict[4] = row_bill["Кол-во"]
                    ord_dict[5] = row_bill["ЦенаНДС"]
                    ord_dict[6] = row_bill["total"]

                    tr1 = TableRow()
                    for key, val in ord_dict.items():  # OrderedDict(ROW1).values():
                        tc1 = TableCell(stylename=cell_style)
                        #tc1 = TableCell()
                        cell_par = cells[key-1].getElementsByType(P)[0]
                        par_style = cell_par.getAttribute("stylename")
                        tc1.addElement(P(text=str(val), stylename=par_style))
                        #tc1.setAttribute("stylename", cell_style)
                        tr1.addElement(tc1)

                    #elem.addElement(tr1)
                    elem.insertBefore(tr1, row1)
                elem.removeChild(row1)
                #elem.removeChild(row_last)

        doc.save(doc_name)

if __name__ == '__main__':
    log_app.PARSER.add_argument('--pg_host', type=str, default='localhost', help='PG host')
    log_app.PARSER.add_argument('--pg_user', type=str, help='PG user')
    log_app.PARSER.add_argument('--bill_no', type=int, help='bill number')
    log_app.PARSER.add_argument('--out_dir', type=str, help='directory for output')
    ARGS = log_app.PARSER.parse_args()
    FT = FillTable(args=ARGS)
    if FT.prep_fill():
        log_app.logging.debug('call fill_bill_table()')
        FT.fill_bill_table()
