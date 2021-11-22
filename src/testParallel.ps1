1..1000 | ForEach-Object -Parallel { 
    import-module "./src/blackjack.psm1"
    blackjack 
} | Group-Object -Property winner -NoElement | Sort-Object -Property winner