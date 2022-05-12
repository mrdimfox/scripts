; Original script source: https://gist.github.com/andrewgodwin/89920ee02501ab12d09b02500897066c

; How much height of screen size the terminal window takes.
VRatio := 0.7
; How much width of screen size the terminal window takes.
HRatio := 0.75

; The path to the Windows Terminal exe file.
WtPath = "%LOCALAPPDATA%\Microsoft\WindowsApps\wt.exe"

#SC29::ToggleTerminal()

ReleaseModifiers(timeout := "") ; timeout in ms
{
	static	aModifiers := ["Ctrl", "Alt", "Shift", "LWin", "RWin"]
	
	startTime := A_Tickcount
	while (isaKeyPhysicallyDown(aModifiers))
	{
		if (timeout && A_Tickcount - startTime >= timeout)
			return 1 ; was taking too long
		sleep, 5
	}
	return
}

isaKeyPhysicallyDown(Keys)
{
  if isobject(Keys)
  {
    for Index, Key in Keys
      if getkeystate(Key, "P")
        return key
  }
  else if getkeystate(Keys, "P")
  	return Keys ;keys!
  return 0
}

ShowAndPositionTerminal()
{
    ScreenX := 0
    ScreenY := 0
    ScreenWidth := A_ScreenWidth
    ScreenHeight := A_ScreenHeight

    global VRatio
    global HRatio

    WinWidth := ScreenWidth - (1 - HRatio) * ScreenWidth
    WinHeight := ScreenHeight * VRatio
    WinX := ScreenX + (ScreenWidth - WinWidth) / 2 + 25
    WinY := ScreenY - 10

    WinShow ahk_class CASCADIA_HOSTING_WINDOW_CLASS
    WinActivate ahk_class CASCADIA_HOSTING_WINDOW_CLASS

    WinMove, ahk_class CASCADIA_HOSTING_WINDOW_CLASS,, WinX, WinY, WinWidth, WinHeight,
}

ToggleTerminal()
{
    ReleaseModifiers()

    WinMatcher := "ahk_class CASCADIA_HOSTING_WINDOW_CLASS"

    DetectHiddenWindows, On

    if WinExist(WinMatcher)
    ; Window Exists
    {
        DetectHiddenWindows, Off

        ; Check if its hidden
        if !WinExist(WinMatcher) || !WinActive(WinMatcher)
        {
            ShowAndPositionTerminal()
        }
        else if WinExist(WinMatcher)
        {
            ; Script sees it without detecting hidden windows, so..
            WinHide ahk_class CASCADIA_HOSTING_WINDOW_CLASS
            Send !{Esc}
        }
    }
    else
    {
        global WtPath
        Run %WtPath%
        Sleep, 1000
        ShowAndPositionTerminal()
    }
}
