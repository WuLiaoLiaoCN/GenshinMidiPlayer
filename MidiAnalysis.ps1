Function GetMidiContent([string]$MidiFilePath)
{
    #获取Midi文件内容
    return Get-Content -Path $MidiFilePath -Encoding Byte
}

Function SplitMidiContent($MidiFileContent)
{
    #分割Midi数据区块
    $StartFlag = 0
    $EndFlag = 0
    [System.Collections.Generic.List[byte[]]]$Midi = @()
    for($i=0;$i -lt $MidiFileContent.Length;$i++)
    {
        if(($MidiFileContent[$i] -eq '77') -and ($MidiFileContent[$i+1] -eq '84') -and ($MidiFileContent[$i+2] -eq '114') -and ($MidiFileContent[$i+3] -eq '107'))
        {
            $StartFlag=$EndFlag
            $EndFlag=$i
            [byte[]]$SubArray=$MidiFileContent[$StartFlag..($EndFlag-1)]
            $Midi.Add($SubArray)
        }
    }
    $StartFlag=$EndFlag
    [Int32[]]$SubArray=$MidiFileContent[$StartFlag..($MidiFileContent.Length-1)]
    $Midi.Add($SubArray)
    return $Midi
}

Function GetMidiFormat([System.Collections.Generic.List[byte[]]]$Midi)
{
    $result = $Midi[0][8]*256+$Midi[0][9]
    Write-Host "全局Midi格式为" $result
}

Function GetSoundTrackCount([System.Collections.Generic.List[byte[]]]$Midi)
{
    $result = $Midi[0][10]*256+$Midi[0][11]
    Write-Host "全局音轨数量为" $result
}

Function GetQuarterNoteTicks([System.Collections.Generic.List[byte[]]]$Midi)
{
    $result = $Midi[0][12]*256+$Midi[0][13]
    Write-Host "全局4分音符Ticks" $result
}

Function GetSoundTrackBeatSpeed([byte[]]$SoundTrack)
{
    for($i=0;$i -lt $SoundTrack.Length;$i++)
    {
        if(($SoundTrack[$i+1] -eq '255') -and ($SoundTrack[$i+2] -eq '81'))
        {
            $byteCount = $SoundTrack[$i+3]
            $result = 0;
            for($j=1;$j -le $byteCount;$j++)
            {
                $num= $SoundTrack[$i+3+$j]
                $result += [math]::pow(256,$byteCount-$j)*$num
            }
            Write-host "节奏信息：" $result
        }
    }
}

Function GetSoundTrackActions([byte[]]$SoundTrack)
{
    $pointer = 0
    $timeLine = 0
    [System.Collections.Generic.List[Int[]]] $KeyNotes = @()
    for($i=0;$i -lt $SoundTrack.Length;$i++)
    {
        if(($SoundTrack[$i] -ge 144) -and ($SoundTrack[$i] -le 159))
        {
            $pointer= $i-1
            [Int[]]$keyNote = $SoundTrack[$pointer],$SoundTrack[$pointer+1],$SoundTrack[$pointer+2],$SoundTrack[$pointer+3]
            $timeLine+= $SoundTrack[$pointer]
            $KeyNotes.Add($keyNote)
            $pointer +=4
            break
        }
    }
    while($pointer -le $soundTrack.Count)
    {
        $deltaTime=0
        $action=0
        $note=0
        $depth=0

        if($SoundTrack[$pointer] -ge 129){
            while($SoundTrack[$pointer] -ge 129)
            {
                $realNumber = $SoundTrack[$pointer]%128
                $deltaTime = $deltaTime*128 + $realNumber
                $pointer++
            }
            $deltaTime =$deltaTime*128 + $SoundTrack[$pointer]
            $pointer++
        }
        else
        {
            $deltaTime = $SoundTrack[$pointer]
            $pointer++
        }

        if(($SoundTrack[$pointer] -eq 255) -and ($SoundTrack[$pointer+1] -eq 47))
        {
            break
        }

        if($SoundTrack[$pointer] -eq 255)
        {
            $skipCount = $SoundTrack[$pointer+2]
            $pointer+=($skipCount+3)
            $timeLine += $deltaTime
            continue
        }

        if($SoundTrack[$pointer] -ge 128)
        {
            $action = $SoundTrack[$pointer]
            $pointer++
            if(($action -ge 192) -and ($action -le 233))
            {
                $note= $SoundTrack[$pointer]
                $pointer++
                $depth= 0
            }
            else
            {
                $note= $SoundTrack[$pointer]
                $pointer++
                $depth= $SoundTrack[$pointer]
                $pointer++
            }
        }
        else
        {
            $action=0
            $note= $SoundTrack[$pointer]
            $pointer++
            $depth= $SoundTrack[$pointer]
            $pointer++
        }
        $timeLine += $deltaTime
        [Int[]]$keyNote = $timeLine,$action,$note,$depth
        $KeyNotes.Add($keyNote)
    }
    return $KeyNotes
}

Function GetKeyPressNote([System.Collections.Generic.List[Int[]]] $KeyNotes)
{
    [System.Collections.Generic.List[Int[]]]$result = @()
    foreach($item in $KeyNotes)
    {
        if(($item[1] -ge 144) -and ($item[1] -le 159))
        {
            $result.Add($item)
        }
    }
    return $result
}



