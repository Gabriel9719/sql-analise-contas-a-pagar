"""Cria o banco (SQLite ou PostgreSQL), carrega os CSVs e executa as consultas de sql/analises/.

    python scripts/banco.py                       # SQLite em data/contas_a_pagar.db
    python scripts/banco.py --postgres "postgresql://usuario:senha@localhost:5432/cap"
"""
from __future__ import annotations

import argparse
import csv
import sqlite3
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
ORDEM = ["parametro", "dim_pa", "dim_fornecedor", "dim_conta_contabil", "dim_usuario", "fato_titulo", "fato_razao"]


def conectar(postgres: str | None, db: Path):
    if postgres:
        import psycopg
        return psycopg.connect(postgres, autocommit=True), "postgres"
    return sqlite3.connect(db), "sqlite"


def executar_script(con, motor: str, caminho: Path) -> None:
    sql = caminho.read_text(encoding="utf-8")
    if motor == "sqlite":
        con.executescript(sql)
    else:
        with con.cursor() as cur:
            cur.execute(sql)


def criar_e_carregar(con, motor: str, dados: Path = RAIZ / "data") -> None:
    executar_script(con, motor, RAIZ / "sql/01_schema.sql")
    ph = "?" if motor == "sqlite" else "%s"
    cur = con.cursor()
    for tabela in ORDEM:
        with (dados / f"{tabela}.csv").open(encoding="utf-8") as f:
            r = csv.reader(f)
            cab = next(r)
            linhas = [[v if v != "" else None for v in linha] for linha in r]
        cur.executemany(f"INSERT INTO {tabela} ({', '.join(cab)}) VALUES ({', '.join([ph] * len(cab))})", linhas)
    if motor == "sqlite":
        con.commit()
    executar_script(con, motor, RAIZ / f"sql/{motor}/02_views.sql")


def consultar(con, sql: str) -> tuple[list[str], list[tuple]]:
    cur = con.cursor()
    cur.execute(sql)
    cols = [d[0] for d in cur.description]
    return cols, cur.fetchall()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--postgres", help="string de conexão PostgreSQL (opcional)")
    ap.add_argument("--db", type=Path, default=RAIZ / "data/contas_a_pagar.db")
    ap.add_argument("--mostrar", type=int, default=8, help="linhas exibidas por consulta")
    a = ap.parse_args()
    con, motor = conectar(a.postgres, a.db)
    criar_e_carregar(con, motor)
    for arq in sorted((RAIZ / "sql/analises").glob("*.sql")):
        cols, linhas = consultar(con, arq.read_text(encoding="utf-8"))
        print(f"\n=== {arq.name} ({len(linhas)} linhas) [{motor}]")
        print(" | ".join(cols))
        for l in linhas[: a.mostrar]:
            print(" | ".join(f"{v:,.2f}" if isinstance(v, float) else str(v) for v in l))


if __name__ == "__main__":
    main()
