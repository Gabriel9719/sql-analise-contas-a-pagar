-- Curva ABC de fornecedores em 2026 (A = até 80% do gasto acumulado, B = até 95%, C = resto).
-- Conceitos: funções de janela com moldura (ROWS UNBOUNDED PRECEDING), SUM() OVER ().
WITH gasto AS (
    SELECT razao_social, SUM(valor) AS total
    FROM vw_titulo
    WHERE ano_venc = 2026
    GROUP BY razao_social
),
acumulado AS (
    SELECT
        razao_social,
        total,
        total / SUM(total) OVER ()                                          AS participacao,
        SUM(total) OVER (ORDER BY total DESC, razao_social
                         ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
          / SUM(total) OVER ()                                              AS pct_acumulado
    FROM gasto
)
SELECT
    razao_social,
    total,
    ROUND(100 * participacao, 2)  AS pct_participacao,
    ROUND(100 * pct_acumulado, 2) AS pct_acumulado,
    CASE WHEN pct_acumulado - participacao < 0.80 THEN 'A'
         WHEN pct_acumulado - participacao < 0.95 THEN 'B'
         ELSE 'C' END             AS classe
FROM acumulado
ORDER BY total DESC;
