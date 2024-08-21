SELECT CASE
         WHEN SC.CODTMV = '1.1.26' THEN U.NOME
         ELSE SC.CAMPOLIVRE2
       END                                                      AS USUARIOCRIACAO,
       SC.CODTMV,
       SC.CODCOLIGADA                                           AS COLIGADA,
       SC.CODFILIAL                                             AS FILIAL_SC,
       SC.NUMEROMOV                                             AS NUM_SC,
       CASE
         WHEN SC.STSCOMPRAS = 'C' THEN 'Em Cotação'
         WHEN SC.STSCOMPRAS = 'P' THEN 'Parcialmente Cotado'
         WHEN SC.STSCOMPRAS = 'T' THEN 'Cotado'
         WHEN SC.STSCOMPRAS = 'G' THEN 'Gerado por Cotação'
         ELSE ''
       END                                                      AS STATUS_COMPRA,
       SC.DATAEMISSAO                                           AS DATA_EMISSAO_SC,
       ISC.CODCCUSTO + ' - ' + GCCUSTO.NOME                     AS CENTRO_CUSTO,
       PSC.CODTB1FAT + ' - ' + TTB1.DESCRICAO                   AS CLASSIFICACAO,
       ISC.NSEQITMMOV                                           AS ITEM_SC,
       ISC.IDPRD,
       PSC.CODIGOPRD                                            AS COD_PROD,
       PSC.NOMEFANTASIA                                         AS NOME_PROD,
       ISC.CODUND                                               AS UNID_SC,
       ISC.QUANTIDADEORIGINAL                                   AS QTDE_SC,
       ISC.QUANTIDADE                                           AS QTDE_PENDENTE_SC,
       ISC.PRECOUNITARIO                                        AS PREÇO_UNIT_SC,
       ISNULL(ISC.QUANTIDADE, 0) * ISNULL(ISC.PRECOUNITARIO, 0) AS PREÇO_TOTAL_SC,
       ISC.DATAENTREGA                                          AS DATA_ENTREGA_SC,
       CASE
         WHEN SC.STATUS = 'A' THEN 'Pendente'
         WHEN SC.STATUS = 'B' THEN 'Bloqueado'
         WHEN SC.STATUS = 'C' THEN 'Cancelado'
         WHEN SC.STATUS = 'F'
              AND SC.STSCONCLUIDO IS NULL THEN 'Recebido'
         WHEN SC.STATUS = 'F'
              AND SC.STSCONCLUIDO = 'C' THEN 'Recebido/Concluído'
         WHEN SC.STATUS = 'F'
              AND SC.STSCONCLUIDO = 'P' THEN 'Recebido/Parcialmente Concluído'
         WHEN SC.STATUS = 'G' THEN 'Parcialmente Recebido'
         WHEN SC.STATUS = 'N' THEN 'Normal'
         WHEN SC.STATUS = 'P' THEN 'Parcialmente Quitado'
         WHEN SC.STATUS = 'Q' THEN 'Quitado'
         WHEN SC.STATUS = 'U' THEN 'Em Faturamento'
         ELSE ''
       END                                                      AS STATUS_SC,
       SC.CODTMV + '-' + TMSC.NOME                              AS TIPO_MOV_SC,
       TCCOTACAOITMMOV.CODCOTACAO                               AS CODCOTACAO,
       TCCOTACAO.CODCOMPRADOR                                   AS COD_COMPRADOR,
       TVEN.NOME                                                AS NOME_COMPRADOR,
       ISC.CODTB2FLX                                            AS [CODIGO EQUIPAMENTO],
       TMOVHISTORICO.HISTORICOLONGO,
       CASE
         WHEN Z.TIPOSOLICITACAOFLUIG = 'C' THEN 'COMPRA CONVENCIONAL'
         WHEN Z.TIPOSOLICITACAOFLUIG = 'E' THEN 'COMPRA EMERGENCIAL'
         ELSE 'N/A'
       END                                                      TIPOSOLICITACAOFLUIG
FROM   TMOV SC
       INNER JOIN TMOVHISTORICO
               ON TMOVHISTORICO.CODCOLIGADA = SC.CODCOLIGADA
                  AND TMOVHISTORICO.IDMOV = SC.IDMOV
       INNER JOIN TITMMOV ISC
               ON SC.CODCOLIGADA = ISC.CODCOLIGADA
                  AND SC.IDMOV = ISC.IDMOV
       INNER JOIN TTMV TMSC
               ON TMSC.CODCOLIGADA = SC.CODCOLIGADA
                  AND TMSC.CODTMV = SC.CODTMV
       INNER JOIN TPRD PSC
               ON PSC.CODCOLIGADA = ISC.CODCOLIGADA
                  AND PSC.IDPRD = ISC.IDPRD
       LEFT JOIN TCCOTACAOITMMOV
              ON TCCOTACAOITMMOV.CODCOLIGADA = ISC.CODCOLIGADA
                 AND TCCOTACAOITMMOV.IDMOV = ISC.IDMOV
                 AND TCCOTACAOITMMOV.NSEQITMMOV = ISC.NSEQITMMOV
       LEFT JOIN TCCOTACAO
              ON TCCOTACAO.CODCOLIGADA = TCCOTACAOITMMOV.CODCOLIGADA
                 AND TCCOTACAO.CODCOTACAO = TCCOTACAOITMMOV.CODCOTACAO
       LEFT JOIN TVEN
              ON TVEN.CODCOLIGADA = TCCOTACAO.CODCOLIGADA
                 AND TVEN.CODVEN = TCCOTACAO.CODCOMPRADOR
       LEFT JOIN GCCUSTO
              ON GCCUSTO.CODCOLIGADA = ISC.CODCOLIGADA
                 AND GCCUSTO.CODCCUSTO = ISC.CODCCUSTO
       LEFT JOIN TTB1
              ON TTB1.CODCOLIGADA = PSC.CODCOLIGADA
                 AND TTB1.CODTB1FAT = PSC.CODTB1FAT
       JOIN TMOVCOMPL Z
         ON Z.CODCOLIGADA = SC.CODCOLIGADA
            AND Z.IDMOV = SC.IDMOV
       JOIN GUSUARIO U
         ON U.CODUSUARIO = SC.USUARIOCRIACAO
WHERE  SC.CODCOLIGADA IN ( 1, 4, 7 )
       AND SC.DATAEMISSAO >= :DATAINICIAL
       AND SC.DATAEMISSAO <= :DATAFINAL
       AND SC.CODTMV IN ( '1.1.03', '1.1.15', '1.1.26' )
       AND SC.STATUS IN ( 'A', 'G' )
       AND ISC.QUANTIDADE > 0
       AND ( TCCOTACAO.STSCOTACAO IS NULL
              OR TCCOTACAO.STSCOTACAO <> 7 ) 
