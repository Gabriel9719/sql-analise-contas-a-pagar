-- =============================================================================
-- Modelo estrela de Contas a Pagar (dados fictícios)
-- DDL portável: roda sem alterações em SQLite 3.39+ e PostgreSQL 13+
-- =============================================================================
DROP VIEW IF EXISTS vw_titulo;
DROP TABLE IF EXISTS fato_razao;
DROP TABLE IF EXISTS fato_titulo;
DROP TABLE IF EXISTS dim_usuario;
DROP TABLE IF EXISTS dim_conta_contabil;
DROP TABLE IF EXISTS dim_fornecedor;
DROP TABLE IF EXISTS dim_pa;
DROP TABLE IF EXISTS parametro;

CREATE TABLE parametro (
    chave  VARCHAR(30) PRIMARY KEY,
    valor  VARCHAR(100) NOT NULL
);

CREATE TABLE dim_pa (
    pa_id     INTEGER PRIMARY KEY,
    nome_pa   VARCHAR(40) NOT NULL,
    regional  VARCHAR(20) NOT NULL
);

CREATE TABLE dim_fornecedor (
    fornecedor_id  INTEGER PRIMARY KEY,
    razao_social   VARCHAR(80) NOT NULL,
    cnpj           VARCHAR(18) NOT NULL,
    grupo_despesa  VARCHAR(50) NOT NULL,
    peso_analise   NUMERIC(4,2) NOT NULL          -- complexidade do lançamento (produtividade)
);

-- Chave substituta (conta_sk): o código reduzido foi REUTILIZADO na reestruturação
-- do plano de contas de 2025, então cod_reduzido NÃO é chave confiável entre anos.
CREATE TABLE dim_conta_contabil (
    conta_sk         INTEGER PRIMARY KEY,
    cod_reduzido     INTEGER NOT NULL,
    conta_completa   VARCHAR(20) NOT NULL,
    descricao        VARCHAR(60) NOT NULL,
    tipo_despesa     VARCHAR(30) NOT NULL,
    vigencia_inicio  DATE NOT NULL,
    vigencia_fim     DATE NOT NULL
);

CREATE TABLE dim_usuario (
    usuario  VARCHAR(20) PRIMARY KEY,
    nome     VARCHAR(60) NOT NULL,
    equipe   VARCHAR(30) NOT NULL
);

CREATE TABLE fato_titulo (
    titulo_id         INTEGER PRIMARY KEY,
    fornecedor_id     INTEGER NOT NULL REFERENCES dim_fornecedor (fornecedor_id),
    pa_id             INTEGER NOT NULL REFERENCES dim_pa (pa_id),
    conta_sk          INTEGER NOT NULL REFERENCES dim_conta_contabil (conta_sk),
    usuario_inclusao  VARCHAR(20) NOT NULL REFERENCES dim_usuario (usuario),
    data_emissao      DATE NOT NULL,
    data_recebimento  DATE NOT NULL,
    data_vencimento   DATE NOT NULL,
    data_pagamento    DATE,                       -- NULL = em aberto
    valor             NUMERIC(14,2) NOT NULL CHECK (valor > 0)
);

CREATE TABLE fato_razao (
    lancamento_id    INTEGER PRIMARY KEY,
    data_lancamento  DATE NOT NULL,
    conta_sk         INTEGER NOT NULL REFERENCES dim_conta_contabil (conta_sk),
    historico        VARCHAR(120) NOT NULL,
    valor            NUMERIC(14,2) NOT NULL,
    titulo_id        INTEGER                      -- NULL = lançamento manual sem título
);

CREATE INDEX ix_titulo_vencimento ON fato_titulo (data_vencimento);
CREATE INDEX ix_titulo_fornecedor ON fato_titulo (fornecedor_id);
CREATE INDEX ix_titulo_pagamento  ON fato_titulo (data_pagamento);
CREATE INDEX ix_razao_titulo      ON fato_razao (titulo_id);
