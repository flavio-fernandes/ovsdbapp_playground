#!/usr/bin/env python
from __future__ import print_function

import sys

from ovsdbapp.backend.ovs_idl import connection
from ovsdbapp.schema.ovn_northbound import impl_idl

conn = "tcp:127.0.0.1:6641"
print("Connecting to", conn, file=sys.stderr)

# The python-ovs Idl class
i = connection.OvsdbIdl.from_server(conn, 'OVN_Northbound')
# The ovsdbapp Connection object
c = connection.Connection(i, 5)
# The OVN_Northbound API implementation object
api = impl_idl.OvnNbApiIdlImpl(c)

# If we only wanted to delete the acls....
# with api.transaction(check_error=True) as txn:
#     txn.add(api.acl_del("sw1"))
#     txn.add(api.acl_del("sw0"))

with api.transaction(check_error=True) as txn:
    for ls_row in api.tables['Logical_Switch'].rows:
        txn.add(api.acl_del(ls_row))
        txn.add(api.ls_del(ls_row))
    for lr_row in api.lr_list().execute(check_error=True):
        txn.add(api.lr_del(lr_row.uuid))


# Loop through rows returned from an API call (very boring after removals :))
for ls_row in api.ls_list().execute(check_error=True):
    print("ls uuid: %s, name: %s" % (ls_row.uuid, ls_row.name))
    for lsp_row in api.lsp_list(switch=ls_row.uuid).execute(check_error=True):
        print("  lsp uuid: %s, name: %s" % (lsp_row.uuid, lsp_row.name))

print("ok")
