import requests
import re

def validate_state(input_string):
    regex = re.compile('State[0-9]+', re.I)
    match = regex.match(str(input_string))
    return bool(match)

def validate_channel(input_string):
    regex = re.compile('C[0-9]+', re.I)
    match = regex.match(str(input_string))
    return bool(match)

def validate_transaction(input_string):
    regex = re.compile('T[0-9]+', re.I)
    match = regex.match(str(input_string))
    return bool(match)

url = 'https://distribucion-digital-ext-qa.apps.ambientesbc.com/digital-distribution/api/v1'

# Limpieza de filtros funcionales

response = requests.get(url+'/technical-parameters/functional-security')
for element in response.json()['data']:
    if(element['name'].startswith('FunctionalSecurityConfigTest_get_')):
        response = requests.delete(url+'/technical-parameters/functional-security/'+element['name'])

# Limpieza de rutas

response = requests.get(url+'/technical-parameters/routes-scg')
for element in response.json()['data']:
    if(element['id'].startswith('Spring-Cloud-Gateway')):
        response = requests.delete(url+'/technical-parameters/routes-scg/'+element['id'])

response = requests.get(url+'/technical-parameters/routes-scg')
for element in response.json()['data']:
    if(element['id'].startswith('transfer_route_')):
        response = requests.delete(url+'/technical-parameters/routes-scg/'+element['id'])