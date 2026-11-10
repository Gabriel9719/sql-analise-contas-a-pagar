-- Camada semântica (SQLite): toda aritmética de datas fica AQUI.
-- As consultas de sql/analises/ usam só esta view e funcionam nos dois bancos.
DROP VIEW IF EXISTS vw_titulo;
CREATE VIEW vw_titulo AS
SELECT
    t.*,
    f.razao_social, f.grupo_despesa, f.peso_analise,
    p.nome_pa, p.regional,
    c.cod_reduzido, c.conta_completa, c.descricao AS conta_descricao, c.tipo_despesa,
    substr(t.data_vencimento, 1, 7)                                              AS ano_mes_venc,
    substr(t.data_recebimento, 1, 7)                                             AS ano_mes_receb,
    CAST(substr(t.data_vencimento, 1, 4) AS INTEGER)                             AS ano_venc,
    CAST(substr(t.data_vencimento, 6, 2) AS INTEGER)                             AS mes_venc,
    CAST(julianday(t.data_vencimento) - julianday(t.data_recebimento) AS INTEGER) AS dias_antecedencia,
    CAST(julianday(t.data_pagamento)  - julianday(t.data_vencimento)  AS INTEGER) AS dias_atraso,
    CAST(julianday((SELECT valor FROM parametro WHERE chave = 'data_base'))
         - julianday(t.data_vencimento) AS INTEGER)                              AS dias_vencido_data_base
FROM fato_titulo t
JOIN dim_fornecedor     f ON f.fornecedor_id = t.fornecedor_id
JOIN dim_pa             p ON p.pa_id = t.pa_id
JOIN dim_conta_contabil c ON c.conta_sk = t.conta_sk;
