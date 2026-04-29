# dbsp

MySQL (v9.3) を Docker Compose で起動するローカル開発環境です。将来的に他のサービスを追加できる構成になっています。

---

## ファイル構成

```
dbsp/
├── docker-compose.yml        # メインの Compose 定義（MySQL サービス定義）
├── .env.example              # 必要な環境変数の一覧（値は空）
├── .env                      # 実際の認証情報（git 管理外）
├── .gitignore                # .env を除外
└── mysql/
    ├── conf.d/
    │   └── my.cnf            # MySQL カスタム設定（文字コード・タイムゾーン等）
    └── initdb.d/
        └── .gitkeep          # 初期化 SQL を置くディレクトリ
```

---

## 各ファイルの役割

| ファイル | 役割 |
|---|---|
| `docker-compose.yml` | MySQL コンテナの定義。将来サービスを追加する際もここに `services:` を追記するだけ |
| `.env.example` | `MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD` 等のキー一覧。実際の値はユーザーが `.env` にコピーして記入 |
| `.gitignore` | `.env`（機密情報）を git 管理から除外 |
| `mysql/conf.d/my.cnf` | `utf8mb4` / `Asia/Tokyo` 等の基本設定。必要に応じて変更 |
| `mysql/initdb.d/` | コンテナ初回起動時に自動実行される `.sql` / `.sh` を置く場所 |

---

## セットアップ・起動手順

### 1. 環境変数ファイルを作成する

```bash
cp .env.example .env
```

`.env` を開き、各変数に値を設定する：

```
MYSQL_ROOT_PASSWORD=（任意のパスワード）
MYSQL_DATABASE=（作成するDB名）
MYSQL_USER=（一般ユーザー名）
MYSQL_PASSWORD=（一般ユーザーのパスワード）
```

### 2. コンテナを起動する

```bash
docker compose up -d
```

### 3. 起動状態を確認する

```bash
docker compose ps
```

### 4. MySQL に接続する

```bash
docker compose exec mysql mysql -u root -p
```

### 5. コンテナを停止する

```bash
docker compose down
```

データボリュームも含めて削除する場合：

```bash
docker compose down -v
```

---

## 将来のサービス追加

新サービスを追加する場合は `docker-compose.yml` の `services:` に追記するだけ：

```yaml
services:
  mysql:
    ...
  app:            # ← 将来追加
    build: .
    depends_on:
      - mysql
```

---

## 設定の詳細

### MySQL バージョン

`mysql:9.3`（2025年時点の最新安定版）

### デフォルト設定（`mysql/conf.d/my.cnf`）

| 項目 | 値 |
|---|---|
| 文字コード | `utf8mb4` |
| 照合順序 | `utf8mb4_unicode_ci` |
| タイムゾーン | `+09:00`（JST） |

### 初期化スクリプト（`mysql/initdb.d/`）

このディレクトリに `.sql` または `.sh` ファイルを置くと、コンテナの**初回起動時**に自動実行されます。
