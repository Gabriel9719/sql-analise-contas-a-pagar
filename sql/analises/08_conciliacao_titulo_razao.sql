-- Conciliação: todo título pago deve ter exatamente um lançamento no razão com o mesmo valor.
-- Conceitos: FULL OUTER JOIN (SQLite 3.39+ / PostgreSQL), COALESCE, classificação por CASE.
WITH pagos AS (
    SELECT titulo_id, valor FROM fato_titulo WHERE data_pagamento IS NOT NULL
),
conciliado AS (
    SELECT
        COALESCE(p.titulo_id, r.titulo_id) AS titulo_id,
        p.valor AS valor_titulo,
        r.valor AS valor_razao,
        CASE
            WHEN r.lancamento_id IS NULL THEN 'PAGO SEM LANÇAMENTO'
            WHEN p.titulo_id IS NULL     THEN 'LANÇAMENTO SEM TÍTULO'
            WHEN p.valor <> r.valor      THEN 'VALOR DIVERGENTE'
            ELSE 'OK'
        END AS status
    FROM pagos p
    FULL OUTER JOIN fato_razao r ON r.titulo_id = p.titulo_id
)
SELECT
    status,
    COUNT(*)                                   AS qtd,
    SUM(COALESCE(valor_titulo, 0))             AS valor_titulos,
    SUM(COALESCE(valor_razao, 0))              AS valor_razao
FROM conciliado
GROUP BY status
ORDER BY qtd DESC;
