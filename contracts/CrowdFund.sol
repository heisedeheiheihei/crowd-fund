// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CrowdFund {
    event LaunchEvent(
        uint256 id,
        address creator,
        uint256 goal,
        uint32 startAt,
        uint32 endAt
    );

    event CancelEvent(uint256 id);
    event PledgeEvent(uint256 indexed id, address caller, uint256 amount);
    event UnpledgeEvent(uint256 indexed id, address caller, uint256 amount);
    event ClaimEvent(uint256 _id);
    
    // 募捐活动结构体
    struct Campaign {
        address creator;
        uint256 goal;
        uint256 pledged; // 质押数量
        uint32 startAt;
        uint32 endAt;
        bool claimed; // 募捐结束标识符
    }

    // 使用基于ERC20规范的代币
    IERC20 public immutable token;

    uint256 public campaignNum;

    mapping(uint256 => Campaign) public campaignsMapping;
    mapping(uint256 => mapping(address => uint256)) public pledgedAmountMapping;

    constructor(address _token) {
        token = IERC20(_token);
    }

    // 发起募捐
    function launch(uint256 _goal, uint32 _startAt, uint32 _endAt) external {
        require(_startAt >= block.timestamp, "start at < now");
        require(_endAt >= _startAt, "end at < start at");
        require(_endAt <= block.timestamp + 30 days, "end at > max duration"); // 募捐周期最长为30天

        campaignsMapping[campaignNum] = Campaign(
            msg.sender,
            _goal,
            0,
            _startAt,
            _endAt,
            false
        );

        emit LaunchEvent(campaignNum, msg.sender, _goal, _startAt, _endAt);
    }

    function cancel(uint256 _id) cancelModifier(_id) external {
        delete campaignsMapping[_id];

        emit CancelEvent(_id);
    }

    // 募捐期间抵押
    function pledge(uint256 _id, uint256 _amount) external {
        Campaign storage campaign = campaignsMapping[_id];
        require(campaign.startAt <= block.timestamp, "campaign has not started");
        require(campaign.endAt >= block.timestamp, "campaign has ended");

        campaign.pledged += _amount;
        pledgedAmountMapping[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        emit PledgeEvent(_id, msg.sender, _amount);
    }

    // 募捐未结束时解押
    function unpledge(uint256 _id, uint256 _amount) external {
        Campaign storage campaign = campaignsMapping[_id];
        require(campaign.endAt > block.timestamp, "campaign has ended");

        campaign.pledged -= _amount;
        pledgedAmountMapping[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);

        emit UnpledgeEvent(_id, msg.sender, _amount);
    }

    // 募捐结束转移资产
    function claim(uint256 _id) external {
        Campaign storage campaign = campaignsMapping[_id];
        require(campaign.creator == msg.sender, "not creator");
        require(campaign.endAt < block.timestamp, "not ended");
        require(campaign.pledged >= campaign.goal, "pledged < goal");
        require(!campaign.claimed, "claimed");

        campaign.claimed = true;

        token.transfer(campaign.creator, campaign.pledged);

        emit ClaimEvent(_id);
    }

    // 募捐结束未达目标时退款
    function refund(uint256 _id) external {
        Campaign memory campaign = campaignsMapping[_id];

        require(campaign.endAt < block.timestamp, "not ended");
        require(campaign.pledged < campaign.goal, "pledged >= goal");

        uint256 balance = pledgedAmountMapping[_id][msg.sender];
        pledgedAmountMapping[_id][msg.sender] = 0;

        token.transfer(msg.sender, balance);
    }

    modifier cancelModifier(uint256 _id) {
        Campaign memory campaign = campaignsMapping[_id];
        require(campaign.creator == msg.sender, "only creator can cancel");
        require(campaign.startAt > block.timestamp, "campaign has started");
        _;
    }
}