#!/bin/sh

./fill_bill.py --pg_host=vm-pg-devel --pg_user=arc_energo --out_dir='/smb/system/Scripts/odf_userfields/Contracts/Docs/Bil/2020' --bill_no="$1"
