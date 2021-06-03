---
title: "pydocstyle+bytes型でエラーを出し続けたお話"
emoji: "👏"
type: "tech" # tech: 技術記事 / idea: アイデア
topics: ["python", "flake8", "pydocstyle"]
published: true
---

# はじめに

本日、研究のコードを書いていると急に以下のエラーが発生しました。

利用している研究環境では、 `git commit` 時 `git hook` の `pre-commit` によって `flake8` が実行されるようになっています。
`flake8` には `pydocstyle` のプラグインが設定されており、そのプラグインが以下のエラーを出していました。
commit するときに強制的に lint や flake8 をかけているため、必ず以下のエラーが出てしまい、コミットできませんでした。
flake8 を `pre-commit` から外してもよいのですが、根本的な解決ではないのでちゃんと原因を探しました。

```shell
Traceback (most recent call last):
  File "/Users/ganariya/Library/Caches/pypoetry/virtualenvs/styleworks-zp3epwej-py3.9/bin/flake8", line 8, in <module>
    sys.exit(main())
  File "/Users/ganariya/Library/Caches/pypoetry/virtualenvs/styleworks-zp3epwej-py3.9/lib/python3.9/site-packages/flake8/main/cli.py", line 22, in main
    app.run(argv)
  File "/Users/ganariya/Library/Caches/pypoetry/virtualenvs/styleworks-zp3epwej-py3.9/lib/python3.9/site-packages/flake8/main/application.py", line 363, in run
    self._run(argv)
  File "/Users/ganariya/Library/Caches/pypoetry/virtualenvs/styleworks-zp3epwej-py3.9/lib/python3.9/site-packages/flake8/main/application.py", line 351, in _run
    self.run_checks()
  File "/Users/ganariya/Library/Caches/pypoetry/virtualenvs/styleworks-zp3epwej-py3.9/lib/python3.9/site-packages/flake8/main/application.py", line 264, in run_checks
    self.file_checker_manager.run()
  File "/Users/ganariya/Library/Caches/pypoetry/virtualenvs/styleworks-zp3epwej-py3.9/lib/python3.9/site-packages/flake8/checker.py", line 323, in run
    self.run_serial()
  File "/Users/ganariya/Library/Caches/pypoetry/virtualenvs/styleworks-zp3epwej-py3.9/lib/python3.9/site-packages/flake8/checker.py", line 307, in run_serial
    checker.run_checks()
  File "/Users/ganariya/Library/Caches/pypoetry/virtualenvs/styleworks-zp3epwej-py3.9/lib/python3.9/site-packages/flake8/checker.py", line 589, in run_checks
    self.run_ast_checks()
  File "/Users/ganariya/Library/Caches/pypoetry/virtualenvs/styleworks-zp3epwej-py3.9/lib/python3.9/site-packages/flake8/checker.py", line 494, in run_ast_checks
    for (line_number, offset, text, _) in runner:
  File "/Users/ganariya/Library/Caches/pypoetry/virtualenvs/styleworks-zp3epwej-py3.9/lib/python3.9/site-packages/flake8_docstrings.py", line 142, in run
    for error in self._check_source():
  File "/Users/ganariya/Library/Caches/pypoetry/virtualenvs/styleworks-zp3epwej-py3.9/lib/python3.9/site-packages/flake8_docstrings.py", line 127, in _check_source
    for err in self._call_check_source():
  File "/Users/ganariya/Library/Caches/pypoetry/virtualenvs/styleworks-zp3epwej-py3.9/lib/python3.9/site-packages/pydocstyle/checker.py", line 149, in check_source
    error = this_check(
  File "/Users/ganariya/Library/Caches/pypoetry/virtualenvs/styleworks-zp3epwej-py3.9/lib/python3.9/site-packages/pydocstyle/checker.py", line 235, in check_one_liners
    lines = ast.literal_eval(docstring).split('\n')
TypeError: a bytes-like object is required, not 'str'
```

https://github.com/PyCQA/pydocstyle/blob/b174899473013ab2408eb758e36bb5cf17bbfa17/src/pydocstyle/checker.py#L235

# 原因を探る

エラーコードを読むと `TypeError: a bytes-like object is required, not 'str'` と出ています。
そのため、バイト列と文字列が混ざってしまったため起こったエラーだと考えます。

Python ではバイナリデータを直接扱うことができます。
たとえば、なにかしらの文字列を utf-8 などでバイナリに変換すると `\xe3\x81\x82` のようになります。
`\x` が 16 進数であることを表しています。

よって、これらの分析からバイト列と文字列が混ざってしまうようなコードのバグを探しました。
しかし、どんなに重要そうなコード（編集していた肝である箇所）を睨んでも bytes と str が混ざるようなコードはありません。

# もっと原因を探る

何度も見直しましたが、間違っている箇所が見当たりません。
**ついに諦めようとしたとき、ファイルの先頭が目に留まりました。**

```python
b"""Research Code."""
import  os
import  json

# 以下 200行ぐらいのモジュール
```

`b` がついていました（**驚愕**）。

文字列の先頭に `b` をつけると、バイト列として解釈されます。
そして、 `pydocstring` では docstring が str で書かれていることを前提としています。
そのため、 bytes str の混合エラーが起こっていたようです。

# 学び

- エラーを睨むときは全体を通して読もう（重要そうな箇所はより丁寧に）
- バイト列の仕組みを理解した
