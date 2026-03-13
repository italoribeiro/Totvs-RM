//Versão 1.0

// Variável pública/propriedade da sua atividade que vai guardar o resultado final
public string JsonPayload { get; set; } 

private void fnSiengePayload_ExecuteCode(object sender, System.EventArgs args)
{
    try
    {
        // 1. Pega as tabelas das atividades SQL
        var dtHead = this.dsSiengeSQLHeader.DataSet.Tables[0];
        var dtDetail = this.dsSiengeSQLDetail.DataSet.Tables[0]; // Ajuste o nome exato da sua atividade Detail aqui

        // 2. Verifica se a consulta de cabeçalho trouxe dados
        if (dtHead.Rows.Count == 0)
        {
            throw new System.Exception("AVISO: Nenhum dado de cabeçalho encontrado. O JSON não será gerado.");
        }

        // Pega a primeira linha do cabeçalho
        var rowHead = dtHead.Rows[0];

        // 3. Monta a lista de Rateios (budgetCategories) fazendo um loop na tabela Detail
        var listBudgetCategories = new System.Collections.Generic.List<object>();
        foreach (System.Data.DataRow row in dtDetail.Rows)
        {
            listBudgetCategories.Add(new 
            {
                // Substitua os nomes em MAIÚSCULO pelos nomes das colunas exatas do seu SELECT no RM
                costCenterId = System.Convert.ToInt32(row["COSTCENTERID"]),
                paymentCategoriesId = System.Convert.ToString(row["PAYMENTCATEGORIESID"]),
                percentage = System.Convert.ToDecimal(row["PERCENTAGE"]) // Assumindo que você tem essa coluna no SELECT
            });
        }

        // 4. Monta o objeto principal juntando o Cabeçalho com as Listas
        var payloadObj = new 
        {
            debtorId = System.Convert.ToInt32(rowHead["DEBTORID"]),
            creditorId = System.Convert.ToInt32(rowHead["CREDITORID"]),
            documentIdentificationId = System.Convert.ToString(rowHead["DOCUMENTIDENTIFICATIONID"]),
            documentNumber = System.Convert.ToString(rowHead["DOCUMENTNUMBER"]),
            issueDate = System.Convert.ToString(rowHead["ISSUEDATE"]),
            installmentsNumber = System.Convert.ToInt32(rowHead["INSTALLMENTSNUMBER"]),
            indexId = System.Convert.ToInt32(rowHead["INDEXID"]),
            baseDate = System.Convert.ToString(rowHead["BASEDATE"]),
            dueDate = System.Convert.ToString(rowHead["DUEDATE"]),
            billDate = System.Convert.ToString(rowHead["BILLDATE"]),
            totalInvoiceAmount = System.Convert.ToDecimal(rowHead["TOTALINVOICEAMOUNT"]),
            notes = System.Convert.ToString(rowHead["NOTES"]),
            discount = System.Convert.ToDecimal(rowHead["DISCOUNT"]),
            
            // Aqui nós injetamos a lista que criamos no loop acima
            budgetCategories = listBudgetCategories,
            
            // Arrays vazios conforme seu modelo (ou você pode popular igual fizemos acima)
            taxes = new object[] { },
            
            // Exemplo de array chumbado conforme seu modelo (ou pode vir de um dsSQLSiengeDept)
            departmentsCost = new object[] 
            { 
                new { departmentId = "18", percentage = "100" } 
            },
            
            buildingsCost = new object[] { },
            units = new object[] { }
        };

        // 5. Converte o objeto inteiro para uma string JSON formatada
        string jsonResult = Newtonsoft.Json.JsonConvert.SerializeObject(payloadObj, Newtonsoft.Json.Formatting.Indented);

        // 6. Salva na variável para a próxima atividade do RM (Expressão/REST) usar
        this.JsonPayload = jsonResult;

        // Apenas para testes visuais na Fórmula Visual (pode comentar/apagar depois)
        throw new System.Exception("SUCESSO. O JSON GERADO FOI:\n\n" + jsonResult);
    }
    catch (System.Exception ex)
    {
        throw new System.Exception("ERRO NO C#: " + ex.Message);
    }
}
