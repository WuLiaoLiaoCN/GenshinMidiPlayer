. ".\MidiAnalysis.ps1"
. ".\Key-SoundMap.ps1"

##
#运行时需要用Administrator权限打开Powershell ISE
#将运行目录切换到 GenshinPlayer 目录下
#进入游戏，打开风物之琴界面 点击开始即可开始演奏
#该脚本目前只支持演奏单音轨 三个八度的Midi乐谱
#Midi文件 放在 “.\MidiFile” 目录下
#想要正确演奏需要测试每个音轨的情况，选择正确的音轨
#如果需要演奏多个音轨可以自行调整代码（需要PowerShell 基础）
#对于风物之琴不支持的音会自动 降低 升高 一个音调，具体在 Key-SoundMap.ps1 中设置
##

#=============手动设置区=============
$gameWindowName = "原神"
$midiFileName = '.\MidiFile\ZhiAiLiSi.mid'
$ToneControl = 0 #调整音调 +16为升一个八度 -16为降一个八度
$SoundTrackSelect = 2 #0为全局信息 1为第一音轨 2为第二音轨 。。以此类推
$PlaySpeed = 3.5 #播放速度 取值范围为0.1~2 根据自己需求调整
#==================================

$wshell = New-Object -ComObject wscript.shell
$wshell.AppActivate($gameWindowName)
$content = GetMidiContent $midiFileName
$Midi = SplitMidiContent $content
GetMidiFormat $Midi
GetSoundTrackCount $Midi                                                  
$KeyNotes = GetSoundTrackActions $midi[$SoundTrackSelect]
$keyPress = GetKeyPressNote($KeyNotes)
$playPointer = 0
$KeyCount = $keyPress.count

Write-Host '即将开始自动演奏，请打开风物之琴并将原神游戏窗口设为焦点'
for($i=5;$i -gt 0 ;$i--)
{
    Write-Host '自动演奏将在' $i.ToString() '秒后开始'
    sleep -Seconds 1
}

$elapsed = [System.Diagnostics.Stopwatch]::StartNew()
while($true)
{
    if($playPointer -ge $KeyCount)
    {
        break
    }

    if(($keyPress[$playPointer][0]*$PlaySpeed) -lt $elapsed.Elapsed.TotalMilliseconds)
    {
        $wshell.SendKeys($KeySoundMap[$keyPress[$playPointer][2]+$ToneControl])
        $playPointer++
    }
}

