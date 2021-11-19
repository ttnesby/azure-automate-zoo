# azure-automate-zoo

`src/blackjack.ps1` is a lambda calculus oriented programming, containing a powershell function `blackjack`. 

Consider the function as a kind of `function zoo` :-)

The learning points are;
1. Each powershell function is a script block
2. Script block can be defined in different ways
3. Script block is a value and be a parameter into other script blocks
4. Script blocks can be anonymous
5. Kind of doable in pwsh, but not recommended!

At the end of the day, independent of whatever programming language and platform - composability (building larger components from smaller ones) and referential integrity are the ultimate goals. It has nothing to do with `being esoteric`.   

If you can read the code, you are ready for any pwsh script!

# Test the function
```powershell
# dot source the blackjack.ps1 - will make it available as a function
. ./src/blackjack.ps1

# execute the function
blackjack

# output example
{                                                                                                              
  "winner": "magnus",
  "me": {
    "score": 25,
    "cards": "C10 H5 CK "
  },
  "magnus": {
    "score": 18,
    "cards": "D10 H8 "
  }
}
```