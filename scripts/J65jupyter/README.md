JupyterHub に統一する計画
=========================

OCaml
=========================

* 普通にはOCamlがうまく立ち上がらない
* 症状は OCaml カーネルを起動すると, dlllwt_unix_stubs.so が見つからないみたいなエラー
* 根本的にはOCaml/opam が全ユーザ共通のインストールができないため
* 詳細:
まずopamを使ったOCaml, OCaml kernelのインストール手順は以下
```
opam init --yes
opam install --yes jupyter
opam install --yes jupyter-archimedes
~/.opam/default/bin/ocaml-jupyter-opam-genspec
sudo jupyter kernelspec install --name ocaml-jupyter ~/.opam/default/share/jupyter
```
* 上記 ~/.opam/default/bin/ocaml-jupyter-opam-genspec で ~/.opam/default/share/jupyter/kernel.json が生成される
```
share@taulec:~/.opam/default/share/jupyter$ less kernel.json.bak 
{
  "display_name": "OCaml default",
  "language": "OCaml",
  "argv": [
    "/bin/sh",
    "-c",
    "eval $(opam config env --switch=default --shell=sh) && /home/share/.opam/default/bin/ocaml-jupyter-kernel \"$@\"",
    "ocaml-jupyter-kernel",
    "-init", "/home/share/.ocamlinit",
    "--merlin", "/home/share/.opam/default/bin/ocamlmerlin",
    "--verbosity", "app",
    "--connection-file", "{connection_file}"
  ]
}
```
* sudo jupyter kernelspec install --name ocaml-jupyter ~/.opam/default/share/jupyter で ~/.opam/default/share/jupyter/kernel.json を /usr/local/share/jupyter/kernels/ocaml-jupyter/kernel.json にコピーしている. 最終的にはOCaml kernelを起動した際これが実行される

* 上記 kernel.json は eval $(opam config env --switch=default --shell=sh) の部分で必要な環境変数をセットしているが, これが opam config env を起動したユーザにしか通用しないパス名を返してくる. 例えば u20000 が起動したなら, OCAML_LD_LIBRARY_PATH=/home/u20000/.opam/...
* ところが u20000 自身が OCaml をインストールしていない限り /home/u20000/.opam/... は無効なディレクトリ. 上記の opam install --yes jupyter を実行したユーザが share という名前だったら必要なファイルは /home/share/.opam/... 以下にある

* 直し方は, 上記の eval $(opam config env --switch=default --shell=sh) であくまで OCAML_LD_LIBRARY_PATH=/home/share/.opam/...  みたいなことが起きるようにする
* そこで以下で kernel.json を修正する
* sed --in-place=.bak -e 's:eval $(opam config env --switch=default --shell=sh):. /home/share/.opam/opam-init/init.sh:g' ~/.opam/default/share/jupyter/kernel.json
* それらは taulec_env/scripts/J65jupyter/ocaml/ocaml.mk に反映
* opam install ... などは share というユーザ名で実行
* /home/share は 0755 (他のユーザにも読めるようにする)

VPython
=========================

* 椎名君, ひぐち君が直した vpython kernel を使う
* それでも from vpython import *; sphere() としてもうまく動かない
* 理由はどうも, 最初に実行したときに /usr/local/share/jupyter/lab/static/ というディレクトリの下に vpython_data というフォルダを作り, その下に何やらデータを書きに行くから
* 仕方がないので以下のようにしておく
```
mkdir -p /usr/local/share/jupyter/lab/static/vpython_data -m 777
```

nbgrader
=========================

* nbgrader_config.py をどこにおけばいいんだろうという感じ
* 各ユーザの ~/.jupyter/nbgrader_config.py におくと読んでくれる模様


taulec_env/user_scripts/problems/all 下のrefactoring
=========================

* 場所を移動
* jupyter.mk
  * compile -- mdを書く方式に統一(sosとそれ以外で分けない)
  * dep -- 不要になる
  * run -- 不要になる
  * ps -- たぶん不要になる
  * kill -- たぶん不要になる?
  * passwd -- 必要
  * workplace -- 必要(passwordを教えるため)
  * watch -- 新しくする
  * cgroup -- 必要
  * nbgrader_config.py を deploy するみたいのが必要
