-- Checagens de qualidade de dados. O esperado em produção é ocorrencias = 0 em todas.
-- Conceitos: UNION ALL de checagens, subconsultas correlacionadas e de agregação.
SELECT 'Títulos duplicados (fornecedor + valor + emissão)' AS checagem,
       COUNT(*) AS ocorrencias
FROM (SELECT fornecedor_id, valor, data_emissao
      FROM fato_titulo
      GROUP BY fornecedor_id, valor, data_emissao
      HAVING COUNT(*) > 1) d
UNION ALL
SELECT 'Pagamento anterior à emissão', COUNT(*)
FROM fato_titulo WHERE data_pagamento < data_emissao
UNION ALL
SELECT 'Título em conta fora da vigência', COUNT(*)
FROM fato_titulo t JOIN dim_conta_contabil c ON c.conta_sk = t.conta_sk
WHERE t.data_vencimento NOT BETWEEN c.vigencia_inicio AND c.vigencia_fim
UNION ALL
SELECT 'Lançamento no razão com título inexistente', COUNT(*)
FROM fato_razao r
WHERE r.titulo_id IS NOT NULL
  AND NOT EXISTS (SELECT 1 FROM fato_titulo t WHERE t.titulo_id = r.titulo_id)
UNION ALL
SELECT 'Título com mais de um lançamento no razão', COUNT(*)
FROM (SELECT titulo_id FROM fato_razao WHERE titulo_id IS NOT NULL
      GROUP BY titulo_id HAVING COUNT(*) > 1) m;
