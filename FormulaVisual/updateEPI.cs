private void fnUpDate_ExecuteCode(object sender, System.EventArgs args) 
{
  try 
  {
    
    string sql = "UPDATE VEPI SET CODLOC = '004', CODFILIAL = '5', " +
                 "RECMODIFIEDON = GETDATE(), RECMODIFIEDBY = 'mestre' " +
                 "WHERE CODCOLIGADA = 1 AND CODIDENTEPI = 'BOT 39-0003'";

    this.DBS.QueryExec(sql);
  } 
  catch (Exception ex) 
  {
    throw new Exception("Erro ao executar a atualização: " + ex.Message);
  }
}
