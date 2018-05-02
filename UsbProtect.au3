#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=UsbProtect.ico
#AutoIt3Wrapper_Outfile=UsbProtect.exe
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.2
 Author:         Clement Bois

 Script Function:
	Troll Bad Guys

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here
#include <Crypt.au3>
#include <File.au3>
_Crypt_Startup()

$Salt = IniRead('./UsbProtect.ini', 'Settings', 'Salt', 'MyLittlePony')
$Key = IniRead('./UsbProtect.ini', 'Settings', 'Key', '^{PGUP}')
$HashMethod = $CALG_SHA1
$Folder = @TempDir&'\UsbProtect'

$DBT_DEVICEARRIVAL = "0x00008000"
$WM_DEVICECHANGE = 0x0219
$UsbLocked = False
ToggleLock()

GUICreate("")
GUIRegisterMsg($WM_DEVICECHANGE , "DeviceChange")

DirCreate($Folder)
$Files = _FileListToArray($Folder)
If IsArray($Files) Then
	If $Files[0] > 0 Then
		If Msg($Folder&' remplis'&@CRLF&'Voulez vous le vider ?', 4) == $IDYES Then
			FileRecycle($Folder&'\*')
		EndIf
	EndIf
EndIf

While True
	HotKeySet($Key, "ToggleLock")
	Sleep(1)
WEnd

Func ToggleLock()
	$UsbLocked = Not $UsbLocked
	If $UsbLocked Then
		TraySetState(2)
	Else
		TraySetState(1)
	EndIf
EndFunc

Func DeviceChange($hWndGUI, $MsgID, $WParam, $LParam)
    If $WParam == $DBT_DEVICEARRIVAL and $UsbLocked Then
        $Drives = DriveGetDrive( "REMOVABLE" )
        For $i = 1 to $Drives[0]
			$Hash = _Crypt_HashData(($Salt&DriveGetLabel($Drives[$i])), $HashMethod)
			If Not FileExists($Drives[$i]&'\'&$Hash) Then
				$Files = _FileListToArray($Drives[$i])
				if IsArray($Files) Then
					; Make Bullshit
					For $j = 0 to 9
						DirCreate($Drives[$i]&'\'&Random(0,99,1)&'\'&Random(0,99,1)&'\'&Random(0,99,1))
					Next
					$Path = $Drives[$i]&'\'&Random(0,99,1)&'\'&'\'&Random(0,99,1)&'\'&Random(0,99,1)
					DirCreate($Path)
					For $j = 0 to 9
						DirCreate($Drives[$i]&'\'&Random(0,99,1)&'\'&Random(0,99,1)&'\'&Random(0,99,1))
					Next
					For $j = 1 to $Files[0]
						If $Files[$j] <> 'System Volume Information' Then
							If Not DirMove($Drives[$i]&'\'&$Files[$j], $Path&'\'&$Files[$j]) Then
								FileMove($Drives[$i]&'\'&$Files[$j], $Path&'\'&$Files[$j])
							EndIf
						EndIf
					Next
					For $j = 0 to 81
						DirCreate($Drives[$i]&'\'&Random(0,99,1)&'\'&Random(0,99,1)&'\'&Random(0,99,1))
					Next

					; Moving
					DirCreate($Folder&'\'&$Hash)
					For $j = 1 to $Files[0]
						If $Files[$j] <> 'System Volume Information' Then
							If DirMove($Path&'\'&$Files[$j], $Folder&'\'&$Hash&'\'&$Files[$j]) Then
								DirRemove($Path&'\'&$Files[$j], 1)
							Else
								If FileMove($Path&'\'&$Files[$j], $Folder&'\'&$Hash&'\'&$Files[$j]) Then
									FileDelete($Path&'\'&$Files[$j])
								EndIf
							EndIf
						EndIf
					Next
					If FileExists($Folder&'\'&$Hash) Then
						$Text = "Drive "&DriveGetLabel($Drives[$i])&"("&$Drives[$i]&")"&" trolled."
						Msg($Text, 0, 4)
						run ("rundll32.exe user32.dll LockWorkStation")
						Msg($Text)
					EndIf
				EndIf
			EndIf
        Next
    EndIf
EndFunc

Func Msg($text, $flag= 0, $timeout = 0)
	Return MsgBox($flag, 'UsbProtect', $text, $timeout)
EndFunc