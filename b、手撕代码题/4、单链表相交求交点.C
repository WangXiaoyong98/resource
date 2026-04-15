struct ListNode {
    int val;
    struct ListNode* next;
};

struct ListNode* findFirstCommonNode(const struct ListNode* pHead1,const struct ListNode* pHead2){
    struct ListNode* p = pHead1;
    struct ListNode* q = pHead2;
    while(p != q){
        p = (p == NULL ? pHead2 : p->next);
        q = (q == NULL ? pHead1 : q->next);
    }
    return p;
}

