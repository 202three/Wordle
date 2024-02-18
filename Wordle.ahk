#SingleInstance, Force

;;;;;;;;;;;;;;;

rowCount := 6 ;2 minimum
colCount := 5 ;3 minimum

Initialize:

gameActive := 1
dictionaryPath := A_ScriptDir "\dictionary.txt"
colWidth := 30
marginWidth := 4
marginHeight := 4
headerFooterWidth := (colWidth * colCount) + ((colCount - 1) * marginWidth) + 1
footerColWidth := (headerFooterWidth / 2) - (marginWidth / 2)
footerColWidthEditPos := (rowCount * colCount) + 2

activeRow := 1
guiTitle := "Wordle"

;;;;;;;;;;;;;;;Build GUI

Gui, Margin, %marginWidth%, %marginHeight%

gui, add, button, w%footerColWidth% section gReset, Reset
gui, add, button, w%footerColWidth% ys ggiveUp, Give Up

gui, add, text, section xs w%headerFooterWidth% h20 center, %guiTitle%


Gui, Font, Bold

loop % rowCount
	{
	rowIndex := A_Index
	if (rowIndex = 1)
		disabledVar := ""
	else
		disabledVar := "disabled"
	
	loop % colCount
		{
		colIndex := A_Index
		
		if (colIndex = 1)
			sectionVar := "section xs"
		else
			sectionVar := "ys"
		
		gui, add, edit, %sectionVar% w%colWidth% limit1 Uppercase gOnEntry %disabledVar% center vR%rowIndex%C%colIndex%
		}
	}

Gui, Font
gui, add, edit, section xs w%headerFooterWidth% center vStatusDisplay ReadOnly,Waiting for user...

gui add, text, w%footerColWidth% section xs y+7 center,Cols/Rows:
gui, add, edit, w%footerColWidth% ys-3 vcolRowInput center,%colCount%/%rowCount%

gosub, loadDictionary
gosub, getRandomWord
gosub, setIneractiveLimit

gui,show,,%guiTitle%

GroupAdd, currentWinGroupname, %guiTitle%

ControlFocus,Edit1,A

return

;;;;;;;;;;;;;;;

setIneractiveLimit:

interactiveLimitArr := []
startingEditNum := colCount * (activeRow - 1) + 1

loop % colCount
	{
	indexAdjust := A_Index - 1
	interactiveArrEntry := indexAdjust + startingEditNum
	interactiveLimitArr[interactiveArrEntry] := interactiveArrEntry
	}

return

;;;;;;;;;;;;;;;

OnEntry:

ControlGetFocus, currentEditFocus, %guiTitle%

currentEditFocusNum := StrReplace(currentEditFocus,"Edit")

currentEditFocusNum++

if !interactiveLimitArr[currentEditFocusNum] ;|| !CurrentContent
	return

ControlFocus,Edit%currentEditFocusNum%,A

Return

;;;;;;;;;;;;;;;

Reset:

Gui, Submit, NoHide

if !RegExMatch(colRowInput, "\d+\/\d+")
	{
	GuiControl,, StatusDisplay, Bad Row/Col Input!
	return
	}

tempInputColRowArr := StrSplit(colRowInput, "/")
if (tempInputColRowArr[1] < 3)
	{
	GuiControl,, StatusDisplay, Col > 3 !
	return
	}
if (tempInputColRowArr[2] < 2)
	{
	GuiControl,, StatusDisplay, Row > 2 !
	return
	}
	
colCount := tempInputColRowArr[1]
rowCount := tempInputColRowArr[2]

gui, destroy
gosub, Initialize

Return

;;;;;;;;;;;;;;;

loadDictionary:

if !FileExist(dictionaryPath)
	{
	msgbox,,,Dictionary not found!
	ExitApp
	}

pickDictionary := {}
checkDictionary := {}
totalDicCount := 0

Loop, read, %dictionaryPath%
	{
	if (StrLen(A_LoopReadLine) = colCount)
		{
		totalDicCount++
		pickDictionary[totalDicCount] := A_LoopReadLine
		checkDictionary[A_LoopReadLine] := A_LoopReadLine
		}
	}

if (totalDicCount = 0)
	{
	msgbox,,,No valid words found in dictionary!
	ExitApp
	}

return

;;;;;;;;;;;;;;;

getRandomWord:

Random randomPos, 1, %totalDicCount%
currentWord := pickDictionary[randomPos]
currentWordArray := StrSplit(currentWord)

return

;;;;;;;;;;;;;;;

#IfWinActive ahk_group currentWinGroupname

Enter::
NumpadEnter::

ControlGetFocus, currentEditFocus, %guiTitle%

currentEditFocusNum := StrReplace(currentEditFocus,"Edit")

if (currentEditFocusNum = footerColWidthEditPos)
	{
	gosub, Reset
	return
	}

loop % colCount
	{
	GuiControlGet, lastColValue ,, R%activeRow%C%A_Index%
	if !lastColValue
		return
	}

