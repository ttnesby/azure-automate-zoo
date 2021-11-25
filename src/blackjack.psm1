$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

$docJson = '[{"suit":"DIAMONDS","value":"2"},{"suit":"DIAMONDS","value":"10"},{"suit":"HEARTS","value":"2"},{"suit":"DIAMONDS","value":"5"},{"suit":"HEARTS","value":"4"},{"suit":"HEARTS","value":"10"},{"suit":"CLUBS","value":"K"},{"suit":"CLUBS","value":"Q"},{"suit":"SPADES","value":"6"},{"suit":"DIAMONDS","value":"Q"},{"suit":"CLUBS","value":"2"},{"suit":"HEARTS","value":"A"},{"suit":"DIAMONDS","value":"A"},{"suit":"SPADES","value":"2"},{"suit":"SPADES","value":"7"},{"suit":"SPADES","value":"J"},{"suit":"SPADES","value":"Q"},{"suit":"SPADES","value":"3"},{"suit":"SPADES","value":"K"},{"suit":"HEARTS","value":"9"},{"suit":"SPADES","value":"A"},{"suit":"CLUBS","value":"5"},{"suit":"CLUBS","value":"9"},{"suit":"HEARTS","value":"3"},{"suit":"CLUBS","value":"8"},{"suit":"SPADES","value":"5"},{"suit":"HEARTS","value":"Q"},{"suit":"CLUBS","value":"4"},{"suit":"DIAMONDS","value":"8"},{"suit":"CLUBS","value":"3"},{"suit":"HEARTS","value":"8"},{"suit":"HEARTS","value":"7"},{"suit":"CLUBS","value":"A"},{"suit":"SPADES","value":"4"},{"suit":"DIAMONDS","value":"3"},{"suit":"CLUBS","value":"6"},{"suit":"DIAMONDS","value":"6"},{"suit":"DIAMONDS","value":"K"},{"suit":"HEARTS","value":"K"},{"suit":"CLUBS","value":"J"},{"suit":"DIAMONDS","value":"7"},{"suit":"HEARTS","value":"J"},{"suit":"SPADES","value":"9"},{"suit":"CLUBS","value":"7"},{"suit":"HEARTS","value":"5"},{"suit":"SPADES","value":"10"},{"suit":"DIAMONDS","value":"9"},{"suit":"HEARTS","value":"6"},{"suit":"DIAMONDS","value":"4"},{"suit":"DIAMONDS","value":"J"},{"suit":"SPADES","value":"8"},{"suit":"CLUBS","value":"10"}]'

$function:getDOCFull = { $docJson | ConvertFrom-Json | Get-Random -Shuffle }

$function:getDOCOneToX = { param($x)
    $docJson | ConvertFrom-Json | Get-Random -Count (Get-Random -Minimum 1 -Maximum $x)
}

$function:cardScore = { param($card)
    switch ($card.value) {
        { $_ -cin @('J', 'Q', 'K') } { 10 }
        'A' { 11 }
        default { $_ }
    }
}

$function:cardShow = { param($card) $card.suit[0] + $card.value }

$function:docLoop = { param([object[]]$doc, $x, $sb)
    if ($doc.Count -eq 1) { (&$sb $x $doc[0]) }
    else { docLoop ($doc[1..$doc.Count]) (&$sb $x $doc[0]) $sb }
}

$function:docScore = { param ([object[]] $doc)
    if ($doc.Count -eq 0) { 0 }
    else { (docLoop $doc 0 { param($x, $c) $x + (cardScore $c) }) }
}

$function:docShow = { param([object[]]$doc)
    if ($doc.Count -eq 0) { '' }
    else { (docLoop $doc '' { param($x, $c) $x + (cardShow $c) + ' ' }) }
}

$function:noCards = { param([object[]]$doc) $doc.Count -eq 0 }
$function:isLT17 = { param([object[]]$doc) (docScore $doc) -lt 17 }

$BlackJack = { 21 }
$function:isBJ = { param([object[]]$doc) (docScore $doc) -eq (&$BlackJack) }
$function:isGTBJ = { param([object[]]$doc) (docScore $doc) -gt (&$BlackJack) }

$function:giveReceiveX = { param($x, [object[]]$g, [object[]]$r)
    (& { param($t) ($g[$x..$g.Count]), ($r + $t) } ($g[0..($x - 1)]))
}

$function:bjResult = { param($winner, [object[]]$me, [object[]]$magnus)
    $status = { param($d) [ordered]@{ score = (docScore $d); cards = (docShow $d) } }
    $result = { [ordered]@{ winner = $winner; me = (&$status $me); magnus = (&$status $magnus) } }

    & { param($ht)
        if ($asJson) { ConvertTo-Json -InputObject $ht }
        else { [pscustomobject]$ht } } (&$result)
}

