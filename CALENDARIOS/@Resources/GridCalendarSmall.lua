local viewMonth = 1
local viewYear = 2026
local selectedDay = 1
local cachedEvents = {}
local currentWeekStart = 1

local function ellipsis(text, maxLen)
    if not text then return "" end
    if #text <= maxLen then return text end
    return text:sub(1, maxLen - 3) .. "..."
end

function Initialize()
    local now = os.date("*t")
    viewMonth = now.month
    viewYear = now.year
    selectedDay = now.day
    SKIN:Bang("!Log", "ANTIGRA GridSmall: Inicializado")
    DrawGrid()
    UpdateEventList()
end

function Parse()
    local fullPath = SKIN:GetVariable('@') .. "Calendar.ics"

    local file = io.open(fullPath, "r")
    if not file then
        SKIN:Bang("!Log", "ANTIGRA GridSmall Error: No se pudo abrir " .. fullPath)
        return
    end

    local content = file:read("*all")
    file:close()

    local now = os.time()
    local maxDate = now + (60 * 24 * 60 * 60)

    cachedEvents = {}

    local function getVal(block, key)
        local pattern = "[\r\n]" .. key .. "[^:]*:(.-)[\r\n]"
        local val = block:match(pattern)
        if not val then
             pattern = "^" .. key .. "[^:]*:(.-)[\r\n]"
             val = block:match(pattern)
        end
        return val
    end

    local lastPos = 1
    while true do
        local bStart, bEnd = content:find("BEGIN:VEVENT", lastPos)
        if not bStart then break end
        local eStart, eEnd = content:find("END:VEVENT", bEnd)
        if not eStart then break end
        local block = content:sub(bStart, eEnd)
        lastPos = eEnd

        local summary = getVal(block, "SUMMARY") or "Sin título"
        local dtstart = getVal(block, "DTSTART") or ""
        local datePart = dtstart:match("(%d%d%d%d%d%d%d%d)")

        if datePart then
            local y, m, d = datePart:match("(%d%d%d%d)(%d%d)(%d%d)")
            if y and m and d then
                local eventTime = os.time({year=tonumber(y), month=tonumber(m), day=tonumber(d)})
                if eventTime >= now and eventTime <= maxDate then
                    local key = tonumber(y) .. "-" .. tonumber(m) .. "-" .. tonumber(d)
                    if not cachedEvents[key] then cachedEvents[key] = {} end

                    local color = "200,200,200"
                    local lSummary = summary:lower()
                    if lSummary:find("exam") then color = "255,82,82"
                    elseif lSummary:find("patio") then color = "105,240,174"
                    elseif lSummary:find("reun") or lSummary:find("junta") then color = "255,171,64"
                    elseif lSummary:find("preparar") then color = "224,64,251"
                    end

                    table.insert(cachedEvents[key], {summary = summary, color = color})
                end
            end
        end
    end
    DrawGrid()
    UpdateEventList()
end

