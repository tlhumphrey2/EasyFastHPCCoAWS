#!/usr/bin/python
'''
parseJSON.py MultiThorHPCCCloudFormationTemplate.json
'''
import sys
import json

def process_list(indent,x):
  for i, v in enumerate(x):
    print('%sGROUP[%d]' % (indent,i))
    if type(v) is dict:
      process_dict(indent+'.',v)
    elif type(v) is list:
      process_list(indent+'.',v)
    else:
      print('%sitem=%s' % (indent,v))

def process_dict(indent,x):
  for key, value in x.iteritems():
    if type(value) is dict:
      print('%skey="%s":' % (indent,key))
      process_dict(indent+'.',value)
    elif type(value) is list:
      print('%skey="%s":' % (indent,key))
      process_list(indent+'.',value)
    else:
      print('%skey=%s, value=%s' % (indent,key,value))

filename=sys.argv[1]

try:
    fileobj = open(sys.argv[1], 'r')
except IndexError:
    fileobj = sys.stdin

with fileobj:
    data = fileobj.read()

my_json=json.loads(data)
      
print('Output %s:' % filename)
process_dict('',my_json) 

