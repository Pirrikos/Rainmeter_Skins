local upcomingEvents = {}
local maxEvents = 8

local function V(name, fallback)
    local value = SKIN:GetVariable(name)
    if value == nil or value == "" then
        return fallback
    end
    return value
end

local function ellipsis(text, maxLen)
    if not text then return "" end
    if #text <= maxLen then return text end
    return text:sub(1, maxLen - 3) .. "..."
end

function Initialize()
    maxEvents = tonumber(SKIN:GetVariable("MaxEvents")) or 8
    SKIN:Bang("!Log", "Countdown: Inicializado")
    Parse()
end

local function eventColorFor(summary)
    local color = V("CdEventDefault", "200,200,200")
    local lSummary = summary:lower()
    if lSummary:find("exam") then color = V("CdEventExam", "255,82,82")
    elseif lSummary:find("patio") then color = V("CdEventPatio", "105,240,174")
    elseif lSummary:find("reun") or lSummary:find("junta") then color = V("CdEventMeeting", "255,171,64")
    elseif lSummary:find("preparar") then color = V("CdEventPrep", "224,64,251")
    end
    return color
end

local function urgencyByDays(daysLeft)
    if daysLeft <= 2 then
        return "critical", V("CdDaysCritical", "255,82,82"), V("CdRowCritical", "255,82,82,11")
    elseif daysLeft <= 6 then
        return "warn", V("CdDaysWarn", "255,171,64"), V("CdRowWarn", "255,171,64,9")
    end
    return "normal", V("CdDaysNormal", "255,255,255,180"), V("CdRowNormal", "255,255,255,4")
end

function Parse()
    -- Use Calendar.ics from CALENDARIOS
    local icsPath = SKIN:GetVariable('SKINSPATH') .. "CALENDARIOS\\@Resources\\Calendar.ics"

    local file = io.open(icsPath, "r")
    if not file then
        SKIN:Bang("!Log", "Countdown Error: No se pudo abrir " .. icsPath)
        return
    end

    local content = file:read("*all")
    file:close()

    local now = os.time()
    local today = os.time({
        year = os.date("*t", now).year,
        month = os.date("*t", now).month,
        day = os.date("*t", now).day,
        hour = 0, min = 0, sec = 0
    })

    upcomingEvents = {}

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
                local eventTime = os.time({
                    year = tonumber(y),
                    month = tonumber(m),
                    day = tonumber(d),
                    hour = 0, min = 0, sec = 0
                })

                -- Only future events (including today)
                if eventTime >= today then
                    local daysLeft = math.floor((eventTime - today) / 86400)

                    summary = summary:gsub("\\,", ","):gsub("\\n", " "):gsub("\\;", ";")
                    if summary == "Busy" then summary = "Ocupado" end

                    local eventTypeColor = eventColorFor(summary)
                    local urgency, daysColor, rowColor = urgencyByDays(daysLeft)

                    table.insert(upcomingEvents, {
                        summary = summary,
                        daysLeft = daysLeft,
                        eventColor = eventTypeColor,
                        daysColor = daysColor,
                        urgency = urgency,
                        rowColor = rowColor,
                        timestamp = eventTime
                    })
                end
            end
        end
    end

    -- Sort by date (nearest first)
    table.sort(upcomingEvents, function(a, b)
        return a.timestamp < b.timestamp
    end)

    -- Limit to maxEvents
    while #upcomingEvents > maxEvents do
        table.remove(upcomingEvents)
    end

    UpdateDisplay()
end

function UpdateDisplay()
    SKIN:Bang("!SetOption", "MeterCountValue", "Text", tostring(#upcomingEvents) .. " pendientes")

    if #upcomingEvents == 0 then
        SKIN:Bang("!ShowMeter", "MeterEmptyState")
    else
        SKIN:Bang("!HideMeter", "MeterEmptyState")
    end

    for i = 1, maxEvents do
        local rowBgMeter = "MeterRowBg" .. i
        local bulletMeter = "MeterBullet" .. i
        local nameMeter = "MeterEventName" .. i
        local daysMeter = "MeterDaysLeft" .. i
        local hitMeter = "MeterHit" .. i

        if upcomingEvents[i] then
            local event = upcomingEvents[i]
            local daysText = ""

            if event.daysLeft == 0 then
                daysText = "HOY"
            elseif event.daysLeft == 1 then
                daysText = "1 dia"
            else
                daysText = event.daysLeft .. " dias"
            end

            SKIN:Bang("!SetOption", rowBgMeter, "Shape", "Rectangle 0,-5,300,30,6 | Fill Color " .. event.rowColor .. " | StrokeWidth 0")
            SKIN:Bang("!SetOption", bulletMeter, "Shape", "Rectangle 0,0,3,16 | Fill Color " .. event.eventColor .. " | StrokeWidth 0")
            SKIN:Bang("!SetOption", nameMeter, "Text", ellipsis(event.summary, 30))
            SKIN:Bang("!SetOption", nameMeter, "ToolTipText", event.summary)
            SKIN:Bang("!SetOption", daysMeter, "Text", daysText)
            SKIN:Bang("!SetOption", daysMeter, "FontColor", event.daysColor)

            if event.daysLeft == 0 then
                SKIN:Bang("!SetOption", daysMeter, "SolidColor", V("CdTodayPill", "255,82,82,34"))
                SKIN:Bang("!SetOption", daysMeter, "Padding", "6,1,6,1")
                SKIN:Bang("!SetOption", daysMeter, "FontWeight", "800")
            else
                SKIN:Bang("!SetOption", daysMeter, "SolidColor", "0,0,0,0")
                SKIN:Bang("!SetOption", daysMeter, "Padding", "0,0,0,0")
                SKIN:Bang("!SetOption", daysMeter, "FontWeight", "700")
            end

            SKIN:Bang("!SetOption", hitMeter, "ToolTipText", event.summary)

            SKIN:Bang("!ShowMeter", rowBgMeter)
            SKIN:Bang("!ShowMeter", bulletMeter)
            SKIN:Bang("!ShowMeter", nameMeter)
            SKIN:Bang("!ShowMeter", daysMeter)
            SKIN:Bang("!ShowMeter", hitMeter)
        else
            SKIN:Bang("!HideMeter", rowBgMeter)
            SKIN:Bang("!HideMeter", bulletMeter)
            SKIN:Bang("!HideMeter", nameMeter)
            SKIN:Bang("!HideMeter", daysMeter)
            SKIN:Bang("!HideMeter", hitMeter)
            SKIN:Bang("!SetOption", hitMeter, "ToolTipText", "")
        end
    end
end

function Refresh()
    Parse()
end
