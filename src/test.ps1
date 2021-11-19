Measure-Command {
    $result = 1..100 | ForEach-Object -Parallel { 
        . ./src/blackjack.ps1
        blackjack
    }
}