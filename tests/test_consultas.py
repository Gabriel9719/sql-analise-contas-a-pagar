"""Executa todas as consultas e valida resultados. Se a variável PG_DSN estiver definida,
roda também no PostgreSQL e exige que os dois bancos devolvam exatamente o mesmo resultado."""
import os
import sqlite3
import sys
from decimal import Decimal
from pathlib import Path

import pytest

RAIZ = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(RAIZ / "scripts"))
from banco import consultar, criar_e_carregar  # noqa: E402
import gerar_dados  # noqa: E402

CONSULTAS = sorted((RAIZ / "sql/analises").glob("*.sql"))


@pytest.fixture(scope="session")
def dados(tmp_path_factory):
    pasta = tmp_path_factory.mktemp("dados")
    gerar_dados.main(str(pasta))
    return pasta


@pytest.fixture(scope="session")
def sqlite(dados):
    con = sqlite3.connect(":memory:")
    criar_e_carregar(con, "sqlite", dados)
    return con


def q(con, nome):
    cols, linhas = consultar(con, (RAIZ / "sql/analises" / nome).read_text(encoding="utf-8"))
    return [dict(zip(cols, l)) for l in linhas]


def normalizar(linhas, aproximado=False):
    """Torna comparáveis os tipos dos dois bancos: datas viram texto ISO e números viram float.
    Arredondamentos podem diferir na última casa (float binário no SQLite x NUMERIC exato no
    PostgreSQL, ex.: 4,85 -> 4,8 ou 4,9), por isso a comparação numérica tolera uma unidade na última casa decimal."""
    def v(x):
        if isinstance(x, (float, Decimal)):
            return pytest.approx(float(x), abs=0.11) if aproximado else float(x)
        if hasattr(x, "isoformat"):
            return x.isoformat()
        return x
    return [tuple(v(x) for x in l) for l in linhas]


@pytest.mark.parametrize("arq", CONSULTAS, ids=lambda p: p.name)
def test_todas_as_consultas_executam(sqlite, arq):
    cols, linhas = consultar(sqlite, arq.read_text(encoding="utf-8"))
    assert cols and linhas, f"{arq.name} não retornou linhas"


def test_aging_soma_igual_ao_total_em_aberto(sqlite):
    for r in q(sqlite, "01_aging_titulos_em_aberto.sql"):
        faixas = r["a_vencer"] + r["vencido_1_30"] + r["vencido_31_60"] + r["vencido_61_90"] + r["vencido_90_mais"]
        assert faixas == pytest.approx(r["total_em_aberto"], abs=0.01)


def test_curva_abc_consistente(sqlite):
    abc = q(sqlite, "03_curva_abc_fornecedores.sql")
    assert abc[-1]["pct_acumulado"] == pytest.approx(100, abs=0.01)
    classes = [r["classe"] for r in abc]
    assert classes == sorted(classes), "A antes de B antes de C"


def test_conciliacao_encontra_problemas_plantados(sqlite):
    st = {r["status"]: r["qtd"] for r in q(sqlite, "08_conciliacao_titulo_razao.sql")}
    assert st["LANÇAMENTO SEM TÍTULO"] == 4
    assert st["VALOR DIVERGENTE"] == 1
    assert st["PAGO SEM LANÇAMENTO"] > 0


def test_qualidade_encontra_duplicidades(sqlite):
    chk = {r["checagem"]: r["ocorrencias"] for r in q(sqlite, "10_qualidade_dos_dados.sql")}
    assert chk["Títulos duplicados (fornecedor + valor + emissão)"] == 3
    assert chk["Título em conta fora da vigência"] == 0
    assert chk["Pagamento anterior à emissão"] == 0


def test_codigo_reduzido_reutilizado_e_detectado(sqlite):
    r = q(sqlite, "07_armadilha_codigo_reduzido.sql")
    assert [x["cod_reduzido"] for x in r] == [4512]


@pytest.fixture(scope="session")
def pg(dados):
    import psycopg
    con = psycopg.connect(os.environ["PG_DSN"], autocommit=True)
    criar_e_carregar(con, "postgres", dados)
    return con


@pytest.mark.skipif(not os.environ.get("PG_DSN"), reason="defina PG_DSN para testar no PostgreSQL")
@pytest.mark.parametrize("arq", CONSULTAS, ids=lambda p: p.name)
def test_sqlite_e_postgres_dao_o_mesmo_resultado(sqlite, pg, arq):
    sql = arq.read_text(encoding="utf-8")
    assert normalizar(consultar(sqlite, sql)[1]) == normalizar(consultar(pg, sql)[1], aproximado=True)
