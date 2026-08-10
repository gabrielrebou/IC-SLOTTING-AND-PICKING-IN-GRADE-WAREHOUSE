# Define o título da janela
$host.UI.RawUI.WindowTitle = "Executando main.jl"

Write-Host "Iniciando execucao de main.jl..." -ForegroundColor Cyan
Write-Host "Caso trave em algum processo, pressione Enter para continuar..." -ForegroundColor Cyan

# Executa o arquivo Julia
julia main.jl

# Verifica se houve erro na execução
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERRO] O script main.jl terminou com erro (Código: $LASTEXITCODE)." -ForegroundColor Red
} else {
    Write-Host "`n[SUCESSO] Script finalizado com sucesso." -ForegroundColor Green
}

# Mantém o terminal aberto
Write-Host "`nPressione Enter para fechar esta janela..." -ForegroundColor Yellow
Read-Host