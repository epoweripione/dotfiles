# https://blog.csdn.net/qwertyupoiuytr/article/details/78123958
# Usage:
# . ".\json_parser.ps1"; $ret = JSONParser -Path jsonData.json -FirstObjectType Dictionary

function JSONParser() {       
    param(
        # Path
        [Parameter(Mandatory = $true)] 
        [string]$Path,

        # Type
        [Parameter(Mandatory = $true)]
        [ValidateSet('Array', 'Dictionary')]
        [string]$FirstObjectType
    )
 
    $content = Get-Content -Path $Path -ErrorAction Ignore;
    if ($null -eq $content) {
        return;
    }
    $linesCount = $content.Count;

    function GetPropertyWithEnd($line, $propertySearchTag, $endSearchTag) {
        if ($line.Contains($propertySearchTag)) {
            $value = $line.Substring($line.IndexOf($propertySearchTag) + $propertySearchTag.Length);
            if ($value.IndexOf($endSearchTag) -ge 0) {
                $value = $value.Substring(0, $value.IndexOf($endSearchTag));
            }
            return $value;
        }
        return "";
    }

    function GetProperty($line, $propertySearchTag) {
        if ($line.Contains($propertySearchTag)) {
            $value = $line.Substring($line.IndexOf($propertySearchTag) + $propertySearchTag.Length);
            return $value;
        }
        return "";
    }

    function GetArrayObject($array, $index) {
        $line = (GetLine $index);
        if ($null -eq $line) {
            return ($array, $index);
        }
        if ($line -eq "]" -or $line -eq "],") {
            $index++;
            return ($array, $index);
        }
        $value = $line.Trim(' ');
        if ($value -eq "[") {
            $index++;
            $chindArray = @();
            $ret = (GetArrayObject $chindArray $index);
            $value = $ret[0];
            $index = $ret[1];
        } elseif ($value -eq "{") {
            $index++;
            $childDict = @{};
            $ret = (GetDictObject $childDict $index);
            $value = $ret[0];
            $index = $ret[1];
        } else {
            $index++;
            if ($value.Contains('"')) {
                $value = (GetPropertyWithEnd $value '"' '"');
            } else {
                $value = $value.TrimEnd(',');
                if ($value -eq "{}") {
                    $value = @{};
                }
                if ($value -eq "[]") {
                    $value = @();
                }
            }
        }
        $array += $value;
        $ret = (GetArrayObject $array $index);
        $array = $ret[0];
        $index = $ret[1];
        return ($array, $index);
    }

    function GetDictObject($dict, $index, $defaultKey) {
        $line = (GetLine $index);
        if ($null -eq $line) {
            return ($dict, $index);
        }
        if ($line -eq "}" -or $line -eq "},") {
            $index++;
            return ($dict, $index);
        }
        $key = $defaultKey;
        $value = $line;
        if ($null -eq $defaultKey) {
            $splitIndex = $line.IndexOf(":");
            if ($splitIndex -ge 0) {
                $key = (GetPropertyWithEnd $line.Substring(0, $splitIndex) '"' '"');
                $value = $line.Substring($splitIndex + 1).Trim(' ');
            }
        }
        if ($value -eq "[") {
            $index++;
            $chindArray = @();
            $ret = (GetArrayObject $chindArray $index);
            $value = $ret[0];
            $index = $ret[1];
        } elseif ($value -eq "{") {
            $index++;
            $childDict = @{};
            $ret = (GetDictObject $childDict $index);
            $value = $ret[0];
            $index = $ret[1];
        } else {
            $index++;
            if ($value.Contains('"')) {
                $value = (GetPropertyWithEnd $value '"' '"');
            } else {
                $value = $value.TrimEnd(',');
                if ($value -eq "{}") {
                    $value = @{};
                }
                if ($value -eq "[]") {
                    $value = @();
                }
            }
        }
        if ($null -eq $key) {
            return ($dict, $index);
        }
        $dict.Add($key, $value);
        $ret = (GetDictObject $dict $index);
        $dict = $ret[0];
        $index = $ret[1];
        return ($dict, $index);
    }

    function GetLine($index, $escapeChars=@()) {
        if ($index -lt $linesCount) {
            $line = $content[$index];
            Write-Host $line;
            #dealing with special chars
            foreach ($escapeChar in $escapeChars) {
                if ($line.Contains($escapeChar)) {
                    $line = $line.Replace($escapeChar, "\"+$escapeChar);
                }
            }
            return $line.Trim(' ');
        } else {
            return $null;
        }
    }

    function ParseContent() {
        if ($FirstObjectType -eq "Array") {
            $result = @();
            $result = (GetArrayObject $result 0)[0];
            return $result;
        } elseif ($FirstObjectType -eq "Dictionary") {
            $result = @{};
            $result = (GetDictObject $result 0 "defaultKey")[0]["defaultKey"];
            return $result;
        }
    }

    return ParseContent;
}