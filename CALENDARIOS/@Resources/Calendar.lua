function Update()
end

function Parse()
    -- Read from @Resources folder
    local fullPath = SKIN:GetVariable('@') .. "Calendar.ics"
    
    local file = io.open(fullPath, "r")
    if not file then 
        SKIN:Bang("!SetOption", "MeterEvent1Title", "Text", "Error: Archivo no accesible")
        return 
    end

    local content = file:read("*all")
    file:close()
    
    if content == "" or content == nil then 
        SKIN:Bang("!SetOption", "MeterEvent1Title", "Text", "Calendario vacío")
        return 
    end

    local daysSpanish = {"DOMINGO", "LUNES", "MARTES", "MIERCOLES", "JUEVES", "VIERNES", "SABADO"}
    local now = os.date("*t")
    local todayStart = os.time({year=now.year, month=now.month, day=now.day, hour=0, min=0, sec=0})

    -- Mostrar eventos desde hoy hasta 14 días después (semana actual + próxima)
    local maxDate = todayStart + (14 * 24 * 60 * 60)

    local events = {}
    
    local function getVal(block, key)
        -- Robust anchored pattern for key-value extraction
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
        local dtstart = getVal(block, "DTSTART") or "0"
        
        local datePart = dtstart:match("(%d%d%d%d%d%d%d%d)") or "00000000"
        local ey, em, ed = datePart:match("(%d%d%d%d)(%d%d)(%d%d)")
        
        local formattedDay = "--"
        local formattedDate = "--/--"
        local eventTS = 0
        if ed and em and ey then
            eventTS = os.time({year=tonumber(ey), month=tonumber(em), day=tonumber(ed), hour=12})
            local dayNum = os.date("*t", eventTS).wday
            formattedDay = daysSpanish[dayNum]
            formattedDate = tonumber(ed) .. " / " .. tonumber(em)
        end

        -- Optimización: Solo procesar eventos relevantes
        if eventTS >= todayStart and eventTS <= maxDate then
            summary = summary:gsub("\\,", ","):gsub("\\n", " "):gsub("\\;", ";")
            if summary == "Busy" then summary = "Ocupado" end
            
            local iconType = ""
            local lowerSummary = summary:lower()
            if lowerSummary:find("exam") then iconType = "Exam"
            elseif lowerSummary:find("patio") then iconType = "Patio"
            elseif lowerSummary:find("reun") or lowerSummary:find("junta") then iconType = "Reunion"
            elseif lowerSummary:find("preparar") then iconType = "Prepara"
            end

            table.insert(events, {summary = summary, time = dtstart, day = formattedDay, date = formattedDate, iconType = iconType})
        end
    end

    if #events == 0 then
        SKIN:Bang("!SetOption", "MeterEvent1Title", "Text", "Sin eventos próximamente")
    end

    table.sort(events, function(a, b) return a.time < b.time end)

    for i = 1, 10 do
        local titleMeter = "MeterEvent" .. i .. "Title"
        local dayMeter = "MeterEvent" .. i .. "Day"
        local dateMeter = "MeterEvent" .. i .. "Date"
        local bulletMeter = "MeterEvent" .. i .. "Bullet"
        local sepMeter = "MeterEvent" .. i .. "Sep"
        
        SKIN:Bang("!HideMeter", "MeterEvent" .. i .. "IconExam")
        SKIN:Bang("!HideMeter", "MeterEvent" .. i .. "IconPatio")
        SKIN:Bang("!HideMeter", "MeterEvent" .. i .. "IconReunion")
        SKIN:Bang("!HideMeter", "MeterEvent" .. i .. "IconPrepara")
        
        if events[i] then
            SKIN:Bang("!SetOption", titleMeter, "Text", events[i].summary)
            SKIN:Bang("!SetOption", dayMeter, "Text", events[i].day)
            SKIN:Bang("!SetOption", dateMeter, "Text", events[i].date)
            
            if events[i].iconType ~= "" then
                SKIN:Bang("!ShowMeter", "MeterEvent" .. i .. "Icon" .. events[i].iconType)
            end
            
            -- Separator logic: Only show if next event is a different day
            if i < 10 then
                if events[i+1] and events[i].date ~= events[i+1].date then
                    SKIN:Bang("!ShowMeter", sepMeter)
                else
                    SKIN:Bang("!HideMeter", sepMeter)
                end
            end
            
            SKIN:Bang("!ShowMeter", titleMeter)
            SKIN:Bang("!ShowMeter", dayMeter)
            SKIN:Bang("!ShowMeter", dateMeter)
            SKIN:Bang("!ShowMeter", bulletMeter)
        else
            SKIN:Bang("!HideMeter", titleMeter)
            SKIN:Bang("!HideMeter", dayMeter)
            SKIN:Bang("!HideMeter", dateMeter)
            SKIN:Bang("!HideMeter", bulletMeter)
            if i < 10 then SKIN:Bang("!HideMeter", sepMeter) end
        end
    end
end