* cmd/exec_cell.py
* cmd/mk_version.py
* cmd/sos_to_ipynb.py -- SOS以外にも対応する, nbgraderに対応する
* cmd/to_ipynb.py

authoring tool仕様
=========================

* ~/public_html/lecture/taulec_env/user_scripts/problems/all/cmd/mk_nb.py
* きっとどこかへ移す
* 例: ~/public_html/lecture/programming_languages/gen/jupyter/nb_src/ex00_jupyter_intro.ml
* 例: ~/public_html/lecture/pmp/homepage/public/jupyter/nb_src/source/pmp00/pmp00_intro.py

config file
=========================

* jupyterhub の config file は 明示的に -f で指定
```
sudo jupyterhub -f ~/.jupyter/jupyterhub_config.py
```
* nbgrader の config file は ~/.jupyter/nbgrader_config.py

* pl, cs, pmp, os, pd のような採点者用アカウントを作る
* 例えば pmp 採点者用アカウントでは nbgrader_config.py で以下のようにする

```
c.CourseDirectory.course_id = 'pmp'
```

```
import os
c.CourseDirectory.root = os.path.expanduser('~/notebooks')
```

```
c.Exchange.root = '/home/share/exchange/pmp'
```

* 学生にも同じものを配る
* 上記の2個目がトリッキー

c.CourseDirectory.root = '~/notebooks'

ではダメだった(Formgraderのタブを開こうとするとエラーになる)

まだ動かない
=========================

* 上記のようにするとなんとか Formgrader のところまではたどり着く
* 学生の側から Assignments -> Fetch するところまでは動く
* しかしそのあと Fetch されたファイルを開こうとすると Page Not Found 的なエラーが出る
* jupyterhub のログを見ると,
```
[W 2021-02-13 13:34:01.866 SingleUserNotebookApp configurable:190] Config option `template_path` not recognized by `HTMLExporter`.  Did you mean one of: `extra_template_paths, template_name, template_paths`?
```
みたいなエラーがでているが本当にこれが関係しているのかは不明
* 上記のエラー自身は, nbconvert を 5.6.0 に戻すことで解消する
```
sudo pip3 install nbconvert==5.6.0
```
* それでも問題は解決しない
* もう一つ怪しい問題があり, pmp00というassignmentをFetchしたときにpmp00というフォルダがホーム直下に出来る. ~/notebooks の下ではなく
* jupyterhubを使わず直接notebook を立ち上げた場合はそんなことはなかった. 何が違うのかを考えると, jupyter-notebook を立ち上げたときの current directory がホームディレクトリになっているからではないかという気がする
* 直接Jupyter notebookを立ち上げた時:
  * 今まで cd ~/notebooks してから Jupyter notebook を立ち上げていた
  * fetch すると ~/notebooks/課題名 というフォルダができてそこにコピーされる (例: ~/notebooks/pmp00)
  * notebookへのリンクは以下の通り https://taulec.zapto.org:10000/tree/pmp00/pmp00_intro.py.ipynb
* Jupyterhub経由の時
  * いろいろ調べて, current directory が home になっており, その状態では諸々がうまく動かないということがわかった
  1. 普通に作った notebooks/a.ipynb というファイルへのリンクは https://taulec.zapto.org:8000/user/ユーザ名/notebooks/a.ipynb のようになる
  2. fetch すると ~/課題名 というフォルダができてそこにコピーされる (例: ~/pmp00)
  3. fetch した課題のファイルを指す URL は https://taulec.zapto.org:8000/user/u21000/pmp00/pmp00_intro.py.ipynb のようになる
* 1. はいかにも ~/ が起点になっているという感じがする. 2.はいかにも Jupyter notebook の current directory が ~/ であることを匂わせる. 3 はパス pmp00/pmp00_intro.py.ipynb が notebook_dir を起点とした相対パスになっているので, 結果的に ~/notebooks/pmp00/pmp00_intro.py.ipynb をアクセスしに行くがそんなファイルはないのでダメとなっている気がする

* 試しに jupyterhub_config.py で c.Spawner.notebook_dir を '' (= ~/) にしてみると, 他の設定をしなくても万事うまく行く