$function:bjloop = { param($me, $magnus, $doc)

    $function:giveMe = { param($x)
        (& { param([object[]]$d) bjloop $d[1] $magnus $d[0] } (giveReceiveX $x $doc $me))
    }

    $function:giveMagnus = { param($x)
        (& { param([object[]]$d) bjloop $me $d[1] $d[0] } (giveReceiveX $x $doc $magnus))
    }

    $MagnusLEMe = { (docScore $magnus) -le (docScore $me) }

    $winMe = { (bjResult 'me' $me $magnus) }
    $winMagnus = { (bjResult 'magnus' $me $magnus) }
    $winDraw = { (bjResult 'draw' $me $magnus) }

    switch ('**blackjack compact**') {
        { (noCards $me) } { giveMe 2; break }
        { (noCards $magnus) } { giveMagnus 2; break }
        { ((isBJ $me) -and (isBJ $magnus)) } { return (&$winDraw) }
        { (isBJ $me) } { return (&$winMe) }
        { (isBJ $magnus) } { return (&$winMagnus) }
        { (isLT17 $me) } { giveMe 1; break }
        { (isGTBJ $me) } { return (&$winMagnus) }
        { (&$MagnusLEMe) } { giveMagnus 1; break }
        { (isGTBJ $magnus) } { return (&$winMe) }
        Default { return (&$winMagnus) }
    }
}

function blackjackURL {
    param(
        $me = @(),
        $magnus = @(),
        $urlDOC = 'http://nav-deckofcards.herokuapp.com/shuffle',
        [scriptblock] $docInit = { (Invoke-WebRequest -Uri $urlDOC).Content | ConvertFrom-Json },
        [switch]$asJson = $false
    )
    bjloop $me $magnus (&$docInit)
}

function blackjack {
    param(
        $me = @(),
        $magnus = @(),
        $doc = (getDOCFull),
        [switch]$asJson = $false,
        [switch]$printDOC = $false
    )
    if ($printDOC) { Write-Host "doc: $(docShow $doc)" }
    bjloop $me $magnus $doc
}

$function:enoughCards = { param ($x, [object[]]$doc) $doc.Count -ge $x }
$function:isGE17 = { param([object[]]$doc) (docScore $doc) -ge 17 }

$function:bjloopRandom = { param($me, $magnus, $doc)

    $function:giveMe = { param($x)
        (& { param([object[]]$d) bjloopRandom $d[1] $magnus $d[0] } (giveReceiveX $x $doc $me))
    }

    $function:giveMagnus = { param($x)
        (& { param([object[]]$d) bjloopRandom $me $d[1] $d[0] } (giveReceiveX $x $doc $magnus))
    }

    $MagnusLEMe = { (docScore $magnus) -le (docScore $me) }
    $MagnusGTMe = { (docScore $magnus) -gt (docScore $me) }

    $winMe = { (bjResult 'me' $me $magnus) }
    $winMagnus = { (bjResult 'magnus' $me $magnus) }
    $winDraw = { (bjResult 'draw' $me $magnus) }
    $winNA = { (bjResult 'N/A' $me $magnus) }

    switch ('**blackjack random doc compact**') {
        { ((noCards $me) -and (enoughCards 2 $doc)) } { giveMe 2; break }
        { ((noCards $magnus) -and (enoughCards 2 $doc)) } { giveMagnus 2; break }
        { ((isBJ $me) -and (isBJ $magnus)) } { return (&$winDraw) }
        { ((isBJ $me) -and (enoughCards 2 $magnus)) } { return (&$winMe) }
        { (isBJ $magnus) } { return (&$winMagnus) }
        { ((isLT17 $me) -and (enoughCards 2 $magnus) -and (enoughCards 1 $doc)) } { giveMe 1; break }
        { (isGTBJ $me) } { return (&$winMagnus) }
        { ((&$MagnusLEMe) -and (enoughCards 2 $magnus) -and (enoughCards 1 $doc)) } { giveMagnus 1; break }
        { (isGTBJ $magnus) } { return (&$winMe) }
        { ((&$MagnusGTMe) -and (isGE17 $me)) } { return (&$winMagnus) }
        Default { return (&$winNA) }
    }
}

function blackjackRandomURL {
    param(
        $me = @(),
        $magnus = @(),
        $urlDOC = 'https://randomdoc.azurewebsites.net/api/get?max=10',
        [scriptblock] $docInit = { (Invoke-WebRequest -Uri $urlDOC).Content | ConvertFrom-Json },
        [switch]$asJson = $false
    )
    bjloopRandom $me $magnus (&$docInit)
}

function blackjackRandom {
    param(
        $me = @(),
        $magnus = @(),
        $doc = (getDOCOneToX 10),
        [switch]$asJson = $false,
        [switch]$printDOC = $false
    )
    if ($printDOC) { Write-Host "doc: $(docShow $doc)" }
    bjloopRandom $me $magnus $doc
}

Export-ModuleMember -Function @(
    "getDOCFull"
    "getDOCOneToX"
    "blackjackURL"
    "blackjack"
    "blackjackRandomURL"
    "blackjackRandom"
)