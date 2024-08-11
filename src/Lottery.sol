// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console.sol";

contract Lottery {
	uint256 public cost;
	mapping(address => uint16) public lotto;
	mapping(address => bool) public sell;
	mapping(address => uint256) public sell_time;
	mapping(address => bool) public game_result;
	address[] public gamers;
	uint256 public gamers_cnt;
	uint256 public winners;
	uint256 public hold;
	uint256 public start_time;
	bool public run;

	constructor() {
		cost = 0.1 ether;
	}
	modifier sellChk {
		require(sell[msg.sender] == true, "no sell");
		_;
	}
	modifier timeChk {
		require(sell_time[msg.sender] + 24 hours <= block.timestamp, "time error");
		_;
	}

	function buy(uint16 number) payable public {
		require(msg.value == cost, "eth revert");
		if (start_time > 0) {
			require(start_time + 24 hours > block.timestamp, "phase ended");
		}
		require(sell[msg.sender] == false, "no dup");
		lotto[msg.sender] = number;
		sell[msg.sender] = true;
		game_result[msg.sender] = false;
		sell_time[msg.sender] = block.timestamp;
		gamers.push(msg.sender);
		if (start_time == 0) {
			start_time = block.timestamp;
		}
		run = true;
	}

	function draw() public sellChk timeChk {
		uint16 win = winningNumber();
		winners = 0;
		gamers_cnt = 0;
		for (uint256 i = 0; i < gamers.length; i++) {
			if (lotto[gamers[i]] == win) {
				game_result[gamers[i]] = true;
				winners += 1;
			}
			gamers_cnt += 1;
		}
		delete gamers;
		if (winners == 0) {
			hold = cost * gamers_cnt;
			gamers_cnt = 0;
		}
	}

	function claim() public sellChk timeChk {
		address to = msg.sender;
		uint256 val = 0;
		if (game_result[to]) {
			val = (cost * gamers_cnt + hold) / winners;
			if (address(this).balance < val) {
				val = address(this).balance;
			}
		}
		game_result[to] = false;
		sell[to] = false;
		(bool success, ) = to.call{value: val}("");
		require(success, "Transfer failed");
		start_time = 0; 
	}

	function winningNumber() public view returns (uint16) {
		return uint16(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 10000);
	}

	receive() external payable {}
}
