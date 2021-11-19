[CmdletBinding()]
param (
    [Parameter(HelpMessage = "URL to deck of cards (doc)", Mandatory = $false)]
    [string]
    $urlDOC = 'http://nav-deckofcards.herokuapp.com/shuffle'
)

$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

function blackjack {
    param(
        $me = @(),
        $magnus = @(),
        $doc = ((Invoke-WebRequest -Uri $urlDOC).Content | ConvertFrom-Json)
    )

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
    
    $function:docScore = { param ([object[]] $doc) (docLoop $doc 0 { param($x, $c) $x + (cardScore $c) }) }
    $function:docShow = { param([object[]]$doc) (docLoop $doc '' { param($x, $c) $x + (cardShow $c) + ' ' }) }
    
    $function:noCards = { param([object[]]$doc) $doc.Count -eq 0 }
    $function:isLT17 = { param([object[]]$doc) (docScore $doc) -lt 17 }
    
    $BlackJack = { 21 }
    $function:isBJ = { param([object[]]$doc) (docScore $doc) -eq (&$BlackJack) }
    $function:isGTBJ = { param([object[]]$doc) (docScore $doc) -gt (&$BlackJack) }
    
    $function:giveReceiveX = { param($x, [object[]]$g, [object[]]$r)
        (& { param($t) ($g[2..$g.Count]), ($r + $t) } ($g[0..($x - 1)]))
    }
    
    $function:bjResult = { param($winner, [object[]]$me, [object[]]$magnus)
        $status = { param($d) [ordered]@{ score = (docScore $d); cards = (docShow $d) } }
    
        [ordered]@{ winner = $winner; me = (&$status $me); magnus = (&$status $magnus) } | ConvertTo-Json
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
            { (isBJ $me -and isBJ $magnus) } { return (&$winDraw) }
            { (isBJ $me) } { return (&$winMe) }
            { (isBJ $magnus) } { return (&$winMagnus) }
            { (isLT17 $me) } { giveMe 1; break }
            { (isGTBJ $me) } { return (&$winMagnus) }
            { (&$MagnusLEMe) } { giveMagnus 1; break }
            { (isGTBJ $magnus) } { return (&$winMe) }
            Default { return (&$winMagnus) }
        }
    }

    bjloop $me $magnus $doc
}