function DrawGrid()
    local months = {"ENERO", "FEBRERO", "MARZO", "ABRIL", "MAYO", "JUNIO", "JULIO", "AGOSTO", "SEPTIEMBRE", "OCTUBRE", "NOVIEMBRE", "DICIEMBRE"}

    local mIdx = tonumber(viewMonth) or 1
    if mIdx < 1 or mIdx > 12 then mIdx = 1 end
    SKIN:Bang("!SetOption", "MeterMonthYear", "Text", months[mIdx] .. " " .. viewYear)

    local firstDayTS = os.time({year=viewYear, month=mIdx, day=1})
    local startWDay = os.date("*t", firstDayTS).wday
    local startDayIdx = (startWDay == 1) and 7 or (startWDay - 1)

    local mNext = mIdx + 1
    local yNext = viewYear
    if mNext > 12 then mNext = 1; yNext = yNext + 1 end
    local lastDayTS = os.time({year=yNext, month=mNext, day=0})
    local daysInMonth = tonumber(os.date("%d", lastDayTS))

    local now = os.date("*t")

    -- Calcular en qué fila está el día actual (o selectedDay)
    local targetDay = selectedDay
    if targetDay == 0 then targetDay = now.day end
    if viewMonth ~= now.month or viewYear ~= now.year then
        targetDay = 1
    end

    local targetCellIdx = startDayIdx + targetDay - 1
    local targetRow = math.ceil(targetCellIdx / 7)
    currentWeekStart = (targetRow - 1) * 7 + 1

    for i = 1, 7 do
        local gridIdx = currentWeekStart + i - 1
        local actualDay = gridIdx - startDayIdx + 1
        local isWeekend = (i >= 6)
        local dayMeter = "MeterDay" .. i
        local dotMeter = "MeterMark" .. i
        local hitMeter = "MeterHit" .. i

        if actualDay > 0 and actualDay <= daysInMonth then
            SKIN:Bang("!SetOption", dayMeter, "Text", actualDay)
            SKIN:Bang("!ShowMeter", dayMeter)
            SKIN:Bang("!ShowMeter", hitMeter)

            local key = viewYear .. "-" .. mIdx .. "-" .. actualDay
            local tooltipText = ""

            SKIN:Bang("!SetOption", dayMeter, "Padding", "6,1,6,1")

            if actualDay == selectedDay then
                SKIN:Bang("!SetOption", dayMeter, "FontColor", "#CalSelectedText#")
                SKIN:Bang("!SetOption", dayMeter, "FontWeight", "700")
                SKIN:Bang("!SetOption", dayMeter, "SolidColor", "#CalSelectedBg#")
            elseif actualDay == now.day and mIdx == now.month and viewYear == now.year then
                SKIN:Bang("!SetOption", dayMeter, "FontColor", "#CalTodayText#")
                SKIN:Bang("!SetOption", dayMeter, "FontWeight", "700")
                SKIN:Bang("!SetOption", dayMeter, "SolidColor", "#CalTodayBg#")
            elseif isWeekend then
                SKIN:Bang("!SetOption", dayMeter, "FontColor", "#CalWeekendText#")
                SKIN:Bang("!SetOption", dayMeter, "FontWeight", "400")
                SKIN:Bang("!SetOption", dayMeter, "SolidColor", "0,0,0,0")
            else
                SKIN:Bang("!SetOption", dayMeter, "FontColor", "#CalDayText#")
                SKIN:Bang("!SetOption", dayMeter, "FontWeight", "400")
                SKIN:Bang("!SetOption", dayMeter, "SolidColor", "0,0,0,0")
            end

            if cachedEvents[key] then
                local color = cachedEvents[key][1].color
                SKIN:Bang("!SetOption", dotMeter, "Shape", "Rectangle -10,20,20,4 | Fill Color " .. color .. " | StrokeWidth 0 | Ellipse 0,26,1.6,1.6 | Fill Color " .. color .. " | StrokeWidth 0")
                SKIN:Bang("!ShowMeter", dotMeter)

                for idx = 1, math.min(#cachedEvents[key], 4) do
                    if idx > 1 then tooltipText = tooltipText .. "\n" end
                    tooltipText = tooltipText .. ellipsis(cachedEvents[key][idx].summary, 80)
                end
            else
                SKIN:Bang("!HideMeter", dotMeter)
            end

            SKIN:Bang("!SetOption", hitMeter, "ToolTipText", tooltipText)
        else
            SKIN:Bang("!SetOption", dayMeter, "Text", " ")
            SKIN:Bang("!HideMeter", dayMeter)
            SKIN:Bang("!HideMeter", dotMeter)
            SKIN:Bang("!HideMeter", hitMeter)
            SKIN:Bang("!SetOption", hitMeter, "ToolTipText", "")
        end
    end
end

function SelectCell(idx)
    local i = tonumber(idx)
    if not i then return end

    local mIdx = tonumber(viewMonth) or 1
    local firstDayTS = os.time({year=viewYear, month=mIdx, day=1})
    local startWDay = os.date("*t", firstDayTS).wday
    local startDayIdx = (startWDay == 1) and 7 or (startWDay - 1)

    local gridIdx = currentWeekStart + i - 1
    local actualDay = gridIdx - startDayIdx + 1

    local mNext = mIdx + 1
    local yNext = viewYear
    if mNext > 12 then mNext = 1; yNext = yNext + 1 end
    local lastDayTS = os.time({year=yNext, month=mNext, day=0})
    local daysInMonth = tonumber(os.date("%d", lastDayTS))

    if actualDay > 0 and actualDay <= daysInMonth then
        selectedDay = actualDay
        DrawGrid()
        UpdateEventList()
    end
end

function ChangeMonth(delta)
    viewMonth = viewMonth + delta
    if viewMonth > 12 then viewMonth = 1; viewYear = viewYear + 1 end
    if viewMonth < 1 then viewMonth = 12; viewYear = viewYear - 1 end
    selectedDay = 0
    DrawGrid()
    UpdateEventList()
end

function ChangeWeek(delta)
    local mIdx = tonumber(viewMonth) or 1
    local firstDayTS = os.time({year=viewYear, month=mIdx, day=1})
    local startWDay = os.date("*t", firstDayTS).wday
    local startDayIdx = (startWDay == 1) and 7 or (startWDay - 1)

    local mNext = mIdx + 1
    local yNext = viewYear
    if mNext > 12 then mNext = 1; yNext = yNext + 1 end
    local lastDayTS = os.time({year=yNext, month=mNext, day=0})
    local daysInMonth = tonumber(os.date("%d", lastDayTS))

    local newWeekStart = currentWeekStart + (delta * 7)

    -- Verificar límites
    if delta > 0 then
        local lastCellNeeded = newWeekStart
        local lastDay = lastCellNeeded - startDayIdx + 1
        if lastDay > daysInMonth then
            -- Pasar al siguiente mes
            ChangeMonth(1)
            return
        end
    elseif delta < 0 then
        if newWeekStart < 1 then
            -- Pasar al mes anterior
            ChangeMonth(-1)
            return
        end
        local firstDay = newWeekStart - startDayIdx + 1
        if firstDay < 1 and (newWeekStart + 6 - startDayIdx + 1) < 1 then
            ChangeMonth(-1)
            return
        end
    end

    currentWeekStart = newWeekStart
    if selectedDay > 0 then
        local selCellIdx = startDayIdx + selectedDay - 1
        if selCellIdx < currentWeekStart or selCellIdx >= currentWeekStart + 7 then
            selectedDay = 0
        end
    end
    DrawGrid()
    UpdateEventList()
end

function UpdateEventList()
    local sDay = tonumber(selectedDay) or 0
    local mIdx = tonumber(viewMonth) or 1
    local yVal = tonumber(viewYear) or 2026

    if sDay == 0 then
        SKIN:Bang("!HideMeter", "MeterListTitle")
        for i = 1, 4 do
            SKIN:Bang("!HideMeter", "MeterListText" .. i)
            SKIN:Bang("!HideMeter", "MeterListBullet" .. i)
        end
        return
    end

    local now = os.date("*t")
    if sDay == now.day and mIdx == now.month and yVal == now.year then
        SKIN:Bang("!SetOption", "MeterListTitle", "Text", "HOY")
    else
        SKIN:Bang("!SetOption", "MeterListTitle", "Text", "SELECCIONADO")
    end
    SKIN:Bang("!ShowMeter", "MeterListTitle")

    local key = yVal .. "-" .. mIdx .. "-" .. sDay
    local events = cachedEvents[key] or {}

    for i = 1, 4 do
        local textMeter = "MeterListText" .. i
        local bulletMeter = "MeterListBullet" .. i
        if events[i] then
            SKIN:Bang("!SetOption", textMeter, "Text", events[i].summary)
            SKIN:Bang("!SetOption", bulletMeter, "Shape", "Rectangle 0,5,2,14 | Fill Color " .. events[i].color .. " | StrokeWidth 0")
            SKIN:Bang("!ShowMeter", textMeter)
            SKIN:Bang("!ShowMeter", bulletMeter)
        else
            SKIN:Bang("!HideMeter", textMeter)
            SKIN:Bang("!HideMeter", bulletMeter)
        end
    end
end
