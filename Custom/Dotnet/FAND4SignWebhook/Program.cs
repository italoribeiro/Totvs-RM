using FAND4signWebhook.Models;
using FAND4signWebhook.Services;
using System.Text.Json;
using Microsoft.AspNetCore.HttpOverrides; // Para o Nginx
using Microsoft.Extensions.Logging.EventLog; // Para o Log de Eventos

var builder = WebApplication.CreateBuilder(args);

// Configura o serviço de Log de Eventos do Windows
builder.Logging.AddEventLog(eventLogSettings =>
{
    eventLogSettings.SourceName = "FAND4signWebhook API";
});

// Adiciona o suporte a Windows Service
builder.Host.UseWindowsService();

// --- 2. Configurar Serviços (Injeção de Dependência) ---
builder.Services.AddHttpClient(); 
builder.Services.AddScoped<IHmacValidatorService, HmacValidatorService>();
builder.Services.AddScoped<IRmApiService, RmApiService>();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// --- 3. Bloco de Construção da Aplicação ---
var app = builder.Build();

// Confiança no Proxy Reverso (Nginx)
app.UseForwardedHeaders(new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedFor | 
                       ForwardedHeaders.XForwardedProto
});

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection(); 

// --- 4. O ENDPOINT ---
app.MapPost("/webhook/fan-d4sign-listener", async (HttpContext httpContext) =>
{
    // Obtemos os serviços DE DENTRO do HttpContext
    var hmacValidator = httpContext.RequestServices.GetRequiredService<IHmacValidatorService>();
    var rmApiService = httpContext.RequestServices.GetRequiredService<IRmApiService>();
    
    // --- LINHA CORRIGIDA ---
    var logger = httpContext.RequestServices.GetRequiredService<ILogger<Program>>();
    // --- FIM DA CORREÇÃO ---

    D4SignPayload? payload;

    // ETAPA 0: Ler o Body (JSON) manualmente
    try
    {
        payload = await httpContext.Request.ReadFromJsonAsync<D4SignPayload>();
        if (payload == null)
        {
            logger.LogWarning("Requisição rejeitada: Body (JSON) vazio ou mal formatado."); 
            return Results.Problem(detail: "Payload JSON vazio ou inválido.", statusCode: 400); 
        }
    }
    catch (JsonException ex)
    {
        logger.LogWarning(ex, "Falha ao deserializar o JSON do D4Sign."); 
        return Results.Problem(detail: "Payload JSON mal formatado.", statusCode: 400);
    }

    // Etapa 1: Validar o Header HMAC
    string? hmacHeader = httpContext.Request.Headers["Content-Hmac"];
    if (string.IsNullOrEmpty(hmacHeader) || !hmacValidator.IsValid(payload.uuid, hmacHeader))
    {
        // O HmacValidatorService (que usa ILogger) já logou o erro no Event Log
        return Results.Problem(
            detail: "Assinatura HMAC inválida ou ausente.",
            statusCode: 401);
    }

    // Etapa 2: Validado! Tentar enviar para a API do RM
    logger.LogInformation("HMAC validado para {Uuid}. Enviando para a API do RM...", payload.uuid);

    bool sucessoRm = await rmApiService.EnviarPayloadAsync(payload);

    // Etapa 3: Analisar o resultado da chamada ao RM
    if (sucessoRm)
    {
        return Results.Ok(new { status = "Recebido e processado." });
    }
    else
    {
        // O RmApiService (que usa ILogger) já logou o erro no Event Log
        return Results.Problem(
            detail: "A requisição foi recebida, mas falhou ao ser processada pelo sistema interno (RM).",
            statusCode: 502); 
    }
})
.WithName("D4SignWebhookListener")
.WithTags("Webhooks");

// Endpoint de Health Check
app.MapGet("/health", () => Results.Ok(new { status = "online" }));

// --- 5. Bloco de Execução ---
app.Run();