<#
GNU General Public License, Version 2.0

Copyright (C) 2025 KITA Munemitsu
https://github.com/kmu2030/PwshOpcUaClient

This program is free software; you can redistribute it and/or modify it under the terms of
the GNU General Public License as published by the Free Software Foundation;
either version 2 of the License, or (at your option) any later version.
This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License along with this program;
if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
#>

<#
# About This Script
This script performs pseudo UA method calls for FBs published using
the "Variables in User-defined Function Blocks Published to OPC UA Communications" feature
on OMRON's NX and NJ controllers and the Sysmac Studio OPU UA server.

## Usage Environment
Controllers: OMRON Co., Ltd. NX1 (Ver. 1.64 or later), NX5 (Ver. 1.64 or later), NX7 (Ver. 1.35 or later), NJ5 (Ver. 1.63 or later)
IDE:Sysmac Studio Ver.1.62 or later
PowerShell: PowerShell 7.5 or later

## Usage Steps (Simulator)
1.  Run `./PwshOpcUaClient/setup.ps1`.
    This retrieves the assemblies required by `PwshOpcUaClient` using NuGet.
2.  Open `ExamplePseudoUAMethod.smc2` in Sysmac Studio.
3.  Start the simulator and the OPC UA server for simulation.
4.  Generate a certificate on the OPC UA server for simulation.   
    This step is unnecessary if a certificate has already been generated.
5.  Register a user and password for the OPC UA server for simulation.   
    This step is unnecessary if a user has already been registered.
6.  Run `ExamplePseudoUAMethod.ps1`.

## Usage Steps (Controller)
1.  Run `./PwshOpcUaClient/setup.ps1`.
    This retrieves the assemblies required by `PwshOpcUaClient` using NuGet.
2.  Open `ExamplePseudoUAMethod.smc2` in Sysmac Studio.
3.  Adjust the project's configuration and settings to match the controller you are using.
4.  Transfer the project to the controller.
5.  Generate a certificate on the controller's OPC UA server.   
    This step is unnecessary if a certificate has already been generated.
6.  Register a user and password for the controller's OPC UA server.   
    This step is unnecessary if a user has already been registered.
7.  Run `ExamplePseudoUAMethod.ps1`.
8.  Trust the client certificate on the controller's OPC UA server. Trust the rejected client certificate.   
    This step is unnecessary if you are using anonymous access without signing or encryption for message exchange.
9.  Run `ExamplePseudoUAMethod.ps1`.


# このスクリプトについて
このスクリプトはOMRON社のNX、NJコントローラ、Sysmac StudioのOPU UAサーバの
"ユーザ定義ファンクションブロックの変数の OPC UA 通信への公開"機能で公開したFBについて、
疑似的なUA Method呼び出しを行います。

## 使用環境
コントローラ : OMRON社製 NX1(Ver.1.64以降), NX5(Ver.1.64以降), NX7(Ver.1.35以降), NJ5(Ver.1.63以降)
IDE         : Sysmac Studio Ver.1.62以降
PowerShell  : PowerShell 7.5以降

## 使用手順 (シミュレータ)
1.  `./PwshOpcUaClient/setup.ps1`を実行
    `PwshOpcUaClient`が必要とするアセンブリをNuGetで取得。
2.  Sysmac Studioで`ExamplePseudoUAMethod.smc2`を開く
3.  シミュレータとシミュレーション用OPC UAサーバを起動
4.  シミュレーション用OPC UAサーバで証明書を生成
    既に生成してある場合は不要。
5.  シミュレーション用OPC UAサーバへユーザーとパスワードを登録
    既に登録してある場合は不要。
6.  `ExamplePseudoUAMethod.ps1`を実行

## 使用手順 (コントローラ)
1.  `./PwhsOpcUaClient/setup.ps1`を実行
    `PwshOpcUaClient`が必要とするアセンブリをNuGetで取得。
2.  Sysmac Studioで`ExamplePseudoUAMethod.smc2`を開く
3.  プロジェクトの構成と設定を使用するコントローラに合わせる
4.  プロジェクトをコントローラに転送
5.  コントローラのOPC UAサーバで証明書を生成
    既に生成してある場合は不要。
6.  コントローラのOPC UAサーバへユーザーとパスワードを登録
    既に登録してある場合は不要。
7.  `ExamplePseudoUAMethod.ps1`を実行
8.  コントローラのOPC UAサーバでクライアント証明書の信頼
    拒否されたクライアント証明書を信頼する。
    Anonymousでメッセージ交換に署名も暗号化も使用しないのであれば不要。
9.  `ExamplePseudoUAMethod.ps1`を実行
#>

using namespace Opc.Ua
param(
    [bool]$UseSimulator = $true,
    [string]$ServerUrl = 'opc.tcp://localhost:4840',
    [bool]$UseSecurity = $true,
    [string]$UserName = 'taker',
    [string]$UserPassword = 'chocolatepancakes',
    [double]$Interval = 0.05
)
. "$PSScriptRoot/PwshOpcUaClient/PwshOpcUaClient.ps1"

