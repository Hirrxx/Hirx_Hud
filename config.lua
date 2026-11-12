Config = {}

-- Framework:
-- 'auto'       -> Detecta automaticamente ESX, QBCore o Standalone
-- 'esx'        -> Fuerza ESX (es_extended + esx_status)
-- 'qbcore'     -> Fuerza QBCore / QBX (qb-core / qbx_core)
-- 'standalone' -> Sin framework (comida fija al 100% o por export)
Config.Framework = 'auto'

-- Estilo de HUD por defecto:
-- 'minimal'  -> Boceto 1 (Capsula horizontal minimalista + velocimetro rectangular)
-- 'rings'    -> Boceto 2 (Anillos circulares + velocimetro en arco)
-- 'tactical' -> Boceto 3 (Dock tactico simetrico centro-abajo)
Config.DefaultStyle = 'minimal'

-- Permitir al jugador elegir entre estilo 1 ('minimal'), 2 ('rings') o 3 ('tactical')
-- y guardar su preferencia automaticamente en KVP
Config.AllowStyleCommand = true
Config.StyleCommand = 'hudestilo' -- Uso: /hudestilo [1|2|3|minimal|rings|tactical]

-- Comando para ocultar/mostrar el HUD manualmente
Config.AllowToggleCommand = true
Config.ToggleCommand = 'hud'

-- Ocultar el HUD cuando el menu de pausa esta abierto
Config.HideWhenPaused = true

-- Unidad del velocimetro: 'kmh' o 'mph'
Config.SpeedUnit = 'kmh'

-- Velocidad maxima usada para rellenar la barra/arco del velocimetro
Config.MaxSpeedDisplay = 240

-- Mostrar siempre el velocimetro (false = solo dentro de un vehiculo)
Config.AlwaysShowSpeedo = false

-- Tiempo maximo bajo el agua base en segundos (para calcular % de oxigeno)
Config.MaxOxygenTime = 10.0

-- Intervalos de actualizacion en milisegundos
Config.StatusTickMs = 150
Config.VehicleTickMs = 45

-- Etiquetas para los 3 modos de rango de pma-voice
Config.VoiceLabels = {
    [1] = 'Susurro',
    [2] = 'Normal',
    [3] = 'Grito'
}
