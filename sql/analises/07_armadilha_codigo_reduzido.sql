-- Diagnóstico: códigos reduzidos reutilizados com significados diferentes ao longo do tempo.
-- Agrupar por cod_reduzido somaria "telefonia" de 2024 com "limpeza" de 2025 na mesma linha.
SELECT
    c.cod_reduzido,
    COUNT(DISTINCT c.conta_sk)  AS contas_distintas,
    MIN(c.descricao)            AS descricao_1,
    MAX(c.descricao)            AS descricao_2,
    MIN(c.vigencia_inicio)      AS primeira_vigencia,
    MAX(c.vigencia_inicio)      AS ultima_vigencia,
    SUM(t.valor)                AS valor_que_seria_misturado
FROM dim_conta_contabil c
JOIN fato_titulo t ON t.conta_sk = c.conta_sk
GROUP BY c.cod_reduzido
HAVING COUNT(DISTINCT c.conta_sk) > 1;
