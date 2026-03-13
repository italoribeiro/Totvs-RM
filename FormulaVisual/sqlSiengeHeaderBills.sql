SELECT P.CODCOLIGADA,
       ISNULL(G.CODEXTERNO, 'NAOINFORMADO')             AS debtorId,
       FORMAT(Getdate(), 'yyyy-MM-dd')                  AS issueDate,
       '1'                                              AS installmentsNumber,
       '0'                                              AS indexId,
       FORMAT(Getdate(), 'yyyy-MM-dd')                  AS baseDate,
       FORMAT(Dateadd(DAY, 3, Getdate()), 'yyyy-MM-dd') AS dueDate,
       FORMAT(Getdate(), 'yyyy-MM-01')                  AS billDate,
       
       -- ADICIONADO: Campo documentNumber (Obrigatório para o JSON)
       -- Estou concatenando a sigla + mês + ano para formar o número do documento
       CONCAT(
           CASE
             WHEN F.NROPERIODO = '1' THEN 'ADF'
             WHEN F.NROPERIODO = '2' THEN 'FOLH'
             WHEN F.NROPERIODO = '3' THEN 'FERI'
             WHEN F.NROPERIODO = '4' THEN 'RESC'
             ELSE 'DOC'
           END, 
           F.MESCOMP, F.ANOCOMP
       )                                                AS documentNumber,

       -- ADICIONADO: Campo discount (Obrigatório para o JSON, mandando 0)
       0                                                AS discount,

       CASE
         WHEN F.NROPERIODO = '1' THEN 'ADF'
         WHEN F.NROPERIODO = '2' THEN 'FOLH'
         WHEN F.NROPERIODO = '3' THEN 'FERI'
         WHEN F.NROPERIODO = '4' THEN 'RESC'
         ELSE 'NAOINFORMADO'
       END                                              AS documentIdentificationId,
       F.ANOCOMP                                        AS ANOCOMP,
       F.MESCOMP                                        AS MESCOMP,
       CASE
         WHEN F.NROPERIODO = '1' THEN '4'
         WHEN F.NROPERIODO = '2' THEN '4'
         WHEN F.NROPERIODO = '3' THEN '41'
         WHEN F.NROPERIODO = '4' THEN '42'
         ELSE 'NAOINFORMADO'
       END                                              AS creditorId,
       Sum(CASE
             WHEN E.PROVDESCBASE = 'P' THEN F.VALOR
             ELSE 0
           END)                                         AS TOTAL_PROVENTOS,
       Sum(CASE
             WHEN E.PROVDESCBASE = 'D' THEN F.VALOR
             ELSE 0
           END)                                         AS TOTAL_DESCONTOS,
       Sum(CASE
             WHEN E.PROVDESCBASE = 'P' THEN F.VALOR
             ELSE 0
           END) - Sum(CASE
                         WHEN E.PROVDESCBASE = 'D' THEN F.VALOR
                         ELSE 0
                       END)                             AS totalInvoiceAmount,
       CONCAT(CASE
                WHEN F.NROPERIODO = '1' THEN 'FOLHA ADIANT'
                WHEN F.NROPERIODO = '2' THEN 'FOLHA MENSAL'
                WHEN F.NROPERIODO = '3' THEN 'FOLHA FERIAS'
                WHEN F.NROPERIODO = '4' THEN 'RESCIS'
                ELSE 'OUTROS'
              END, ' ', 
       F.MESCOMP, '/', F.ANOCOMP)                       AS notes
FROM   PFFINANC F (NOLOCK)
       INNER JOIN PFUNC P (NOLOCK)
               ON F.CODCOLIGADA = P.CODCOLIGADA
                  AND F.CHAPA = P.CHAPA
       INNER JOIN PEVENTO E (NOLOCK)
               ON F.CODCOLIGADA = E.CODCOLIGADA
                  AND F.CODEVENTO = E.CODIGO
       INNER JOIN GCOLIGADA G (NOLOCK)
               ON G.CODCOLIGADA = F.CODCOLIGADA
