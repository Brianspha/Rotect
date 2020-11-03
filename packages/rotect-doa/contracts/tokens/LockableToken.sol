pragma solidity >=0.5.0;
import "@openzeppelin/contracts-ethereum-package/contracts/ownership/Ownable.sol";


contract LockableToken is Ownable {
    function increaseLockedAmount(address _owner, uint256 _amount) public returns (uint256);
    function decreaseLockedAmount(address _owner, uint256 _amount) public returns (uint256);
    function getLockedAmount(address _owner)  public view returns (uint256);
    function getUnlockedAmount(address _owner)  public view returns (uint256);
}