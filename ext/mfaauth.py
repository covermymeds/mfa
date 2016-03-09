#! /usr/bin/env python
#
# 
# 
#
# 
# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4

import radiusd
import re
import requests

def authorize(authData):
    authUser = ''
    authPass = ''
    authMfa  = ''
    mfaOnly  = 0

    print authData
    
    # Find the user/pass bits in the request
    for t in authData:
        if t[0] == 'User-Name':
            # Grab the username, sans some potential quoting
            authUser = re.subn('\"', "", t[1])[0]
        elif t[0] == 'User-Password':
            # Remove the extra quotes from the pass field
            tAuthPass = re.subn('\"', "", t[1])[0]

            # See if were 6 digits only
            if re.match('^[0-9]{6}$', tAuthPass) == None:
	        # Split the password, fail if we cant find a 6 digit key at the end
                reRes = re.search('(.+)([0-9]{6})', tAuthPass)
                if reRes:
                    authPass = reRes.group(1)
                    authMfa  = reRes.group(2)
                else:
                    return radiusd.RLM_MODULE_REJECT
            else:
                authMfa = tAuthPass
        elif t[0] == 'MFA-Only':
            # Stuff the value in mfaOnly for later
            mfaOnly = t[1]
        

    mfaPayload = {'password': authPass, 'mfa': authMfa, 'mfa_only': mfaOnly}

    if mfaOnly != '1' and authPass == '':
        print mfaPayload
        return radiusd.RLM_MODULE_REJECT

    print mfaPayload
    req = requests.put('https://127.0.0.1/authenticate/' + authUser, verify=False, data=mfaPayload)
   
    print req.json()

    if req.json()['status'] == 'SUCCESS':
	return (radiusd.RLM_MODULE_UPDATED,
	    (('Session-Timeout', '3600'),),
	    (('Auth-Type', 'python'),))
    else:
        return radiusd.RLM_MODULE_REJECT

def authenticate(authData):
    return radiusd.RLM_MODULE_OK