WHERE  F.CODCOLIGADA = :CODCOLIGADA
       AND F.ANOCOMP = :ANOCOMP
       AND F.MESCOMP = :MESCOMP
       AND F.NROPERIODO = :NROPERIODO
       AND E.PROVDESCBASE IN ( 'P', 'D' )
GROUP  BY P.CODCOLIGADA,
          G.CODEXTERNO,
          F.NROPERIODO,
          F.ANOCOMP,
          F.MESCOMP;

/*
SELECT P.CODCOLIGADA,
       ISNULL(G.CODEXTERNO, 'NAOINFORMADO')             AS debtorId,
       FORMAT(Getdate(), 'yyyy-MM-dd')                  AS issueDate,
       '1 '                                             AS installmentsNumber,
       '0'                                              AS indexId,
       FORMAT(Getdate(), 'yyyy-MM-dd')                  AS baseDate,
       FORMAT(Dateadd(DAY, 3, Getdate()), 'yyyy-MM-dd') AS dueDate,
       FORMAT(Getdate(), 'yyyy-MM-01')                  AS billDate,
       CASE
         WHEN F.NROPERIODO = '1' THEN 'ADF'
         WHEN F.NROPERIODO = '2' THEN 'FOLH'
         WHEN F.NROPERIODO = '3' THEN 'FERI'
         WHEN F.NROPERIODO = '4' THEN 'RESC'
         ELSE 'NAOINFORMADO'
       END                                              AS documentIdentificationId,
       F.ANOCOMP                                        AS ANOCOMP,
       F.MESCOMP                                        AS MESCOMP,
       CASE
         WHEN F.NROPERIODO = '1' THEN '4'
         WHEN F.NROPERIODO = '2' THEN '4'
         WHEN F.NROPERIODO = '3' THEN '41'
         WHEN F.NROPERIODO = '4' THEN '42'
         ELSE 'NAOINFORMADO'
       END                                              AS creditorId,
       Sum(CASE
             WHEN E.PROVDESCBASE = 'P' THEN F.VALOR
             ELSE 0
           END)                                         AS TOTAL_PROVENTOS,
       Sum(CASE
             WHEN E.PROVDESCBASE = 'D' THEN F.VALOR
             ELSE 0
           END)                                         AS TOTAL_DESCONTOS,
       Sum(CASE
             WHEN E.PROVDESCBASE = 'P' THEN F.VALOR
             ELSE 0
           END) - Sum(CASE
                        WHEN E.PROVDESCBASE = 'D' THEN F.VALOR
                        ELSE 0
                      END)                              AS totalInvoiceAmount,
       CONCAT(CASE
                WHEN F.NROPERIODO = '1' THEN 'FOLHA ADIANT'
                WHEN F.NROPERIODO = '2' THEN 'FOLHA MENSAL'
                WHEN F.NROPERIODO = '3' THEN 'FOLHA FERIAS'
                WHEN F.NROPERIODO = '4' THEN 'RESCIS'
                ELSE 'OUTROS'
              END, ' ', -- Espaço para separar o texto da data
       F.MESCOMP, '/', F.ANOCOMP)                       AS notes
FROM   PFFINANC F (NOLOCK)
       INNER JOIN PFUNC P (NOLOCK)
               ON F.CODCOLIGADA = P.CODCOLIGADA
                  AND F.CHAPA = P.CHAPA
       INNER JOIN PEVENTO E (NOLOCK)
               ON F.CODCOLIGADA = E.CODCOLIGADA
                  AND F.CODEVENTO = E.CODIGO
       INNER JOIN GCOLIGADA G (NOLOCK)
               ON G.CODCOLIGADA = F.CODCOLIGADA
WHERE  F.CODCOLIGADA = :CODCOLIGADA
       AND F.ANOCOMP = :ANOCOMP
       AND F.MESCOMP = :MESCOMP
       AND F.NROPERIODO = :NROPERIODO
       AND E.PROVDESCBASE IN ( 'P', 'D' )
GROUP  BY P.CODCOLIGADA,
          G.CODEXTERNO,
          F.NROPERIODO,
          F.ANOCOMP,
          F.MESCOMP 
          
          
*/
