private void fnValidateMaskCnt_ExecuteCode(object sender, System.EventArgs args)
{
    string[] contratosValidos = new string[] { "CT", "OS", "OP", "CR" };
    string codigoContrato = this.CtrCntDataResult.ValueConverter.AsString; 
    var pattern = @"^[A-Za-z]{2}\.\d{5}\.\d{2}$";
    if (string.IsNullOrWhiteSpace(codigoContrato) || !System.Text.RegularExpressions.Regex.IsMatch(codigoContrato, pattern))
    {
        throw new ArgumentException("Código do contrato inválido. O formato correto é: DUAS_LETRAS.PONTO.CINCO_NUMEROS.PONTO.DOIS_NUMEROS (exemplo: CT.00777.25).");
    }
    // Validar prefixo
    string prefixo = codigoContrato.Length >= 2 ? codigoContrato.Substring(0, 2).ToUpper() : "";
    bool prefixoValido = false;
    foreach (var p in contratosValidos)
    {
        if (prefixo == p)
        {
            prefixoValido = true;
            break;
        }
    }
    if (!prefixoValido)
    {
        throw new ArgumentException("Prefixo inválido. Os prefixos válidos são: OS,OP,CT,CV");
    }
}

