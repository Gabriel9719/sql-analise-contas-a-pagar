-- Aging dos títulos em aberto na data-base, por regional.
-- Conceitos: CTE, CASE em agregação (pivot manual), filtro por NULL.
WITH aberto AS (
    SELECT regional, valor, dias_vencido_data_base AS dias
    FROM vw_titulo
    WHERE data_pagamento IS NULL
)
SELECT
    regional,
    SUM(CASE WHEN dias <= 0              THEN valor ELSE 0 END) AS a_vencer,
    SUM(CASE WHEN dias BETWEEN 1 AND 30  THEN valor ELSE 0 END) AS vencido_1_30,
    SUM(CASE WHEN dias BETWEEN 31 AND 60 THEN valor ELSE 0 END) AS vencido_31_60,
    SUM(CASE WHEN dias BETWEEN 61 AND 90 THEN valor ELSE 0 END) AS vencido_61_90,
    SUM(CASE WHEN dias > 90              THEN valor ELSE 0 END) AS vencido_90_mais,
    SUM(valor)                                                  AS total_em_aberto,
    COUNT(*)                                                    AS qtd_titulos
FROM aberto
GROUP BY regional
ORDER BY total_em_aberto DESC;
