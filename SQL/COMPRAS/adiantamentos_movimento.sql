

SELECT A.CAMPOLIVRE1                                              AS IDFLUIG,
       A.CODCOLIGADA                                              AS IDCOLIGADA,
       A.CODFILIAL                                                AS IDFILIAL,
       A.IDMOV                                                    AS REFMOV,
       L.IDLAN                                                    AS REFLANC,
       F.NOMEFANTASIA                                             AS FUNCIONARIO,
       A.CODCFO                                                   AS CODCFO,
       FUNC.CHAPA                                                 AS CHAPA,
       A.CODTMV                                                   AS CODMOVIMENTO,
       FORMAT(A.DATAEMISSAO, 'dd/MM/yyyy')                        AS EMISSAO,
       FORMAT(A.DATAEXTRA1, 'dd/MM/yyyy')                         AS IDA,
       FORMAT(A.DATAEXTRA2, 'dd/MM/yyyy')                         AS VOLTA,
       Datediff(DAY, A.DATAEXTRA2, Getdate())                     AS ATRASO,
       Replace(CONVERT(DECIMAL(15, 2), A.VALORLIQUIDO), '.', ',') AS VALORLIQUIDO,
       C.CODCCUSTO + '-' + C.NOME                                 AS CCUSTO,
       P2.NOME                                                    AS APROVADOR,
       P4.DESCRICAO                                               AS SITUACAO,
       L.HISTORICO                                                AS HISTORICO,
       L.CODTDO                                                   AS CODDOC,
       FF.DESCRICAO                                               AS TIPODOCUMENTO,
       ADV.STATUSCREDITO                                          AS STATUS_PC,
       ADV.IDLANREL                                               AS IDLANREL
FROM   TMOV A (NOLOCK)
       JOIN FCFO F
         ON ( F.CODCOLIGADA = A.CODCOLIGADA
               OR F.CODCOLIGADA = A.CODCOLCFO )
            AND F.CODCFO = A.CODCFO
       LEFT JOIN GCCUSTO C
              ON C.CODCOLIGADA = A.CODCOLIGADA
                 AND C.CODCCUSTO = A.CODCCUSTO
       LEFT JOIN FLAN L
              ON L.CODCOLIGADA = A.CODCOLIGADA
                 AND L.IDMOV = A.IDMOV
      LEFT JOIN (
                SELECT 
                    W.CODCOLIGADA,
                    W.IDLANREL,
                    W.IDLAN,
                    CASE
                    WHEN J.STATUSLAN = '0' THEN 'ABERTO'
                    WHEN J.STATUSLAN = '1' THEN 'BAIXADO'
                    WHEN J.STATUSLAN = '2' THEN 'CANCELADO'
                    WHEN J.STATUSLAN = '3' THEN 'BAIXADO ACORDO'
                    WHEN J.STATUSLAN = '4' THEN 'BAIXADO PARC.'
                    WHEN J.STATUSLAN = '5' THEN 'BORDERO'
                    ELSE 'OUTROS'
                   END AS STATUSCREDITO
                FROM   FRELLAN W
               JOIN FLAN J
                     ON W.CODCOLIGADA = J.CODCOLIGADA
                    AND W.IDLANREL    = J.IDLAN
               AND W.TIPOREL = 30
              
              )  AS ADV ON ADV.CODCOLIGADA=L.CODCOLIGADA AND ADV.IDLAN=L.IDLAN
            
       LEFT JOIN FTDO FF
              ON FF.CODCOLIGADA = L.CODCOLIGADA
                 AND FF.CODTDO = L.CODTDO
       LEFT JOIN PPESSOA P2
              ON P2.CODIGO = C.RESPONSAVEL
       LEFT JOIN PPESSOA P1
              ON P1.CPF = Replace(Replace(F.CGCCFO, '.', ''), '-', '')
       LEFT JOIN (SELECT Y.CODPESSOA,
                         Y.CHAPA,
                         Y.CODSITUACAO,
                         Y.DATAADMISSAO
                  FROM   PFUNC Y
                  WHERE  Y.ID = (SELECT Max(ID)
                                 FROM   PFUNC
                                 WHERE  CODPESSOA = Y.CODPESSOA)) AS FUNC
              ON FUNC.CODPESSOA = P1.CODIGO
       LEFT OUTER JOIN PCODSITUACAO P4
                    ON P4.CODCLIENTE = FUNC.CODSITUACAO
WHERE  A.CODTMV = '1.2.65'
       AND A.STATUS = 'Q'
       AND A.DATAEMISSAO <= Getdate() 
ORDER BY A.DATAEMISSAO DESC
