-- Pontualidade por fornecedor (títulos pagos em 2026, mínimo de 20 títulos).
-- Conceitos: HAVING, média condicional, ordenação por múltiplos critérios.
SELECT
    razao_social,
    COUNT(*)                                                            AS titulos_pagos,
    SUM(CASE WHEN dias_atraso > 0 THEN 1 ELSE 0 END)                    AS pagos_em_atraso,
    ROUND(100.0 * SUM(CASE WHEN dias_atraso > 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct_atraso,
    ROUND(AVG(CASE WHEN dias_atraso > 0 THEN 1.0 * dias_atraso END), 1)  AS media_dias_atraso
FROM vw_titulo
WHERE data_pagamento IS NOT NULL
  AND ano_venc = 2026
GROUP BY razao_social
HAVING COUNT(*) >= 20
ORDER BY pct_atraso DESC, razao_social;
