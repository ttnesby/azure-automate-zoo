1..10 | ForEach-Object -Parallel { 
    . "./src/blackjack.ps1"
    blackjack 
} | Group-Object -NoElement {$_.winner} | Sort-Object {$_.winner}