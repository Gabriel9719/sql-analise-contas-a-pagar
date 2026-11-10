-- Produtividade da equipe de Contas a Pagar em 2026, ponderada pela complexidade.
-- Pontos por título = peso do grupo de despesa + fator por faixa de valor.
-- Conceitos: CASE por faixas, JOIN com dimensão, RANK() sobre agregação.
WITH pontos AS (
    SELECT
        t.usuario_inclusao,
        t.peso_analise
        + CASE WHEN t.valor <= 1000    THEN 0.10
               WHEN t.valor <= 2000    THEN 0.20
               WHEN t.valor <= 15000   THEN 0.30
               WHEN t.valor <= 100000  THEN 0.40
               ELSE 0.50 END AS pontos
    FROM vw_titulo t
    WHERE t.ano_mes_receb >= '2026-01'
)
SELECT
    u.nome,
    COUNT(*)                                  AS titulos,
    ROUND(SUM(p.pontos), 2)                   AS pontos,
    ROUND(SUM(p.pontos) / COUNT(*), 3)        AS pontos_por_titulo,
    RANK() OVER (ORDER BY SUM(p.pontos) DESC) AS ranking
FROM pontos p
JOIN dim_usuario u ON u.usuario = p.usuario_inclusao
WHERE u.equipe = 'Contas a Pagar'
GROUP BY u.nome
ORDER BY ranking;
