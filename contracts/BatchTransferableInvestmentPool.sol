pragma solidity ^0.4.23;

import "./BaseInvestmentPool.sol";


/**
 * @title BatchTransferableInvestmentPool
 * @dev The contract extends BaseInvestmentPool and adds possibility of sending tokens to investors.
 */
contract BatchTransferableInvestmentPool is BaseInvestmentPool {
  /**
   * @notice number of investors per one transfer transaction.
   */
  uint public constant BATCH_SIZE = 50;

  /**
   * @notice investors which contributed funds and can get tokens.
   */
  address[] internal investors;

  /**
   * @notice transfers tokens to multiple investors address.
   *
   * @param _index number of page of addresses, starts from 1
   */
  function batchTransferFromPage(uint _index) external nonReentrant {
    uint indexOffset = (_index - 1) * BATCH_SIZE;
    require(indexOffset < investors.length);

    uint batchLength = BATCH_SIZE;
    if (investors.length - indexOffset < BATCH_SIZE) {
      batchLength = investors.length - indexOffset;
    }

    uint tokenRaised = ERC20Basic(tokenAddress).balanceOf(this).add(tokensWithdrawn);
    uint tokenAmountMultiplex = tokenRaised.mul(1000 - rewardPermille).div(weiRaised.mul(1000));

    uint batchTokenAmount;
    for (uint i = 0; i < batchLength; i ++) {
      address currentInvestor = investors[i + (indexOffset)];
      uint invested = investments[currentInvestor];
      uint tokenAmount = invested.mul(tokenAmountMultiplex).sub(tokensWithdrawnByInvestor[currentInvestor]);

      if (invested == 0 || tokenAmount == 0) {
        continue;
      } else {
        ERC20Basic(tokenAddress).transfer(currentInvestor, tokenAmount);
        batchTokenAmount += tokenAmount;

        tokensWithdrawnByInvestor[currentInvestor] += tokenAmount;
        emit WithdrawTokens(currentInvestor, tokenAmount);
      }
    }
    tokensWithdrawn += batchTokenAmount;
  }


  /**
   * @notice returns number of page (starting from 1), which have unsended investor tokens
   */
  function getPage() public view returns (uint) {
    uint firstIndex;
    bool isIndexAssigned;
    for (uint i = 0; i < investors.length; i++) {
      uint investorAmount = _getInvestorTokenAmount(investors[i]);
      if (investorAmount != 0) {
        firstIndex = i;
        isIndexAssigned = true;
        break;
      }
    }
    if (isIndexAssigned) {
      return firstIndex.div(BATCH_SIZE) + 1;
    } else {
      return firstIndex;
    }
  }

  /**
   * @notice returns total number of investors, who sended money on contract
   */
  function investorsCount() public view returns (uint) {
    return investors.length;
  }

  /**
   * @notice returns rest amount of unreceived tokens on page
   * @param _index number of page (starting from 1)
   */
  function pageTokenAmount(uint _index) public view returns (uint batchTokenAmount) {
    uint indexOffset = (_index - 1) * BATCH_SIZE;
    require(indexOffset < investors.length);

    uint batchLength = BATCH_SIZE;
    if (investors.length - indexOffset < BATCH_SIZE) {
      batchLength = investors.length - indexOffset;
    }

    uint tokenRaised = ERC20Basic(tokenAddress).balanceOf(this).add(tokensWithdrawn);
    uint tokenAmountMultiplex = tokenRaised.mul(1000 - rewardPermille).div(weiRaised.mul(1000));

    for (uint i = 0; i < batchLength; i ++) {
      address currentInvestor = investors[i + (indexOffset)];
      uint invested = investments[currentInvestor];
      uint tokenAmount = invested.mul(tokenAmountMultiplex).sub(tokensWithdrawnByInvestor[currentInvestor]);

      if (invested == 0 || tokenAmount == 0) {
        continue;
      } else {
        batchTokenAmount += tokenAmount;
      }
    }
  }

  /**
   * @notice returns number of investors that have not received tokens yet
   * @param _index number of page (starting from 1)
   */
  function pageInvestorsRemain(uint _index) public view returns (uint investorsRemain) {
    uint indexOffset = (_index - 1) * BATCH_SIZE;
    require(indexOffset < investors.length);

    uint batchLength = BATCH_SIZE;
    if (investors.length - indexOffset < BATCH_SIZE) {
      batchLength = investors.length - indexOffset;
    }

    uint tokenRaised = ERC20Basic(tokenAddress).balanceOf(this).add(tokensWithdrawn);
    uint tokenAmountMultiplex = tokenRaised.mul(1000 - rewardPermille).div(weiRaised.mul(1000));

    for (uint i = 0; i < batchLength; i ++) {
      address currentInvestor = investors[i + (indexOffset)];
      uint invested = investments[currentInvestor];
      uint tokenAmount = invested.mul(tokenAmountMultiplex).sub(tokensWithdrawnByInvestor[currentInvestor]);

      if (invested == 0 || tokenAmount == 0) {
        continue;
      } else {
         investorsRemain++;
      }
    }
  }

  /**
   * @notice validates investor's transactions and storing investor's address before adding investor funds
   */
  function _preValidateInvest(address _beneficiary, uint _amount) internal {
    super._preValidateInvest(_beneficiary, _amount);
    if (investments[_beneficiary] == 0) {
      investors.push(_beneficiary);
    }
  }
}
