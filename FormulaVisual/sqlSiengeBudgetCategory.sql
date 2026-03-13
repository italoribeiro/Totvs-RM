SELECT P.CODCOLIGADA,
       ISNULL(G.CODEXTERNO, 'NAOINFORMADO')                                            AS debtorId,
       CASE
         WHEN F.NROPERIODO = '1' THEN 'ADF'
         WHEN F.NROPERIODO = '2' THEN 'FOLH'
         WHEN F.NROPERIODO = '3' THEN 'FERI'
         WHEN F.NROPERIODO = '4' THEN 'RESC'
         ELSE 'NAOINFORMADO'
       END                                                                             AS documentIdentificationId,
       CASE
         WHEN F.NROPERIODO = '1' THEN '4'
         WHEN F.NROPERIODO = '2' THEN '4'
         WHEN F.NROPERIODO = '3' THEN '41'
         WHEN F.NROPERIODO = '4' THEN '42'
         ELSE 'NAOINFORMADO'
       END                                                                             AS creditorId,
       CASE
         WHEN F.NROPERIODO = '1' THEN '2010201'
         WHEN F.NROPERIODO = '2' THEN '2010201'
         WHEN F.NROPERIODO = '3' THEN '2010202'
         WHEN F.NROPERIODO = '4' THEN '2010213'
         ELSE 'NAOINFORMADO'
       END                                                                             AS paymentCategoriesId,
       P.CODSECAO,
       S.DESCRICAO                                                                     AS nomeSecao,
       Cast(SS.COSTCENTERID AS VARCHAR(255))                                           AS costCenterId,
       -- NOVA COLUNA: Calcula a porcentagem PROPORCIONAL ao valor líquido
       -- Pega o líquido desta linha, divide pelo líquido TOTAL da consulta e multiplica por 100.
       Cast(( ( Sum(CASE
                      WHEN E.PROVDESCBASE = 'P' THEN F.VALOR
                      ELSE 0
                    END) - Sum(CASE
                                 WHEN E.PROVDESCBASE = 'D' THEN F.VALOR
                                 ELSE 0
                               END) ) / NULLIF(Sum(Sum(CASE
                                                         WHEN E.PROVDESCBASE = 'P' THEN F.VALOR
                                                         ELSE 0
                                                       END) - Sum(CASE
                                                                    WHEN E.PROVDESCBASE = 'D' THEN F.VALOR
                                                                    ELSE 0
                                                                  END))
                                                 OVER(), 0) ) * 100 AS DECIMAL(18, 6)) AS percentage,
       Sum(CASE
             WHEN E.PROVDESCBASE = 'P' THEN F.VALOR
             ELSE 0
           END)                                                                        AS TOTAL_PROVENTOS,
       Sum(CASE
             WHEN E.PROVDESCBASE = 'D' THEN F.VALOR
             ELSE 0
           END)                                                                        AS TOTAL_DESCONTOS,
       Sum(CASE
             WHEN E.PROVDESCBASE = 'P' THEN F.VALOR
             ELSE 0
           END) - Sum(CASE
                        WHEN E.PROVDESCBASE = 'D' THEN F.VALOR
                        ELSE 0
                      END)                                                             AS VALOR_LIQUIDO
FROM   PFFINANC F (NOLOCK)
       INNER JOIN PFUNC P (NOLOCK)
               ON F.CODCOLIGADA = P.CODCOLIGADA
                  AND F.CHAPA = P.CHAPA
       INNER JOIN PSECAO S (NOLOCK)
               ON P.CODCOLIGADA = S.CODCOLIGADA
                  AND P.CODSECAO = S.CODIGO
       INNER JOIN PEVENTO E (NOLOCK)
               ON F.CODCOLIGADA = E.CODCOLIGADA
                  AND F.CODEVENTO = E.CODIGO
       INNER JOIN GCOLIGADA G
               ON G.CODCOLIGADA = F.CODCOLIGADA
       INNER JOIN PSECAOCOMPL SS (NOLOCK)
               ON SS.CODCOLIGADA = S.CODCOLIGADA
                  AND SS.CODIGO = S.CODIGO
