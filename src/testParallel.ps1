Write-Host "====== Blackjack ======"
1..100 | ForEach-Object -Parallel { 
    import-module "./src/blackjack.psm1"
    blackjack 
} | Group-Object -Property winner -NoElement | Sort-Object -Property winner
Write-Host ""
Write-Host "====== Blackjack Random ======"
1..100 | ForEach-Object -Parallel { 
    import-module "./src/blackjack.psm1"
    blackjackRandom 
} | Group-Object -Property winner -NoElement | Sort-Object -Property winner