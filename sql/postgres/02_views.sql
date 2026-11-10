-- Camada semântica (PostgreSQL): mesmas colunas da versão SQLite.
DROP VIEW IF EXISTS vw_titulo;
CREATE VIEW vw_titulo AS
SELECT
    t.*,
    f.razao_social, f.grupo_despesa, f.peso_analise,
    p.nome_pa, p.regional,
    c.cod_reduzido, c.conta_completa, c.descricao AS conta_descricao, c.tipo_despesa,
    to_char(t.data_vencimento, 'YYYY-MM')                                  AS ano_mes_venc,
    to_char(t.data_recebimento, 'YYYY-MM')                                 AS ano_mes_receb,
    EXTRACT(YEAR  FROM t.data_vencimento)::int                             AS ano_venc,
    EXTRACT(MONTH FROM t.data_vencimento)::int                             AS mes_venc,
    (t.data_vencimento - t.data_recebimento)                               AS dias_antecedencia,
    (t.data_pagamento  - t.data_vencimento)                                AS dias_atraso,
    ((SELECT valor FROM parametro WHERE chave = 'data_base')::date - t.data_vencimento) AS dias_vencido_data_base
FROM fato_titulo t
JOIN dim_fornecedor     f ON f.fornecedor_id = t.fornecedor_id
JOIN dim_pa             p ON p.pa_id = t.pa_id
JOIN dim_conta_contabil c ON c.conta_sk = t.conta_sk;
