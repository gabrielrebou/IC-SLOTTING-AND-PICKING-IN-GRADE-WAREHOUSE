[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   VERIFICADOR E INSTALADOR DE AMBIENTE JULIA     " -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# 1. Verificar Julia
Write-Host "[1/3] Verificando se o Julia está instalado..." -ForegroundColor Yellow
$juliaPath = Get-Command julia -ErrorAction SilentlyContinue
if ($null -eq $juliaPath) {
    Write-Host "Julia não encontrado. Instalando via Winget..." -ForegroundColor Yellow
    winget install --id Julialang.Julia -e --silent --accept-source-agreements --accept-package-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
} else {
    Write-Host "Julia já está instalado!" -ForegroundColor Green
}

# 2. Verificar e Instalar Bibliotecas
Write-Host "[2/3] Verificando e instalando pacotes necessários..." -ForegroundColor Yellow

$setupScriptContent = @'
using Pkg
packages = ["Plots", "Graphs", "HiGHS", "JuMP", "Clustering"]
to_install = String[]

for pkg in packages
    if Base.find_package(pkg) === nothing
        println("  [!] $pkg não encontrado. Adicionando à fila...")
        push!(to_install, pkg)
    else
        println("  [OK] $pkg já instalado.")
    end
end

if !isempty(to_install)
    println("  Instalando pacotes pendentes...")
    Pkg.add(to_install)
else
    println("  Todos os pacotes externos já estão instalados.")
end
'@

$setupScriptContent | Out-File -Encoding utf8 "setup_temp.jl"
julia setup_temp.jl
Remove-Item "setup_temp.jl" -ErrorAction SilentlyContinue

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERRO] Falha ao instalar os pacotes." -ForegroundColor Red
    Read-Host "Pressione Enter para sair..."
    exit 1
}

# 3. Validação Final
Write-Host "[3/3] Validação final de importação..." -ForegroundColor Yellow

$valScriptContent = @'
libs = ["LinearAlgebra", "Statistics", "Plots", "Graphs", "HiGHS", "JuMP", "SparseArrays", "Random", "Clustering"]
all_ok = true
for lib in libs
    try
        eval(Meta.parse("using $lib"))
        println("  [SUCESSO] $lib carregado.")
    catch e
        println("  [ERRO] $lib falhou: $e")
        global all_ok = false
    end
end
exit(all_ok ? 0 : 1)
'@

$valScriptContent | Out-File -Encoding utf8 "val_temp.jl"
julia val_temp.jl
$valExitCode = $LASTEXITCODE
Remove-Item "val_temp.jl" -ErrorAction SilentlyContinue

if ($valExitCode -eq 0) {
    Write-Host "==================================================" -ForegroundColor Green
    Write-Host " [SUCESSO] TUDO INSTALADO E VERIFICADO CORRETAMENTE! " -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Green
} else {
    Write-Host "[ERRO] Houve problemas na validação final das bibliotecas." -ForegroundColor Red
}

Read-Host "Pressione Enter para fechar o programa..."