activeRowWordGuess := ""

Loop % colCount
	{
	GuiControlGet, lastColValue ,, R%activeRow%C%A_Index%
	activeRowWordGuess .= lastColValue
	}

if !checkDictionary[activeRowWordGuess]
	{
	GuiControl,, StatusDisplay, Not a word!
	return
	}

if (currentWord = activeRowWordGuess)
	{
	loop % colCount
		{
		Gui, Font, c0x21D375 Bold ;green
		GuiControl, Font, R%activeRow%C%A_Index%
		GuiControl, +ReadOnly, R%activeRow%C%A_Index%
		}
	GuiControl,, StatusDisplay, You Win!
	gameActive := 0
	return
	}

greenLettersArray := {}
yellowLettersArray := {}
lettersArrayExclude := {}
yellowLettersArrayAssoc := {}

loop % colCount
	{
	firstIndexNum := A_Index
	GuiControlGet, checkCurrentLetter ,, R%activeRow%C%firstIndexNum%
	
	if (checkCurrentLetter = currentWordArray[firstIndexNum])
			{
			greenLettersArray[firstIndexNum] := checkCurrentLetter
			lettersArrayExclude[firstIndexNum] := checkCurrentLetter
			continue
			}
	loop % colCount
		{
		secondIndexCheck := A_Index

		if (checkCurrentLetter = currentWordArray[secondIndexCheck])
			{
			yellowLettersArray[firstIndexNum] := checkCurrentLetter	
			yellowLettersArrayAssoc[secondIndexCheck] := firstIndexNum	
			continue
			}
		GuiControl, +ReadOnly, R%activeRow%C%firstIndexNum%
		}
	}

for k,v in lettersArrayExclude
	{
	for k2,v2 in yellowLettersArrayAssoc
		{
		if (k = k2)
			yellowLettersArray.Remove(v2)
			break
		}
	}
	
for k,v in greenLettersArray
	{
	Gui, Font, c0x21D375 Bold ;green
	GuiControl, Font, R%activeRow%C%k%
	GuiControl, +ReadOnly, R%activeRow%C%k%
	}

for k,v in yellowLettersArray
	{
	Gui, Font, c0xFFA500 Bold ;Orange Yellow
	GuiControl, Font, R%activeRow%C%k%
	GuiControl, +ReadOnly, R%activeRow%C%k%
	}

activeRow++

if (activeRow > rowCount)
	{
	gosub, losingProcess
	return
	}
	
loop % colCount
	{
	GuiControl, enable, R%activeRow%C%A_Index%
	GuiControl, -ReadOnly, R%activeRow%C%A_Index%
	}

currentFirstFocus := 1 + (colCount * (activeRow - 1))
ControlFocus, Edit%currentFirstFocus%, A

gosub, setIneractiveLimit

return

;;;;;;;;;;;;;;;

giveUp:

if (gameActive = 0)
	return

gosub, losingProcess

return

;;;;;;;;;;;;;;;

losingProcess:

GuiControl,, StatusDisplay, You Lose! [%currentWord%]
gameActive := 0

loop % rowCount
	{
	tempRowIndex := A_Index
	loop % colCount
		{
		tempColumnIndex := A_Index
		GuiControl, disable, R%tempRowIndex%C%tempColumnIndex%
		GuiControl, +ReadOnly, R%tempRowIndex%C%tempColumnIndex%
		}
	}

return

;;;;;;;;;;;;;;;

Backspace::

ControlGetFocus, currentEditFocus, %guiTitle%

currentEditFocusNum := StrReplace(currentEditFocus,"Edit")

if (currentEditFocusNum = footerColWidthEditPos)
	{
	GuiControl,, Edit%currentEditFocusNum%
	return
	}

colAdjustedValue := Mod(currentEditFocusNum, colCount)

if (colAdjustedValue = 0)
	colAdjustedValue := colCount

originalEditFocusNum := colAdjustedValue

GuiControl, -g, R%activeRow%C%colAdjustedValue%

GuiControlGet,CurrentContent,,R%activeRow%C%colAdjustedValue%

if (CurrentContent)
	{
	GuiControl,, %currentEditFocus%
	ControlFocus,Edit%currentEditFocus%,A
	GuiControl, +gOnEntry, R%activeRow%C%colAdjustedValue%
	return
	}

currentEditFocusNum--

if !interactiveLimitArr[currentEditFocusNum]
	return

colAdjustedValue := Mod(currentEditFocusNum, colCount)

if (colAdjustedValue = 0)
	colAdjustedValue := colCount

GuiControl, -g, R%activeRow%C%colAdjustedValue%

GuiControl,, Edit%currentEditFocusNum%
ControlFocus,Edit%currentEditFocusNum%,A

GuiControl, +gOnEntry, R%activeRow%C%originalEditFocusNum%
GuiControl, +gOnEntry, R%activeRow%C%colAdjustedValue%

return

#If

;;;;;;;;;;;;;;;

GuiClose:
ExitApp