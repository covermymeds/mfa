# Multi-Factor Authentication (MFA)

## Overview

The Multi-Factor Authenticatiom (MFA) app is a small rails application that hooks into AD (or another LDAP backend) to manage and authenticate against the AD/LDAP backend with a password+TOTP pair.  The original purpose of this app was to provide a GUI for the [Google Authenticator PAM](https://github.com/google/google-authenticator) backend for RADIUS, but ultimately moved to using the rails app for management as well as authentication purposes.

The goal of this app is to allow for a simplified management model of TOTP tokens, including self service, without the overhead of a full blown IDM solution (ala FreeIPA or OpenAM).

## Installation

Deploy the application as a standard rails app as is appropriate to your environment.  This app has been tested in a [Passenger+Apache](https://www.phusionpassenger.com/library/) solution.

## Configuration

Configuration settings are managed via the [Settings](https://github.com/railsconfig/config) gem.  For a basic configuration, copy the `config/settings.yml` file to `config/settings.local.yml` and modify values to suit your environment.

Two fields will need to be created or repurposed in LDAP to store the TOTP token and boolean if the token is active.  Additionally the user defined in `bind_dn` will need to have read and write access control entries added so that it can manage these values.  The fields themselves can be existing or added in as custom entries, as long as they are both string values.  The default is to leverage the extensionAttribute fields available in AD.

A password and salt will also need to be generated.  It is advised that these be long, random strings.  The following bit of ruby code will provide a random salt and pass.

```ruby
require 'securerandom'
puts "Pass: #{SecureRandom.hex(32)}"
puts "Salt: #{SecureRandom.hex(32)}"
```

These values should be placed in `totp_pass` and `totp_salt` before generating any keys.  If these are lost or changed, all keys will become invalid!

### Configuration Settings

#### Mailer

Mail/SMTP related configuration options

* from_address: The email address that email'ed QR codes will sent from.  This is likely to be your support email or IT help center email.
* to_domain: The email domain user accounts are from.  This is used as a fall back if the mail attribute in AD/LDAP is not filled or available.
* smtp_server: The SMTP server to relay messages through.
* enable_starttls_auto: Enables SMTP/TLS (STARTTLS) for this object if server is able to negotiate it.

#### LDAP

LDAP/AD related configuration

* type: The type of LDAP backend to communicate with.  Currently only `active_directory` is supported.
* host: The FQDN or IP of the LDAP host to connect to.
* port: The Port to connect to LDAP to.  Usually 389 (LDAP) or 636 (LDAPS).
* base: The base OU to search from.
* bind_dn: The RDN to connect to LDAP with.  This account should have write access to totp_field and enabled_field.
* bind_pw: The password associated with the `bind_dn`.
* totp_field: The field to retrieve and store the encrypted TOTP token from.
* enabled_field: The field to retiever and store if the TOTP token is active for the user.
* admin_group: The group associated with Administrators of the MFA system.  These users can manage/modify other users MFA tokens.

#### General

General settings 

* totp_pass: The passphrase to encrypt TOTP tokens with
* totp_salt: The salt to encrypt TOTP tokens with
* org_name: The Friendly name of the organization.  This is used on the front page as well as the organization in the TOTP token.

## Authentication

The other part of MFA is actually using it as an authentication method.  At its core, authentication can be done via the RESTful interface for any application. This has been tested with FreeRADIUS 3.0.

To configure FreeRADIUS, set up your FreeRADIUS server to run as a [Virtual Server](http://freeradius.org/features/virtual_servers.html) and then place the following files in the following locations:

* ext/python.radius.mods.conf => $RADIUSDIR/mods-enabled/python
* ext/mfa.radius.site.conf    => $RADIUSDIR/sites-enabled/mfa
* ext/mfaauth.py              => $RADIUSDIR/sites-config/python/mfaauth.py

The FreeRADIUS server will also need to know where the python script lives.  Depending on your OS/Distribution, make sure that $PYTHONPATH is set to include $RADIUSDIR/sites-config/python for the user running FreeRADIUS.  Once these are set up, change the client to use virtual_server = mfa, and RADIUS should use the python module.

### Authenticate REST API

* **URL**

  /authenticate/:id

* **Method**

  POST

* **Params**

  **Required:**

  password=[string]

  The password (first factor) for the account (id).
  Note: This can be empty if mfa_only is true.

  mfa=[integer]

  The TOTP code from Google Authenticator for the account (id).

  mfa_only=[boolean]

  Only use the mfa token.

* **Response**

  Code: 200
  Response: A json object with a status value and a message. The status is either 'SUCCESS' or 'FAIL'.
  {status: 'SUCCESS', message: 'MFA successful'}
