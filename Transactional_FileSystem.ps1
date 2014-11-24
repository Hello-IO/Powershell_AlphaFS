#add AlphaFS library. 
$alphaFS_path = Join-Path $PSScriptRoot '\AlphaFS\AlphaFS.dll'
[System.Reflection.Assembly]::LoadFrom( $alphaFS_path)  |Out-Null

#Import Invoke-Using Module for auto-dispose of objects
$using_path = Join-Path $PSScriptRoot -ChildPath 'Invoke-Using.psm1'
Import-Module $using_path



function Get-LongPath{
    param([parameter(Mandatory=$true,Position=0)][string[]]$LiteralPath)
    [Alphaleonis.Win32.FileSystem.Path]::GetLongPath($LiteralPath)
}

function Invoke-FileSystemTransaction{
    param([ScriptBlock]$Action)
   
    Start-Transaction
    Invoke-Using ( $kt = New-Object Alphaleonis.Win32.Filesystem.KernelTransaction ){
        try{
            $Action.Invoke()
            [void] $kt.Commit()            
        }
        catch{
            "[Invoke-FileSystemTransaction Error] `r`n $_.Exception.InnerException" 
        }finally{
            Complete-Transaction
        }        
    }    #END Invoke-Using    
} #END New-KernelTransaction

function New-FileInfo{
    param($KernelTransaction,$LiteralPath )
    $fileInfo = New-Object Alphaleonis.Win32.Filesystem.FileInfo($KernelTransaction,$LiteralPath)
    $fileInfo
}


function Move-File{
    param([parameter(Mandatory=$true,Position=0)][string[]]$LiteralPath
          ,[parameter(Mandatory=$true,Position=1)][string]$Destination)
    $fileInfos = New-Object 'System.Collections.Generic.List[System.IO.FileInfo]'
     
    $action = {
                foreach($path in $LiteralPath){
                $fileInfo = New-FileInfo $kt (Get-LongPath $path)
                $fileInfo.MoveTo( (Join-Path $Destination $fileInfo.Name)  )
                }   
    }   #END action
     
    Invoke-FileSystemTransaction -Action $action   

}

