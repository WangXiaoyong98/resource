struct ListNode{
    int val;
    struct ListNode* Node;
}


bool havecircle(const struct ListNode* pHead){
    if(pHead == NULL){
        return false;
    }
    struct ListNode* slow = pHead;
    struct ListNode* fast = pHead;
    while(fast->Node != NULL&&fast->Node->Node != NULL){
        slow = slow->Node;
        fast = fast->Node->Node;
        if(slow == fast){
            return true;
        }
    }
    return false;
}