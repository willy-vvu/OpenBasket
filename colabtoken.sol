pragma solidity ^0.4.8;

contract Token {
  /* Public variables of the token */
  string public standard = 'Token 0.1';
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public price;
  uint256 public totalSupply;

  /* Define variable owner of the type address*/
  address owner;

  /* Function to recover the funds on the contract */
  function kill() { if (msg.sender == owner) selfdestruct(owner); }

  /* This creates an array with all balances */
  mapping (address => uint256) public balanceOf;

  /* This generates a public event on the blockchain that will notify clients */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /* Initializes contract with initial supply tokens to the creator of the contract */
  function Token(
      uint256 initialSupply,
      string tokenName,
      string tokenSymbol,
      uint8 decimalUnits,
      uint256 initialPrice
    ) {
    totalSupply = initialSupply;
    balanceOf[this] = totalSupply;
    name = tokenName;
    symbol = tokenSymbol;
    decimals = decimalUnits;
    price = initialPrice;
    owner = msg.sender;
  }

  /* Send coins */
  function transfer(address _to, uint256 _value) {
    if (_to == 0x0) throw;                               // Prevent transfer to 0x0 address. Use burn() instead
    if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
    if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
    balanceOf[msg.sender] -= _value;                     // Subtract from the sender
    balanceOf[_to] += _value;                            // Add the same to the recipient
    Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
  }

  function setPrice(uint256 _price) returns (bool success) {
      price = _price;
      return true;
  }

  function buy() payable returns (uint amount){        // Buy in ETH
    amount = msg.value / price;                        // calculates the amount
    if (balanceOf[this] < amount) throw;               // checks if it has enough to sell
    balanceOf[msg.sender] += amount;                   // adds the amount to buyer's balance
    balanceOf[this] -= amount;                         // subtracts amount from seller's balance
    Transfer(this, msg.sender, amount);                // execute an event reflecting the change
    return amount;                                     // ends function and returns
  }

  function sell(uint amount) returns (uint revenue){   // Sell in tokens
    if (balanceOf[msg.sender] < amount ) throw;        // checks if the sender has enough to sell
    balanceOf[this] += amount;                         // adds the amount to owner's balance
    balanceOf[msg.sender] -= amount;                   // subtracts the amount from seller's balance
    revenue = amount * price;
    msg.sender.transfer(revenue);
    Transfer(msg.sender, this, amount);            // executes an event reflecting on the change
    return revenue;                                // ends function and returns
  }

  /* The function without name is the default function that is called whenever anyone sends funds to a contract */
  function () payable {}
}


contract TokenToken is Token{
/* Public variables of the token */

  address[] public tokenExchanges;
  uint256[] public tokenRatios;

  /* This generates a public event on the blockchain that will notify clients */
  //event Transfer(address indexed from, address indexed to, uint256 value);

  /* Initializes contract with initial supply tokens to the creator of the contract */
  function TokenToken(
    uint256 initialSupply,
    string tokenName,
    string tokenSymbol,
    uint8 decimalUnits,
    address[] initialTokenExchanges,
    uint256[] initialTokenRatios
    ) Token(
      initialSupply,
      tokenName,
      tokenSymbol,
      decimalUnits,
      0
    ) {
    totalSupply = initialSupply;
    balanceOf[this] = totalSupply;
    name = tokenName;
    symbol = tokenSymbol;
    decimals = decimalUnits;
    tokenExchanges = initialTokenExchanges;
    tokenRatios = initialTokenRatios;
    owner = msg.sender;
  }

  function setTokenExchanges(
    address[] newTokenExchanges,
    uint256[] newTokenRatios
  ) returns (bool success) {
      tokenExchanges = newTokenExchanges;
      tokenRatios = newTokenRatios;
      return true;
  }

  function setPrice() returns (bool success) {
    return false;
  }


  function buy() payable returns (uint amount){        // Buy in ETH
    uint256 totalPrice = 0;
    for (uint i = 0; i < tokenExchanges.length; ++i) {
      Token token = Token(tokenExchanges[i]);
      uint256 ratio = tokenRatios[i];
      totalPrice += token.price() * ratio;
    }

    amount = msg.value / totalPrice;                   // calculates the amount
    if (balanceOf[this] < amount) throw;               // checks if it has enough to sell
    for (i = 0; i < tokenExchanges.length; ++i) { // Unsafe code: what if the loop errors halfway?
      token = Token(tokenExchanges[i]);
      ratio = tokenRatios[i];
      token.buy.value(amount * token.price() * ratio)();
    }
    balanceOf[msg.sender] += amount;                   // adds the amount to buyer's balance
    balanceOf[this] -= amount;                         // subtracts amount from seller's balance
    Transfer(this, msg.sender, amount);                // execute an event reflecting the change
    return amount;                                     // ends function and returns
  }

  function sell(uint amount) returns (uint revenue){   // Sell in tokens
    if (balanceOf[msg.sender] < amount ) throw;        // checks if the sender has enough to sell
    balanceOf[this] += amount;                         // adds the amount to owner's balance
    balanceOf[msg.sender] -= amount;                   // subtracts the amount from seller's balance

    uint256 totalPrice = 0;
    for (uint i = 0; i < tokenExchanges.length; ++i) { // Unsafe code: what if the loop errors halfway?
      Token token = Token(tokenExchanges[i]);
      uint256 ratio = tokenRatios[i];
      token.sell(amount * ratio);
      totalPrice += token.price() * ratio;
    }

    revenue = amount * totalPrice;
    msg.sender.transfer(revenue);
    Transfer(msg.sender, this, amount);            // executes an event reflecting on the change
    return revenue;                                // ends function and returns
  }

  function breakdown(uint amount) {   // Sell in tokens
    if (balanceOf[msg.sender] < amount ) throw;        // checks if the sender has enough to sell
    balanceOf[this] += amount;                         // adds the amount to owner's balance
    balanceOf[msg.sender] -= amount;                   // subtracts the amount from seller's balance

    for (uint i = 0; i < tokenExchanges.length; ++i) { // Unsafe code: what if the loop errors halfway?
      Token token = Token(tokenExchanges[i]);
      uint256 ratio = tokenRatios[i];
      token.transfer(msg.sender, amount * ratio);
    }
  }
}