WHERE  F.CODCOLIGADA = :CODCOLIGADA
       AND F.ANOCOMP = :ANOCOMP
       AND F.MESCOMP = :MESCOMP
       AND F.NROPERIODO = :NROPERIODO
       AND E.PROVDESCBASE IN ( 'P', 'D' )
GROUP  BY P.CODCOLIGADA,
          G.CODEXTERNO,
          P.CODSECAO,
          S.DESCRICAO,
          F.NROPERIODO,
          Cast(SS.COSTCENTERID AS VARCHAR(255))
ORDER  BY P.CODCOLIGADA,
          P.CODSECAO;

/*
SELECT P.CODCOLIGADA,
       ISNULL(G.CODEXTERNO, 'NAOINFORMADO')  AS debtorId,
       CASE
         WHEN F.NROPERIODO = '1' THEN 'ADF'
         WHEN F.NROPERIODO = '2' THEN 'FOLH'
         WHEN F.NROPERIODO = '3' THEN 'FERI'
         WHEN F.NROPERIODO = '4' THEN 'RESC'
         ELSE 'NAOINFORMADO'
       END                                   AS documentIdentificationId,
       CASE
         WHEN F.NROPERIODO = '1' THEN '4'
         WHEN F.NROPERIODO = '2' THEN '4'
         WHEN F.NROPERIODO = '3' THEN '41'
         WHEN F.NROPERIODO = '4' THEN '42'
         ELSE 'NAOINFORMADO'
       END                                   AS CREDITORID,
       CASE
         WHEN F.NROPERIODO = '1' THEN '2010201'
         WHEN F.NROPERIODO = '2' THEN '2010201'
         WHEN F.NROPERIODO = '3' THEN '2010202'
         WHEN F.NROPERIODO = '4' THEN '2010213'
         ELSE 'NAOINFORMADO'
       END                                   AS paymentCategoriesId,
       P.CODSECAO,
       S.DESCRICAO                           AS NOME_SECAO,
       Cast(SS.COSTCENTERID AS VARCHAR(255)) AS COSTCENTERID,
      
       Sum(CASE
             WHEN E.PROVDESCBASE = 'P' THEN F.VALOR
             ELSE 0
           END)                              AS TOTAL_PROVENTOS,
       Sum(CASE
             WHEN E.PROVDESCBASE = 'D' THEN F.VALOR
             ELSE 0
           END)                              AS TOTAL_DESCONTOS,
       Sum(CASE
             WHEN E.PROVDESCBASE = 'P' THEN F.VALOR
             ELSE 0
           END) - Sum(CASE
                        WHEN E.PROVDESCBASE = 'D' THEN F.VALOR
                        ELSE 0
                      END)                   AS VALOR_LIQUIDO
FROM   PFFINANC F (NOLOCK)
       INNER JOIN PFUNC P (NOLOCK)
               ON F.CODCOLIGADA = P.CODCOLIGADA
                  AND F.CHAPA = P.CHAPA
       INNER JOIN PSECAO S (NOLOCK)
               ON P.CODCOLIGADA = S.CODCOLIGADA
                  AND P.CODSECAO = S.CODIGO
       INNER JOIN PEVENTO E (NOLOCK)
               ON F.CODCOLIGADA = E.CODCOLIGADA
                  AND F.CODEVENTO = E.CODIGO
       INNER JOIN GCOLIGADA G
               ON G.CODCOLIGADA = F.CODCOLIGADA
       INNER JOIN PSECAOCOMPL SS (NOLOCK)
               ON SS.CODCOLIGADA = S.CODCOLIGADA
                  AND SS.CODIGO = S.CODIGO
WHERE  F.CODCOLIGADA = :CODCOLIGADA
       AND F.ANOCOMP = :ANOCOMP
       AND F.MESCOMP = :MESCOMP
       AND F.NROPERIODO = :NROPERIODO
       AND E.PROVDESCBASE IN ( 'P', 'D' )
GROUP  BY P.CODCOLIGADA,
          G.CODEXTERNO,
          P.CODSECAO,
          S.DESCRICAO,
          F.NROPERIODO,
          Cast(SS.COSTCENTERID AS VARCHAR(255))
ORDER  BY P.CODCOLIGADA,
          P.CODSECAO; 
*/
