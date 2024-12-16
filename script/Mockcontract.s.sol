// SPDX-License-Identifier: MIT
pragma solidity >0.2.0 <0.9.0;


contract MockVRFCoordinator {
    function requestRandomWords(
        bytes32,
        uint64,
        uint16,
        uint32,
        uint32
    ) external pure returns (uint256) {
        // Mock a request ID
        return 1;
    }
}
