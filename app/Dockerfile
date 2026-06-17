# 1. ベースとなる公式のPythonイメージを指定
FROM python:3.11-slim

# 2. コンテナ内の作業ディレクトリを設定
WORKDIR /workspace

# 3. Pythonが.pycファイルを書き込むのを防ぐ設定（コンテナを軽量に保つ）
ENV PYTHONDONTWRITEBYTECODE=1
# 4. 標準出力をバッファリングせず、ログをリアルタイムで見られるようにする設定
ENV PYTHONUNBUFFERED=1

# 5. まずパッケージのリストだけをコピー（キャッシュを効かせるため）
COPY requirements.txt .

# 6. パッケージのインストール（キャッシュを汚さないよう--no-cache-dirを付与）
RUN pip install --no-cache-dir --upgrade -r requirements.txt

# 7. アプリケーションのソースコードをコンテナ内にコピー
COPY ./app ./app

# 8. コンテナが起動したときに実行するコマンド（Uvicornの起動）
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]