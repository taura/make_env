
certificate 更新にまつわるトラブル

[1] 以下みたいなエラー

TASK [cert : create challenge path] ********************************************
[WARNING]: an unexpected error occurred during Jinja2 environment setup: cannot
import name 'environmentfilter' from 'jinja2.filters'
(/usr/local/lib/python3.10/dist-packages/jinja2/filters.py)   line 0
[WARNING]: an unexpected error occurred during Jinja2 environment setup: cannot
import name 'environmentfilter' from 'jinja2.filters'
(/usr/local/lib/python3.10/dist-packages/jinja2/filters.py)   line 0
fatal: [taulecgw]: FAILED! => {"msg": "template error while templating string: cannot import name 'environmentfilter' from 'jinja2.filters' (/usr/local/lib/python3.10/dist-packages/jinja2/filters.py)\n  line 0. String: /var/www/html/{{ acme_challenge['challenge_data'][fqdn]['http-01']['resource'] | dirname }}"}
fatal: [taulec]: FAILED! => {"msg": "template error while templating string: cannot import name 'environmentfilter' from 'jinja2.filters' (/usr/local/lib/python3.10/dist-packages/jinja2/filters.py)\n  line 0. String: /var/www/html/{{ acme_challenge['challenge_data'][fqdn]['http-01']['resource'] | dirname }}"}

sudo pip3 install Jinja2==3.0.0

でJina2 のバージョンを下げるとでなくなる

いくつまで下げればいいのか不明. 3.0.0 でOKな模様

[2] そのようにして実行しても証明書が更新される気配がない

https://taulec.zapto.org/ をアクセスしてブラウザの鍵マークをクリックして証明書を表示させて, 開始日, 終了日をクリックしても, 昔のまま

更新されるべきファイルは

/etc/pki/tls/certs/taulec.zapto.org/taulec.zapto.org.crt

というファイルだがこれのタイムスタンプも更新されている気配がない

苦肉の策としてこのファイルを一旦どかして

cd /etc/pki/tls/certs/taulec.zapto.org/
sudo mv taulec.zapto.org.crt taulec.zapto.org.crt.x

みたいなことをした上でansibleを走らせるとまともに更新された.
これでいいのか謎

