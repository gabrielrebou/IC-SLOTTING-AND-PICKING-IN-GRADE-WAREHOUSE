# Função auxiliar para ler e validar Booleanos (y/n)
function read_bool(prompt::String)::Bool
    print(prompt, " (y/n): ")
    while true
        input = lowercase(strip(readline()))

        if input == ""
            continue
        elseif input == "y"
            return true
        elseif input == "n"
            return false
        else
            println("Entrada invalida. Por favor, digite 'y' para sim, ou 'n' para nao.")
        end
    end
end

function read_int_range(prompt::String, max_val::Int)::Int
    print(prompt, " (1 a $max_val): ")
    while true
        input = strip(readline())
        if input == ""
            continue
        else 
            val = tryparse(Int, input)
        end

        if val !== nothing && 1 <= val <= max_val
            return val
        else
            println("Entrada invalida. Digite um número inteiro entre 1 e $max_val.")
        end
    end
end