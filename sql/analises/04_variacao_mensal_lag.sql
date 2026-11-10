-- Gasto mensal (por vencimento) em 2026 com variação sobre o mês anterior e média móvel de 3 meses.
-- Conceitos: LAG, AVG() OVER com moldura deslizante, NULLIF para evitar divisão por zero.
WITH mensal AS (
    SELECT ano_mes_venc AS mes, SUM(valor) AS total
    FROM vw_titulo
    WHERE ano_venc = 2026
    GROUP BY ano_mes_venc
)
SELECT
    mes,
    total,
    LAG(total) OVER (ORDER BY mes)                                              AS total_mes_anterior,
    ROUND(100 * (total - LAG(total) OVER (ORDER BY mes))
          / NULLIF(LAG(total) OVER (ORDER BY mes), 0), 1)                       AS variacao_pct,
    ROUND(AVG(total) OVER (ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS media_movel_3m
FROM mensal
ORDER BY mes;
