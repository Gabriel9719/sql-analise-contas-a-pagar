-- Regra D+3: o documento deve chegar ao Contas a Pagar com pelo menos 3 dias
-- antes do vencimento. Abaixo disso é "exceção" (pagamento sob risco de atraso).
-- Conceitos: agregação condicional, percentual com NULLIF, filtro de período.
SELECT
    ano_mes_receb                                                        AS mes_recebimento,
    COUNT(*)                                                             AS titulos,
    SUM(CASE WHEN dias_antecedencia < 3 THEN 1 ELSE 0 END)               AS excecoes_d3,
    ROUND(100.0 * SUM(CASE WHEN dias_antecedencia < 3 THEN 1 ELSE 0 END)
          / NULLIF(COUNT(*), 0), 1)                                      AS pct_excecao,
    SUM(CASE WHEN dias_antecedencia < 3 THEN valor ELSE 0 END)           AS valor_em_excecao
FROM vw_titulo
WHERE ano_mes_receb >= '2026-01'
GROUP BY ano_mes_receb
ORDER BY ano_mes_receb;
