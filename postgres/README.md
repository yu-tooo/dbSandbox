# 役割

このディレクトリ(`./postgres/`)はPostgreSQLの学習環境に関するファイルを置くことを目的としています。

- 学習で使用するデータ（CSVなど）は `./postgres/data/` に配置する
- 必要に応じて、テーブル作成などの初期化SQLは `./postgres/initdb.d/` に配置する（コンテナ初回起動時に自動実行される）


## ディレクトリ構成

| ディレクトリ | 役割 |
|---|---|
| `./postgres/data/` | 学習で使う投入用データ（CSVなど） |
| `./postgres/initdb.d/` | コンテナ初回起動時に実行される初期化SQL（テーブル作成など） |

## 運用手順

### 注意：`initdb.d/` は初回起動時のみ自動実行される

`./postgres/initdb.d/*.sql` は **`postgres_data` ボリュームが空のとき（＝初回 `docker compose up`）にしか実行されません**。
すでにボリュームが存在している状態で新しいSQLを `initdb.d/` に追加しても、`docker compose up -d` だけでは反映されません。

そのため、運用としては次の2パターンを使い分けます。

### A. 手動でSQLファイルを当てる（既存データを残したい場合）

新しく `initdb.d/` にDDLを追加した、または既存DBにスキーマを追加したい場合に使います。
DDLが `IF NOT EXISTS` で書かれていれば、何度実行しても安全です。

やり方は2パターンあります。お好みでどちらでもOKです。

#### A-1. ホスト側のファイルを標準入力で流し込む

ホスト側のシェルでファイルを開き、その中身を `docker compose exec` の標準入力に流し込みます。
**プロジェクトルート（`./postgres/...` が見えるディレクトリ）で実行してください。**

```bash
docker compose exec -T postgres \
  psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  < ./postgres/initdb.d/02_address2.sql
```

各オプションの意味：

| 部分 | 意味 |
|---|---|
| `docker compose exec` | 起動中のコンテナ内でコマンドを実行する |
| `-T` | TTYを割り当てない（標準入力からSQLファイルを流し込むため必須） |
| `postgres` | `docker-compose.yml` で定義したサービス名 |
| `psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"` | `.env` で指定したユーザー / DBに接続するpsql |
| `< ./postgres/initdb.d/02_address2.sql` | **ホスト側**のファイルの中身を標準入力に流し込む |

> `$POSTGRES_USER` / `$POSTGRES_DB` はホスト側のシェルで展開されるため、ホスト側の環境変数として読み込んでおく必要があります。
> `.env` を読ませたい場合は `set -a; source .env; set +a` などで事前にエクスポートしてください。

#### A-2. コンテナ内のマウントパスを `psql -f` で読み込む

`./postgres/initdb.d/` は `docker-compose.yml` で **`/docker-entrypoint-initdb.d`** にマウントされているので、コンテナ内から直接ファイルを指定できます。
標準入力を使わないので `-T` は不要、ホスト側のカレントディレクトリにも依存しません。

```bash
docker compose exec postgres \
  psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -f /docker-entrypoint-initdb.d/02_address2.sql
```

| 部分 | 意味 |
|---|---|
| `-f /docker-entrypoint-initdb.d/02_address2.sql` | psql に **コンテナ内**のファイルパスを直接読み込ませる |

> `/docker-entrypoint-initdb.d` はホストの `./postgres/initdb.d` がマウントされたコンテナ内パスです（`docker-compose.yml` 参照）。

#### データの手動投入

データを手動で投入する場合は、サーバ側 COPY を使うのが手軽です：

```sql
COPY address FROM '/var/lib/postgresql/mnt_data/address.csv' WITH (FORMAT csv);
```

> `/var/lib/postgresql/mnt_data` はホストの `./postgres/data` がコンテナ内にマウントされたパスです（`docker-compose.yml` 参照）。

### B. ボリュームを削除して作り直す（完全リセットしたい場合）

学習中にスキーマを変更した、または initdb.d の内容を全部きれいに反映し直したい場合に使います。
**ボリューム上のデータは全部消えるので、必要なものは事前にバックアップしてください。**

```bash
docker compose down -v
docker compose up -d
```

| コマンド | 意味 |
|---|---|
| `docker compose down -v` | コンテナを停止・削除し、`-v` で**名前付きボリュームも削除**する |
| `docker compose up -d` | コンテナを起動。ボリュームが空なので `initdb.d/*.sql` がアルファベット順に自動実行される |

実行後、初期化が走ったかどうかは以下で確認できます：

```bash
docker compose logs postgres | grep -i "initdb"
```

`running /docker-entrypoint-initdb.d/01_address.sql` のようなログが出ていれば成功です。
