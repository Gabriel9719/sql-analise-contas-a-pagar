# SQL para análise de Contas a Pagar

![sql](https://img.shields.io/badge/SQL-SQLite%20%7C%20PostgreSQL-336791) ![testes](https://img.shields.io/badge/testes-27%20consultas%20validadas-0A9EDC) ![ci](https://img.shields.io/badge/CI-GitHub%20Actions-2088FF)

Banco de dados dimensional de **Contas a Pagar** (jul/2024 a out/2026, ~3,6 mil títulos) e **11 consultas analíticas** que respondem às perguntas do dia a dia de um financeiro: o que está vencido, quem concentra o gasto, onde a contabilização não bate, como a equipe está produzindo e se os dados são confiáveis.

As consultas são **portáveis**: o mesmo SQL roda em **SQLite** e em **PostgreSQL**, e o CI confere que os dois bancos devolvem **o mesmo resultado** a cada commit.

> **Dados fictícios.** Fornecedores, PAs, usuários e valores são gerados por `scripts/gerar_dados.py`, que também planta problemas reais (duplicidades, títulos pagos sem contabilização, código de conta reutilizado) para as consultas encontrarem.

## Modelo de dados

```mermaid
erDiagram
    dim_fornecedor ||--o{ fato_titulo : fornece
    dim_pa ||--o{ fato_titulo : "centro de custo"
    dim_conta_contabil ||--o{ fato_titulo : classifica
    dim_usuario ||--o{ fato_titulo : inclui
    fato_titulo ||--o| fato_razao : "contabilizado em"
    dim_conta_contabil ||--o{ fato_razao : ""
    fato_titulo {
        int titulo_id PK
        date data_recebimento
        date data_vencimento
        date data_pagamento "NULL = em aberto"
        numeric valor
    }
    dim_conta_contabil {
        int conta_sk PK "chave substituta"
        int cod_reduzido "reutilizado em 2025!"
        date vigencia_inicio
        date vigencia_fim
    }
    fato_razao {
        int lancamento_id PK
        int titulo_id "NULL = ajuste manual"
        numeric valor
    }
```

**Decisão de modelagem:** na reestruturação do plano de contas de 2025, um código reduzido passou a significar outra conta. Agrupar por `cod_reduzido` somaria "telefonia" de 2024 com "limpeza" de 2025. Por isso a dimensão usa uma **chave substituta** (`conta_sk`) com **vigência**, e a consulta 07 demonstra a armadilha.

**Portabilidade:** toda a aritmética de datas, que é diferente em cada banco, fica numa única view (`sql/sqlite/02_views.sql` e `sql/postgres/02_views.sql`, com as mesmas colunas). As consultas de análise usam só SQL padrão.

## Consultas

| # | Pergunta de negócio | Técnicas |
|---|---|---|
| 01 | Quanto está em aberto e há quanto tempo vencido, por regional? (**aging**) | CTE, `CASE` dentro de `SUM` (pivot) |
| 02 | Quantos documentos chegam sem os **3 dias de antecedência** (regra D+3)? | agregação condicional, `NULLIF` |
| 03 | Quais fornecedores concentram 80% do gasto? (**curva ABC**) | `SUM() OVER (ORDER BY … ROWS UNBOUNDED PRECEDING)` |
| 04 | Como o gasto variou mês a mês? | `LAG`, média móvel de 3 meses |
| 05 | Top 3 fornecedores de cada regional | `DENSE_RANK() OVER (PARTITION BY …)` |
| 06 | Jan–out 2026 × jan–out 2025 por tipo de despesa | comparação de períodos equivalentes |
| 07 | Há código de conta reutilizado que distorce comparativos? | `HAVING COUNT(DISTINCT …) > 1` |
| 08 | Todo título pago foi contabilizado com o mesmo valor? | **`FULL OUTER JOIN`**, `COALESCE` |
| 09 | Produtividade da equipe **ponderada pela complexidade** | `CASE` por faixas, `RANK()` |
| 10 | Os dados são confiáveis? (duplicidades, órfãos, vigência) | `UNION ALL` de checagens, `NOT EXISTS` |
| 11 | Quais fornecedores pagamos com atraso? | `HAVING`, média condicional |

### Exemplos de resultado

**03: Curva ABC (2026)**
```
razao_social               | total        | % acumulado | classe
TRANSVALOR LTDA            | 1.684.668,36 | 16,65       | A
CONSERVA MAIS EIRELI       | 1.503.761,10 | 31,51       | A
...
IMOBILIÁRIA CENTRAL LTDA   |   654.704,92 | 83,54       | A
TECNOLOGIA NUVEM AZUL S.A. |   480.351,06 | 88,29       | B
```

**08: Conciliação título × razão**
```
status                | qtd   | valor_titulos | valor_razao
OK                    | 3.577 | 27.347.500,55 | 27.347.500,55
PAGO SEM LANÇAMENTO   |    36 |    298.100,87 |          0,00
LANÇAMENTO SEM TÍTULO |     4 |          0,00 |      2.340,04
VALOR DIVERGENTE      |     1 |      4.830,28 |      4.880,28
```

A saída completa de todas as consultas está em [`docs/resultados_exemplo.txt`](docs/resultados_exemplo.txt).

## Como executar

```bash
pip install -r requirements.txt
python scripts/gerar_dados.py          # CSVs em data/
python scripts/banco.py                # cria o SQLite, carrega e roda as 11 consultas

# PostgreSQL (opcional)
python scripts/banco.py --postgres "postgresql://usuario:senha@localhost:5432/cap"
```

## Testes

```bash
pytest -q                                              # SQLite
PG_DSN="postgresql://usuario:senha@localhost:5432/cap" pytest -q   # + PostgreSQL
```

São 27 testes. Eles conferem que todas as consultas executam e que o aging fecha com o total em aberto. Também verificam se a curva ABC chega a 100% e se a conciliação e a checagem de qualidade encontram **exatamente** os problemas plantados. Por fim, comparam **SQLite × PostgreSQL** linha a linha. O GitHub Actions sobe um PostgreSQL 16 como serviço e roda tudo.

## Estrutura

```
├── sql/
│   ├── 01_schema.sql            # DDL portável (PK, FK, CHECK, índices)
│   ├── sqlite/02_views.sql      # camada semântica por dialeto
│   ├── postgres/02_views.sql
│   └── analises/01..11_*.sql    # consultas comentadas
├── scripts/
│   ├── gerar_dados.py           # dados fictícios com problemas plantados
│   └── banco.py                 # cria, carrega e executa (SQLite/PostgreSQL)
├── tests/test_consultas.py
└── data/*.csv
```

---
Autor: **Gabriel Antônio Ribeiro**, Analista Financeiro · [LinkedIn](https://www.linkedin.com/in/gabriel-ant%C3%B4nio-ribeiro-017808210)
