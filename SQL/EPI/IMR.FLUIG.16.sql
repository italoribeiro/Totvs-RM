 SELECT      B.CODTIPO,
			 B.CODCOLIGADA,
			 B.CODFILIAL,
			 G.NOMEFANTASIA AS FILIAL,
			 B.CODPESSOA,
			 B.CHAPA,
			 B.NOME,
			 B.DATAADMISSAO,
			 CONCAT(F.CODCCUSTO,'|',F.NOME) AS CENTRODECUSTO,
			 CONCAT(D.CODIGO,'|',D.NOME) AS FUNCAO,
			 CONCAT(E.CODIGO,'|',E.DESCRICAO) AS SECAO,
			 E.NROCENCUSTOCONT
			 FROM PPESSOA  A (NOLOCK)
			 JOIN PFUNC    B (NOLOCK)   ON A.CODIGO=B.CODPESSOA
			 JOIN GUSUARIO C (NOLOCK)   ON C.CODUSUARIO=A.CODUSUARIO
			 JOIN PFUNCAO  D (NOLOCK)   ON D.CODCOLIGADA=B.CODCOLIGADA AND D.CODIGO=B.CODFUNCAO
			 JOIN PSECAO   E (NOLOCK)   ON E.CODCOLIGADA=B.CODCOLIGADA AND E.CODIGO=B.CODSECAO
			 JOIN GCCUSTO  F (NOLOCK)   ON F.CODCOLIGADA=D.CODCOLIGADA AND F.CODCCUSTO=NROCENCUSTOCONT
			 JOIN GFILIAL  G (NOLOCK)   ON G.CODCOLIGADA=B.CODCOLIGADA AND G.CODFILIAL=B.CODFILIAL
			 WHERE
			 B.CODCOLIGADA=1 AND
			 B.CODSITUACAO<>'D' AND
			 B.CODTIPO='N'
			 