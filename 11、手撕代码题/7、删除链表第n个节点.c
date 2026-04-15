struct ListNode {
    int val;
    struct ListNode* next;
};

struct ListNode* removeNthNode(struct ListNode* head,int n){
    struct ListNode* temp = head;

    int i = 0;
    for(int i = 0; i < n; i++){
        temp = temp->next
    }
    temp->next = temp->next->next;
    free(temp->next);
    return head;
}