# how this directory works

This directory installs certbot and obtains SSL certificate for the host.

Things are complicated because we have to do different things depending on whether the host is configured for the first time or is rebooted.

When it is brought up for the first time, all we have to do is to obtain a new certificate

```
certbot --apache -d $(hostname) -n --agree-tos --email tau@eidos.ic.i.u-tokyo.ac.jp
```

This gets certificate, installs it under /etc/letsencrypt and configures apache2.

/etc/letsencrypt
/etc/apache2/sites-available/000-default-le-ssl.conf

While the host is running, it must renew the certificate from time to time, for which we have to do

```
certbot renew
```

The makefile checks if /etc/letsencrypt exists or not, obtains a new certificate if not, and restores the back up otherwise.

We have to make sure renew happens before a certificate expires.  
So, occasionally, we will run renew and back up from the laptop.

cd letsencrypt_backup/
./renew_and_backup.sh taulec.zapto.org
./renew_and_backup.sh tauleg.zapto.org
./renew_and_backup.sh taulex.zapto.org
(whichever is necessary)

When the cerficaite is obtained or renewed, we must make a back up of the following two directories.
It must be preserved in the repository.

When it is rebooted, we need to do reinstall the back up.


# renew log

root@taulec:~/taulec_env/scripts/J60ssl# certbot renew
Saving debug log to /var/log/letsencrypt/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Processing /etc/letsencrypt/renewal/taulec.zapto.org.conf
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Cert is due for renewal, auto-renewing...
Plugins selected: Authenticator apache, Installer apache
Renewing an existing certificate for taulec.zapto.org
Performing the following challenges:
http-01 challenge for taulec.zapto.org
Enabled Apache rewrite module
Waiting for verification...
Cleaning up challenges

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
new certificate deployed with reload of apache server; fullchain is
/etc/letsencrypt/live/taulec.zapto.org/fullchain.pem
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

Congratulations, all renewals succeeded. The following certs have been renewed:
  /etc/letsencrypt/live/taulec.zapto.org/fullchain.pem (success)
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
