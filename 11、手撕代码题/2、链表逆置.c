struct ListNode{
    int val;
    struct ListNode* next;
}

struct ListNode* ReverseListNode(const struct ListNode* pHead){
    struct ListNode* pre = NULL;
    struct ListNode* cur = pHead;
    struct ListNode* next = NULL;
    if(cur != NULL){
        next = cur->next;
        cur->next = pre;
        pre = cur;
        cur = next;
    }
}