* spawnerの実装 /usr/local/lib/python3.8/dist-packages/jupyterhub/spawner.py を見ると, current directory をそのユーザの home (~/) とすることが決め打たれていることがわかった

```
class LocalProcessSpawner(Spawner):
   ...
   async def start(self):
```
中で
```
        popen_kwargs = dict(
            preexec_fn=self.make_preexec_fn(self.user.name),
            start_new_session=True,  # don't forward signals
            )
        popen_kwargs.update(self.popen_kwargs)
```
となっていて, これがPopenに渡されている.
self.make_preexec_fn の中では, home directory に chdir するということが決め打たれている
```
    def make_preexec_fn(self, name):
        """
        Return a function that can be used to set the user id of the spawned process to user with name `name`
        This function can be safely passed to `preexec_fn` of `Popen`
        """
        return set_user_setuid(name)
```
set_user_setuid(name) 内では
```
ef set_user_setuid(username, chdir=True):
    user = pwd.getpwnam(username)
      ...
    home = user.pw_dir

    def preexec():
        ...
                                                                            
        if chdir:
            _try_setcwd(home)

    return preexec
```
みたいなことになっていて, user の home directory 以外に chdir するということはない

* 従って Jupyterhubから起動した場合, home 以外を current directory とすることはだいぶ無理があるっぽい
* やるとしたら Jupyter notebook が立ち上がってから読み込まれるconfig fileの中で無理矢理 chdir する
* なお, Jupyter notebook の current directory は Terminalを開いたときの current directory

* ということで nbgrader_config.py からそれを無理矢理やることにする

```
import os
c.CourseDirectory.root = os.path.expanduser('~/notebooks')
os.chdir(c.CourseDirectory.root)
```

* なお, このファイル nbgrader_config.py をどこにどう置くか. できれば /home/share/ 下にひとつファイルをおいて残りはそれを symlink で参照する (どうもそれだとうまく行かなかった気がしたが, 勘違いだったようで結局 symlink で問題なさそう)
* nbgrader_config.py の場所は ~/.jupyter 

* 結局 config file は以下の通り
* jupyterhub_config.py (本件に関係するのは最初のひとつだけ): tau ユーザが sudo jupyterhub -f ... で明示的に指定
```
c.Spawner.notebook_dir = '~/notebooks'
c.JupyterHub.ssl_cert = '/etc/letsencrypt/live/taulec.zapto.org/fullchain.pem'
c.JupyterHub.ssl_key = '/etc/letsencrypt/live/taulec.zapto.org/privkey.pem'
```
* nbgrader_config.py  全ユーザの ~/.jupyter 下にコピー
```
c.CourseDirectory.course_id = 'pmp'  # 授業ごとに異なる

import os
c.CourseDirectory.root = os.path.expanduser('~/notebooks')
os.chdir(c.CourseDirectory.root)
```


instructor の設定
=========================

* mkdir ~/.jupyter
* ~/.jupyter/nbgrader_config.py -> /home/share/_jupyter/nbgrader_config_xxx.py
* mkdir notebooks
* cd notebooks
* ln -s ~/public_html/lecture/xxx/jupyter/notebooks/source 

https://github.com/jupyterhub/jupyterhub/issues/314


install jupyter environment
====================

* make will install jupyter notebook and kernels

```
inst_jupyter$ make -n
cd jupyter && make -f jupyter.mk
cd c && make -f c.mk
cd ocaml && make -f ocaml.mk
cd vpython && make -f vpython.mk
cd sos && make -f sos.mk
```

* c : C and shell kernel
* ocaml : OCaml
* vpython : visual python
* sos : script of script (multiple kernels in one page)

* ocaml and sos simply install packages by pip

* c and vpython install extended/bug-fixed kernels

* if you need only some of them, edit this line
```
subdirs := jupyter c ocaml vpython sos
```

* you can choose whether you install it via root (sudo pip3 install ...) or via regular user (pip3 install --user ...) by changing the following lines in each .mk file (c/c.mk, ocaml/ocam.mk, vpython/vpython.mk and sos/sos.mk)

```
#mode?=user
mode?=root
```
