// Variável pública para armazenar o resultado da integração (sucesso ou erro) para o log do RM
public string StatusIntegracao { get; set; }

// =========================================================================
// 1. FUNÇÃO PRINCIPAL (Entry Point do RM)
// =========================================================================
private void fnSiengePayload_ExecuteCode(object sender, System.EventArgs args)
{
    try
    {
        // Passo 1: Montar o Payload (JSON)
        string jsonPayload = fnSiengeBuildPayload();

        // Passo 2: Enviar para a API do Sienge
        string retornoApi = fnSiengeSendPostRequest(jsonPayload);

        // Passo 3: Registrar Sucesso
        this.StatusIntegracao = "SUCESSO: " + retornoApi;
        
        // Opcional: Se quiser que o RM exiba uma janela de sucesso e pare o fluxo, descomente a linha abaixo:
        // throw new System.Exception("INTEGRAÇÃO CONCLUÍDA!\n" + retornoApi);
    }
    catch (System.Exception ex)
    {
        // Se der erro, salva na variável e estoura na tela do usuário do RM
        this.StatusIntegracao = "FALHA: " + ex.Message;
        throw new System.Exception(ex.Message);
    }
}

// =========================================================================
// 2. FUNÇÃO: CONSTRUTORA DO PAYLOAD (Mantém a regra de negócio do JSON)
// =========================================================================
private string fnSiengeBuildPayload()
{
    var dtHead = this.dsSiengeSQLHeader.DataSet.Tables[0];
    var dtDetail = this.dsSiengeSQLDetail.DataSet.Tables[0];

    if (dtHead.Rows.Count == 0)
        throw new System.Exception("AVISO: Nenhum dado de cabeçalho encontrado. O JSON não será gerado.");

    var rowHead = dtHead.Rows[0];
    var listBudgetCategories = new System.Collections.Generic.List<object>();

    foreach (System.Data.DataRow row in dtDetail.Rows)
    {
        listBudgetCategories.Add(new 
        {
            costCenterId = System.Convert.ToInt32(row["COSTCENTERID"]),
            paymentCategoriesId = System.Convert.ToString(row["PAYMENTCATEGORIESID"]),
            percentage = System.Convert.ToDecimal(row["PERCENTAGE"])
        });
    }

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
        
        budgetCategories = listBudgetCategories,
        taxes = new object[] { },
        departmentsCost = new object[] { new { departmentId = "18", percentage = "100" } },
        buildingsCost = new object[] { },
        units = new object[] { }
    };

    // Serializa. Usar Formatting.None economiza bytes na rede (o JSON vai em uma linha só).
    return Newtonsoft.Json.JsonConvert.SerializeObject(payloadObj, Newtonsoft.Json.Formatting.None); 
}

// =========================================================================
// 3. FUNÇÃO: CLIENTE HTTP (Envia a requisição com Basic Auth)
// =========================================================================
private string fnSiengeSendPostRequest(string payload)
{
    string urlApi = "https://api.sienge.com.br/bcpengenharia/public/api/v1/bills";

    // DICA: Substitua pelas suas credenciais reais
    string usuarioSienge = "bcpengenharia-thyago";
    string senhaSienge = "u1ZVArDN8ZHGA4T9osAlaqMNxo2RBTKX";

    // Converte Usuario:Senha para Base64 (Basic Auth)
    string credenciais = System.Convert.ToBase64String(System.Text.Encoding.ASCII.GetBytes(usuarioSienge + ":" + senhaSienge));
    string tokenAuth = "Basic " + credenciais;

    var request = (System.Net.HttpWebRequest)System.Net.WebRequest.Create(urlApi);
    request.Method = "POST";
    request.ContentType = "application/json";
    request.Headers.Add("Authorization", tokenAuth);

    // Escreve o JSON no corpo da requisição usando bloco 'using' para limpar a memória
    using (var streamWriter = new System.IO.StreamWriter(request.GetRequestStream()))
    {
        streamWriter.Write(payload);
        streamWriter.Flush();
    }

    try
    {
        // Tenta pegar a resposta do Sienge
        using (var response = (System.Net.HttpWebResponse)request.GetResponse())
        {
            if (response.StatusCode == System.Net.HttpStatusCode.Created || 
                response.StatusCode == System.Net.HttpStatusCode.OK)
            {
                return "Título gerado com sucesso! Status: " + (int)response.StatusCode;
            }
            
            return "Retorno inesperado da API: " + response.StatusCode;
        }
    }
    catch (System.Net.WebException wex)
    {
        // Captura o erro da API (Ex: Status 400 Bad Request) e processa a mensagem do Sienge
        string erroDetalhado = fnSiengeExtractErrorMessage(wex);
        throw new System.Exception("Sienge rejeitou a integração:\n" + erroDetalhado);
    }
}

// =========================================================================
// 4. FUNÇÃO: TRATAMENTO DE ERRO (Lê o JSON de rejeição do Sienge)
// =========================================================================
private string fnSiengeExtractErrorMessage(System.Net.WebException wex)
{
    if (wex.Response == null) return wex.Message;

    try
    {
        using (var streamReader = new System.IO.StreamReader(wex.Response.GetResponseStream()))
        {
            string errorJson = streamReader.ReadToEnd();
            
            // Lemos o JSON como um Dicionário de chave/valor em vez de 'dynamic'
            var errorObj = Newtonsoft.Json.JsonConvert.DeserializeObject<System.Collections.Generic.Dictionary<string, object>>(errorJson);
            
            if (errorObj != null && errorObj.ContainsKey("clientMessage") && errorObj["clientMessage"] != null)
            {
                return errorObj["clientMessage"].ToString();
            }
            
            return errorJson; // Se não achar o clientMessage, retorna o body inteiro
        }
    }
    catch
    {
        // Fallback de segurança caso dê falha ao ler o corpo do erro
        var resp = (System.Net.HttpWebResponse)wex.Response;
        return "Erro HTTP Status: " + (int)resp.StatusCode + " - " + resp.StatusDescription;
    }
}
