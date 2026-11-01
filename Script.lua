-- Carrega a Rayfield UI (Gen2)
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Window = Rayfield:CreateWindow({
    name = "Anti-Lag Auto Clear",
    subtitle = "Otimizador Gradual (Sem Travas)",
    sidebarLayout = true,
})

local Tab = Window:CreateTab({ name = "Anti-Lag Auto", icon = 93364949241311 })

-- Serviços
local Lighting = game:GetService("Lighting")
local Terrain = workspace:FindFirstChildOfClass("Terrain")

-- Configurações
local autoCleanEnabled = false
local intervaloLimpeza = 60 -- Intervalo padrão em segundos

---------------------------------------------------------
-- FUNÇÃO DE LIMPEZA GRADUAL (DIVIDIDA EM LOTES)
---------------------------------------------------------
local function runGradualOptimization()
    -- Pega todos os descendentes do workspace de uma vez
    local descendants = workspace:GetDescendants()
    local batchSize = 150 -- Quantidade de objetos processados por vez (evita travar o frame)

    -- 1. Processamento gradual de Partes, Texturas e Partículas
    task.spawn(function()
        for i = 1, #descendants, batchSize do
            if not autoCleanEnabled then break end -- Para se o usuário desativar
            
            -- Processa um lote de objetos
            for j = i, math.min(i + batchSize - 1, #descendants) do
                local obj = descendants[j]
                
                if obj then
                    if obj:IsA("BasePart") then
                        pcall(function()
                            if not obj:IsA("Terrain") then
                                obj.Material = Enum.Material.SmoothPlastic
                            end
                        end)
                    elseif obj:IsA("Texture") or obj:IsA("Decal") then
                        pcall(function()
                            obj.Texture = ""
                        end)
                    elseif obj:IsA("ParticleEmitter") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") then
                        pcall(function()
                            obj.Enabled = false
                        end)
                    end
                end
            end
            
            -- Pausa curtíssima entre os lotes para liberar o processador do jogo
            task.wait() 
        end
    end)

    -- 2. Limpeza rápida de Iluminação (Isso é leve e não trava)
    pcall(function()
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
    end)

    for _, effect in ipairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") or effect:IsA("Atmosphere") or effect:IsA("Sky") then
            pcall(function()
                effect.Enabled = false
            end)
        end
    end

    -- 3. Otimização do Terreno
    if Terrain then
        pcall(function()
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 0
        end)
    end
end

---------------------------------------------------------
-- INTERFACE E CONTROLES
---------------------------------------------------------

Tab:CreateSection("Configurações")

-- Slider de Intervalo
Tab:CreateSlider({
    name = "Intervalo da Limpeza (Segundos)",
    Range = {30, 300},
    Increment = 10,
    Suffix = "s",
    CurrentValue = 60,
    Flag = "LimpezaIntervaloSlider",
    callback = function(value)
        intervaloLimpeza = value
    end,
})

Tab:CreateSection("Ativação")

-- Toggle único para ativar/desativar
Tab:CreateToggle({
    name = "Auto Limpeza Gradual",
    CurrentValue = false,
    Flag = "AutoCleanToggle",
    callback = function(value)
        autoCleanEnabled = value
        
        if autoCleanEnabled then
            Rayfield:Notify({
                Title = "Auto-Limpeza Ativada",
                Content = "Otimizando o mapa de forma fluida a cada " .. intervaloLimpeza .. "s.",
                Duration = 3,
                Image = 4483362458,
            })
            task.spawn(runGradualOptimization)
        end
    end,
})

-- Loop principal do temporizador
task.spawn(function()
    while true do
        task.wait(intervaloLimpeza)
        if autoCleanEnabled then
            runGradualOptimization()
        end
    end
end)