function Main () {
    try {
        $AccessUserIdentity = [string]::IsNullOrEmpty($UserName) `
                                ? (New-Object UserIdentity) `
                                : (New-Object UserIdentity -ArgumentList $UserName, $UserPassword)
        $clientParam = @{
            ServerUrl = $ServerUrl
            UseSecurity = $UseSecurity
            SessionLifeTime = 60000
            AccessUserIdentity = $AccessUserIdentity
        }
        $client = New-PwshOpcUaClient @clientParam

        $in1 = 0
        $in2 = 1000
        While ($true) {
            $result = Call-MyAdd -Session $client.Session -In1 $in1 -In2 $in2
            "MyAdd($in1, $in2) = $result"
                | Write-Host

            ++$in1

            if ($in1 -gt 100) { break }
            Start-Sleep -Seconds $Interval
        }
    }
    catch {
        $_.Exception
    }
    finally {
        Dispose-PwsOpcUaClient -Client $client
    }
}

function Call-MyAdd() {
    param(
        [ISession]$Session,
        [UInt16]$In1,
        [UInt16]$In2
    )

    $baseNodeId = $UseSimulator `
                    ? 'ns=2;s=Programs.Methods.MyAdd'
                    : 'ns=4;s=Methods/MyAdd'
    $separator = $UseSimulator ? '.' : '/'

    # Create call method parameters.
    $callParams = New-Object WriteValueCollection
    $callParam = New-Object WriteValue
    $callParam.NodeId = New-Object NodeId -ArgumentList (@($baseNodeId, 'In1') -join $separator)
    $callParam.AttributeId = [Attributes]::Value
    $callParam.Value = New-Object DataValue
    $callParam.Value.Value = $In1
    $callParams.Add($callParam)
    $callParam = New-Object WriteValue
    $callParam.NodeId = New-Object NodeId -ArgumentList (@($baseNodeId, 'In2') -join $separator)
    $callParam.AttributeId = [Attributes]::Value
    $callParam.Value = New-Object DataValue
    $callParam.Value.Value = $In2
    $callParams.Add($callParam)
    $callParam= New-Object WriteValue
    $callParam.NodeId = New-Object NodeId -ArgumentList (@($baseNodeId, 'Execute') -join $separator)
    $callParam.AttributeId = [Attributes]::Value
    $callParam.Value = New-Object DataValue
    $callParam.Value.Value = [bool]$true
    $callParams.Add($callParam)

    $results = $null
    $diagnosticInfos = $null
    $response = $Session.Write(
        $null,
        $callParams,
        [ref]$results,
        [ref]$diagnosticInfos
    )
    if ($null -ne ($exception = ValidateResponse `
                                    $response `
                                    $results `
                                    $diagnosticInfos `
                                    $callParams `
                                    'Failed to execute.')
    ) {
        throw $exception
    }

    # Create done call parameters.
    $doneParams = New-Object ReadValueIdCollection
    $doneParam = New-Object ReadValueId -Property @{
        AttributeId = [Attributes]::Value
    }
    $doneParam.NodeId = New-Object NodeId -ArgumentList (@($baseNodeId, 'Done') -join $separator)
    $doneParams.Add($doneParam)

    $doneParam= New-Object ReadValueId -Property @{
        AttributeId = [Attributes]::Value
    }
    $doneParam.NodeId = New-Object NodeId -ArgumentList (@($baseNodeId, 'Out') -join $separator)
    $doneParams.Add($doneParam)

    $results= New-Object DataValueCollection
    $diagnosticInfos = New-Object DiagnosticInfoCollection
    do {
        $response = $Session.Read(
            $null,
            [double]0,
            [TimestampsToReturn]::Both,
            $doneParams,
            [ref]$results,
            [ref]$diagnosticInfos
        )
        if ($null -ne ($exception = ValidateResponse `
                                        $response `
                                        $results `
                                        $diagnosticInfos `
                                        $doneParams `
                                        'Failed to done.')
        ) {
            throw $exception
        }
    }
    until ($results.Count -gt 0 -and $results[0].Value)

    $retVal = $results[1].Value

    $clearParams = New-Object WriteValueCollection
    $clearParam = New-Object WriteValue
    $clearParam.NodeId = New-Object NodeId -ArgumentList (@($baseNodeId, 'Execute') -join $separator)
    $clearParam.AttributeId = [Attributes]::Value
    $clearParam.Value = New-Object DataValue
    $clearParam.Value.Value = [bool]$false
    $clearParams.Add($clearParam)

    $results = $null
    $diagnosticInfos = $null
    $Session.Write(
        $null,
        $clearParams,
        [ref]$results,
        [ref]$diagnosticInfos
    ) | Out-Null
    if ($null -ne ($exception = ValidateResponse `
                                    $response `
                                    $results `
                                    $diagnosticInfos `
                                    $clearParams `
                                    'Failed to clear.')
    ) {
        throw $exception
    }     

    return $retVal
}

class OpcUaFetchException : System.Exception {
    [hashtable]$CallInfo
    OpcUaFetchException([string]$Message, [hashtable]$CallInfo) : base($Message)
    {
        $this.CallInfo = $CallInfo
    }
}

function ValidateResponse {
    param(
        $Response,
        $Results,
        $DiagnosticInfos,
        $Requests,
        $ExceptionMessage
    )

    if (($Results
            | Where-Object { $_ -is [StatusCode]}
            | ForEach-Object { [ServiceResult]::IsNotGood($_) }
        ) -contains $true `
        -or ($Results.Count -ne $Requests.Count)
    ) {
        return [OpcUaFetchException]::new($ExceptionMessage, @{
            Response = $Response
            Results = $Results
            DiagnosticInfos = $DiagnosticInfos
        })
    } else {
        return $null
    }
}

Main
