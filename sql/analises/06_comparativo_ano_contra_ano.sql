-- Despesa jan-out 2026 x jan-out 2025 por tipo de despesa (mesmo período = comparação justa).
-- O agrupamento usa tipo_despesa, vindo da dimensão pela chave substituta conta_sk,
-- e NÃO o cod_reduzido, que mudou de significado em 2025 (ver consulta 07).
SELECT
    tipo_despesa,
    SUM(CASE WHEN ano_venc = 2025 THEN valor ELSE 0 END) AS jan_out_2025,
    SUM(CASE WHEN ano_venc = 2026 THEN valor ELSE 0 END) AS jan_out_2026,
    ROUND(100 * (SUM(CASE WHEN ano_venc = 2026 THEN valor ELSE 0 END)
               - SUM(CASE WHEN ano_venc = 2025 THEN valor ELSE 0 END))
          / NULLIF(SUM(CASE WHEN ano_venc = 2025 THEN valor ELSE 0 END), 0), 1) AS variacao_pct
FROM vw_titulo
WHERE mes_venc BETWEEN 1 AND 10
  AND ano_venc IN (2025, 2026)
GROUP BY tipo_despesa
ORDER BY jan_out_2026 DESC;
