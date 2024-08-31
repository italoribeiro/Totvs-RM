/*
TOTVS NORDESTE
Consultor: Italo Ribeiro
Controle de EPI Fluig
*/

SELECT B.CODEPI,
       B.NOME EPI,
       A.CODIDENTEPI,
       A.CA,
       CASE
         WHEN B.TIPOEQUIPAMENTO = 1 THEN 'EPI'
         ELSE 'EPC'
       END    AS TIPO,
       CASE
         WHEN B.DESCARTAVEL = 1 THEN 'S'
         ELSE 'N'
       END    AS DESCARTAVEL
      
FROM   VEPI A (NOLOCK)
       JOIN VCATALOGOEPI B (NOLOCK)
         ON A.CODCOLIGADA = B.CODCOLIGADA
            AND A.CODEPI = B.CODEPI
       JOIN TPRD C (NOLOCK)
         ON C.IDPRD = B.IDPRD
WHERE  
A.CODCOLIGADA = 1 
AND B.INATIVA=0
AND B.NOME LIKE '%' +:NOME + '%'
