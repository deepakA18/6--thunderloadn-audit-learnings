### [H-1] Erronous `ThunderLoan::updateExchangeRate` in the `deposit` function causes protocol to think it has more fees than it really does, which blocks redemption and incorrectly sets the exchange rate

**Description:** In the Tunderloan protocol, the `exchangeRate` is responsible for calculating the exchange  rate between assetTokens and underlying tokens. In a way, it's responsible for keeping track of how many fees to give to Liquidity providers.

However, the `deposit` function, updates this rate, without collecting any fees! 

```
function deposit(IERC20 token, uint256 amount) external revertIfZero(amount) revertIfNotAllowedToken(token) {
        AssetToken assetToken = s_tokenToAssetToken[token];
        uint256 exchangeRate = assetToken.getExchangeRate();
        uint256 mintAmount = (amount * assetToken.EXCHANGE_RATE_PRECISION()) / exchangeRate;
        
        emit Deposit(msg.sender, token, amount);
        assetToken.mint(msg.sender, mintAmount);

        //@audit - high
        
@>        uint256 calculatedFee = getCalculatedFee(token, amount);
@>        assetToken.updateExchangeRate(calculatedFee);
        
      
        token.safeTransferFrom(msg.sender, address(assetToken), amount);
    }

```

**Impact:** There are several impacts to this bug.

1. The `redeem` function is blocked, because the protocol thinkd the owed tokens is more than it has.
2. Rewards are incorrectly calculated, leading t liquidity providers potentially getting way more or less than deserved.

**Proof of Concept:**

1. LP deposits 
2. User takes out a flash loan
3. It is now impossible for LP to redeem.

<details>
<summary>Proof of Code</summary>

```javascript

function testRedeemAfterLoan() public setAllowedToken hasDeposits {
        uint256 amountToBorrow = AMOUNT * 10;
        uint256 calculatedFee = thunderLoan.getCalculatedFee(tokenA, amountToBorrow);
        vm.startPrank(user);
        tokenA.mint(address(mockFlashLoanReceiver), calculatedFee);
        thunderLoan.flashloan(address(mockFlashLoanReceiver), tokenA, amountToBorrow, "");
        vm.stopPrank();

        uint256 amountToRedeem = type(uint256).max;
        vm.startPrank(liquidityProvider);
        thunderLoan.redeem(tokenA, amountToRedeem);
    }

```

</details>

**Recommended Mitigation:** Remove the incorrectly updated exchangeRate from `Thunderloan::deposit`

```diff

function deposit(IERC20 token, uint256 amount) external revertIfZero(amount) revertIfNotAllowedToken(token) {
        AssetToken assetToken = s_tokenToAssetToken[token];
        uint256 exchangeRate = assetToken.getExchangeRate();
        uint256 mintAmount = (amount * assetToken.EXCHANGE_RATE_PRECISION()) / exchangeRate;
        
        emit Deposit(msg.sender, token, amount);
        assetToken.mint(msg.sender, mintAmount);

        //@audit - high
        
-       uint256 calculatedFee = getCalculatedFee(token, amount);
-        assetToken.updateExchangeRate(calculatedFee);
        
      
        token.safeTransferFrom(msg.sender, address(assetToken), amount);
    }

```
