[Variables]
; Include global variables
@Include=#SKINSPATH#@Global\Variables.inc

; --- Google Calendar Integration ---
CalendarURL=https://calendar.google.com/calendar/ical/israelquilonsanchez%40gmail.com/public/basic.ics

; --- Calendar-specific Layout ---
BarHeight=40
SkinWidth=260

; --- Calendar Visual Tokens ---
CalHeaderBg=255,245,170,130
CalHeaderText=40,40,40,185
CalDayText=255,255,255,180
CalWeekendText=235,235,235,130
CalWeekendHeader=70,70,70,165
CalTodayText=#ColorToday#
CalSelectedText=#ColorAccent#
CalSelectedBg=255,255,255,18
CalTodayBg=255,255,255,10
CalHitIdleFill=255,255,255,5
CalHitHoverFill=255,255,255,14
CalHitHoverStroke=#ColorAccent#,90
CalMarkerShape=Rectangle -10,20,20,4 | Fill Color %s | StrokeWidth 0 || Ellipse 0,26,1.6,1.6 | Fill Color %s | StrokeWidth 0
CalListTitle=255,255,255,135
CalIconIdle=255,255,255,112
CalIconHover=#ColorAccent#

; --- Calendar Layout (Small) ---
CalSmall_RowStart=115
CalSmall_RowSpacing=50
CalSmall_ColStart=38
CalSmall_ColSpacing=44
CalSmall_TopBarY=27
CalSmall_LeftPad=16
CalSmall_RightPad=16
CalSmall_HitX=-18
CalSmall_HitY=-11
CalSmall_HitW=36
CalSmall_HitH=36
CalSmall_HitR=8

; --- Calendar Layout (Big) ---
CalBig_RowStart=180
CalBig_RowSpacing=115
CalBig_ColStart=55
CalBig_ColSpacing=100
CalBig_TopBarY=25
CalBig_LeftPad=26
CalBig_RightPad=26
CalBig_HitX=-45
CalBig_HitY=-11
CalBig_HitW=90
CalBig_HitH=90
CalBig_HitR=8
CalBig_EventOffsetX=-45
CalBig_EventOffsetY1=32
CalBig_EventOffsetY2=47

; --- Update Rates ---
UpdateIntervalCalendar=1800
