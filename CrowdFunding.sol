// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract CrowdFunding{
    mapping(address => uint) public contributors; //address -> ether
    address public manager;
    uint public minimumContribution;
    uint public deadlines;
    uint public target;
    uint public raiseAmount;
    uint public noOfContributors;
    
    struct Request {
        string description;
        address payable recipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address => bool) voters;
    }
    
    mapping(uint => Request) public request;
    uint public numRequest;
    
    constructor(uint _target , uint _deadline){
        target=_target;
        deadlines=block.timestamp+_deadline;
        minimumContribution = 100 wei;
        manager = msg.sender;
    }
    
    function sendEther() public payable  {
        require(block.timestamp < deadlines , "Deadline has passed!");
        require(msg.value >= minimumContribution , "Minimum contribution is not met!");
        
        if(contributors[msg.sender] == 0){
            noOfContributors++;
        }
        contributors[msg.sender]+=msg.value;
        raiseAmount+=msg.value;
    }
    
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function refund() public {
        require(block.timestamp > deadlines && raiseAmount < target , "You are not eligible for refund!");
        require(contributors[msg.sender] > 0 , "You are not contributed yet!");
        address payable user = payable(msg.sender); // payable user
        user.transfer(contributors[msg.sender]); // transfer value store in contributors[msg.sender]
        contributors[msg.sender] = 0;
    }
    
    modifier onlyManager(){
        require(msg.sender == manager , "Access Denied!");
        _;
    }
    
    function createRequests(string memory _desc , address payable _recipient , uint _value) public onlyManager{
        Request storage newRequest = request[numRequest];
        numRequest++;
        newRequest.description =_desc;
        newRequest.recipient =_recipient;
        newRequest.value =_value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }
    
    function voteRequest(uint _requestNo) public{
        require(contributors[msg.sender] > 0 , "You must be a contributor!");
        Request storage thisRequest = request[_requestNo];
        require(thisRequest.voters[msg.sender] == false , "You have already voted");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }
    
    function makePayment(uint _requestNo) public onlyManager{
        require(raiseAmount >= target);
        Request storage thisRequest = request[_requestNo];
        require(thisRequest.completed == false , "The request has been completed!");
        require(thisRequest.noOfVoters > noOfContributors/2 , "Majority does not support!");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;
    }
    
}