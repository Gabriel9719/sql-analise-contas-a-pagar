-- Os 3 maiores fornecedores de cada regional em 2026.
-- Conceitos: DENSE_RANK() com PARTITION BY, filtro sobre resultado de janela via CTE.
WITH ranking AS (
    SELECT
        regional,
        razao_social,
        SUM(valor) AS total,
        DENSE_RANK() OVER (PARTITION BY regional ORDER BY SUM(valor) DESC) AS posicao
    FROM vw_titulo
    WHERE ano_venc = 2026
    GROUP BY regional, razao_social
)
SELECT regional, posicao, razao_social, total
FROM ranking
WHERE posicao <= 3
ORDER BY regional, posicao;
