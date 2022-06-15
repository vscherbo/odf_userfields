#!/usr/bin/env python
#-*- coding:utf-8 -*-

""" Demo fill table
"""

from collections import OrderedDict
from odf.opendocument import load
#from odf.style import Style, TableCellProperties
from odf.text import P
from odf.table import Table, TableRow, TableCell
from odf import text

import pg_app
import log_app

TABLE_ITEMS = 'table_items'
#BILL_NO = 82241283
SQL_BILL_ITEMS = """
SELECT "ПозицияСчета" pg_pos
-- , "Наименование"
, concat_ws(', Арт: ', "Наименование", (SELECT art_id FROM devmod.modifications m WHERE m."КодСодержания" = ss."КодСодержания" AND m.version_num =1)) pg_pos_name
, "Ед Изм" pg_mes_unit
,to_char("Кол-во", '999 999D9') pg_qnt
,to_char("ЦенаНДС", '999 999D99') pg_price
,to_char(round("Кол-во"*"ЦенаНДС", 2), '999 999D99') pg_sum
,COALESCE("Срок2", E'') pg_period
--, round("Кол-во", 1) "Кол-во"
--, round("ЦенаНДС",2) "ЦенаНДС"
--, round ("Кол-во"*"ЦенаНДС", 2) total
--, "Срок2"
-- , devmod.ks_url(ss."КодСодержания") pg_url
FROM arc_energo."Содержание счета" ss
WHERE ss."№ счета" = %s
order by "ПозицияСчета"
"""

SQL_BILL_ITEMS_URL = """
SELECT
devmod.ks_url(c."КодСодержания") pg_url
FROM "Содержание счета" c
WHERE
c."№ счета" = %s
ORDER BY c."ПозицияСчета";"""




#OUT_DIR = u'/smb/system/Scripts/odf_userfields/Contracts/Docs/Bil/2020'
#DOC_NAME = u'ДС-82241283.odt'
#DOC_NAME = u'ДС-{}.odt'


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
        self.bill_urls = []
        self.out_dir = args.out_dir
        self.doc_name = args.doc_file

    def prep_fill(self):
        """ Prepare data for bill's table """
        # prepare data
        ret_val = False
        self.bill_items = []
        self.bill_urls = []
        pgapp = pg_app.PGapp(pg_host=self.args.pg_host, pg_user=self.args.pg_user)
        if pgapp.pg_connect(cursor_factory=pg_app.psycopg2.extras.RealDictCursor):
            sql_bill_items_url = pgapp.curs_dict.mogrify(SQL_BILL_ITEMS_URL, (self.args.bill_no,))
            rcode_url = pgapp.run_query(sql_bill_items_url, dict_mode=True)
            if rcode_url == 0:
                for bill_i in pgapp.curs_dict:
                    self.bill_urls.append(bill_i)
            log_app.logging.info('rcode_url=%s', rcode_url)
            log_app.logging.info('bill_urls=%s', self.bill_urls)
            sql_bill_items = pgapp.curs_dict.mogrify(SQL_BILL_ITEMS, (self.args.bill_no,))
            rcode = pgapp.run_query(sql_bill_items, dict_mode=True)
            if rcode == 0:
                #self.bill_items.append(res)
                for bill_i in pgapp.curs_dict:
                    self.bill_items.append(bill_i)
                    log_app.logging.debug('bill_i=%s', bill_i)
                log_app.logging.debug('bill_items=%s', self.bill_items)
                ret_val = True
        return ret_val


    def fill_bill_table(self):
        """Fill a table of a bill's items"""
        #out_dir = u'/smb/system/Scripts/odf_userfields/Contracts/Docs/Bil/2020'
        doc_name = u"{0}/{1}".format(self.out_dir, self.doc_name) #.decode('utf-8')

        doc = load(doc_name)

        for elem in doc.getElementsByType(Table):
            #log_app.logging.debug(elem.getAttribute('name'))
            if elem.getAttribute('name') == TABLE_ITEMS:
                row1 = elem.getElementsByType(TableRow)[1]
                #row_last = elem.getElementsByType(TableRow)[-1]
                cells = row1.getElementsByType(TableCell)
                cell_style = cells[-1].getAttribute("stylename")
                for row_key, row_bill in enumerate(self.bill_items):
                    ord_dict = OrderedDict()
                    ord_dict[1] = row_bill["pg_pos"]
                    ord_dict[2] = row_bill["pg_pos_name"]
                    ord_dict[3] = row_bill["pg_mes_unit"]
                    ord_dict[4] = row_bill["pg_qnt"]
                    ord_dict[5] = row_bill["pg_price"]
                    ord_dict[6] = row_bill["pg_sum"]
                    ord_dict[7] = row_bill["pg_period"]
                    #ord_dict[8] = row_bill["pg_url"]
                    """
                    ord_dict[1] = row_bill["ПозицияСчета"]
                    ord_dict[2] = row_bill["Наименование"]
                    ord_dict[3] = row_bill["Ед Изм"]
                    ord_dict[4] = row_bill["Кол-во"]
                    ord_dict[5] = row_bill["ЦенаНДС"]
                    ord_dict[6] = row_bill["total"]
                    ord_dict[7] = row_bill["Срок2"]
                    """

                    tr1 = TableRow()
                    for key, val in ord_dict.items():  # OrderedDict(ROW1).values():
                        tc1 = TableCell(stylename=cell_style)
                        #tc1 = TableCell()
                        cell_par = cells[key-1].getElementsByType(P)[0]
                        par_style = cell_par.getAttribute("stylename")
                        #tc1.setAttribute("stylename", cell_style)
                        par = P(stylename=par_style)
                        if key == 2:  # Наименование
                            #anchor = text.A(href=recs_url[r]['ks_url'], text=cell_txt)
                            #pars[0].addElement(anchor)
                            anchor = text.A(href=self.bill_urls[row_key]['pg_url'], text=str(val))
                            par.addElement(anchor)
                            log_app.logging.debug('url=%s', self.bill_urls[row_key]['pg_url'])
                            log_app.logging.debug('type(row_key)=%s', type(row_key))
                            log_app.logging.debug('row_key=%s', row_key)
                        else:
                            par = P(text=str(val), stylename=par_style)

                        tc1.addElement(par)

                        tr1.addElement(tc1)

                    #elem.addElement(tr1)
                    elem.insertBefore(tr1, row1)
                elem.removeChild(row1)
                #elepm.removeChild(row_last)
        doc.save(doc_name)

if __name__ == '__main__':
    log_app.PARSER.add_argument('--pg_host', type=str, default='localhost', help='PG host')
    log_app.PARSER.add_argument('--pg_user', type=str, default='arc_energo', help='PG user')
    log_app.PARSER.add_argument('--bill_no', type=str, required=True,
                                help='bill number')
    log_app.PARSER.add_argument('--doc_file', type=str, required=True,
                                help='full path to odt file with table_items')
    log_app.PARSER.add_argument('--out_dir', type=str, required=True,
                                help='directory for output')
    ARGS = log_app.PARSER.parse_args()
    FT = FillTable(args=ARGS)
    if FT.prep_fill():
        log_app.logging.debug('call fill_bill_table()')
        FT.fill_bill_table()
